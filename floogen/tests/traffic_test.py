# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for traffic generation."""

from pathlib import Path

import pytest
from pydantic import ValidationError

from floogen.config_parser import parse_config
from floogen.model.network import Network
from floogen.model.traffic import (
    TrafficStream,
    _xy_addr_map,
    gen_traffic_builtin,
    parse_traffic_cfg,
)

EXAMPLES_DIR = Path(__file__).resolve().parents[1] / "examples"


def _flow(**kwargs) -> dict:
    """A minimal traffic flow description, as found in a traffic configuration file."""
    flow = {
        "name": "flow",
        "initiator": [0, 0],
        "endpoint": [1, 1],
        "rw": "write",
        "narrow_burst": {"number": 0, "length": 1},
        "wide_burst": {"number": 1, "length": 1},
    }
    flow.update(kwargs)
    return flow


@pytest.mark.parametrize("route_algo", ["xy", "yx", "id", "src"])
def test_builtin_traffic_uses_mesh_coordinates_for_all_routing_algorithms(tmp_path, route_algo):
    """Built-in traffic uses topology coordinates rather than routing IDs."""
    network = parse_config(Network, EXAMPLES_DIR / f"nw_mesh_{route_algo}.yml")
    assert network is not None
    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    addr_map = _xy_addr_map(network)
    assert addr_map[(0, 0)] == 0
    assert 0x0000_8000_0000 in addr_map.values()

    gen_traffic_builtin(
        "hotspot",
        network,
        "mesh",
        tmp_path,
        num_narrow_bursts=1,
        narrow_burst_length=1,
        num_wide_bursts=1,
        wide_burst_length=1,
        traffic_rw="write",
    )

    assert (tmp_path / "mesh_0.txt").read_text()
    assert (tmp_path / "mesh_100.txt").read_text()


def test_traffic_stream_defaults():
    """Without `start_time` and `qos`, a flow starts at cycle 0 with QoS 0."""
    flow = TrafficStream.model_validate(_flow())
    assert flow.start_time == 0
    assert flow.qos == 0


@pytest.mark.parametrize(
    "field, value",
    [
        ("qos", -1),
        ("qos", 16),
        ("start_time", -1),
        ("start_time", 2**32),
        ("qos", "high"),
        ("start_time", 1.5),
    ],
)
def test_traffic_stream_rejects_invalid_values(field, value):
    """`qos` is a 4-bit AXI QoS level and `start_time` a non-negative cycle count."""
    with pytest.raises(ValidationError):
        TrafficStream.model_validate(_flow(**{field: value}))


@pytest.mark.parametrize("field, value", [("qos", 0), ("qos", 15), ("start_time", 2**32 - 1)])
def test_traffic_stream_accepts_boundary_values(field, value):
    assert getattr(TrafficStream.model_validate(_flow(**{field: value})), field) == value


@pytest.mark.parametrize("name", ["nw_mesh_xy", "axi_mesh_xy"])
def test_example_traffic_files_parse(name):
    """The example traffic files have no `start_time`/`qos` and keep their defaults."""
    traffic = parse_traffic_cfg(EXAMPLES_DIR / "traffic" / f"{name}.yml")
    assert all(f.start_time == 0 and f.qos == 0 for f in traffic.traffic_flows)
