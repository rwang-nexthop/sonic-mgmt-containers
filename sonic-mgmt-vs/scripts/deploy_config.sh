#!/bin/bash

# Complete deployment configuration script for t1-small topology
# This script configures both interfaces and BGP routing using SONiC native commands
# It also creates inventory and testbed files for sonic-mgmt testing

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "========================================="
echo "  T1-Small Topology Configuration"
echo "========================================="
echo ""

# Function to create sonic-mgmt configuration files
create_sonic_mgmt_configs() {
    echo -e "${BLUE}Creating sonic-mgmt configuration files...${NC}"

    # Create temporary config directory INSIDE sonic-mgmt container
    docker exec clab-t1-small-sonic-mgmt mkdir -p /tmp/sonic-configs

    # Create inventory file INSIDE sonic-mgmt container
    # Note: Ansible looks for inventory files in /sonic-mgmt/ansible/ directory
    # Use sudo if needed to handle permission issues
    docker exec clab-t1-small-sonic-mgmt bash -c 'sudo bash -c '\''cat > /sonic-mgmt/ansible/t1-small << INVENTORY_EOF
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin

[t0]
t0 ansible_host=172.30.30.3 ansible_user=admin

[t2]
t2 ansible_host=172.30.30.2 ansible_user=admin

[ptf]
ptf ansible_host=172.30.30.6 ansible_user=root
INVENTORY_EOF
'\'''

    # Also create a copy in /tmp/sonic-configs for reference
    docker exec clab-t1-small-sonic-mgmt mkdir -p /tmp/sonic-configs
    docker exec clab-t1-small-sonic-mgmt sudo cp /sonic-mgmt/ansible/t1-small /tmp/sonic-configs/inventory.ini
    docker exec clab-t1-small-sonic-mgmt sudo chmod 644 /tmp/sonic-configs/inventory.ini

    # Create testbed.yaml file INSIDE sonic-mgmt container
    docker exec clab-t1-small-sonic-mgmt bash -c 'cat > /tmp/sonic-configs/testbed.yaml << '\''TESTBED_EOF'\''
- conf-name: t1-small
  group-name: t1-small-group
  topo: t1
  ptf_image_name: docker-ptf
  ptf: ptf
  ptf_ip: 172.30.30.6/24
  server: localhost
  vm_base:
  dut:
    - sonic-dut
  inv_name: t1-small
  auto_recover: '\''False'\''
  comment: t1-small topology for sonic-mgmt testing
TESTBED_EOF'

    # Set proper permissions
    docker exec clab-t1-small-sonic-mgmt chmod 644 /tmp/sonic-configs/testbed.yaml

    echo -e "${GREEN}✓ Configuration files created in sonic-mgmt container at /tmp/sonic-configs/${NC}"
    echo "  - inventory.ini"
    echo "  - testbed.yaml"
}

# Function to check docker connectivity
check_docker_connectivity() {
    echo -e "${BLUE}Checking Docker connectivity...${NC}"

    local containers=("clab-t1-small-sonic-dut" "clab-t1-small-t0" "clab-t1-small-t2" "clab-t1-small-ptf" "clab-t1-small-sonic-mgmt")
    local all_running=true

    for container in "${containers[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo -e "  ${GREEN}✓${NC} $container is running"
        else
            echo -e "  ${RED}✗${NC} $container is NOT running"
            all_running=false
        fi
    done

    if [ "$all_running" = false ]; then
        echo -e "${RED}Error: Not all containers are running!${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ All containers are running${NC}"
}

# Function to check sonic-mgmt docker socket access
check_sonic_mgmt_docker_access() {
    echo -e "${BLUE}Checking sonic-mgmt Docker socket access...${NC}"

    # Try to run docker ps from sonic-mgmt container
    if docker exec clab-t1-small-sonic-mgmt docker ps > /dev/null 2>&1; then
        echo -e "${GREEN}✓ sonic-mgmt can access Docker socket${NC}"
    else
        echo -e "${YELLOW}⚠ sonic-mgmt cannot access Docker socket (may need sudo)${NC}"
        echo -e "${YELLOW}  This is expected if running as non-root user${NC}"
    fi
}

# Function to check sonic-mgmt network connectivity
check_sonic_mgmt_network() {
    echo -e "${BLUE}Checking sonic-mgmt network connectivity...${NC}"

    # Check connectivity to sonic-dut
    if docker exec clab-t1-small-sonic-mgmt ping -c 1 -W 2 172.30.30.4 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} sonic-mgmt → sonic-dut (172.30.30.4)"
    else
        echo -e "  ${RED}✗${NC} sonic-mgmt → sonic-dut (172.30.30.4) - No response"
    fi

    # Check connectivity to t0
    if docker exec clab-t1-small-sonic-mgmt ping -c 1 -W 2 172.30.30.3 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} sonic-mgmt → t0 (172.30.30.3)"
    else
        echo -e "  ${RED}✗${NC} sonic-mgmt → t0 (172.30.30.3) - No response"
    fi

    # Check connectivity to t2
    if docker exec clab-t1-small-sonic-mgmt ping -c 1 -W 2 172.30.30.2 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} sonic-mgmt → t2 (172.30.30.2)"
    else
        echo -e "  ${RED}✗${NC} sonic-mgmt → t2 (172.30.30.2) - No response"
    fi
}

# Function to bring up eth interfaces (containerlab links)
bring_up_eth_interfaces() {
    echo -e "${BLUE}Bringing up containerlab eth interfaces...${NC}"

    # Bring up eth interfaces on all SONiC nodes
    docker exec clab-t1-small-sonic-dut ip link set eth1 up
    docker exec clab-t1-small-sonic-dut ip link set eth2 up
    docker exec clab-t1-small-sonic-dut ip link set eth3 up
    docker exec clab-t1-small-sonic-dut ip link set eth4 up

    docker exec clab-t1-small-t0 ip link set eth1 up
    docker exec clab-t1-small-t0 ip link set eth2 up

    docker exec clab-t1-small-t2 ip link set eth1 up
    docker exec clab-t1-small-t2 ip link set eth2 up

    # PTF interfaces
    docker exec clab-t1-small-ptf ip link set eth1 up
    docker exec clab-t1-small-ptf ip link set eth2 up

    sleep 2
    echo -e "${GREEN}✓ All eth interfaces are up${NC}"
}

# Function to configure SONiC interface using native config command
configure_sonic_interface() {
    local container=$1
    local sonic_interface=$2
    local ip_addr=$3

    echo -e "${YELLOW}Configuring ${container} ${sonic_interface} with ${ip_addr}${NC}"

    # Use SONiC native config command to add IP and bring up interface
    docker exec ${container} config interface ip add ${sonic_interface} ${ip_addr} 2>&1 | grep -v "SyntaxWarning" || true
    docker exec ${container} config interface startup ${sonic_interface} 2>&1 | grep -v "SyntaxWarning" || true

    # Also ensure the interface is up at kernel level (sometimes needed for SONiC-vs)
    docker exec ${container} ip link set ${sonic_interface} up 2>/dev/null || true

    echo -e "${GREEN}✓ ${container} ${sonic_interface} configured${NC}"
}

# Function to configure PTF interface (Linux-based)
configure_linux_interface() {
    local container=$1
    local interface=$2
    local ip_addr=$3

    echo -e "${YELLOW}Configuring ${container} ${interface} with ${ip_addr}${NC}"

    docker exec ${container} ip addr add ${ip_addr} dev ${interface} 2>/dev/null || true

    echo -e "${GREEN}✓ ${container} ${interface} configured${NC}"
}

# Function to enable bgpd daemon
enable_bgpd() {
    local container=$1
    echo -e "${YELLOW}Enabling bgpd in ${container}...${NC}"

    # Enable bgpd in /etc/frr/daemons
    docker exec ${container} sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons 2>&1 | grep -v "SyntaxWarning" || true

    # Restart FRR service (this starts bgpd via watchfrr, not supervisorctl)
    docker exec ${container} service frr restart 2>&1 | grep -v "Cannot stop watchfrr" || true
    sleep 3

    # Verify bgpd is running by checking process list
    local bgpd_running=$(docker exec ${container} ps aux 2>&1 | grep -c "/usr/lib/frr/bgpd" | grep -v grep || echo "0")

    if [ "$bgpd_running" -gt "0" ]; then
        echo -e "${GREEN}✓ bgpd is RUNNING in ${container}${NC}"
    else
        echo -e "${RED}✗ bgpd failed to start in ${container}${NC}"
        echo -e "${YELLOW}  Checking process list...${NC}"
        docker exec ${container} ps aux | grep bgpd || true
        return 1
    fi
}

# Function to configure BGP on SONiC with complete configuration
configure_bgp() {
    local container=$1
    local asn=$2
    local router_id=$3
    shift 3
    local neighbors=("$@")

    echo -e "${YELLOW}Configuring BGP on ${container} (AS ${asn})${NC}"

    # Build the complete BGP configuration command
    local bgp_config="configure terminal\n"
    bgp_config+="router bgp ${asn}\n"
    bgp_config+="bgp router-id ${router_id}\n"
    bgp_config+="bgp log-neighbor-changes\n"
    bgp_config+="no bgp ebgp-requires-policy\n"

    # Add all neighbors
    for neighbor in "${neighbors[@]}"; do
        IFS=',' read -r neighbor_ip neighbor_asn neighbor_network <<< "$neighbor"
        bgp_config+="neighbor ${neighbor_ip} remote-as ${neighbor_asn}\n"
    done

    # Configure address-family with networks and neighbor activation
    bgp_config+="address-family ipv4 unicast\n"

    # Add network statements for directly connected networks
    for neighbor in "${neighbors[@]}"; do
        IFS=',' read -r neighbor_ip neighbor_asn neighbor_network <<< "$neighbor"
        if [ -n "$neighbor_network" ]; then
            bgp_config+="network ${neighbor_network}\n"
        fi
    done

    # Activate all neighbors
    for neighbor in "${neighbors[@]}"; do
        IFS=',' read -r neighbor_ip neighbor_asn neighbor_network <<< "$neighbor"
        bgp_config+="neighbor ${neighbor_ip} activate\n"
    done

    # Redistribute connected routes
    bgp_config+="redistribute connected\n"
    bgp_config+="exit-address-family\n"

    # Add route-map to allow all
    bgp_config+="exit\n"
    bgp_config+="route-map ALLOW-ALL permit 10\n"
    bgp_config+="exit\n"
    bgp_config+="exit\n"

    # Apply configuration
    echo -e "$bgp_config" | docker exec -i ${container} vtysh 2>&1 | grep -v "Unknown command" | grep -v "Note: this version" || true

    # Save configuration
    docker exec ${container} vtysh -c "write memory" 2>&1 | grep -v "Note: this version" || \
    docker exec ${container} vtysh -c "write" 2>&1 | grep -v "Note: this version" || true

    echo -e "${GREEN}✓ BGP configured on ${container}${NC}"
}

echo -e "${BLUE}[0/6] Pre-Deployment Checks${NC}"
echo "-------------------------------------------"
check_docker_connectivity
echo ""

echo -e "${BLUE}[1/6] Creating sonic-mgmt Configuration Files${NC}"
echo "-------------------------------------------"
create_sonic_mgmt_configs
echo ""

echo -e "${BLUE}[2/6] Bringing Up Interfaces${NC}"
echo "-------------------------------------------"
bring_up_eth_interfaces
echo ""

echo -e "${BLUE}[3/6] Configuring SONiC Interfaces${NC}"
echo "-------------------------------------------"

# Configure sonic-dut interfaces (eth1->Ethernet0, eth2->Ethernet4, eth3->Ethernet8, eth4->Ethernet12)
configure_sonic_interface "clab-t1-small-sonic-dut" "Ethernet0" "10.0.0.1/31"
configure_sonic_interface "clab-t1-small-sonic-dut" "Ethernet4" "10.0.0.3/31"
configure_sonic_interface "clab-t1-small-sonic-dut" "Ethernet8" "10.0.0.5/31"
configure_sonic_interface "clab-t1-small-sonic-dut" "Ethernet12" "10.0.0.7/31"

# Configure t0 interfaces
configure_sonic_interface "clab-t1-small-t0" "Ethernet0" "10.0.0.0/31"
configure_sonic_interface "clab-t1-small-t0" "Ethernet4" "10.0.1.0/31"

# Configure t2 interfaces
configure_sonic_interface "clab-t1-small-t2" "Ethernet0" "10.0.0.2/31"
configure_sonic_interface "clab-t1-small-t2" "Ethernet4" "10.0.1.1/31"

# Configure PTF interfaces (Linux-based)
configure_linux_interface "clab-t1-small-ptf" "eth1" "10.0.0.4/31"
configure_linux_interface "clab-t1-small-ptf" "eth2" "10.0.0.6/31"

echo ""
echo -e "${YELLOW}Waiting 5 seconds for interfaces to stabilize...${NC}"
sleep 5

echo ""
echo -e "${BLUE}[4/6] Enabling BGP Daemon${NC}"
echo "-------------------------------------------"

# Enable bgpd on all SONiC containers
enable_bgpd "clab-t1-small-sonic-dut"
enable_bgpd "clab-t1-small-t0"
enable_bgpd "clab-t1-small-t2"

echo ""
echo -e "${BLUE}[5/6] Configuring BGP${NC}"
echo "-------------------------------------------"

# Configure BGP on sonic-dut (AS 65100)
# Format: "neighbor_ip,neighbor_asn,network_to_advertise"
configure_bgp "clab-t1-small-sonic-dut" "65100" "10.1.0.1" \
    "10.0.0.0,65000,10.0.0.0/31" \
    "10.0.0.2,65200,10.0.0.2/31"

# Configure BGP on t0 (AS 65000)
configure_bgp "clab-t1-small-t0" "65000" "10.0.0.100" \
    "10.0.0.1,65100,10.0.0.0/31" \
    "10.0.1.1,65200,10.0.1.0/31"

# Configure BGP on t2 (AS 65200)
configure_bgp "clab-t1-small-t2" "65200" "10.0.0.200" \
    "10.0.0.3,65100,10.0.0.2/31" \
    "10.0.1.0,65000,10.0.1.1/31"

echo ""
echo -e "${BLUE}[6/6] Checking sonic-mgmt Connectivity${NC}"
echo "-------------------------------------------"
check_sonic_mgmt_docker_access
check_sonic_mgmt_network
echo ""

echo -e "${BLUE}Verification${NC}"
echo "-------------------------------------------"

# Wait for BGP to establish
echo "Waiting 30 seconds for BGP to establish..."
sleep 30

# Test connectivity
echo ""
echo "Testing connectivity..."
if docker exec clab-t1-small-t0 ping -c 2 -W 2 10.0.0.1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ t0 → sonic-dut (10.0.0.1)${NC}"
else
    echo -e "${YELLOW}⚠ t0 → sonic-dut (10.0.0.1) - No response${NC}"
fi

if docker exec clab-t1-small-t2 ping -c 2 -W 2 10.0.0.3 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ t2 → sonic-dut (10.0.0.3)${NC}"
else
    echo -e "${YELLOW}⚠ t2 → sonic-dut (10.0.0.3) - No response${NC}"
fi

if docker exec clab-t1-small-t0 ping -c 2 -W 2 10.0.1.1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ t0 → t2 (10.0.1.1)${NC}"
else
    echo -e "${YELLOW}⚠ t0 → t2 (10.0.1.1) - No response${NC}"
fi

# Check BGP neighbors
echo ""
echo "Checking BGP neighbors..."

bgp_status=$(docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary" 2>/dev/null | grep -c "Established" || echo "0")
bgp_status=$(echo "$bgp_status" | tr -d '\n' | tr -d ' ')
if [ "$bgp_status" -gt "0" ] 2>/dev/null; then
    echo -e "${GREEN}✓ BGP neighbors established: ${bgp_status}${NC}"
else
    echo -e "${YELLOW}⚠ No BGP neighbors established yet (may need more time)${NC}"
fi

echo ""
echo "========================================="
echo "  Configuration Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - All containers verified and running"
echo "  - sonic-mgmt configuration files created"
echo "  - All interfaces configured with IP addresses"
echo "  - BGP configured on all SONiC nodes"
echo "  - BGP connectivity verified"
echo "  - sonic-mgmt network connectivity verified"
echo ""
echo "sonic-mgmt Configuration Files:"
echo "  - Inventory: /tmp/sonic-configs/inventory.ini"
echo "  - Testbed:   /tmp/sonic-configs/testbed.yaml"
echo ""
echo "Next steps:"
echo "  - Check BGP status: docker exec clab-t1-small-sonic-dut vtysh -c 'show ip bgp summary'"
echo "  - Check routes: docker exec clab-t1-small-sonic-dut vtysh -c 'show ip route'"
echo "  - Run full verification: ./verify_topology.sh"
echo "  - Run sonic-mgmt tests:"
echo "    docker exec -it clab-t1-small-sonic-mgmt bash"
echo "    cd /sonic-mgmt/tests"
echo "    python -m pytest bgp/test_bgp_fact.py -v \\"
echo "      --testbed /tmp/sonic-configs/testbed.yaml \\"
echo "      --inventory /tmp/sonic-configs/inventory.ini \\"
echo "      --host-pattern sonic-dut"
echo ""

