# Sonic-MGMT Test Commands for ContainerLab

Copy and paste each command block into the sonic-mgmt container.

## Setup (Run Once)
```bash
cd /var/src/sonic-mgmt-master/tests
```

---

## Test 1: BGP Facts (No PTF)
**Purpose:** Verify BGP configuration is loaded correctly
```bash
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 2: Ping BGP Neighbors (No PTF)
**Purpose:** Test connectivity to BGP neighbors via ping
```bash
python -m pytest bgp/test_ping_bgp_neighbor.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 3: Interface Status (No PTF)
**Purpose:** Verify interface configuration and status
```bash
python -m pytest test_interfaces.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 4: SNMP Loopback (No PTF)
**Purpose:** Test SNMP queries over loopback IP
```bash
python -m pytest snmp/test_snmp_loopback.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 5: SSH Default Password (No PTF)
**Purpose:** Verify SSH default credentials
```bash
python -m pytest ssh/test_ssh_default_password.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 6: LLDP (No PTF)
**Purpose:** Test LLDP neighbor discovery
```bash
python -m pytest lldp/test_lldp.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 7: NTP (No PTF)
**Purpose:** Verify NTP configuration
```bash
python -m pytest ntp/test_ntp.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 8: Platform Info (No PTF)
**Purpose:** Verify platform information retrieval
```bash
python -m pytest platform_tests/test_platform_info.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 9: BGP Session (No PTF)
**Purpose:** Verify BGP session establishment
```bash
python -m pytest bgp/test_bgp_session.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Test 10: BGP Command (No PTF)
**Purpose:** Test BGP CLI commands
```bash
python -m pytest bgp/test_bgp_command.py -v \
  --testbed clab-sonic-vs-t0 \
  --testbed_file clab_testbed.yaml \
  --host-pattern dut \
  --inventory /var/src/ansible/clab_inventory.yml
```

---

## Notes
- All tests are **non-PTF** (no packet generation required)
- Tests use Ansible fixtures to connect to DUT
- Tests use SSH commands to query device state
- Results will show: PASSED, FAILED, or SKIPPED
- SKIPPED = test requirements not met for this topology

