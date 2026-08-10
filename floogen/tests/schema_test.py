# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Regression tests for the config-model schema.

These cover input shapes that used to be accepted (and silently misinterpreted)
rather than rejected, plus validators that returned the wrong thing.
"""

import pytest
from pydantic import ValidationError

from floogen.model.endpoint import EndpointDesc
from floogen.model.protocol import AXI4
from floogen.model.router import RouterDesc
from floogen.model.routing import Coord, RouteRule, RouteTable, SimpleId


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
