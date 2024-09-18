# Channels

Now that we established flits -- the smallest unit of data that is sent -- we can discuss how a flit is sent from one node to another. As we have explained in the [flits](flits.md) section, there usually exist multiple types of flits, which differ in the payload they carry. For instance, the payload can be an AXI request, an AXI response, or any other data that needs to be sent from one node to another. For multiple reasons, it makes sense to send these different types of flits over different "channels", which we will discuss in this section.

## Why use multiple channels?

Channels are a way to separate different types of flits. For instance, one channel can be used to send AXI requests, another channel can be used to send AXI responses, and a third channel can be used to send other types of data. This separation has multiple advantages:

1. **Message-Level deadlocks**: If all flits are sent over a single channel, it could happen that message-level deadlocks are introduced. For instance, if node A sends a request to node B, and node B sends a request to node A, both nodes both nodes might need to wait for their response before accepting a new request, which can lead to a deadlock. By separating the request and response channel, we can ensure forward progress.

1. **Latency**: Different types of flits might have different priorities. For instance, some messages are very latency-sensitive (e.g. synchronization messages), while others are much more latency-tolerant (e.g. bulk data transfers). By separating the channels, we can ensure that the congestion can be kept low on the latency-sensitive channel, which in turn reduces the latency of these messages.

1. **Bandwidth**: Different types of flits might have different bandwidth requirements. For instance, the data widths of AXI can reach up to 1024 bit, and AXI additionally supports burst transfers. Using wide links is the natural way to increase the bandwidth of the channel. However, smaller flits like AXI write responses are only a fraction of the link width and would waste bandwidth if sent over a wide link.

## Virtual vs. Physical channels

There are essentially two different ways how to implement multiple channels:

1. **Virtual channels**: Virtual channels are a way to multiplex multiple channels over a single physical channel. Virtual channel have the advantage that the physical channel can be used more efficiently, as it can be shared between multiple virtual channels. Moreover, message-level deadlocks can be prevented with virtual channels, as messages from different channels can be interleaved, resp. they can overtake each other. This is possible, since on the RX side of a virtual channel, every channel has its own buffers. So even if for instance the buffer for requests is full, responses can still be received. While virtual channels have its advantages, they also have some disadvantages. For instance, virtual channels require additional logic to multiplex and demultiplex the channels, which increases the complexity of the design. Furthermore, multiplexing onto a single physical channel limits the throughput of the channel.

1. **Physical channels**: Physical channels on the other hand are _real_ physical channels in hardware. Effectively, physical channels result in multiple separate networks used to send different types of messages throught the network. The main advantage of physical channels is the throughpt of the channel, since it is not shared with other channels. Also, routers for physical channels can be streamlined, since they don't require multiplexing of virtual channels. One disadvantage of physical channels is that they require more routing resources, as each physical channel is implemented as a separate network.

One of the main design principles of _FlooNoC_ is to use multiple physical channels instead of virtual channels. While the main drawback of physical channels is the increased routing resources, modern technologies come to rescue here. For instance, modern technologies usually can feature up to 20 metal layers and have routing resources of >10000 wires/mm that can be exploited to implement multiple physical channels. Not all of it is avaliable for routing of course, since some routing resources are used for cell connectivity and power distribution. However, the routing resources tend not to be the bottleneck in the design, especially not global wires on higher metal layers of the chip, which are primarly used for the routing of the physical links.

!!! tip "Wires are cheap now"

    A very good source on this topic, which has also greatly influenced the use of physical channels during the development of _FlooNoC_ is the NOCS keynote  [Reflections on 21 Years of NoCS](https://www.youtube.com/watch?v=Nk3oQm9NxcY) from Bill Dally, one of the pioneers in early NoC research.

## _FlooNoC_ channels

In _FlooNoC_, we use multiple physical channels to separate different types of traffic. The most basic form of _FlooNoC_ is to use two channels `req` and `rsp`, to send all request resp. responses. However, traffic in an SoC can be quite diverse, and comes with different requirements. For instance, synchronization messages are usually very small in the order of a few bytes, but are very latency-sensitive. On the other hand, bulk data transfers can be very large, but are usually more tolerant to latency, since they can be issued as multiple outstanding transactions. In some systems, this is the reason why mulitple AXI interfaces are used. A narrow one for configuration and synchronization messages and a wider one for bulk data transfers. In that case, _FlooNoC_ also featuers a `wide` channel to provide high bandwidth for bulk data transfers.

## Channel Mapping

### Single-AXI to `req`, `rsp` mapping

If only a single AXI interface is used (e.g. with 32-bit address width and 64-bit data width), the AXI channels are mapped to the _FlooNoC_ channels as follows:

| | `req` | `rsp` | primary payload |
| ----------------- | ---- | ---- | --- |
| `Aw`              | :material-check: | - | `addr` (32-bit) |
| `Aw`              | :material-check: | - | `addr` (32-bit) |
| `W`               | :material-check: | - | `w_data` (64-bit) |
| `R`               | - | :material-check: | `r_data` (64-bit) |
| `B`               | - | :material-check: | `b_rsp` (2-bit) |

The mapping is quite straightforward. Requests from AXI manager are sent over the `req` channel, while responses from AXI subordinates are sent over the `rsp` channel. Message-level deadlock are also avoided this way, since requests and responses are sent over different channels.

## Narrow-Wide AXI to `req`, `rsp`, `wide` mapping

In case two AXI interfaces are used, a narrow (e.g. 64-bit) and a wide one (e.g. 512-bit), the AXI channels are mapped to the _FlooNoC_ channels as follows:

| | `req` | `rsp` | `wide` | primary payload |
| ----------------- | ---- | ---- | ---- | --- |
| `NarrowAw`       | :material-check: | - | - | `addr` (32-bit) |
| `NarrowAr`       | :material-check: | - | - | `addr` (32-bit) |
| `NarrowW`        | :material-check: | - | - | `w_data` (64-bit) |
| `NarrowR`        | - | :material-check: | - | `r_data` (64-bit) |
| `NarrowB`        | - | :material-check: | - | `b_rsp` (2-bit) |
| `WideAw`         | - | - | :material-check: | `addr` (32-bit) |
| `WideAr`         | :material-check: | - | - | `addr` (32-bit) |
| `WideW`          | - | - | :material-check: | `w_data` (512-bit) |
| `WideR`          | - | - | :material-check: | `r_data` (512-bit) |
| `WideB`          | - | :material-check: | -  | `b_rsp` (2-bit) |

In this case, the narrow AXI to `req`, `rsp` mapping is the same as in the single-AXI case. However, the wide AXI interface mapping is a different and requires some explanation. Unsurprisingly, the wide data channels `WideR` and `WideW` are mapped to the `wide` channel to make use of its high bandwidth. The AXI read request `WideAr` and the write response `WideB` are mapped to the `req` and `rsp` channel, respectively. Those are smaller messages and would underutilize the `wide` channel. The outlier here is the AXI write requests `WideAw`, which is mapped to the `wide` channel, eventhough it is a small message. The reason for this is related to the ordering of AXI transactions.

??? info "AXI ordering for the curious"

      AXI supports out-of-order transactions by specifying transaction IDs (`txnID`). Transactions with the same `txnID` need to be ordered with respect to each other i.e. they cannot overtake each other. Transactions with different `txnID` however are free to do so. The `txnID` is specified in the initial requests and the corresponding read and write response also carries the same `txnID`. However, the write data is a bit different in this regard. The write data `W` does not feature any `txnID` and needs to be sent (and eventually arrive at the AXI subordinate) in the same order as the write requests `Aw`. This also needs to be guaranteed in systems with multiple AXI managers that send write requests to the same AXI subordinate. If the `Aw` and `W` are sent over different channels, it might be that the order of them is not preserved since those differnent channels might have different congestion levels. To avoid this, the `WideAw` and `WideW` are sent over the same channel, which is the `wide` channel in this case. Furthermore, it also needs to be guaranteed that `WideW` payloads from different AXI requesters are not interleaved in the network, since they cannot be distinguished when arriving at the destination (which would also very likely require large reorder buffers). The non-interleaving needs to be guaranteed by the routers as well, which will be discussed later in the [routers](routers.md) section.


_FlooNoC_ uses `unions` to represent the different types of flits that are sent over the same physical channel. For instance, the `req` channel for a single-AXI configuration is defined as follows:

```verilog
typedef union packed {
  floo_aw_flit_t axi_aw;
  floo_w_flit_t axi_w;
  floo_ar_flit_t axi_ar;
  floo_generic_flit_t generic;
} floo_req_chan_t;
```

A `union` essentially allows to represent multiple types of data in the same number of bits. This is also why `rsvd` bits are used in the flits, to ensure that the flits sent over a channel all have the same size. The `generic` is not meant to represent a flit with an actual payload, but can be used to decode the type of flit from its header.

!!! example "SystemVerilog Macros"
    Similar to the flits, _FlooNoC_ provides System Verilog macros in `typedef.svh` to generate the channel types such as `FLOO_TYPEDEF_AXI_CHAN_ALL` for a single-AXI configuration and `FLOO_TYPEDEF_AXI_CHAN_ALL` for a narrow-wide AXI configuration.


## Links
