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
import re



def main():
    """Main function."""
    # parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--output_file", type=str, required=True)
    parser.add_argument("--results_file", type=str, required=True)
    parser.add_argument("--router_tb", type=str, required=True)

    parser.add_argument("--traffic_rw", type=str, required=True)
    args = parser.parse_args()
    assert os.path.exists(args.output_file), \
        "Error: output file does not exist"
    assert args.router_tb in ["tb_floo_dma_mesh", "tb_floo_vc_dma_mesh"], \
        "Error: router_tb not tb_floo_dma_mesh"
    assert "read" == args.traffic_rw or "write" == args.traffic_rw, \
        "Error: traffic_rw not read or write"


    monitors_n = []
    monitors_w = []

    monitor_regex = re.compile(r"# \[Monitor (wide|narrow)_dma_._.\]\[(Read|Write)\] " + \
        r"Latency: (\d+.\d+) \+- (\d+.\d+), BW: (\d+.\d+) Bits/cycle, Util: \d+.\d+%")

    # read the output file
    output = open(args.output_file, "r", encoding="utf8")
    output_lines = output.readlines()
    for line_index, line in enumerate(output_lines):
        regex_match = monitor_regex.match(line)
        if not regex_match:
            continue
        # check if legal: if traffic_rw == read: must be all 0 if Write
        [mtype, mrw, mlat, mlatstd, mbw] = regex_match.groups()
        # ignore all 0 lines:
        if(mlat == "0.00" and mlatstd == "0.00" and mbw == "0.00"):
            continue
        if((mrw == "Read" and args.traffic_rw == "write")
           or (mrw == "Write" and args.traffic_rw == "read")):
            print(f"Error: nonzero {mrw} monitor in {args.traffic_rw} experiment: ")
            print(f"Line {line_index}: {line}")
            return
        if(mtype == "narrow"):
            monitors_n.append([mlat, mlatstd, mbw])
        else:
            monitors_w.append([mlat, mlatstd, mbw])
    assert not output_lines[-2].startswith("# Errors: 0, Warnings:"), \
        "Error: simulation did not finish correctly"


    output.close()

    assert len(monitors_n) == len(monitors_w), "Error: number of monitors do not match"
    assert len(monitors_n) > 0, "Error: no monitors found"

    # process monitors
    n_lat = n_lat_std = n_bw = 0
    w_lat  = w_lat_std  = w_bw  = 0

    # variances add linearly -> square, add, sqrt
    for (mlat, mlatstd, mbw) in monitors_n:
        n_lat += float(mlat)
        n_lat_std += float(mlatstd) ** 2
        n_bw += float(mbw)

    for (mlat, mlatstd, mbw) in monitors_w:
        w_lat += float(mlat)
        w_lat_std += float(mlatstd) ** 2
        w_bw += float(mbw)

    n_lat_std = math.sqrt(n_lat_std)
    w_lat_std  = math.sqrt(w_lat_std)

    n_lat /= len(monitors_n)
    n_lat_std /= len(monitors_n)
    n_bw /= len(monitors_n)

    w_lat /= len(monitors_w)
    w_lat_std /= len(monitors_w)
    w_bw /= len(monitors_w)



#     - average nw latency
#     - average w latency
#     - average nw Bandwidth
#     - average w Bandwidth

    results = open(args.results_file, "a", encoding="utf8") # a for append
    if args.router_tb == "tb_floo_dma_mesh":
        results.write("Old router: ")
    else:
        results.write("VC router : ")
    results.write(f"[latency, std, BW]: narrow: [{n_lat:.2f}, {n_lat_std:.2f}, {n_bw:.2f}], \
wide: [{w_lat:.2f}, {w_lat_std:.2f}, {w_bw:.2f}]\n")
    results.close()


if __name__ == "__main__":
    main()
