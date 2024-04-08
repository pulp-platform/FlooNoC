#!/usr/bin/env python3
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Tim Fischer <fischeti@iis.ee.ethz.ch>

import random
import argparse
import os

MEM_SIZE = 2**16
NUM_X = 4
NUM_Y = 4

data_widths = {"wide": 512, "narrow": 64}


def clog2(x: int):
    """Compute the ceiling of the log2 of x."""
    return (x - 1).bit_length()


def get_xy_base_addr(x: int, y: int):
    """Get the address of a tile in the mesh."""
    assert x <= NUM_X+1 and y <= NUM_Y+1
    return (x + 2 ** clog2(NUM_X + 2) * y) * MEM_SIZE


def gen_job_str(
    length: int,
    src_addr: int,
    dst_addr: int,
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
    with open(f"{out_dir}/{name}_{idx}.txt", "w", encoding="utf-8") as job_file:
        job_file.write(jobs)
        job_file.close()


def gen_chimney2chimney_traffic(
    narrow_burst_length: int = 16,
    num_narrow_bursts: int = 16,
    rw: str = "write",
    bidir: bool = False,
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
        emit_jobs(jobs, out_dir, "chimney2chimney", i)


def gen_nw_chimney2chimney_traffic(
    narrow_burst_length: int,
    wide_burst_length: int,
    num_narrow_bursts: int,
    num_wide_bursts: int,
    rw: str,
    bidir: bool,
    out_dir: str
):
    # pylint: disable=too-many-arguments
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
        emit_jobs(wide_jobs, out_dir, "nw_chimney2chimney", i)
        emit_jobs(narrow_jobs, out_dir, "nw_chimney2chimney", i + 100)


def gen_mesh_traffic(
    narrow_burst_length: int,
    wide_burst_length: int,
    num_narrow_bursts: int,
    num_wide_bursts: int,
    rw: str,
    traffic_type: str,
    out_dir: str,
    **_kwargs
):
    # pylint: disable=too-many-arguments, too-many-locals
    """Generate Mesh traffic."""
    for x in range(1, NUM_X + 1):
        for y in range(1, NUM_Y + 1):
            wide_jobs = ""
            narrow_jobs = ""
            wide_length = wide_burst_length * data_widths["wide"] / 8
            narrow_length = narrow_burst_length * data_widths["narrow"] / 8
            assert wide_length <= MEM_SIZE and narrow_length <= MEM_SIZE
            if traffic_type == "hbm":
                # Tile x=0 are the HBM channels
                # Each core read from the channel of its y coordinate
                hbm_addr = get_xy_base_addr(0, y)
                local_addr = get_xy_base_addr(x, y)
                src_addr = hbm_addr if rw == "read" else local_addr
                dst_addr = local_addr if rw == "read" else hbm_addr
            elif traffic_type == "random":
                local_addr = get_xy_base_addr(x, y)
                ext_addr = get_xy_base_addr(random.randint(1, NUM_X), random.randint(1, NUM_Y))
                src_addr = ext_addr if rw == "read" else local_addr
                dst_addr = local_addr if rw == "read" else ext_addr
            elif traffic_type == "onehop":
                if not (x == 1 and y == 1):
                    wide_length = 0
                    narrow_length = 0
                    src_addr = 0
                    dst_addr = 0
                else:
                    local_addr = get_xy_base_addr(x, y)
                    ext_addr = get_xy_base_addr(x, y + 1)
                    src_addr = ext_addr if rw == "read" else local_addr
                    dst_addr = local_addr if rw == "read" else ext_addr
            else:
                raise ValueError(f"Unknown traffic type: {traffic_type}")
            for _ in range(num_wide_bursts):
                wide_jobs += gen_job_str(wide_length, src_addr, dst_addr)
            for _ in range(num_narrow_bursts):
                narrow_jobs += gen_job_str(narrow_length, src_addr, dst_addr)
            emit_jobs(wide_jobs, out_dir, "mesh", x + (y - 1) * NUM_X)
            emit_jobs(narrow_jobs, out_dir, "mesh", x + (y - 1) * NUM_X + 100)


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
    parser.add_argument("--traffic_type", type=str, default="random")
    parser.add_argument("--rw", type=str, default="read")
    args = parser.parse_args()

    kwargs = vars(args)

    if args.tb == "chimney2chimney":
        gen_chimney2chimney_traffic(**kwargs)
    elif args.tb == "nw_chimney2chimney":
        gen_nw_chimney2chimney_traffic(**kwargs)
    elif args.tb == "dma_mesh":
        gen_mesh_traffic(**kwargs)
    else:
        raise ValueError(f"Unknown testbench: {args.tb}")


if __name__ == "__main__":
    main()
