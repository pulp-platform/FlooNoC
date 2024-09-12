# Link-Level transport

## Flits

We start with the _flits_, also called flow control units, which is the smallest unit of data that is sent from node to another (e.g. from router to router, of network interface to router). Flits consists of two types of data:

1. **Routing information**: Also called the header of the flit, this data is used by the routers to route the flit through the network. The header contains information such as the destination address, the source address, the flit type, etc.

1. **Payload**: This is the actual data that is being sent from one node to another. Router do not look at the payload, they just forward it to the next hop.

In traditional NoCs, the links have a fixed width (e.g. 32-bit). Usually, the payload and the information required for routing far exceeds this width. Therefore, the payload is split into multiple data flits and a header flit which encodes the routing information. Based on this information, routers in the network then know how to route the following data flits to the destination.

In modern NoCs, this way of serializing payloads over the network is not very efficient anymore. With higher bandwidth requirements of the endpoints, the serialization becomes more and more a bottleneck, since the frequency of the links is limited. Further, serialization causes additional latency which is undesirable. Lastly, the overhead of the header flits is not negligible, especially when the payload is small.

Therefore, In _FlooNoC_ and modern NoCs in general, another approach is taken, which differs in two ways:

1. **Flit width**: The width of the flits is not fixed anymore. Instead, the flits can be as wide as the payload to send the payload in a single cycle resp. in a single flit.

1. **Parallel header**: Instead of sending the header before the payload, the header is sent in parallel to the payload. This way, the link utilization is not degraded by header flits.

!!! info "AMBA CHI"

    _FlooNoC_ is not the first NoC to use this approach. For example, the [AMBA CHI](https://developer.arm.com/documentation/ihi0050/latest/) protocol also encodes the entire payload (cachelines in this case) in a single flit including all the information required for routing.

!!! tip "Wires are cheap now"

    You might wonder why this was not used in the first place. The reason is that wires were not as cheap as they are today. Modern technologies now have >10 metal layers which can fit >10000 wires/mm. A very good source on this topic, which has also influenced the design of _FlooNoC_ is the NOCS keynote  [Reflections on 21 Years of NoCS](https://www.youtube.com/watch?v=Nk3oQm9NxcY) from Bill Dally, one of the pioneers in early NoC research.
