# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Regression tests for the config-model schema.

These cover input shapes that used to be accepted (and silently misinterpreted)
rather than rejected, plus validators that returned the wrong thing.
"""

import pathlib

import pytest
from pydantic import ValidationError

from floogen.config_parser import parse_config
from floogen.model.connection import ConnectionDesc
from floogen.model.endpoint import EndpointDesc
from floogen.model.network import Network
from floogen.model.protocol import AXI4
from floogen.model.router import RouterDesc
from floogen.model.routing import (
    AddrRange,
    Coord,
    RouteAlgo,
    RouteMap,
    RouteRule,
    RouteTable,
    Routing,
    RoutingDesc,
    SimpleId,
    VcImpl,
    WideRwDecouple,
)

EXAMPLE = pathlib.Path(__file__).parents[1] / "examples" / "axi_mesh_xy.yml"


def test_route_table_model_validate_returns_a_model():
    """`sort_and_pad` must return `self`, not the result of `list.reverse()`."""
    table = RouteTable.model_validate({"name": "t", "routes": [{"route": None, "id": {"id": 0}}]})
    assert isinstance(table, RouteTable)
    assert len(table) == 1


def test_route_table_pads_and_reverses():
    """Missing destinations are filled in and the table is emitted in reverse order."""
    routes = [RouteRule(route=None, id=SimpleId(id=2))]
    table = RouteTable(name="t", routes=routes)
    assert [r.id for r in table.routes] == [SimpleId(id=2), SimpleId(id=1), SimpleId(id=0)]


@pytest.mark.parametrize("model", [EndpointDesc, RouterDesc])
def test_scalar_xy_id_offset_is_rejected(model):
    """A non-mapping offset used to be silently dropped to `None`."""
    with pytest.raises(ValidationError):
        model(name="n", xy_id_offset=5)


@pytest.mark.parametrize("model", [EndpointDesc, RouterDesc])
def test_misspelled_coord_key_is_rejected(model):
    """`{'X': 3}` used to validate as `Coord(x=0, ...)`, silently losing the offset."""
    with pytest.raises(ValidationError):
        model(name="n", xy_id_offset={"X": 3, "y": 2})


@pytest.mark.parametrize("model", [EndpointDesc, RouterDesc])
def test_xy_id_offset_accepts_both_union_branches(model):
    """Both `SimpleId` and `Coord` must be reachable through the union."""
    assert model(name="n", xy_id_offset={"id": 7}).xy_id_offset == SimpleId(id=7)
    assert model(name="n", xy_id_offset={"x": 1, "y": 2}).xy_id_offset == Coord(x=1, y=2)


@pytest.mark.parametrize("model", [EndpointDesc, RouterDesc])
def test_partial_coord_offset_is_accepted(model):
    """A partial offset keeps working; the omitted axis defaults to 0."""
    assert model(name="n", xy_id_offset={"x": 2}).xy_id_offset == Coord(x=2, y=0)


def test_unknown_protocol_field_is_rejected():
    """Misspelled keys in the `protocols` section used to be silently ignored.

    `userwidth` reaches the default for `user_width` rather than setting it.
    """
    with pytest.raises(ValidationError):
        AXI4.model_validate(
            {
                "name": "n",
                "protocol": "AXI4",
                "data_width": 64,
                "addr_width": 32,
                "id_width": 3,
                "userwidth": 8,
            }
        )


# --- shared coercions (`OneOrMany`, `ArrayDims`, `ConfigEnum`) ------------------------
#
# These go through `model_validate` rather than `__init__`, because that is the path a
# YAML config actually takes. It is also the honest one to test: the shorthand spellings
# widen what validation accepts, not what the declared field type is, so passing a bare
# `int` to a `list[int]` field is a type error at a statically-checked call site.


@pytest.mark.parametrize("model", [EndpointDesc, RouterDesc])
def test_array_accepts_bare_int(model):
    """`array: 4` is shorthand for `array: [4]`."""
    assert model.model_validate({"name": "n", "array": 4}).array == (4,)
    assert model.model_validate({"name": "n", "array": [4, 2]}).array == (4, 2)


def test_tree_accepts_bare_int():
    assert RouterDesc.model_validate({"name": "n", "tree": 3}).tree == [3]
    assert RouterDesc.model_validate({"name": "n", "tree": [3, 2]}).tree == [3, 2]


def test_addr_range_accepts_a_single_mapping():
    """A lone address range need not be wrapped in a list."""
    ep = EndpointDesc.model_validate(
        {"name": "n", "sbr_port_protocol": ["p"], "addr_range": {"start": 0, "end": 16}}
    )
    assert ep.addr_range == [AddrRange(start=0, end=16)]


def test_rdl_addrmap_grp_accepts_a_single_name():
    rng = AddrRange.model_validate({"start": 0, "end": 16, "rdl_addrmap_grp": "grp"})
    assert rng.rdl_addrmap_grp == ["grp"]


def test_connection_idx_accepts_bare_int():
    con = ConnectionDesc.model_validate({"src": "a", "dst": "b", "src_idx": 1, "dst_idx": [2, 3]})
    assert con.src_idx == [1]
    assert con.dst_idx == [2, 3]


def test_optional_list_fields_stay_none_when_omitted():
    """The list coercion must not turn an absent value into `[None]`."""
    assert AddrRange(start=0, end=16).rdl_addrmap_grp is None
    assert ConnectionDesc(src="a", dst="b").src_idx is None


@pytest.mark.parametrize("value", ["XY", "xy", "XYRouting"])
def test_route_algo_accepts_name_and_value(value):
    assert RoutingDesc(route_algo=value).route_algo is RouteAlgo.XY


def test_route_algo_rejects_unknown_name():
    with pytest.raises(ValidationError):
        RoutingDesc(route_algo="Diagonal")


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("Phys", WideRwDecouple.PHYS),
        ("PHYS", WideRwDecouple.PHYS),
        ("vc", WideRwDecouple.VC),
        (True, WideRwDecouple.PHYS),
        (False, WideRwDecouple.NONE),
    ],
)
def test_decouple_rw_spellings(value, expected):
    """The bool shorthand and the name/value spellings all still resolve."""
    assert RoutingDesc(route_algo="XY", decouple_rw=value).decouple_rw is expected


@pytest.mark.parametrize("value", ["preempt", "PREEMPT", "VcPreemptValid"])
def test_vc_impl_spellings(value):
    assert RoutingDesc(route_algo="XY", vc_impl=value).vc_impl is VcImpl.PREEMPT


# --- config vs. elaborated routing ---------------------------------------------------


def test_generated_routing_fields_are_not_configurable():
    """`sam`, the widths and the endpoint counts are derived, not declared."""
    for field in ("sam", "num_x_bits", "num_endpoints", "addr_width", "num_route_bits"):
        assert field not in RoutingDesc.model_fields
        with pytest.raises(ValidationError):
            RoutingDesc.model_validate({"route_algo": "XY", field: 1})


def test_routing_info_is_unavailable_before_elaboration():
    """Reading a derived width too early names the cause instead of returning `None`."""
    network = parse_config(Network, EXAMPLE)
    with pytest.raises(ValueError, match="gen_routing_info"):
        _ = network.routing_info


def test_routing_info_is_available_after_elaboration():
    network = parse_config(Network, EXAMPLE)
    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    routing = network.routing_info
    assert isinstance(routing, Routing)
    # Derived values are non-optional once elaborated, so no caller has to re-check.
    assert routing.num_endpoints > 0
    assert routing.addr_width == network.protocols[0].addr_width
    assert len(routing.sam) > 0
    # ... and the configuration it was built from is carried over unchanged.
    assert routing.route_algo is RouteAlgo.XY
    assert routing.use_id_table is True


def test_unset_decouple_rw_emits_no_localparam():
    """`decouple_rw`/`vc_impl` are only rendered when the config asked for them."""
    desc = RoutingDesc(route_algo=RouteAlgo.XY)
    assert desc.decouple_rw is None
    assert desc.vc_impl is None
    routing = Routing.from_desc(
        desc, addr_width=32, num_endpoints=1, num_id_bits=1, sam=RouteMap(name="sam", rules=[])
    )
    assert routing.render_vc_impl() == ""


def test_set_decouple_rw_emits_localparam():
    routing = Routing.from_desc(
        RoutingDesc(route_algo=RouteAlgo.XY, decouple_rw="Phys", vc_impl="PREEMPT"),
        addr_width=32,
        num_endpoints=1,
        num_id_bits=1,
        sam=RouteMap(name="sam", rules=[]),
    )
    rendered = routing.render_vc_impl()
    assert "WideRwDecouple" in rendered
    assert "VcImpl" in rendered
