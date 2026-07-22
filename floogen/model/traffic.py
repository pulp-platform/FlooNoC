#!/usr/bin/env python3
# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Gianluca Bellocchi <gianluca.bellocchi@unimore.it>

"""Generation of DMA traffic jobs for FlooNoC testbenches from:

- traffic configuration files describing traffic streams between
  endpoints identified by their XY coordinates (see `gen_traffic_cfg`);
- built-in traffic patterns (see `gen_traffic_builtin`), requiring no 
  dedicated traffic configuration file.
"""

import math
import random
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import ruamel.yaml
from pydantic import BaseModel, ConfigDict, ValidationError, field_validator

from floogen.model.network import Network
from floogen.model.routing import XYDirections
from floogen.utils import clog2

# Built-in, mesh-wide algorithmic traffic patterns supported by `gen_traffic_builtin`.
MESH_TRAFFIC_TYPES = [
    "hbm", "uniform", "onehop", "bit_complement", "bit_reverse", "bit_rotation",
    "neighbor", "shuffle", "transpose", "tornado", "hotspot", "hotspot_boundary", "matmul",
]

# Seeded for reproducibility of the `uniform` traffic pattern.
random.seed(42)

def _log(verbose: bool, msg: str):
    """Print `msg` only when verbose output is enabled."""
    if verbose:
        print(msg)


class Burst(BaseModel):
    """Group of bursts with the same length and data width.

    Attributes:
        number (int): Number of bursts to generate.
        length (int): Burst length [Beats].
        data_width (Optional[int]): Resolved from the FlooNoC narrow/wide protocol.
    """

    number: int
    length: int

    # Resolved using FlooNoC model
    data_width: Optional[int] = None


class TrafficStream(BaseModel):
    """Traffic stream between an initiator and an endpoint.

    Attributes:
        name (str): Name of the traffic flow, used to identify the emitted job files.
        initiator (List[int]): XY coordinates of the initiator node.
        endpoint (List[int]): XY coordinates of the endpoint node.
        rw (str): `"read"` or `"write"` transaction.
        narrow_burst (List[Burst]): Narrow bursts to generate for this flow.
        wide_burst (List[Burst]): Wide bursts to generate for this flow.
    """

    name: str
    initiator: List[int]
    endpoint: List[int]
    rw: str
    narrow_burst: List[Burst]
    wide_burst: List[Burst]

    @field_validator("narrow_burst", "wide_burst", mode="before")
    @classmethod
    def wrap_single_burst(cls, v):
        """Accept a single burst dict as well as a list."""
        if isinstance(v, dict):
            return [v]
        return v

    # Resolved using FlooNoC model
    initiator_addr: Optional[int] = None
    endpoint_addr: Optional[int] = None


class Traffic(BaseModel):
    """Traffic class describing how different traffic streams interact in the FlooNoC system."""

    model_config = ConfigDict(arbitrary_types_allowed=True, extra="forbid")
    traffic_flows: List[TrafficStream]


def parse_traffic_cfg(cfg: Path) -> Traffic:
    """Parse a traffic configuration file into a `Traffic` model."""
    with open(cfg, "r", encoding="utf-8") as f:
        traffic_desc = ruamel.yaml.YAML(typ="safe").load(f)
    try:
        return Traffic.model_validate(traffic_desc)
    except ValidationError as e:
        raise ValueError(f"Error while validating traffic configuration '{cfg}': {e}") from e


def _protocol_data_widths(network: Network, verbose: bool = False) -> Dict[str, int]:
    """Map protocol type (`"narrow"`/`"wide"`) to data width, resolved from the FlooNoC model."""
    proto_dw: Dict[str, int] = {}
    for p in network.protocols:
        if p.type is None:
            _log(verbose, f"Warning: Protocol '{p.name}' does not have a type, please provide a "
                          f"type in the FlooNoC configuration: '{network.name}'")
            continue
        proto_dw.setdefault(p.type, p.data_width)
    return proto_dw


def _ni_mesh_coord(network: Network, ni_name: str) -> Tuple[int, int]:
    """Infer an NI's mesh coordinate from its router connection.

    Traffic configurations identify nodes by their physical mesh coordinates. Those
    coordinates are independent of the routing ID: ID and source routing assign a
    ``SimpleId`` to the NI, whereas XY and YX routing assign a ``Coord``. Derive
    the coordinate from the adjacent router's array index and the link direction
    instead.
    """
    if network.graph is None:
        raise ValueError("Network graph has not been created")

    for neighbor in network.graph.neighbors(ni_name):
        if not network.graph.is_rt_node(neighbor):
            continue

        router_idx = network.graph.get_node_arr_idx(neighbor)
        if len(router_idx) != 2:
            continue

        edge = network.graph.edges[(ni_name, neighbor)]
        direction = edge["dst_dir"]
        if direction is None and network.graph.has_edge(neighbor, ni_name):
            direction = network.graph.edges[(neighbor, ni_name)]["src_dir"]
        if direction is None:
            continue

        offset = XYDirections.to_coords(direction)
        return router_idx[0] + offset.x, router_idx[1] + offset.y

    raise ValueError(f"Cannot infer a mesh coordinate for network interface '{ni_name}'")


def _xy_addr_map(network: Network) -> Dict[Tuple[int, int], int]:
    """Build an XY-coordinate-to-base-address lookup from the physical mesh topology."""
    if network.graph is None:
        raise ValueError("Network graph has not been created")

    xy_addr_map: Dict[Tuple[int, int], int] = {}
    for ni_name, ni in network.graph.get_ni_nodes(with_name=True):
        if getattr(ni, "addr_range", None):
            xy_addr_map[_ni_mesh_coord(network, ni_name)] = ni.addr_range[0].start
    return xy_addr_map


def resolve_traffic_model(traffic_model: Traffic, network: Network,
                          verbose: bool = False) -> Traffic:
    """Resolve burst data widths and initiator/endpoint addresses using the FlooNoC model."""
    proto_dw = _protocol_data_widths(network, verbose=verbose)
    for flow in traffic_model.traffic_flows:
        for burst in flow.narrow_burst:
            burst.data_width = proto_dw.get("narrow")
        for burst in flow.wide_burst:
            burst.data_width = proto_dw.get("wide")

    xy_addr_map = _xy_addr_map(network)

    # Resolve initiator and endpoint addresses for each traffic flow
    for flow in traffic_model.traffic_flows:
        init_xy = (flow.initiator[0], flow.initiator[1])
        ep_xy = (flow.endpoint[0], flow.endpoint[1])
        if init_xy in xy_addr_map:
            flow.initiator_addr = xy_addr_map[init_xy]
        else:
            _log(verbose, f"Warning: No address found for initiator {init_xy} in flow '{flow.name}'")
        if ep_xy in xy_addr_map:
            flow.endpoint_addr = xy_addr_map[ep_xy]
        else:
            _log(verbose, f"Warning: No address found for endpoint {ep_xy} in flow '{flow.name}'")

    return traffic_model


def print_traffic_model(traffic_model: Traffic):
    """Print a summary of all traffic flows in the traffic model."""
    print("\n=== Traffic Model ===")
    for i, flow in enumerate(traffic_model.traffic_flows):
        init_addr_str = hex(flow.initiator_addr) if flow.initiator_addr is not None else "N/A"
        ep_addr_str = hex(flow.endpoint_addr) if flow.endpoint_addr is not None else "N/A"
        print(f"\n  Flow [{i}]: '{flow.name}'")
        print(f"    Initiator : {flow.initiator}  addr={init_addr_str}")
        print(f"    Endpoint  : {flow.endpoint}  addr={ep_addr_str}")
        print(f"    R/W       : {flow.rw}")
        narrow_str = ", ".join(
            f"(num={b.number}, len={b.length}, dw={b.data_width})" for b in flow.narrow_burst
        ) or "none"
        wide_str = ", ".join(
            f"(num={b.number}, len={b.length}, dw={b.data_width})" for b in flow.wide_burst
        ) or "none"
        print(f"    Narrow bursts : {narrow_str}")
        print(f"    Wide bursts   : {wide_str}")
    print("====================\n")


def _gen_job_str(
    length: int,
    src_addr: int,
    dst_addr: int,
    *,
    max_src_burst_size: int = 256,
    max_dst_burst_size: int = 256,
    r_aw_decouple: bool = False,
    r_w_decouple: bool = False,
    num_errors: int = 0,
) -> str:
    """Generate the job-file representation of a single job."""
    return (
        f"{int(length)}\n"
        f"{hex(src_addr)}\n"
        f"{hex(dst_addr)}\n"
        f"{0}\n"  # src_protocol: AXI
        f"{0}\n"  # dst_protocol: AXI
        f"{max_src_burst_size}\n"
        f"{max_dst_burst_size}\n"
        f"{int(r_aw_decouple)}\n"
        f"{int(r_w_decouple)}\n"
        f"{num_errors}\n"
    )


def _emit_jobs(jobs: str, outdir: Path, filename: str, idx: int):
    """Emit jobs to a job file."""
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / f"{filename}_{idx}.txt").write_text(jobs, encoding="utf-8")


def gen_traffic_cfg(  # pylint: disable=too-many-arguments, too-many-positional-arguments
    cfg: Path, network: Network, 
    filename: str, outdir: Path, 
    verbose: bool = False,
):
    """Create a traffic model from a traffic configuration file, then generate DMA jobs for all traffic streams and for the given network."""
    traffic_model = parse_traffic_cfg(cfg)
    traffic_model = resolve_traffic_model(traffic_model, network, verbose=verbose)
    if verbose:
        print_traffic_model(traffic_model)
    floonoc_num_y = network.routers[0].array[1]
    for flow in traffic_model.traffic_flows:
        local_addr = flow.initiator_addr
        ext_addr = flow.endpoint_addr
        if local_addr is None or ext_addr is None:
            _log(verbose, f"Warning: Skipping flow '{flow.name}' due to unresolved addresses")
            continue
        src_addr = ext_addr if flow.rw == "read" else local_addr
        dst_addr = local_addr if flow.rw == "read" else ext_addr

        wide_jobs = ""
        for burst in flow.wide_burst:
            if burst.data_width is None:
                _log(verbose, f"Warning: No wide interface was detected, skipping wide burst "
                              f"generation for traffic flow '{flow.name}'")
                continue
            wide_length = burst.length * burst.data_width / 8
            wide_jobs += _gen_job_str(wide_length, src_addr, dst_addr) * burst.number

        narrow_jobs = ""
        for burst in flow.narrow_burst:
            if burst.data_width is None:
                _log(verbose, f"Warning: No narrow interface was detected, skipping narrow burst "
                              f"generation for traffic flow '{flow.name}'")
                continue
            narrow_length = burst.length * burst.data_width / 8
            narrow_jobs += _gen_job_str(narrow_length, src_addr, dst_addr) * burst.number

        x, y = flow.initiator[0], flow.initiator[1]
        idx = x * floonoc_num_y + y
        _emit_jobs(wide_jobs, outdir, filename, idx)
        _log(verbose, f"Emitted wide job with index {idx} (x: {x}, y: {y})")
        _emit_jobs(narrow_jobs, outdir, filename, idx + 100)
        _log(verbose, f"Emitted narrow job with index {idx + 100} (x: {x}, y: {y})")


def gen_traffic_builtin(  # pylint: disable=too-many-arguments, too-many-positional-arguments
    traffic_type: str, network: Network,
    filename: str, outdir: Path,
    num_narrow_bursts: int, narrow_burst_length: int,
    num_wide_bursts: int, wide_burst_length: int, 
    traffic_rw: str, verbose: bool = False, 
):
    """Generate DMA job files for a built-in traffic pattern. Unlike `gen_traffic_cfg`, this does not require a dedicated traffic configuration file."""
    # pylint: disable=too-many-locals, too-many-branches, too-many-statements
    if traffic_type not in MESH_TRAFFIC_TYPES:
        raise ValueError(f"Unknown traffic type: '{traffic_type}'. "
                          f"Supported types: {', '.join(MESH_TRAFFIC_TYPES)}")

    num_x, num_y = network.routers[0].array[0], network.routers[0].array[1]
    xy_addr_map = _xy_addr_map(network)
    proto_dw = _protocol_data_widths(network, verbose=verbose)
    narrow_dw = proto_dw.get("narrow")
    wide_dw = proto_dw.get("wide")

    def addr(x, y):
        a = xy_addr_map.get((x, y))
        if a is None:
            _log(verbose, f"Warning: No address found for node ({x}, {y})")
        return a

    for x in range(num_x):
        for y in range(num_y):
            local_addr = addr(x, y)
            wide_length = wide_burst_length * wide_dw / 8 if wide_dw is not None else None
            narrow_length = narrow_burst_length * narrow_dw / 8 if narrow_dw is not None else None
            if traffic_type == "hbm":
                # Tile x=0 are the HBM channels; each core reads/writes the channel of its
                # y coordinate.
                accesses = [(addr(-1, y), traffic_rw, wide_length)]
            elif traffic_type == "uniform":
                ext_x, ext_y = x, y
                while (ext_x, ext_y) == (x, y):
                    ext_x = random.randint(0, num_x - 1)
                    ext_y = random.randint(0, num_y - 1)
                accesses = [(addr(ext_x, ext_y), traffic_rw, wide_length)]
            elif traffic_type == "onehop":
                if (x, y) != (0, 0):
                    wide_length = narrow_length = 0
                    ext_addr = local_addr = 0
                else:
                    ext_addr = addr(x, y + 1)
                accesses = [(ext_addr, traffic_rw, wide_length)]
            elif traffic_type == "bit_complement":
                accesses = [(addr(num_x - x - 1, num_y - y - 1), traffic_rw, wide_length)]
            elif traffic_type == "bit_reverse":
                # in order to achieve same result as garnet:
                # change to space where addresses start at 0 and return afterwards
                straight = x * num_y + y
                num_destinations = num_x * num_y
                reverse = straight & 1  # LSB
                num_bits = clog2(num_destinations)
                for _ in range(1, num_bits):
                    reverse <<= 1
                    straight >>= 1
                    reverse |= straight & 1  # LSB
                accesses = [(addr(reverse % num_x, reverse // num_x), traffic_rw, wide_length)]
            elif traffic_type == "bit_rotation":
                source = x * num_y + y
                num_destinations = num_x * num_y
                if source % 2 == 0:
                    ext = source // 2
                else:  # (source % 2 == 1)
                    ext = (source // 2) + (num_destinations // 2)
                accesses = [(addr(ext % num_x, ext // num_x), traffic_rw, wide_length)]
            elif traffic_type == "neighbor":
                accesses = [(addr((x + 1) % num_x, y), traffic_rw, wide_length)]
            elif traffic_type == "shuffle":
                source = x * num_y + y
                num_destinations = num_x * num_y
                if source < num_destinations // 2:
                    ext = source * 2
                else:
                    ext = (source * 2) - num_destinations + 1
                accesses = [(addr(ext % num_x, ext // num_x), traffic_rw, wide_length)]
            elif traffic_type == "transpose":
                if num_x == num_y:
                    dest_x, dest_y = y, x
                elif num_y > num_x:
                    assert num_y % num_x == 0, "num_y must be divisible by num_x"
                    dest_x = y - (y // num_x) * num_x
                    dest_y = x + (y // num_x) * num_x
                else:
                    assert num_x % num_y == 0, "num_x must be divisible by num_y"
                    dest_x = y + (x // num_y) * num_y
                    dest_y = x - (x // num_y) * num_y
                accesses = [(addr(dest_x, dest_y), traffic_rw, wide_length)]
            elif traffic_type == "tornado":
                dest_x = (x + math.ceil(num_x / 2) - 1) % num_x
                accesses = [(addr(dest_x, y), traffic_rw, wide_length)]
            elif traffic_type == "hotspot_boundary":
                accesses = [(addr(-1, num_y // 2), traffic_rw, wide_length)]
            elif traffic_type == "hotspot":
                accesses = [(addr(num_x // 2, num_y // 2), traffic_rw, wide_length)]
            else:  # traffic_type == "matmul"
                # access matrix A from HBM
                accesses = [(addr(-1, y), "read", None if wide_length is None else wide_length // 2)]
                # access matrix B from HBM
                for i in range(num_y):
                    length = None if wide_length is None else (wide_length // 2) // num_y
                    accesses += [(addr(-1, (y + i) % num_y), "read", length)]
                # writeback of matrix C to HBM
                accesses += [(addr(-1, y), "write",
                              None if wide_length is None else wide_length // 4)]

            wide_jobs = ""
            narrow_jobs = ""
            for _ in range(num_wide_bursts):
                for ext_addr, access_rw, length in accesses:
                    if ext_addr is None or local_addr is None or length is None:
                        continue
                    src_addr = ext_addr if access_rw == "read" else local_addr
                    dst_addr = local_addr if access_rw == "read" else ext_addr
                    wide_jobs += _gen_job_str(length, src_addr, dst_addr)
            for _ in range(num_narrow_bursts):
                for ext_addr, access_rw, _length in accesses:
                    if ext_addr is None or local_addr is None or narrow_length is None:
                        continue
                    src_addr = ext_addr if access_rw == "read" else local_addr
                    dst_addr = local_addr if access_rw == "read" else ext_addr
                    narrow_jobs += _gen_job_str(narrow_length, src_addr, dst_addr)

            idx = x * num_y + y
            _emit_jobs(wide_jobs, outdir, filename, idx)
            _emit_jobs(narrow_jobs, outdir, filename, idx + 100)
