# Network Configuration Fix Summary

## Problem Identified
BGP neighbors were not establishing connections. The issue was incorrect interface naming in the topology file.

**Key Understanding:**
- **Topology file**: Must use Linux interface names: `eth1`, `eth2`, `eth3` (where X > 0)
- **Config files**: Must use SONiC port names: `Ethernet0`, `Ethernet4`, `Ethernet8`
- **Mapping**: `eth1` → `Ethernet0`, `eth2` → `Ethernet4`, `eth3` → `Ethernet8`

The SONiC-VM containerlab kind requires this specific naming convention.

## Changes Made

### 1. Topology File (sonic-vs-t0.clab.yml)
**Corrected to use Linux interface names (ethX where X > 0):**
- `dut:eth1` ↔ `leaf1:eth1` (maps to Ethernet0 on both sides)
- `dut:eth2` ↔ `leaf2:eth1` (maps to Ethernet4 on DUT, Ethernet0 on Leaf2)
- `leaf1:eth2` ↔ `leaf2:eth2` (maps to Ethernet4 on both sides)

### 2. DUT Config (configs/dut/config_db.json)
**Interface Configuration (SONiC port names):**
- PORT: `Ethernet0`, `Ethernet4` (up)
- INTERFACE: `Ethernet0|10.0.0.0/31`, `Ethernet4|10.0.1.0/31`

**BGP Configuration:**
- ASN: 65000, Router ID: 1.1.1.1
- Neighbors: `10.0.0.1` (leaf1, ASN 65101), `10.0.1.1` (leaf2, ASN 65102)
- Route Maps: `PERMIT_ALL`

### 3. Leaf1 Config (configs/leaf1/config_db.json)
**Interface Configuration (SONiC port names):**
- PORT: `Ethernet0`, `Ethernet4`, `Ethernet8` (up)
- INTERFACE: `Ethernet0|10.0.0.1/31`, `Ethernet4|10.0.2.0/31`, `Ethernet8|192.168.1.1/24`

**BGP Configuration:**
- ASN: 65101, Router ID: 11.11.11.11
- Neighbors: `10.0.0.0` (DUT, ASN 65000), `10.0.2.1` (leaf2, ASN 65102)
- Advertises: `192.168.1.0/24`

### 4. Leaf2 Config (configs/leaf2/config_db.json)
**Interface Configuration (SONiC port names):**
- PORT: `Ethernet0`, `Ethernet4`, `Ethernet8` (up)
- INTERFACE: `Ethernet0|10.0.1.1/31`, `Ethernet4|10.0.2.1/31`, `Ethernet8|192.168.2.1/24`

**BGP Configuration:**
- ASN: 65102, Router ID: 12.12.12.12
- Neighbors: `10.0.1.0` (DUT, ASN 65000), `10.0.2.0` (leaf1, ASN 65101)
- Advertises: `192.168.2.0/24`

## Network Topology After Fix

```
DUT (1.1.1.1)
├─ Ethernet0 (10.0.0.0/31) ──── Leaf1 Ethernet0 (10.0.0.1/31)
└─ Ethernet4 (10.0.1.0/31) ──── Leaf2 Ethernet0 (10.0.1.1/31)

Leaf1 (11.11.11.11)
├─ Ethernet0 (10.0.0.1/31) ──── DUT Ethernet0
├─ Ethernet4 (10.0.2.0/31) ──── Leaf2 Ethernet4 (10.0.2.1/31)
└─ Ethernet8 (192.168.1.1/24) - Local subnet

Leaf2 (12.12.12.12)
├─ Ethernet0 (10.0.1.1/31) ──── DUT Ethernet4
├─ Ethernet4 (10.0.2.1/31) ──── Leaf1 Ethernet4 (10.0.2.0/31)
└─ Ethernet8 (192.168.2.1/24) - Local subnet
```

## BGP Configuration
- DUT: ASN 65000, Router ID 1.1.1.1
- Leaf1: ASN 65101, Router ID 11.11.11.11
- Leaf2: ASN 65102, Router ID 12.12.12.12

All route maps standardized to `PERMIT_ALL` for simplicity.

## Next Steps
1. Destroy old topology: `sudo containerlab destroy -t sonic-vs-t0.clab.yml --cleanup`
2. Deploy new topology: `sudo containerlab deploy -t sonic-vs-t0.clab.yml`
3. Verify BGP: `docker exec clab-sonic-vs-t0-dut bash -c "show bgp summary"`
4. Test connectivity: `docker exec clab-sonic-vs-t0-dut bash -c "ping -c 3 11.11.11.11"`

