# Flits

We start with the _flits_, also called flow control units, which is the smallest unit of data that is sent from node to another (e.g. from router to router, of network interface to router). Flits consists of two types of data:

1. **Routing information**: Also called the header of the flit, this data is used by the routers to route the flit through the network. The header contains information such as the destination address, the source address, the flit type, etc.

1. **Payload**: This is the actual data that is being sent from one node to another. Router do not look at the payload, they just forward it to the next hop.

In traditional NoCs, the links have a fixed width (e.g. 32-bit). Usually, the payload and the information required for routing far exceeds this width. Therefore, the payload is split into multiple data flits and a header flit which encodes the routing information. Based on this information, routers in the network then know how to route the following data flits to the destination.

In modern NoCs, this way of serializing payloads over the network is not very efficient anymore. With higher bandwidth requirements of the endpoints, the serialization becomes more and more a bottleneck, since the frequency of the links is limited. Further, serialization causes additional latency which is undesirable. Lastly, the overhead of the header flits is not negligible, especially when the payload is small.

Therefore, In _FlooNoC_ and modern NoCs in general[^1], another approach is taken, which differs in two ways:

[^1]: The [AMBA CHI](https://developer.arm.com/documentation/ihi0050/latest/) protocol also encodes the entire payload (cachelines in this case) in a single flit including all the information required for routing.

1. **Flit width**: The width of the flits is not fixed anymore. Instead, the flits can be as wide as the payload to send the payload in a single cycle resp. in a single flit.

1. **Parallel header**: Instead of sending the header before the payload, the header is sent in parallel to the payload. This way, the link utilization is not degraded by header flits.

Below, we will discuss the header and the payload in more detail.

## Header

In _FlooNoC_ the header consists of the following fields:

| Field | Type | Required by | Description |
| ----------- | --------------- | ---------- | --------------------- |
| `dst_id` | `dst_t` or `route_t` | Router | The destination ID of the flit. In the case of source-based routing, it encodes the entire route from source to destination. |
| `src_id` | `dst_t` | Chimney | The source ID of the flit. Used by the Chimney to set the `dst_id` for the response |
| `last` | `logic` | Router | Can be used by the Chimneys that a burst of flits is not interleaved with other flits from other endpoints. If not set the router performs wormhole routing i.e. it locks the direction until flit with the `last` bit set has been sent. |
| `axi_ch` | `axi_ch_e`[^2] | Chimney | Used by the Chimney to encode the type of packet e.g. which AXI channel |
| `rob_req` | `logic` | Chimney | Flag to signal that the flit might need to be reordered in the Chimney |
| `rob_idx` | `rob_idx_t` | Chimney | The index into the reorder buffer of the Chimney |
| `atop` | `logic` | Chimney | Flag to signal that the flit is an ATOP flit and can bypass the reodering logic. |

!!! info "Additional fields"

    Additional fields can be added to the header if needed. The routers just ignore those fields and forward them to the next router/Chimney.

!!! example "SystemVerilog macros"

    _FlooNoC_ provides System Verilog macros in `typedef.svh` to generate the header fields such as `FLOO_TYPEDEF_HDR_T`.

[^2]: The type is arbitrary and depends on the type of Chimney used but it is usually an `enum`. For instance, the single-AXI chimney encodes only 5 channels in `axi_ch_e`, while the narrow-wide AXI chimney encodes 10 channels in `nw_ch_e`. This can also be extended.

## Payload

The payload itself can be any data that needs to be sent from one node to another. The payload is not interpreted by the routers, they just forward it to the next hop. The payload can be of any width. Usually, the payload consists of an AXI request or response of one of the 5 channels.

## Types of flits

The entire flit is constructed by concatenating the header and the payload. One can define many types of flits i.e. one for every payload. The only requirement is that the flit includes the following fields:

| Field | Type | Description |
| ----------- | --------------- | --------------------- |
| `hdr` | `hdr_t` | The header of the flit, which is identical across the whole network |
| `payload` | `payload_t`[^3] | The payload of the flit, which can be of any width |
| `rsvd` | `logic[RsvdBits-1:0]` | Optional padding bits if the flit is smaller than the link width |

[^3]: The payload type can be anything. For instance, sending an AXI AW is done by defining a `axi_aw_chan_t` struct for the payload type.

!!! info "Additional fields"

    Again, additional fields can be added if needed. The only requirement is that the width of the flit matches exactly the width of the link.

!!! example "SystemVerilog macros"

    _FlooNoC_ provides System Verilog macros in `typedef.svh` to generate the flits such as `FLOO_TYPEDEF_FLIT_T` for flits with the `rsvd` field and generic flits `FLOO_TYPEDEF_GENERIC_FLIT_T` without a `rsvd` field.
