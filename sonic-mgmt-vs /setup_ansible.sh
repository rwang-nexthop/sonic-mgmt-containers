#!/bin/bash

# Setup Ansible for Containerlab Topology
# This script configures Ansible inventory and SSH access

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SONIC_MGMT_DIR="${SCRIPT_DIR}/sonic-mgmt-master"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if sonic-mgmt container is running
check_container() {
    if ! docker ps | grep -q sonic-mgmt-test; then
        log_error "sonic-mgmt-test container is not running"
        log_info "Start it with: ./setup-container.sh -n sonic-mgmt-test -d /var/src"
        exit 1
    fi
    log_info "sonic-mgmt-test container is running"
}

# Create Ansible inventory
create_inventory() {
    log_info "Creating Ansible inventory..."
    
    docker exec sonic-mgmt-test bash -c "
    cat > /var/src/ansible/clab_inventory.yml << 'EOF'
all:
  children:
    sonic_devices:
      hosts:
        dut:
          ansible_host: 172.20.20.2
          ansible_user: admin
          ansible_password: YourPassword
          ansible_network_os: sonic
        leaf1:
          ansible_host: 172.20.20.11
          ansible_user: admin
          ansible_password: YourPassword
          ansible_network_os: sonic
        leaf2:
          ansible_host: 172.20.20.12
          ansible_user: admin
          ansible_password: YourPassword
          ansible_network_os: sonic
        leaf3:
          ansible_host: 172.20.20.13
          ansible_user: admin
          ansible_password: YourPassword
          ansible_network_os: sonic
        leaf4:
          ansible_host: 172.20.20.14
          ansible_user: admin
          ansible_password: YourPassword
          ansible_network_os: sonic
EOF
    " || {
        log_error "Failed to create inventory"
        exit 1
    }
    
    log_info "Inventory created at /var/src/ansible/clab_inventory.yml"
}

# Test Ansible connectivity
test_connectivity() {
    log_info "Testing Ansible connectivity..."
    
    docker exec sonic-mgmt-test bash -c "
    cd /var/src/ansible
    ansible -i clab_inventory.yml sonic_devices -m ping
    " || {
        log_warn "Some hosts may not be ready yet"
        log_info "Wait a few moments and try again"
    }
}

# Setup SSH keys
setup_ssh_keys() {
    log_info "Setting up SSH keys..."
    
    docker exec sonic-mgmt-test bash -c "
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH key if not exists
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
    fi
    
    # Add known hosts
    for host in 172.20.20.2 172.20.20.11 172.20.20.12 172.20.20.13 172.20.20.14; do
        ssh-keyscan -H \$host >> ~/.ssh/known_hosts 2>/dev/null || true
    done
    " || {
        log_warn "SSH key setup had issues, continuing..."
    }
    
    log_info "SSH keys configured"
}

# Main execution
main() {
    log_info "Starting Ansible setup for Containerlab topology"
    
    check_container
    create_inventory
    setup_ssh_keys
    
    log_info "Waiting 5 seconds before testing connectivity..."
    sleep 5
    
    test_connectivity
    
    log_info "Ansible setup completed"
    log_info "Next: Run tests with ansible-playbook or pytest"
}

main "$@"

