# _FlooGen_: The NoC Generation Framework

_FlooGen_ is the Python-based configuration and generation framework bundled with _FlooNoC_. While _FlooNoC_ provides the efficient hardware IP blocks (mainly routers and network interfaces), _FlooGen_ acts as the system architect that assembles them into a functional Network-on-Chip.

It transforms a high-level, human-readable description of your network (topology, routing rules, protocols) into fully connected, verified, and synthesizable SystemVerilog RTL.

## Why use a Generator?

Designing a Network-on-Chip manually is tedious and error-prone. Connecting hundreds of router ports, calculating deadlock-free routing tables, and maintaining consistent global address maps becomes unmanageable as system complexity grows.

_FlooGen_ solves this by raising the abstraction level. Instead of writing Verilog wire connections, you define **endpoints**, **routers** and their **connections**. _FlooGen_ handles the low-level implementation details, ensuring that:

* **Protocol conversion**: Network interfaces are automatically instantiated to bridge different endpoint protocols to the NoC link protocol.
* **Routing is correct**: Paths are calculated automatically based on the topology.
* **Configuration is consistent**: Address maps and endpoint IDs are allocated globally without overlaps.

## Key Capabilities

* **Topology Agnostic**: Generate standard topologies (Mesh, Ring, Tree) or completely custom irregular graphs based on your system constraints.
* **Automatic Routing**: Built-in engines to calculate routing tables for different routing algorithms.
* **Protocol Abstraction**: Define endpoints using high-level protocols (e.g., AXI4). _FlooGen_ automatically manages the conversion to the internal NoC link protocol.
* **Network Visualization**: Generate visual graphs of your network topology to inspect connections and routing paths before simulation.
* **Validation**: The internal graph model checks for errors such as overlapping address regions, isolated nodes, or invalid port assignments before a single line of RTL is generated.

## The Generation Flow

_FlooGen_ operates in four distinct stages to turn your configuration into hardware:

1.  **Parse & Elaborate**: Reads the YAML configuration file to understand the requested nodes, links, and system parameters.
2.  **Graph Construction**: Builds an internal Network Graph representation of the system.
3.  **Routing & Mapping**:
    * Runs routing algorithms on the graph.
    * Allocates Endpoint IDs.
    * Computes the global system address map.
4.  **Render**: Generates the final SystemVerilog code using validated templates.

## Generated Artifacts

When you run _FlooGen_, it produces two primary outputs:

* **The NoC Top-Level (`floo_<name>_noc.sv`)**: A structural SystemVerilog module that instantiates all routers and network interfaces and connects them according to the topology.
* **The NoC Package (`floo_<name>_noc_pkg.sv`)**: A SystemVerilog package containing all the necessary metadata, including:
    * Typedefs for flits and links.
    * Routing tables and rules.
    * System address maps and endpoint ID enumerations.
