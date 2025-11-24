# SONiC VM Topology Guide

## Overview

This guide explains the VM-based SONiC topology (`t1-small-vm.clab.yml`) and how it differs from the container-based topology.

## sonic-vs vs sonic-vm

| Feature | sonic-vs (Container) | sonic-vm (VM) |
|---------|----------------------|---------------|
| **Type** | Docker container | Virtual Machine (KVM) |
| **Boot Time** | ~10 seconds | ~60 seconds |
| **Resource Usage** | Low (lightweight) | High (full OS) |
| **Realism** | Simplified | More realistic |
| **Performance** | Fast for testing | Closer to production |
| **Virtualization** | Not required | KVM required |
| **Default User** | admin | admin |
| **Default Password** | admin | admin |

## Prerequisites

### 1. KVM/Virtualization Support

sonic-vm requires KVM virtualization support on the host:

```bash
# Check if KVM is available
grep -o 'vmx\|svm' /proc/cpuinfo | head -1

# Install KVM (if not present)
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients
```

### 2. sonic-vm Image

You need a sonic-vm image. Options:

**Option A: Use Nexthop internal registry**
```bash
# Already configured in t1-small-vm.clab.yml
image: container-registry.sw.internal.nexthop.ai/clab-sonic:12336
```

**Option B: Build your own**
```bash
# Download SONiC image from Azure pipeline
# Then wrap it with vrnetlab
# See: https://github.com/srl-labs/vrnetlab/tree/master/sonic
```

**Option C: Use public registry (if available)**
```bash
image: ghcr.io/sonic-net/sonic-vm:latest
```

## Deploying t1-small-vm Topology

### Step 1: Update the Image

Edit `topology/t1-small-vm.clab.yml` and set the correct sonic-vm image:

```yaml
kinds:
  sonic-vm:
    image: <your-sonic-vm-image>
```

### Step 2: Deploy the Topology

```bash
cd ~/sonic-mgmt-vm
containerlab deploy -t topology/t1-small-vm.clab.yml
```

### Step 3: Wait for Nodes to Boot

sonic-vm nodes take ~60 seconds to boot. Monitor progress:

```bash
# Check container status
docker ps | grep clab-t1-small-vm

# Check if SSH is ready
docker exec clab-t1-small-vm-sonic-dut bash -c "ps aux | grep sshd"
```

### Step 4: Verify Connectivity

```bash
# Test SSH to sonic-dut
ssh admin@172.30.30.4

# Test ansible
ansible -i /sonic-mgmt/ansible/lab sonic-dut -m ping
```

## Key Differences in Configuration

### 1. Startup Config

sonic-vm requires **full** config_db.json (not partial):

```bash
# Extract full config from running sonic-vm
containerlab save -t topology/t1-small-vm.clab.yml
```

### 2. SSH Access

sonic-vm has SSH enabled by default:

```bash
# SSH directly (no need to start SSH service)
ssh admin@172.30.30.4
```

### 3. CLI Access

Access SONiC CLI via vtysh:

```bash
ssh admin@172.30.30.4
vtysh
```

Or via telnet:

```bash
telnet sonic-dut 5000
```

## Troubleshooting

### sonic-vm nodes not booting

```bash
# Check logs
docker logs clab-t1-small-vm-sonic-dut

# Check if KVM is available
docker exec clab-t1-small-vm-sonic-dut ls -la /dev/kvm
```

### SSH connection refused

```bash
# Wait longer (up to 2 minutes for full boot)
sleep 60
ssh admin@172.30.30.4
```

### High CPU/Memory usage

sonic-vm uses more resources than sonic-vs. Ensure host has:
- At least 4 CPU cores
- At least 8GB RAM
- 20GB free disk space

## Running Tests with sonic-vm

The test workflow is the same as sonic-vs:

```bash
# Deploy topology
containerlab deploy -t topology/t1-small-vm.clab.yml

# Create config files
./scripts/deploy_config.sh

# Copy inventory
docker exec -it clab-t1-small-vm-sonic-mgmt bash
sudo cp /tmp/sonic-configs/inventory.ini /sonic-mgmt/ansible/lab
exit

# Run tests
docker exec -it clab-t1-small-vm-sonic-mgmt bash
cd /sonic-mgmt/tests
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

## Cleanup

```bash
# Destroy topology
containerlab destroy -t topology/t1-small-vm.clab.yml

# Remove all containers
docker system prune -a --volumes
```

## References

- [Containerlab sonic-vm documentation](https://containerlab.dev/manual/kinds/sonic-vm/)
- [vrnetlab sonic project](https://github.com/srl-labs/vrnetlab/tree/master/sonic)
- [SONiC documentation](https://sonic-net.github.io/SONiC/)

