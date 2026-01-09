# Quick Reference Guide

## One-Command Deployment (With PTF)

```bash
cd sonic-mgmt-vs
chmod +x scripts/*.sh
bash scripts/deploy_complete.sh
```

**Note:** This deployment now includes PTF (Packet Test Framework) container for running comprehensive tests.

## Important: After Uploading to Remote Server

**You MUST destroy the old topology before deploying the new one with PTF:**

```bash
cd /home/rwang/sonic-mgmt-vs

# Destroy old topology (without PTF)
sudo containerlab destroy -t sonic-vs-t0.clab.yml --cleanup

# Deploy new topology (with PTF)
sudo containerlab deploy -t sonic-vs-t0.clab.yml

# Verify all containers are running (including ptf-clab)
docker ps | grep sonic-vs-t0
```

---

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

### 7. Setup sonic-mgmt Container (For Running Tests)
```bash
cd sonic-mgmt-master
./setup-container.sh -n sonic-mgmt-test -d /var/src -m /home/rwang/sonic-mgmt-vs
```

**Important:** The `-m` flag must point to the remote path on ts107 (`/home/rwang/sonic-mgmt-vs`), not your local macOS path.

### 8. Enter sonic-mgmt Container
```bash
docker exec -it sonic-mgmt-test bash
```

### 9. Run Tests Inside Container
```bash
cd /var/src/sonic-mgmt-master/tests

# BGP Facts Test
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml

# Ping BGP Neighbors Test
python -m pytest bgp/test_ping_bgp_neighbor.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml

# Interface Status Test
python -m pytest test_interfaces.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

See `TEST_COMMANDS.md` for all available tests.

### 10. Setup Ansible (Optional)
```bash
cd /var/src/ansible
ansible -i clab_inventory.yml sonic_devices -m ping
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

# sonic-mgmt container (if running, change user and IP based on output of deploying sonic-mgmt script)
ssh -i ~/.ssh/id_rsa_docker_sonic_mgmt rwang@172.17.0.3
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

All tests are run inside the sonic-mgmt container. See `TEST_COMMANDS.md` for complete list of available tests.

```bash
# Enter container first
docker exec -it sonic-mgmt-test bash

# Navigate to tests directory
cd /var/src/sonic-mgmt-master/tests

# Run any test with this format:
python -m pytest <test_file> -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml

# Examples:
# BGP Facts
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml

# Ping BGP Neighbors
python -m pytest bgp/test_ping_bgp_neighbor.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml

# Interface Status
python -m pytest test_interfaces.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

**Note:** Tests marked as SKIPPED are expected - they require specific topology features not present in this containerlab setup.

### Ansible Commands

```bash
# Enter container first
docker exec -it sonic-mgmt-test bash

# Navigate to ansible directory
cd /var/src/ansible

# Ping all hosts (verify connectivity)
ansible -i clab_inventory.yml sonic_devices -m ping

# Run command on all hosts
ansible -i clab_inventory.yml sonic_devices -m shell \
  -a "vtysh -c 'show bgp summary'"

# Run command on specific host
ansible -i clab_inventory.yml dut -m shell \
  -a "vtysh -c 'show bgp ipv4 unicast'"

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

