# FlooNoC: A Fast, Low-Overhead On-chip Network

_FlooNoC_, is a Network-on-Chip (NoC) research project, which is part of the [PULP (Parallel Ultra-Low Power) Platform](https://pulp-platform.org/). The main idea behind _FlooNoC_ is to provide a scalable high-performance NoC for non-coherent systems. _FlooNoC_ was mainly designed to interface with [AXI4+ATOPs](https://github.com/pulp-platform/axi/tree/master), but can easily be extended to other On-Chip protocols. _FlooNoC_ already provides network interface IPs (named chimneys) for AXI4 protocol, which converts to a custom-link level protocol that provides significantly better scalability than AXI4. _FlooNoC_ also includes protocol-agnostic routers based on the custom link-level protocol to transport payloads. Finally, _FlooNoC_ also include additional NoC components to assemble a complete NoC in a modular fashion. _FlooNoC_ is also highly flexible and supports a wide variety of topologies and routing algorithms. A Network generation framework called _FlooGen_ makes it possible to easily generate entire networks based on a simple configuration file.

## Getting Started

Check out our getting started [guide](https://pulp-platform.github.io/FlooNoC/getting_started/)

## Directory structure

- `docs`: Contains the documentation of the project
- `hw`: Contains all SystemVerilog files for the hardware implementation
  - `test`: Contains verification IPs (VIPs) for testing
  - `tb`: Contains testbenches for module verification
  - `include`: Contains macros for _FlooNoC_ typedefs
- `floogen`: Contains the _FlooGen_ network generation framework
  - `examples`: Contains example network configurations
  - `model`: Contains the _FlooGen_ models for the network components such as network interfaces, routers and endpoints.
  - `tempaltes`: Contains the `mako` templates to render the SV components
  - `test`: Contains tests for the _FlooGen_ framework
