#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import pathlib
from importlib.resources import files, as_file
from typing import Optional, List, ClassVar
from typing_extensions import Annotated

import networkx as nx
import matplotlib.pyplot as plt
from mako.lookup import Template
from pydantic import BaseModel, ConfigDict, StringConstraints, field_validator, model_validator

from floogen.model.routing import Routing, RouteAlgo, RouteMapRule, RouteRule, RouteMap, RouteTable
from floogen.model.routing import Coord, SimpleId, AddrRange, XYDirections
from floogen.model.graph import Graph
from floogen.model.endpoint import EndpointDesc, Endpoint
from floogen.model.router import RouterDesc, NarrowWideRouter, AxiRouter
from floogen.model.connection import ConnectionDesc
from floogen.model.link import NarrowWideLink, NarrowWideVCLink, AxiLink
from floogen.model.network_interface import NarrowWideAxiNI, AxiNI
from floogen.model.protocol import AXI4, AXI4Bus
from floogen.utils import clog2, sv_enum_typedef, sv_param_decl
import floogen.templates


class Network(BaseModel):  # pylint: disable=too-many-public-methods
    """
    Network class to describe a network with routers and endpoints.
    """

    model_config = ConfigDict(arbitrary_types_allowed=True, extra="forbid")

    with as_file(files(floogen.templates).joinpath("floo_top_noc.sv.mako")) as _tpl_path:
        noc_tpl: ClassVar = Template(filename=str(_tpl_path))
    with as_file(files(floogen.templates).joinpath("floo_top_noc_pkg.sv.mako")) as _tpl_path:
        pkg_tpl: ClassVar = Template(filename=str(_tpl_path))
    with as_file(files(floogen.templates).joinpath("floo_addrmap.rdl.mako")) as _tpl_path:
        rdl_tpl: ClassVar = Template(filename=str(_tpl_path))

    name: str
    description: Optional[str]
    network_type: Annotated[str, StringConstraints(pattern=r"axi|narrow-wide")]
    protocols: List[AXI4]
    endpoints: List[EndpointDesc]
    routers: List[RouterDesc]
    connections: List[ConnectionDesc]
    graph: Optional[Graph] = None
    routing: Routing

    def create_network(self):
        """Initialize the network as a graph."""
        self.graph = Graph()
        self.create_routers()
        self.create_endpoints()
        self.create_connections()

    def compile_network(self):
        """Compile the network."""
        self.compile_ids()
        self.compile_links()
        self.compile_endpoints()
        self.compile_nis()
        self.compile_routers()

    @field_validator("endpoints")
    @classmethod
    def validate_endpoints(cls, endpoints):
        """Check that endpoint names are unique."""
        names = set()
        for ep in endpoints:
            if ep.name in names:
                raise ValueError("Endpoint names must be unique")
            names.add(ep.name)
        return endpoints

    @field_validator("routers")
    @classmethod
    def validate_routers(cls, routers):
        """Check that router ids are unique."""
        names = set()
        for rt in routers:
            if rt.name in names:
                raise ValueError("router names must be unique")
            names.add(rt.name)
        return routers

    @model_validator(mode="after")
    def validate_protocols(self):
        """Check that names are unique and parameters are compatible."""
        # Check that address width is unique among all protocols
        if len(set(prot.addr_width for prot in self.protocols)) != 1:
            raise ValueError("All protocols must have the same address width")
        if self.network_type == "narrow-wide":
            # Check that `narrow` and `wide` protocols have the same data width
            if len(set(prot.data_width for prot in self.protocols if prot.type == "narrow")) != 1:
                raise ValueError("All `narrow` protocols must have the same data width")
            if len(set(prot.data_width for prot in self.protocols if prot.type == "wide")) != 1:
                raise ValueError("All `wide` protocols must have the same data width")
            # Check that `narrow` and `wide` protocols have the same user width
            if len(set(prot.user_width for prot in self.protocols if prot.type == "narrow")) != 1:
                raise ValueError("All `narrow` protocols must have the same user width")
            if len(set(prot.user_width for prot in self.protocols if prot.type == "wide")) != 1:
                raise ValueError("All `wide` protocols must have the same user width")
            # Check that `type` is defined when using `narrow-wide` network
            if any(prot.type not in ["narrow", "wide"] for prot in self.protocols) and \
                "narrow-wide" in self.network_type:
                raise ValueError("Protocols must define `type` for `narrow-wide` networks")
        else:
            # Check that data width is the same among all protocols
            if len(set(prot.data_width for prot in self.protocols)) != 1:
                raise ValueError("All protocols must have the same data width")
            # Check that user width is the same among all protocols
            if len(set(prot.user_width for prot in self.protocols)) != 1:
                raise ValueError("All protocols must have the same user width")
        return self

    @model_validator(mode="after")
    def set_addr_width(self):
        """Set the address width of the network."""
        self.routing.addr_width = self.protocols[0].addr_width
        return self

    def create_routers(self):
        """Create the routers in the network."""

        for rt_desc in self.routers:
            # handle single router
            match (rt_desc.array, rt_desc.tree):
                # Single router case
                case (None, None):
                    self.graph.add_node(rt_desc.name, obj=rt_desc, type="router")
                # 2D mesh case
                case ((m, n), None):
                    self.graph.add_nodes_as_array(
                        name=rt_desc.name,
                        array=(m, n),
                        node_type="router",
                        edge_type="link",
                        node_obj=rt_desc,
                        connect=rt_desc.auto_connect,
                    )
                # tree case
                case (None, tree_list):
                    self.graph.add_nodes_as_tree(
                        parent=rt_desc.name,
                        tree=tree_list,
                        node_type="router",
                        edge_type="link",
                        node_obj=rt_desc,
                        connect=rt_desc.auto_connect,
                    )
                # Invalid case
                case (_, _):
                    raise ValueError("Invalid router description")

    def create_endpoints(self):
        """Create the endpoints in the network."""

        for ep_desc in self.endpoints:
            # handle single endpoint
            match ep_desc.array:
                # Single endpoint case
                case None:
                    self.graph.add_node(ep_desc.name, obj=ep_desc, type="endpoint")
                    self.graph.add_node(f"{ep_desc.name}_ni", obj=ep_desc, type="network_interface")
                    if ep_desc.is_sbr():
                        self.graph.add_edge(f"{ep_desc.name}_ni", ep_desc.name, type="protocol")
                    if ep_desc.is_mgr():
                        self.graph.add_edge(ep_desc.name, f"{ep_desc.name}_ni", type="protocol")
                # 1D array case
                case (n,):
                    self.graph.add_nodes_as_array(
                        name=ep_desc.name,
                        array=(n,),
                        node_type="endpoint",
                        node_obj=ep_desc,
                        connect=False,
                    )
                    self.graph.add_nodes_as_array(
                        name=f"{ep_desc.name}_ni",
                        array=(n,),
                        node_type="network_interface",
                        node_obj=ep_desc,
                        connect=False,
                    )
                    ep_nodes = self.graph.get_nodes_from_range(ep_desc.name, [(0, n - 1)])
                    ni_nodes = self.graph.get_nodes_from_range(f"{ep_desc.name}_ni", [(0, n - 1)])
                    if ep_desc.is_sbr():
                        for ep_node, ni_node in zip(ep_nodes, ni_nodes):
                            self.graph.add_edge(ni_node, ep_node, type="protocol")
                    if ep_desc.is_mgr():
                        for ep_node, ni_node in zip(ep_nodes, ni_nodes):
                            self.graph.add_edge(ep_node, ni_node, type="protocol")
                # 2D array case
                case (m, n):
                    self.graph.add_nodes_as_array(
                        name=ep_desc.name,
                        array=(m, n),
                        node_type="endpoint",
                        node_obj=ep_desc,
                        connect=False,
                    )
                    self.graph.add_nodes_as_array(
                        name=f"{ep_desc.name}_ni",
                        array=(m, n),
                        node_type="network_interface",
                        node_obj=ep_desc,
                        connect=False,
                    )
                    ep_nodes = self.graph.get_nodes_from_range(
                        ep_desc.name, [(0, m - 1), (0, n - 1)]
                    )
                    ni_nodes = self.graph.get_nodes_from_range(
                        f"{ep_desc.name}_ni", [(0, m - 1), (0, n - 1)]
                    )
                    if ep_desc.is_sbr():
                        for ep_node, ni_node in zip(ep_nodes, ni_nodes):
                            self.graph.add_edge(ni_node, ep_node, type="protocol")
                    if ep_desc.is_mgr():
                        for ep_node, ni_node in zip(ep_nodes, ni_nodes):
                            self.graph.add_edge(ep_node, ni_node, type="protocol")
                # Invalid case
                case _:
                    raise ValueError("Invalid endpoint description")

    def create_connections(self):
        """Initialize the connections in the network."""
        for con in self.connections:
            # Get the source nodes
            match (con.src_idx, con.src_range, con.src_lvl):
                # Explicit node case
                case (None, None, None):
                    srcs = [con.src]
                # Get node from index
                case (idx, None, None):
                    srcs = self.graph.get_nodes_from_idx(con.src, idx)
                # Get node from range
                case (None, rng, None):
                    srcs = self.graph.get_nodes_from_range(con.src, rng)
                # Get node from level
                case (None, None, lvl):
                    srcs = self.graph.get_nodes_from_lvl(con.src, lvl)
                # Invalid case
                case (_, _, _):
                    raise ValueError("src_idx, src_range and src_lvl are mutually exclusive")

            # Get the destination nodes
            match (con.dst_idx, con.dst_range, con.dst_lvl):
                # Explicit node case
                case (None, None, None):
                    dsts = [con.dst]
                # Get node from index
                case (idx, None, None):
                    dsts = self.graph.get_nodes_from_idx(con.dst, idx)
                # Get node from range
                case (None, rng, None):
                    dsts = self.graph.get_nodes_from_range(con.dst, rng)
                # Get node from level
                case (None, None, lvl):
                    dsts = self.graph.get_nodes_from_lvl(con.dst, lvl)
                # Invalid case
                case (_, _, _):
                    raise ValueError("dst_idx, dst_range and dst_lvl are mutually exclusive")

            def get_ni_of_ep(ep):
                """Get the network interface of an endpoint."""
                if self.graph.is_ep_node(ep):
                    return self.graph.get_node_obj(ep).get_ni_name(ep)
                return ep

            srcs = [get_ni_of_ep(src) for src in srcs]
            dsts = [get_ni_of_ep(dst) for dst in dsts]

            # Add edges between the nodes
            match (len(srcs), len(dsts), con.allow_multi):
                # Normal case where srcs and dsts have the same length
                case (n_srcs, n_dsts, _) if n_srcs == n_dsts:
                    pass
                # Multi connection case where srcs is dividable by dsts
                case (n_srcs, n_dsts, True) if n_srcs % n_dsts == 0 and n_srcs > n_dsts:
                    num_multi_con = n_srcs // n_dsts
                    # Duplicate dsts
                    dsts = [dst for dst in dsts for _ in range(num_multi_con)]
                # Multi connection case where dsts is dividable by srcs
                case (n_srcs, n_dsts, True) if n_dsts % n_srcs == 0 and n_dsts > n_srcs:
                    num_multi_con = n_dsts // n_srcs
                    # Duplicate srcs
                    srcs = [src for src in srcs for _ in range(num_multi_con)]
                case (_, _, False):
                    raise ValueError(
                        "srcs and dsts must have the same length \
                        or `allow_multi` must be `True` and lengths \
                        must be dividable by each other"
                    )

            # Add edges between the nodes
            for src, dst in zip(srcs, dsts):
                self.graph.add_edge(src, dst, type="link",
                                    src_dir=con.src_dir, dst_dir=con.dst_dir)
                if con.bidirectional:
                    self.graph.add_edge(dst, src, type="link",
                                        src_dir=con.dst_dir, dst_dir=con.src_dir)

    def compile_ids(self):
        """Infer the id type from the network."""
        # Add XY coordinates to the nodes
        match self.routing.route_algo:
            case RouteAlgo.XY:
                # 1st stage: Get all router nodes
                for node_name, node in self.graph.get_rt_nodes(with_name=True):
                    x, y = self.graph.get_node_arr_idx(node_name)
                    node_xy_id = Coord(x=x, y=y)
                    if node.xy_id_offset is not None:
                        node_xy_id += node.xy_id_offset
                    self.graph.nodes[node_name]["id"] = node_xy_id
                for node_name, node in self.graph.get_ni_nodes(with_name=True):
                    # Search for a neighbor node *with* an array index
                    for neighbor in self.graph.neighbors(node_name):
                        if self.graph.nodes[neighbor].get("id") is not None:
                            # If it has a directed edge, we can derive the coordinate from there
                            edge = self.graph.edges[(node_name, neighbor)]
                            if edge["dst_dir"] is not None:
                                node_xy_id = self.graph.nodes[neighbor][
                                    "id"
                                ] + XYDirections.to_coords(edge["dst_dir"])
                                break
                            edge = self.graph.edges[(neighbor, node_name)]
                            if edge["src_dir"] is not None:
                                node_xy_id = self.graph.nodes[neighbor][
                                    "id"
                                ] + XYDirections.to_coords(edge["src_dir"])
                                break
                    assert node_xy_id is not None
                    if node.xy_id_offset is not None:
                        node_xy_id += node.xy_id_offset
                    self.graph.nodes[node_name]["id"] = node_xy_id
            case RouteAlgo.ID | RouteAlgo.SRC:
                for ep_name, ep in self.graph.get_ep_nodes(with_name=True):
                    node_id = SimpleId(id=self.graph.create_unique_ep_id(ep_name))
                    ni_name = ep.get_ni_name(ep_name)
                    self.graph.nodes[ep_name]["id"] = node_id
                    self.graph.nodes[ni_name]["id"] = node_id

        # Add unique IDs (uid's) to the nodes
        for ep_name, ep in self.graph.get_ep_nodes(with_name=True):
            node_id = SimpleId(id=self.graph.create_unique_ep_id(ep_name))
            ni_name = ep.get_ni_name(ep_name)
            self.graph.nodes[ep_name]["uid"] = node_id
            self.graph.nodes[ni_name]["uid"] = node_id

    def compile_links(self):
        """Infer the link type from the network."""
        for edge in self.graph.get_link_edges(with_obj=False, with_name=True):
            # Check if link is bidirectional
            is_bidirectional = self.graph.has_edge(edge[1], edge[0])
            link = {
                "source": edge[0],
                "dest": edge[1],
                "source_type": self.graph.nodes[edge[0]]["type"],
                "dest_type": self.graph.nodes[edge[1]]["type"],
                "is_bidirectional": is_bidirectional,
            }
            match (self.network_type, self.routing.num_vc_id_bits):
                case ("axi", 0):
                    self.graph.set_edge_obj(edge, AxiLink(**link))
                case ("narrow-wide", 0):
                    self.graph.set_edge_obj(edge, NarrowWideLink(**link))
                case ("narrow-wide", _):
                    self.graph.set_edge_obj(edge, NarrowWideVCLink(**link))
                case _:
                    raise NotImplementedError(
                        f"Network type {self.network_type} with VC routers is not supported yet"
                    )

    def compile_routers(self): # pylint: disable=too-many-branches, too-many-locals
        """Infer the router type from the network."""
        for rt_name, rt_obj in self.graph.get_rt_nodes(with_name=True):
            dir_in_edges = self.graph.get_edges_to(rt_name,
                filters=[lambda e: self.graph.edges[e]["dst_dir"] is not None], with_name=True)
            dir_out_edges = self.graph.get_edges_from(rt_name,
                filters=[lambda e: self.graph.edges[e]["src_dir"] is not None], with_name=True)
            non_dir_in_edges = self.graph.get_edges_to(rt_name,
                filters=[lambda e: self.graph.edges[e]["dst_dir"] is None])
            non_dir_out_edges = self.graph.get_edges_from(rt_name,
                filters=[lambda e: self.graph.edges[e]["src_dir"] is None])
            if rt_obj.degree is not None:
                num_edges = rt_obj.degree
            else:
                num_edges = len(dir_in_edges) + len(non_dir_in_edges)

            incoming, outgoing = [None] * num_edges, [None] * num_edges
            # First, add the directed edges to in_dir_edges and out_dir_edges edges
            for edge, edge_obj in dir_in_edges:
                in_dir = self.graph.edges[edge]["dst_dir"]
                if incoming[in_dir] is not None:
                    raise ValueError(
                        f"Trying to set incoming link #{in_dir} of {rt_name} " +
                        f"to ({edge[0]} -> {edge[1]}), already taken by " +
                        f"({incoming[in_dir].source} -> {incoming[in_dir].dest})")
                incoming[in_dir] = edge_obj
            for edge, edge_obj in dir_out_edges:
                out_dir = self.graph.edges[edge]["src_dir"]
                if outgoing[out_dir] is not None:
                    raise ValueError(
                        f"Trying to set outgoing link #{out_dir} of {rt_name} " +
                        f"to ({edge[0]} -> {edge[1]}), already taken by " +
                        f"({outgoing[out_dir].source} -> {outgoing[out_dir].dest})")
                outgoing[out_dir] = edge_obj
            # Second, add the undirected edges to in_dir_edges and out_dir_edges edges
            for i, in_edge in enumerate(incoming):
                if non_dir_in_edges == []:
                    break
                if in_edge is None:
                    incoming[i] = non_dir_in_edges.pop(0)
            for i, out_edge in enumerate(outgoing):
                if non_dir_out_edges == []:
                    break
                if out_edge is None:
                    outgoing[i] = non_dir_out_edges.pop(0)

            assert non_dir_in_edges == []
            assert non_dir_out_edges == []

            router_dict = {
                "name": rt_name,
                "incoming": incoming,
                "outgoing": outgoing,
                "degree": num_edges,
                "route_algo": self.routing.route_algo,
            }
            if self.routing.route_algo == RouteAlgo.XY:
                router_dict["id"] = self.graph.get_node_id(rt_name)
            match self.network_type:
                case "axi":
                    self.graph.set_node_obj(rt_name, AxiRouter(**router_dict))
                case "narrow-wide":
                    self.graph.set_node_obj(rt_name, NarrowWideRouter(**router_dict))

    def compile_endpoints(self):
        """Infer the endpoint type from the network."""
        for ep_name, ep in self.graph.get_ep_nodes(with_name=True):
            mgr_ports = []
            sbr_ports = []
            if ep.is_mgr():
                for i in ep.mgr_port_protocol:
                    prot = {}
                    protocol = next(p for p in self.protocols if p.name == i)
                    if protocol.direction is None:
                        protocol.direction = "input"
                    elif protocol.direction != "input":
                        raise ValueError("Protocol cannot be used for both manager and subordinate")
                    prot["base_name"] = f"{ep.name}_{protocol.name}"
                    prot["source"] = ep_name
                    prot["dest"] = ep.get_ni_name(ep_name)
                    if ep.array is not None:
                        prot["arr_dim"] = ep.array
                        prot["arr_idx"] = self.graph.get_node_arr_idx(ep_name)
                    protocol = AXI4Bus(**prot, **protocol.__dict__)
                    mgr_ports.append(protocol)
                self.graph.set_edge_obj((prot["source"], prot["dest"]), mgr_ports)
            if ep.is_sbr():
                for i in ep.sbr_port_protocol:
                    prot = {}
                    protocol = next(p for p in self.protocols if p.name == i)
                    if protocol.direction is None:
                        protocol.direction = "output"
                    elif protocol.direction != "output":
                        raise ValueError("Protocol cannot be used for both manager and subordinate")
                    prot["base_name"] = f"{ep.name}_{protocol.name}"
                    prot["source"] = ep.get_ni_name(ep_name)
                    prot["dest"] = ep_name
                    if ep.array is not None:
                        prot["arr_dim"] = ep.array
                        prot["arr_idx"] = self.graph.get_node_arr_idx(ep_name)
                    protocol = AXI4Bus(**prot, **protocol.__dict__)
                    sbr_ports.append(protocol)
                self.graph.set_edge_obj((prot["source"], prot["dest"]), sbr_ports)
            # Add endpoint object to the node
            self.graph.set_node_obj(
                ep_name, Endpoint(mgr_ports=mgr_ports, sbr_ports=sbr_ports, **ep.__dict__)
            )

    def compile_nis(self):
        """Compile the endpoints in the network."""

        for ni_name, ep_desc in self.graph.get_ni_nodes(with_name=True):
            ni_dict = {
                "name": f"{ni_name}",
                "endpoint": ep_desc,
                "routing": self.routing,
                "addr_range": [rng.model_copy() for rng in ep_desc.addr_range],
                "id": self.graph.get_node_id(node_name=ni_name).model_copy(),
                "uid": self.graph.get_node_uid(node_name=ni_name).model_copy(),
            }

            assert ep_desc

            match ep_desc.array:
                # Single endpoint case
                case None:
                    pass

                # 1D array case
                case (m,):
                    node_idx = self.graph.get_node_arr_idx(ni_name)[0]
                    ni_dict["arr_idx"] = SimpleId(id=node_idx)
                    if ep_desc.is_sbr():
                        ni_dict["addr_range"] = [
                            rng.model_copy().set_arr(node_idx, m) for rng in ep_desc.addr_range
                        ]

                # 2D array case
                case (m, n):
                    x, y = self.graph.get_node_arr_idx(ni_name)
                    idx = x * n + y
                    ni_dict["arr_idx"] = Coord(x=x, y=y)
                    if ep_desc.is_sbr():
                        ni_dict["addr_range"] = [
                            rng.model_copy().set_arr(idx, m*n) for rng in ep_desc.addr_range
                        ]
                # Invalid case
                case _:
                    raise ValueError("Invalid endpoint array description")

            sbr_prot_edges = self.graph.get_edges_from(ni_name, filters=[self.graph.is_prot_edge])
            mgr_prot_edges = self.graph.get_edges_to(ni_name, filters=[self.graph.is_prot_edge])
            for protocols in sbr_prot_edges:
                for prot in protocols:
                    match (self.network_type, prot.type):
                        case ("axi", _):
                            ni_dict["sbr_port"] = prot
                        case ("narrow-wide", "narrow"):
                            ni_dict["sbr_narrow_port"] = prot
                        case ("narrow-wide", "wide"):
                            ni_dict["sbr_wide_port"] = prot

            for protocols in mgr_prot_edges:
                for prot in protocols:
                    match (self.network_type, prot.type):
                        case ("axi", _):
                            ni_dict["mgr_port"] = prot
                        case ("narrow-wide", "narrow"):
                            ni_dict["mgr_narrow_port"] = prot
                        case ("narrow-wide", "wide"):
                            ni_dict["mgr_wide_port"] = prot

            ni_dict["mgr_link"] = self.graph.get_edges_from(
                ni_name, filters=[self.graph.is_link_edge]
            )[0]
            ni_dict["sbr_link"] = self.graph.get_edges_to(
                ni_name, filters=[self.graph.is_link_edge]
            )[0]
            match self.network_type:
                case "axi":
                    self.graph.set_node_obj(ni_name, AxiNI(**ni_dict))
                case "narrow-wide":
                    self.graph.set_node_obj(ni_name, NarrowWideAxiNI(**ni_dict))

    def gen_routing_info(self):
        """Wrapper function to generate all the routing info for the network,
        for a specific routing algorithm."""
        self.routing.num_endpoints = len(self.graph.get_ni_nodes())
        if self.routing.num_endpoints == 0:
            raise ValueError(
                "No endpoints found in the network. Use the `only_pkg` flag for package generation."
            )
        self.routing.num_id_bits = clog2(len(self.graph.get_ni_nodes()))
        match self.routing.route_algo:
            case RouteAlgo.XY:
                for info, value in self.gen_xy_routing_info().items():
                    setattr(self.routing, info, value)
            case RouteAlgo.ID:
                self.gen_router_tables()
            case RouteAlgo.SRC:
                self.gen_routes()
            case _:
                raise NotImplementedError(
                    f"Routing algorithm {self.routing.route_algo} is not supported yet"
                )
        self.routing.sam = self.gen_sam()
        # Provide the routing info to the network interfaces
        for ni in self.graph.get_ni_nodes():
            ni.routing = self.routing

    def gen_router_tables(self):
        """Generate the routing table for the network."""
        for rt in self.graph.get_rt_nodes():
            routing_table = []
            ni_sbr_nodes = [ni for ni in self.graph.get_ni_nodes() if ni.is_sbr()]
            for ni in ni_sbr_nodes:
                shortest_path = nx.shortest_path(self.graph, rt.name, ni.name)
                out_edge = (rt.name, shortest_path[1])
                out_link = self.graph.get_edge_obj(out_edge)
                out_idx = rt.outgoing.index(out_link)
                dest = SimpleId(id=out_idx)
                addr_range = AddrRange(start=ni.id.id, size=1)
                routing_table.append(RouteMapRule(dest=dest, addr_range=addr_range, desc=ni.name))

            # Add routing table to the router
            rt.table = RouteMap(name=rt.name + "_map", rules=routing_table)
            rt.table.trim()

    def gen_xy_routing_info(self):
        """Generate the XY routing info for the network."""
        ni_nodes = self.graph.get_ni_nodes()
        ni_sbr_nodes = [ni for ni in ni_nodes if ni.is_sbr()]
        min_x = min(ni.id.x for ni in ni_nodes)
        min_y = min(ni.id.y for ni in ni_nodes)
        max_x = max(ni.id.x for ni in ni_nodes)
        max_y = max(ni.id.y for ni in ni_nodes)
        max_address = max(max(rng.end for rng in ni.addr_range) for ni in ni_sbr_nodes)
        xy_routing_info = {}
        xy_routing_info["num_x_bits"] = clog2(max_x - min_x + 1)
        xy_routing_info["num_y_bits"] = clog2(max_y - min_y + 1)
        xy_routing_info["addr_offset_bits"] = clog2(max_address)
        xy_routing_info["xy_id_offset"] = Coord(x=min_x, y=min_y)
        return xy_routing_info

    def gen_routes(self):
        """Generates the routes for source-based routing."""
        self.routing.num_route_bits = 0
        for ni_src in self.graph.get_ni_nodes():
            routes = []
            for ni_dst in self.graph.get_ni_nodes():
                # Skip if source and destination are the same
                # and for manager-manager and subordinate-subordinate
                # connections
                if (
                    ni_src.name == ni_dst.name
                    or (ni_src.is_only_mgr() and ni_dst.is_only_mgr())
                    or (ni_src.is_only_sbr() and ni_dst.is_only_sbr())
                ):
                    routes.append(RouteRule(route=None, id=ni_dst.id, desc=f"-> {ni_dst.name}"))
                    continue
                route = nx.shortest_path(self.graph, ni_src.name, ni_dst.name)
                max_route_bits = 0
                port_lst = []
                for i in range(1, len(route) - 1):
                    out_edge = (route[i], route[i + 1])
                    out_link = self.graph.get_edge_obj(out_edge)
                    rt = self.graph.get_node_obj(route[i])
                    out_port = rt.outgoing.index(out_link)
                    num_port_bits = clog2(len(rt.outgoing))
                    port_lst.append((out_port, num_port_bits))
                    max_route_bits += num_port_bits
                rule = RouteRule(route=port_lst, id=ni_dst.id, desc=f"-> {ni_dst.name}")
                routes.append(rule)
                self.routing.num_route_bits = max(self.routing.num_route_bits, max_route_bits)
            ni_src.table = RouteTable(name=ni_src.name + "_table", routes=routes)

    def gen_sam(self):
        """Generate the system address map, which is used by the network interfaces
        to determine the destination of a packet based on the address."""
        addr_table = []
        ni_sbr_nodes = reversed([ni for ni in self.graph.get_ni_nodes() if ni.is_sbr()])
        for ni in ni_sbr_nodes:
            dest = ni.id
            if self.routing.xy_id_offset is not None:
                dest -= self.routing.xy_id_offset
            for _, addr_range in enumerate(ni.addr_range):
                rule_name = ni.endpoint.name
                if addr_range.desc is not None:
                    rule_name += f"_{addr_range.desc}"
                addr_rule = RouteMapRule(dest=dest, addr_range=addr_range, desc=rule_name)
                addr_table.append(addr_rule)
        return RouteMap(name="sam", rules=addr_table)

    def render_ports(self, pkg_name=""):
        """Render the ports in the generated code."""
        ports, declared_ports = [], []
        for ep in self.graph.get_ep_nodes():
            if ep.name in declared_ports:
                continue
            ports += ep.render_ports(pkg_name=pkg_name)
            declared_ports.append(ep.name)
        port_string = ",\n  ".join(ports) + "\n"
        return port_string

    def render_link_typedefs(self):
        """Render the protocol configuration structs."""
        string = ""
        if self.network_type == "narrow-wide":
            narrow_in_prot = next((prot for prot in self.protocols
                if prot.type == "narrow" and prot.direction == "input"), None)
            narrow_out_prot = next((prot for prot in self.protocols
                if prot.type == "narrow" and prot.direction == "output"), None)
            wide_in_prot = next((prot for prot in self.protocols
                if prot.type == "wide" and prot.direction == "input"), None)
            wide_out_prot = next((prot for prot in self.protocols
                if prot.type == "wide" and prot.direction == "output"), None)
            string += AXI4.render_cfg("AxiCfgN", narrow_in_prot, narrow_out_prot)
            string += AXI4.render_cfg("AxiCfgW", wide_in_prot, wide_out_prot)

            string += NarrowWideLink.render_typedefs(
                narrow_in_prot.type_name(), wide_in_prot.type_name(), "AxiCfgN", "AxiCfgW"
            )
        else:
            in_prot = next((prot for prot in self.protocols if prot.direction == "input"), None)
            out_prot = next((prot for prot in self.protocols if prot.direction == "output"), None)
            string += AXI4.render_cfg("AxiCfg", in_prot, out_prot)
            string += AxiLink.render_typedefs(in_prot.type_name(), "AxiCfg")
        return string

    def render_prots(self):
        """Render the protocols in the generated code."""
        string = ""
        for prot_list in self.graph.get_prot_edges():
            for prot in prot_list:
                string += prot.declare()
        return string

    def render_links(self):
        """Render the links in the generated code."""
        string = ""
        for link in self.graph.get_link_edges():
            string += link.declare()
        return string

    def render_routers(self):
        """Render the routers in the generated code."""
        string = ""
        for rt in self.graph.get_rt_nodes():
            string += rt.render(network=self)
        return string

    def render_ni_tables(self):
        """Render the network interfaces tables in the generated code."""
        string = ""
        sorted_ni_list = sorted(
            self.graph.get_ni_nodes(),
            key=lambda ni: self.graph.get_node_id(node_obj=ni),
            reverse=True
        )
        for ni in sorted_ni_list:
            string += ni.table.render(
                num_route_bits=self.routing.num_route_bits, no_decl=True)
            string += ",\n"
        string = "'{\n" + string[:-2] + "}\n"
        return sv_param_decl(
            name="RoutingTables",
            value=string,
            dtype="route_t",
            array_size=["NumEndpoints-1", "NumEndpoints-1"],
        )

    def render_nis(self):
        """Render the network interfaces in the generated code."""
        string = ""
        for ni in self.graph.get_ni_nodes():
            string += ni.render(noc=self)
        return string

    def render_ep_enum(self):
        """Render the endpoint enum in the generated code."""
        fields_dict = {}
        for ni in self.graph.get_ni_nodes():
            name = ni.render_enum_name()
            fields_dict[name] = self.graph.get_node_uid(node_obj=ni).id
        fields_dict = dict(sorted(fields_dict.items(), key=lambda item: item[1]))
        fields_dict["num_endpoints"] = len(fields_dict)
        return sv_enum_typedef(name="ep_id_e", fields_dict=fields_dict)

    def render_sam_idx_enum(self):
        """Render the system address map index enum in the generated code."""
        fields_dict = {}
        for i, desc in enumerate(reversed(self.routing.sam.rules)):
            fields_dict[desc.desc] = i
        return sv_enum_typedef(name="sam_idx_e", fields_dict=fields_dict)

    def render_network(self):
        """Render the network in the generated code."""
        return self.noc_tpl.render(noc=self)

    def render_package(self):
        """Render the network package in the generated code."""
        return self.pkg_tpl.render(noc=self)

    def render_rdl(self, rdl_as_mem=False):
        """Render the network RDL in the generated code."""
        return self.rdl_tpl.render(noc=self, rdl_as_mem=rdl_as_mem)

    def visualize(self, savefig=True, filename: pathlib.Path = "network.png"):
        """Visualize the network graph."""
        ni_nodes = self.graph.get_ni_nodes(with_obj=False, with_name=True)
        router_nodes = self.graph.get_rt_nodes(with_obj=False, with_name=True)
        filtered_graph = self.graph.subgraph(ni_nodes + router_nodes)
        nx.draw(filtered_graph, with_labels=True)
        if savefig:
            plt.savefig(filename)
        else:
            plt.show()
