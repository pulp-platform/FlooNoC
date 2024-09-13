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
from floogen.model.network import Network
from floogen.utils import verible_format


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
        help="Path to the output directory of the generated output.",
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


def main(): # pylint: disable=too-many-branches
    """Generates the network."""
    args = parse_args()
    network = parse_config(Network, args.config)

    if args.outdir:
        outdir = Path(os.getcwd(), args.outdir)
    else:
        # default output directory
        outdir = Path(os.getcwd(), "generated")

    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    # Visualize the network graph
    if args.visualize:
        if outdir:
            network.visualize(filename=outdir / (network.name + ".pdf"))
        else:
            network.visualize(savefig=False)

    # Generate the network description
    rendered_top = network.render_network()
    if not args.no_format:
        rendered_top = verible_format(rendered_top)
    # Write the network description to file or print it to stdout
    if outdir:
        outdir.mkdir(parents=True, exist_ok=True)
        top_file_name = outdir / f"floo_{network.name}_noc.sv"
        with open(top_file_name, "w+", encoding="utf-8") as top_file:
            top_file.write(rendered_top)
    else:
        print(rendered_top)


if __name__ == "__main__":
    main()
