# FlooNoC: A Fast, Low-Overhead On-chip Network

_FlooNoC_, is a Network-on-Chip (NoC) research project, which is part of the [PULP (Parallel Ultra-Low Power) Platform](https://pulp-platform.org/). The main idea behind _FlooNoC_ is to provide a scalable high-performance NoC for non-coherent systems. _FlooNoC_ was mainly designed to interface with [AXI4+ATOPs](https://github.com/pulp-platform/axi/tree/master), but can easily be extended to other On-Chip protocols. _FlooNoC_ already provides network interface IPs (named chimneys) for AXI4 protocol, which converts to a custom-link level protocol that provides significantly better scalability than AXI4. _FlooNoC_ also includes protocol-agnostic routers based on the custom link-level protocol to transport payloads. Finally, _FlooNoC_ also include additional NoC components to assemble a complete NoC in a modular fashion. _FlooNoC_ is also highly flexible and supports a wide variety of topologies and routing algorithms. A Network generation framework called _FlooGen_ makes it possible to easily generate entire networks based on a simple configuration file.

## Quick Links

<div class="grid cards" markdown>

-   :material-fast-forward:{ .lg .middle } __Setup & Installation__

    ---

    Install Bender for HW IPs and python dependencies for _FlooGen_

    [:octicons-arrow-right-24: Getting started](getting_started.md)

-   :fontawesome-solid-microchip:{ .lg .middle } __Hardware IPs__

    ---

    Check out the documentation of _FlooNoC_ hardware IPs.

    [:octicons-arrow-right-24: Hardware IPs](hw/overview.md)

-   :material-magic-staff:{ .lg .middle } __Network Generation__

    ---

    Learn how to generate a _FlooNoC_ network using _FlooGen_

    [:octicons-arrow-right-24: FlooGen](floogen/overview.md)

-   :material-scale-balance:{ .lg .middle } __License__

    ---

    _FlooNoC_ is available open-source on [GitHub](https://github.com/pulp-platform/FlooNoC) under permissive licenses.

    [:octicons-arrow-right-24: License](license.md)

-   :material-bookshelf:{ .lg .middle } __Publication__

    ---

    Read the publication of _FlooNoC_.

    [:octicons-arrow-right-24: Publication](https://arxiv.org/abs/2305.08562)

-   :material-file-document:{ .lg .middle } __Changelog__

    ---

    Check out what has changed in the latest version of _FlooNoC_.

    [:octicons-arrow-right-24: Changelog](changelog.md)

</div>
