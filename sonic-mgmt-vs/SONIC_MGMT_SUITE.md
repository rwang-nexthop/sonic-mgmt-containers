# Using sonic-mgmt Test Suite to Test SONiC Containers

## What is sonic-mgmt?

**sonic-mgmt** is the official SONiC management and testing framework from the sonic-net GitHub repository. It provides:
- **Testbed deployment** - Automated setup of SONiC test environments
- **Test infrastructure** - Pytest-based testing framework with 100+ test categories
- **Device management** - Ansible-based automation for device configuration
- **Test reporting** - Junit XML report generation and processing

**GitHub**: https://github.com/sonic-net/sonic-mgmt

## Overview

The sonic-mgmt test suite is a comprehensive pytest-based framework for testing SONiC devices. It uses:
- **Pytest** - Test runner and framework
- **Ansible** - Device management and configuration
- **PTF** - Packet Test Framework for data plane testing
- **Fixtures** - Reusable test components (duthosts, ptfhost, etc.)

## sonic-mgmt Docker Image

### Official Images

The sonic-mgmt framework is distributed as a Docker container image:

**Official Registry**: `sonicdev-microsoft.azurecr.io:443/docker-sonic-mgmt`

**Available Tags**:
- `latest` - Latest stable release
- `master` - Latest development version
- `<version>` - Specific version tags

### Using sonic-mgmt Container

The sonic-mgmt container includes:
- Python 3.x with pytest
- Ansible for device management
- All required dependencies and libraries
- Pre-configured test infrastructure

### Setup sonic-mgmt Container

Use the official setup script:

```bash
# Clone sonic-mgmt repository
git clone https://github.com/sonic-net/sonic-mgmt.git
cd sonic-mgmt

# Run setup script
./setup-container.sh -n sonic-mgmt-container -i sonicdev-microsoft.azurecr.io:443/docker-sonic-mgmt

# Enter container
docker exec -u <username> -it sonic-mgmt-container bash
```

### For Your Containerlab Deployment

In your `t1-small.clab.yml`, the sonic-mgmt container is already configured:

```yaml
sonic-mgmt:
  image: docker-sonic-mgmt-rwang:master  # Your custom image
  container_name: clab-t1-small-sonic-mgmt
  network_mode: host
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /etc/sonic:/etc/sonic
```

## Key Components

### 1. Testbed Configuration
Defines the topology and device information:
```yaml
# testbed.yaml
- name: t1-small
  topology: t1
  dut:
    - sonic-dut
  ptf_image_name: docker-ptf
  ptf:
    - ptf
  neighbors:
    - t0
    - t2
```

### 2. Inventory File
Maps device names to IP addresses and credentials:
```ini
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin

[t0]
t0 ansible_host=172.30.30.3 ansible_user=admin

[t2]
t2 ansible_host=172.30.30.2 ansible_user=admin
```

### 3. Test Structure
Tests are organized by feature:
```
tests/
├── bgp/              # BGP protocol tests
├── route/            # Routing tests
├── interface/        # Interface tests
├── system_health/    # System monitoring
├── common/           # Shared utilities and fixtures
└── conftest.py       # Pytest configuration
```

## Running Tests

### Basic Test Execution
```bash
# Run single test
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut

# Run test category
python -m pytest bgp/ -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut

# Run with specific marker
python -m pytest -v -m "topology_t1" \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

### Test Markers
```bash
# Example with markers (always include --testbed, --testbed_file, and --inventory)
python -m pytest -v -m "topology_t1" \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini

# Topology markers
-m "topology_t0"        # T0 topology tests
-m "topology_t1"        # T1 topology tests
-m "topology_ptf"       # PTF tests

# Platform markers
-m "platform_virtual"   # Virtual switch tests
-m "platform_broadcom"  # Broadcom-specific tests

# Feature markers
-m "bgp"                # BGP tests
-m "acl"                # ACL tests
-m "reboot"             # Reboot tests
```

## Key Fixtures

### duthosts
Access to DUT (Device Under Test) containers:
```python
def test_example(duthosts, enum_frontend_dut_hostname):
    dut = duthosts[enum_frontend_dut_hostname]
    # Run commands on DUT
    result = dut.shell("show ip bgp summary")
```

### ptfhost
Access to PTF container for packet testing:
```python
def test_packet_test(ptfhost):
    # Send/receive packets
    ptfhost.shell("python ptf_test.py")
```

### ansible_adhoc
Direct Ansible module execution:
```python
def test_with_ansible(ansible_adhoc):
    # Run Ansible modules
    ansible_adhoc(inventory="sonic-dut", module="shell", 
                  args="show version")
```

## Common Test Patterns

### BGP Testing
```python
def test_bgp_neighbors(duthosts, enum_frontend_dut_hostname):
    dut = duthosts[enum_frontend_dut_hostname]
    # Get BGP facts
    bgp_facts = dut.bgp_facts()
    # Verify neighbors
    assert len(bgp_facts['ansible_facts']['bgp_neighbors']) > 0
```

### Interface Testing
```python
def test_interface_status(duthosts, enum_frontend_dut_hostname):
    dut = duthosts[enum_frontend_dut_hostname]
    # Get interface status
    result = dut.shell("show interface status")
    # Verify all interfaces are up
    assert "down" not in result['stdout']
```

### Configuration Testing
```python
def test_config_reload(duthosts, enum_frontend_dut_hostname):
    dut = duthosts[enum_frontend_dut_hostname]
    # Reload configuration
    dut.shell("config reload -y")
    # Verify system is stable
    assert dut.shell("show system-health status")['rc'] == 0
```

## Debugging Tests

### Verbose Output
```bash
# Very verbose with local variables
python -m pytest bgp/test_bgp_fact.py -vv --showlocals \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini --host-pattern sonic-dut

# Short traceback
python -m pytest bgp/test_bgp_fact.py -v --tb=short \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini --host-pattern sonic-dut

# Full traceback
python -m pytest bgp/test_bgp_fact.py -v --tb=long \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini --host-pattern sonic-dut
```

### Collect Tests Without Running
```bash
# List all tests
python -m pytest bgp/ --collect-only \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini

# List tests matching pattern
python -m pytest bgp/ --collect-only -k "session" \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini
```

## Test Categories Available

| Category | Purpose | Example |
|----------|---------|---------|
| bgp/ | BGP protocol | test_bgp_fact.py, test_bgp_session.py |
| route/ | Routing | test_static_route.py, test_route_consistency.py |
| interface/ | Interfaces | test_interfaces.py |
| system_health/ | System monitoring | test_system_status.py |
| process_monitoring/ | Container/process | test_critical_process_monitoring.py |
| counter/ | Statistics | test_xon_xoff.py |
| lldp/ | LLDP discovery | test_lldp.py |
| arp/ | ARP protocol | test_arp.py |
| fib/ | Forwarding table | test_fib.py (requires PTF) |
| acl/ | Access control | test_acl.py |

## Complete Workflow for Your t1-small Topology

### Step 1: Enter sonic-mgmt Container

The sonic-mgmt container is where all testing happens. This container has pytest, Ansible, and all testing tools pre-installed.

```bash
# SSH to your remote server (if needed)
ssh user@remote-server

# Enter the sonic-mgmt container
docker exec -it clab-t1-small-sonic-mgmt bash

# You should now see a prompt like: rwang@sonic-mgmt:~$
```

### Step 2: Create Configuration Files

The `/configs` directory may be read-only if mounted from the host. Create files in a writable location instead.

**Option A: Create in /tmp (Temporary - Lost on Container Restart)**

```bash
# Create temporary config directory
mkdir -p /tmp/sonic-configs
cd /tmp/sonic-configs

# Create inventory.ini file
cat > /tmp/sonic-configs/inventory.ini << 'EOF'
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin

[t0]
t0 ansible_host=172.30.30.3 ansible_user=admin

[t2]
t2 ansible_host=172.30.30.2 ansible_user=admin

[ptf]
ptf ansible_host=172.30.30.6 ansible_user=root
EOF

# Create testbed.yaml file
cat > /tmp/sonic-configs/testbed.yaml << 'EOF'
- name: t1-small
  topology: t1
  dut:
    - sonic-dut
  ptf_image_name: docker-ptf
  ptf:
    - ptf
  neighbors:
    - t0
    - t2
EOF

# Verify files were created
ls -la /tmp/sonic-configs/
cat /tmp/sonic-configs/inventory.ini
```

**Option B: Create on Host and Mount (Persistent)**

If `/configs` is read-only, you need to create files on the host and mount them. Edit your `t1-small.clab.yml`:

```yaml
sonic-mgmt:
  image: docker-sonic-mgmt-rwang:master
  container_name: clab-t1-small-sonic-mgmt
  network_mode: host
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /etc/sonic:/etc/sonic
    - /path/to/host/configs:/configs  # Add this line
```

Then on the host, create the files:

```bash
# On host machine
mkdir -p ~/sonic-configs

cat > ~/sonic-configs/inventory.ini << 'EOF'
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin

[t0]
t0 ansible_host=172.30.30.3 ansible_user=admin

[t2]
t2 ansible_host=172.30.30.2 ansible_user=admin

[ptf]
ptf ansible_host=172.30.30.6 ansible_user=root
EOF

cat > ~/sonic-configs/testbed.yaml << 'EOF'
- name: t1-small
  topology: t1
  dut:
    - sonic-dut
  ptf_image_name: docker-ptf
  ptf:
    - ptf
  neighbors:
    - t0
    - t2
EOF

# Redeploy topology
clab deploy -t topology/t1-small.clab.yml
```

### Step 3: Verify Connectivity Before Running Tests

**IMPORTANT**: The SONiC containers (sonic-dut, t0, t2) do NOT have SSH services running. Instead, sonic-mgmt uses `docker exec` to communicate with them. This is the correct approach for containerized testing.

**Verify containers are running and reachable**:

```bash
# Inside sonic-mgmt container

# Check if containers are running
docker ps

# Test basic connectivity to sonic-dut using docker exec
docker exec clab-t1-small-sonic-dut vtysh -c "show version"

# Test connectivity to t0
docker exec clab-t1-small-t0 vtysh -c "show version"

# Test connectivity to t2
docker exec clab-t1-small-t2 vtysh -c "show version"

# Expected output: Version information from each device
```

**If you see "Connection refused" errors with Ansible SSH**:

This is NORMAL and expected. The SONiC containers don't have SSH enabled. The sonic-mgmt test framework handles this automatically - it uses `docker exec` internally, not SSH.

**Verify the containers are accessible**:

```bash
# Inside sonic-mgmt container

# List all running containers
docker ps | grep clab-t1-small

# Check sonic-dut is running
docker ps | grep sonic-dut

# Verify network connectivity
ping -c 2 172.30.30.4  # sonic-dut
ping -c 2 172.30.30.3  # t0
ping -c 2 172.30.30.2  # t2
```

If containers are running and pings work, you're ready to run tests.

### Step 4: Run Tests

Now you can run the actual tests. Both `--testbed` (testbed name) and `--testbed_file` (testbed file path) are **REQUIRED** for pytest to work correctly.

**Quick BGP Test (Recommended First Test)**:
```bash
# Navigate to tests directory
cd /sonic-mgmt/tests

# Run BGP fact test - gathers BGP neighbor information
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

**Run All BGP Tests**:
```bash
python -m pytest bgp/ -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

**Run Interface Tests**:
```bash
python -m pytest interface/ -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

**Run Routing Tests**:
```bash
python -m pytest route/ -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

**Run System Health Tests**:
```bash
python -m pytest system_health/ -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

### Step 5: Interpret Test Results

After running tests, you'll see output like:

```
test_bgp_fact.py::test_bgp_facts PASSED                                 [100%]
```

Result meanings:

- ✅ **PASSED** - Test succeeded, everything is working
- ❌ **FAILED** - Test failed, check the error message below
- ⊘ **SKIPPED** - Test skipped (topology/platform doesn't match)
- ⚠ **ERROR** - Test error (usually configuration issue)

**Example: Successful BGP Test Output**:
```
test_bgp_fact.py::test_bgp_facts PASSED [100%]
======================== 1 passed in 2.34s ========================
```

**Example: Failed Test Output**:
```
test_bgp_fact.py::test_bgp_facts FAILED [100%]
AssertionError: BGP neighbor not found
```

### Step 6: Run Full Verification Script

After tests pass, run the comprehensive verification script to check overall topology health:

```bash
# Exit sonic-mgmt container (if needed)
exit

# Run verification script from host
cd ~/sonic-mgmt-containers/sonic-mgmt-vs/scripts
./verify_topology.sh

# This will show:
# - Container status
# - BGP neighbor status
# - Interface configuration
# - Routing tables
# - Connectivity tests
# - And more...
```

## Tips & Tricks

1. **Filter tests by name**: Use `-k` flag
   ```bash
   pytest bgp/ -k "session" -v \
     --testbed t1-small \
     --testbed_file /tmp/sonic-configs/testbed.yaml \
     --inventory /tmp/sonic-configs/inventory.ini
   ```

2. **Stop on first failure**: Use `-x` flag
   ```bash
   pytest bgp/ -x -v \
     --testbed t1-small \
     --testbed_file /tmp/sonic-configs/testbed.yaml \
     --inventory /tmp/sonic-configs/inventory.ini
   ```

3. **Run N tests**: Use `--maxfail=N`
   ```bash
   pytest bgp/ --maxfail=3 -v \
     --testbed t1-small \
     --testbed_file /tmp/sonic-configs/testbed.yaml \
     --inventory /tmp/sonic-configs/inventory.ini
   ```

4. **Save output**: Redirect to file
   ```bash
   pytest bgp/ -v \
     --testbed t1-small \
     --testbed_file /tmp/sonic-configs/testbed.yaml \
     --inventory /tmp/sonic-configs/inventory.ini > test_results.log 2>&1
   ```

5. **Parallel execution**: Use pytest-xdist
   ```bash
   pytest bgp/ -n auto -v \
     --testbed t1-small \
     --testbed_file /tmp/sonic-configs/testbed.yaml \
     --inventory /tmp/sonic-configs/inventory.ini
   ```

6. **Verbose debugging**: Show local variables
   ```bash
   pytest bgp/test_bgp_fact.py -vv --showlocals \
     --testbed t1-small \
     --testbed_file /tmp/sonic-configs/testbed.yaml \
     --inventory /tmp/sonic-configs/inventory.ini
   ```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│         sonic-mgmt Container                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Pytest Framework                                │   │
│  │  ├── conftest.py (fixtures)                      │   │
│  │  ├── pytest.ini (markers)                        │   │
│  │  └── tests/ (100+ test categories)               │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Ansible Integration                             │   │
│  │  ├── Inventory (device definitions)              │   │
│  │  ├── Playbooks (deployment/config)               │   │
│  │  └── Modules (custom SONiC modules)              │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  PTF Framework                                   │   │
│  │  ├── Packet injection/capture                    │   │
│  │  └── Data plane testing                          │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
         ↓ (SSH/Ansible)
┌─────────────────────────────────────────────────────────┐
│  SONiC Containers (DUT, T0, T2)                         │
│  ├── sonic-dut (Device Under Test)                      │
│  ├── t0 (Upstream neighbor)                             │
│  └── t2 (Downstream neighbor)                           │
└─────────────────────────────────────────────────────────┘
```

## Troubleshooting

### AttributeError: 'NoneType' object has no attribute 'endswith'

**Problem**: You see this error when running pytest:
```
AttributeError: 'NoneType' object has no attribute 'endswith'
```

**Cause**: Missing or incorrect pytest parameters. The `--testbed` and `--testbed_file` parameters are **REQUIRED**.

**Solution**: Make sure you're using BOTH parameters:

```bash
# ❌ WRONG - Missing --testbed_file
python -m pytest bgp/test_bgp_fact.py -v \
  --inventory /tmp/sonic-configs/inventory.ini

# ✅ CORRECT - Include both parameters
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

**Key Points**:
- `--testbed t1-small` = The testbed NAME (from the "name:" field in testbed.yaml)
- `--testbed_file /tmp/sonic-configs/testbed.yaml` = The testbed FILE PATH
- Both are required by the sonic-mgmt framework

### Host unreachable in the inventory

**Problem**: You see this error when running pytest:
```
[WARNING]: Unable to parse /sonic-mgmt/ansible/sonic as an inventory source
[WARNING]: No inventory was parsed, only implicit localhost is available
...
AnsibleConnectionFailure: Host unreachable in the inventory
```

**Cause**: Ansible can't find the inventory file because:
1. The `inv_name` field in testbed.yaml tells Ansible which inventory file to use
2. Ansible looks for it in `/sonic-mgmt/ansible/{inv_name}`
3. If `inv_name: sonic`, Ansible looks for `/sonic-mgmt/ansible/sonic`
4. If that file doesn't exist, Ansible can't resolve hostnames

**Solution**: The deploy script now:
1. Creates the inventory file in `/sonic-mgmt/ansible/t1-small` (where Ansible expects it)
2. Sets `inv_name: t1-small` in testbed.yaml (matches the inventory file name)
3. Also copies it to `/tmp/sonic-configs/inventory.ini` for reference

The key is that `inv_name` must match the inventory file name in `/sonic-mgmt/ansible/`.

### KeyError: 'tg_api_server'

**Problem**: You see this error when running pytest:
```
KeyError: 'tg_api_server'
```

**Cause**: The testbed.yaml is using the wrong format. There are TWO testbed formats in sonic-mgmt:
- **OLD format** (what you need): Uses `conf-name`, `ptf_ip`, `dut` list
- **NEW NUT format** (for advanced setups): Uses `name`, `duts`, `tgs`, `tg_api_server`

Your testbed.yaml was using the NEW format but sonic-mgmt expects the OLD format.

**Solution**: The deploy script now creates the correct OLD format with proper `inv_name`:
```yaml
- conf-name: t1-small
  group-name: t1-small-group
  topo: t1
  ptf_image_name: docker-ptf
  ptf: ptf
  ptf_ip: 172.30.30.6/24
  server: localhost
  dut:
    - sonic-dut
  inv_name: t1-small
  auto_recover: 'False'
  comment: t1-small topology for sonic-mgmt testing
```

Just run the updated deploy script and it will create the correct format.

### Config Files Not Found

**Problem**: You see `/tmp/sonic-configs/: No such file or directory`

**Cause**: The `deploy_config.sh` script hasn't been run yet.

**Solution**:
1. Exit the sonic-mgmt container: `exit`
2. Run the deploy script: `cd ~/sonic-mgmt-containers/sonic-mgmt-vs/scripts && ./deploy_config.sh`
3. Re-enter the container: `docker exec -it clab-t1-small-sonic-mgmt bash`
4. Run tests with correct parameters

### SSH Connection Refused Errors (NORMAL - Don't Worry!)

**Problem**: You see "Connection refused" or "UNREACHABLE" errors when trying to connect via SSH

**This is NORMAL and expected!** SONiC containers don't have SSH services running. The sonic-mgmt framework handles this automatically by using `docker exec` internally, not SSH.

**Verify containers are accessible**:
```bash
# Inside sonic-mgmt container

# Check containers are running
docker ps | grep clab-t1-small

# Test direct access to sonic-dut
docker exec clab-t1-small-sonic-dut vtysh -c "show version"

# Test direct access to t0
docker exec clab-t1-small-t0 vtysh -c "show version"

# Test direct access to t2
docker exec clab-t1-small-t2 vtysh -c "show version"
```

If these commands work, your containers are accessible and tests will run fine.

### Connection Issues

**Problem**: Tests fail with "Connection refused" or "Unreachable"

**Solution**:
1. Verify containers are running: `docker ps | grep clab-t1-small`
2. Check network connectivity: `ping 172.30.30.4`
3. Verify container IPs match inventory file (172.30.30.x)
4. Check device logs: `docker logs clab-t1-small-sonic-dut`

### Test Failures

**Problem**: Tests fail with "FAILED" status

**Solution**:
1. Check device logs: `docker logs clab-t1-small-sonic-dut`
2. Verify BGP is running: `docker exec clab-t1-small-sonic-dut vtysh -c "show ip bgp summary"`
3. Check interface status: `docker exec clab-t1-small-sonic-dut vtysh -c "show interface"`
4. Review test output for specific error messages

### View Test Logs
```bash
# Show last 50 lines of test output
pytest bgp/test_bgp_fact.py -v --tb=short \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini | tail -50

# Full traceback
pytest bgp/test_bgp_fact.py -v --tb=long \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini

# Run with verbose debugging
pytest bgp/test_bgp_fact.py -vv --showlocals \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini
```

### Verify Testbed Configuration
```bash
# List all available tests
pytest --collect-only \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini

# List tests matching pattern
pytest --collect-only -k "bgp" \
  --testbed t1-small \
  --testbed_file /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini
```

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| SSH Connection refused | Normal - no SSH on SONiC containers | Ignore, tests use docker exec |
| Containers unreachable | Containers not running | Run `docker ps` and check status |
| BGP tests fail | BGP not configured | Run `./deploy_config.sh` first |
| Interface tests fail | Interfaces not up | Check interface status with vtysh |
| Ansible warnings about groups | Normal Ansible behavior | Can be ignored, doesn't affect tests |

## Resources

- **GitHub**: https://github.com/sonic-net/sonic-mgmt
- **SONiC Wiki**: https://github.com/sonic-net/SONiC/wiki
- **Pytest Docs**: https://docs.pytest.org/
- **Ansible Docs**: https://docs.ansible.com/

