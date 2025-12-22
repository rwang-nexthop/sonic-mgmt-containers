# Quick Reference Guide

## One-Command Deployment

```bash
cd sonic-mgmt-vs
chmod +x *.sh
bash deploy_topology.sh
```

## Manual Step-by-Step

### 1. Deploy Topology
```bash
cd sonic-mgmt-vs
sudo containerlab deploy -t sonic-vs-t0.clab.yml
```

### 2. Configure BGP
```bash
chmod +x configure_bgp.sh
./configure_bgp.sh
```

### 3. Setup sonic-mgmt
```bash
cd sonic-mgmt-master
./setup-container.sh -n sonic-mgmt-test -d /var/src \
  -m ../sonic-mgmt-vs:/sonic-mgmt-vs
```

### 4. Setup Ansible
```bash
cd ../sonic-mgmt-vs
chmod +x setup_ansible.sh
./setup_ansible.sh
```

### 5. Test Connectivity
```bash
chmod +x test_connectivity.sh
./test_connectivity.sh
```

## Common Commands

### Access Nodes

```bash
# DUT
docker exec -it sonic-vs-t0-dut bash

# Leaf nodes
docker exec -it sonic-vs-t0-leaf1 bash
docker exec -it sonic-vs-t0-leaf2 bash
docker exec -it sonic-vs-t0-leaf3 bash
docker exec -it sonic-vs-t0-leaf4 bash

# sonic-mgmt container
docker exec -it sonic-mgmt-test bash
```

### Check Status

```bash
# Topology status
sudo containerlab inspect -t sonic-vs-t0.clab.yml

# Running containers
docker ps | grep sonic-vs-t0

# BGP status
docker exec sonic-vs-t0-dut bash -c "show bgp summary"

# Interface status
docker exec sonic-vs-t0-dut bash -c "show interfaces status"
```

### Run Tests

```bash
# Inside sonic-mgmt container
cd /var/src/tests

# BGP tests
python -m pytest bgp/test_bgp_fact.py -v

# Specific test
python -m pytest bgp/test_bgp_neighbor.py::test_bgp_neighbor -v

# With inventory
python -m pytest bgp/test_bgp_fact.py -v \
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

| Node | Management IP | BGP ASN | Role |
|------|---------------|---------|------|
| dut | 172.20.20.2 | 65000 | Device Under Test |
| leaf1 | 172.20.20.11 | 65001 | Neighbor |
| leaf2 | 172.20.20.12 | 65002 | Neighbor |
| leaf3 | 172.20.20.13 | 65003 | Neighbor |
| leaf4 | 172.20.20.14 | 65004 | Neighbor |

## BGP Peering

| Link | DUT IP | Neighbor IP | Neighbor |
|------|--------|-------------|----------|
| Ethernet0 | 10.0.0.0/31 | 10.0.0.1 | leaf1 |
| Ethernet4 | 10.0.0.4/31 | 10.0.0.5 | leaf2 |
| Ethernet8 | 10.0.0.8/31 | 10.0.0.9 | leaf3 |
| Ethernet12 | 10.0.0.12/31 | 10.0.0.13 | leaf4 |

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
├── sonic-vs-t0.clab.yml          # Topology definition
├── configure_bgp.sh              # BGP setup
├── setup_ansible.sh              # Ansible setup
├── test_connectivity.sh          # Connectivity tests
├── deploy_topology.sh            # Full deployment
├── cleanup.sh                    # Cleanup
├── README.md                     # Overview
├── SETUP_GUIDE.md               # Detailed setup
├── QUICK_REFERENCE.md           # This file
└── TROUBLESHOOTING.md           # Troubleshooting

sonic-mgmt-master/
├── setup-container.sh            # Container setup
├── ansible/                      # Ansible playbooks
├── tests/                        # Test cases
└── docs/                         # Documentation
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

