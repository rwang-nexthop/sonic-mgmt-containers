#!/bin/bash

# Cleanup Script for SONiC-VS Topology
# Removes all deployed resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Confirm cleanup
confirm_cleanup() {
    echo -e "${RED}WARNING: This will remove all deployed resources!${NC}"
    echo "This includes:"
    echo "  - Containerlab topology (sonic-vs-t0)"
    echo "  - sonic-mgmt-test container"
    echo "  - All associated networks and volumes"
    echo
    read -p "Are you sure? (yes/no): " response
    
    if [ "$response" != "yes" ]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
}

# Remove sonic-mgmt container
remove_sonic_mgmt() {
    log_step "Removing sonic-mgmt container..."
    
    if docker ps -a | grep -q sonic-mgmt-test; then
        if docker rm -f sonic-mgmt-test; then
            log_info "sonic-mgmt-test container removed"
        else
            log_warn "Failed to remove sonic-mgmt-test container"
        fi
    else
        log_info "sonic-mgmt-test container not found"
    fi
}

# Remove containerlab topology
remove_topology() {
    log_step "Removing containerlab topology..."
    
    cd "$SCRIPT_DIR"
    
    if sudo containerlab destroy -t sonic-vs-t0.clab.yml --cleanup; then
        log_info "Topology removed successfully"
    else
        log_warn "Failed to remove topology (may already be removed)"
    fi
}

# Clean up Docker networks
clean_networks() {
    log_step "Cleaning up Docker networks..."
    
    # Remove sonic-vs-t0 network if it exists
    if docker network ls | grep -q sonic-vs-t0; then
        if docker network rm sonic-vs-t0 2>/dev/null; then
            log_info "sonic-vs-t0 network removed"
        else
            log_warn "Failed to remove sonic-vs-t0 network"
        fi
    fi
}

# Clean up log files
clean_logs() {
    log_step "Cleaning up log files..."
    
    cd "$SCRIPT_DIR"
    
    if [ -f bgp_config.log ]; then
        rm -f bgp_config.log
        log_info "bgp_config.log removed"
    fi
    
    if [ -d clab-sonic-vs-t0 ]; then
        rm -rf clab-sonic-vs-t0
        log_info "clab-sonic-vs-t0 directory removed"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}SONiC-VS Topology Cleanup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    confirm_cleanup
    
    echo
    remove_sonic_mgmt
    remove_topology
    clean_networks
    clean_logs
    
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Cleanup completed!${NC}"
    echo -e "${BLUE}========================================${NC}"
}

main "$@"

