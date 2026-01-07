# Quick Reference Guide

## One-Command Deployment

```bash
cd sonic-mgmt-vs
chmod +x scripts/*.sh
bash scripts/deploy_complete.sh
```

## Manual Step-by-Step

### 1. Deploy Topology
```bash
cd sonic-mgmt-vs
sudo containerlab deploy -t sonic-vs-t0.clab.yml
```

### 2. Verify Topology Deployment
```bash
# Check all containers are running
docker ps | grep sonic-vs-t0

# Inspect topology status
sudo containerlab inspect -t sonic-vs-t0.clab.yml
```

### 3. Verify Interface Configuration
```bash
# Check DUT interfaces
ssh admin@172.20.20.2 "show interfaces status"

# Check leaf1 interfaces
ssh admin@172.20.20.11 "show interfaces status"

# Check leaf2 interfaces
ssh admin@172.20.20.12 "show interfaces status"
```

### 4. Verify BGP Configuration
```bash
# Check DUT BGP status
ssh admin@172.20.20.2 "vtysh -c 'show bgp summary'"

# Check leaf1 BGP status
ssh admin@172.20.20.11 "vtysh -c 'show bgp summary'"

# Check leaf2 BGP status
ssh admin@172.20.20.12 "vtysh -c 'show bgp summary'"
```

### 5. Verify BGP Routes
```bash
# Check DUT BGP routes
ssh admin@172.20.20.2 "vtysh -c 'show bgp ipv4 unicast'"

# Check leaf1 BGP routes
ssh admin@172.20.20.11 "vtysh -c 'show bgp ipv4 unicast'"

# Check leaf2 BGP routes
ssh admin@172.20.20.12 "vtysh -c 'show bgp ipv4 unicast'"

# Check DUT BGP IP routes
ssh admin@172.20.20.2 "vtysh -c 'show ip route bgp'"

# Check leaf1 BGP IP routes
ssh admin@172.20.20.11 "vtysh -c 'show ip route bgp'"

# Check leaf2 BGP IP routes
ssh admin@172.20.20.12 "vtysh -c 'show ip route bgp'"
```

### 6. Test Connectivity Between Nodes
```bash
# Ping from DUT to leaf1 loopback
ssh admin@172.20.20.2 "ping -c 3 11.11.11.11"

# Ping from DUT to leaf2 loopback
ssh admin@172.20.20.2 "ping -c 3 12.12.12.12"

# Ping from leaf1 to leaf2 loopback
ssh admin@172.20.20.11 "ping -c 3 12.12.12.12"
```

### 7. Setup sonic-mgmt Container (Optional - for testing)
```bash
cd sonic-mgmt-master
./setup-container.sh -n sonic-mgmt-test -d /var/src -m /Users/rwang/Python/Projects/sonic-mgmt-vs
```

### 8. Setup Ansible (Optional - for testing)
```bash
cd ../scripts
bash setup_ansible.sh
```

### 9. Verify Ansible Connectivity (Optional - for testing)
```bash
bash verify_ansible_connectivity.sh
```

## Post-Deployment Verification Checklist

After deploying the topology, verify the following:

- [ ] All containers are running: `docker ps | grep sonic-vs-t0`
- [ ] Interfaces are up: `ssh admin@172.20.20.2 "show interfaces status"`
- [ ] BGP neighbors are established: `ssh admin@172.20.20.2 "vtysh -c 'show bgp summary'"`
- [ ] BGP routes are advertised: `ssh admin@172.20.20.2 "vtysh -c 'show bgp ipv4 unicast'"`
- [ ] BGP IP routes learned: `ssh admin@172.20.20.2 "vtysh -c 'show ip route bgp'"`
- [ ] Loopback connectivity works: `ssh admin@172.20.20.2 "ping -c 3 11.11.11.11"`
- [ ] All leaf nodes have BGP established
- [ ] Routes are learned on all nodes

## Common Commands

### Access Nodes

```bash
# DUT via SSH
ssh admin@172.20.20.2

# Leaf1 via SSH
ssh admin@172.20.20.11

# Leaf2 via SSH
ssh admin@172.20.20.12

# sonic-mgmt container (if running)
docker exec -u vscode -it sonic-mgmt-test bash
```

### Check Status

```bash
# Topology status
sudo containerlab inspect -t sonic-vs-t0.clab.yml

# Running containers
docker ps | grep sonic-vs-t0

# BGP status on DUT
ssh admin@172.20.20.2 "vtysh -c 'show bgp summary'"

# BGP status on leaf1
ssh admin@172.20.20.11 "vtysh -c 'show bgp summary'"

# BGP status on leaf2
ssh admin@172.20.20.12 "vtysh -c 'show bgp summary'"

# Interface status
ssh admin@172.20.20.2 "show interfaces status"

# BGP routes on DUT
ssh admin@172.20.20.2 "vtysh -c 'show bgp ipv4 unicast'"

# BGP IP routes on DUT
ssh admin@172.20.20.2 "vtysh -c 'show ip route bgp'"

# All IP routes on DUT
ssh admin@172.20.20.2 "vtysh -c 'show ip route'"
```

### Test Connectivity

```bash
# Ping DUT to leaf1 loopback
ssh admin@172.20.20.2 "ping -c 3 11.11.11.11"

# Ping DUT to leaf2 loopback
ssh admin@172.20.20.2 "ping -c 3 12.12.12.12"

# Ping leaf1 to leaf2 loopback
ssh admin@172.20.20.11 "ping -c 3 12.12.12.12"

# Ping leaf2 to DUT loopback
ssh admin@172.20.20.12 "ping -c 3 1.1.1.1"
```

### Run Tests

```bash
# Inside sonic-mgmt container
cd /var/src/sonic-mgmt-master/tests

# BGP tests (with required testbed parameters)
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml

# Specific test
python -m pytest bgp/test_bgp_neighbor.py::test_bgp_neighbor -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

### Ansible Commands

```bash
# Inside sonic-mgmt container
cd /var/src/ansible

# Ping all hosts
ansible -i clab_inventory.yml sonic_devices -m ping

# Run command on all hosts
ansible -i clab_inventory.yml sonic_devices -m shell \
  -a "show version"

# Run playbook
ansible-playbook -i clab_inventory.yml playbook.yml
```

## Network Information

| Node | Management IP | Loopback IP | BGP ASN | Role |
|------|---------------|------------|---------|------|
| dut | 172.20.20.2 | 1.1.1.1 | 65000 | Device Under Test (Spine) |
| leaf1 | 172.20.20.11 | 11.11.11.11 | 65101 | Neighbor (Leaf) |
| leaf2 | 172.20.20.12 | 12.12.12.12 | 65102 | Neighbor (Leaf) |

## BGP Peering

| Link | Interface | DUT IP | Neighbor IP | Neighbor ASN |
|------|-----------|--------|-------------|--------------|
| DUT-Leaf1 | eth1 (Ethernet0) | 10.0.0.0/31 | 10.0.0.1 | 65101 |
| DUT-Leaf2 | eth2 (Ethernet4) | 10.0.1.0/31 | 10.0.1.1 | 65102 |
| Leaf1-Leaf2 | eth2 (Ethernet4) | 10.0.2.0/31 | 10.0.2.1 | - |

## Advertised Networks

| Node | Network | Purpose |
|------|---------|---------|
| leaf1 | 192.168.1.0/24 | Leaf1 subnet |
| leaf2 | 192.168.2.0/24 | Leaf2 subnet |

## Cleanup

```bash
# Full cleanup
cd sonic-mgmt-vs
chmod +x cleanup.sh
./cleanup.sh

# Or manual cleanup
docker rm -f sonic-mgmt-test
sudo containerlab destroy -t sonic-vs-t0.clab.yml --cleanup
```

## File Locations

```
sonic-mgmt-vs/
├── sonic-vs-t0.clab.yml                    # Topology definition
├── README.md                               # Overview
├── QUICK_REFERENCE.md                      # This file
├── SSH_AND_ANSIBLE_SETUP.md               # SSH/Ansible setup guide
├── TOPOLOGY_CHANGES.md                     # Topology changes documentation
│
├── scripts/
│   ├── deploy_complete.sh                 # Complete automated deployment
│   ├── configure_bgp.sh                   # BGP configuration
│   ├── enable_ssh_on_leafs.sh             # Enable SSH on leaf nodes
│   ├── setup_dut_ssh.sh                   # Setup DUT SSH
│   ├── setup_ansible.sh                   # Ansible setup
│   ├── verify_ansible_connectivity.sh     # Verify Ansible connectivity
│   └── cleanup.sh                         # Cleanup script
│
├── ansible/
│   └── clab_inventory.yml                 # Ansible inventory
│
└── sonic-mgmt-master/
    ├── setup-container.sh                 # Container setup
    ├── ansible/                           # Ansible playbooks
    ├── tests/                             # Test cases
    └── docs/                              # Documentation
```

## Useful Links

- [SONiC GitHub](https://github.com/sonic-net/SONiC)
- [sonic-mgmt Documentation](https://github.com/sonic-net/sonic-mgmt/tree/master/docs)
- [Containerlab Documentation](https://containerlab.dev/)
- [Ansible Documentation](https://docs.ansible.com/)

## Tips & Tricks

1. **Speed up deployment**: Pre-pull sonic-vs image
2. **Debug BGP**: Check `/var/log/bgpd.log` inside nodes
3. **Persistent config**: Use `config save` in SONiC
4. **Test isolation**: Use `cleanup.sh` between test runs
5. **SSH without password**: Configure SSH keys in Ansible

