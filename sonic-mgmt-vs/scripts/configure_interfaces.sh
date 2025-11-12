#!/bin/bash

# Configure interfaces for t1-small topology
# This script configures IP addresses on the SONiC-vs containers

set -e

echo "========================================="
echo "Configuring Interfaces for T1-Small Topology"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to configure SONiC interface
configure_sonic_interface() {
    local container=$1
    local interface=$2
    local ip_addr=$3
    
    echo -e "${YELLOW}Configuring ${container} ${interface} with ${ip_addr}${NC}"
    
    # Bring interface up
    docker exec ${container} ip link set ${interface} up
    
    # Add IP address
    docker exec ${container} ip addr add ${ip_addr} dev ${interface} 2>/dev/null || true
    
    # Verify
    if docker exec ${container} ip addr show ${interface} | grep -q "${ip_addr%/*}"; then
        echo -e "${GREEN}✓ ${container} ${interface} configured successfully${NC}"
    else
        echo -e "${RED}✗ Failed to configure ${container} ${interface}${NC}"
        return 1
    fi
}

echo ""
echo "Step 1: Configuring sonic-dut interfaces..."
echo "-------------------------------------------"
configure_sonic_interface "clab-t1-small-sonic-dut" "eth1" "10.0.0.1/31"
configure_sonic_interface "clab-t1-small-sonic-dut" "eth2" "10.0.0.3/31"
configure_sonic_interface "clab-t1-small-sonic-dut" "eth3" "10.0.0.5/31"
configure_sonic_interface "clab-t1-small-sonic-dut" "eth4" "10.0.0.7/31"

echo ""
echo "Step 2: Configuring t0 interfaces..."
echo "-------------------------------------------"
configure_sonic_interface "clab-t1-small-t0" "eth1" "10.0.0.0/31"
configure_sonic_interface "clab-t1-small-t0" "eth2" "10.0.1.0/31"

echo ""
echo "Step 3: Configuring t2 interfaces..."
echo "-------------------------------------------"
configure_sonic_interface "clab-t1-small-t2" "eth1" "10.0.0.2/31"
configure_sonic_interface "clab-t1-small-t2" "eth2" "10.0.1.1/31"

echo ""
echo "Step 4: Configuring PTF interfaces..."
echo "-------------------------------------------"
configure_sonic_interface "clab-t1-small-ptf" "eth1" "10.0.0.4/31"
configure_sonic_interface "clab-t1-small-ptf" "eth2" "10.0.0.6/31"

echo ""
echo "========================================="
echo "Interface Configuration Complete!"
echo "========================================="
echo ""
echo "Verification:"
echo "-------------------------------------------"

# Test connectivity
echo "Testing connectivity from t0 to sonic-dut..."
if docker exec clab-t1-small-t0 ping -c 2 -W 2 10.0.0.1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ t0 → sonic-dut (10.0.0.1) - SUCCESS${NC}"
else
    echo -e "${YELLOW}⚠ t0 → sonic-dut (10.0.0.1) - No response (BGP may not be configured yet)${NC}"
fi

echo "Testing connectivity from t2 to sonic-dut..."
if docker exec clab-t1-small-t2 ping -c 2 -W 2 10.0.0.3 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ t2 → sonic-dut (10.0.0.3) - SUCCESS${NC}"
else
    echo -e "${YELLOW}⚠ t2 → sonic-dut (10.0.0.3) - No response (BGP may not be configured yet)${NC}"
fi

echo "Testing connectivity from t0 to t2..."
if docker exec clab-t1-small-t0 ping -c 2 -W 2 10.0.1.1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ t0 → t2 (10.0.1.1) - SUCCESS${NC}"
else
    echo -e "${YELLOW}⚠ t0 → t2 (10.0.1.1) - No response${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Configure BGP: ./configure_bgp.sh"
echo "  2. Verify topology: ./verify_topology.sh"
echo ""

