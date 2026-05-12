#!/usr/bin/env python3
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Tim Fischer <fischeti@iis.ee.ethz.ch>

import random
import argparse
import os
import math
import yaml
from pathlib import Path

from typing import Dict, List, Optional, Tuple
from pydantic import BaseModel, ConfigDict, ValidationError, field_validator

try:
    from floogen.config_parser import parse_config
    from floogen.model.network import Network
    FLOOGEN_AVAILABLE = True
except ImportError:
    FLOOGEN_AVAILABLE = False

MEM_SIZE = 2**16
NUM_X = 4
NUM_Y = 4
HBM_BASE_ADDR = 0x80000000

data_widths = {"wide": 512, "narrow": 64}

random.seed(42)

class Burst(BaseModel):
    """
    Burst class.
    """
    # Defined in traffic configuration file
    number: int
    length: int

    # Resolved using FlooNoC model
    data_width: Optional[int] = 512

class TrafficStream(BaseModel):
    """
    A single traffic flow between an initiator and an endpoint.
    """
    # Defined in traffic configuration file
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

class Traffic(BaseModel):  # pylint: disable=too-many-public-methods
    """
    Traffic class to describe how different traffic streams interact in the FlooNoC system.
    """
    model_config = ConfigDict(arbitrary_types_allowed=True, extra="forbid")
    traffic_flows: List[TrafficStream]

def create_floonoc_model(floonoc_cfg: str):
    """Parse FlooNoC configuration and create model using FlooGen."""
    if not FLOOGEN_AVAILABLE:
        print(f"Warning: floogen not available, skipping topology validation")
        return None
    cfg_path = Path(floonoc_cfg)
    if not cfg_path.exists():
        print(f"Warning: FlooNoC configuration file not found: {floonoc_cfg}")
        return None
    try:
        # Parse FlooNoC configuration
        floonoc_model = parse_config(Network, cfg_path)
        if floonoc_model is None:
            print("Warning: Failed to parse FlooNoC configuration")
            return None
        # Build FlooNoC model
        floonoc_model.create_network()
        floonoc_model.compile_network()
        floonoc_model.gen_routing_info()
        return floonoc_model
    except Exception as e:
        print(f"Warning: Error parsing FlooNoC configuration: {e}")
        return None

def create_traffic_model(traffic_cfg: str, floonoc_model: Optional[Network]):
    """Parse traffic configuration and create traffic stream model."""
    cfg_path = Path(traffic_cfg)
    if not cfg_path.exists():
        print(f"Warning: Traffic configuration file not found: {traffic_cfg}")
        return None
    # Load custom mapping from file descriptor
    try:
        with open(traffic_cfg, "r", encoding="utf-8") as f:
            traffic_desc = yaml.safe_load(f)
    except Exception as e:
        print(f"Warning: Error while loading traffic configuration: {e}")
        return None
    # Create traffic model
    try:
        traffic_model = Traffic.model_validate(traffic_desc)
    except ValidationError as e:
        print(f"Warning: Error while validating traffic configuration: {e}")
        return None
    # Add NoC channel data width from FlooNoC model
    if floonoc_model:
        proto_dw: Dict[str, int] = {}
        for p in floonoc_model.protocols:
            if p.type is not None:
                if p.type not in proto_dw:
                    proto_dw[p.type] = p.data_width
            else:
                print(f"Warning: Protocol '{p.name}' does not have a type, please provide a type in the FlooNoC configuration: '{floonoc_model.name}'")
                
        for flow in traffic_model.traffic_flows:
            for burst in flow.narrow_burst:
                burst.data_width = proto_dw.get("narrow")
            for burst in flow.wide_burst:
                burst.data_width = proto_dw.get("wide")
    # Build XY-to-address lookup from FlooNoC nodes
    xy_addr_map: Dict[Tuple[int, int], int] = {}
    if floonoc_model:
        for ni_name, ni in floonoc_model.graph.get_ni_nodes(with_name=True):
            coord = floonoc_model.graph.get_node_id(node_name=ni_name)
            if hasattr(ni, 'addr_range') and ni.addr_range:
                xy_addr_map[(coord.x, coord.y)] = ni.addr_range[0].start
    # Build XY-to-SAM-index lookup from FlooNoC routing rules
    xy_to_sam_idx: Dict[Tuple[int, int], int] = {}
    if floonoc_model and floonoc_model.routing.sam:
        xy_offset = floonoc_model.routing.xy_id_offset
        for sam_idx, rule in enumerate(reversed(floonoc_model.routing.sam.rules)):
            dest = rule.dest
            if hasattr(dest, 'x') and hasattr(dest, 'y'):
                if xy_offset is not None:
                    mesh_x = dest.x + xy_offset.x
                    mesh_y = dest.y + xy_offset.y
                else:
                    mesh_x = dest.x
                    mesh_y = dest.y
                key = (mesh_x, mesh_y)
                if key not in xy_to_sam_idx:
                    xy_to_sam_idx[key] = sam_idx
    # Resolve initiator and endpoint addresses for each traffic flow
    for flow in traffic_model.traffic_flows:
        init_xy = (flow.initiator[0], flow.initiator[1])
        ep_xy = (flow.endpoint[0], flow.endpoint[1])
        if init_xy in xy_addr_map:
            flow.initiator_addr = xy_addr_map[init_xy]
        else:
            print(f"Warning: No address found for initiator {init_xy} in flow '{flow.name}'")
        if ep_xy in xy_addr_map:
            flow.endpoint_addr = xy_addr_map[ep_xy]
        else:
            print(f"Warning: No address found for endpoint {ep_xy} in flow '{flow.name}'")
    return traffic_model

def print_traffic_model(traffic_model: Traffic):
    """Print a summary of all traffic flows in the traffic model."""
    print("\n=== Traffic Model ===")
    for i, flow in enumerate(traffic_model.traffic_flows):
        init_addr_str = hex(flow.initiator_addr) if flow.initiator_addr is not None else "N/A"
        ep_addr_str   = hex(flow.endpoint_addr)  if flow.endpoint_addr  is not None else "N/A"
        print(f"\n  Flow [{i}]: '{flow.name}'")
        print(f"    Initiator : {flow.initiator}  addr={init_addr_str}")
        print(f"    Endpoint  : {flow.endpoint}  addr={ep_addr_str}")
        print(f"    R/W       : {flow.rw}")
        narrow_str = ", ".join(f"(num={b.number}, len={b.length}, dw={b.data_width})" for b in flow.narrow_burst) or "none"
        wide_str   = ", ".join(f"(num={b.number}, len={b.length}, dw={b.data_width})" for b in flow.wide_burst)   or "none"
        print(f"    Narrow bursts : {narrow_str}")
        print(f"    Wide bursts   : {wide_str}")
    print("====================\n")

def clog2(x: int):
    """Compute the ceiling of the log2 of x."""
    return (x - 1).bit_length()


def get_xy_base_addr(x: int, y: int):
    """Get the address of a tile in the mesh."""
    assert x <= NUM_X+1 and y <= NUM_Y+1
    return (x * NUM_Y + y) * MEM_SIZE

def get_hbm_base_addr(ch: int):
    """Get the address of an HBM channel."""
    assert ch <= NUM_Y+1
    return HBM_BASE_ADDR + (ch << clog2(MEM_SIZE))


def gen_job_str(
    length: int,
    src_addr: int,
    dst_addr: int,
    *,
    max_src_burst_size: int = 256,
    max_dst_burst_size: int = 256,
    r_aw_decouple: bool = False,
    r_w_decouple: bool = False,
    num_errors: int = 0,
):
    # pylint: disable=too-many-arguments
    """Generate a single job."""
    job_str = ""
    job_str += f"{int(length)}\n"
    job_str += f"{hex(src_addr)}\n"
    job_str += f"{hex(dst_addr)}\n"
    job_str += f"{0}\n" # src_protocol: AXI
    job_str += f"{0}\n" # dst_protocol: AXI
    job_str += f"{max_src_burst_size}\n"
    job_str += f"{max_dst_burst_size}\n"
    job_str += f"{int(r_aw_decouple)}\n"
    job_str += f"{int(r_w_decouple)}\n"
    job_str += f"{num_errors}\n"
    return job_str


def emit_jobs(jobs, out_dir, name, idx):
    """Emit jobs to file."""
    # Generate directory if it does not exist
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    file_path = f"{out_dir}/{name}_{idx}.txt"
    with open(file_path, "w", encoding="utf-8") as job_file:
        job_file.write(jobs)
        job_file.close()

def gen_chimney2chimney_traffic(
    narrow_burst_length: int = 16,
    num_narrow_bursts: int = 16,
    rw: str = "write",
    bidir: bool = False,
    traffic_name: str = "chimney2chimney",
    out_dir: str = "jobs"
):
    """Generate Chimney to Chimney traffic."""
    num_masters = 2
    for i in range(num_masters):
        jobs = ""
        if bidir or i == 0:
            for _ in range(num_narrow_bursts):
                length = narrow_burst_length * data_widths["narrow"] / 8
                assert length <= MEM_SIZE
                src_addr = 0 if rw == "write" else MEM_SIZE
                dst_addr = MEM_SIZE if rw == "write" else 0
                job_str = gen_job_str(length, src_addr, dst_addr)
                jobs += job_str
        emit_jobs(jobs, out_dir, traffic_name, i)


def gen_nw_chimney2chimney_traffic(
    narrow_burst_length: int,
    wide_burst_length: int,
    num_narrow_bursts: int,
    num_wide_bursts: int,
    rw: str,
    bidir: bool,
    traffic_name: str,
    out_dir: str
):
    # pylint: disable=too-many-arguments, too-many-positional-arguments
    """Generate Narrow Wide Chimney to Chimney traffic."""
    num_masters = 2
    for i in range(num_masters):
        wide_jobs = ""
        narrow_jobs = ""
        wide_length = wide_burst_length * data_widths["wide"] / 8
        narrow_length = narrow_burst_length * data_widths["narrow"] / 8
        assert wide_length <= MEM_SIZE and narrow_length <= MEM_SIZE
        src_addr = 0 if rw == "write" else MEM_SIZE
        dst_addr = MEM_SIZE if rw == "write" else 0
        if bidir or i == 0:
            for _ in range(num_wide_bursts):
                wide_jobs += gen_job_str(wide_length, src_addr, dst_addr)
            for _ in range(num_narrow_bursts):
                narrow_jobs += gen_job_str(narrow_length, src_addr, dst_addr)
        emit_jobs(wide_jobs, out_dir, traffic_name, i)
        emit_jobs(narrow_jobs, out_dir, traffic_name, i + 100)


def gen_mesh_traffic(
    narrow_burst_length: int,
    wide_burst_length: int,
    num_narrow_bursts: int,
    num_wide_bursts: int,
    rw: str,
    traffic_name: str,
    traffic_type: str,
    out_dir: str,
    **_kwargs
):
    # pylint: disable=too-many-arguments, too-many-locals, too-many-branches, too-many-statements, too-many-positional-arguments
    """Generate Mesh traffic."""
    for x in range(0, NUM_X):
        for y in range(0, NUM_Y):
            wide_jobs = ""
            narrow_jobs = ""
            wide_length = wide_burst_length * data_widths["wide"] / 8
            narrow_length = narrow_burst_length * data_widths["narrow"] / 8
            local_addr = get_xy_base_addr(x, y)
            assert wide_length <= MEM_SIZE and narrow_length <= MEM_SIZE
            if traffic_type == "hbm":
                # Tile x=0 are the HBM channels
                # Each core read from the channel of its y coordinate
                ext_addr = get_hbm_base_addr(y)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "uniform":
                ext_addr = local_addr
                while ext_addr == local_addr:
                    ext_addr = get_xy_base_addr(random.randint(0, NUM_X-1),
                                                random.randint(0, NUM_Y-1))
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "onehop":
                if not (x == 0 and y == 0):
                    wide_length = 0
                    narrow_length = 0
                    local_addr = 0
                    ext_addr = 0
                else:
                    ext_addr = get_xy_base_addr(x, y + 1)
                accesses = [(ext_addr, rw, wide_length)]

            elif traffic_type == "bit_complement":
                ext_addr = get_xy_base_addr(NUM_X - x - 1, NUM_Y - y - 1)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "bit_reverse":
                # in order to achieve same result as garnet:
                # change to space where addresses start at 0 and return afterwards
                straight = x * NUM_Y + y
                num_destinations = NUM_X * NUM_Y
                reverse = straight & 1  # LSB
                num_bits = clog2(num_destinations)
                for _ in range(1, num_bits):
                    reverse <<= 1
                    straight >>= 1
                    reverse |= (straight & 1)  # LSB
                ext_addr = get_xy_base_addr(reverse % NUM_X, reverse // NUM_X)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "bit_rotation":
                source = x * NUM_Y + y
                num_destinations = NUM_X * NUM_Y
                if source % 2 == 0:
                    ext = source // 2
                else:  # (source % 2 == 1)
                    ext = (source // 2) + (num_destinations // 2)
                ext_addr = get_xy_base_addr(ext % NUM_X, ext // NUM_X)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "neighbor":
                ext_addr = get_xy_base_addr((x + 1) % NUM_X, y)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "shuffle":
                source = x * NUM_Y + y
                num_destinations = NUM_X * NUM_Y
                if source < num_destinations // 2:
                    ext = source * 2
                else:
                    ext = (source * 2) - num_destinations + 1
                ext_addr = get_xy_base_addr(ext % NUM_X, ext // NUM_X)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "transpose":
                if NUM_X == NUM_Y:
                    dest_x = y
                    dest_y = x
                elif NUM_Y > NUM_X:
                    assert NUM_Y % NUM_X == 0, "NUM_Y must be divisible by NUM_X"
                    dest_x = y - (y // NUM_X) * NUM_X
                    dest_y = x + (y // NUM_X) * NUM_X
                else:
                    assert NUM_X % NUM_Y == 0, "NUM_X must be divisible by NUM_Y"
                    dest_x = y + (x // NUM_Y) * NUM_Y
                    dest_y = x - (x // NUM_Y) * NUM_Y
                ext_addr = get_xy_base_addr(dest_x, dest_y)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "tornado":
                dest_x = (x + math.ceil(NUM_X / 2) - 1) % NUM_X
                ext_addr = get_xy_base_addr(dest_x, y)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "hotspot_boundary":
                ext_addr = get_hbm_base_addr(NUM_Y//2)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "hotspot":
                ext_addr = get_xy_base_addr(NUM_X//2, NUM_Y//2)
                accesses = [(ext_addr, rw, wide_length)]
            elif traffic_type == "matmul":
                # access matrix A from HBM
                accesses = [(get_hbm_base_addr(y), "read", wide_length//2)]
                # access matrix B from HBM
                for i in range(NUM_Y):
                    hbm_addr = get_hbm_base_addr((y + i) % NUM_Y)
                    accesses += [(hbm_addr, "read", (wide_length//2)//NUM_Y)]
                # Writeback of matrix C to HBM
                accesses += [(get_hbm_base_addr(y), "write", wide_length//4)]
            else:
                raise ValueError(f"Unknown traffic type: {traffic_type}")
            for _ in range(num_wide_bursts):
                for access in accesses:
                    src_addr = access[0] if access[1] == "read" else local_addr
                    dst_addr = local_addr if access[1] == "read" else access[0]
                    wide_jobs += gen_job_str(access[2], src_addr, dst_addr)
            for _ in range(num_narrow_bursts):
                for access in accesses:
                    src_addr = access[0] if access[1] == "read" else local_addr
                    dst_addr = local_addr if access[1] == "read" else access[0]
                    narrow_jobs += gen_job_str(access[2], src_addr, dst_addr)
            emit_jobs(wide_jobs, out_dir, traffic_name, x * NUM_Y + y)
            emit_jobs(narrow_jobs, out_dir, traffic_name, x * NUM_Y + y + 100)

def gen_traffic_cfg(
    traffic_cfg: str,
    floonoc_cfg: str,
    traffic_name: str,
    out_dir: str,
    **_kwargs
):
    # pylint: disable=too-many-arguments, too-many-locals, too-many-branches, too-many-statements, too-many-positional-arguments
    """Load FlooNoC configuration and create FlooNoC model using FlooGen."""
    floonoc_model = None
    if floonoc_cfg:
        floonoc_model = create_floonoc_model(floonoc_cfg)
    else:
        raise ValueError(f"FlooNoC configuration file not provided")

    """Load traffic stream configuration and create traffic model."""
    traffic_model = None
    if traffic_cfg:
        traffic_model = create_traffic_model(traffic_cfg, floonoc_model)
        if traffic_model is None:
            raise RuntimeError("Failed to create traffic model")
        print_traffic_model(traffic_model)
    else:
        raise ValueError(f"Traffic configuration file not provided")

    """Generate traffic jobs."""
    for flow in traffic_model.traffic_flows:
        wide_jobs = ""
        narrow_jobs = ""
        local_addr = flow.initiator_addr
        ext_addr = flow.endpoint_addr
        if local_addr is None or ext_addr is None:
            print(f"Warning: Skipping flow '{flow.name}' due to unresolved addresses")
            continue
        src_addr = ext_addr  if flow.rw == "read"  else local_addr
        dst_addr = local_addr if flow.rw == "read" else ext_addr
        for burst in flow.wide_burst:
            if burst.data_width is not None:
                wide_length = burst.length * burst.data_width / 8
                assert wide_length <= MEM_SIZE
                for _ in range(burst.number):
                    wide_jobs += gen_job_str(wide_length, src_addr, dst_addr)
            else:
                print(f"Warning: No wide interface was detected, skipping wide burst generation for traffic flow '{flow.name}'")
        for burst in flow.narrow_burst:
            if burst.data_width is not None:
                narrow_length = burst.length * burst.data_width / 8
                assert narrow_length <= MEM_SIZE
                for _ in range(burst.number):
                    narrow_jobs += gen_job_str(narrow_length, src_addr, dst_addr)
            else:
                print(f"Warning: No narrow interface was detected, skipping narrow burst generation for traffic flow '{flow.name}'")
        x = flow.initiator[0]
        y = flow.initiator[1]
        floonoc_num_x = floonoc_model.routers[0].array[0]
        floonoc_num_y = floonoc_model.routers[0].array[1]
        idx = x * floonoc_num_y + y
        emit_jobs(wide_jobs, out_dir, traffic_name, idx)
        print(f"Emitted wide job with index {idx} (x: {x}, y: {y})")
        emit_jobs(narrow_jobs, out_dir, traffic_name, idx + 100)
        print(f"Emitted narrow job with index {idx + 100} (x: {x}, y: {y})")


def main():
    """Main function."""
    # parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--out_dir", type=str, default="test/jobs")
    parser.add_argument("--num_narrow_bursts", type=int, default=10)
    parser.add_argument("--num_wide_bursts", type=int, default=100)
    parser.add_argument("--narrow_burst_length", type=int, default=1)
    parser.add_argument("--wide_burst_length", type=int, default=16)
    parser.add_argument("--bidir", action="store_true")
    parser.add_argument("--tb", type=str, default="dma_mesh")
    parser.add_argument("--traffic_name", type=str, default="mesh")
    parser.add_argument("--traffic_type", type=str, default="uniform")
    parser.add_argument("--traffic_cfg", type=str, default="traffic.yml")
    parser.add_argument("--rw", type=str, default="read")
    parser.add_argument("--floonoc_cfg", type=str, default=None)
    args = parser.parse_args()

    kwargs = vars(args)

    if args.tb == "chimney2chimney":
        gen_chimney2chimney_traffic(**kwargs)
    elif args.tb == "nw_chimney2chimney":
        gen_nw_chimney2chimney_traffic(**kwargs)
    elif args.tb == "dma_mesh":
        gen_mesh_traffic(**kwargs)
    elif args.tb == "import_traffic_cfg":
        gen_traffic_cfg(**kwargs)
    else:
        raise ValueError(f"Unknown testbench: {args.tb}")


if __name__ == "__main__":
    main()
