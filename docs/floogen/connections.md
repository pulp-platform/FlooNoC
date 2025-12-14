# Connections

Connections define the physical links between the components of the network (Endpoints and Routers). They determine the topology of the NoC. FlooGen allows for flexible connection schemes, supporting point-to-point links as well as range-based connections for arrays of components.

## Configuration

Connections are defined under the `connections` list in the configuration file.

### Parameters

| Parameter | Type | Description | Required | Default |
| :--- | :--- | :--- | :---: | :--- |
| `src` | String | Name of the source component (Endpoint or Router). | Yes | - |
| `dst` | String | Name of the destination component (Endpoint or Router). | Yes | - |
| `bidirectional` | Boolean | If true, creates a full-duplex link (Request and Response channels). Currently, only bidirectional links are supported. | No | `true` |
| `dst_dir` | String | Specifies the port direction on the destination router (e.g., `"North"`, `"Local"`, `"Eject"`). | No | `None` |
| `src_range` | List[Tuple] | Selects a range of indices from the source array to connect. Format: `[(start, end)]` or `[(start_x, end_x), (start_y, end_y)]`. | No | `None` |
| `dst_range` | List[Tuple] | Selects a range of indices from the destination array to connect. | No | `None` |
| `src_idx` | List[Int] | Selects specific indices from the source array. | No | `None` |
| `dst_idx` | List[Int] | Selects specific indices from the destination array. | No | `None` |
| `allow_multi` | Boolean | Allows multiple connections to/from the same port (useful for complex topologies). | No | `false` |
| `description` | String | Optional description of the connection. | No | `""` |

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
