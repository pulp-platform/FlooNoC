# Channels

Now that we established flits -- the smallest unit of data that is sent -- we can discuss how a flit is sent from one node to another. As we have explained in the [flits](flits.md) section, there usually exist multiple types of flits, which differ in the payload they carry. For instance, the payload can be an AXI request, an AXI response, or any other data that needs to be sent from one node to another. For multiple reasons, it makes sense to send these different types of flits over different "channels", which we will discuss in this section.

## Why use multiple channels?

Channels are a way to separate different types of flits. For instance, one channel can be used to send AXI requests, another channel can be used to send AXI responses, and a third channel can be used to send other types of data. This separation has multiple advantages:

1. **Message-Level deadlocks**: If all flits are sent over a single channel, it could happen that message-level deadlocks are introduced. For instance, if node A sends a request to node B, and node B sends a request to node A, both nodes both nodes might need to wait for their response before accepting a new request, which can lead to a deadlock. By separating the request and response channel, we can ensure forward progress.

1. **Latency**: Different types of flits might have different priorities. For instance, some messages are very latency-sensitive (e.g. synchronization messages), while others are much more latency-tolerant (e.g. bulk data transfers). By separating the channels, we can ensure that the congestion can be kept low on the latency-sensitive channel, which in turn reduces the latency of these messages.

1. **Bandwidth**: Different types of flits might have different bandwidth requirements. For instance, the data widths of AXI can reach up to 1024 bit, and AXI additionally supports burst transfers. Using wide links is the natural way to increase the bandwidth of the channel. However, smaller flits like AXI write responses are only a fraction of the link width and would waste bandwidth if sent over a wide link.

## Virtual vs. Physical channels

## _FlooNoC_ channels

### `req` channel

### `rsp` channel

### `wide`

## AXI Channel mapping

## Links
