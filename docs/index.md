# FlooNoC: A Fast, Low-Overhead On-chip Network

_FlooNoC_, is a Network-on-Chip (NoC) research project, which is part of the [PULP (Parallel Ultra-Low Power) Platform](https://pulp-platform.org/). The main idea behind _FlooNoC_ is to provide a scalable high-performance NoC for non-coherent systems. _FlooNoC_ was mainly designed to interface with [AXI4+ATOPs](https://github.com/pulp-platform/axi/tree/master), but can easily be extended to other On-Chip protocols. _FlooNoC_ already provides network interface IPs (named chimneys) for AXI4 protocol, which converts to a custom-link level protocol that provides significantly better scalability than AXI4. _FlooNoC_ also includes protocol-agnostic routers based on the custom link-level protocol to transport payloads. Finally, _FlooNoC_ also include additional NoC components to assemble a complete NoC in a modular fashion. _FlooNoC_ is also highly flexible and supports a wide variety of topologies and routing algorithms. A Network generation framework called _FlooGen_ makes it possible to easily generate entire networks based on a simple configuration file.

## Quick Links

<div class="grid cards" markdown>

-   :fontawesome-solid-microchip:{ .lg .middle } __FlooNoC__

    ---

    Check out the documentation of _FlooNoC_.

    [:octicons-arrow-right-24: FlooNoC](floonoc/overview.md)

-   :material-magic-staff:{ .lg .middle } __FlooGen__

    ---

    Learn how to generate a _FlooNoC_ network using _FlooGen_

    [:octicons-arrow-right-24: FlooGen](floogen/overview.md)

-   :material-bookshelf:{ .lg .middle } __Publication__

    ---

    Read the publication of _FlooNoC_.

    [:octicons-arrow-right-24: Publication](https://arxiv.org/abs/2409.17606)

-   :material-file-document:{ .lg .middle } __Changelog__

    ---

    Check out what has changed in the latest versions.

    [:octicons-arrow-right-24: Changelog](CHANGELOG.md)


</div>
