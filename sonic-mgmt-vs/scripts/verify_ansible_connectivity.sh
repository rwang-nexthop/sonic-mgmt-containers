#!/bin/bash

# Script to verify Ansible connectivity to all nodes
# Tests SSH and Ansible ping to DUT and leaf nodes

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SONIC_MGMT_CONTAINER="sonic-mgmt-test"
NODES=("dut" "leaf1" "leaf2")
IPS=("172.20.20.2" "172.20.20.11" "172.20.20.12")

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Verifying Ansible Connectivity to All Nodes            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if sonic-mgmt container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${SONIC_MGMT_CONTAINER}$"; then
    echo -e "${RED}✗ sonic-mgmt-test container is not running${NC}"
    exit 1
fi

echo -e "${GREEN}✓ sonic-mgmt-test container is running${NC}"
echo ""

# Test 1: SSH connectivity to each node
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 1: SSH Connectivity${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    ip="${IPS[$i]}"
    
    echo "Testing SSH to $node ($ip)..."
    
    if docker exec -u rwang $SONIC_MGMT_CONTAINER bash -c "sshpass -p 'YourPassword' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 admin@$ip 'show version' >/dev/null 2>&1"; then
        echo -e "  ${GREEN}✓ SSH connection successful${NC}"
    else
        echo -e "  ${RED}✗ SSH connection failed${NC}"
    fi
done

echo ""

# Test 2: Ansible ping to each node
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 2: Ansible Ping (Individual Hosts)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

for node in "${NODES[@]}"; do
    echo "Ansible ping to $node..."
    
    if docker exec -u rwang $SONIC_MGMT_CONTAINER bash -c "cd /var/src/ansible && ansible -i clab_inventory.yml $node -m ping" 2>&1 | grep -q "SUCCESS"; then
        echo -e "  ${GREEN}✓ Ansible ping successful${NC}"
    else
        echo -e "  ${YELLOW}⚠ Ansible ping may have issues (checking details)${NC}"
    fi
done

echo ""

# Test 3: Ansible ping to all sonic_devices group
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 3: Ansible Ping (All sonic_devices Group)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if docker exec -u rwang $SONIC_MGMT_CONTAINER bash -c "cd /var/src/ansible && ansible -i clab_inventory.yml sonic_devices -m ping"; then
    echo -e "${GREEN}✓ All nodes responded to Ansible ping${NC}"
else
    echo -e "${YELLOW}⚠ Some nodes may not have responded${NC}"
fi

echo ""

# Test 4: Run a simple command on all nodes
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 4: Execute Command on All Nodes (show version)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

docker exec -u rwang $SONIC_MGMT_CONTAINER bash -c "cd /var/src/ansible && ansible -i clab_inventory.yml sonic_devices -m shell -a 'show version' 2>&1 | head -50" || true

echo ""

# Test 5: Verify inventory file
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 5: Verify Ansible Inventory${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo "Inventory file contents:"
docker exec -u rwang $SONIC_MGMT_CONTAINER bash -c "cat /var/src/ansible/clab_inventory.yml" || true

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  Verification Complete                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

