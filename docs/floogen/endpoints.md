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

### SystemRDL Generation

The [`rdl` CLI command](cli.md#rdl) generates a SystemRDL description of the network's
address map, with one addrmap entry per subordinate address range. By default, an
address range without further annotation is either skipped or rendered as an anonymous
`external mem` block (if `--as-mem` is passed on the command line). Two `addr_range`
fields give finer control over how each range is rendered:

- `rdl_name`: instantiates an externally-defined SystemRDL component (e.g. a register
  file described in its own `.rdl` file) at this address range. FlooGen emits an
  `` `include `` for it in the generated file.
- `rdl_as_mem`: renders this specific range as an anonymous `external mem` block,
  overriding the global `--as-mem` flag for this range only (`true` forces it on,
  `false` forces it off, regardless of the CLI flag).

`rdl_name` and `rdl_as_mem` are mutually exclusive on the same address range.

```yaml
endpoints:
  - name: "cluster"
    addr_range:
      - base: 0x1000_0000
        size: 0x0004_0000
        rdl_name: "cluster_regs" # instantiate an externally-defined `cluster_regs.rdl`
      - base: 0x1000_4000
        size: 0x0000_1000
        rdl_as_mem: true # always render as `external mem`, regardless of --as-mem
    sbr_port_protocol:
      - "axi_out"
```

### SystemRDL Addrmap Groups

Each address range can be tagged with one or more `rdl_addrmap_grp` values to control
which generated SystemRDL addrmap(s) it appears in (see the [`rdl` CLI
command](cli.md#rdl)). This is a per-`addr_range` field, not a per-endpoint one, since
different address ranges of the *same* endpoint (e.g. its main registers vs. a
debug-only region) may need to be reachable from different views. A single group can
be given as a plain string, or multiple groups as a list. Address ranges without
`rdl_addrmap_grp` are considered common and are included in every group's file.

```yaml
endpoints:
  - name: "cluster"
    addr_range:
      - base: 0x1000_0000
        size: 0x0004_0000
        rdl_name: "cluster_regs"
        rdl_addrmap_grp: ["32b", "64b"] # visible in both the 32b and 64b addrmaps
      - base: 0x1000_4000
        size: 0x0000_1000
        rdl_name: "cluster_debug_regs"
        rdl_addrmap_grp: "64b" # only visible in the 64b addrmap
    sbr_port_protocol:
      - "axi_out"
  - name: "hbm"
    addr_range:
      base: 0x8000_0000
      size: 0x1000_0000
      rdl_name: "hbm_regs"
      rdl_addrmap_grp: "64b" # only visible in the 64b addrmap
    sbr_port_protocol:
      - "axi_out"
```
