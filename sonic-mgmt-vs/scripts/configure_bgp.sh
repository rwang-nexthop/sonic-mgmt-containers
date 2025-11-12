#!/bin/bash

# Script to configure BGP on all SONiC containers in t1-small topology
# This script enables BGP route redistribution for connected routes

set -e

# Container names
CONTAINERS=("clab-t1-small-sonic-dut" "clab-t1-small-t0" "clab-t1-small-t2")

# AS numbers for each container
declare -A AS_NUMBERS
AS_NUMBERS["clab-t1-small-sonic-dut"]="65100"
AS_NUMBERS["clab-t1-small-t0"]="65000"
AS_NUMBERS["clab-t1-small-t2"]="65200"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "BGP Configuration Script for t1-small"
echo "=========================================="
echo ""

# Function to wait for SONiC to be ready
wait_for_sonic() {
    local container=$1
    local max_attempts=30
    local attempt=0

    echo -n "Waiting for $container to be ready..."
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec "$container" vtysh -c "show version" &>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done
    
    echo -e " ${RED}✗${NC}"
    echo -e "${RED}Error: $container did not become ready in time${NC}"
    return 1
}

# Function to configure BGP on a container
configure_bgp() {
    local container=$1
    local asn=${AS_NUMBERS[$container]}
    
    echo -e "${YELLOW}Configuring BGP on $container (AS $asn)...${NC}"
    
    # Configure BGP to redistribute connected routes
    docker exec "$container" vtysh << EOF
configure terminal
router bgp $asn
address-family ipv4 unicast
redistribute connected
exit
exit
write memory
exit
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully configured $container${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to configure $container${NC}"
        return 1
    fi
}

# Function to verify BGP status
verify_bgp() {
    local container=$1
    echo -e "${YELLOW}Verifying BGP on $container...${NC}"
    
    docker exec "$container" vtysh -c "show ip bgp summary"
    echo ""
}

# Main execution
main() {
    local failed=0
    
    # Wait for all containers to be ready
    echo "Step 1: Waiting for SONiC containers to boot..."
    for container in "${CONTAINERS[@]}"; do
        if ! wait_for_sonic "$container"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -gt 0 ]; then
        echo -e "${RED}Some containers failed to start. Exiting.${NC}"
        exit 1
    fi
    
    echo ""
    echo "Step 2: Configuring BGP on all containers..."
    for container in "${CONTAINERS[@]}"; do
        configure_bgp "$container"
        echo ""
    done
    
    echo ""
    echo "Step 3: Verifying BGP configuration..."
    for container in "${CONTAINERS[@]}"; do
        verify_bgp "$container"
    done
    
    echo "=========================================="
    echo -e "${GREEN}BGP configuration complete!${NC}"
    echo "=========================================="
}

# Run main function
main

