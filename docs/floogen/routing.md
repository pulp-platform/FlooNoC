# Routing

The second aspect of the network is how the routing is performed in _FlooNoC_, which is where _FlooGen_ comes into play. A lot of of the routing information is quite cumbersome to define and error-prone to do by hand. _FlooGen_ allows you to define the routing in a high-level way, and it will generate the low-level routing information for you. The basic information you need to provide is:

```yaml
routing:
  route_algo: "XY"
  use_id_table: true
```

::: floogen.model.routing.RoutingDesc
    options:
      show_root_heading: false
      show_root_toc_entry: false
      show_bases: false
      members: false
      inherited_members: false
      show_source: false
      show_signature: false

## Reference

Beyond what you configure above, _FlooGen_ derives a great deal more from the elaborated network: the system address map (`sam`), the coordinate and route widths, the endpoint count, and so on. Those live on [`Routing`][floogen.model.routing.Routing], which extends `RoutingDesc` and is built by `Network.gen_routing_info()`. They are not configuration and cannot be set in a configuration file.

::: floogen.model.routing.Routing
    options:
      show_root_heading: false
      show_root_toc_entry: false
      show_bases: false
      members: false
      inherited_members: false
      show_source: false
      show_signature: false

The full API reference of the routing model, including methods and other routing-related classes (e.g., `RouteMap`, `RouteTable`), can be found in the [Routing Reference](reference/routing.md#floogen.model.routing).
