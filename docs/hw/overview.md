# Overview of the Hardware IPs

_FlooNoC_ is a collection of Network-on-Chip (NoC) IPs written in SystemVerilog that can used to assemble an NoC. In system architecture, there are a myriad of different considerations that go into the implementation of the on-chip network. From the topology of the network, the routing algorithm, flow-control, the use of virtual or physical channels, etc. This is why our goal was to make the _FlooNoC_ IPs as modular, configurable and extendible as possible, so that they can be easily integrated into any system.

However, this also means that the hardware IPs are heavily parametrizable and the user has to make a lot of decisions when configuring the _FlooNoC_ IPs. This is what this documentation aims to help with. It will guide through all the available IPs, explain their architecture, and show how they need to be configured and what the trade-offs are. The documentation is structured as follows:

1. **[Links](links.md)**: This section will explain the custom link-level protocol, which is used to connect the routers and network interfaces in the NoC.

1. **[Routing Algorithms](route_algos.md)**: This section will explain the different routing algorithms that are available in _FlooNoC_ and how they can be configured.

1. **[Network Interfaces](chimneys.md)**: This section will explain the different network interfaces which are used to convert to the custom link-level protocol of _FlooNoC_.

1. **[Routers](routers.md)**: This section will explain the routers routers that are available in _FlooNoC_ and how they can be configured.

1. **[Common IPs](commons.md)**: Apart from the two essential IPs, routers and network interfaces, there are also some common IPs that can be used to extend the functionality of the NoC. This section will explain these IPs.

1. **[Verification IPs](vips.md)**: This section will explain the verification IPs that are available in _FlooNoC_ and how they can be used to verify the NoC.

1. **[Tips & Tricks](tips.md)**: This section will give some tips and tricks on how to use the _FlooNoC_ IPs.
