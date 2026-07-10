#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import pytest
from floogen.model.routing import AddrRange, RouteMapRule, RouteMap, SimpleId


def test_addr_range_creation1():
    """Test the creation of an AddrRange object."""
    addr_range = AddrRange(start=0, end=50)
    assert addr_range.start == 0
    assert addr_range.end == 50
    assert addr_range.size == 50
    assert addr_range.base is None
    assert addr_range.arr_idx is None
    assert addr_range.arr_dim is None


def test_addr_range_creation2():
    """Test the creation of an AddrRange object."""
    addr_range = AddrRange(start=50, size=100)
    assert addr_range.start == 50
    assert addr_range.end == 150
    assert addr_range.size == 100
    assert addr_range.base is None
    assert addr_range.arr_idx is None


def test_addr_range_creation3():
    """Test the creation of an AddrRange object."""
    addr_range = AddrRange(base=50, size=100, arr_idx=(5,))
    assert addr_range.start == 550
    assert addr_range.end == 650
    assert addr_range.size == 100
    assert addr_range.base == 50
    assert addr_range.arr_idx == (5,)
    assert addr_range.arr_dim is None


def test_addr_range_creation4():
    """Test the creation of an AddrRange object."""
    addr_range = AddrRange(base=50, size=100)
    assert addr_range.start == 50
    assert addr_range.end == 150
    assert addr_range.size == 100
    assert addr_range.base == 50
    assert addr_range.arr_idx is None
    assert addr_range.arr_dim is None


def test_addr_range_arr_idx():
    """Test the arr_idx method of an AddrRange object."""
    addr_range = AddrRange(base=50, size=100)
    addr_range.set_arr((1, ), (5, ))
    assert addr_range.start == 150
    assert addr_range.end == 250
    assert addr_range.size == 100
    assert addr_range.base == 50
    assert addr_range.arr_idx == (1,)
    assert addr_range.arr_dim == (5,)


def test_invalid_addr_range():
    """Test the validation of an AddrRange object."""
    with pytest.raises(ValueError):
        AddrRange(start=100, end=0, size=100)

    with pytest.raises(ValueError):
        AddrRange(start=0, end=100, size=0)

    with pytest.raises(ValueError):
        addr_range = AddrRange(start=0, end=100, size=100)
        addr_range.set_arr(2, 5)


def test_rdl_name_and_rdl_as_mem_mutually_exclusive():
    """Test that setting both rdl_name and rdl_as_mem raises a validation error."""
    with pytest.raises(ValueError):
        AddrRange(start=0, end=0x1000, rdl_name="foo", rdl_as_mem=True)


def test_get_rdl_per_endpoint_as_mem():
    """Test that rdl_as_mem=True in AddrRange enables memory block regardless of global flag."""
    rule = RouteMapRule(
        addr_range=AddrRange(start=0, end=0x1000, rdl_as_mem=True),
        dest=SimpleId(id=1),
    )
    result = rule.get_rdl("inst", rdl_as_mem=False, rdl_memwidth=8)
    assert len(result) == 1
    assert "external mem" in result[0]["rdl_name"]


def test_get_rdl_per_endpoint_opt_out():
    """Test that rdl_as_mem=False excludes the endpoint even when --as-mem is passed."""
    rule = RouteMapRule(
        addr_range=AddrRange(start=0, end=0x1000, rdl_as_mem=False),
        dest=SimpleId(id=1),
    )
    assert rule.get_rdl("inst", rdl_as_mem=True, rdl_memwidth=8) == []


def test_get_rdl_global_fallback():
    """Test that the global --as-mem CLI flag still works when rdl_as_mem is not set."""
    rule = RouteMapRule(
        addr_range=AddrRange(start=0, end=0x1000),
        dest=SimpleId(id=1),
    )
    assert rule.get_rdl("inst", rdl_as_mem=False) == []
    result = rule.get_rdl("inst", rdl_as_mem=True, rdl_memwidth=32)
    assert len(result) == 1
    assert "memwidth = 32" in result[0]["rdl_name"]


def test_get_rdl_rdl_name_takes_priority():
    """Test that rdl_name still takes priority over rdl_as_mem."""
    rule = RouteMapRule(
        addr_range=AddrRange(start=0, end=0x1000, rdl_name="my_block"),
        dest=SimpleId(id=1),
    )
    result = rule.get_rdl("inst", rdl_as_mem=True)
    assert result[0]["rdl_name"] == "my_block"

def test_routing_table_len():
    """Test the length of a RoutingTable object."""
    rule1 = RouteMapRule(addr_range=AddrRange(start=0, end=10), dest=SimpleId(id=1))
    rule2 = RouteMapRule(addr_range=AddrRange(start=11, end=20), dest=SimpleId(id=2))
    routing_table = RouteMap(name="test_map", rules=[rule1, rule2])
    assert len(routing_table) == 2


def test_check_no_overlapping_ranges():
    """Test the check_no_overlapping_ranges method of a RoutingTable object."""
    rule1 = RouteMapRule(addr_range=AddrRange(start=0, end=10), dest=SimpleId(id=1))
    rule2 = RouteMapRule(addr_range=AddrRange(start=5, end=15), dest=SimpleId(id=2))
    with pytest.raises(ValueError):
        RouteMap(name="test_map", rules=[rule1, rule2])


def test_trim():
    """Test the trim method of a RoutingTable object."""
    rule1 = RouteMapRule(addr_range=AddrRange(start=0, end=10), dest=SimpleId(id=1))
    rule2 = RouteMapRule(addr_range=AddrRange(start=10, end=20), dest=SimpleId(id=1))
    rule3 = RouteMapRule(addr_range=AddrRange(start=20, end=30), dest=SimpleId(id=2))
    rule4 = RouteMapRule(addr_range=AddrRange(start=31, end=40), dest=SimpleId(id=2))
    routing_table = RouteMap(name="test_map", rules=[rule1, rule2, rule3, rule4])
    routing_table.trim()
    expected_rules = [
        RouteMapRule(addr_range=AddrRange(start=0, end=20), dest=SimpleId(id=1)),
        RouteMapRule(addr_range=AddrRange(start=20, end=30), dest=SimpleId(id=2)),
        RouteMapRule(addr_range=AddrRange(start=31, end=40), dest=SimpleId(id=2)),
    ]
    assert routing_table.rules == expected_rules


def test_rdl_addrmap_grp_addr_range_scalar_and_list():
    """Test that a scalar or list rdl_addrmap_grp both normalize to a List[str]."""
    ar_scalar = AddrRange(start=0, end=0x1000, rdl_addrmap_grp="32b")
    ar_list = AddrRange(start=0, end=0x1000, rdl_addrmap_grp=["32b", "64b"])
    assert ar_scalar.rdl_addrmap_grp == ["32b"]
    assert ar_list.rdl_addrmap_grp == ["32b", "64b"]


def test_route_map_distinct_groups():
    """Test that distinct_groups() collects the sorted set of groups across all rules."""
    rule1 = RouteMapRule(addr_range=AddrRange(start=0, end=10, rdl_addrmap_grp=["32b", "64b"]),
                          dest=SimpleId(id=1))
    rule2 = RouteMapRule(addr_range=AddrRange(start=10, end=20, rdl_addrmap_grp=["32b"]),
                          dest=SimpleId(id=2))
    rule3 = RouteMapRule(addr_range=AddrRange(start=20, end=30), dest=SimpleId(id=3))
    route_map = RouteMap(name="sam", rules=[rule1, rule2, rule3])
    assert route_map.distinct_groups() == ["32b", "64b"]


def test_route_map_filter_by_group():
    """Test filtering a RouteMap by group, keeping untagged rules in every group."""
    rule1 = RouteMapRule(addr_range=AddrRange(start=0, end=10, rdl_addrmap_grp=["32b", "64b"]),
                          dest=SimpleId(id=1), desc="endpoint1")
    rule2 = RouteMapRule(addr_range=AddrRange(start=10, end=20, rdl_addrmap_grp=["32b"]),
                          dest=SimpleId(id=2), desc="endpoint2")
    rule3 = RouteMapRule(addr_range=AddrRange(start=20, end=30, rdl_addrmap_grp=["64b"]),
                          dest=SimpleId(id=3), desc="endpoint3")
    route_map = RouteMap(name="sam", rules=[rule1, rule2, rule3])

    grp_32b = route_map.filter_by_group("32b")
    assert {r.desc for r in grp_32b.rules} == {"endpoint1", "endpoint2"}

    grp_64b = route_map.filter_by_group("64b")
    assert {r.desc for r in grp_64b.rules} == {"endpoint1", "endpoint3"}


def test_route_map_filter_by_group_includes_untagged():
    """Test that untagged rules are included in every group's filtered RouteMap."""
    tagged = RouteMapRule(addr_range=AddrRange(start=0, end=10, rdl_addrmap_grp=["32b"]),
                          dest=SimpleId(id=1), desc="tagged")
    untagged = RouteMapRule(addr_range=AddrRange(start=10, end=20), dest=SimpleId(id=2),
                             desc="untagged")
    route_map = RouteMap(name="sam", rules=[tagged, untagged])

    grp_32b = route_map.filter_by_group("32b")
    assert {r.desc for r in grp_32b.rules} == {"tagged", "untagged"}

    grp_64b = route_map.filter_by_group("64b")
    assert {r.desc for r in grp_64b.rules} == {"untagged"}


def test_rdl_addrmap_grp_differs_per_addr_range_of_same_endpoint():
    """Test that two addr_ranges of the same endpoint can belong to different groups."""
    narrow_range = RouteMapRule(addr_range=AddrRange(start=0, end=10, rdl_addrmap_grp="32b"),
                                 dest=SimpleId(id=1), desc="ep_narrow")
    wide_range = RouteMapRule(addr_range=AddrRange(start=10, end=20, rdl_addrmap_grp="64b"),
                               dest=SimpleId(id=1), desc="ep_wide")
    route_map = RouteMap(name="sam", rules=[narrow_range, wide_range])

    grp_32b = route_map.filter_by_group("32b")
    assert {r.desc for r in grp_32b.rules} == {"ep_narrow"}

    grp_64b = route_map.filter_by_group("64b")
    assert {r.desc for r in grp_64b.rules} == {"ep_wide"}
