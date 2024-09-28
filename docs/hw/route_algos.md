# Routing Algorithms

One of the main design principles of _FlooNoC_ is that it is flexible and can support multiple routing algorithms as well as arbitrary topologies. Currently, _FlooNoC_ supports the following routing algorithms:

1. **Dimension-ordered Routing (DOR)**: Also known as XY-Routing and arguably the most popular routingn algorithm used in 2D mesh networks, due to its simple implementation and guarantee of deadlock freedom.

1. **Source-based routing**: A routing algorithm where the source specifies the entire route to the destination.

1. **Table-based routing**: A routing algorithm where the selection of port is based on a table that is provided to the router.

All of those routing algorithms are static respectively deterministic. While dynanmic routing algorithms might feature better performance since it can adapt to changing network conditions, they are also more complex to implement and might introduce deadlocks. Furthermore, _FlooNoC_ uses the deterministic routing assumption of the network to guarante the correct ordering of AXI transactions. For instance, _FlooNoC_ relies on the fact that flits from the same source and channel to the same destination remain ordered, which is not given in dynamic routing algorithms.

## Dimension-ordered (DOR)

Dimension-ordered routing is a simple routing algorithm that routes flits based on XY-coordinates, which is why it is commonly used in 2D mesh networks. In dimension ordered routing, a flit is always routed in one dimension and then in the other. Since this routing cannot introduce any cycles, it is deadlock-free by design. The implementation of DOR is also very simple, as it only requires the current and destination coordinates of the flit. Each router knows its own XY coordinates and compares them to the destination coordinates of the flit. The routing algorithm then is the following:

$$
Port = \begin{cases}
East & id_{dst, x} > id_{router, x} \\
West & id_{dst, x} < id_{router, x} \\
North & id_{dst, x} = id_{router, x} \land id_{dst, y} > id_{router, y} \\
South & id_{dst, x} = id_{router, x} \land id_{dst, y} < id_{router, y} \\
Eject & id_{dst, x} = id_{router, x} \land id_{dst, y} = id_{router, y}
\end{cases}
$$

Meaning, the flits is routed to either the east or west until it reaches the correct X-coordinate, after which it is routed to the north or south until. If both coordinates match, the flit is ejected from the network i.e. it is sent to (one of the) local port(s) of the router.

### Advantages

The DOR routing algorithm is very simple but effective and results in very low complexity in the hardware. Furthermore, it is deadlock-free by design since it cannot introduce any cycles. Also, XY-routing allows for some optimization in the router design. Since a flit is always routed first in X and then in Y, some connections in the router are illegal and can be disabled to reduce the number of connections in the router. For instance, the connection from north to east or west is not possible as this would imply that the flit was routed in the Y-dimension before the X-dimension.

### Disadvantages

The main disadvantage of DOR routing is that it only works in 2D meshes. Also, there are some corner cases where DOR routing can create problems. For instance, if nodes are attached to the boundary of the mesh, a flit entering from the north boundary cannot reach the east boundary, since it would have to change X and Y direction multiple times.

## Source-based Routing

Source-based routing is another simple routing algorithm where the entire route to the destination is specified by node which injects the flit into the network. The route is encoded in the header of the flit as an array of ports that each router should take. The size of the route encoding depends on the diameter of the network (the maximum number of hops) as well as the router radix (number of router ports). For instance, a route might be encoded like this in a 4x4 2D mesh network:

```verilog
  route_t route = '{3'b0, 3'b1, 3'b2, 3'b3, 3'b4, 3'b5, 3'b6};
```

A router usually has 5 ports (4 for the cardinal directions and one local port), which can be encoded in 3 bits. Further, the maximum number of hops in a router is 7 (including the routers where the flit is injected and ejected), which results in a route encoding of 21 bits. This route encoding is part of the flit header and is checked by each router.

??? example "Flit header differences"
    The header of a flit is different for source-based routing compared to the other routing algorithms. Instead of encoding the destination id (`dst_id`) as a node ID (of type `id_t`), the destination id is encoded as a route (`route_t`). The source id (`src_id`) is still encoded as a node ID, since the source node generally does not know the route back to itself from the destination. Instead it provides the `src_id`, which can be translated back to a route by the destination node.


The implementation of this routing algorithm is also very simple, since every router _consumes_ a port from the route encoding, which means it simply shifts the route encoding by the number of bits that is required to encode the number of possible ports. This way, a router does not neet to be aware of how many hops a flit has already passed, since it can simply look at the first bits of the route encoding to determine the next port.

### Advantages

The main advantage of source-based routing is that it is very flexible and can be used in arbitrary topologies, that go beyond 2D meshes. The routes can also be optimized for instance to reduce congestion or to minimize the number of hops. Theoretically, source-based routing can also be dynamic, since the source can change the route encoding based on the network conditions. However, as mentioned before, _FlooNoC_ currently does not support dynamic routing algorithms.

### Disadvantages

The main disadvantage of source-based routing is that the bits required for encoding the route grows with the network diameter and at some point it becomes infeasible to encode the route in the flit header. Also, source-based routing is not inherently deadlock-free, if the routes are not carefully chosen. Lastly, the route encodings need to be provided to the source respectively the network interface, which can become quite large, since every destination requires its own route encoding.

## Table-based Routing

Table-based routing shifts the routing computation to the routers themselves. Each router has a table that specifies the output port for each destination. Instead of using actual tables, it is also possible to use address decoders which can reduce the number of entries in the table, since it allows to specify a range of destinations that are routed to the same port. An instance of such a routing table could look like the following:

```verilog
  localparam router_rule_t [NumRules-1:0] RouterTable = '{
      '{idx: 1, start_addr: 0, end_addr: 2}, // -> port 1 for destination 0, 1
      '{idx: 2, start_addr: 2, end_addr: 3}, // -> port 2 for destination 2
      '{idx: 3, start_addr: 3, end_addr: 10} // -> port 3 for destination 3 to 9
  };
```

where `idx` is the port number and `start_addr` and `end_addr` is the range of destination node IDs that are routed to the port.

### Advantages
Similar to source-routing, table-based routing can be used for any kind of topology and the routes respectively the routing tables can be optimized to avoid congestion etc., Also, table-based routing can be dynamic, since the routing tables could be updated dynamically (which is not supported by _FlooNoC_).

### Disadvantages
Table-based routing has a similar problem as source-based routing, since the router tables grow with the number of destinations. Also, table-based routing is not inherently deadlock-free, if the routing tables are not carefully chosen. Lastly, the routing tables need to be provided to the routers, which can become quite large, since every destination requires its own routing table.
