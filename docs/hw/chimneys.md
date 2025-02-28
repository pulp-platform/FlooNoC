# Network interfaces (a.k.a. chimneys)

Network interfaces (NIs) are essentially the gateway to the Network-on-Chip (NoC). Every endpoint in the system requires its own NI to issue and receive packets over the NoC. The main purpose of the NI is to translate the on-chip protocol (e.g. AXI) to the link-level protocol of the network. NIs are not trivial to implement since they need to adhere to all the rules of the on-chip protocol e.g. ordering, flow control, etc. However, the advantage of using NIs is that the rest of the network can be agnostic to the on-chip protocol, which results in simpler router microarchitecture and as well as better scalability. Currently, _FlooNoC_ was mainly designed to support AXI4 and ships with dedicated NIs. However, it is possible to extend _FlooNoC_ also with other protocols, by implementing custom NIs.

??? quote "Why chimneys?"
    The name of _FlooNoC_ is derived from the Floo Network of Harry Potter. In the books, the Floo Network is a magical network of fireplaces that allows witches and wizards to travel from one place to another. Therefore, the chimneys are the gateways to the Floo Network, which is why they are called chimneys.

## AXI Network Interface

_FlooNoC_ ships with two different AXI NIs: the `axi_chimney` and the `nw_chimney`, which mainly differ from the ports and links that are connected to them. As the name implies, the `axi_chimney` has a single AXI port and uses only `req`/`rsp` physical channels, while the `nw_chimney` has a narrow *and* a wide AXI port and additionally features a `wide` physical channel. In the following, we will describe the inner workings of the `axi_chimney` in more detail. The `nw_chimney` is very similar, with largely duplicate datapaths for the narrow and wide ports.

### Ordering

One of the main challenges of implementing an NI for the AXI protocol is the strict ordering requirement that is imposed by AXI. The NI interface needs to be able to guarantee that for transactions with the same `txnID` all responses arrive with the same order as how the request were injected into the network. By design, the _FlooNoC_ link-level protocol does not guarantee ordering. For instance, if one request is sent to destination `A` and second request to destination `B`, the response from `B` can arrive before the response from `A`. There are essentially to ways of solving this problem: _Reordering_ or _stalling_.

#### Reordering

Responses that arrive out-of-order are buffered in a reorder buffer (RoB) until they can be delivered in-order. This approach is more performant, since multiple requests can be issued to different endpoints at the same time. However, a RoB is costly in terms of area and needs to be limited in size. Furthermore, the NI still needs to ensure that all responses from the NoC can be handled, either by buffering them in the RoB or forwarding them to the on-chip protocol (if they are in order). Stalling the network is not an option, as this would inevitably lead to deadlocks. Therefore, the NI also needs to track or allocate space in the RoB and only inject new requests into the network if it can guarantee that the responses can be handled:

#### Stalling

Another way to solve the ordering problem is to simply stall the injection of new requests into the network if the NI cannot guarantee that the responses will arrive in order. This approach is very simple to implement, and has a very small overhead, but it can lead to significant performance degredation in some cases. Luckily, there are some optimizations that the AXI NIs apply, which reduce the number of stalls. First, transactions to the same destination are always guaranteed to arrive in order (assuming a static routing algorithm is used in side the network). This means that the NI can inject multiple requests into the network, while the destination stays the same. Second, the ordering requirement only applies to transactions with the same `txnID`. Therefore, downstream components can also use different IDs to avoid ordering issues.

The AXI NIs of _FlooNoC_ offers both options, and there are different implementations that can be set with the `ChimneyCfg.RoBType` parameter. The following table shows the different options:

| RoBType | Description |
|---------|-------------|
| `NoRoB` | No RoB, which stalls transactions of the same `txnID` going to different destinations until the previous transaction is completed. This is option is useful if the ordering of transactions is handled downstream, e.g. in the DMA by issuing AXI transactions with different `txnIDs`. The overhead of this RoB is very low, since it only requires counters for tracking the number of outstanding transactions of each `txnID`.|
| `NormalRoB` |  The most performant but also most complex RoB, which supports reodering of responses. This reorder buffer retains the out-of-order nature of AXI transactions with different IDs. Supports multiple outstanding transactions and bursts |
| `SimpleRoB` | Simpler FIFO-like RoB, which does not support reordering of responses with the same AXI `txnID`. Transactions with different `txnIDs` are effectively serialized. Supports multiple outstanding transactions but currently does not support burst transactions. Mainly useful for B-responses which are single transactions. |

The selection of the RoB type depends on the endpoints that are attached to it. For instance, cores with narrower AXI interfaces might are less costly to reorder with a RoB, while DMAs with wider interfaces and burst requests might be prohibitively expensive to reorder. `FlooNoC` gives the option to specify the RoB type and size in the `ChimneyCfg` parameter. In AXI, both read and write response exist, for which different RoBs can be selected. For instance, the `B` response is very small and the cost of reordering it is quite low, which might not be true for the `R` responses.

### Routing

Another task of the NI is also to create the header of the flit which contains all the information required to route a packet from source to destination. To do this, the NI needs to translate the request address to a destination ID, which can be done in two different ways:

* Address Offset: The NI simply uses a fixed offset into the request address to determine the destination ID. For instance, assuming an node ID width of 3, and an address offset of 8, the address `0x0f00` would be translated to node ID `0x7`. This is the simplest way to route packets, but it is also the least flexible. For instance, if not all of the endpoints have the same address range size, a lot of address space might be wasted. For simpler systems, this might however be a good choice. The Address Offset method can be enabled by setting the `RouteCfg.IdAddrOffset`, respectively `RouteCfg.XYAddrOffsetX` and `RouteCfg.XYAddrOffsetX` in case of `XYRouting`.

* Address Map: The other alternative is to use an address map to translate the request address to a node ID. This is usually in the form of a global System Address Map (SAM), which consists of a list of address ranges and the corresponding node IDs. To configure this, the `RouteCfg.UseIdTable` needs to be set and the System Address Map can be passed to the network interface with the `Sam` parameter (which also requires setting the `RouteCfg.NumSamRules` parameter).

Source-based routing is handled a bit different, since the route instead of the destination ID needs to be included in the header. Calculating the route is done in two steps 1) the destination ID is computed the same way as for the node ID based routing and 2) the destination ID is used as an index into a routing table to determine the route. The routing table is passed to the network interface over the `route_table_i` port (which requires setting the `RouteCfg.NumRoutes` parameter).

### AXI Transaction ID handling

### Configuration
* spill registers
