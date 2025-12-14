<div align="center">

  <img src="docs/img/floo_noc_logo.png" alt="Logo" width="300">

# FlooNoC: A Fast, Low-Overhead On-chip Network
</div>

<a href="https://pulp-platform.org">
<img src="docs/img/pulp_logo_icon.svg" alt="Logo" width="100" align="right">
</a>

_FlooNoC_ is a configurable, open-source Network-on-Chip (NoC) architecture designed for high-bandwidth, non-coherent multi-core clusters and AI accelerators. It addresses the bandwidth bottlenecks of traditional serialized NoCs by deploying **wide physical channels** that transport entire AXI4 messages (header + data) in a single flit, eliminating serialization latency.

Designed for the [PULP Platform](https://pulp-platform.org/), _FlooNoC_ decouples the low-complexity transport layer (routers) from the protocol handling (Network Interfaces), enabling high scalability. It supports **end-to-end AXI4** with multiple outstanding transactions and separates traffic into parallel physical streams—isolating bulk DMA transfers from latency-sensitive control messages.

Included is **_FlooGen_**, a Python-based generation framework that produces fully connected SystemVerilog RTL, routing information and tables from a simple high-level configuration file.

<div align="center">

[![CI status](https://github.com/pulp-platform/FlooNoC/actions/workflows/gitlab-ci.yml/badge.svg?branch=main)](https://github.com/pulp-platform/FlooNoC/actions/workflows/gitlab-ci.yml?query=branch%3Amain)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/pulp-platform/FlooNoC?color=blue&label=current&sort=semver)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE-APACHE)
[![License](https://img.shields.io/badge/license-SHL--0.51-green)](LICENSE-SHL)
[![Static Badge](https://img.shields.io/badge/IEEE_TVLSI-blue?style=flat&label=DOI&color=00629b)](https://doi.org/10.1109/TVLSI.2025.3527225)
[![Static Badge](https://img.shields.io/badge/2409.17606-blue?style=flat&label=arXiv&color=b31b1b)](https://arxiv.org/abs/2409.17606)

[**Read the Documentation**](https://pulp-platform.github.io/FlooNoC/) •
[Design Principles](#-design-principles) •
[Publication](#-publication) •
[License](#-license)
</div>

## 📚 Documentation

Complete documentation, including installation guides, simulation instructions, and IP references, is available online:

### [👉 pulp-platform.github.io/FlooNoC](https://pulp-platform.github.io/FlooNoC/)

The documentation is organized into two main tracks:

| **Hardware IPs (FlooNoC)** | **Generator (FlooGen)** |
|:--- |:--- |
| Focuses on the SystemVerilog IPs, simulation, and integration. | Focuses on configuration, topology generation, and CLI usage. |
| • [**Getting Started**](https://pulp-platform.github.io/FlooNoC/floonoc/getting_started/)<br>• [Architecture Overview](https://pulp-platform.github.io/FlooNoC/floonoc/overview/)<br>• [Routers & Chimneys](https://pulp-platform.github.io/FlooNoC/floonoc/routers/) | • [**Installation**](https://pulp-platform.github.io/FlooNoC/floogen/installation/)<br>• [Configuration Format](https://pulp-platform.github.io/FlooNoC/floogen/minimal_example/)<br>• [CLI Reference](https://pulp-platform.github.io/FlooNoC/floogen/cli/) |
## 💡 Design Principles
_FlooNoC_ is built on five key principles to achieve high bandwidth and low latency:

1. **Wide Physical Channels**: Unlike traditional NoCs that serialize packets into narrow flits, _FlooNoC_ uses wide links to send entire messages (header + data) in a single cycle. This allows endpoints to utilize their full bandwidth without being constrained by NoC frequency or serialization overhead.

2. **Full AXI4 Support**: The architecture fully supports AXI4+ATOPs (AXI5), handling bursts and multiple outstanding transactions efficiently. It provides end-to-end ordering and ID tracking, ensuring seamless integration with standard IP blocks.

3. **Decoupled Architecture**: Complexity is moved to the edges (Network Interfaces/Chimneys), keeping the routers simple and fast. This decoupling allows the network to scale to hundreds of cores without timing degradation.

4. **Traffic Separation**: _FlooNoC_ can physically separate traffic classes. High-bandwidth, burst-based traffic (e.g., DMA) travels on wide links, while latency-sensitive control traffic travels on separate narrow links, preventing head-of-line blocking.

5. **Modularity**: The system is composed of modular building blocks—Routers, Links, and Chimneys (Network Interfaces). This modularity allows _FlooGen_ to assemble arbitrary topologies (Mesh, Tree, Irregular) tailored to specific system requirements.

## 🔮 Origin of the name

The names of the IPs are inspired by the [Harry Potter](https://en.wikipedia.org/wiki/Harry_Potter) universe, where the [Floo Network](https://harrypotter.fandom.com/wiki/Floo_Network) is a magical transportation system. The Network interfaces are named after the fireplaces and chimneys used to access the Floo Network.

> In use for centuries, the Floo Network, while somewhat uncomfortable, has many advantages. Firstly, unlike broomsticks, the Network can be used without fear of breaking the International Statute of Secrecy. Secondly, unlike Apparition, there is little to no danger of serious injury. Thirdly, it can be used to transport children, the elderly and the infirm."

## 🔐 License
All code checked into this repository is made available under a permissive license. All software sources are licensed under the Apache License 2.0 (see [`LICENSE-APACHE`](LICENSE-APACHE)), and all hardware sources in the `hw` folder are licensed under the Solderpad Hardware License 0.51 (see [`LICENSE-SHL`](LICENSE-SHL)).

## 📖 Publication
If you use FlooNoC in your research, please cite the following paper:
<details>
<summary><b>FlooNoC: A 645 Gbps/link 0.15 pJ/B/hop Open-Source NoC with Wide Physical Links and End-to-End AXI4 Parallel Multi-Stream Support</b></summary>
<p>

```
@ARTICLE{10848526,
  author={Fischer, Tim and Rogenmoser, Michael and Benz, Thomas and Gürkaynak, Frank K. and Benini, Luca},
  journal={IEEE Transactions on Very Large Scale Integration (VLSI) Systems},
  title={FlooNoC: A 645-Gb/s/link 0.15-pJ/B/hop Open-Source NoC With Wide Physical Links and End-to-End AXI4 Parallel Multistream Support},
  year={2025},
  volume={33},
  number={4},
  pages={1094-1107},
  keywords={Bandwidth;Very large scale integration;Data transfer;Routing;Complexity theory;Scalability;Nickel;Memory management;Engines;Europe;Advanced extensible interface (AXI);network interface (NI);network-on-chip (NoC);physical design;very large scale integration},
  doi={10.1109/TVLSI.2025.3527225}}

```

</p>
</details>

## ⭐ Getting Started

### Pre-requisites

FlooNoC uses [bender](https://github.com/pulp-platform/bender) to manage its dependencies and to automatically generate compilation scripts. Further `Python >= 3.10` is required to install the generation framework.

### Simulation
Currently, we do not provide any open-source simulation setup. Internally, the FlooNoC was tested using QuestaSim, which can be launched with the following command:

```sh
# Compile the sources
make compile-sim
# Run the simulation
make run-sim-batch TB_DUT=tb_floo_dut
```

or in the GUI, with prepared waveforms:

```sh
# Compile the sources
make compile-sim
# Run the simulation
make run-sim TB_DUT=tb_floo_dut
```
By replacing `tb_floo_dut` with the name of the testbench you want to simulate.

## 🛠️ Generation

FlooNoC comes with a generation framework called `floogen`. It allows to create complex network configurations with a simple configuration file.

### Capabilities

`floogen` has a graph-based internal representation of the network configuration. This allows to easily add new features and capabilities to the generation framework. The following list shows the a couple of the current capabilities of `floogen`:

- **Validation**: The configuration is validated before the generation to ensure that the configuration is valid. For instance, the configuration is checked for invalid user input, overlapping address ranges
- **Routing**: XY-Routing and ID-Table routing are supported. `floogen` automatically generates the routing tables for the routers, as well as the address map for the network interfaces.
- **Package Generation**: `floogen` automatically generates a SystemVerilog package with all the needed types and constants for the network configuration.
- **Top Module Generation**: `floogen` automatically generates a top module that contains all router and network interfaces. The interfaces of the top module are AXI4 interfaces for all the enpdoints specified in the configuration.

### Example

The following example shows the configuration for a simple mesh topology with 4x4 routers and 4x4 chimneys with XY-Routing.

```yaml
  name: example_system
  description: "Example of a configuration file"

  routing:
    route_algo: "XY"
    use_id_table: true

  protocols:
    - name: "axi_in"
      type: "AXI4"
      data_width: 64
      addr_width: 32
      id_width: 3
      user_width: 1
    - name: "axi_out"
      type: "AXI4"
      data_width: 64
      addr_width: 32
      id_width: 3
      user_width: 1

  endpoints:
    - name: "cluster"
      array: [4, 4]
      addr_range:
        base: 0x1000_0000
        size: 0x0004_0000
      mgr_port_protocol:
        - "axi_in"
      sbr_port_protocol:
        - "axi_out"

  routers:
    - name: "router"
      array: [4, 4]

  connections:
    - src: "cluster"
      dst: "router"
      src_range:
      - [0, 3]
      - [0, 3]
      dst_range:
      - [0, 3]
      - [0, 3]
      bidirectional: true
```

### Usage

To install `floogen` run the following command:

```sh
pip install .
```

which allows you to use `floogen` with the following command:

```sh
floogen rtl -c <config_file> -o <output_dir>
```

### Configuration

The example configuration above shows the basic structure of a configuration file. A more detailed description of the configuration file can be found in the [documentation](docs/floogen.md).
