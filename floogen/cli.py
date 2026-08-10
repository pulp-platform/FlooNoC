#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import argparse
import json
import sys
from importlib.metadata import version
from importlib.util import find_spec
from pathlib import Path
from typing import TypedDict

from mako.template import Template

from floogen.config_parser import ConfigError, parse_config
from floogen.model.network import Network, config_json_schema
from floogen.model.traffic import MESH_TRAFFIC_TYPES, gen_traffic_builtin, gen_traffic_cfg
from floogen.query import handle_query
from floogen.utils import verible_format

tpl_dir = Path(__file__).parent / "templates"

SCHEMA_FILE_NAME = "floogen.schema.json"


class RenderKwargs(TypedDict, total=False):
    """Keyword arguments forwarded to `render_template`."""

    outdir: Path | None
    format_output: bool
    verible_fmt_bin: str | None
    verible_fmt_args: str | None


def render_template(
    context: dict,
    tpl: Path,
    outdir: Path | None = None,
    file_name: str | None = None,
    format_output: bool = False,
    verible_fmt_bin: str | None = None,
    verible_fmt_args: str | None = None,
):
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

    # Parser that holds all common options
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "-c", "--config", type=Path, required=True, help="Path to the configuration file."
    )
    common.add_argument(
        "-o",
        "--outdir",
        type=Path,
        required=False,
        help=(
            "Path to the output directory of the generated output files. "
            "If not specified, the files are printed to stdout."
        ),
    )
    common.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print detailed information about what the tool is doing.",
    )

    # Parser for SystemVerilog formatting options
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
        help="Override the module/package name and prefix for generated files.",
    )

    # Top-level parser
    parser = argparse.ArgumentParser(
        description="FlooGen: A Network-on-Chip Generator for FlooNoC",
        add_help=True,
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {version('floogen')}",
    )

    subparsers = parser.add_subparsers(dest="command", metavar="")

    # floogen rtl -> pkg + top
    subparsers.add_parser(
        "rtl",
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

    # floogen templates <template1> <template2> ...
    p_templates = subparsers.add_parser(
        "template",
        parents=[common, sv_format],
        add_help=True,
        help="Render custom (external) templates.",
    )
    p_templates.add_argument(
        "template",
        type=Path,
        nargs="+",
        help="Path to external template to render. Multiple templates can be specified.",
    )

    # floogen visualize (only available if the optional 'viz' extra is installed)
    if find_spec("matplotlib") is not None:
        subparsers.add_parser(
            "visualize",
            parents=[common],
            add_help=True,
            help="Visualize the network graph.",
        )

    # floogen traffic generation
    p_traffic = subparsers.add_parser(
        "traffic",
        parents=[common],
        add_help=True,
        help="Generate DMA job files from a traffic configuration file.",
    )
    p_traffic_src = p_traffic.add_mutually_exclusive_group(required=True)
    p_traffic_src.add_argument(
        "--traffic-cfg",
        dest="traffic_cfg",
        type=Path,
        help="Path to the traffic configuration file.",
    )
    p_traffic_src.add_argument(
        "--traffic-type",
        dest="traffic_type",
        type=str,
        choices=MESH_TRAFFIC_TYPES,
        help="Generate a built-in traffic pattern, not requiring any dedicated traffic configuration file. "
        "Available types: " + ", ".join(MESH_TRAFFIC_TYPES) + ".",
    )
    p_traffic.add_argument(
        "--traffic-name",
        dest="traffic_name",
        type=str,
        default=None,
        help="Base name of the emitted job files. Defaults to the traffic configuration filename. ",
    )
    p_traffic.add_argument(
        "--traffic-rw",
        dest="traffic_rw",
        type=str,
        default="write",
        choices=["read", "write"],
        help="Read or write transaction, only used with --traffic-type.",
    )
    p_traffic.add_argument(
        "--num-narrow-bursts",
        dest="num_narrow_bursts",
        type=int,
        default=10,
        help="Number of narrow bursts per node, only used with --traffic-type.",
    )
    p_traffic.add_argument(
        "--num-wide-bursts",
        dest="num_wide_bursts",
        type=int,
        default=100,
        help="Number of wide bursts per node, only used with --traffic-type.",
    )
    p_traffic.add_argument(
        "--narrow-burst-length",
        dest="narrow_burst_length",
        type=int,
        default=1,
        help="Narrow burst length, in beats, only used with --traffic-type.",
    )
    p_traffic.add_argument(
        "--wide-burst-length",
        dest="wide_burst_length",
        type=int,
        default=16,
        help="Wide burst length, in beats, only used with --traffic-type.",
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

    # floogen schema
    # Deliberately not built on `common`: this describes the shape of a configuration
    # file rather than reading one, so `--config` would make no sense.
    p_schema = subparsers.add_parser(
        "schema",
        add_help=True,
        help="Emit the JSON schema of the configuration file, for editor validation.",
    )
    p_schema.add_argument(
        "-o",
        "--outdir",
        type=Path,
        required=False,
        help=(
            f"Directory to write '{SCHEMA_FILE_NAME}' to. "
            "If not specified, the schema is printed to stdout."
        ),
    )
    # floogen help [<command>]
    p_help = subparsers.add_parser(
        "help",
        add_help=True,
        help="Show the help message of `floogen` or of a specific command.",
    )
    p_help.add_argument(
        "help_command",
        metavar="command",
        type=str,
        nargs="?",
        choices=list(subparsers.choices),
        help="Command to show the help message for. If omitted, the general help is shown.",
    )
    # Make the subcommand parsers accessible to `floogen help <command>`.
    p_help.set_defaults(subparsers=subparsers.choices)

    return parser


def main():
    """Generates the network."""

    parser = build_parser()
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 0

    # Handled before the config is read, since it does not need one.
    if args.command == "schema":
        schema = json.dumps(config_json_schema(), indent=2) + "\n"
        if args.outdir:
            args.outdir.mkdir(parents=True, exist_ok=True)
            (args.outdir / SCHEMA_FILE_NAME).write_text(schema, encoding="utf-8")
        else:
            print(schema, end="")

    if args.command == "help":
        if args.help_command is None:
            parser.print_help()
        else:
            args.subparsers[args.help_command].print_help()
        return 0

    try:
        network = parse_config(Network, args.config)
    except ConfigError as e:
        # `parse_config` has already reported the individual problems in detail; a traceback
        # would only bury them.
        print(f"floogen: {e}", file=sys.stderr)
        return 1

    network.create_network()
    network.compile_network()
    network.gen_routing_info()

    # The general context to pass to all templates
    context = {"noc": network}

    # Additional render arguments
    render_kwargs: RenderKwargs = {"outdir": args.outdir}

    # Command specific render arguments
    match args.command:
        case "rtl" | "pkg" | "top" | "template":
            render_kwargs["format_output"] = not args.no_format
            render_kwargs["verible_fmt_bin"] = args.verible_fmt_bin
            render_kwargs["verible_fmt_args"] = args.verible_fmt_args
            context["name"] = args.name or network.name
            pkg_file_name = f"floo_{args.name or network.name}_noc_pkg.sv"
            top_file_name = f"floo_{args.name or network.name}_noc.sv"
        case "traffic":
            traffic_outdir = args.outdir or Path("jobs")
            default_traffic_name = args.traffic_cfg.stem if args.traffic_cfg else "mesh"
            traffic_name = args.traffic_name or default_traffic_name

    match args.command:
        case "rtl":
            render_template(
                context,
                tpl=tpl_dir / "floo_noc_pkg.sv.mako",
                file_name=pkg_file_name,
                **render_kwargs,
            )
            render_template(
                context,
                tpl=tpl_dir / "floo_noc.sv.mako",
                file_name=top_file_name,
                **render_kwargs,
            )
        case "pkg":
            render_template(
                context,
                tpl=tpl_dir / "floo_noc_pkg.sv.mako",
                file_name=pkg_file_name,
                **render_kwargs,
            )
        case "top":
            render_template(
                context,
                tpl=tpl_dir / "floo_noc.sv.mako",
                file_name=top_file_name,
                **render_kwargs,
            )
        case "rdl":
            context["rdl_as_mem"] = args.as_mem
            context["rdl_memwidth"] = args.memwidth
            sam = network.routing_info.sam
            groups = sam.distinct_groups() or [None]
            for group in groups:
                suffix = f"_{group}" if group else ""
                context["sam"] = sam.filter_by_group(group) if group else sam
                context["suffix"] = suffix
                render_template(
                    context,
                    tpl=tpl_dir / "floo_addrmap.rdl.mako",
                    file_name=f"{network.name}_addrmap{suffix}.rdl",
                    **render_kwargs,
                )
        case "template":
            for tpl in args.template:
                render_template(
                    context,
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
        case "traffic":
            if args.traffic_cfg:
                gen_traffic_cfg(
                    args.traffic_cfg, network, traffic_name, traffic_outdir, verbose=args.verbose
                )
            else:
                gen_traffic_builtin(
                    args.traffic_type,
                    network,
                    traffic_name,
                    traffic_outdir,
                    args.num_narrow_bursts,
                    args.narrow_burst_length,
                    args.num_wide_bursts,
                    args.wide_burst_length,
                    args.traffic_rw,
                    verbose=args.verbose,
                )


if __name__ == "__main__":
    main()
