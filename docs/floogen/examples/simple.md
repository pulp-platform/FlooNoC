# Simple Example: Star Topology

This example demonstrates a basic **Star Topology** configuration. It consists of a single central router that connects multiple endpoints, including a compute cluster, HBM memory, and peripherals. It uses **ID-based routing** and supports heterogeneous **Narrow-Wide** links.

## Key Features

* **Topology**: Star (Single Router).
* **Network Type**: `narrow-wide` (separate control and data planes).
* **Routing**: `ID` (Table-based routing).
* **Roles**: Demonstrates endpoints acting as Managers (Masters), Subordinates (Slaves), or both.

## Configuration

### Global Settings & Routing

The network is defined as `narrow-wide`, meaning links carry both a narrow control channel and a wide data channel. The routing algorithm is set to `ID`, which uses a lookup table in the router to forward packets based on the destination ID, rather than geometric coordinates.

```yaml
name: single_cluster
description: "Single Cluster Configuration for FlooGen"
network_type: "narrow-wide"

routing:
  route_algo: "ID"
  use_id_table: true
```

### Protocols

Four protocols are defined to support the heterogeneous network. `narrow` protocols are used for control messages (64-bit data), while `wide` protocols handle bulk data transfer (512-bit data).

```yaml
protocols:
  - name: "narrow_in"
    type: "narrow"
    protocol: "AXI4"
    data_width: 64
    # ...
  - name: "wide_in"
    type: "wide"
    protocol: "AXI4"
    data_width: 512
    # ...
```

### Endpoints

The endpoints represent the various IP blocks in the system.

  * **Cluster**: A processing cluster that acts as both Manager (sends requests) and Subordinate (receives requests).
  * **HBM**: A high-bandwidth memory that acts only as a Subordinate.
  * **CVA6**: A processor core acting as a Manager only (fetching instructions/data).

```yaml
endpoints:
  - name: "cluster"
    addr_range:
      base: 0x1000_0000
      size: 0x0004_0000
    mgr_port_protocol:
      - "narrow_in"
      - "wide_in"
    sbr_port_protocol:
      - "narrow_out"
      - "wide_out"
  - name: "hbm"
    addr_range:
      base: 0x8000_0000
      size: 0x4000_0000
    sbr_port_protocol:
      - "wide_out"
  - name: "cva6"
    mgr_port_protocol:
      - "narrow_in"
```

### Router

A single router is defined. Since it is not an array, it represents a discrete switching unit.

```yaml
routers:
  - name: "router"
```

### Connections

All connections are point-to-point links between the endpoints and the central router, effectively forming the star topology. Unlike mesh configurations, no coordinate ranges or directions are needed here; FlooGen simply links the specified source to the destination.

```yaml
connections:
  - src: "cluster"
    dst: "router"
  - src: "hbm"
    dst: "router"
  - src: "serial_link"
    dst: "router"
  - src: "cva6"
    dst: "router"
  - src: "peripherals"
    dst: "router"
```
