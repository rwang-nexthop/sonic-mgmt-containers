# Quick Start Guide - SONiC VM Topology

## 5-Minute Setup

### Step 1: Verify Prerequisites (1 min)

```bash
# Check KVM support
grep -o 'vmx\|svm' /proc/cpuinfo | head -1

# Check Docker
docker --version

# Check Containerlab
containerlab version
```

### Step 2: Update sonic-vm Image (1 min)

Edit `topology/t1-small-vm.clab.yml`:

```yaml
kinds:
  sonic-vm:
    image: container-registry.sw.internal.nexthop.ai/clab-sonic:12336
```

### Step 3: Deploy Topology (1 min)

```bash
cd ~/sonic-mgmt-vm
containerlab deploy -t topology/t1-small-vm.clab.yml
```

### Step 4: Wait for Boot (2 min)

```bash
# Monitor boot progress
watch -n 5 'docker ps | grep clab-t1-small-vm'

# Or check individual node
docker logs clab-t1-small-vm-sonic-dut | tail -20
```

### Step 5: Verify Connectivity (1 min)

```bash
# Test SSH
ssh admin@172.30.30.4

# Exit SSH
exit

# Test Ansible
docker exec -it clab-t1-small-vm-sonic-mgmt bash
ansible -i /sonic-mgmt/ansible/lab sonic-dut -m ping
exit
```

## Running Your First Test

### 1. Deploy Configuration

```bash
cd ~/sonic-mgmt-vm
./scripts/deploy_config.sh
```

### 2. Enter Management Container

```bash
docker exec -it clab-t1-small-vm-sonic-mgmt bash
```

### 3. Copy Inventory

```bash
sudo cp /tmp/sonic-configs/inventory.ini /sonic-mgmt/ansible/lab
```

### 4. Run BGP Test

```bash
cd /sonic-mgmt/tests
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

## Common Commands

### Access SONiC CLI

```bash
# Via SSH
ssh admin@172.30.30.4
vtysh

# Via Telnet
telnet sonic-dut 5000
```

### Check Node Status

```bash
# List all containers
docker ps | grep clab-t1-small-vm

# Check specific node logs
docker logs clab-t1-small-vm-sonic-dut

# Enter node shell
docker exec -it clab-t1-small-vm-sonic-dut bash
```

### Cleanup

```bash
# Destroy topology
containerlab destroy -t topology/t1-small-vm.clab.yml

# Clean Docker
docker system prune -a --volumes
```

## Troubleshooting

### Nodes not booting?

```bash
# Wait longer (up to 2 minutes)
sleep 120
docker ps | grep clab-t1-small-vm

# Check logs
docker logs clab-t1-small-vm-sonic-dut
```

### SSH connection refused?

```bash
# Verify SSH is running
docker exec clab-t1-small-vm-sonic-dut ps aux | grep sshd

# Check if port 22 is listening
docker exec clab-t1-small-vm-sonic-dut netstat -tlnp | grep 22
```

### High resource usage?

sonic-vm uses more resources than sonic-vs. Ensure:
- 4+ CPU cores available
- 8+ GB RAM available
- 20+ GB free disk space

## Next Steps

- Read **SONIC_VM_TOPOLOGY.md** for detailed documentation
- Check **README.md** for directory structure
- Review test examples in `/sonic-mgmt/tests`

## Support

For issues:
1. Check logs: `docker logs clab-t1-small-vm-<node-name>`
2. Review SONIC_VM_TOPOLOGY.md troubleshooting section
3. Check Containerlab docs: https://containerlab.dev/manual/kinds/sonic-vm/

