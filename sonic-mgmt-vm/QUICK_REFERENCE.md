# Quick Reference - Running sonic-mgmt Tests

## Prerequisites

Topology deployed and all containers running:
```bash
containerlab deploy -t topology/t1-small-vm.clab.yml
```

## Step 1: Run Deployment Script

```bash
cd ~/sonic-mgmt-containers/sonic-mgmt-vm/scripts
./deploy_config.sh
```

**Expected Output:**
```
[0/4] Pre-Deployment Checks ✓
[1/4] Creating sonic-mgmt Configuration Files ✓
[2/4] Fixing Cache Permissions ✓
[3/4] Creating Ansible Configuration ✓
[4/4] Checking sonic-mgmt Connectivity ✓
```

## Step 2: Enter Container & Copy Inventory

```bash
docker exec -it clab-t1-small-vm-sonic-mgmt bash
sudo cp /tmp/sonic-configs/inventory.ini /sonic-mgmt/ansible/lab
```

## Step 3: Verify Ansible Connectivity

```bash
cd /sonic-mgmt/ansible
ansible -i lab sonic-dut -m ping
```

**Expected Output:**
```
sonic-dut | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Step 4: Run Tests

```bash
cd /sonic-mgmt/tests
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH Connection Refused | Wait 60+ seconds for sonic-vm to boot |
| config_facts not found | Verify: `ls /sonic-mgmt/tests/library/config_facts.py` |
| Permission denied | Run: `sudo chmod -R 777 /sonic-mgmt/tests/.pytest_cache` |
| Ansible connection failed | Check: `cat /sonic-mgmt/ansible/lab` |

## Key Files

- Inventory: `/sonic-mgmt/ansible/lab`
- Testbed: `/tmp/sonic-configs/testbed.yaml`
- Ansible Config: `/sonic-mgmt/ansible/ansible.cfg`

