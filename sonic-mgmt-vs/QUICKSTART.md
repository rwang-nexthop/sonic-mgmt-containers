# SONiC-MGMT-VS Quick Start Guide

## ⚡ 3-Command Deploy

```bash
cd ~/Projects/sonic-mgmt-vs/topology
sudo clab deploy -t t1-small.clab.yml
cd ../scripts && ./deploy_config.sh
```

## 📦 Enter sonic-mgmt Container

```bash
docker exec -it clab-t1-small-sonic-mgmt bash
```

## 🔍 Verify Image & Configuration

### Inside sonic-mgmt container:

```bash
# Check OS
cat /etc/os-release

# Verify mounts
ls -la /configs/
ls -la /scripts/

# Check network connectivity
ping -c 3 172.30.30.2  # sonic-dut
ping -c 3 172.30.30.3  # t0
ping -c 3 172.30.30.4  # t2
```

## 🧪 Run Tests on SONiC Containers

### From sonic-mgmt container:

```bash
# Run full verification
cd /scripts && ./verify_topology.sh

# Check BGP status
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary"

# Check interface status
docker exec clab-t1-small-sonic-dut show interface status

# Test connectivity
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.0  # t0
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.2  # t2

# View routing table
docker exec clab-t1-small-sonic-dut vtysh -c "show ip route"

# Check LLDP neighbors
docker exec clab-t1-small-sonic-dut show lldp table
```

## 📋 Setup Methods

### Option A: DevContainer (Recommended for Mac)

1. Install Docker Desktop and VS Code with "Dev Containers" extension
2. Open `sonic-mgmt-vs` folder in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for container to start (2-3 minutes first time)
5. Deploy from DevContainer terminal:

```bash
cd topology
sudo clab deploy -t t1-small.clab.yml
cd ../scripts && ./deploy_config.sh
```

### Option B: Direct Installation

**Prerequisites:**
```bash
docker ps                    # Docker running
clab version                 # Containerlab installed
docker images | grep sonic   # SONiC image available
```

**Deploy:**
```bash
cd ~/Projects/sonic-mgmt-vs/topology
sudo clab deploy -t t1-small.clab.yml
cd ../scripts && ./deploy_config.sh
```

## ✅ Verification Checklist

```bash
# All containers running
docker ps | grep clab-t1-small

# BGP neighbors established
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary"

# Interfaces up
docker exec clab-t1-small-sonic-dut show interface status

# Connectivity works
docker exec clab-t1-small-sonic-dut ping -c 2 10.0.0.0
docker exec clab-t1-small-sonic-dut ping -c 2 10.0.0.2

# Routing table populated
docker exec clab-t1-small-sonic-dut vtysh -c "show ip route"
```

## 🔧 Essential Commands

```bash
# Container access
docker exec -it clab-t1-small-sonic-mgmt bash
docker exec -it clab-t1-small-sonic-dut bash
docker exec -it clab-t1-small-ptf bash

# BGP troubleshooting
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp neighbors"
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp"

# Interface diagnostics
docker exec clab-t1-small-sonic-dut show interface Ethernet0
docker exec clab-t1-small-sonic-dut show ip interface

# Logs
docker logs clab-t1-small-sonic-dut | tail -50

# Cleanup
sudo clab destroy -t t1-small.clab.yml --cleanup
```

## 📊 Network Reference

| Link | IPs | Purpose |
|------|-----|---------|
| sonic-dut ↔ t0 | 10.0.0.0/31 | BGP peering |
| sonic-dut ↔ t2 | 10.0.0.2/31 | BGP peering |
| t0 ↔ t2 | 10.0.1.0/31 | Interconnect |
| PTF ↔ sonic-dut | 10.0.0.4/31, 10.0.0.6/31 | Data plane |

## 🐛 Troubleshooting

**BGP neighbors stuck in "Active":**
```bash
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp neighbors"
# Check if neighbors are activated in address-family
```

**Interfaces not up:**
```bash
docker exec clab-t1-small-sonic-dut show interface status
docker exec clab-t1-small-sonic-dut show ip interface
```

**No connectivity:**
```bash
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.0
docker exec clab-t1-small-sonic-dut vtysh -c "show ip route"
```

## 📚 Documentation

- **OVERVIEW.md** - Architecture and configuration review
- **README.md** - Full documentation
- **NETWORK_DIAGRAM.md** - Network topology diagram

## 🏆 Status

✅ **Production-Ready** - Deploy with confidence
