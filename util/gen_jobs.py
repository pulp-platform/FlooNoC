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


# GarnetSyntheticTraffic::generatePkt() {
#     int num_destinations = numDestinations;
#     int radix = (int) sqrt(num_destinations);
#     unsigned destination = id;
#     int dest_x = -1;
#     int dest_y = -1;
#     int source = id;
#     int src_x = id%radix;
#     int src_y = id/radix;
#     if (singleDest >= 0) {
#         destination = singleDest;
#     } else if (traffic == UNIFORM_RANDOM_) {
#         destination = random_mt.random<unsigned>(0, num_destinations - 1);
#     } else if (traffic == BIT_COMPLEMENT_) {
#         dest_x = radix - src_x - 1;
#         dest_y = radix - src_y - 1;
#         destination = dest_y*radix + dest_x;
#     } else if (traffic == BIT_REVERSE_) {
#         unsigned int straight = source;
#         unsigned int reverse = source & 1; // LSB
#         int num_bits = (int) log2(num_destinations);
#         for (int i = 1; i < num_bits; i++) {
#             reverse <<= 1;
#             straight >>= 1;
#             reverse |= (straight & 1); // LSB }
#         destination = reverse;
#     } else if (traffic == BIT_ROTATION_) {
#         if (source%2 == 0)
#             destination = source/2;
#         else // (source%2 == 1)
#             destination = ((source/2) + (num_destinations/2));
#     } else if (traffic == NEIGHBOR_) {
#         dest_x = (src_x + 1) % radix;
#         dest_y = src_y;
#         destination = dest_y*radix + dest_x;
#     } else if (traffic == SHUFFLE_) {
#         if (source < num_destinations/2) destination = source*2;
#         else destination = (source*2 - num_destinations + 1);
#     } else if (traffic == TRANSPOSE_) {
#         dest_x = src_y;
#         dest_y = src_x;
#         destination = dest_y*radix + dest_x;
#     } else if (traffic == TORNADO_) {
#         dest_x = (src_x + (int) ceil(radix/2) - 1) % radix;
#         dest_y = src_y;
#         destination = dest_y*radix + dest_x; }

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
    # pylint: disable=too-many-arguments, too-many-locals, too-many-branches, too-many-statements
    """Generate Mesh traffic."""
    for x in range(1, NUM_X + 1):
        for y in range(1, NUM_Y + 1):
            wide_jobs = ""
            narrow_jobs = ""
            wide_length = wide_burst_length * data_widths["wide"] / 8
            narrow_length = narrow_burst_length * data_widths["narrow"] / 8
            local_addr = get_xy_base_addr(x, y)
            assert wide_length <= MEM_SIZE and narrow_length <= MEM_SIZE
            if traffic_type == "hbm":
                # Tile x=0 are the HBM channels
                # Each core read from the channel of its y coordinate
                ext_addr = get_xy_base_addr(0, y)
            elif traffic_type == "random":
                ext_addr = local_addr
                while ext_addr == local_addr:
                    ext_addr = get_xy_base_addr(random.randint(1, NUM_X), random.randint(1, NUM_Y))
            elif traffic_type == "onehop":
                if not (x == 1 and y == 1):
                    wide_length = 0
                    narrow_length = 0
                    local_addr = 0
                    ext_addr = 0
                else:
                    ext_addr = get_xy_base_addr(x, y + 1)
            elif traffic_type == "bit_complement":
                ext_addr = get_xy_base_addr(NUM_X - x + 1, NUM_Y - y + 1)
            elif traffic_type == "bit_reverse":
                # in order to achieve same result as garnet:
                # change to space where addresses start at 0 and return afterwards
                straight = x-1 + (y-1) * NUM_X
                num_destinations = NUM_X * NUM_Y
                reverse = straight & 1  # LSB
                num_bits = clog2(num_destinations)
                for _ in range(1, num_bits):
                    reverse <<= 1
                    straight >>= 1
                    reverse |= (straight & 1)  # LSB
                ext_addr = get_xy_base_addr(reverse % NUM_X + 1, reverse // NUM_X + 1)
            elif traffic_type == "bit_rotation":
                source = x-1 + (y-1) * NUM_X
                num_destinations = NUM_X * NUM_Y
                if source % 2 == 0:
                    ext = source // 2
                else:  # (source % 2 == 1)
                    ext = (source // 2) + (num_destinations // 2)
                ext_addr = get_xy_base_addr(ext % NUM_X + 1, ext // NUM_X + 1)
            elif traffic_type == "neighbor":
                ext_addr = get_xy_base_addr(x % NUM_X + 1, y)
            elif traffic_type == "shuffle":
                source = x-1 + (y-1) * NUM_X
                num_destinations = NUM_X * NUM_Y
                if source < num_destinations // 2:
                    ext = source * 2
                else: ext = (source * 2) - num_destinations + 1
                ext_addr = get_xy_base_addr(ext % NUM_X + 1, ext // NUM_X + 1)
            elif traffic_type == "transpose":
                dest_x = y
                dest_y = x
                ext_addr = get_xy_base_addr(dest_x, dest_y)
            elif traffic_type == "tornado":
                dest_x = (x-1 + math.ceil(NUM_X / 2) - 1) % NUM_X + 1
                ext_addr = get_xy_base_addr(dest_x, y)
            else:
                raise ValueError(f"Unknown traffic type: {traffic_type}")
            src_addr = ext_addr if rw == "read" else local_addr
            dst_addr = local_addr if rw == "read" else ext_addr
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
