# Detailed Setup Guide: SONiC-VS + sonic-mgmt Integration

## Phase 1: Prepare the Environment

### Step 1.1: Verify Prerequisites

```bash
# Check Docker
docker --version
docker ps

# Check Containerlab
containerlab version

# Check sonic-vs image
docker images | grep sonic-vs
```

If sonic-vs image is missing, download it:

```bash
# Download sonic-vs image
wget https://sonic-build.azurewebsites.net/api/sonic/artifacts?branchName=master&platform=vs&target=target/sonic-vs.img.gz -O sonic-vs.img.gz

# Load into Docker
gunzip sonic-vs.img.gz
docker load < sonic-vs.img
```

### Step 1.2: Navigate to sonic-mgmt-vs Directory

```bash
cd sonic-mgmt-vs
pwd  # Verify location
```

## Phase 2: Deploy Containerlab Topology

### Step 2.1: Deploy the Topology

```bash
# Deploy with sudo (required for network setup)
sudo containerlab deploy -t sonic-vs-t0.clab.yml

# Expected output shows:
# - 5 nodes deployed (dut, leaf1-4)
# - Management network created
# - Links established
```

### Step 2.2: Verify Topology Deployment

```bash
# Inspect the deployed topology
sudo containerlab inspect -t sonic-vs-t0.clab.yml

# Check running containers
docker ps | grep sonic-vs-t0

# Verify management network
docker network ls | grep sonic-vs-t0
```

### Step 2.3: Test Node Connectivity

```bash
# Test DUT
docker exec sonic-vs-t0-dut bash -c "show version"

# Test Leaf nodes
for i in 1 2 3 4; do
  docker exec sonic-vs-t0-leaf$i bash -c "show version"
done
```

## Phase 3: Configure BGP

### Step 3.1: Run BGP Configuration Script

```bash
# Make script executable
chmod +x configure_bgp.sh

# Run configuration
./configure_bgp.sh

# Check log
cat bgp_config.log
```

### Step 3.2: Verify BGP Configuration

```bash
# Check DUT BGP neighbors
docker exec sonic-vs-t0-dut bash -c "show bgp summary"

# Check Leaf BGP neighbors
docker exec sonic-vs-t0-leaf1 bash -c "show bgp summary"
```

## Phase 4: Setup sonic-mgmt Container

### Step 4.1: Navigate to sonic-mgmt-master

```bash
cd sonic-mgmt-master
pwd
```

### Step 4.2: Create sonic-mgmt Container

```bash
# Create container with mount to sonic-mgmt-vs
./setup-container.sh -n sonic-mgmt-test \
  -d /var/src \
  -m ../sonic-mgmt-vs:/sonic-mgmt-vs

# Note the SSH command and container IP
```

### Step 4.3: Verify Container Setup

```bash
# Check container is running
docker ps | grep sonic-mgmt-test

# Enter container
docker exec -it sonic-mgmt-test bash

# Inside container, verify mounts
ls -la /var/src
ls -la /sonic-mgmt-vs
```

## Phase 5: Configure Ansible for Containerlab

### Step 5.1: Create Ansible Inventory

Inside sonic-mgmt container:

```bash
cd /var/src/ansible

cat > clab_inventory.yml << 'EOF'
all:
  children:
    sonic_devices:
      hosts:
        dut:
          ansible_host: 172.20.20.2
          ansible_user: admin
          ansible_password: YourPassword
        leaf1:
          ansible_host: 172.20.20.11
          ansible_user: admin
          ansible_password: YourPassword
        leaf2:
          ansible_host: 172.20.20.12
          ansible_user: admin
          ansible_password: YourPassword
        leaf3:
          ansible_host: 172.20.20.13
          ansible_user: admin
          ansible_password: YourPassword
        leaf4:
          ansible_host: 172.20.20.14
          ansible_user: admin
          ansible_password: YourPassword
EOF
```

### Step 5.2: Test Ansible Connectivity

```bash
# From sonic-mgmt container
ansible -i clab_inventory.yml sonic_devices -m ping

# Expected: All hosts return SUCCESS
```

## Phase 6: Run Tests

### Step 6.1: Run BGP Tests

```bash
cd /var/src/tests

# Run BGP fact test
python -m pytest bgp/test_bgp_fact.py -v -k "test_bgp_fact" \
  --inventory clab_inventory.yml

# Run BGP neighbor test
python -m pytest bgp/test_bgp_neighbor.py -v \
  --inventory clab_inventory.yml
```

### Step 6.2: Verify Test Results

```bash
# Check test output for PASSED/FAILED
# Logs are in /var/src/tests/logs/
```

## Cleanup

### Remove Topology

```bash
cd sonic-mgmt-vs
sudo containerlab destroy -t sonic-vs-t0.clab.yml
```

### Remove sonic-mgmt Container

```bash
docker rm -f sonic-mgmt-test
```

## Next Steps

- Customize topology in sonic-vs-t0.clab.yml
- Add more test cases
- Configure additional BGP features
- Integrate with CI/CD pipeline

