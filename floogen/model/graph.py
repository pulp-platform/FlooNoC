#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import List, Tuple

import networkx as nx

from floogen.model.routing import XYDirections


class Graph(nx.DiGraph):  # pylint: disable=too-many-public-methods
    """Network graph class."""

    def __init__(self):
        """Initialize the graph."""
        super().__init__()
        self._node_idx = 0

    def add_node(self, node_for_adding: str, **attr):
        """Add a node to the graph."""
        if self.has_node(node_for_adding):
            raise ValueError(f"Node {node_for_adding} already exists in the graph.")
        assert "type" in attr, "Node type not provided"
        if "obj" not in attr:
            attr["obj"] = None
        super().add_node(node_for_adding, **attr)

    def add_edge(self, u_of_edge: str, v_of_edge: str, **attr):
        """Add an edge to the graph."""
        if self.has_edge(u_of_edge, v_of_edge):
            raise ValueError(f"Edge ({u_of_edge}, {v_of_edge}) already exists in the graph.")
        assert "type" in attr, "Edge type not provided"
        if "obj" not in attr:
            attr["obj"] = None
        super().add_edge(u_of_edge, v_of_edge, **attr)

    def add_edge_bidir(self, u_of_edge: str, v_of_edge: str, **attr):
        """Add a bidirectional edge to the graph."""
        self.add_edge(u_of_edge, v_of_edge, **attr)
        self.add_edge(v_of_edge, u_of_edge, **attr)  # pylint: disable=arguments-out-of-order

    def get_node_obj(self, node):
        """Return the node object."""
        return self.nodes[node]["obj"]

    def set_node_obj(self, node, obj):
        """Set the node object."""
        self.nodes[node]["obj"] = obj

    def get_node_arr_idx(self, node):
        """Return the node array index."""
        return self.nodes[node]["arr_idx"]

    def get_node_lvl(self, node):
        """Return the node level."""
        return self.nodes[node]["lvl"]

    def get_edge_obj(self, edge):
        """Return the edge object."""
        return self.edges[edge]["obj"]

    def set_edge_obj(self, edge, obj):
        """Set the edge object."""
        self.edges[edge]["obj"] = obj

    def is_rt_node(self, node):
        """Return whether the node is a router node."""
        return self.nodes[node]["type"] == "router"

    def is_ep_node(self, node):
        """Return whether the node is an endpoint node."""
        return self.nodes[node]["type"] == "endpoint"

    def is_ni_node(self, node):
        """Return whether the node is an ni node."""
        return self.nodes[node]["type"] == "network_interface"

    def is_prot_edge(self, edge):
        """Return whether the edge is a protocol edge."""
        return self.edges[edge]["type"] == "protocol"

    def is_link_edge(self, edge):
        """Return whether the edge is a link edge."""
        return self.edges[edge]["type"] == "link"

    def get_nodes(self, filters=None, with_name=False):
        """Filter the nodes from the graph."""
        nodes = self.nodes
        if filters is not None:
            for flt in filters:
                nodes = list(filter(flt, nodes))
        if with_name:
            return [(node, self.get_node_obj(node)) for node in nodes]
        return [self.get_node_obj(node) for node in nodes]

    def get_edges(self, filters=None, with_name=False):
        """Filter the edges from the graph."""
        edges = self.edges
        if filters is not None:
            for flt in filters:
                edges = list(filter(flt, edges))
        if with_name:
            return [(edge, self.get_edge_obj(edge)) for edge in edges]
        return [self.get_edge_obj(edge) for edge in edges]

    def get_edges_from(self, node, filters=None, with_name=False):
        """Return the outgoing edges from the node."""
        if filters is None:
            filters = []
        filters = [lambda e: e[0] == node] + filters
        return self.get_edges(filters=filters, with_name=with_name)

    def get_edges_to(self, node, filters=None, with_name=False):
        """Return the incoming edges to the node."""
        if filters is None:
            filters = []
        filters = [lambda e: e[1] == node] + filters
        return self.get_edges(filters=filters, with_name=with_name)

    def get_edges_of(self, node, filters=None, with_name=False):
        """Return the edges of the node."""
        if filters is None:
            filters = []
        filters = [lambda e: node in e] + filters
        return self.get_edges(filters=filters, with_name=with_name)

    def get_ni_nodes(self, with_name=False):
        """Return the ni nodes."""
        return self.get_nodes(filters=[self.is_ni_node], with_name=with_name)

    def get_rt_nodes(self, with_name=False):
        """Return the router nodes."""
        return self.get_nodes(filters=[self.is_rt_node], with_name=with_name)

    def get_ep_nodes(self, with_name=False):
        """Return the endpoint nodes."""
        return self.get_nodes(filters=[self.is_ep_node], with_name=with_name)

    def get_prot_edges(self, with_name=False):
        """Return the protocol edges."""
        return self.get_edges(filters=[self.is_prot_edge], with_name=with_name)

    def get_link_edges(self, with_name=False):
        """Return the link edges."""
        return self.get_edges(filters=[self.is_link_edge], with_name=with_name)

    def get_nodes_from_range(self, node: str, rng: List[Tuple[int]]):
        """Return the nodes from the range."""
        nodes = []
        if len(rng) == 0:
            raise ValueError("Range is empty")
        start, end = rng[0]
        step = 1 if end > start else -1
        for i in range(start, end + step, step):
            if len (rng) == 1:
                node_name = f"{node}_{i}"
                if self.has_node(node_name):
                    nodes.append(node_name)
                else:
                    raise ValueError(f"Node {node_name} does not exist")
            else:
                nodes.extend(self.get_nodes_from_range(f"{node}_{i}", rng[1:]))
        return nodes

    def get_nodes_from_idx(self, node: str, idx: List[int]):
        """Return the nodes from the index."""
        node_name = f"{node}_{'_'.join([str(i) for i in idx])}"
        if self.has_node(node_name):
            return [node_name]
        raise ValueError(f"Node {node_name} does not exist")

    def get_nodes_from_lvl(self, node: str, lvl: int):
        """Return the nodes from the level."""
        nodes = self.get_nodes(
            filters=[lambda n: n.startswith(node), lambda n: self.nodes[n]["lvl"] == lvl],
            with_name=True,
        )
        return [name for name, _ in nodes]

    def add_nodes_as_tree(
        self,
        parent: str,
        tree: List[int],
        node_type: str,
        edge_type: str,
        *,
        lvl: int = 0,
        node_obj=None,
        edge_obj=None,
        connect=True,
    ):  # pylint: disable=too-many-arguments
        """Add nodes as a tree."""
        if lvl == len(tree):
            return
        for i in range(tree[lvl]):
            node = f"{parent}_{i}"
            self.add_node(node, type=node_type, lvl=lvl, obj=node_obj)
            if connect and lvl > 0:
                self.add_edge(
                    parent, node, type=edge_type, obj=edge_obj, src_dir=None, dst_dir=None
                )
                self.add_edge(
                    node, parent, type=edge_type, obj=edge_obj, src_dir=None, dst_dir=None
                )
            self.add_nodes_as_tree(
                node,
                tree,
                node_type,
                edge_type,
                lvl=lvl + 1,
                node_obj=node_obj,
                edge_obj=edge_obj,
                connect=connect,
            )

    def add_nodes_as_array(
        self,
        name: str,
        array: Tuple[int],
        node_type: str,
        *,
        edge_type: str = "",
        node_obj=None,
        edge_obj=None,
        connect=True,
    ):  # pylint: disable=too-many-arguments
        """Add nodes as an array."""
        match array:
            case [n]:
                for i in range(n):
                    node = f"{name}_{i}"
                    self.add_node(node, type=node_type, arr_idx=(i,), obj=node_obj)
                    if i > 0 and connect:
                        self.add_edge(node, f"{name}_{i-1}", type=edge_type, obj=edge_obj)
                        self.add_edge(f"{name}_{i-1}", node, type=edge_type, obj=edge_obj)
            case [n, m]:
                for i in range(n):
                    for j in range(m):
                        node = f"{name}_{i}_{j}"
                        self.add_node(node, type=node_type, arr_idx=(i, j), obj=node_obj)
                        if i > 0 and connect:
                            self.add_edge(
                                node,
                                f"{name}_{i-1}_{j}",
                                type=edge_type,
                                obj=edge_obj,
                                src_dir=XYDirections.WEST.value,
                                dst_dir=XYDirections.EAST.value,
                            )
                            self.add_edge(
                                f"{name}_{i-1}_{j}",
                                node,
                                type=edge_type,
                                obj=edge_obj,
                                src_dir=XYDirections.EAST.value,
                                dst_dir=XYDirections.WEST.value,
                            )
                        if j > 0 and connect:
                            self.add_edge(
                                node,
                                f"{name}_{i}_{j-1}",
                                type=edge_type,
                                obj=edge_obj,
                                src_dir=XYDirections.SOUTH.value,
                                dst_dir=XYDirections.NORTH.value,
                            )
                            self.add_edge(
                                f"{name}_{i}_{j-1}",
                                node,
                                type=edge_type,
                                obj=edge_obj,
                                src_dir=XYDirections.NORTH.value,
                                dst_dir=XYDirections.SOUTH.value,
                            )
            case _:
                raise NotImplementedError(f"Unsupported array {array}")

    def create_unique_ep_id(self, node) -> int:
        """Return the endpoint id."""
        ep_nodes = [name for name, _ in self.get_ep_nodes(with_name=True)]
        return sorted(ep_nodes).index(node)

    def get_node_id(self, node_name=None, node_obj=None):
        """Return the node id."""
        if node_name is not None:
            return self.nodes[node_name]["id"]
        if node_obj is not None:
            return self.nodes[node_obj.name]["id"]
        raise ValueError("Node name or object not provided")

    def get_node_uid(self, node_name=None, node_obj=None):
        """Return the unique node id."""
        if node_name is not None:
            return self.nodes[node_name]["uid"]
        if node_obj is not None:
            return self.nodes[node_obj.name]["uid"]
        raise ValueError("Node name or object not provided")
