# Protocols

Protocols in FlooGen define the communication interfaces used by endpoints and routers within the network. Currently, FlooGen primarily supports the **AXI4** protocol. These definitions determine the properties of the interface, such as data width, address width, and ID width, which are then used to generate the corresponding SystemVerilog typedefs and structs.

## Configuration

Protocols are defined under the `protocols` list in the configuration file. Each entry specifies a configuration that can be referenced by endpoints and routers.

### Parameters

| Parameter | Type | Description | Required | Default |
| :--- | :--- | :--- | :---: | :--- |
| `name` | String | Unique identifier for the protocol. Used to reference it in endpoint configurations. | Yes | - |
| `protocol` | String | The protocol standard. Must be set to `"AXI4"`. | Yes | - |
| `data_width` | Integer | Width of the data bus in bits. | Yes | - |
| `addr_width` | Integer | Width of the address bus in bits. | Yes | - |
| `id_width` | Integer | Width of the ID signals in bits. | Yes | - |
| `user_width` | Int / Map | Configuration for the AXI User signal. Can be a single integer (total width) or a map defining fields. | No | `1` |
| `type` | String | Sub-type classification, useful for heterogeneous networks (e.g., `"narrow"`, `"wide"`). | No | `None` |
| `type_prefix` | String | Prefix for generated SystemVerilog types. Set to `null` or empty to remove default. | No | `"axi"` |
| `description` | String | Optional description of the protocol. | No | `""` |

## Examples

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
