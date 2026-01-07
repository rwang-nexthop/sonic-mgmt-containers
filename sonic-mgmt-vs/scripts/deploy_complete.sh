#!/bin/bash

# Complete deployment script for SONiC-VS T0 topology with 2 leafs
# This script deploys the topology, configures BGP, enables SSH, and sets up sonic-mgmt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Step 1: Deploy topology (configs are applied automatically via startup-config)
log_step "STEP 1: Deploying SONiC-VS T0 Topology (2 leafs)"
cd "$PROJECT_DIR"
sudo containerlab deploy -t sonic-vs-t0.clab.yml
log_info "Topology deployed successfully with configurations applied"
sleep 5

# Step 2: Enable SSH on leaf nodes
log_step "STEP 2: Enabling SSH on leaf nodes"
cd "$SCRIPT_DIR"
bash enable_ssh_on_leafs.sh
log_info "SSH enabled on leaf nodes"
sleep 5

# Step 3: Setup DUT SSH
log_step "STEP 3: Setting up SSH on DUT"
bash setup_dut_ssh.sh
log_info "DUT SSH setup completed"
sleep 5

# Step 4: Setup sonic-mgmt container
log_step "STEP 4: Setting up sonic-mgmt container"
cd "$PROJECT_DIR/sonic-mgmt-master"
./setup-container.sh -n sonic-mgmt-test -d /var/src -m "$PROJECT_DIR"
log_info "sonic-mgmt container created"
sleep 5

# Step 5: Setup Ansible
log_step "STEP 5: Setting up Ansible"
cd "$SCRIPT_DIR"
bash setup_ansible.sh
log_info "Ansible setup completed"

# Step 6: Verify Ansible connectivity
log_step "STEP 6: Verifying Ansible Connectivity"
cd "$SCRIPT_DIR"
bash verify_ansible_connectivity.sh
log_info "Ansible connectivity verification completed"

# Step 7: Final status check
log_step "STEP 7: Final Status Check"
echo ""
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "sonic-mgmt-test|clab-sonic-vs-t0"
echo ""
echo "Network Connectivity:"
docker exec -u rwang sonic-mgmt-test bash -c "ping -c 1 172.20.20.2 && echo '✓ DUT reachable'"
docker exec -u rwang sonic-mgmt-test bash -c "ping -c 1 172.20.20.11 && echo '✓ Leaf1 reachable'"
docker exec -u rwang sonic-mgmt-test bash -c "ping -c 1 172.20.20.12 && echo '✓ Leaf2 reachable'"

log_step "DEPLOYMENT COMPLETE!"
echo ""
echo "✅ All nodes are configured and ready for testing!"
echo ""
echo "Next steps:"
echo "1. Access sonic-mgmt container: docker exec -u rwang -it sonic-mgmt-test bash"
echo "2. Run tests: cd /var/src/tests && python -m pytest bgp/test_bgp_fact.py -v"
echo "3. Check Ansible: cd /var/src/ansible && ansible -i clab_inventory.yml sonic_devices -m ping"
echo ""

