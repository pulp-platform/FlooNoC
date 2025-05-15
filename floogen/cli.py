#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import os
import argparse
from pathlib import Path

from floogen.config_parser import parse_config
from floogen.query import handle_query
from floogen.model.network import Network
from floogen.utils import verible_format


# pylint: disable=too-many-branches
def render_sources(network: Network, args: argparse.Namespace):
    """Render the sources for the network."""

    # Create the output directory if it doesn't exist
    if args.outdir:
        outdir = Path(args.outdir)
        if not outdir.is_absolute():
            outdir = Path(os.getcwd(), outdir)
        outdir.mkdir(parents=True, exist_ok=True)

    # Visualize the network graph
    if args.visualize:
        if args.outdir:
            network.visualize(filename=outdir / (network.name + ".pdf"))
        else:
            network.visualize(savefig=False)

    # Generate the network description
    rendered_pkg = network.render_package()
    rendered_top = network.render_network()

    # Format the output if requested
    if not args.no_format:
        rendered_top = verible_format(rendered_top, args.verible_fmt_bin, args.verible_fmt_args)
        rendered_pkg = verible_format(rendered_pkg, args.verible_fmt_bin, args.verible_fmt_args)

    # Write the network description to file or print it to stdout
    if args.outdir:
        if not args.only_top and not args.rdl:
            pkg_file_name = outdir / f"floo_{network.name}_noc_pkg.sv"
            with open(pkg_file_name, "w+", encoding="utf-8") as pkg_file:
                pkg_file.write(rendered_pkg)
        if not args.only_pkg and not args.rdl:
            top_file_name = outdir / f"floo_{network.name}_noc.sv"
            with open(top_file_name, "w+", encoding="utf-8") as top_file:
                top_file.write(rendered_top)
        if args.rdl:
            rdl_file_name = outdir / f"{network.name}.rdl"
            with open(rdl_file_name, "w+", encoding="utf-8") as rdl_file:
                rdl_file.write(network.render_rdl())
    else:
        if not args.only_top and not args.rdl:
            print(rendered_pkg)
        if not args.only_pkg and not args.rdl:
            print(rendered_top)
        if args.rdl:
            print(network.render_rdl())


def parse_args():
    """Parse the command line arguments."""
    parser = argparse.ArgumentParser(description="FlooGen: A Network-on-Chip Generator")
    parser.add_argument(
        "-c", "--config", type=Path, required=True, help="Path to the configuration file."
    )
    parser.add_argument(
        "-o",
        "--outdir",
        type=Path,
        required=False,
        help=(
            "Path to the output directory of the generated output files. "
            "If not specified, the files are printed to stdout."
        ),
    )
    parser.add_argument(
        "--only-pkg",
        dest="only_pkg",
        action="store_true",
        default=False,
        help="Only generate the NoC package.",
    )
    parser.add_argument(
        "--only-top",
        dest="only_top",
        action="store_true",
        default=False,
        help="Only generate the NoC top-module.",
    )
    parser.add_argument(
        "--rdl",
        dest="rdl",
        action="store_true",
        default=False,
        help="Generate the system's RDL.",
    )
    parser.add_argument(
        "--no-format",
        dest="no_format",
        action="store_true",
        help="Do not format the output.",
    )
    parser.add_argument(
        "--verible-fmt-bin",
        type=str,
        default=None,
        help="Overwrite default `verible-verilog-format` binary.",
    )
    parser.add_argument(
        "--verible-fmt-args",
        type=str,
        default=None,
        help="Additional arguments to pass to `verible-verilog-format`.",
    )
    parser.add_argument("--visualize", action="store_true", help="Visualize the network graph.")
    parser.add_argument(
        "-q", "--query", type=str, help="Query a specific key in the configuration."
    )

    return parser.parse_args()


def main():
    """Generates the network."""

    args = parse_args()

    network = parse_config(Network, args.config)

    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    if args.query:
        handle_query(network, args.query)
    else:
        render_sources(network, args)


if __name__ == "__main__":
    main()
