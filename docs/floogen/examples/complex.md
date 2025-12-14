# Complex Example: Heterogeneous Narrow-Wide NoC

This example illustrates a complex configuration for a system named [`picobello`](https://github.com/pulp-platform/picobello). It demonstrates how to construct a heterogeneous network ("Narrow-Wide") that supports multicast and uses a non-uniform topology constructed from multiple router arrays.

## Key Features

* **Network Type**: `narrow-wide` (separate physical links for control and data).
* **Routing**: `XY` routing with **Multicast** enabled.
* **Topology**: A partitioned mesh created by defining multiple router arrays with coordinate offsets.
* **Protocols**: Custom `user_width` definitions to carry multicast masks.

## Configuration

### Global Settings & Protocols

The network is configured as `narrow-wide`, meaning endpoints can have distinct narrow (control) and wide (data) interfaces. Multicast is enabled in the routing section, which requires specific support in the protocols (the `mcast_mask` in `user_width`).

```yaml
name: picobello
description: "picobello NoC configuration"
network_type: "narrow-wide"

routing:
  route_algo: "XY"
  use_id_table: true
  en_multicast: true

protocols:
  - name: "narrow_in"
    type: "narrow"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 5
    user_width:
      mcast_mask: 48 # Reserved bits for multicast routing
      user: 5        # Actual user bits
  # ... (other protocols defined similarly)
```

### Advanced Endpoints

Endpoints in this configuration demonstrate two advanced features:

1.  **Multiple Address Ranges**: The `cheshire` endpoint responds to two disjoint address ranges (`internal` and `external`).
2.  **Split Interfaces**: Endpoints like `top_spm_narrow` and `top_spm_wide` connect only to the narrow or wide planes respectively.

```yaml
endpoints:
  - name: "cluster"
    array: [4, 4]
    en_multicast: true # Enables multicast reception for this array
    # ...
  - name: "cheshire"
    addr_range:
      - start: 0x0000_0000
        end: 0x2000_0000
        desc: "internal"
      - start: 0x8000_0000
        end: 0x200_0000_0000
        desc: "external"
    # ...
```

### Partitioned Topology (Router Offsets)

Instead of a single uniform mesh, this NoC is built from three distinct router arrays: `router_left`, `router_center`, and `router_right`. By using `xy_id_offset`, these arrays are placed at specific logical coordinates in the global grid.

  * **Left**: 1x4 array at X=0
  * **Center**: 4x4 array starting at X=4
  * **Right**: 2x4 array starting at X=8

This allows for creating "gaps" or irregular shapes in the NoC topology while maintaining XY routing logic. This is only useful for multicast support, since multicast support requires the multicast-capable endpoint coordinates to be based on powers of two.

```yaml
routers:
  - name: "router_left"
    array: [1, 4]
    degree: 5
  - name: "router_center"
    array: [4, 4]
    degree: 5
    xy_id_offset:
      x: 4 # Logically starts at X=4
      y: 0
  - name: "router_right"
    array: [2, 4]
    degree: 5
    xy_id_offset:
      x: 8 # Logically starts at X=8
      y: 0
```

### Precise Connections

Because the topology is manually partitioned, connections are used to stitch the endpoints to specific routers. The `dst_idx` field is used to target specific routers within an array, and `dst_dir` ensures the endpoint attaches to the correct port (e.g., `Eject` for the local port).

```yaml
connections:
  - src: "cluster"
    dst: "router_center"
    # Connects the 4x4 cluster array to the 4x4 center router array
    src_range: [[0, 3], [0, 3]]
    dst_range: [[0, 3], [0, 3]]
    dst_dir: "Eject"

  - src: "cheshire"
    dst: "router_right"
    dst_idx: [1, 3] # Connects to router at index [1, 3] of the 'right' array
    dst_dir: "Eject"
```

The routers inside one groups are automatically connected in a mesh topology due to `auto_connect: true` (default). But the router groups themselves are not connected to each other automatically.

```yaml
connections:
  - src: "router_left"
    dst: "router_center"
    src_range:
      - [0, 0] # X range
      - [0, 3] # Y range
    dst_range:
      - [0, 0] # X range
      - [0, 3] # Y range
    src_dir: "East"
    dst_dir: "West"
  - src: "router_center"
    dst: "router_right"
    src_range:
      - [3, 3] # X range
      - [0, 3] # Y range
    dst_range:
      - [0, 1] # X range
      - [0, 3] # Y range
    src_dir: "East"
    dst_dir: "West"
```
