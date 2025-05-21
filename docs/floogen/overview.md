# Overview

_FlooNoC_ comes with a generation framework called _FlooGen_. It allows to create complex network configurations with a high-level configuration file.

## How it works

Internally _FlooGen_ has a graph-based representation of the network based on the configuration file that is given as an input by the user. Thanks to this, _FlooGen_ is capable of performing the following things:

- **Validation**: The configuration given by the user is validated to ensure that the input is valid and does not contain any accidental mistakes. For instance, _FlooGen_ automatically checks for overlapping address ranges, or router ports that are assigned multpile times.

- **Routing**: Based on the connectivity graph of the network, _FlooGen_ is able to derive all required routing related information such as routing tables and the system address map which is used by routers and network interfaces.

- **Package Generation**: _FlooGen_ automatically generates a SystemVerilog package with all the needed AXI and flit types, which additionally includes all the routing information.

- **Top Module Generation**: _FlooGen_ can also generate a top module that instantiates all router and network interfaces. The interfaces of the top module are AXI4 interfaces for all the enpdoints specified in the configuration.

## Exmaple configuration

Below is an example of a configuration for a simple 4x4 mesh network, which will be explained in more detail in the next sections:

```yaml
name: axi_mesh
description: "AXI mesh configuration with XY routing for FlooGen"
network_type: "axi"

routing:
  route_algo: "XY"
  use_id_table: true

protocols:
  - name: "axi_in"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 4
    user_width: 1
  - name: "axi_out"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 2
    user_width: 1

endpoints:
  - name: "cluster"
    array: [4, 4]
    addr_range:
      base: 0x0000_0000_0000
      size: 0x0000_0001_0000
    mgr_port_protocol:
      - "axi_in"
    sbr_port_protocol:
      - "axi_out"

routers:
  - name: "router"
    array: [4, 4]
    degree: 5

connections:
  - src: "cluster"
    dst: "router"
    src_range:
    - [0, 3]
    - [0, 3]
    dst_range:
    - [0, 3]
    - [0, 3]
    dst_dir: "Eject"
```
