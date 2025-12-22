#!/bin/bash
# Setup SSH service on SONiC DUT container
# This script configures SSH on the DUT to allow remote access from sonic-mgmt container

set -e

DUT_CONTAINER="${1:-clab-sonic-vs-t0-dut}"

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# Check if DUT container is running
if ! docker ps | grep -q "$DUT_CONTAINER"; then
    log_error "DUT container '$DUT_CONTAINER' is not running"
    exit 1
fi

log_info "Setting up SSH on DUT container: $DUT_CONTAINER"

# Fix SSH key permissions
log_info "Fixing SSH key permissions..."
docker exec "$DUT_CONTAINER" bash -c "chmod 600 /etc/ssh/ssh_host_*_key" || true

# Create /run/sshd directory
log_info "Creating /run/sshd directory..."
docker exec "$DUT_CONTAINER" bash -c "mkdir -p /run/sshd && chmod 700 /run/sshd"

# Create admin user if it doesn't exist
log_info "Creating admin user..."
docker exec "$DUT_CONTAINER" bash -c "id admin >/dev/null 2>&1 || (useradd -m -s /bin/bash admin && echo 'admin:YourPassword' | chpasswd)" || true

# Add sshd to supervisord config if not already present
log_info "Configuring supervisord for SSH..."
if ! docker exec "$DUT_CONTAINER" grep -q "\[program:sshd\]" /etc/supervisor/conf.d/supervisord.conf; then
    docker exec "$DUT_CONTAINER" bash -c 'cat >> /etc/supervisor/conf.d/supervisord.conf << "EOF"

[program:sshd]
command=/usr/sbin/sshd -D
priority=0
autostart=true
autorestart=true
stdout_logfile=syslog
stderr_logfile=syslog
EOF'
    
    # Reload supervisord
    log_info "Reloading supervisord..."
    docker exec "$DUT_CONTAINER" supervisorctl reread
    docker exec "$DUT_CONTAINER" supervisorctl update
fi

# Start sshd
log_info "Starting SSH service..."
docker exec "$DUT_CONTAINER" supervisorctl restart sshd || docker exec "$DUT_CONTAINER" supervisorctl start sshd

# Wait for SSH to be ready
log_info "Waiting for SSH to be ready..."
sleep 2

# Test SSH connectivity
log_info "Testing SSH connectivity..."
DUT_IP=$(docker inspect "$DUT_CONTAINER" | grep -oP '"IPAddress": "\K[^"]+' | head -1)

if [ -z "$DUT_IP" ]; then
    log_error "Could not determine DUT IP address"
    exit 1
fi

log_info "DUT IP: $DUT_IP"

# Try to connect
if docker exec sonic-mgmt-test ping -c 1 "$DUT_IP" >/dev/null 2>&1; then
    log_info "Ping to DUT successful"
else
    log_error "Cannot ping DUT at $DUT_IP"
    exit 1
fi

# Test SSH
if docker exec sonic-mgmt-test sshpass -p "YourPassword" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 admin@"$DUT_IP" "echo 'SSH connection successful'" >/dev/null 2>&1; then
    log_info "SSH connection successful!"
else
    log_error "SSH connection failed"
    exit 1
fi

log_info "SSH setup completed successfully"
log_info "You can now run tests with: ./run_clab_tests.sh bgp/test_bgp_fact.py -v"

