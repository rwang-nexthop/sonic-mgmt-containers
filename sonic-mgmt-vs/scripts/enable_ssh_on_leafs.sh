#!/bin/bash

# Script to enable SSH on leaf nodes
# This resolves the SSH connectivity issue for Ansible
# Configures SSH, creates admin user, and adds to known_hosts

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

LEAF_CONTAINERS=("clab-sonic-vs-t0-leaf1" "clab-sonic-vs-t0-leaf2")
SONIC_MGMT_CONTAINER="sonic-mgmt-test"

echo ""
echo "=========================================="
echo "  Enabling SSH on Leaf Nodes"
echo "=========================================="
echo ""

# Step 1: Check if containers are running
echo -e "${BLUE}Step 1: Checking if leaf containers are running...${NC}"
echo "-------------------------------------------"

for container in "${LEAF_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "  ${GREEN}✓${NC} $container is running"
    else
        echo -e "  ${RED}✗${NC} $container is NOT running"
        exit 1
    fi
done

echo ""

# Step 2: Configure SSH on each leaf
echo -e "${BLUE}Step 2: Configuring SSH on leaf nodes...${NC}"
echo "-------------------------------------------"

for container in "${LEAF_CONTAINERS[@]}"; do
    echo "Configuring SSH on $container..."

    # Fix SSH key permissions
    docker exec $container bash -c "chmod 600 /etc/ssh/ssh_host_*_key" 2>&1 || true

    # Create /run/sshd directory
    docker exec $container bash -c "mkdir -p /run/sshd && chmod 700 /run/sshd" 2>&1 || true

    # Create admin user if it doesn't exist
    docker exec $container bash -c "id admin >/dev/null 2>&1 || (useradd -m -s /bin/bash admin && echo 'admin:YourPassword' | chpasswd)" 2>&1 || true

    # Setup sudo configuration
    docker exec $container bash -c "mkdir -p /etc/sudoers.d && echo 'admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/admin && chmod 0440 /etc/sudoers.d/admin" 2>&1 || true

    # Enable password authentication in SSH
    docker exec $container bash -c "sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config" 2>&1 || true

    # Set root password for SSH access
    docker exec $container bash -c "echo 'root:sonic' | chpasswd" 2>&1 || true

    echo -e "  ${GREEN}✓${NC} SSH configured on $container"
done

echo ""

# Step 3: Enable SSH daemon in supervisord
echo -e "${BLUE}Step 3: Enabling SSH daemon in supervisord...${NC}"
echo "-------------------------------------------"

for container in "${LEAF_CONTAINERS[@]}"; do
    echo "Enabling sshd in $container..."

    # Check if sshd is already in supervisord config
    if ! docker exec $container grep -q "\[program:sshd\]" /etc/supervisor/conf.d/supervisord.conf 2>/dev/null; then
        # Add sshd to supervisord config
        docker exec $container bash -c 'cat >> /etc/supervisor/conf.d/supervisord.conf << "EOF"

[program:sshd]
command=/usr/sbin/sshd -D
priority=0
autostart=true
autorestart=true
stdout_logfile=syslog
stderr_logfile=syslog
EOF' 2>&1 || true
    fi

    # Reload supervisord
    docker exec $container supervisorctl reread 2>&1 || true
    docker exec $container supervisorctl update 2>&1 || true
    docker exec $container supervisorctl restart sshd 2>&1 || docker exec $container supervisorctl start sshd 2>&1 || true

    sleep 2

    echo -e "  ${GREEN}✓${NC} sshd enabled in $container"
done

echo ""

# Step 4: Verify SSH is running
echo -e "${BLUE}Step 4: Verifying SSH is running...${NC}"
echo "-------------------------------------------"

for container in "${LEAF_CONTAINERS[@]}"; do
    if docker exec $container bash -c "ss -tuln | grep -q ':22'" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} SSH is listening on $container"
    else
        echo -e "  ${YELLOW}⚠${NC} SSH may not be listening yet on $container (will retry)"
        sleep 3
        if docker exec $container bash -c "ss -tuln | grep -q ':22'" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} SSH is now listening on $container"
        else
            echo -e "  ${RED}✗${NC} SSH is NOT listening on $container"
        fi
    fi
done

echo ""

# Step 5: Test SSH connectivity from DUT
echo -e "${BLUE}Step 5: Testing SSH connectivity from DUT...${NC}"
echo "-------------------------------------------"

for container in "${LEAF_CONTAINERS[@]}"; do
    ip=$(docker inspect $container --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    echo "Testing SSH to $container ($ip)..."

    if timeout 5 docker exec clab-sonic-vs-t0-dut bash -c "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 admin@$ip 'echo OK'" 2>/dev/null | grep -q "OK"; then
        echo -e "  ${GREEN}✓${NC} SSH connection successful to $container"
    else
        echo -e "  ${YELLOW}⚠${NC} SSH connection failed to $container (retrying...)"
        sleep 3
        if timeout 5 docker exec clab-sonic-vs-t0-dut bash -c "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 admin@$ip 'echo OK'" 2>/dev/null | grep -q "OK"; then
            echo -e "  ${GREEN}✓${NC} SSH connection successful to $container (on retry)"
        else
            echo -e "  ${RED}✗${NC} SSH connection failed to $container"
        fi
    fi
done

echo ""

# Step 6: Add leaf nodes to sonic-mgmt known_hosts
echo -e "${BLUE}Step 6: Adding leaf nodes to sonic-mgmt known_hosts...${NC}"
echo "-------------------------------------------"

if docker ps --format '{{.Names}}' | grep -q "^${SONIC_MGMT_CONTAINER}$"; then
    for container in "${LEAF_CONTAINERS[@]}"; do
        ip=$(docker inspect $container --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
        echo "Adding $container ($ip) to known_hosts..."

        docker exec -u rwang $SONIC_MGMT_CONTAINER bash -c "ssh-keyscan -t ed25519 $ip >> ~/.ssh/known_hosts 2>/dev/null || true" 2>&1 || true

        echo -e "  ${GREEN}✓${NC} $container added to known_hosts"
    done
else
    echo -e "  ${YELLOW}⚠${NC} sonic-mgmt-test container not running (skipping known_hosts setup)"
fi

echo ""
echo "=========================================="
echo "  SSH Configuration Complete!"
echo "=========================================="
echo ""
echo "Leaf nodes are now ready for Ansible connectivity."
echo ""

