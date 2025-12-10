#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import argparse
from pathlib import Path
from importlib.resources import files

from mako.template import Template

from floogen.config_parser import parse_config
from floogen.query import handle_query
from floogen.model.network import Network
from floogen.utils import verible_format

tpl_dir = files("floogen") / "templates"

def render_template(context: dict, tpl: Path,
                    outdir: Path = None, file_name: str = None,
                    format_output: bool=False, verible_fmt_bin: str = None,
                    verible_fmt_args: str = None):
    """Render a template, format if requested and write to file or print to stdout."""
    if not tpl.exists():
        # Search in the internal template directory if the template exists there
        if (tpl_dir / tpl.name).exists():
            tpl = tpl_dir / tpl.name
        else:
            raise FileNotFoundError(f"Template not found: {tpl}")
    rendered = Template(filename=str(tpl.resolve())).render(**context)
    if format_output:
        rendered = verible_format(rendered, verible_fmt_bin, verible_fmt_args)
    if outdir:
        outdir.mkdir(parents=True, exist_ok=True)
        if file_name:
            outfile = outdir / file_name
        else:
            outfile = outdir / tpl.stem
        with open(outfile, "w+", encoding="utf-8") as f:
            f.write(rendered)
    else:
        print(rendered)


def build_parser() -> argparse.ArgumentParser:
    """Parse the command line arguments."""

    # Parser that holds all common options (no help, reused)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "-c", "--config", type=Path, required=True,
        help="Path to the configuration file."
    )
    common.add_argument(
        "-o", "--outdir", type=Path, required=False,
        help=(
            "Path to the output directory of the generated output files. "
            "If not specified, the files are printed to stdout."
        ),
    )
    sv_format = argparse.ArgumentParser(add_help=False)
    sv_format.add_argument(
        "--no-format",
        dest="no_format",
        action="store_true",
        help="Do not format the output.",
    )
    sv_format.add_argument(
        "--verible-fmt-bin",
        type=str,
        default=None,
        help="Overwrite default `verible-verilog-format` binary.",
    )
    sv_format.add_argument(
        "--verible-fmt-args",
        type=str,
        default=None,
        help="Additional arguments to pass to `verible-verilog-format`.",
    )
    sv_format.add_argument(
        "--name",
        type=str,
        default=None,
        help="Override the module/package name and prefix for generated files."
    )

    # Top-level parser ALSO gets the common options so
    # `floogen -c cfg.yaml` works without subcommand.
    parser = argparse.ArgumentParser(
        description="FlooGen: A Network-on-Chip Generator for FlooNoC",
        add_help=True,
    )

    subparsers = parser.add_subparsers(dest="command")

    # floogen all -> pkg + top
    subparsers.add_parser(
        "all",
        parents=[common, sv_format],
        add_help=True,
        help="Generate both the NoC package and top-module.",
    )

    # floogen pkg
    subparsers.add_parser(
        "pkg",
        parents=[common, sv_format],
        add_help=True,
        help="Generate the NoC package.",
    )

    # floogen top
    subparsers.add_parser(
        "top",
        parents=[common, sv_format],
        add_help=True,
        help="Generate the NoC top-module.",
    )

    # floogen rdl
    p_rdl = subparsers.add_parser(
        "rdl",
        parents=[common],
        add_help=True,
        help="Generate the SystemRDL of all endpoint address regions.",
    )
    p_rdl.add_argument(
        "--as-mem",
        dest="as_mem",
        action="store_true",
        default=False,
        help="Add memory blocks for address regions without 'rdl_name' declared.",
    )
    p_rdl.add_argument(
        "--memwidth",
        dest="memwidth",
        type=int,
        default=8,
        help="Use the memory width of the RDL address region as the width of the memory block.",
    )

    # floogen visualize
    subparsers.add_parser(
        "visualize",
        parents=[common],
        add_help=True,
        help="Visualize the network graph.",
    )

    # floogen query <key>
    p_query = subparsers.add_parser(
        "query",
        parents=[common],
        add_help=True,
        help="Query a specific key in the configuration.",
    )
    p_query.add_argument(
        "query",
        type=str,
        help="Key to query in the configuration.",
    )

    # floogen templates <template1> <template2> ...
    p_templates = subparsers.add_parser(
        "template",
        parents=[common, sv_format],
        add_help=True,
        help="Render only external templates.",
    )
    p_templates.add_argument(
        "template",
        type=Path,
        nargs="+",
        help="Path to external template to render. Multiple templates can be specified.",
    )

    return parser


def main():
    """Generates the network."""

    parser = build_parser()
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 0

    network = parse_config(Network, args.config)

    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    # The general context to pass to all templates
    context = {"noc": network}

    # Additional render arguments
    render_kwargs = {"outdir": args.outdir}

    # Command specific render arguments
    match args.command:
        case "all" | "pkg" | "top" | "template":
            render_kwargs["format_output"] = not args.no_format
            render_kwargs["verible_fmt_bin"] = args.verible_fmt_bin
            render_kwargs["verible_fmt_args"] = args.verible_fmt_args
            context["name"] = args.name or network.name
            pkg_file_name = f"floo_{args.name or network.name}_noc_pkg.sv"
            top_file_name = f"floo_{args.name or network.name}_noc.sv"
        case "rdl":
            rdl_file_name = f"{network.name}_addrmap.rdl"


    match args.command:
        case "all":
            render_template(context,
                tpl=tpl_dir / "floo_noc_pkg.sv.mako",
                file_name=pkg_file_name,
                **render_kwargs,
            )
            render_template(context,
                tpl=tpl_dir / "floo_noc.sv.mako",
                file_name=top_file_name,
                **render_kwargs,
            )
        case "pkg":
            render_template(context,
                tpl=tpl_dir / "floo_noc_pkg.sv.mako",
                file_name=pkg_file_name,
                **render_kwargs,
            )
        case "top":
            render_template(context,
                tpl=tpl_dir / "floo_noc.sv.mako",
                file_name=top_file_name,
                **render_kwargs,
            )
        case "rdl":
            context["rdl_as_mem"] = args.as_mem
            context["rdl_memwidth"] = args.memwidth
            render_template(context,
                tpl=tpl_dir / "floo_addrmap.rdl.mako",
                file_name=rdl_file_name,
                **render_kwargs,
            )
        case "template":
            for tpl in args.template:
                render_template(context,
                    tpl=tpl,
                    **render_kwargs,
                )
        case "visualize":
            if args.outdir:
                network.visualize(filename=args.outdir / (network.name + ".pdf"))
            else:
                network.visualize(savefig=False)
        case "query":
            handle_query(network, args.query)


if __name__ == "__main__":
    main()
