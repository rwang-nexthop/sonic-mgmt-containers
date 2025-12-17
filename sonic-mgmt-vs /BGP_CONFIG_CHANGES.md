# BGP Configuration Script Redesign

## Overview

The `configure_bgp.sh` script has been completely redesigned to follow best practices from the **bgp-free-core** and **NH-CLU-CLAB** projects.

## Key Changes

### 1. **Configuration Method**
- **Old**: Used `sonic-cfggen` with JSON files to configure BGP
- **New**: Uses `vtysh` commands directly (FRR native approach)
- **Benefit**: More reliable, follows industry standard BGP configuration

### 2. **Step-by-Step Approach**
The script now follows a structured 7-step process:

1. **Verify Containers** - Check all containers are running
2. **Configure Interfaces** - Set up IP addresses on all interfaces
3. **Enable BGP Daemon** - Start FRR bgpd service
4. **Configure DUT BGP** - Set up BGP on Device Under Test
5. **Configure Leaf BGP** - Set up BGP on all Leaf nodes
6. **Wait for Convergence** - Allow BGP sessions to establish
7. **Verify Configuration** - Display BGP status

### 3. **Enhanced Logging**
- Added `log_step()` function for major steps (blue color)
- Better visual separation with headers and dividers
- Comprehensive summary at the end
- Log file saved to `bgp_config.log`

### 4. **Better Error Handling**
- Container existence verification before configuration
- Graceful error handling with `|| true` for non-critical commands
- Clear error messages with color coding

### 5. **Configuration Details**

**DUT (Device Under Test)**
- ASN: 65000
- Router ID: 1.1.1.1
- Neighbors: 4 Leaf nodes
- Loopback: 1.1.1.1/32

**Leaf Nodes**
- ASNs: 65001-65004
- Router IDs: 10.10.10.1-10.10.10.4
- Loopbacks: 10.10.10.1-10.10.10.4/32
- Neighbor: DUT (65000)

### 6. **BGP Features Enabled**
- Router ID configuration
- BGP log neighbor changes
- No EBGP policy requirement
- IPv4 unicast address family
- Connected route redistribution
- Network advertisement

### 7. **Interface Configuration**
```
DUT Ethernet0  <-> Leaf1 Ethernet0  (10.0.0.0/31)
DUT Ethernet4  <-> Leaf2 Ethernet0  (10.0.0.4/31)
DUT Ethernet8  <-> Leaf3 Ethernet0  (10.0.0.8/31)
DUT Ethernet12 <-> Leaf4 Ethernet0  (10.0.0.12/31)
```

## Usage

```bash
# Make script executable
chmod +x configure_bgp.sh

# Run configuration
./configure_bgp.sh
```

## Output Example

```
==========================================
  SONiC-VS T0 Topology - BGP Configuration
==========================================

[STEP] Waiting for all containers to be ready...
[INFO] Waiting for sonic-vs-t0-dut to be ready...
[INFO] sonic-vs-t0-dut is ready
...
[STEP] Verifying all containers are running...
  ✓ sonic-vs-t0-dut is running
  ✓ sonic-vs-t0-leaf1 is running
...
[STEP] Configuring interfaces and IP addresses...
[INFO] Configuring DUT interfaces...
✓ All interfaces configured
...
[STEP] Verifying BGP configuration...
=== sonic-vs-t0-dut BGP Summary ===
BGP router identifier 1.1.1.1, local AS number 65000
...
```

## Verification Commands

After configuration completes, verify BGP status:

```bash
# Check BGP neighbors
docker exec sonic-vs-t0-dut vtysh -c "show ip bgp summary"

# Check BGP routes
docker exec sonic-vs-t0-dut vtysh -c "show ip bgp"

# Check routing table
docker exec sonic-vs-t0-dut vtysh -c "show ip route"

# Enter vtysh interactive mode
docker exec -it sonic-vs-t0-dut vtysh
```

## Advantages Over Previous Version

✓ Uses industry-standard vtysh commands
✓ Better error handling and validation
✓ Clearer step-by-step process
✓ Enhanced logging and output
✓ Follows best practices from production labs
✓ More reliable BGP configuration
✓ Easier to troubleshoot and debug
✓ Better documentation in code

## References

- bgp-free-core: `/Users/rwang/Python/Projects/bgp-free-core/scripts/configure_folded_clos.sh`
- NH-CLU-CLAB: `/Users/rwang/Python/Projects/NH-CLU-CLAB/scripts/configure_bgp_redistribute.sh`

