# Connections

Connections define the physical links between the components of the network (Endpoints and Routers). They determine the topology of the NoC. FlooGen allows for flexible connection schemes, supporting point-to-point links as well as range-based connections for arrays of components.

## Configuration

Connections are defined under the `connections` list in the configuration file.

::: floogen.model.connection.ConnectionDesc
    options:
      show_root_heading: true
      show_root_toc_entry: true
      show_root_full_path: false
      show_bases: false
      members: []
      show_source: false
      show_signature: false

## Examples

### Basic Connection

Connects a single endpoint to a router. This is the most common connection type for simple star or mesh topologies where `auto_connect` handles the inter-router links.

```yaml
connections:
  - src: "cpu_0"
    dst: "router_0"
```

### Range Connection (Arrays)

When connecting arrays (e.g., a cluster of CPUs to a mesh of routers), you can use `src_range` and `dst_range`. This avoids writing a separate connection for every single element.

The following example connects a 4x4 endpoint array (`cluster`) to a 4x4 router array (`router`). It maps `cluster[0..3][0..3]` to `router[0..3][0..3]`.

```yaml
connections:
  - src: "cluster"
    dst: "router"
    src_range:
      - [0, 3] # X range
      - [0, 3] # Y range
    dst_range:
      - [0, 3]
      - [0, 3]
```

### Specifying Router Ports

When manually connecting routers (or specific endpoints), you might need to specify which port direction to attach to. Available directions are usually `North`, `East`, `South`, `West`, or `Eject` (Local).

```yaml
connections:
  - src: "hbm_controller"
    dst: "router_0"
    dst_dir: "West" # Connects HBM to the West port of router_0
```

### Complex Mappings

You can map different ranges to specific ports. For example, connecting a linear array of HBM controllers to the bottom edge of a mesh router grid.

```yaml
connections:
  - src: "hbm"       # Array of 4 HBM endpoints
    dst: "router"    # 4x4 Router mesh
    src_range:
      - [0, 3]       # Select all 4 HBMs
    dst_range:
      - [0, 3]       # Select X indices 0-3
      - [0, 0]       # Select Y index 0 (Bottom row)
    dst_dir: "South" # Connect to the South port of the routers
```
