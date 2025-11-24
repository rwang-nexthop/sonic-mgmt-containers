# Test Execution Guide

## Prerequisites

1. **Topology deployed:**
   ```bash
   containerlab deploy -t topology/t1-small-vm.clab.yml
   ```

2. **All containers running:**
   ```bash
   docker ps | grep clab-t1-small-vm
   ```

## Step 1: Run Deployment Script

```bash
cd ~/sonic-mgmt-containers/sonic-mgmt-vm/scripts
./deploy_config.sh
```

This will:
- Create inventory with Ansible credentials
- Create testbed.yaml with topology info
- Fix cache permissions
- Create ansible.cfg with library paths

## Step 2: Enter sonic-mgmt Container

```bash
docker exec -it clab-t1-small-vm-sonic-mgmt bash
```

## Step 3: Copy Inventory to Ansible

```bash
sudo cp /tmp/sonic-configs/inventory.ini /sonic-mgmt/ansible/lab
```

## Step 4: Verify Ansible Connectivity

```bash
cd /sonic-mgmt/ansible
ansible -i lab sonic-dut -m ping
```

Expected output:
```
sonic-dut | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Step 5: Run Tests

```bash
cd /sonic-mgmt/tests
python -m pytest bgp/test_bgp_fact.py -v \
  --testbed /tmp/sonic-configs/testbed.yaml \
  --inventory /tmp/sonic-configs/inventory.ini \
  --host-pattern sonic-dut
```

## Troubleshooting

**SSH Connection Refused:**
- Wait 60+ seconds for sonic-vm to fully boot
- Check: `ssh admin@172.30.30.4 "show version"`

**config_facts module not found:**
- Verify: `ls -la /sonic-mgmt/tests/library/config_facts.py`
- Check ansible.cfg library path

**Permission denied errors:**
- Run: `sudo chmod -R 777 /sonic-mgmt/tests/.pytest_cache`

**Ansible connection failed:**
- Verify inventory: `cat /sonic-mgmt/ansible/lab`
- Test SSH: `ssh -v admin@172.30.30.4`

