# Quick Start Guide - SONiC T1-Small Topology

## 🚀 5-Minute Setup

### Choose Your Setup Method

**Option A: DevContainer (Recommended for Mac)** - Use VS Code DevContainer for easy setup
**Option B: Direct** - Install containerlab directly on your system

---

## Option A: DevContainer Setup (Mac/Windows/Linux)

### Step 1: Open in DevContainer

1. Install Docker Desktop and VS Code with "Dev Containers" extension
2. Open the `sonic-mgmt-vs` folder in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for container to start (2-3 minutes first time)

### Step 2: Deploy from DevContainer

```bash
# Inside the DevContainer terminal
cd topology
sudo clab deploy -t t1-small.clab.yml  # sudo is required!
```

**Note:** The `sudo` command is required because containerlab needs to modify `/etc/hosts` and create network interfaces.

Continue to **Step 3** below (same for both options).

See [.devcontainer/README.md](.devcontainer/README.md) for more details.

---

## Option B: Direct Setup

### Step 1: Verify Prerequisites

```bash
# Check Docker is running
docker ps

# Check containerlab is installed
clab version

# Check SONiC-vs image exists
docker images | grep sonic-vs
```

If `docker-sonic-vs:latest` is not available, you'll need to build or pull it first.

### Step 2: Deploy the Topology

```bash
cd /Users/rwang/Python/Projects/sonic-mgmt-vs/topology
sudo clab deploy -t t1-small.clab.yml  # sudo is required!
```

**Important:** Always use `sudo` with containerlab commands. Containerlab needs root permissions to:
- Modify `/etc/hosts` for container name resolution
- Create network interfaces and bridges
- Configure network namespaces

**Expected output:**
```
+---+---------------------------+--------------+-------------+
| # |           Name            |     Kind     |    State    |
+---+---------------------------+--------------+-------------+
| 1 | clab-t1-small-ptf         | linux        | running     |
| 2 | clab-t1-small-sonic-dut   | sonic-vs     | running     |
| 3 | clab-t1-small-sonic-mgmt  | linux        | running     |
| 4 | clab-t1-small-t0          | sonic-vs     | running     |
| 5 | clab-t1-small-t2          | sonic-vs     | running     |
+---+---------------------------+--------------+-------------+
```

### Step 3: Wait for SONiC Boot (2-3 minutes)

Monitor the boot process:

```bash
# Watch sonic-dut logs
docker logs -f clab-t1-small-sonic-dut

# Or check if ready
docker exec clab-t1-small-sonic-dut vtysh -c "show version"
```

When you see the SONiC version output, the system is ready.

### Step 4: Configure Interfaces

**IMPORTANT:** SONiC-vs doesn't automatically load config_db.json. Configure interfaces first:

```bash
cd ../scripts
./configure_interfaces.sh
```

This configures IP addresses on all interfaces and verifies connectivity.

### Step 5: Configure BGP

```bash
./configure_bgp.sh
```

**Expected output:**
```
==========================================
BGP Configuration Script for t1-small
==========================================

Step 1: Waiting for SONiC containers to boot...
Waiting for clab-t1-small-sonic-dut to be ready... ✓
Waiting for clab-t1-small-t0 to be ready... ✓
Waiting for clab-t1-small-t2 to be ready... ✓

Step 2: Configuring BGP on all containers...
Configuring BGP on clab-t1-small-sonic-dut (AS 65100)...
✓ Successfully configured clab-t1-small-sonic-dut
...
```

### Step 6: Verify Everything Works

```bash
./verify_topology.sh
```

## 🔍 Quick Verification Commands

### Check BGP Neighbors

```bash
# On sonic-dut
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary"
```

Expected output:
```
IPv4 Unicast Summary:
BGP router identifier 10.1.0.1, local AS number 65100
Neighbor        V         AS   MsgRcvd   MsgSent   Up/Down State/PfxRcd
10.0.0.1        4      65000        XX        XX  00:XX:XX            1
10.0.0.3        4      65200        XX        XX  00:XX:XX            1
```

### Test Connectivity

```bash
# Ping t0 from sonic-dut
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.1

# Ping t2 from sonic-dut
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.3
```

### Check Routes

```bash
# View all routes on sonic-dut
docker exec clab-t1-small-sonic-dut vtysh -c "show ip route"

# View only BGP routes
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp"
```

## 🧪 PTF Testing

### Access PTF Container

```bash
docker exec -it clab-t1-small-ptf bash
```

### Check PTF Interfaces

```bash
# Inside PTF container
ip link show
```

You should see `eth0` and `eth1` connected to sonic-dut.

### Run Basic PTF Test

```bash
# Inside PTF container
cd /ptf

# List available interfaces
ip addr show

# Send test packet (example)
scapy
>>> sendp(Ether()/IP(dst="10.0.0.1")/ICMP(), iface="eth0")
```

## 🛑 Stopping the Lab

```bash
cd /Users/rwang/Python/Projects/sonic-mgmt-vs/topology
sudo clab destroy -t t1-small.clab.yml
```

## 🐛 Common Issues

### Issue: "failed to create hosts file: permission denied" (macOS)

**This is normal on macOS and can be ignored!**

macOS System Integrity Protection (SIP) prevents containerlab from modifying `/etc/hosts`. The deployment still succeeds - verify with:

```bash
docker ps --filter "name=clab-t1-small"
```

All containers should show "Up" status. You can proceed with the next steps!

### Issue: "docker-sonic-vs:latest" not found

**Solution 1:** Use a different SONiC image
```bash
# Edit topology/t1-small.clab.yml
# Change: image: docker-sonic-vs:latest
# To: image: <your-sonic-image>
```

**Solution 2:** Build SONiC-vs from source
```bash
git clone https://github.com/sonic-net/sonic-buildimage.git
cd sonic-buildimage
make configure PLATFORM=vs
make target/docker-sonic-vs.gz
docker load < target/docker-sonic-vs.gz
```

### Issue: BGP neighbors stuck in "Active" state

**Check:**
1. Wait 2-3 minutes for SONiC to fully boot
2. Verify interfaces are up:
   ```bash
   docker exec clab-t1-small-sonic-dut vtysh -c "show interface brief"
   ```
3. Check IP addresses are configured:
   ```bash
   docker exec clab-t1-small-sonic-dut ip addr show
   ```

### Issue: PTF container fails to start

**Note:** The topology uses a generic Alpine Linux image. For full PTF functionality, edit the topology file to use your PTF image:
```yaml
# In topology/t1-small.clab.yml
ptf:
  kind: linux
  image: your-ptf-image:tag  # Replace with your PTF image
```

### Issue: Cannot access sonic-mgmt container

**Note:** The topology uses a generic Alpine Linux image. For full sonic-mgmt functionality, edit the topology file to use your sonic-mgmt image:
```yaml
# In topology/t1-small.clab.yml
sonic-mgmt:
  kind: linux
  image: your-sonic-mgmt-image:tag  # Replace with your image
```

## 💡 Tips

- **SONiC CLI:** Use `vtysh` for FRR routing commands
- **Config persistence:** Use `config save -y` in SONiC to save changes
- **Logs:** View container logs with `docker logs <container-name>`
- **Shell access:** Use `docker exec -it <container-name> bash`
- **Network inspection:** Use `docker network inspect clab` to see network details

## 📚 Next Steps

1. Explore the full [README.md](README.md) for detailed documentation
2. Customize BGP configurations in `configs/` directory
3. Add custom PTF tests in `configs/ptf/` directory
4. Experiment with different routing scenarios
5. Add more SONiC nodes to expand the topology

## 🔗 Useful Commands

```bash
# List all containers in the lab
sudo clab inspect -t t1-small.clab.yml

# View containerlab graph
sudo clab graph -t t1-small.clab.yml

# Save running configs from all SONiC nodes
for node in sonic-dut t0 t2; do
  docker exec clab-t1-small-$node config save -y
done

# Restart a specific container
docker restart clab-t1-small-sonic-dut

# View real-time logs
docker logs -f clab-t1-small-sonic-dut
```

