#!/bin/bash

# Script to verify the t1-small topology is working correctly

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "t1-small Topology Verification Script"
echo "=========================================="
echo ""

# Check if containers are running
echo -e "${BLUE}1. Checking container status...${NC}"
containers=("clab-t1-small-sonic-dut" "clab-t1-small-t0" "clab-t1-small-t2" "clab-t1-small-ptf" "clab-t1-small-sonic-mgmt")

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "  ${GREEN}✓${NC} $container is running"
    else
        echo -e "  ${RED}✗${NC} $container is NOT running"
    fi
done
echo ""

# Check BGP neighbors
echo -e "${BLUE}2. Checking BGP neighbor status...${NC}"
echo -e "${YELLOW}sonic-dut BGP neighbors:${NC}"
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary" 2>/dev/null || echo "  BGP not ready yet"
echo ""

echo -e "${YELLOW}t0 BGP neighbors:${NC}"
docker exec clab-t1-small-t0 vtysh -c "show ip bgp summary" 2>/dev/null || echo "  BGP not ready yet"
echo ""

echo -e "${YELLOW}t2 BGP neighbors:${NC}"
docker exec clab-t1-small-t2 vtysh -c "show ip bgp summary" 2>/dev/null || echo "  BGP not ready yet"
echo ""

# Check interface status
echo -e "${BLUE}3. Checking interface status on sonic-dut...${NC}"
docker exec clab-t1-small-sonic-dut vtysh -c "show interface brief" 2>/dev/null || echo "  Interfaces not ready yet"
echo ""

# Check LLDP neighbors
echo -e "${BLUE}4. Checking LLDP neighbors on sonic-dut...${NC}"
docker exec clab-t1-small-sonic-dut show lldp table 2>/dev/null || echo "  LLDP not ready yet"
echo ""

# Check PTF interfaces
echo -e "${BLUE}5. Checking PTF container interfaces...${NC}"
docker exec clab-t1-small-ptf ip link show 2>/dev/null | grep -E "eth[0-9]:" || echo "  PTF interfaces not ready"
echo ""

# Ping tests
echo -e "${BLUE}6. Testing connectivity...${NC}"
echo -e "${YELLOW}Ping from sonic-dut to t0 (10.0.0.1):${NC}"
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.1 2>/dev/null && echo -e "${GREEN}✓ Success${NC}" || echo -e "${RED}✗ Failed${NC}"
echo ""

echo -e "${YELLOW}Ping from sonic-dut to t2 (10.0.0.3):${NC}"
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.3 2>/dev/null && echo -e "${GREEN}✓ Success${NC}" || echo -e "${RED}✗ Failed${NC}"
echo ""

# Check routes
echo -e "${BLUE}7. Checking routing table on sonic-dut...${NC}"
docker exec clab-t1-small-sonic-dut vtysh -c "show ip route" 2>/dev/null || echo "  Routes not ready yet"
echo ""

echo "=========================================="
echo -e "${GREEN}Verification complete!${NC}"
echo "=========================================="

