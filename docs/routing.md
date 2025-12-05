# FlooNoC Routing Architecture

## Table of Contents
1. [Introduction](#introduction)
2. [Packet Format](#packet-format)
3. [Coordinate System](#coordinate-system)
4. [Routing Algorithms](#routing-algorithms)
5. [Port ID Mapping](#port-id-mapping)
6. [Routing Examples](#routing-examples)

## Introduction

FlooNoC uses a packet-based Network-on-Chip (NoC) architecture where routers forward packets based on destination coordinates or IDs. This document explains how routing works, how coordinates are assigned, and how packets are routed through the network.

## Packet Format

### Flit Structure

FlooNoC uses a **single-flit packet design** where header and payload are combined into one wide flit. The structure is defined in `hw/include/floo_noc/typedef.svh`:

```systemverilog
typedef struct packed {
  hdr_t hdr;        // Routing header
  payload_t payload; // Data payload
} flit_t;
```

### Header Fields

The header contains routing information:

```systemverilog
typedef struct packed {
  logic rob_req;           // Reorder buffer request
  rob_idx_t rob_idx;       // Reorder buffer index
  dst_t dst_id;            // Destination ID/coordinate
  src_t src_id;            // Source ID/coordinate
  logic last;              // Last flit indicator
  logic atop;              // Atomic operation flag
  axi_ch_e axi_ch;         // AXI channel type
} hdr_t;
```

### Coordinate Structure

For XY routing, the `dst_id` and `src_id` fields contain coordinates:

```systemverilog
typedef struct packed {
  x_bits_t x;           // X coordinate (e.g., 2 bits for 4x4 mesh)
  y_bits_t y;           // Y coordinate (e.g., 2 bits for 4x4 mesh)
  p_bits_t port_id;     // Port ID (0 to N-1 for N local ports)
} xy_node_id_t;
```

**Important Notes:**
- All coordinate fields use **unsigned logic types** (`logic[N-1:0]`)
- The bit widths are automatically calculated based on network size
- For a 4x4 mesh: `x_bits_t = logic[1:0]`, `y_bits_t = logic[1:0]`

## Coordinate System

### Router-Centric Coordinate Assignment

FlooNoC uses a **router-centric** coordinate system where:

1. **Routers** get coordinates directly from their array indices
2. **Network Interfaces (NIs)** derive coordinates from their connected router plus a direction offset

This assignment is performed in `floogen/model/network.py`:

```python
# Stage 1: Assign coordinates to routers from array indices
for node_name, node in self.graph.get_rt_nodes(with_name=True):
    x, y = self.graph.get_node_arr_idx(node_name)
    node_xy_id = Coord(x=x, y=y)
    self.graph.nodes[node_name]["id"] = node_xy_id

# Stage 2: NIs derive coordinates from connected router + direction offset
for node_name, node in self.graph.get_ni_nodes(with_name=True):
    edge = self.graph.edges[(node_name, neighbor)]
    if edge["dst_dir"] is not None:
        node_xy_id = self.graph.nodes[neighbor]["id"] + \
                    XYDirections.to_coords(edge["dst_dir"])
```

### Direction Offsets

When an NI connects to a router via a directional port, its coordinate is calculated as:

```
NI_coordinate = Router_coordinate + Direction_offset
```

Direction offsets are defined in `floogen/model/routing.py`:

| Direction | X Offset | Y Offset | Example Router (1,1) |
|-----------|----------|----------|---------------------|
| North     | 0        | +1       | NI at (1, 2)        |
| East      | +1       | 0        | NI at (2, 1)        |
| South     | 0        | -1       | NI at (1, 0)        |
| West      | -1       | 0        | NI at (0, 1)        |
| Eject     | 0        | 0        | NI at (1, 1)        |

**⚠️ Important:** For XY routing, all NIs should connect via `Eject` ports with different `port_id` values to avoid negative or out-of-bounds coordinates.

### NI Coordinate Configuration

Network Interfaces receive their coordinates at instantiation time via the `id_i` input port (`hw/floo_axi_chimney.sv:74`):

```systemverilog
module floo_axi_chimney (
  input  id_t id_i,  // Coordinate assigned at compile-time
  // ...
);
```

The NI uses this coordinate as the source ID for all outgoing packets:

```systemverilog
floo_axi_aw.hdr.src_id = id_i;  // AW channel
floo_axi_w.hdr.src_id = id_i;   // W channel
floo_axi_ar.hdr.src_id = id_i;  // AR channel
```

## Routing Algorithms

### XY Routing

XY routing is a dimension-ordered routing algorithm implemented in `hw/floo_route_select.sv:101-120`:

```systemverilog
always_comb begin : proc_route_sel
  route_sel_id = East;  // Default

  // Check if destination reached
  if (id_in.x == xy_id_i.x && id_in.y == xy_id_i.y) begin
    // At destination router: use port_id to select local port
    route_sel_id = Eject + channel_i.hdr.dst_id.port_id;
  end
  // Route in Y dimension first (when X matches)
  else if (id_in.x == xy_id_i.x) begin
    if (id_in.y < xy_id_i.y) route_sel_id = South;
    else route_sel_id = North;
  end
  // Route in X dimension (when X doesn't match)
  else begin
    if (id_in.x < xy_id_i.x) route_sel_id = West;
    else route_sel_id = East;
  end
end
```

**Key Points:**
- **port_id is ONLY used when (x, y) coordinates match** the destination router
- Directional routing (North/East/South/West) is based ONLY on x, y coordinates
- port_id does NOT affect directional routing decisions

### ID Routing

ID routing uses lookup tables to map destination IDs to output ports. This allows for:
- Arbitrary network topologies
- Non-mesh interconnects
- Custom routing policies

The lookup table is generated in the package and indexed by the destination ID.

## Port ID Mapping

### Physical Port Assignment

Router ports are numbered according to `hw/floo_pkg.sv:45-52`:

```systemverilog
typedef enum logic[2:0] {
  North = 3'd0,  // Port 0
  East  = 3'd1,  // Port 1
  South = 3'd2,  // Port 2
  West  = 3'd3,  // Port 3
  Eject = 3'd4   // Port 4 (first local port)
} route_direction_e;
```

### Port ID to Physical Port Mapping

When a packet reaches its destination router (x and y match), the physical port is selected using:

```systemverilog
route_sel_id = Eject + port_id;
```

This means:

```
Physical Port Number = 4 + port_id
```

### Complete Mapping Table

| port_id | Calculation | Physical Port | Port Name | Usage            |
|---------|-------------|---------------|-----------|------------------|
| 0       | 4 + 0       | **4**         | Eject+0   | 1st local port   |
| 1       | 4 + 1       | **5**         | Eject+1   | 2nd local port   |
| 2       | 4 + 2       | **6**         | Eject+2   | 3rd local port   |
| 3       | 4 + 3       | **7**         | Eject+3   | 4th local port   |
| N       | 4 + N       | **4+N**       | Eject+N   | (N+1)th local port |

### Critical Understanding

❌ **WRONG Interpretation:**
```
port_id=0 → North (Port 0)  ✗
port_id=1 → East  (Port 1)  ✗
port_id=2 → South (Port 2)  ✗
port_id=3 → West  (Port 3)  ✗
```

✅ **CORRECT Interpretation:**
```
port_id=0 → Port 4 (Eject+0)  ✓ Local port
port_id=1 → Port 5 (Eject+1)  ✓ Local port
port_id=2 → Port 6 (Eject+2)  ✓ Local port
port_id=3 → Port 7 (Eject+3)  ✓ Local port
```

**All port_id values select local ports, never directional ports!**

### Router Degree Requirements

To use a given maximum port_id, the router must have sufficient ports:

| Max port_id | Required Ports | Router Degree |
|-------------|----------------|---------------|
| 0           | ≥ 5            | degree ≥ 5    |
| 1           | ≥ 6            | degree ≥ 6    |
| 2           | ≥ 7            | degree ≥ 7    |
| 3           | ≥ 8            | degree ≥ 8    |

Port allocation:
- **Ports 0-3:** North, East, South, West (directional ports)
- **Ports 4+:** Eject, Eject+1, Eject+2, ... (local ports)

## Routing Examples

### Scenario: Router with 3 Local Nodes

Consider Router(1,1) with degree=7 connecting 3 local nodes:

```yaml
routers:
  - name: "router"
    array: [4, 4]
    degree: 7  # 4 directional + 3 local = 7 ports

connections:
  - src: "cluster"
    dst: "router"
    dst_dir: "Eject"  # port_id=0

  - src: "hbm"
    dst: "router"
    dst_dir: "Eject"  # port_id=1

  - src: "dram"
    dst: "router"
    dst_dir: "Eject"  # port_id=2
```

### Port Assignment for Router(1,1)

```
Router(1,1) degree=7:
  Port 0: North  → connects to Router(1,2)
  Port 1: East   → connects to Router(2,1)
  Port 2: South  → connects to Router(1,0)
  Port 3: West   → connects to Router(0,1)
  Port 4: Eject+0 → Cluster(1,1)  ← port_id=0
  Port 5: Eject+1 → HBM[5]        ← port_id=1
  Port 6: Eject+2 → DRAM[5]       ← port_id=2
```

### Coordinate Assignment

| Node         | Coordinate           | Physical Port |
|--------------|----------------------|---------------|
| Cluster(1,1) | {x:1, y:1, port_id:0} | Port 4        |
| HBM[5]       | {x:1, y:1, port_id:1} | Port 5        |
| DRAM[5]      | {x:1, y:1, port_id:2} | Port 6        |

### Example 1: Packet to Cluster(1,1)

```
Destination: dst_id = {x:1, y:1, port_id:0}
Source: Router(0,0)

Routing path:
  Router(0,0): x≠1 → East → Router(1,0)
  Router(1,0): x=1, y≠1 → North → Router(1,1)
  Router(1,1): x=1, y=1 ✓ (match!)
               route_sel_id = Eject + 0 = 4
               → Port 4 → Cluster
```

### Example 2: Packet to HBM[5]

```
Destination: dst_id = {x:1, y:1, port_id:1}
Source: Router(0,0)

Routing path:
  Router(0,0): x≠1 → East → Router(1,0)
  Router(1,0): x=1, y≠1 → North → Router(1,1)
  Router(1,1): x=1, y=1 ✓ (match!)
               route_sel_id = Eject + 1 = 5
               → Port 5 → HBM
```

### Example 3: Packet to DRAM[5]

```
Destination: dst_id = {x:1, y:1, port_id:2}
Source: Router(0,0)

Routing path:
  Router(0,0): x≠1 → East → Router(1,0)
  Router(1,0): x=1, y≠1 → North → Router(1,1)
  Router(1,1): x=1, y=1 ✓ (match!)
               route_sel_id = Eject + 2 = 6
               → Port 6 → DRAM
```

### Key Observation

**Multiple packets with the same (x,y) but different port_id:**
- Take IDENTICAL paths through the mesh
- Only diverge at the FINAL destination router
- The final router uses port_id to select the correct local port

### Example with port_id=3

If a 4th local node (e.g., SSD) is added:

```
Router degree=8:
  Port 0-3: North/East/South/West
  Port 4: Eject+0 (Cluster)
  Port 5: Eject+1 (HBM)
  Port 6: Eject+2 (DRAM)
  Port 7: Eject+3 (SSD) ← port_id=3
```

Coordinate: `{x:1, y:1, port_id:3}`
Routing result: `route_sel_id = 4 + 3 = 7` → Port 7 → SSD

## Important Conclusions

### 1. port_id Never Selects Directional Ports

No matter what value port_id has (0, 1, 2, 3, or higher):

```
Physical Port = 4 + port_id ≥ 4
```

Since directional ports are 0-3 and local ports start at 4, it is **mathematically impossible** for port_id to select a directional port.

### 2. Directional Routing Only Uses Coordinates

To select North/East/South/West (Ports 0-3), the ONLY mechanism is coordinate comparison:

```systemverilog
// When x or y coordinates don't match
if (id_in.x < xy_id_i.x) route_sel_id = West;   // Port 3
else if (id_in.x > xy_id_i.x) route_sel_id = East;  // Port 1
else if (id_in.y < xy_id_i.y) route_sel_id = South; // Port 2
else route_sel_id = North;  // Port 0
```

This logic **does not use port_id at all**.

### 3. Best Practices for XY Routing

For XY routing configurations:

✅ **Recommended:**
- Connect all endpoints via `Eject` direction
- Use different `port_id` values for multiple endpoints at same router
- Ensure router degree ≥ 4 + (number of local endpoints)

❌ **Avoid:**
- Connecting endpoints via North/East/South/West directions
- This can create negative or out-of-bounds coordinates
- Use ID routing if such connections are needed

### 4. When to Use ID Routing

Use ID routing instead of XY routing when:
- Arbitrary topology required (not a regular mesh)
- Endpoints need to connect via directional ports
- Custom routing policies needed
- Negative coordinates would otherwise occur

## See Also

- [FlooGen Configuration Guide](floogen.md) - Network configuration format
- `hw/floo_route_select.sv` - Router routing logic implementation
- `hw/include/floo_noc/typedef.svh` - Packet and header type definitions
- `floogen/model/network.py` - Coordinate assignment implementation
