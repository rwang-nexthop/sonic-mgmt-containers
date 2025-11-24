# Deployment Script Updates

## Changes Made to deploy_config.sh

### 1. Enhanced Inventory Configuration
Added complete Ansible variables required for test execution:
- `ansible_become=yes` - Enable privilege escalation
- `ansible_become_method=sudo` - Use sudo for escalation
- `ansible_become_user=root` - Escalate to root
- `ansible_become_pass=admin` - Password for sudo

### 2. Enhanced Testbed Configuration
Added missing fields:
- `topo_name: t1-small-vm` - Topology identifier
- `neighbor_type: sonic` - Type of neighbors
- Fixed `ptf_ip` from 172.30.30.6 to 172.30.30.5

### 3. New Functions Added

#### fix_cache_permissions()
Fixes pytest cache directory permissions:
```bash
chmod -R 777 /sonic-mgmt/tests/.pytest_cache
chmod -R 777 /sonic-mgmt/tests/_cache
```

#### create_ansible_config()
Creates `/sonic-mgmt/ansible/ansible.cfg` with:
- Library paths for Ansible modules
- Host key checking disabled
- Deprecation warnings disabled
- Inventory path configured

### 4. Updated Script Flow
Changed from 2 steps to 4 steps:
1. Pre-Deployment Checks
2. Create Configuration Files
3. Fix Cache Permissions (NEW)
4. Create Ansible Configuration (NEW)
5. Check Connectivity

### 5. Updated Documentation
Enhanced next steps with:
- Ansible connectivity verification
- Proper test execution commands
- Clear step-by-step instructions

## Files Updated
- `/Users/rwang/Python/Projects/sonic-mgmt-vm/scripts/deploy_config.sh`
- `/Users/rwang/Python/Projects/sonic-mgmt-vs/scripts/deploy_config.sh`

## How to Use

```bash
cd ~/sonic-mgmt-containers/sonic-mgmt-vm/scripts
./deploy_config.sh
```

Then follow the printed instructions to run tests.

