# SONiC T1-Small Topology for Testing

A containerlab-based SONiC testing environment featuring a T1-small topology with SONiC-vs containers, PTF (Packet Test Framework), and sonic-mgmt container.

## 🚀 Quick Start

**TL;DR - 3 Commands:**
```bash
cd topology && sudo clab deploy -t t1-small.clab.yml  # Deploy topology
cd ../scripts && ./deploy_config.sh                    # Configure everything
./verify_topology.sh                                   # Verify (optional)
```

📖 For detailed setup guide, see [QUICKSTART.md](QUICKSTART.md)

## 🏗️ Topology Overview

This topology replaces all Arista cEOS nodes with SONiC-vs containers for a fully SONiC-based testing environment.

```
                    ┌─────────────┐
                    │ sonic-mgmt  │
                    │ (Management)│
                    └─────────────┘
                           │
                    Management Network
                    (172.30.30.0/24)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
    ┌───▼────┐        ┌────▼─────┐      ┌────▼───┐
    │   t0   │◄──────►│sonic-dut │◄────►│   t2   │
    │ AS65000│  eth1  │ AS65100  │ eth2 │AS65200 │
    └───┬────┘        └────┬─┬───┘      └────┬───┘
        │                  │ │               │
        │              eth3│ │eth4           │
        │                  │ │               │
        │             ┌────▼─▼────┐          │
        │             │    PTF     │          │
        │             │  (Tester)  │          │
        │             └────────────┘          │
        │                                     │
        └─────────────────┬───────────────────┘
                      eth2 (interconnect)
```

## 📋 Network Details

### Node Information

| Node | Type | AS Number | Loopback | Role |
|------|------|-----------|----------|------|
| sonic-dut | SONiC-vs | 65100 | 10.1.0.1/32 | Device Under Test |
| t0 | SONiC-vs | 65000 | 10.0.0.100/32 | Tier 0 Neighbor |
| t2 | SONiC-vs | 65200 | 10.0.0.200/32 | Tier 2 Neighbor |
| ptf | Linux | - | - | Packet Test Framework |
| sonic-mgmt | Linux | - | - | Management Container |

### IP Addressing

**Point-to-Point Links:**
- sonic-dut ↔ t0: 10.0.0.0/31 (sonic-dut: .0, t0: .1)
- sonic-dut ↔ t2: 10.0.0.2/31 (sonic-dut: .2, t2: .3)
- t0 ↔ t2: 10.0.1.0/31 (t0: .0, t2: .1)

**PTF Connections:**
- PTF eth0 → sonic-dut eth3 (10.0.0.4/31)
- PTF eth1 → sonic-dut eth4 (10.0.0.6/31)

**BGP Networks:**
- t0 advertises: 192.168.0.0/24
- t2 advertises: 192.168.2.0/24

## 🚀 Getting Started

### Option 1: Using VS Code DevContainer (Recommended for Mac Users)

The easiest way to get started, especially on Mac, is to use the included VS Code DevContainer:

1. **Install Prerequisites:**
   - Docker Desktop
   - VS Code with "Dev Containers" extension

2. **Open in DevContainer:**
   - Open the `sonic-mgmt-vs` folder in VS Code
   - Click "Reopen in Container" when prompted
   - Wait for the container to start (2-3 minutes first time)

3. **Deploy from DevContainer:**
   ```bash
   cd topology
   sudo clab deploy -t t1-small.clab.yml
   ```

See [.devcontainer/README.md](.devcontainer/README.md) for detailed DevContainer documentation.

### Option 2: Direct Installation

1. **Docker** installed and running
2. **Containerlab** installed (v0.40.0 or later)
3. **SONiC-vs image** available: `docker-sonic-vs:latest`

### Building SONiC-vs Image (if needed)

If you don't have the SONiC-vs image, you can build it from the SONiC repository:

```bash
# Clone SONiC buildimage repository
git clone https://github.com/sonic-net/sonic-buildimage.git
cd sonic-buildimage

# Build SONiC-vs image
make configure PLATFORM=vs
make target/docker-sonic-vs.gz

# Load the image
docker load < target/docker-sonic-vs.gz
docker tag docker-sonic-vs:latest docker-sonic-vs:latest
```

Alternatively, use a pre-built image from a registry.

**Note:** The PTF and sonic-mgmt containers use generic Alpine Linux images (`ghcr.io/srl-labs/alpine:latest`). If you need the full PTF or sonic-mgmt functionality, you can replace these with the appropriate images from your registry.

## 📦 Deployment

### 1. Deploy the Topology

```bash
cd /Users/rwang/Python/Projects/sonic-mgmt-vs/topology
sudo clab deploy -t t1-small.clab.yml  # sudo is required!
```

**Important:** Always use `sudo` with containerlab commands. Containerlab requires root permissions to modify `/etc/hosts`, create network interfaces, and configure network namespaces.

Expected output:
```
INFO[0000] Containerlab v0.x.x starting
INFO[0001] Creating lab directory: /root/clab-t1-small
INFO[0002] Creating container: "clab-t1-small-sonic-dut"
INFO[0003] Creating container: "clab-t1-small-t0"
INFO[0004] Creating container: "clab-t1-small-t2"
INFO[0005] Creating container: "clab-t1-small-ptf"
INFO[0006] Creating container: "clab-t1-small-sonic-mgmt"
...
```

### 2. Wait for SONiC to Boot

SONiC containers take approximately 2-3 minutes to fully boot. You can monitor the progress:

```bash
# Check container status
docker ps --filter "name=clab-t1-small"

# Watch sonic-dut boot process
docker logs -f clab-t1-small-sonic-dut
```

### 3. Deploy Configuration (One-Step Setup)

**IMPORTANT:** SONiC-vs doesn't automatically load the config_db.json files. Run the unified deployment script:

```bash
cd ../scripts
./deploy_config.sh
```

This single script will:
- ✅ Configure IP addresses on all interfaces (eth1, eth2, eth3, eth4)
- ✅ Bring all interfaces up
- ✅ Configure BGP routing on all nodes
- ✅ Verify connectivity between nodes
- ✅ Check BGP neighbor status

**Alternative - Individual Scripts:**

If you prefer to run steps separately:

```bash
# Step 1: Configure interfaces only
./configure_interfaces.sh

# Step 2: Configure BGP only
./configure_bgp.sh

# Step 3: Verify topology
./verify_topology.sh
```

## 🔍 Verification & Testing

### Access Containers

```bash
# Access sonic-dut
docker exec -it clab-t1-small-sonic-dut bash

# Access PTF container
docker exec -it clab-t1-small-ptf bash

# Access sonic-mgmt container
docker exec -it clab-t1-small-sonic-mgmt bash
```

### Check BGP Status

```bash
# On sonic-dut
docker exec -it clab-t1-small-sonic-dut vtysh -c "show ip bgp summary"

# View BGP routes
docker exec -it clab-t1-small-sonic-dut vtysh -c "show ip bgp"

# View routing table
docker exec -it clab-t1-small-sonic-dut vtysh -c "show ip route"
```

### Test Connectivity

```bash
# Ping from sonic-dut to t0
docker exec -it clab-t1-small-sonic-dut ping -c 3 10.0.0.1

# Ping from sonic-dut to t2
docker exec -it clab-t1-small-sonic-dut ping -c 3 10.0.0.3

# Traceroute
docker exec -it clab-t1-small-sonic-dut traceroute 192.168.0.1
```

### PTF Testing

```bash
# Access PTF container
docker exec -it clab-t1-small-ptf bash

# Inside PTF container, run tests
cd /ptf
ptf --test-dir tests/ --interface 0@eth0 --interface 1@eth1
```

## 🗂️ Directory Structure

```
sonic-mgmt-vs/
├── .devcontainer/
│   ├── devcontainer.json          # VS Code DevContainer config (Docker-outside-of-Docker)
│   └── README.md                  # DevContainer documentation
├── topology/
│   └── t1-small.clab.yml          # Containerlab topology definition
├── configs/
│   ├── sonic-dut/
│   │   └── config_db.json         # sonic-dut configuration
│   ├── t0/
│   │   └── config_db.json         # t0 neighbor configuration
│   ├── t2/
│   │   └── config_db.json         # t2 neighbor configuration
│   └── ptf/
│       ├── ptf_nn_agent.conf      # PTF configuration
│       └── README.md              # PTF documentation
├── scripts/
│   ├── configure_bgp.sh           # BGP configuration automation
│   └── verify_topology.sh         # Topology verification script
└── README.md                      # This file
```

## 🛠️ Troubleshooting

### Issue: "failed to create hosts file: permission denied" on macOS

**This is expected and can be ignored!**

macOS has System Integrity Protection (SIP) that prevents modification of `/etc/hosts` even with `sudo`. The deployment still succeeds - all containers are created and running.

**Verify deployment succeeded:**
```bash
docker ps --filter "name=clab-t1-small"
```

**Workaround for hostname resolution:**
Use container names or IP addresses instead of hostnames, or manually add entries to `/etc/hosts` if needed.

### Issue: SONiC containers not starting

**Check Docker resources:**
```bash
docker system df
docker system prune  # Clean up if needed
```

**Check SONiC image:**
```bash
docker images | grep sonic-vs
```

### Issue: BGP neighbors not establishing

**Wait for boot:** SONiC needs 2-3 minutes to fully boot

**Check interface status:**
```bash
docker exec -it clab-t1-small-sonic-dut vtysh -c "show interface brief"
```

**Check BGP configuration:**
```bash
docker exec -it clab-t1-small-sonic-dut vtysh -c "show running-config"
```

### Issue: PTF container not working

**Note:** The topology uses a generic Alpine Linux image for PTF. For full PTF functionality:
- Build the PTF image from the SONiC repository
- Use a pre-built PTF image from your registry
- Edit the topology file to specify your PTF image

**Check PTF interfaces:**
```bash
docker exec -it clab-t1-small-ptf ip link show
```

## 🧹 Cleanup

To destroy the topology:

```bash
cd topology
sudo clab destroy -t t1-small.clab.yml
```

To remove all containers and networks:

```bash
sudo clab destroy --cleanup
```

## 📚 References

- [Containerlab Documentation](https://containerlab.dev/)
- [SONiC Documentation](https://github.com/sonic-net/SONiC/wiki)
- [PTF Documentation](https://github.com/p4lang/ptf)
- [SONiC Testing Guide](https://github.com/sonic-net/sonic-mgmt)

## 🤝 Contributing

This topology is designed for SONiC testing and development. Feel free to extend it with additional nodes or features.

## 📝 Notes

- All Arista cEOS nodes have been replaced with SONiC-vs containers
- The topology uses containerlab's native networking (no OVS bridges required)
- PTF container is configured for basic packet testing
- sonic-mgmt container provides management capabilities

