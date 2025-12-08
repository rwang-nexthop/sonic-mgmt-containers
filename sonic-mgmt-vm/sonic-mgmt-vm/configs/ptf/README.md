# PTF Configuration

This directory contains the Packet Test Framework (PTF) configuration for the t1-small-vm topology.

## Files

- **ptf_nn_agent.conf** - PTF NN Agent configuration file

## Configuration Details

### Interface Mapping

The PTF container has two test interfaces connected to sonic-dut:

- `eth1` → sonic-dut:eth3 (test port 0)
- `eth2` → sonic-dut:eth4 (test port 1)

### DUT Information

- **Hostname**: sonic-dut
- **Management IP**: 172.30.30.2 (or assigned by containerlab)

### Test Parameters

- **Testbed Type**: t1-small-vm
- **Router MAC**: 00:11:22:33:44:55
- **ASIC Type**: vs (virtual switch)

## Usage

The PTF configuration is automatically loaded when the topology is deployed. No manual configuration is needed unless you want to customize the test parameters.

## Customization

To customize PTF configuration:

1. Edit `ptf_nn_agent.conf`
2. Redeploy the topology: `containerlab deploy -t topology/t1-small-vm.clab.yml`
3. Or restart the PTF container: `docker restart clab-t1-small-vm-ptf`

## References

- [PTF Documentation](https://github.com/p4lang/ptf)
- [SONiC PTF Tests](https://github.com/Azure/sonic-mgmt/tree/master/tests)

