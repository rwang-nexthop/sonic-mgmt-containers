#!/bin/bash

# Automated Topology Deployment Script
# Deploys containerlab topology and configures everything

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SONIC_MGMT_DIR="${SCRIPT_DIR}/sonic-mgmt-master"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_info "Docker found"
    
    # Check Containerlab
    if ! command -v containerlab &> /dev/null; then
        log_error "Containerlab is not installed"
        exit 1
    fi
    log_info "Containerlab found"
    
    # Check sonic-vs image
    if ! docker images | grep -q sonic-vs; then
        log_error "sonic-vs Docker image not found"
        log_warn "Download from: https://sonic-build.azurewebsites.net"
        exit 1
    fi
    log_info "sonic-vs image found"
}

# Deploy topology
deploy_topology() {
    log_step "Deploying containerlab topology..."
    
    cd "$SCRIPT_DIR"
    
    if sudo containerlab deploy -t sonic-vs-t0.clab.yml; then
        log_info "Topology deployed successfully"
    else
        log_error "Failed to deploy topology"
        exit 1
    fi
    
    sleep 10  # Wait for nodes to stabilize
}

# Configure BGP
configure_bgp() {
    log_step "Configuring BGP..."
    
    cd "$SCRIPT_DIR"
    
    if bash configure_bgp.sh; then
        log_info "BGP configured successfully"
    else
        log_error "Failed to configure BGP"
        exit 1
    fi
}

# Setup sonic-mgmt container
setup_sonic_mgmt() {
    log_step "Setting up sonic-mgmt container..."
    
    cd "$SONIC_MGMT_DIR"
    
    if bash setup-container.sh -n sonic-mgmt-test \
        -d /var/src \
        -m "$SCRIPT_DIR:/sonic-mgmt-vs"; then
        log_info "sonic-mgmt container created"
    else
        log_error "Failed to create sonic-mgmt container"
        exit 1
    fi
    
    sleep 5  # Wait for container to stabilize
}

# Setup Ansible
setup_ansible() {
    log_step "Setting up Ansible..."
    
    cd "$SCRIPT_DIR"
    
    if bash setup_ansible.sh; then
        log_info "Ansible configured successfully"
    else
        log_error "Failed to configure Ansible"
        exit 1
    fi
}

# Test connectivity
test_connectivity() {
    log_step "Testing connectivity..."
    
    cd "$SCRIPT_DIR"
    
    if bash test_connectivity.sh; then
        log_info "All connectivity tests passed"
    else
        log_warn "Some connectivity tests failed"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}SONiC-VS Topology Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    check_prerequisites
    deploy_topology
    configure_bgp
    setup_sonic_mgmt
    setup_ansible
    test_connectivity
    
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo "Next steps:"
    echo "1. Enter sonic-mgmt container:"
    echo "   docker exec -it sonic-mgmt-test bash"
    echo
    echo "2. Run tests:"
    echo "   cd /var/src/tests"
    echo "   python -m pytest bgp/test_bgp_fact.py -v"
    echo
}

main "$@"

