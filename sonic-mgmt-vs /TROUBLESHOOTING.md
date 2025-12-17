# Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: sonic-vs Docker Image Not Found

**Error:**
```
Error response from daemon: image not found
```

**Solution:**
```bash
# Download sonic-vs image
wget https://sonic-build.azurewebsites.net/api/sonic/artifacts?branchName=master&platform=vs&target=target/sonic-vs.img.gz -O sonic-vs.img.gz

# Extract and load
gunzip sonic-vs.img.gz
docker load < sonic-vs.img

# Verify
docker images | grep sonic-vs
```

### Issue 2: Containerlab Deploy Fails

**Error:**
```
failed to deploy lab: permission denied
```

**Solution:**
```bash
# Use sudo for containerlab commands
sudo containerlab deploy -t sonic-vs-t0.clab.yml

# Or add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Issue 3: Nodes Not Becoming Ready

**Error:**
```
Waiting for dut to be ready... timeout
```

**Solution:**
```bash
# Check node logs
docker logs sonic-vs-t0-dut

# Wait longer and retry
sleep 30
./configure_bgp.sh

# Or manually check node status
docker exec sonic-vs-t0-dut bash -c "show version"
```

### Issue 4: BGP Configuration Fails

**Error:**
```
Failed to configure DUT
```

**Solution:**
```bash
# Check if node is ready
docker exec sonic-vs-t0-dut bash -c "show version"

# Check current config
docker exec sonic-vs-t0-dut bash -c "show running-configuration"

# Manually configure
docker exec sonic-vs-t0-dut bash -c "
config load-json /tmp/dut_bgp.json
"
```

### Issue 5: Ansible Ping Fails

**Error:**
```
FAILED - SSH Error: Permission denied
```

**Solution:**
```bash
# Inside sonic-mgmt container
# Check SSH connectivity
ssh -v admin@172.20.20.2

# Add SSH key
ssh-copy-id -i ~/.ssh/id_rsa.pub admin@172.20.20.2

# Update inventory with correct credentials
# Edit /var/src/ansible/clab_inventory.yml
```

### Issue 6: sonic-mgmt Container Creation Fails

**Error:**
```
failed to build docker image
```

**Solution:**
```bash
# Check if j2cli is installed
which j2

# Install if missing
pip install j2cli

# Retry container creation
./setup-container.sh -n sonic-mgmt-test -d /var/src
```

### Issue 7: Network Connectivity Issues

**Error:**
```
Ping from dut to leaf1 failed
```

**Solution:**
```bash
# Check interface status
docker exec sonic-vs-t0-dut bash -c "show interfaces status"

# Check IP configuration
docker exec sonic-vs-t0-dut bash -c "show ip interface"

# Verify links
sudo containerlab inspect -t sonic-vs-t0.clab.yml

# Check Docker network
docker network inspect sonic-vs-t0
```

### Issue 8: BGP Neighbors Not Established

**Error:**
```
show bgp summary shows 0 neighbors
```

**Solution:**
```bash
# Check BGP configuration
docker exec sonic-vs-t0-dut bash -c "show running-configuration bgp"

# Check BGP logs
docker exec sonic-vs-t0-dut bash -c "show log bgpd"

# Verify interface IPs
docker exec sonic-vs-t0-dut bash -c "show ip interface"

# Manually restart BGP
docker exec sonic-vs-t0-dut bash -c "
config load-json /tmp/dut_bgp.json
systemctl restart bgpd
"
```

### Issue 9: Tests Fail with "No such file or directory"

**Error:**
```
FileNotFoundError: /var/src/tests/...
```

**Solution:**
```bash
# Verify sonic-mgmt mount
docker exec sonic-mgmt-test bash -c "ls -la /var/src"

# Verify sonic-mgmt-vs mount
docker exec sonic-mgmt-test bash -c "ls -la /sonic-mgmt-vs"

# Recreate container with correct mounts
docker rm -f sonic-mgmt-test
./setup-container.sh -n sonic-mgmt-test \
  -d /var/src \
  -m ../sonic-mgmt-vs:/sonic-mgmt-vs
```

### Issue 10: Port Conflicts

**Error:**
```
Error response from daemon: Ports are not available
```

**Solution:**
```bash
# Check which ports are in use
netstat -tuln | grep LISTEN

# Change ports in sonic-vs-t0.clab.yml
# Or stop conflicting services

# Redeploy
sudo containerlab destroy -t sonic-vs-t0.clab.yml
sudo containerlab deploy -t sonic-vs-t0.clab.yml
```

## Debug Commands

### Check Topology Status
```bash
sudo containerlab inspect -t sonic-vs-t0.clab.yml
```

### Check Node Logs
```bash
docker logs sonic-vs-t0-dut
docker logs sonic-vs-t0-leaf1
```

### Check Network
```bash
docker network ls
docker network inspect sonic-vs-t0
```

### Check Containers
```bash
docker ps -a
docker inspect sonic-vs-t0-dut
```

### SSH to Node
```bash
docker exec -it sonic-vs-t0-dut bash
```

### Check Ansible Inventory
```bash
docker exec sonic-mgmt-test bash -c "
cd /var/src/ansible
ansible-inventory -i clab_inventory.yml --list
"
```

## Getting Help

1. Check logs in `/var/src/tests/logs/`
2. Review BGP configuration: `./bgp_config.log`
3. Check Docker logs: `docker logs <container>`
4. Verify connectivity: `./test_connectivity.sh`
5. Review sonic-mgmt documentation: `/var/src/docs/`

