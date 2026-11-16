# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Tests for traffic generation."""

from pathlib import Path

import pytest
import ruamel.yaml
from pydantic import ValidationError

from floogen.config_parser import parse_config
from floogen.model.network import Network
from floogen.model.traffic import (
    Traffic,
    TrafficStream,
    _gen_job_str,
    _xy_addr_map,
    gen_traffic_builtin,
    gen_traffic_cfg,
    parse_traffic_cfg,
)

EXAMPLES_DIR = Path(__file__).resolve().parents[1] / "examples"

# Number of lines of a job, as written by the generator (one value per line), so that it
# follows the job file format.
JOB_LINES = _gen_job_str(0, 0, 0).count("\n")


def _network(name: str = "nw_mesh_xy") -> Network:
    network = parse_config(Network, EXAMPLES_DIR / f"{name}.yml")
    assert network is not None
    network.create_network()
    network.compile_network()
    network.gen_routing_info()
    return network


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


def _write_traffic_cfg(path: Path, flows: list[dict]) -> Path:
    """Write a traffic configuration file with the given flow descriptions."""
    with open(path, "w", encoding="utf-8") as f:
        ruamel.yaml.YAML(typ="safe").dump({"traffic_flows": flows}, f)
    return path


def _jobs(path: Path) -> list[list[str]]:
    """Split a job file without error descriptions into its jobs."""
    lines = path.read_text(encoding="utf-8").splitlines()
    assert len(lines) % JOB_LINES == 0
    return [lines[i : i + JOB_LINES] for i in range(0, len(lines), JOB_LINES)]


@pytest.mark.parametrize("route_algo", ["xy", "yx", "id", "src"])
def test_builtin_traffic_uses_mesh_coordinates_for_all_routing_algorithms(tmp_path, route_algo):
    """Built-in traffic uses topology coordinates rather than routing IDs."""
    network = _network(f"nw_mesh_{route_algo}")

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

    assert _jobs(tmp_path / "mesh_0.txt")
    assert _jobs(tmp_path / "mesh_100.txt")


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


def test_traffic_rejects_two_flows_on_one_initiator():
    """Only one flow per initiator is supported, since each DMA runs a single job file."""
    flows = [_flow(name="first"), _flow(name="second", endpoint=[2, 2])]
    with pytest.raises(ValidationError, match="'first' and 'second' share initiator"):
        Traffic.model_validate({"traffic_flows": flows})


@pytest.mark.parametrize("name", ["nw_mesh_xy", "axi_mesh_xy"])
def test_example_traffic_files_parse(name):
    """The example traffic files have no `start_time`/`qos` and keep their defaults."""
    traffic = parse_traffic_cfg(EXAMPLES_DIR / "traffic" / f"{name}.yml")
    assert all(f.start_time == 0 and f.qos == 0 for f in traffic.traffic_flows)


def test_job_string_starts_with_release_cycle_and_qos():
    assert _gen_job_str(64, 0x10, 0x20, release_cycle=100, qos=7) == (
        "100\n7\n64\n0x10\n0x20\n0\n0\n256\n256\n0\n0\n0\n"
    )


def test_traffic_cfg_jobs(tmp_path):
    """Jobs carry the flow's start time and QoS, and their transfers follow `rw`."""
    network = _network()
    addr_map = _xy_addr_map(network)
    cfg = _write_traffic_cfg(
        tmp_path / "traffic.yml",
        [
            _flow(
                name="w",
                initiator=[0, 1],
                endpoint=[2, 3],
                start_time=500,
                qos=9,
                narrow_burst={"number": 1, "length": 2},
                wide_burst={"number": 2, "length": 4},
            ),
            _flow(name="r", initiator=[3, 3], endpoint=[-1, 0], rw="read"),
        ],
    )
    gen_traffic_cfg(cfg, network, "t", tmp_path / "jobs")

    local, ext = addr_map[(0, 1)], addr_map[(2, 3)]
    # Wide DMA of node (0, 1): two 4-beat bursts of 512 bits.
    assert (
        _jobs(tmp_path / "jobs" / "t_1.txt")
        == [["500", "9", "256", hex(local), hex(ext), "0", "0", "256", "256", "0", "0", "0"]] * 2
    )
    # Narrow DMA of node (0, 1): one 2-beat burst of 64 bits.
    assert _jobs(tmp_path / "jobs" / "t_101.txt") == [
        ["500", "9", "16", hex(local), hex(ext), "0", "0", "256", "256", "0", "0", "0"]
    ]

    # A read flow copies from the endpoint into the initiator, with the defaults.
    local, ext = addr_map[(3, 3)], addr_map[(-1, 0)]
    assert _jobs(tmp_path / "jobs" / "t_15.txt") == [
        ["0", "0", "64", hex(ext), hex(local), "0", "0", "256", "256", "0", "0", "0"]
    ]
    assert _jobs(tmp_path / "jobs" / "t_115.txt") == []


def test_traffic_cfg_idle_dmas_get_files_without_jobs(tmp_path):
    """Every DMA of a node without a flow gets a job file without jobs, replacing stale ones."""
    network = _network()
    outdir = tmp_path / "jobs"
    outdir.mkdir()
    (outdir / "t_5.txt").write_text("stale jobs from an earlier run\n", encoding="utf-8")
    cfg = _write_traffic_cfg(
        tmp_path / "traffic.yml",
        [_flow(narrow_burst={"number": 1, "length": 1})],
    )
    gen_traffic_cfg(cfg, network, "t", outdir)

    assert len(_jobs(outdir / "t_0.txt")) == 1
    assert len(_jobs(outdir / "t_100.txt")) == 1
    for idx in range(1, 16):
        assert _jobs(outdir / f"t_{idx}.txt") == []
        assert _jobs(outdir / f"t_{idx + 100}.txt") == []
    assert len(list(outdir.glob("t_*.txt"))) == 32


@pytest.mark.parametrize(
    "initiator, endpoint, error",
    [
        ([-1, 0], [1, 1], r"initiator \[-1, 0\] is outside the 4x4 mesh"),
        ([4, 0], [1, 1], r"initiator \[4, 0\] is outside the 4x4 mesh"),
        ([0, 0], [7, 7], r"no network interface at endpoint \[7, 7\]"),
    ],
)
def test_traffic_cfg_rejects_flows_that_cannot_run(tmp_path, initiator, endpoint, error):
    """A flow that cannot run is an error, and no job file is written."""
    network = _network()
    cfg = _write_traffic_cfg(
        tmp_path / "traffic.yml", [_flow(name="bad", initiator=initiator, endpoint=endpoint)]
    )
    with pytest.raises(ValueError, match=error):
        gen_traffic_cfg(cfg, network, "t", tmp_path / "jobs")
    assert not (tmp_path / "jobs").exists()


def test_traffic_cfg_rejects_two_flows_on_one_initiator(tmp_path):
    network = _network()
    cfg = _write_traffic_cfg(tmp_path / "traffic.yml", [_flow(name="a"), _flow(name="b")])
    with pytest.raises(ValueError, match="'a' and 'b' share initiator"):
        gen_traffic_cfg(cfg, network, "t", tmp_path / "jobs")


def test_builtin_traffic_jobs_have_default_release_and_qos(tmp_path):
    """Built-in patterns release all jobs at cycle 0 with QoS 0."""
    gen_traffic_builtin(
        "uniform",
        _network(),
        "mesh",
        tmp_path,
        num_narrow_bursts=2,
        narrow_burst_length=1,
        num_wide_bursts=3,
        wide_burst_length=1,
        traffic_rw="read",
    )
    for idx in [*range(16), *range(100, 116)]:
        jobs = _jobs(tmp_path / f"mesh_{idx}.txt")
        assert len(jobs) == (3 if idx < 100 else 2)
        assert all(job[:2] == ["0", "0"] for job in jobs)
