# Copyright 2023 ETH Zurich and University of Bologna
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import pathlib
import shutil
import subprocess

from floogen.config_parser import parse_config
from floogen.model.network import Network


def parse_args():
    """Parse the command line arguments."""
    parser = argparse.ArgumentParser(description="FlooGen: A Network-on-Chip Generator")
    parser.add_argument(
        "-c", "--config", type=pathlib.Path, required=True, help="Path to the configuration file."
    )
    parser.add_argument(
        "-o", "--output", type=pathlib.Path, required=False, help="Path to the output directory."
    )
    parser.add_argument(
        "--no_formatting",
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

    # Visualize the network graph
    if args.visualize:
        network.visualize()

    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    # Generate the network description
    rendered_top = network.render_network()
    rendered_cfg = network.render_link_cfg()
    if  not args.no_formatting:
        if shutil.which("verible-verilog-format") is None:
            raise RuntimeError(
                "verible-verilog-format not found. Please install it to use the --format option."
            )
        # Format the output using verible-verilog-format, by piping it into the stdin
        # of the formatter and capturing the stdout
        rendered_top = subprocess.run(
            ["verible-verilog-format", "-"],
            input=rendered_top,
            capture_output=True,
            text=True,
            check=True,
        ).stdout

    # Write the network description to file or print it to stdout
    if args.output:
        # Create the output directory if it does not exist
        args.output.mkdir(parents=True, exist_ok=True)
        top_file_name = args.output / (network.name + "_floo_noc.sv")
        cfg_file_name = args.output / ("narrow_wide_cfg.hjson")
        with open(top_file_name, "w+", encoding="utf-8") as top_file:
            top_file.write(rendered_top)
        with open(cfg_file_name, "w+", encoding="utf-8") as cfg_file:
            cfg_file.write(rendered_cfg)
    else:
        print(rendered_top)
        print(rendered_cfg)


if __name__ == "__main__":
    main()
