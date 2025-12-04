#!/bin/bash

# BGP Verification Script for t1-small-vm topology
# Verifies BGP neighbor establishment, route propagation, and connectivity
# Uses SSH to connect to sonic-vm containers (not docker exec)

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# SSH connection details for sonic-vm nodes
declare -A NODE_IPS
NODE_IPS["sonic-dut"]="172.30.30.5"
NODE_IPS["t0"]="172.30.30.6"
NODE_IPS["t2"]="172.30.30.3"

# Expected BGP neighbors per node
declare -A EXPECTED_NEIGHBORS
EXPECTED_NEIGHBORS["sonic-dut"]="2"
EXPECTED_NEIGHBORS["t0"]="2"
EXPECTED_NEIGHBORS["t2"]="2"

echo ""
echo "=========================================="
echo "  BGP Verification Script - t1-small-vm"
echo "=========================================="
echo ""

# Step 1: Check SSH connectivity to nodes
echo -e "${BLUE}[1/5] Checking SSH connectivity to nodes...${NC}"
echo "-------------------------------------------"

all_reachable=true
for node in "${!NODE_IPS[@]}"; do
    ip=${NODE_IPS[$node]}
    if sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 admin@$ip 'echo' > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $node ($ip) is reachable"
    else
        echo -e "  ${RED}✗${NC} $node ($ip) is NOT reachable"
        all_reachable=false
    fi
done

if [ "$all_reachable" = false ]; then
    echo -e "${RED}Error: Not all nodes are reachable!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All nodes are reachable${NC}"
echo ""

# Step 2: Check BGP neighbor status
echo -e "${BLUE}[2/5] Checking BGP neighbor status...${NC}"
echo "-------------------------------------------"

bgp_established=0
for node in "${!NODE_IPS[@]}"; do
    ip=${NODE_IPS[$node]}
    echo -e "${YELLOW}$node BGP Summary:${NC}"
    sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$ip \
        'vtysh -c "show ip bgp summary"' 2>/dev/null || echo "  BGP not ready yet"

    # Count established neighbors
    established=$(sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$ip \
        'vtysh -c "show ip bgp summary"' 2>/dev/null | grep -c "Established" || echo "0")
    expected=${EXPECTED_NEIGHBORS[$node]}

    if [ "$established" -eq "$expected" ]; then
        echo -e "  ${GREEN}✓ BGP neighbors established: $established/$expected${NC}"
        ((bgp_established++))
    else
        echo -e "  ${YELLOW}⚠ BGP neighbors: $established/$expected (may need more time)${NC}"
    fi
    echo ""
done

echo ""

# Step 3: Check BGP routes
echo -e "${BLUE}[3/5] Checking BGP routes...${NC}"
echo "-------------------------------------------"

for node in "${!NODE_IPS[@]}"; do
    ip=${NODE_IPS[$node]}
    echo -e "${YELLOW}$node BGP Routes:${NC}"
    sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$ip \
        'vtysh -c "show ip bgp"' 2>/dev/null | head -15 || echo "  Routes not ready yet"
    echo ""
done

echo ""

# Step 4: Test connectivity between nodes
echo -e "${BLUE}[4/5] Testing connectivity between nodes...${NC}"
echo "-------------------------------------------"

connectivity_pass=0
total_tests=0

# Test sonic-dut to t0
echo -e "${YELLOW}Test: sonic-dut → t0 (10.0.0.1)${NC}"
if sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@172.30.30.5 \
    'ping -c 2 -W 2 10.0.0.1' > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((connectivity_pass++))
else
    echo -e "  ${RED}✗ FAIL${NC}"
fi
((total_tests++))
echo ""

# Test sonic-dut to t2
echo -e "${YELLOW}Test: sonic-dut → t2 (10.0.0.3)${NC}"
if sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@172.30.30.5 \
    'ping -c 2 -W 2 10.0.0.3' > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((connectivity_pass++))
else
    echo -e "  ${RED}✗ FAIL${NC}"
fi
((total_tests++))
echo ""

# Test loopback connectivity
echo -e "${YELLOW}Test: sonic-dut loopback → t0 loopback (10.0.0.100)${NC}"
if sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@172.30.30.5 \
    'ping -c 2 -W 2 10.0.0.100' > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((connectivity_pass++))
else
    echo -e "  ${RED}✗ FAIL${NC}"
fi
((total_tests++))
echo ""

# Step 5: Summary
echo -e "${BLUE}[5/5] Verification Summary${NC}"
echo "-------------------------------------------"

echo -e "BGP Neighbors Established: ${GREEN}$bgp_established/3${NC}"
echo -e "Connectivity Tests Passed: ${GREEN}$connectivity_pass/$total_tests${NC}"
echo ""

if [ "$bgp_established" -eq 3 ] && [ "$connectivity_pass" -eq "$total_tests" ]; then
    echo -e "${GREEN}✓ All BGP verification checks PASSED!${NC}"
    echo ""
    echo "=========================================="
    echo "  Verification Complete - SUCCESS"
    echo "=========================================="
    exit 0
else
    echo -e "${YELLOW}⚠ Some checks did not pass. This may be normal if BGP is still converging.${NC}"
    echo -e "${YELLOW}  Wait 30-60 seconds and run this script again.${NC}"
    echo ""
    echo "=========================================="
    echo "  Verification Complete - PARTIAL"
    echo "=========================================="
    exit 1
fi

