#!/usr/bin/env python3
"""
Generate minigraph.xml files for each host in the topology
"""

import os
import sys

# Define minigraph content for each host
minigraphs = {
    'dut': '''<?xml version="1.0" encoding="UTF-8"?>
<DeviceMiniGraph xmlns="Microsoft.Search.Autopilot.Evolution" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
  <CpgDec>
    <IsisRouters xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
    <PeeringSessions>
      <BGPSession>
        <StartRouter>dut</StartRouter>
        <StartPeer>10.0.0.0</StartPeer>
        <EndRouter>leaf1</EndRouter>
        <EndPeer>10.0.0.1</EndPeer>
      </BGPSession>
      <BGPSession>
        <StartRouter>dut</StartRouter>
        <StartPeer>10.0.1.0</StartPeer>
        <EndRouter>leaf2</EndRouter>
        <EndPeer>10.0.1.1</EndPeer>
      </BGPSession>
    </PeeringSessions>
    <Routers xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution">
      <a:BGPRouterDeclaration>
        <a:ASN>65000</a:ASN>
        <a:Hostname>dut</a:Hostname>
        <a:Peers>
          <BGPPeer>
            <Address>10.0.0.1</Address>
            <RouteMapIn i:nil="true"/>
            <RouteMapOut i:nil="true"/>
            <Vrf i:nil="true"/>
          </BGPPeer>
          <BGPPeer>
            <Address>10.0.1.1</Address>
            <RouteMapIn i:nil="true"/>
            <RouteMapOut i:nil="true"/>
            <Vrf i:nil="true"/>
          </BGPPeer>
        </a:Peers>
        <a:RouteMaps/>
      </a:BGPRouterDeclaration>
    </Routers>
  </CpgDec>
  <DpgDec>
    <DeviceDataPlaneInfo>
      <IPSecTunnels/>
      <LoopbackIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution">
        <a:LoopbackIPInterface>
          <Name>HostIP</Name>
          <AttachTo>Loopback0</AttachTo>
          <a:Prefix xmlns:b="Microsoft.Search.Autopilot.Evolution">
            <b:IPPrefix>1.1.1.1/32</b:IPPrefix>
          </a:Prefix>
          <a:PrefixStr>1.1.1.1/32</a:PrefixStr>
        </a:LoopbackIPInterface>
      </LoopbackIPInterfaces>
      <ManagementIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
      <ManagementVIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
      <MplsInterfaces/>
      <MplsTeInterfaces/>
      <RsvpInterfaces/>
      <Hostname>dut</Hostname>
      <PortChannelInterfaces/>
      <VlanInterfaces/>
      <IPInterfaces>
        <IPInterface>
          <Name i:nil="true"/>
          <AttachTo>Ethernet0</AttachTo>
          <Prefix>10.0.0.0/31</Prefix>
        </IPInterface>
        <IPInterface>
          <Name i:nil="true"/>
          <AttachTo>Ethernet4</AttachTo>
          <Prefix>10.0.1.0/31</Prefix>
        </IPInterface>
      </IPInterfaces>
    </DeviceDataPlaneInfo>
  </DpgDec>
</DeviceMiniGraph>''',
    'leaf1': '''<?xml version="1.0" encoding="UTF-8"?>
<DeviceMiniGraph xmlns="Microsoft.Search.Autopilot.Evolution" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
  <CpgDec>
    <IsisRouters xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
    <PeeringSessions>
      <BGPSession>
        <StartRouter>leaf1</StartRouter>
        <StartPeer>10.0.0.1</StartPeer>
        <EndRouter>dut</EndRouter>
        <EndPeer>10.0.0.0</EndPeer>
      </BGPSession>
      <BGPSession>
        <StartRouter>leaf1</StartRouter>
        <StartPeer>10.0.2.0</StartPeer>
        <EndRouter>leaf2</EndRouter>
        <EndPeer>10.0.2.1</EndPeer>
      </BGPSession>
    </PeeringSessions>
    <Routers xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution">
      <a:BGPRouterDeclaration>
        <a:ASN>65101</a:ASN>
        <a:Hostname>leaf1</a:Hostname>
        <a:Peers>
          <BGPPeer>
            <Address>10.0.0.0</Address>
            <RouteMapIn i:nil="true"/>
            <RouteMapOut i:nil="true"/>
            <Vrf i:nil="true"/>
          </BGPPeer>
          <BGPPeer>
            <Address>10.0.2.1</Address>
            <RouteMapIn i:nil="true"/>
            <RouteMapOut i:nil="true"/>
            <Vrf i:nil="true"/>
          </BGPPeer>
        </a:Peers>
        <a:RouteMaps/>
      </a:BGPRouterDeclaration>
    </Routers>
  </CpgDec>
  <DpgDec>
    <DeviceDataPlaneInfo>
      <IPSecTunnels/>
      <LoopbackIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution">
        <a:LoopbackIPInterface>
          <Name>HostIP</Name>
          <AttachTo>Loopback0</AttachTo>
          <a:Prefix xmlns:b="Microsoft.Search.Autopilot.Evolution">
            <b:IPPrefix>2.2.2.2/32</b:IPPrefix>
          </a:Prefix>
          <a:PrefixStr>2.2.2.2/32</a:PrefixStr>
        </a:LoopbackIPInterface>
      </LoopbackIPInterfaces>
      <ManagementIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
      <ManagementVIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
      <MplsInterfaces/>
      <MplsTeInterfaces/>
      <RsvpInterfaces/>
      <Hostname>leaf1</Hostname>
      <PortChannelInterfaces/>
      <VlanInterfaces/>
      <IPInterfaces>
        <IPInterface>
          <Name i:nil="true"/>
          <AttachTo>Ethernet0</AttachTo>
          <Prefix>10.0.0.1/31</Prefix>
        </IPInterface>
        <IPInterface>
          <Name i:nil="true"/>
          <AttachTo>Ethernet4</AttachTo>
          <Prefix>10.0.2.0/31</Prefix>
        </IPInterface>
      </IPInterfaces>
    </DeviceDataPlaneInfo>
  </DpgDec>
</DeviceMiniGraph>''',
    'leaf2': '''<?xml version="1.0" encoding="UTF-8"?>
<DeviceMiniGraph xmlns="Microsoft.Search.Autopilot.Evolution" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
  <CpgDec>
    <IsisRouters xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
    <PeeringSessions>
      <BGPSession>
        <StartRouter>leaf2</StartRouter>
        <StartPeer>10.0.1.1</StartPeer>
        <EndRouter>dut</EndRouter>
        <EndPeer>10.0.1.0</EndPeer>
      </BGPSession>
      <BGPSession>
        <StartRouter>leaf2</StartRouter>
        <StartPeer>10.0.2.1</StartPeer>
        <EndRouter>leaf1</EndRouter>
        <EndPeer>10.0.2.0</EndPeer>
      </BGPSession>
    </PeeringSessions>
    <Routers xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution">
      <a:BGPRouterDeclaration>
        <a:ASN>65102</a:ASN>
        <a:Hostname>leaf2</a:Hostname>
        <a:Peers>
          <BGPPeer>
            <Address>10.0.1.0</Address>
            <RouteMapIn i:nil="true"/>
            <RouteMapOut i:nil="true"/>
            <Vrf i:nil="true"/>
          </BGPPeer>
          <BGPPeer>
            <Address>10.0.2.0</Address>
            <RouteMapIn i:nil="true"/>
            <RouteMapOut i:nil="true"/>
            <Vrf i:nil="true"/>
          </BGPPeer>
        </a:Peers>
        <a:RouteMaps/>
      </a:BGPRouterDeclaration>
    </Routers>
  </CpgDec>
  <DpgDec>
    <DeviceDataPlaneInfo>
      <IPSecTunnels/>
      <LoopbackIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution">
        <a:LoopbackIPInterface>
          <Name>HostIP</Name>
          <AttachTo>Loopback0</AttachTo>
          <a:Prefix xmlns:b="Microsoft.Search.Autopilot.Evolution">
            <b:IPPrefix>3.3.3.3/32</b:IPPrefix>
          </a:Prefix>
          <a:PrefixStr>3.3.3.3/32</a:PrefixStr>
        </a:LoopbackIPInterface>
      </LoopbackIPInterfaces>
      <ManagementIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
      <ManagementVIPInterfaces xmlns:a="http://schemas.datacontract.org/2004/07/Microsoft.Search.Autopilot.Evolution"/>
      <MplsInterfaces/>
      <MplsTeInterfaces/>
      <RsvpInterfaces/>
      <Hostname>leaf2</Hostname>
      <PortChannelInterfaces/>
      <VlanInterfaces/>
      <IPInterfaces>
        <IPInterface>
          <Name i:nil="true"/>
          <AttachTo>Ethernet0</AttachTo>
          <Prefix>10.0.1.1/31</Prefix>
        </IPInterface>
        <IPInterface>
          <Name i:nil="true"/>
          <AttachTo>Ethernet4</AttachTo>
          <Prefix>10.0.2.1/31</Prefix>
        </IPInterface>
      </IPInterfaces>
    </DeviceDataPlaneInfo>
  </DpgDec>
</DeviceMiniGraph>'''
}

def main():
    # Create minigraph files in configs directories
    for hostname, content in minigraphs.items():
        config_dir = f"configs/{hostname}"
        os.makedirs(config_dir, exist_ok=True)
        
        filepath = f"{config_dir}/minigraph.xml"
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Created {filepath}")

if __name__ == '__main__':
    main()

