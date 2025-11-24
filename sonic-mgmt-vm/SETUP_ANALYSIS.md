# Sonic-MGMT Test Setup Analysis

## Key Issues Found

### 1. **Missing Ansible Library Modules**
The error `AttributeError: 'config_facts' object has no attribute` indicates the Ansible library path is not configured.

**Required:**
- Ansible library modules must be in `/sonic-mgmt/tests/library/`
- Key modules: `config_facts.py`, `sysfs_facts.py`, etc.

### 2. **Inventory File Issues**
Current inventory is missing critical Ansible variables:

**Current (Incomplete):**
```ini
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin ansible_password=admin
```

**Required (Complete):**
```ini
[sonic]
sonic-dut ansible_host=172.30.30.4 ansible_user=admin ansible_password=admin \
  ansible_connection=ssh ansible_become=yes ansible_become_method=sudo \
  ansible_become_user=root ansible_become_pass=admin
```

### 3. **Testbed Configuration**
The testbed.yaml needs additional fields for proper test execution:

**Missing Fields:**
- `ptf_image_name` - PTF container image
- `ptf_ip` - PTF management IP
- `neighbor_type` - Type of neighbors (sonic, eos, etc.)
- `topo_name` - Topology name for test selection

### 4. **Permission Issues**
Cache directories need proper permissions:
```bash
sudo chmod -R 777 /sonic-mgmt/tests/.pytest_cache
sudo chmod -R 777 /sonic-mgmt/tests/_cache
```

### 5. **Ansible Configuration**
Need `ansible.cfg` in sonic-mgmt container:
```ini
[defaults]
library = /sonic-mgmt/tests/library
host_key_checking = False
```

## Required Setup Steps

1. **Copy Ansible library modules** from sonic-mgmt repo
2. **Update inventory** with all required Ansible variables
3. **Update testbed.yaml** with complete topology info
4. **Fix cache permissions** in sonic-mgmt container
5. **Create ansible.cfg** in sonic-mgmt container
6. **Verify SSH key-based auth** (optional but recommended)

## Next Actions

Update deploy_config.sh to:
- Create ansible.cfg
- Fix cache permissions
- Add complete inventory variables
- Validate Ansible library path

