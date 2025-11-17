# PTF Configuration for t1-small Topology

## Overview

This directory contains configuration files for the PTF (Packet Test Framework) container used in the t1-small topology.

## Files

- **ptf_nn_agent.conf**: PTF network namespace agent configuration
- **README.md**: This file

## PTF Container Details

The PTF container is used for:
- Packet injection and capture
- Traffic generation for testing
- Network protocol testing
- Data plane validation

## Interface Mapping

| PTF Interface | Connected To | Purpose |
|---------------|--------------|---------|
| eth0 | Management Network | Containerlab management (reserved) |
| eth1 | sonic-dut:eth3 | Data plane testing port 0 |
| eth2 | sonic-dut:eth4 | Data plane testing port 1 |

## Running PTF Tests

### Access PTF Container

```bash
docker exec -it clab-t1-small-ptf bash
```

### Basic PTF Test Example

```python
# Inside PTF container
cd /ptf
ptf --test-dir tests/ --interface 0@eth1 --interface 1@eth2
```

### Custom Test Execution

```bash
# Run specific test
ptf --test-dir tests/ \
    --interface 0@eth1 \
    --interface 1@eth2 \
    --test-params="target_dut='sonic-dut'" \
    my_test.MyTestCase
```

## Test Development

PTF tests should be placed in the `/ptf/tests/` directory inside the container.

Example test structure:
```
/ptf/
├── tests/
│   ├── __init__.py
│   ├── basic_tests.py
│   └── advanced_tests.py
└── ptf_nn_agent.conf
```

## Troubleshooting

### Check PTF Interfaces

```bash
docker exec -it clab-t1-small-ptf ip link show
```

### Verify Connectivity

```bash
docker exec -it clab-t1-small-ptf ping -c 3 172.30.30.2
```

### PTF Logs

```bash
docker logs clab-t1-small-ptf
```

## References

- [PTF Documentation](https://github.com/p4lang/ptf)
- [SONiC Testing Guide](https://github.com/sonic-net/sonic-mgmt/blob/master/docs/testbed/README.testbed.Overview.md)

