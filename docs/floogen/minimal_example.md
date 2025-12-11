# Minimal Example

To get you started quickly, here is a complete configuration file for a common use case: **a 4x4 Mesh topology using XY routing**.

In this system, we have a 2D array of "clusters" (endpoints), where each cluster acts as both a manager (initiating requests) and a subordinate (responding to requests).

## The Configuration File

Save the following content as `axi_mesh.yaml`:

```yaml
name: axi_mesh
description: "AXI mesh with XY routing"
network_type: "axi"

# 1. Routing Configuration
routing:
  route_algo: "XY"
  use_id_table: true

# 2. Protocol Definitions
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

# 3. Endpoint Definitions
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

# 4. Router Definitions
routers:
  - name: "router"
    array: [4, 4]
    degree: 5

# 5. Connectivity
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

## Breakdown

Here is what is happening in each section of the configuration:

1.  **System & Routing**:
    We define the global [System Configuration](https://www.google.com/search?q=network_types.md) (name, description) and select `XY` as the [Routing](https://www.google.com/search?q=routing.md) algorithm. `use_id_table: true` tells *FlooGen* to generate a lookup table for address translation, which simplifies the address map logic.

2.  **Protocols**:
    We define two AXI4 [Protocols](protocols.md): `axi_in` (for incoming requests to the NoC) and `axi_out` (for outgoing requests from the NoC). Note that they have different ID widths to account for ID bits consumed by the routing logic.

3.  **Endpoints**:
    We instantiate a 4x4 array of [Endpoints](https://www.google.com/search?q=endpoints.md) named `cluster`.

      * **Addressing**: Each cluster is assigned a chunk of the global address map starting at `base` with a stride of `size`.
      * **Interfaces**: Each cluster has a manager port (using `axi_in`) and a subordinate port (using `axi_out`).

4.  **Routers**:
    We instantiate a corresponding 4x4 array of [Routers](https://www.google.com/search?q=routers.md). The `degree: 5` indicates 5 ports (North, East, South, West, and Local/Eject).

5.  **Connections**:
    The [Connections](https://www.google.com/search?q=connections.md) section wires the endpoints to the routers.

      * We connect the `cluster` array to the `router` array 1-to-1.
      * `dst_dir: "Eject"` specifies that the clusters are connected to the "Local" (or Eject) port of the routers.
      * *Note*: The inter-router connections (North, East, South, West) are automatically inferred by *FlooGen* because we are using a Mesh topology with XY routing.

## Run It

**1. Visualize the Topology**
Before generating code, verify the graph looks correct:

```bash
floogen visualize -c axi_mesh.yaml
```

**2. Generate the RTL**
Generate the SystemVerilog package and top-level module:

```bash
floogen rtl -c axi_mesh.yaml -o out/
```

You will find the generated files `floo_axi_mesh_noc.sv` and `floo_axi_mesh_noc_pkg.sv` in the `out/` directory.
