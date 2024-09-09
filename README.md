<div align="center">

  <img src="docs/img/floo_noc_logo.png" alt="Logo" width="300">

# FlooNoC: A Fast, Low-Overhead On-chip Network
</div>

<a href="https://pulp-platform.org">
<img src="docs/img/pulp_logo_icon.svg" alt="Logo" width="100" align="right">
</a>

_FlooNoC_, is a Network-on-Chip (NoC) research project, which is part of the [PULP (Parallel Ultra-Low Power) Platform](https://pulp-platform.org/). The main idea behind _FlooNoC_ is to provide a scalable high-performance NoC for non-coherent systems. _FlooNoC_ was mainly designed to interface with [AXI4+ATOPs](https://github.com/pulp-platform/axi/tree/master), but can easily be extended to other On-Chip protocols. _FlooNoC_ already provides network interface IPs (named chimneys) for AXI4 protocol, which converts to a custom-link level protocol that provides significantly better scalability than AXI4. _FlooNoC_ also includes protocol-agnostic routers based on the custom link-level protocol to transport payloads. Finally, _FlooNoC_ also include additional NoC components to assemble a complete NoC in a modular fashion. _FlooNoC_ is also highly flexible and supports a wide variety of topologies and routing algorithms. A Network generation framework called _FlooGen_ makes it possible to easily generate entire networks based on a simple configuration file.

<div align="center">

[![CI status](https://github.com/pulp-platform/FlooNoC/actions/workflows/gitlab-ci.yml/badge.svg?branch=main)](https://github.com/pulp-platform/FlooNoC/actions/workflows/gitlab-ci.yml?query=branch%3Amain)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/pulp-platform/FlooNoC?color=blue&label=current&sort=semver)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE-APACHE)
[![License](https://img.shields.io/badge/license-SHL--0.51-green)](LICENSE-SHL)
[![Static Badge](https://img.shields.io/badge/IEEE_D%26T-blue?style=flat&label=DOI&color=00629b)](https://doi.org/10.1109/MDAT.2023.3306720)
[![Static Badge](https://img.shields.io/badge/2409.17606-blue?style=flat&label=arXiv&color=b31b1b)](https://arxiv.org/abs/2409.17606)

[Design Principles](#-design-principles) •
[Getting started](#-getting-started) •
[List of IPs](#-list-of-ips) •
[Generation](#%EF%B8%8F-generation) •
[License](#-license)
</div>

## 💡 Design Principles

_FlooNoC_ design is based on the following key principles:

1. **Full AXI4 Support**: _FlooNoC_ fully supports AXI4+ATOPs from AXI5 as outlined [here](https://github.com/pulp-platform/axi/tree/master), providing a high-bandwidth and latency-tolerant solution. _FlooNoC_ achieves this with full support for bursts and multiple outstanding transactions.

1. **Decoupled Links and Networks**: _FlooNoC_ uses a link-level protocol that is decoupled from the network-level protocol. This allows us to move the complexity of the network-level protocol into the network interfaces, while deploying low-complexity routers in the network, that enable better scalability than multi-layer AXI networks.

1. **Wide Physical Channels**: _FlooNoC_ uses wide physical channels to meet the high-bandwidth requirements at network endpoints without being constrained by the operating frequency. In contrast to traditional NoCs which use serialization with header and tail flits to transport a message, _FlooNoC_ avoids any kind of serialization and sends entire messages in a single flit including header and tail information.

1. **Separation of traffic**: _FlooNoC_ addresses diverse types of traffic that can occur in non-coherent systems, by decoupling multiple links to handle wide, high-bandwidth, burst-based traffic and narrow, latency-sensitive traffic with separate physical channels.

1. **Modularity:** The _FlooNoC_ architecture is designed with modularity in mind. It includes a set of IPs that can be instantiated together to build a NoC. This approach not only promotes reusability but also facilitates flexibility in designing custom NoCs to cater to a variety of specific system requirements.


## 🔮 Origin of the name

The names of the IPs are inspired by the [Harry Potter](https://en.wikipedia.org/wiki/Harry_Potter) universe, where the [Floo Network](https://harrypotter.fandom.com/wiki/Floo_Network) is a magical transportation system. The Network interfaces are named after the fireplaces and chimneys used to access the Floo Network.

> In use for centuries, the Floo Network, while somewhat uncomfortable, has many advantages. Firstly, unlike broomsticks, the Network can be used without fear of breaking the International Statute of Secrecy. Secondly, unlike Apparition, there is little to no danger of serious injury. Thirdly, it can be used to transport children, the elderly and the infirm."

## 🔐 License
All code checked into this repository is made available under a permissive license. All software sources are licensed under the Apache License 2.0 (see [`LICENSE-APACHE`](LICENSE-APACHE)), and all hardware sources in the `hw` folder are licensed under the Solderpad Hardware License 0.51 (see [`LICENSE-SHL`](LICENSE-SHL)).

## 📚 Publication
If you use FlooNoC in your research, please cite the following papers:
<details>
<summary><b>FlooNoC: A 645 Gbps/link 0.15 pJ/B/hop Open-Source NoC with Wide Physical Links and End-to-End AXI4 Parallel Multi-Stream Support</b></summary>
<p>

```
@misc{fischer2024floonoc645gbpslink015,
      title={FlooNoC: A 645 Gbps/link 0.15 pJ/B/hop Open-Source NoC with Wide Physical Links and End-to-End AXI4 Parallel Multi-Stream Support},
      author={Tim Fischer and Michael Rogenmoser and Thomas Benz and Frank K. Gürkaynak and Luca Benini},
      year={2024},
      eprint={2409.17606},
      archivePrefix={arXiv},
      primaryClass={cs.AR},
      url={https://arxiv.org/abs/2409.17606}}
```

</p>
</details>
<details>
<summary><b>FlooNoC: A Multi-Tbps Wide NoC for Heterogeneous AXI4 Traffic</b></summary>
<p>

```
@ARTICLE{10225380,
  author={Fischer, Tim and Rogenmoser, Michael and Cavalcante, Matheus and Gürkaynak, Frank K. and Benini, Luca},
  journal={IEEE Design & Test},
  title={FlooNoC: A Multi-Tb/s Wide NoC for Heterogeneous AXI4 Traffic},
  year={2023},
  volume={40},
  number={6},
  pages={7-17},
  keywords={Bandwidth;Protocols;Scalability;Routing;Payloads;Complexity theory;Network interfaces;Network-on-chip;Network-On-Chip;AXI;Network Interface;Physical design},
  doi={10.1109/MDAT.2023.3306720}}

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

## 🧰 List of IPs

This repository includes the following NoC IPs:

1. **Routers:** A collection of different NoC router designs with varying features such as virtual channels, input/output buffering, and adaptive routing algorithms.
1. **Network Interfaces (NIs)**: A set of NoC network interfaces for connecting IPs to the NoC.
2. **Common IPs** A set of IPs used by the NoC IPs, such as FIFOs, Cuts and arbiters.
3. **Verification IPs (VIPs):** A set of VIPs to verify the correct functionality of the NoC IPs.
4. **Testbenches:** A set of testbenches to evaluate the performance of the NoC IPs, including throughput, latency.

### Routers
| Name | Description | Doc |
| --- | --- | --- |
| [floo_router](hw/floo_router.sv) | A simple router with configurable number of ports, physical and virtual channels, and input/output buffers |  |
| [floo_nw_router](hw/floo_nw_router.sv) | Wrapper of a multi-link router for narrow and wide links |  |

### Network Interfaces
| Name | Description | Doc |
| --- | --- | --- |
| [floo_axi_chimney](hw/floo_axi_chimney.sv) | A bidirectional network interface for connecting AXI4 Buses to the NoC |  |
| [floo_nw_chimney](hw/floo_nw_chimney.sv) | A bidirectional network interface for connecting narrow & wide AXI Buses to the multi-link NoC |  |

### Common IPs
| Name | Description | Doc |
| --- | --- | --- |
| [floo_fifo](hw/floo_fifo.sv) | A FIFO buffer with configurable depth |  |
| [floo_cut](hw/floo_cut.sv) | Elastic buffers for cuting timing paths |  |
| [floo_cdc](hw/floo_cdc.sv) | A Clock-Domain-Crossing (CDC) module implemented with a gray-counter based FIFO. |  |
| [floo_wormhole_arbiter](hw/floo_wormhole_arbiter.sv) | A wormhole arbiter |  |
| [floo_vc_arbiter](hw/floo_vc_arbiter.sv) | A virtual channel arbiter |  |
| [floo_route_comp](hw/floo_route_comp.sv) | A helper module to compute the packet destination |  |
| [floo_rob](hw/floo_rob.sv) | A table-based Reorder Buffer |  |
| [floo_simple_rob](hw/floo_simple_rob.sv) | A simplistic low-complexity Reorder Buffer |  |
| [floo_rob_wrapper](hw/floo_simple_rob.sv) | A wrapper of all available types of RoBs including RoB-less version |  |
| [floo_nw_join](hw/floo_nw_join.sv) | A mux for joining a narrow and wide AXI bus a single wide bus |  |

### Verification IPs
| Name | Description | Doc |
| --- | --- | --- |
| [axi_bw_monitor](hw/test/axi_bw_monitor.sv) | A AXI4 Bus Monitor for measuring the throughput and latency of the AXI4 Bus |  |
| [axi_reorder_compare](hw/test/axi_reorder_compare.sv) | A AXI4 Bus Monitor for verifying the order of AXI transactions with the same ID |  |
| [floo_axi_rand_slave](hw/test/floo_axi_rand_slave.sv) | A AXI4 Bus Multi-Slave generating random AXI respones with configurable response time |  |
| [floo_axi_test_node](hw/test/floo_axi_test_node.sv) | A AXI4 Bus Master-Slave Node for generating random AXI transactions |  |
| [floo_dma_test_node](hw/test/floo_dma_test_node.sv) | An endpoint node with a DMA master port and a Simulation Memory Slave port |  |
| [floo_hbm_model](hw/test/floo_hbm_model.sv) | A very simple model of the HBM memory controller with configurable delay |  |

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
floogen -c <config_file> -o <output_dir>
```

### Configuration

The example configuration above shows the basic structure of a configuration file. A more detailed description of the configuration file can be found in the [documentation](docs/floogen.md).
