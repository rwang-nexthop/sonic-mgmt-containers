#!/bin/bash

# Script to verify the t1-small-vm topology is working correctly

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "t1-small-vm Topology Verification Script"
echo "=========================================="
echo ""

# Check if containers are running
echo -e "${BLUE}1. Checking container status...${NC}"
containers=("clab-t1-small-vm-sonic-dut" "clab-t1-small-vm-t0" "clab-t1-small-vm-t2" "clab-t1-small-vm-ptf" "clab-t1-small-vm-sonic-mgmt")

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "  ${GREEN}✓${NC} $container is running"
    else
        echo -e "  ${RED}✗${NC} $container is NOT running"
    fi
done
echo ""

# Detailed container status table
echo -e "${YELLOW}Detailed container status:${NC}"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep clab-t1-small-vm
echo ""

# Check sonic-mgmt container
echo -e "${BLUE}2. Checking sonic-mgmt container...${NC}"
echo -e "${YELLOW}sonic-mgmt IP addresses:${NC}"
docker exec clab-t1-small-vm-sonic-mgmt ip addr show 2>/dev/null || echo "  sonic-mgmt not ready yet"
echo ""

echo -e "${YELLOW}sonic-mgmt connectivity to sonic-dut (172.30.30.4):${NC}"
docker exec clab-t1-small-vm-sonic-mgmt ping -c 3 172.30.30.4 2>/dev/null && echo -e "${GREEN}✓ Success${NC}" || echo -e "${RED}✗ Failed${NC}"
echo ""

# Check SSH connectivity
echo -e "${BLUE}3. Checking SSH connectivity...${NC}"
echo -e "${YELLOW}SSH to sonic-dut (172.30.30.4):${NC}"
if timeout 5 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@172.30.30.4 "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${YELLOW}⚠ SSH not ready yet (may need more boot time)${NC}"
fi
echo ""

# Check PTF interfaces
echo -e "${BLUE}4. Checking PTF container interfaces...${NC}"
echo -e "${YELLOW}PTF IP addresses:${NC}"
docker exec clab-t1-small-vm-ptf ip addr show 2>/dev/null || echo "  PTF not ready yet"
echo ""

echo -e "${YELLOW}PTF link status:${NC}"
docker exec clab-t1-small-vm-ptf ip link show 2>/dev/null || echo "  PTF interfaces not ready"
echo ""

# Container logs
echo -e "${BLUE}5. Recent container logs (sonic-dut - last 20 lines)...${NC}"
docker logs --tail 20 clab-t1-small-vm-sonic-dut 2>/dev/null || echo "  Logs not available"
echo ""

# Docker network inspection
echo -e "${BLUE}6. Docker network status...${NC}"
echo -e "${YELLOW}t1-mgmt network details:${NC}"
docker network inspect t1-mgmt 2>/dev/null | grep -A 30 "Containers" || echo "  Network not ready yet"
echo ""

echo "=========================================="
echo -e "${GREEN}Verification complete!${NC}"
echo "=========================================="
echo ""
echo "Note: sonic-vm nodes take ~60 seconds to boot."
echo "If SSH is not ready, wait a bit longer and try again."
echo ""

