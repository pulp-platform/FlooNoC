#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import pytest
from floogen.model.graph import Graph


@pytest.fixture(name="graph")
def setup_graph():
    """Return a Graph object."""
    return Graph()


def test_add_node(graph):
    """Add a router node to the graph."""
    graph.add_node("A", type="router")
    assert graph.has_node("A")
    assert graph.get_node_obj("A") is None


def test_add_edge(graph):
    """Add a one-directinal link edge to the graph."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge("A", "B", type="link")
    assert graph.has_edge("A", "B")
    assert graph.get_edge_obj(("A", "B")) is None


def test_add_edge_bidir(graph):
    """Add a bidirectional link edge to the graph."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge_bidir("A", "B", type="link")
    assert graph.has_edge("A", "B")
    assert graph.has_edge("B", "A")


def test_get_node_obj(graph):
    """Add a router node to the graph and get its object."""
    graph.add_node("A", type="router", obj="Router A")
    assert graph.get_node_obj("A") == "Router A"


def test_set_node_obj(graph):
    """Add a router node to the graph and set its object."""
    graph.add_node("A", type="router")
    graph.set_node_obj("A", "Router A")
    assert graph.get_node_obj("A") == "Router A"


def test_get_node_arr_idx(graph):
    """Add a router node to the graph and get its array index."""
    graph.add_node("A", type="router", arr_idx=(0, 1))
    assert graph.get_node_arr_idx("A") == (0, 1)


def test_get_node_lvl(graph):
    """Add a router node to the graph and get its level."""
    graph.add_node("A", type="router", lvl=2)
    assert graph.get_node_lvl("A") == 2


def test_get_edge_obj(graph):
    """Add a one-directional link edge to the graph and get its object."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge("A", "B", type="link", obj="Link AB")
    assert graph.get_edge_obj(("A", "B")) == "Link AB"


def test_set_edge_obj(graph):
    """Add a one-directional link edge to the graph and set its object."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge("A", "B", type="link")
    graph.set_edge_obj(("A", "B"), "Link AB")
    assert graph.get_edge_obj(("A", "B")) == "Link AB"


def test_is_rt_node(graph):
    """Add a router node to the graph and check if it is a router node."""
    graph.add_node("A", type="router")
    assert graph.is_rt_node("A")


def test_is_ep_node(graph):
    """Add an endpoint node to the graph and check if it is an endpoint node."""
    graph.add_node("A", type="endpoint")
    assert graph.is_ep_node("A")


def test_is_ni_node(graph):
    """Add a network interface node to the graph and check if it is a network interface node."""
    graph.add_node("A", type="network_interface")
    assert graph.is_ni_node("A")


def test_is_prot_edge(graph):
    """Add a protocol edge to the graph and check if it is a protocol edge."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge("A", "B", type="protocol")
    assert graph.is_prot_edge(("A", "B"))


def test_is_link_edge(graph):
    """Add a link edge to the graph and check if it is a link edge."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge("A", "B", type="link")
    assert graph.is_link_edge(("A", "B"))


def test_get_nodes(graph):
    """Add a router node and an endpoint node to the graph and get all nodes."""
    graph.add_node("A", type="router", obj="Router A")
    graph.add_node("B", type="endpoint", obj="Endpoint B")
    nodes = graph.get_nodes(with_name=True)
    assert nodes == [("A", "Router A"), ("B", "Endpoint B")]


def test_get_edges(graph):
    """Add a one-directional link edge to the graph and get all edges."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_edge("A", "B", type="link", obj="Link AB")
    edges = graph.get_edges(with_name=True)
    assert edges == [(("A", "B"), "Link AB")]


def test_get_edges_from(graph):
    """Get all outgoing edges."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_node("C", type="endpoint")
    graph.add_node("D", type="router")
    graph.add_edge("A", "B", type="link")
    graph.add_edge("A", "C", type="link")
    graph.add_edge("D", "A", type="link")
    edges = graph.get_edges_from("A", with_name=True)
    assert edges == [(("A", "B"), None), (("A", "C"), None)]


def test_get_edges_to(graph):
    """Get all incoming edges."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_node("C", type="endpoint")
    graph.add_edge("A", "B", type="link")
    graph.add_edge("C", "A", type="link")
    edges = graph.get_edges_to("A", with_name=True)
    assert edges == [(("C", "A"), None)]


def test_get_edges_of(graph):
    """Get all edges of a node."""
    graph.add_node("A", type="router")
    graph.add_node("B", type="endpoint")
    graph.add_node("C", type="endpoint")
    graph.add_node("D", type="router")
    graph.add_edge("A", "B", type="link")
    graph.add_edge("C", "A", type="link")
    graph.add_edge("D", "A", type="link")
    edges = graph.get_edges_of("A", with_name=True)
    assert edges == [(("A", "B"), None), (("C", "A"), None), (("D", "A"), None)]


def test_get_ni_nodes(graph):
    """Test getting all network interfaces"""
    graph.add_node("A", type="network_interface", obj="NI A")
    graph.add_node("B", type="router", obj="Router B")
    graph.add_node("C", type="network_interface", obj="NI C")
    ni_nodes = graph.get_ni_nodes(with_name=True)
    assert ni_nodes == [("A", "NI A"), ("C", "NI C")]


def test_get_rt_nodes(graph):
    """Test getting all routers"""
    graph.add_node("A", type="router", obj="Router A")
    graph.add_node("B", type="endpoint", obj="Endpoint B")
    graph.add_node("C", type="router", obj="Router C")
    rt_nodes = graph.get_rt_nodes(with_name=True)
    assert rt_nodes == [("A", "Router A"), ("C", "Router C")]


def test_get_ep_nodes(graph):
    """Test getting all endpoints"""
    graph.add_node("A", type="router", obj="Router A")
    graph.add_node("B", type="endpoint", obj="Endpoint B")
    graph.add_node("C", type="endpoint", obj="Endpoint C")
    ep_nodes = graph.get_ep_nodes(with_name=True)
    assert ep_nodes == [("B", "Endpoint B"), ("C", "Endpoint C")]


def test_get_prot_edges(graph):
    """Test getting all protocol edges"""
    graph.add_node("A", type="endpoint")
    graph.add_node("B", type="network_interface")
    graph.add_node("C", type="router")
    graph.add_edge("A", "B", type="protocol", obj="Protocol AB")
    graph.add_edge("B", "C", type="link", obj="Link BC")
    prot_edges = graph.get_prot_edges(with_name=True)
    assert prot_edges == [(("A", "B"), "Protocol AB")]


def test_get_link_edges(graph):
    """Test getting all link edges"""
    graph.add_node("A", type="endpoint")
    graph.add_node("B", type="network_interface")
    graph.add_node("C", type="router")
    graph.add_edge("A", "B", type="protocol", obj="Protocol AB")
    graph.add_edge("B", "C", type="link", obj="Link BC")
    link_edges = graph.get_link_edges(with_name=True)
    assert link_edges == [(("B", "C"), "Link BC")]


def test_get_nodes_from_range1(graph):
    """Test getting all nodes from a range"""
    graph.add_node("A_0_0", type="router")
    graph.add_node("A_0_1", type="router")
    graph.add_node("A_1_0", type="router")
    graph.add_node("A_1_1", type="router")
    nodes = graph.get_nodes_from_range("A", [(0, 1), (0, 1)])
    assert nodes == ["A_0_0", "A_0_1", "A_1_0", "A_1_1"]


def test_get_nodes_from_range2(graph):
    """Test getting all nodes from a range"""
    graph.add_node("A_0_0", type="router")
    graph.add_node("A_0_1", type="router")
    graph.add_node("A_1_0", type="router")
    graph.add_node("A_1_1", type="router")
    nodes = graph.get_nodes_from_range("A", [(0, 1), (0, 0)])
    assert nodes == ["A_0_0", "A_1_0"]


def test_get_nodes_from_range3(graph):
    """Test getting all nodes from a range"""
    graph.add_node("A_0", type="router")
    graph.add_node("A_1", type="router")
    graph.add_node("A_2", type="router")
    graph.add_node("A_3", type="router")
    nodes = graph.get_nodes_from_range("A", [(0, 3)])
    assert nodes == ["A_0", "A_1", "A_2", "A_3"]

def test_get_nodes_from_range4(graph):
    """Test getting all nodes from a range"""
    graph.add_node("A_0", type="router")
    graph.add_node("A_1", type="router")
    graph.add_node("A_2", type="router")
    graph.add_node("A_3", type="router")
    nodes = graph.get_nodes_from_range("A", [(2, 1)])
    assert nodes == ["A_2", "A_1"]

def test_get_nodes_from_range_fail1(graph):
    """Test getting all nodes from a range"""
    graph.add_node("A_0", type="router")
    graph.add_node("A_1", type="router")
    graph.add_node("A_2", type="router")
    graph.add_node("A_3", type="router")
    with pytest.raises(ValueError):
        graph.get_nodes_from_range("A", [(0, 1), (0, 1)])

def test_get_nodes_from_range_fail2(graph):
    """Test getting all nodes from a range"""
    graph.add_node("A_0", type="router")
    graph.add_node("A_1", type="router")
    graph.add_node("A_2", type="router")
    graph.add_node("A_3", type="router")
    with pytest.raises(ValueError):
        graph.get_nodes_from_range("A", [(0, 99)])


def test_get_nodes_from_idx(graph):
    """Test getting all nodes from an index"""
    graph.add_node("A_0_0", type="router")
    graph.add_node("A_0_1", type="router")
    graph.add_node("A_1_0", type="router")
    graph.add_node("A_1_1", type="router")
    nodes = graph.get_nodes_from_idx("A", [1, 0])
    assert nodes == ["A_1_0"]


def test_get_nodes_from_lvl(graph):
    """Test getting all nodes from a level"""
    graph.add_node("A", type="router", lvl=0)
    graph.add_node("A_1", type="router", lvl=1)
    graph.add_node("A_2", type="router", lvl=1)
    nodes = graph.get_nodes_from_lvl("A", 1)
    assert nodes == ["A_1", "A_2"]


def test_add_nodes_as_tree(graph):
    """Test adding nodes as a tree"""
    graph.add_nodes_as_tree("A", [1, 2, 2], "router", "link")

    def assert_node(node, lvl):
        assert graph.has_node(node)
        assert graph.is_rt_node(node)
        assert graph.get_node_lvl(node) == lvl

    def assert_edge(edge):
        assert graph.has_edge(*edge)
        assert graph.is_link_edge(edge)
        assert graph.has_edge(*edge[::-1])
        assert graph.is_link_edge(edge[::-1])

    assert_node("A_0", 0)
    assert_node("A_0_0", 1)
    assert_node("A_0_1", 1)
    assert_node("A_0_0_0", 2)
    assert_node("A_0_0_1", 2)
    assert_node("A_0_1_0", 2)
    assert_node("A_0_1_1", 2)
    assert_edge(("A_0", "A_0_0"))
    assert_edge(("A_0", "A_0_1"))
    assert_edge(("A_0_0", "A_0_0_0"))
    assert_edge(("A_0_0", "A_0_0_1"))
    assert_edge(("A_0_1", "A_0_1_0"))
    assert_edge(("A_0_1", "A_0_1_1"))


def test_add_nodes_as_array1(graph):
    """Test adding nodes as an array"""

    def assert_node(node, idx):
        assert graph.has_node(node)
        assert graph.is_rt_node(node)
        assert graph.get_node_arr_idx(node) == idx
    def assert_edge(edge):
        assert graph.has_edge(*edge)
        assert graph.is_link_edge(edge)
        assert graph.has_edge(*edge[::-1])
        assert graph.is_link_edge(edge[::-1])

    graph.add_nodes_as_array("A", [2], "router", edge_type="link")
    assert_node("A_0", (0,))
    assert_node("A_1", (1,))
    assert_edge(("A_0", "A_1"))


def test_add_nodes_as_array2(graph):
    """Test adding nodes as an array"""

    def assert_node(node, idx):
        assert graph.has_node(node)
        assert graph.is_rt_node(node)
        assert graph.get_node_arr_idx(node) == idx

    def assert_edge(edge):
        assert graph.has_edge(*edge)
        assert graph.is_link_edge(edge)

    graph.add_nodes_as_array("A", [2, 2], "router", edge_type="link")
    assert_node("A_0_0", (0, 0))
    assert_node("A_0_1", (0, 1))
    assert_node("A_1_0", (1, 0))
    assert_node("A_1_1", (1, 1))
    assert_edge(("A_0_0", "A_0_1"))
    assert_edge(("A_0_0", "A_1_0"))
    assert_edge(("A_0_1", "A_1_1"))
    assert_edge(("A_1_0", "A_1_1"))


def test_create_unique_ep_id(graph):
    """Test creating a unique endpoint id"""
    graph.add_node("A", type="endpoint")
    graph.add_node("A_0", type="endpoint")
    graph.add_node("B", type="endpoint")
    graph.add_node("C", type="endpoint")
    graph.add_node("R", type="router")
    graph.add_node("S", type="endpoint")
    assert graph.create_unique_ep_id("A") == 0
    assert graph.create_unique_ep_id("A_0") == 1
    assert graph.create_unique_ep_id("B") == 2
    assert graph.create_unique_ep_id("C") == 3
    assert graph.create_unique_ep_id("S") == 4
    with pytest.raises(ValueError):
        graph.create_unique_ep_id("R")


def test_get_node_id(graph):
    """Test getting the id of a node"""
    graph.add_node("A", type="router", id=1)
    assert graph.get_node_id("A") == 1
