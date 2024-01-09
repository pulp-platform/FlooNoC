#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import argparse
import pathlib

from floogen.config_parser import parse_config
from floogen.model.network import Network
from floogen.utils import verible_format


def parse_args():
    """Parse the command line arguments."""
    parser = argparse.ArgumentParser(description="FlooGen: A Network-on-Chip Generator")
    parser.add_argument(
        "-c", "--config", type=pathlib.Path, required=True, help="Path to the configuration file."
    )
    parser.add_argument(
        "-o",
        "--outdir",
        type=pathlib.Path,
        required=False,
        help="Path to the output directory of the generated output.",
    )
    parser.add_argument(
        "--pkg-outdir",
        dest="pkg_outdir",
        type=pathlib.Path,
        required=False,
        default=pathlib.Path(__file__).parent.parent / "hw",
        help="Path to the output directory of the generated output.",
    )
    parser.add_argument(
        "--only-pkg",
        dest="only_pkg",
        action="store_true",
        help="Only generate the package file."
    )
    parser.add_argument(
        "--no-format",
        dest="no_format",
        action="store_true",
        help="Do not format the output.",
    )
    parser.add_argument("--visualize", action="store_true", help="Visualize the network graph.")
    args = parser.parse_args()
    return args


def main():
    """Generates the network."""
    args = parse_args()
    network = parse_config(Network, args.config)


    if not args.only_pkg:
        network.create_network()
        network.compile_network()
        network.gen_routing_info()

        # Visualize the network graph
        if args.visualize:
            if args.outdir:
                network.visualize(filename=args.outdir / (network.name + ".pdf"))
            else:
                network.visualize(savefig=False)

        # Generate the network description
        rendered_top = network.render_network()
        if not args.no_format:
            rendered_top = verible_format(rendered_top)
        # Write the network description to file or print it to stdout
        if args.outdir:
            args.outdir.mkdir(parents=True, exist_ok=True)
            top_file_name = args.outdir / (network.name + "_floo_noc.sv")
            with open(top_file_name, "w+", encoding="utf-8") as top_file:
                top_file.write(rendered_top)
        else:
            print(rendered_top)

    axi_type, rendered_pkg = network.render_link_cfg()
    if not args.no_format:
        rendered_pkg = verible_format(rendered_pkg)
        # Write the link configuration to file or print it to stdout
        if args.pkg_outdir:
            cfg_file_name = args.pkg_outdir / (f"floo_{axi_type}_pkg.sv")
            with open(cfg_file_name, "w+", encoding="utf-8") as cfg_file:
                cfg_file.write(rendered_pkg)
        else:
            print(rendered_pkg)


if __name__ == "__main__":
    main()
