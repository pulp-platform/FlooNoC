#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Randomly generates job files."""
import random
import argparse
import os

MEM_SIZE = 2**16
NUM_X = 4
NUM_Y = 4

data_widths = {'wide': 512, 'narrow': 64}


def clog2(x: int):
    """Compute the ceiling of the log2 of x."""
    return (x - 1).bit_length()


def get_xy_base_addr(x: int, y: int):
    """Get the address of a tile in the mesh."""
    assert (x <= NUM_X and y <= NUM_Y)
    return (x + 2**clog2(NUM_X+1)*y)*MEM_SIZE


def gen_job_str(length: int,
                src_addr: int,
                dst_addr: int,
                max_src_burst_size: int = 256,
                max_dst_burst_size: int = 256,
                r_aw_decouple: bool = False,
                r_w_decouple: bool = False,
                num_errors: int = 0):
    """Generate a single job."""
    job_str = ""
    job_str += f"{int(length)}\n"
    job_str += f"{hex(src_addr)}\n"
    job_str += f"{hex(dst_addr)}\n"
    job_str += f"{max_src_burst_size}\n"
    job_str += f"{max_dst_burst_size}\n"
    job_str += f"{int(r_aw_decouple)}\n"
    job_str += f"{int(r_w_decouple)}\n"
    job_str += f"{num_errors}\n"
    return job_str


def emit_jobs(jobs, out_dir, name, id):
    # Generate directory if it does not exist
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    with open(f'{out_dir}/{name}_{id}.txt', 'w', encoding='utf-8') as job_file:
        job_file.write(jobs)
        job_file.close()


def gen_chimney2chimney_traffic(data_width: int = data_widths['narrow'],
                                burst_length: int = 16,
                                num_bursts: int = 16,
                                rw: str = 'write',
                                bidir: bool = False,
                                outdir: str = 'jobs'):
    """Generate Chimney to Chimney traffic."""
    num_masters = 2
    for i in range(num_masters):
        jobs = ""
        if bidir or i == 0:
            for j in range(num_bursts):
                length = burst_length*data_width/8
                assert (length <= MEM_SIZE)
                src_addr = 0 if rw == 'write' else MEM_SIZE
                dst_addr = MEM_SIZE if rw == 'write' else 0
                job_str = gen_job_str(length, src_addr, dst_addr)
                jobs += job_str
        emit_jobs(jobs, outdir, 'chimney2chimney', i)


def gen_nw_chimney2chimney_traffic(data_widths: dict = data_widths,
                                   burst_lengths: dict = {'wide': 16, 'narrow': 1},
                                   num_bursts: dict = {'wide': 100, 'narrow': 1},
                                   rw: str = 'write',
                                   bidir: bool = False,
                                   outdir: str = 'jobs'):
    """Generate Narrow Wide Chimney to Chimney traffic."""
    num_masters = 2
    for i in range(num_masters):
        wide_jobs = ""
        narrow_jobs = ""
        wide_length = burst_lengths['wide']*data_widths['wide']/8
        narrow_length = burst_lengths['narrow']*data_widths['narrow']/8
        assert (wide_length <= MEM_SIZE and narrow_length <= MEM_SIZE)
        src_addr = 0 if rw == 'write' else MEM_SIZE
        dst_addr = MEM_SIZE if rw == 'write' else 0
        if bidir or i == 0:
            for j in range(num_bursts['wide']):
                wide_jobs += gen_job_str(wide_length, src_addr, dst_addr)
            for j in range(num_bursts['narrow']):
                narrow_jobs += gen_job_str(narrow_length, src_addr, dst_addr)
        emit_jobs(wide_jobs, outdir, 'nw_chimney2chimney', i)
        emit_jobs(narrow_jobs, outdir, 'nw_chimney2chimney', i+100)


def gen_mesh_traffic(data_widths: dict = data_widths,
                     burst_lengths: dict = {'wide': 16, 'narrow': 1},
                     num_bursts: dict = {'wide': 100, 'narrow': 1},
                     rw: str = 'write',
                     traffic_type: str = 'hbm',
                     outdir: str = 'jobs'):
    """Generate Mesh traffic."""
    for x in range(1, NUM_X+1):
        for y in range(1, NUM_Y+1):
            wide_jobs = ""
            narrow_jobs = ""
            wide_length = burst_lengths['wide']*data_widths['wide']/8
            narrow_length = burst_lengths['narrow']*data_widths['narrow']/8
            assert (wide_length <= MEM_SIZE and narrow_length <= MEM_SIZE)
            if traffic_type == 'hbm':
                # Tile x=0 are the HBM channels
                # Each core read from the channel of its y coordinate
                hbm_addr = get_xy_base_addr(0, y)
                local_addr = get_xy_base_addr(x, y)
                src_addr = hbm_addr if rw == 'read' else local_addr
                dst_addr = local_addr if rw == 'read' else hbm_addr
            elif traffic_type == 'random':
                local_addr = get_xy_base_addr(x, y)
                ext_addr = get_xy_base_addr(random.randint(1, NUM_X), random.randint(1, NUM_Y))
                src_addr = ext_addr if rw == 'read' else local_addr
                dst_addr = local_addr if rw == 'read' else ext_addr
            elif traffic_type == 'onehop':
                if not (x == 1 and y == 1):
                    wide_length = 0
                    narrow_length = 0
                    src_addr = 0
                    dst_addr = 0
                else:
                    local_addr = get_xy_base_addr(x, y)
                    ext_addr = get_xy_base_addr(x, y+1)
                    src_addr = ext_addr if rw == 'read' else local_addr
                    dst_addr = local_addr if rw == 'read' else ext_addr
            else:
                raise ValueError(f'Unknown traffic type: {traffic_type}')
            for j in range(num_bursts['wide']):
                wide_jobs += gen_job_str(wide_length, src_addr, dst_addr)
            for j in range(num_bursts['narrow']):
                narrow_jobs += gen_job_str(narrow_length, src_addr, dst_addr)
            emit_jobs(wide_jobs, outdir, 'mesh', x + (y-1)*NUM_X)
            emit_jobs(narrow_jobs, outdir, 'mesh', x + (y-1)*NUM_X + 100)


def main():

    # parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--out_dir', type=str, default='test/jobs')
    parser.add_argument('--num_narrow_bursts', type=int, default=0)
    parser.add_argument('--num_wide_bursts', type=int, default=100)
    parser.add_argument('--narrow_burst_length', type=int, default=1)
    parser.add_argument('--wide_burst_length', type=int, default=16)
    parser.add_argument('--bidir', action='store_true')
    parser.add_argument('--traffic_type', type=str, default='mesh')
    args = parser.parse_args()

    num_bursts = {'narrow': args.num_narrow_bursts, 'wide': args.num_wide_bursts}
    burst_lengths = {'wide': args.wide_burst_length, 'narrow': args.narrow_burst_length}

    if args.traffic_type == 'chimney2chimney':
        gen_chimney2chimney_traffic(data_widths['narrow'], burst_lengths['narrow'], num_bursts['narrow'], rw='write',
                                    bidir=args.bidir, outdir=args.out_dir)
    elif args.traffic_type == 'nw_chimney2chimney':
        gen_nw_chimney2chimney_traffic(data_widths, burst_lengths, num_bursts, rw='read',
                                       bidir=args.bidir, outdir=args.out_dir)
    elif args.traffic_type == 'mesh':
        gen_mesh_traffic(data_widths, burst_lengths, num_bursts, rw='read',
                         traffic_type='hbm', outdir=args.out_dir)
    else:
        raise ValueError(f'Unknown traffic type: {args.traffic_type}')


if __name__ == "__main__":
    main()
