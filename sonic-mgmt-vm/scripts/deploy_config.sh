#!/bin/bash

# Complete deployment configuration script for t1-small-vm topology
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
echo "  T1-Small-VM Topology Configuration"
echo "========================================="
echo ""

# Function to create sonic-mgmt configuration files
create_sonic_mgmt_configs() {
    echo -e "${BLUE}Creating sonic-mgmt configuration files...${NC}"

    # Create temporary config directory INSIDE sonic-mgmt container
    docker exec clab-t1-small-vm-sonic-mgmt mkdir -p /tmp/sonic-configs

    # Create inventory file INSIDE sonic-mgmt container in /tmp/sonic-configs
    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'cat > /tmp/sonic-configs/inventory.ini << '\''INVENTORY_EOF'\''
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin ansible_password=admin ansible_connection=ssh

[t0]
t0 ansible_host=172.30.30.3 ansible_user=admin ansible_password=admin ansible_connection=ssh

[t2]
t2 ansible_host=172.30.30.2 ansible_user=admin ansible_password=admin ansible_connection=ssh

[ptf]
ptf ansible_host=172.30.30.5 ansible_user=root ansible_password=root ansible_connection=ssh
INVENTORY_EOF'

    # Create testbed.yaml file INSIDE sonic-mgmt container
    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'cat > /tmp/sonic-configs/testbed.yaml << '\''TESTBED_EOF'\''
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
  inv_name: lab
  auto_recover: '\''False'\''
  comment: t1-small-vm topology for sonic-mgmt testing
TESTBED_EOF'

    echo -e "${GREEN}✓ Configuration files created in sonic-mgmt container at /tmp/sonic-configs/${NC}"
    echo "  - inventory.ini"
    echo "  - testbed.yaml"
}

# Function to check docker connectivity
check_docker_connectivity() {
    echo -e "${BLUE}Checking Docker connectivity...${NC}"

    local containers=("clab-t1-small-vm-sonic-dut" "clab-t1-small-vm-t0" "clab-t1-small-vm-t2" "clab-t1-small-vm-ptf" "clab-t1-small-vm-sonic-mgmt")
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

# Function to check sonic-mgmt network connectivity
check_sonic_mgmt_network() {
    echo -e "${BLUE}Checking sonic-mgmt network connectivity...${NC}"

    # Check connectivity to sonic-dut
    if docker exec clab-t1-small-vm-sonic-mgmt ping -c 1 -W 2 172.30.30.4 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} sonic-mgmt → sonic-dut (172.30.30.4)"
    else
        echo -e "  ${RED}✗${NC} sonic-mgmt → sonic-dut (172.30.30.4) - No response"
    fi
}

echo -e "${BLUE}[0/2] Pre-Deployment Checks${NC}"
echo "-------------------------------------------"
check_docker_connectivity
echo ""

echo -e "${BLUE}[1/2] Creating sonic-mgmt Configuration Files${NC}"
echo "-------------------------------------------"
create_sonic_mgmt_configs
echo ""

echo -e "${BLUE}[2/2] Checking sonic-mgmt Connectivity${NC}"
echo "-------------------------------------------"
check_sonic_mgmt_network
echo ""

echo -e "${BLUE}Verification${NC}"
echo "-------------------------------------------"

echo ""
echo "========================================="
echo "  Configuration Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - All containers verified and running"
echo "  - sonic-mgmt configuration files created"
echo ""
echo "sonic-mgmt Configuration Files:"
echo "  - Inventory: /tmp/sonic-configs/inventory.ini"
echo "  - Testbed:   /tmp/sonic-configs/testbed.yaml"
echo ""
echo "Next steps:"
echo "  - Enter sonic-mgmt container:"
echo "    docker exec -it clab-t1-small-vm-sonic-mgmt bash"
echo "  - Copy inventory to ansible:"
echo "    sudo cp /tmp/sonic-configs/inventory.ini /sonic-mgmt/ansible/lab"
echo "  - Run sonic-mgmt tests:"
echo "    cd /sonic-mgmt/tests"
echo "    python -m pytest bgp/test_bgp_fact.py -v \\"
echo "      --testbed /tmp/sonic-configs/testbed.yaml \\"
echo "      --inventory /tmp/sonic-configs/inventory.ini \\"
echo "      --host-pattern sonic-dut"
echo ""

