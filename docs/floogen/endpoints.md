Here is the draft for the `floogen/endpoints.md` section, following the style of the previous `protocols.md` page.

# Endpoints

Endpoints represent the interfaces where external IP blocks (like processors, memories, or peripherals) connect to the NoC. They define the role of the connected IP (Manager, Subordinate, or both), the protocols used for communication, and the address ranges they serve.

## Configuration

Endpoints are defined under the `endpoints` list in the configuration file.

### Parameters

| Parameter | Type | Description | Required | Default |
| :--- | :--- | :--- | :---: | :--- |
| `name` | String | Unique identifier for the endpoint. Used in connection definitions. | Yes | - |
| `description` | String | Optional description of the endpoint. | No | `""` |
| `array` | List[Int] | Defines the endpoint as an array (1D or 2D). E.g., `[4]` for a 1D array of size 4, or `[4, 4]` for a 4x4 grid. | No | `None` |
| `addr_range` | List/Map | Defines the address regions served by this endpoint (required if it acts as a Subordinate). | Cond. | `[]` |
| `mgr_port_protocol`| List[String]| List of protocol names (defined in `protocols`) that this endpoint uses to send requests (Manager role). | No | `None` |
| `sbr_port_protocol`| List[String]| List of protocol names (defined in `protocols`) that this endpoint uses to receive requests (Subordinate role). | No | `None` |
| `xy_id_offset` | Map/Int | Offsets for XY coordinates or IDs, used to manually adjust the logical position of the endpoint in the network. | No | `None` |

### Address Ranges

If an endpoint acts as a Subordinate (i.e., it receives requests), it must define at least one address range. This is used to generate the system address map and routing tables. Address ranges can be defined explicitly or relative to a base address for arrays.

| Field | Type | Description |
| :--- | :--- | :--- |
| `start` | Integer | Absolute start address of the range. |
| `end` | Integer | Absolute end address of the range. |
| `size` | Integer | Size of the address range. |
| `base` | Integer | Base address used for calculating ranges in endpoint arrays. |
| `en_multicast` | Boolean | If true, marks this range as a multicast destination. |

## Examples

### Basic Endpoint

A simple memory endpoint that acts as a subordinate (Slave) answering to a specific address range.

```yaml
endpoints:
  - name: "hbm"
    addr_range:
      start: 0x8000_0000
      size: 0x1000_0000 # 256 MB
    sbr_port_protocol:
      - "axi_out"
```

### Processor Endpoint (Manager)

A processor core that only issues requests (Manager) and does not receive them.

```yaml
endpoints:
  - name: "cva6"
    mgr_port_protocol:
      - "narrow_in"
```

### Endpoint Arrays

FlooGen supports defining arrays of endpoints, which is useful for multi-core clusters or tiled architectures. When defining an address range for an array, you typically provide a `base` address and a `size`. FlooGen automatically calculates the specific range for each instance in the array.

```yaml
endpoints:
  - name: "cluster"
    array: [4, 4] # 4x4 Grid of clusters
    addr_range:
      base: 0x1000_0000
      size: 0x0004_0000 # Size per cluster
    mgr_port_protocol:
      - "axi_in"
    sbr_port_protocol:
      - "axi_out"
  - name: "hbm_channels"
    array: [8] # 8 HBM channels
    addr_range:
      base: 0x8000_0000
      size: 0x0200_0000 # Size per channel
    sbr_port_protocol:
      - "axi_out"
```

### Narrow-wide Interfaces

If the `narrow-wide` configuration is used in the network, endpoints can define both/either narrow/wide protocols for their ports.

```yaml
endpoints:
  - name: "dma"
    mgr_port_protocol:
      - "narrow_in"
      - "wide_in"
    sbr_port_protocol:
      - "narrow_out"
      - "wide_out"
```

### Multiple (non-contiguous) Address Ranges

Endpoints can define multiple address ranges to represent non-contiguous memory regions or peripherals.

```yaml
endpoints:
  - name: "peripheral_block"
    addr_range:
      - start: 0x4000_0000
        size: 0x0001_0000
        desc: "Control Registers"
      - start: 0x5000_0000
        size: 0x0001_0000
        desc: "Status Registers"
    sbr_port_protocol:
      - "axi_out"
```
