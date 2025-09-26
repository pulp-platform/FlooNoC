# _FlooGen_: The NoC generation framework for _FlooNoC_

_FlooGen_ is the generation framework bundled with _FlooNoC_. Given a network description in YAML (topology, endpoints, routing, etc.), it produces SystemVerilog RTL (routers, interfaces, routing tables, packages) that you can plug into your design.

## Operation at a glance

1. **Read YAML config** — users define the network (nodes, links, protocols, endpoints).
2. **Internal graph model & validation** — FlooGen builds a graph representation of your network and checks for errors (e.g. overlapping address regions, invalid port assignments).
3. **Route and address map derivation** — from the graph, routing tables and address maps are computed for routers and endpoints.
4. **Code generation** — produces SystemVerilog modules, a package with types and constants, and optionally a top-level wrapper connecting components.

## Get started with _FlooGen_

To install _FlooGen_, python >= 3.10 is required, which allows you to install _FlooGen_ via pip:

```bash
git clone https://github.com/pulp-platform/FlooNoC.git
cd FlooNoC
pip install .
```

You can try out _FlooGen_ by running it with an example configuration file:

```bash
floogen -c floogen/examples/axi_mesh.yaml -o out
```

which will generate two files in the `out/` directory:
- `axi_mesh_pkg.sv`: A SystemVerilog package containing all the types, constants and routing information needed to use the generated NoC.
- `axi_mesh_top.sv`: A top-level module instantiating all routers and network interfaces. The top-level module also requires the package generated above.

## Minimal example

Below is a small example configuration file for a 4×4 mesh using XY routing. Each section will be explained in more detail in the following sections:

1. **[General](network_types.md)**: This section will the general global parameters that are needed to configure the NoC.
1. **[Routing](routing.md)**: This section will explain the routing algorithm configuration.
1. **[Protocols](protocols.md)**: This section will explain how to configure the different protocols that are used by the endpoints that are attached to the NoC.
1. **[Endpoints](endpoints.md)**: This section will explain how to configure the endpoints that are attached to the NoC.
1. **[Routers](routers.md)**: This section will explain how to instantiate the routers that make up the NoC.
1. **[Connections](connections.md)**: This section will explain how to connect the endpoints to the routers. This basically defines the topology of the NoC.


```yaml
name: axi_mesh
description: "AXI mesh with XY routing"
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
