# SONiC-VS Testbed with sonic-mgmt Integration

Complete setup guide for deploying a containerlab SONiC-VS topology and connecting it to sonic-mgmt for testing.

## Overview

This project provides a complete, automated setup for:
- **Containerlab Topology**: SONiC-VS based T0 topology with 1 DUT and 4 leaf neighbors
- **BGP Configuration**: Automated BGP setup with proper peering
- **sonic-mgmt Integration**: Full integration with sonic-mgmt testing framework
- **Ansible Automation**: Automated Ansible inventory and connectivity setup
- **Testing Framework**: Ready-to-run test cases against the topology

## Prerequisites

- Docker installed and running
- Containerlab installed (`sudo apt-get install containerlab` or `brew install containerlab`)
- sonic-vs Docker image available
- sonic-mgmt-master repository cloned inside sonic-mgmt-vs folder
- Linux/macOS system with bash
- sudo access (for containerlab commands)

## Quick Start (5 minutes)

### Automated Deployment

```bash
cd sonic-mgmt-vs
bash deploy_topology.sh
```

This single command will:
1. Deploy the containerlab topology
2. Configure BGP on all nodes
3. Create the sonic-mgmt container
4. Setup Ansible inventory
5. Test all connectivity

### Manual Step-by-Step

```bash
# 1. Deploy topology
cd sonic-mgmt-vs
sudo containerlab deploy -t sonic-vs-t0.clab.yml

# 2. Configure BGP
./configure_bgp.sh

# 3. Setup sonic-mgmt
cd sonic-mgmt-master
./setup-container.sh -n sonic-mgmt-test -d /var/src \
  -m ../sonic-mgmt-vs:/sonic-mgmt-vs

# 4. Setup Ansible
cd ../sonic-mgmt-vs
./setup_ansible.sh

# 5. Test connectivity
./test_connectivity.sh
```

## Directory Structure

```
sonic-mgmt-vs/
├── README.md                    # This file (overview)
├── QUICK_REFERENCE.md          # Quick command reference
├── SETUP_GUIDE.md              # Detailed step-by-step guide
├── TROUBLESHOOTING.md          # Common issues and solutions
│
├── sonic-vs-t0.clab.yml        # Containerlab topology definition
├── configure_bgp.sh            # BGP configuration script
├── setup_ansible.sh            # Ansible setup helper
├── test_connectivity.sh        # Connectivity test script
├── deploy_topology.sh          # Full automated deployment
└── cleanup.sh                  # Cleanup and removal script
```

## Key Features

### Topology
- **DUT**: 1 SONiC-VS device (Device Under Test)
- **Neighbors**: 4 SONiC-VS leaf nodes
- **Management Network**: 172.20.20.0/24
- **BGP Peering**: Full mesh connectivity with proper ASN assignment
- **Ports**: Exposed for SSH access (8022 for DUT)

### Automation
- **One-command deployment**: `bash deploy_topology.sh`
- **Automated BGP setup**: No manual configuration needed
- **Ansible integration**: Ready-to-use inventory
- **Connectivity testing**: Automated verification
- **Easy cleanup**: `bash cleanup.sh`

### Testing
- **sonic-mgmt framework**: Full access to all test cases
- **BGP tests**: Pre-configured for testing
- **Ansible playbooks**: Ready to run
- **Custom tests**: Easy to add your own

## Common Commands

### Access Nodes
```bash
# DUT
docker exec -it sonic-vs-t0-dut bash

# Leaf nodes
docker exec -it sonic-vs-t0-leaf1 bash

# sonic-mgmt container
docker exec -it sonic-mgmt-test bash
```

### Check Status
```bash
# Topology status
sudo containerlab inspect -t sonic-vs-t0.clab.yml

# BGP status
docker exec sonic-vs-t0-dut bash -c "show bgp summary"

# Interface status
docker exec sonic-vs-t0-dut bash -c "show interfaces status"
```

### Run Tests
```bash
# Inside sonic-mgmt container
cd /var/src/tests
python -m pytest bgp/test_bgp_fact.py -v
```

## Documentation

- **QUICK_REFERENCE.md**: Fast lookup for common commands
- **SETUP_GUIDE.md**: Detailed step-by-step instructions
- **TROUBLESHOOTING.md**: Solutions for common issues

## Network Information

| Node | Management IP | BGP ASN | Role |
|------|---------------|---------|------|
| dut | 172.20.20.2 | 65000 | Device Under Test |
| leaf1 | 172.20.20.11 | 65001 | Neighbor |
| leaf2 | 172.20.20.12 | 65002 | Neighbor |
| leaf3 | 172.20.20.13 | 65003 | Neighbor |
| leaf4 | 172.20.20.14 | 65004 | Neighbor |

## Cleanup

```bash
# Full cleanup
bash cleanup.sh

# Or manual cleanup
docker rm -f sonic-mgmt-test
sudo containerlab destroy -t sonic-vs-t0.clab.yml --cleanup
```

## Next Steps

1. **Read QUICK_REFERENCE.md** for common commands
2. **Read SETUP_GUIDE.md** for detailed instructions
3. **Run deploy_topology.sh** to deploy everything
4. **Access sonic-mgmt container** and run tests
5. **Customize topology** in sonic-vs-t0.clab.yml as needed

## Support

- Check **TROUBLESHOOTING.md** for common issues
- Review logs: `docker logs <container>`
- Check BGP config: `./bgp_config.log`
- Run connectivity test: `./test_connectivity.sh`

