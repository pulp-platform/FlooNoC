#!/usr/bin/env python3
# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for traffic generation."""

from pathlib import Path

import pytest

from floogen.config_parser import parse_config
from floogen.model.network import Network
from floogen.model.traffic import _xy_addr_map, gen_traffic_builtin


EXAMPLES_DIR = Path(__file__).resolve().parents[1] / "examples"


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
