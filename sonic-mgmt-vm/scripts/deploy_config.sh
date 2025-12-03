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
    # Note: IP addresses are assigned by containerlab in order of node definition
    # sonic-dut: 172.30.30.5 (first sonic-vm node)
    # t0: 172.30.30.6 (second sonic-vm node)
    # t2: 172.30.30.3 (third sonic-vm node)
    # ptf: 172.30.30.2 (first linux node)
    # sonic-mgmt: 172.30.30.4 (second linux node)
    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'cat > /tmp/sonic-configs/inventory.ini << '\''INVENTORY_EOF'\''
[sonic]
sonic-dut ansible_host=172.30.30.5 ansible_user=admin ansible_password=admin ansible_connection=ssh ansible_become=yes ansible_become_method=sudo ansible_become_user=root ansible_become_pass=admin

[t0]
t0 ansible_host=172.30.30.6 ansible_user=admin ansible_password=admin ansible_connection=ssh ansible_become=yes ansible_become_method=sudo ansible_become_user=root ansible_become_pass=admin

[t2]
t2 ansible_host=172.30.30.3 ansible_user=admin ansible_password=admin ansible_connection=ssh ansible_become=yes ansible_become_method=sudo ansible_become_user=root ansible_become_pass=admin

[ptf]
ptf ansible_host=172.30.30.2 ansible_user=root ansible_password=root ansible_connection=ssh
INVENTORY_EOF'

    # Create testbed.yaml file INSIDE sonic-mgmt container
    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'cat > /tmp/sonic-configs/testbed.yaml << '\''TESTBED_EOF'\''
- conf-name: t1-small
  group-name: t1-small-group
  topo: t1
  topo_name: t1-small-vm
  ptf_image_name: docker-ptf
  ptf: ptf
  ptf_ip: 172.30.30.2/24
  server: localhost
  vm_base:
  dut:
    - sonic-dut
  inv_name: lab
  auto_recover: '\''False'\''
  neighbor_type: sonic
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

# Function to fix cache permissions
fix_cache_permissions() {
    echo -e "${BLUE}Fixing cache permissions...${NC}"

    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'chmod -R 777 /sonic-mgmt/tests/.pytest_cache 2>/dev/null || true'
    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'chmod -R 777 /sonic-mgmt/tests/_cache 2>/dev/null || true'

    echo -e "${GREEN}✓ Cache permissions fixed${NC}"
}

# Function to create ansible.cfg
create_ansible_config() {
    echo -e "${BLUE}Creating ansible.cfg...${NC}"

    docker exec clab-t1-small-vm-sonic-mgmt bash -c 'sudo bash -c '\''cat > /sonic-mgmt/ansible/ansible.cfg << ANSIBLE_EOF
[defaults]
library = /sonic-mgmt/tests/library:/sonic-mgmt/ansible/library
host_key_checking = False
deprecation_warnings = False
inventory = /sonic-mgmt/ansible/lab
ANSIBLE_EOF
'\'''

    echo -e "${GREEN}✓ ansible.cfg created${NC}"
}

# Function to sync inventory into /sonic-mgmt/ansible/lab with correct IPs
sync_inventory_to_ansible() {
    echo -e "${BLUE}Syncing Ansible inventory inside sonic-mgmt...${NC}"

    docker exec clab-t1-small-vm-sonic-mgmt bash -c '
set -e
sudo mkdir -p /sonic-mgmt/ansible

# Copy generated inventory to ansible directory
sudo cp /tmp/sonic-configs/inventory.ini /sonic-mgmt/ansible/lab

# Ensure sonic-dut has correct IP (172.30.30.5)
sudo sed -i "s/sonic-dut[[:space:]]\+ansible_host=172\.30\.30\.4/sonic-dut ansible_host=172.30.30.5/" /sonic-mgmt/ansible/lab || true

# Verify sonic-dut has correct IP
if grep -q "sonic-dut.*ansible_host=172\.30\.30\.5" /sonic-mgmt/ansible/lab; then
  echo "✓ sonic-dut correctly configured at 172.30.30.5"
else
  echo "✗ Warning: sonic-dut IP may not be correct"
fi
'

    echo -e "${GREEN}✓ Inventory synced to /sonic-mgmt/ansible/lab${NC}"
}


# Function to check sonic-mgmt network connectivity
check_sonic_mgmt_network() {
    echo -e "${BLUE}Checking sonic-mgmt network connectivity...${NC}"

    # Check connectivity to sonic-dut (172.30.30.5)
    if docker exec clab-t1-small-vm-sonic-mgmt ping -c 1 -W 2 172.30.30.5 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} sonic-mgmt → sonic-dut (172.30.30.5)"
    else
        echo -e "  ${RED}✗${NC} sonic-mgmt → sonic-dut (172.30.30.5) - No response"
    fi
}

echo -e "${BLUE}[0/5] Pre-Deployment Checks${NC}"
echo "-------------------------------------------"
check_docker_connectivity
echo ""

echo -e "${BLUE}[1/5] Creating sonic-mgmt Configuration Files${NC}"
echo "-------------------------------------------"
create_sonic_mgmt_configs
echo ""

echo -e "${BLUE}[2/5] Fixing Cache Permissions${NC}"
echo "-------------------------------------------"
fix_cache_permissions
echo ""

echo -e "${BLUE}[3/5] Creating Ansible Configuration${NC}"
echo "-------------------------------------------"
create_ansible_config
echo ""

echo -e "${BLUE}[4/5] Syncing Ansible Inventory${NC}"
echo "-------------------------------------------"
sync_inventory_to_ansible
echo ""

echo -e "${BLUE}[5/5] Checking sonic-mgmt Connectivity${NC}"
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
echo "  - Cache permissions fixed"
echo "  - Ansible configuration created"
echo ""
echo "sonic-mgmt Configuration Files:"
echo "  - Inventory:   /tmp/sonic-configs/inventory.ini"
echo "  - Testbed:     /tmp/sonic-configs/testbed.yaml"
echo "  - Ansible cfg: /sonic-mgmt/ansible/ansible.cfg"
echo ""
echo "Next steps:"
echo "  1. Verify Ansible connectivity:"
echo "     docker exec -it clab-t1-small-vm-sonic-mgmt bash"
echo "     ansible -i /sonic-mgmt/ansible/lab sonic-dut -m ping"
echo ""
echo "  2. Run sonic-mgmt tests:"
echo "     cd /sonic-mgmt/tests"
echo "     python -m pytest bgp/test_bgp_fact.py -v \\"
echo "       --testbed /tmp/sonic-configs/testbed.yaml \\"
echo "       --inventory /tmp/sonic-configs/inventory.ini \\"
echo "       --host-pattern sonic-dut"
echo ""

