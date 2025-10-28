# General information

The first part of the configuration file contains some general information about the network:

```yaml
name: my_noc
description: "My first NoC"
network_type: "axi"
```

## `name`

The `name` field specifies the name of the network, which will be used to name the generated files. The example given above will generate the files `floo_my_noc_pkg.sv` and `floo_my_noc_top.sv` which contains the package and the top-level module of the same name.

## `description`
The `description` field is a short description of the network. It is currently not used by _FlooGen_, and it is currently only for user reference.

## `network_type`
The `network_type` field specifies the type of network that is being generated. Currently, only two types are supported:
- `axi`: This will generate a network where the endpoints expose a single AXI interface, which is mapped on two physical links `req` and `rsp`.
- `narrow_wide`: This will generate a network where the endpoints expose both a narrow and a wide AXI interface, which are mapped on to three physical links `req`, `rsp`, `wide`. It is still possible to disable the narrow or wide interface on a per-endpoint basis.
