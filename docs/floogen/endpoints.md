# Endpoints

Endpoints represent the interfaces where external IP blocks (like processors, memories, or peripherals) connect to the NoC. They define the role of the connected IP (Manager, Subordinate, or both), the protocols used for communication, and the address ranges they serve.

## Configuration

Endpoints are defined under the `endpoints` list in the configuration file.

::: floogen.model.endpoint.EndpointDesc
    options:
      show_root_heading: true
      show_root_toc_entry: true
      show_root_full_path: false
      show_bases: false
      members: []
      show_source: false
      show_signature: false

### Address Ranges

If an endpoint acts as a Subordinate (i.e., it receives requests), it must define at least one address range. This is used to generate the system address map and routing tables. Address ranges can be defined explicitly or relative to a base address for arrays.

::: floogen.model.routing.AddrRange
    options:
      show_root_heading: false
      show_root_toc_entry: false
      show_bases: false
      members: []
      show_source: false
      show_signature: false

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
