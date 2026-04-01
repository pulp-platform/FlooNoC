# Routers

Routers are the central switching elements in the Network-on-Chip. They route packets between Endpoints (via Network Interfaces) and other Routers. FlooGen supports generating routers with configurable port counts (degree), routing algorithms, and topologies (meshes, trees, or irregular graphs).

## Configuration

Routers are defined under the `routers` list in the configuration file.

::: floogen.model.router.RouterDesc
    options:
      show_root_heading: true
      show_root_toc_entry: true
      show_root_full_path: false
      show_bases: false
      members: []
      show_source: false
      show_signature: false

## Examples

### Single Router

A standalone router, useful for star topologies or small clusters where everything connects to a central point.

```yaml
routers:
  - name: "router"
```

### Mesh Router (2D Array)

To generate a Mesh NoC, you define an `array` of routers. By default, `auto_connect: true` will automatically create the grid links between them.

```yaml
routers:
  - name: "router"
    array: [4, 4] # 4x4 Grid
    auto_connect: true # Default
```

### Tree Topology

For tree networks, the `tree` parameter defines the structure. For example, a binary tree with 2 levels of switches.

```yaml
routers:
  - name: "tree_router"
    tree: [2, 2] # Binary tree depth definition
```

### Disabling Auto-Connect

If you want to define a custom topology using an array of routers (e.g., a torus or a specific irregular grid) without the default mesh connections, you can disable `auto_connect` and define `connections` manually.

```yaml
routers:
  - name: "custom_router"
    array: [2, 2]
    auto_connect: false # Manual connections required
```

### Override router degree

You can override the default port count of a router by specifying the `degree` parameter. This is useful in XY-Routing which always assumes 5 ports (N, E, S, W, Local). Regardless of whether the router is on the edge or corner of the mesh, it will still have 5 ports.

```yaml
routers:
  - name: "router"
    array: [4, 4]
    degree: 5
```
