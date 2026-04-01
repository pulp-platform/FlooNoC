# Protocols

Protocols in FlooGen define the communication interfaces used by endpoints and routers within the network. Currently, FlooGen primarily supports the **AXI4** protocol. These definitions determine the properties of the interface, such as data width, address width, and ID width, which are then used to generate the corresponding SystemVerilog typedefs and structs.
## Configuration

Protocols are defined under the `protocols` list in the configuration file. Each entry specifies a configuration that can be referenced by endpoints and routers.

::: floogen.model.protocol.ProtocolDesc
    options:
      show_root_heading: true
      show_root_toc_entry: true
      show_root_full_path: false
      show_bases: false
      members: []
      show_source: false
      show_signature: false

::: floogen.model.protocol.AXI4
    options:
      show_root_heading: true
      show_root_toc_entry: true
      show_root_full_path: false
      show_bases: false
      inherited_members: false
      members: []
      show_source: false
      show_signature: false

### Basic AXI4 Configuration

A standard AXI4 configuration with 64-bit data and 48-bit address width.

```yaml
protocols:
  - name: "axi_std"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 4
```

### Custom User Fields

The `user_width` parameter supports structured definitions. Instead of a single integer, you can provide a dictionary of field names and their bit widths. FlooGen will generate a packed SystemVerilog struct for these fields.

```yaml
protocols:
  - name: "axi_custom_user"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 4
    user_width:
      qos: 4
      region: 4
      parity: 1
```

### Heterogeneous Networks

For networks that mix different link types (e.g., a "narrow" control plane and a "wide" data plane), you can use the `type` field. This helps match endpoints to the correct network interfaces.

```yaml
protocols:
  - name: "narrow_in"
    type: "narrow"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 4

  - name: "wide_in"
    type: "wide"
    protocol: "AXI4"
    data_width: 512
    addr_width: 48
    id_width: 6
```

### Customizing Type Names

By default, FlooGen generates SystemVerilog types with an `axi` prefix (e.g., `axi_<name>_req_t`). You can customize this using `type_prefix`. To remove the prefix entirely (e.g., to avoid `axi_axi_...`), leave the value empty.

```yaml
protocols:
  - name: "noc_link"
    protocol: "AXI4"
    data_width: 64
    addr_width: 48
    id_width: 4
    type_prefix: "floo" # Results in floo_noc_link_req_t
```
