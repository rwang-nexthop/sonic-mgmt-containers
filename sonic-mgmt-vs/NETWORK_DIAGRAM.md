# Network Diagram - T1-Small Topology

## Physical Topology

```
                    Management Network (172.30.30.0/24)
                    ┌────────────────────────────────┐
                    │                                │
            ┌───────▼────────┐              ┌────────▼────────┐
            │  sonic-mgmt    │              │      PTF        │
            │  (Management)  │              │   (Testing)     │
            └────────────────┘              └────┬────┬───────┘
                                                 │    │
                                             eth0│    │eth1
                                                 │    │
                    ┌────────────────────────────┼────┼────────┐
                    │                            │    │        │
                ┌───▼────┐                  ┌────▼────▼────┐  │
                │   t0   │                  │  sonic-dut   │  │
                │ AS65000│                  │   AS65100    │  │
                │10.0.0. │                  │   10.1.0.1   │  │
                │  100   │                  │              │  │
                └───┬─┬──┘                  └──┬────────┬──┘  │
                    │ │                        │        │     │
                eth1│ │eth2                eth1│        │eth2 │
                    │ │                        │        │     │
            10.0.0.0│ │10.0.1.0        10.0.0.0│        │10.0.│
                /31 │ │ /31                /31 │        │0.2  │
                    │ │                        │        │/31  │
                    │ └────────────────────────┘        │     │
                    │                                   │     │
                    │                              ┌────▼─────▼──┐
                    │                              │     t2      │
                    │                              │   AS65200   │
                    │                              │  10.0.0.200 │
                    │                              └─────────────┘
                    │                                     │
                    └─────────────────────────────────────┘
                              10.0.1.0/31 (interconnect)
```

## Detailed Connection Map

### sonic-dut (DUT - Device Under Test)

| Interface | IP Address | Connected To | Remote IP | Purpose |
|-----------|------------|--------------|-----------|---------|
| Ethernet0 (eth1) | 10.0.0.0/31 | t0:eth1 | 10.0.0.1 | BGP peering to T0 |
| Ethernet4 (eth2) | 10.0.0.2/31 | t2:eth1 | 10.0.0.3 | BGP peering to T2 |
| Ethernet8 (eth3) | 10.0.0.4/31 | ptf:eth0 | - | PTF test port 0 |
| Ethernet12 (eth4) | 10.0.0.6/31 | ptf:eth1 | - | PTF test port 1 |
| Loopback0 | 10.1.0.1/32 | - | - | BGP router ID |

**BGP Configuration:**
- AS Number: 65100
- Router ID: 10.1.0.1
- Neighbors: 10.0.0.1 (AS 65000), 10.0.0.3 (AS 65200)

### t0 (Tier 0 Neighbor)

| Interface | IP Address | Connected To | Remote IP | Purpose |
|-----------|------------|--------------|-----------|---------|
| Ethernet0 (eth1) | 10.0.0.1/31 | sonic-dut:eth1 | 10.0.0.0 | BGP peering to DUT |
| Ethernet4 (eth2) | 10.0.1.0/31 | t2:eth2 | 10.0.1.1 | BGP peering to T2 |
| Loopback0 | 10.0.0.100/32 | - | - | BGP router ID |

**BGP Configuration:**
- AS Number: 65000
- Router ID: 10.0.0.100
- Neighbors: 10.0.0.0 (AS 65100), 10.0.1.1 (AS 65200)
- Advertised Networks: 192.168.0.0/24

### t2 (Tier 2 Neighbor)

| Interface | IP Address | Connected To | Remote IP | Purpose |
|-----------|------------|--------------|-----------|---------|
| Ethernet0 (eth1) | 10.0.0.3/31 | sonic-dut:eth2 | 10.0.0.2 | BGP peering to DUT |
| Ethernet4 (eth2) | 10.0.1.1/31 | t0:eth2 | 10.0.1.0 | BGP peering to T0 |
| Loopback0 | 10.0.0.200/32 | - | - | BGP router ID |

**BGP Configuration:**
- AS Number: 65200
- Router ID: 10.0.0.200
- Neighbors: 10.0.0.2 (AS 65100), 10.0.1.0 (AS 65000)
- Advertised Networks: 192.168.2.0/24

### PTF (Packet Test Framework)

| Interface | Connected To | Purpose |
|-----------|--------------|---------|
| eth0 | Management Network | Containerlab management (reserved) |
| eth1 | sonic-dut:eth3 | Test traffic injection/capture port 0 |
| eth2 | sonic-dut:eth4 | Test traffic injection/capture port 1 |

## BGP Peering Matrix

| Local Node | Local AS | Neighbor IP | Remote AS | Remote Node | Status |
|------------|----------|-------------|-----------|-------------|--------|
| sonic-dut | 65100 | 10.0.0.1 | 65000 | t0 | eBGP |
| sonic-dut | 65100 | 10.0.0.3 | 65200 | t2 | eBGP |
| t0 | 65000 | 10.0.0.0 | 65100 | sonic-dut | eBGP |
| t0 | 65000 | 10.0.1.1 | 65200 | t2 | eBGP |
| t2 | 65200 | 10.0.0.2 | 65100 | sonic-dut | eBGP |
| t2 | 65200 | 10.0.1.0 | 65000 | t0 | eBGP |

## Traffic Flow Examples

### Example 1: t0 to t2 via sonic-dut

**Path:**
```
t0 (192.168.0.0/24) → sonic-dut → t2 (192.168.2.0/24)
```

**Detailed Flow:**
1. Packet originates from t0 network (192.168.0.0/24)
2. t0 forwards to sonic-dut via 10.0.0.0/31 link
3. sonic-dut receives on Ethernet0, looks up route
4. sonic-dut forwards to t2 via 10.0.0.2/31 link
5. t2 receives on Ethernet0, delivers to 192.168.2.0/24

### Example 2: t0 to t2 direct path

**Path:**
```
t0 (192.168.0.0/24) → t2 (192.168.2.0/24)
```

**Detailed Flow:**
1. Packet originates from t0 network
2. t0 forwards directly to t2 via 10.0.1.0/31 link
3. t2 receives on Ethernet4, delivers to destination

### Example 3: PTF traffic injection

**Path:**
```
PTF eth1 → sonic-dut eth3 → sonic-dut routing → sonic-dut eth1 → t0
```

**Use Case:** Testing data plane forwarding on sonic-dut

## Container Names (Containerlab)

| Device | Container Name | Management IP | Kind |
|--------|----------------|---------------|------|
| sonic-dut | clab-t1-small-sonic-dut | 172.30.30.x | sonic-vs |
| t0 | clab-t1-small-t0 | 172.30.30.x | sonic-vs |
| t2 | clab-t1-small-t2 | 172.30.30.x | sonic-vs |
| ptf | clab-t1-small-ptf | 172.30.30.x | linux |
| sonic-mgmt | clab-t1-small-sonic-mgmt | 172.30.30.x | linux |

## Port Mappings

| Service | Container | Container Port | Host Port | URL |
|---------|-----------|----------------|-----------|-----|
| HTTP | sonic-dut | 80 | 8080 | http://localhost:8080 |
| HTTPS | sonic-dut | 443 | 8443 | https://localhost:8443 |
| PTF RPC | ptf | 8009 | 8009 | tcp://localhost:8009 |

## Interface Naming Convention

SONiC uses the following interface naming:
- **eth1** → **Ethernet0**
- **eth2** → **Ethernet4**
- **eth3** → **Ethernet8**
- **eth4** → **Ethernet12**

This mapping is reflected in the config_db.json files.

## Verification Commands

### Check BGP Status

```bash
# On sonic-dut
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary"

# On t0
docker exec clab-t1-small-t0 vtysh -c "show ip bgp summary"

# On t2
docker exec clab-t1-small-t2 vtysh -c "show ip bgp summary"
```

### Check Routes

```bash
# View all routes on sonic-dut
docker exec clab-t1-small-sonic-dut vtysh -c "show ip route"

# View only BGP routes
docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp"
```

### Test Connectivity

```bash
# From sonic-dut to t0
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.1

# From sonic-dut to t2
docker exec clab-t1-small-sonic-dut ping -c 3 10.0.0.3

# From t0 to t2
docker exec clab-t1-small-t0 ping -c 3 10.0.1.1
```

### Check LLDP Neighbors

```bash
# On sonic-dut
docker exec clab-t1-small-sonic-dut show lldp table
```

### PTF Interface Check

```bash
# List PTF interfaces
docker exec clab-t1-small-ptf ip link show

# Check connectivity from PTF
docker exec clab-t1-small-ptf ping -c 3 10.0.0.4
```

