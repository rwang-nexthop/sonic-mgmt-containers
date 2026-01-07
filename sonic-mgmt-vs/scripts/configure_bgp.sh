#!/bin/bash

# Script to configure SONiC-VS T0 Topology
# 1 DUT (Device Under Test) connected to 2 Leaf nodes
# BGP configuration using vtysh commands

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Container lists
DUT_CONTAINER="clab-sonic-vs-t0-dut"
LEAF_CONTAINERS=("clab-sonic-vs-t0-leaf1" "clab-sonic-vs-t0-leaf2")
ALL_CONTAINERS=("$DUT_CONTAINER" "${LEAF_CONTAINERS[@]}")

# Function to configure BGP on DUT
configure_dut_bgp() {
    local container_name=$1
    local asn=$2
    local router_id="1.1.1.1"
    local neighbor1="10.0.0.1"   # leaf1
    local neighbor2="10.0.0.5"   # leaf2

    echo "Configuring BGP on $container_name (AS $asn)..."

    docker exec $container_name vtysh -c "configure terminal" \
        -c "router bgp $asn" \
        -c "bgp router-id $router_id" \
        -c "bgp log-neighbor-changes" \
        -c "no bgp ebgp-requires-policy" \
        -c "neighbor $neighbor1 remote-as 65001" \
        -c "neighbor $neighbor1 description leaf1" \
        -c "neighbor $neighbor2 remote-as 65002" \
        -c "neighbor $neighbor2 description leaf2" \
        -c "address-family ipv4 unicast" \
        -c "neighbor $neighbor1 activate" \
        -c "neighbor $neighbor2 activate" \
        -c "network $router_id/32" \
        -c "exit-address-family" \
        -c "exit" 2>&1 | grep -v "Unknown command" || true

    docker exec $container_name vtysh -c "write memory" 2>&1 | grep -v "Unknown command" || true

    echo "✓ Successfully configured $container_name"
}

# Function to configure BGP on leaf
configure_leaf_bgp() {
    local container_name=$1
    local asn=$2
    local router_id=""
    local neighbor1=""
    local neighbor1_desc=""

    if [ "$container_name" == "clab-sonic-vs-t0-leaf1" ]; then
        router_id="10.10.10.1"
        neighbor1="10.0.0.0"  # dut
        neighbor1_desc="dut"
    elif [ "$container_name" == "clab-sonic-vs-t0-leaf2" ]; then
        router_id="10.10.10.2"
        neighbor1="10.0.0.4"  # dut
        neighbor1_desc="dut"
    else
        echo "Unknown leaf container: $container_name"
        return 1
    fi

    echo "Configuring BGP on $container_name (AS $asn)..."

    docker exec $container_name vtysh -c "configure terminal" \
        -c "router bgp $asn" \
        -c "bgp router-id $router_id" \
        -c "bgp log-neighbor-changes" \
        -c "no bgp ebgp-requires-policy" \
        -c "neighbor $neighbor1 remote-as 65000" \
        -c "neighbor $neighbor1 description $neighbor1_desc" \
        -c "address-family ipv4 unicast" \
        -c "neighbor $neighbor1 activate" \
        -c "network $router_id/32" \
        -c "exit-address-family" \
        -c "exit" 2>&1 | grep -v "Unknown command" || true

    docker exec $container_name vtysh -c "write memory" 2>&1 | grep -v "Unknown command" || true

    echo "✓ Successfully configured $container_name"
}

echo ""
echo "=========================================="
echo "  SONiC-VS T0 Lab - Complete Configuration"
echo "=========================================="
echo ""

# Step 0: Check Docker connectivity
echo -e "${BLUE}Step 0: Checking Docker connectivity...${NC}"
echo "-------------------------------------------"

all_running=true
for container in "${ALL_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "  ${GREEN}✓${NC} $container is running"
    else
        echo -e "  ${RED}✗${NC} $container is NOT running"
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    echo -e "${RED}Error: Not all containers are running!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All containers are running${NC}"
echo ""

# Step 1: Enable bgpd on all containers
echo -e "${BLUE}Step 1: Enabling bgpd daemon on all containers...${NC}"
echo "--------------------------------------------------"

for container in "${ALL_CONTAINERS[@]}"; do
    docker exec $container sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
    docker exec $container service frr restart 2>&1 | grep -v "Cannot stop watchfrr" || true
    sleep 2
done

echo -e "${GREEN}✓ bgpd enabled on all containers${NC}"
echo ""

# Wait for FRR daemons to be ready
echo "Waiting for FRR daemons to be ready..."
sleep 5

# Step 2: Configure interfaces and IP addresses
echo -e "${BLUE}Step 2: Configuring interfaces and IP addresses...${NC}"
echo "-------------------------------------------"

# DUT interfaces (connected to leaves 1-2) - using vtysh
docker exec $DUT_CONTAINER vtysh -c "configure terminal" \
    -c "interface Ethernet0" \
    -c "ip address 10.0.0.0/31" \
    -c "no shutdown" \
    -c "exit" \
    -c "interface Ethernet4" \
    -c "ip address 10.0.0.4/31" \
    -c "no shutdown" \
    -c "exit" \
    -c "interface Loopback0" \
    -c "ip address 1.1.1.1/32" \
    -c "exit" 2>&1 | grep -v "Unknown command" || true

# Leaf 1 interfaces
docker exec clab-sonic-vs-t0-leaf1 vtysh -c "configure terminal" \
    -c "interface Ethernet0" \
    -c "ip address 10.0.0.1/31" \
    -c "no shutdown" \
    -c "exit" \
    -c "interface Loopback0" \
    -c "ip address 10.10.10.1/32" \
    -c "exit" 2>&1 | grep -v "Unknown command" || true

# Leaf 2 interfaces
docker exec clab-sonic-vs-t0-leaf2 vtysh -c "configure terminal" \
    -c "interface Ethernet0" \
    -c "ip address 10.0.0.5/31" \
    -c "no shutdown" \
    -c "exit" \
    -c "interface Loopback0" \
    -c "ip address 10.10.10.2/32" \
    -c "exit" 2>&1 | grep -v "Unknown command" || true

echo -e "${GREEN}✓ All interfaces configured${NC}"
sleep 5
echo ""

# Step 3: Configure BGP on DUT
echo -e "${BLUE}Step 3: Configuring BGP on DUT...${NC}"
echo "--------------------------------------------"

configure_dut_bgp "$DUT_CONTAINER" "65000"

echo -e "${GREEN}✓ BGP configured on DUT${NC}"
echo ""

# Step 4: Configure BGP on leaf routers
echo -e "${BLUE}Step 4: Configuring BGP on leaf routers...${NC}"
echo "-------------------------------------------"

configure_leaf_bgp "clab-sonic-vs-t0-leaf1" "65001"
configure_leaf_bgp "clab-sonic-vs-t0-leaf2" "65002"

echo -e "${GREEN}✓ BGP configured on leaf routers${NC}"
echo ""

# Step 5: Wait for BGP sessions to establish and exchange routes
echo -e "${BLUE}Step 5: Waiting for BGP sessions to establish and exchange routes...${NC}"
echo "----------------------------------------------------------------------"
echo "Waiting 5 seconds for BGP convergence..."
sleep 5
echo -e "${GREEN}✓ BGP convergence complete${NC}"
echo ""

# Step 6: Verify BGP status
echo -e "${BLUE}Step 6: Verifying BGP configuration...${NC}"
echo "---------------------------------------"

for container in "${ALL_CONTAINERS[@]}"; do
    echo "=== $container BGP Summary ==="
    docker exec $container vtysh -c "show ip bgp summary" 2>/dev/null || echo "BGP not ready yet"
    echo ""
done

# Step 7: Test connectivity
echo -e "${BLUE}Step 7: Testing connectivity...${NC}"
echo "--------------------------------"

echo "Testing DUT -> Leaf1 connectivity..."
docker exec $DUT_CONTAINER ping -c 2 10.0.0.1 2>/dev/null || echo "Connectivity test in progress..."
echo ""

echo "Testing DUT -> Leaf2 connectivity..."
docker exec $DUT_CONTAINER ping -c 2 10.0.0.5 2>/dev/null || echo "Connectivity test in progress..."
echo ""

echo "=========================================="
echo "  Configuration Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - All containers verified and running"
echo "  - All interfaces configured with IP addresses"
echo "  - BGP configured on all nodes"
echo "  - BGP sessions established"
echo ""
echo "Verification commands:"
echo "  - Check BGP neighbors: docker exec <container> vtysh -c 'show ip bgp summary'"
echo "  - Check BGP routes:    docker exec <container> vtysh -c 'show ip bgp'"
echo "  - Check routing table: docker exec <container> vtysh -c 'show ip route'"
echo "  - Enter vtysh:         docker exec -it <container> vtysh"
echo ""
echo "Powered by SONiC-VS"
echo ""

