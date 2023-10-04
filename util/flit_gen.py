#!/usr/bin/env python3

# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Tim Fischer <fischeti@iis.ee.ethz.ch>

import argparse
import hjson
import pathlib
import math
from jsonref import JsonRef
from mako.lookup import TemplateLookup

AXI_CHANNELS = ["aw", "w", "b", "ar", "r"]

templates = TemplateLookup(directories=[pathlib.Path(__file__).parent],
                           output_encoding="utf-8")


def clog2(x: int) -> int:
    """Compute the ceil of the log2 of x."""
    return int(math.ceil(math.log(x, 2)))


def get_axi_chs(channel_mapping: dict, **kwargs) -> list:
    """Return all the AXI channels."""
    channels = []
    for axi_chs in channel_mapping.values():
        for key, values in axi_chs.items():
            for v in values:
                channels.append(f"{key}_{v}")
    return channels


def get_inverted_mapping(channel_mapping: dict, **kwargs) -> dict:
    """Return the mapping of the link."""
    mappings = {}
    for phys_ch, ch_types in channel_mapping.items():
        for ch_type, axi_chs in ch_types.items():
            for axi_ch in axi_chs:
                mappings.setdefault(ch_type, {})[axi_ch] = phys_ch
    return mappings


def get_axi_channel_sizes(aw: int, dw: int, iw: int, uw: int) -> dict:
    """Compute the AXI channel size in bits."""

    # Constant widths
    burst = 2
    resp = 2
    cache = 4
    prot = 3
    qos = 4
    region = 4
    len = 8
    size = 3
    atop = 6
    last = 1
    lock = 1

    if isinstance(iw, dict):
        iw = max(iw.values())

    axi_ch_size = {}
    axi_ch_size["aw"] = iw + aw + len + size + burst + lock + cache + \
        prot + qos + region + atop + uw
    axi_ch_size["w"] = dw + dw//8 + last + uw
    axi_ch_size["b"] = iw + resp + uw
    axi_ch_size["ar"] = iw + aw + len + size + burst + lock + cache + \
        prot + qos + region + uw
    axi_ch_size["r"] = iw + dw + resp + last + uw

    return axi_ch_size


def get_link_sizes(channel_mapping: dict, protocols: list, **kwargs) -> dict:
    """Infer the link sizes AXI channels and the mapping."""
    link_sizes = {}
    for phys_ch, axi_chs in channel_mapping.items():
        # Get all protocols that use this channel
        used_protocols = [p for p in protocols if p['name'] in axi_chs and p['direction'] == 'input']
        # Get only the exact AXI channels that are used by the link
        used_axi_chs = [axi_chs[p['name']] for p in used_protocols]
        # Get the sizes of the AXI channels
        axi_ch_sizes = [get_axi_channel_sizes(**p['params']) for p in used_protocols]
        link_message_sizes = []
        for used_axi_ch, axi_ch_size in zip(used_axi_chs, axi_ch_sizes):
            link_message_sizes += [axi_ch_size[ch] for ch in used_axi_ch]
        # Get the maximum size of the link
        link_sizes[phys_ch] = max(link_message_sizes)
    return link_sizes


def main():
    """Generate a flit packet package."""

    parser = argparse.ArgumentParser(
        description="Generate flit files for a given configuration")
    parser.add_argument("--config", "-c", type=pathlib.Path, required=True, help="Path to the config file")

    args = parser.parse_args()

    # Read HJSON description of System.
    with open(args.config, "r") as f:
        cfg = JsonRef.replace_refs(hjson.load(f))

    kwargs = cfg
    kwargs['axi_channels'] = get_axi_chs(**kwargs)
    kwargs['header']['axi_ch'] = clog2(len(get_axi_chs(**kwargs)))
    kwargs['inv_map'] = get_inverted_mapping(**kwargs)
    kwargs['get_axi_channel_sizes'] = get_axi_channel_sizes
    kwargs['link_sizes'] = get_link_sizes(**kwargs)

    tpl = templates.get_template("floo_flit_pkg.sv.mako")
    print(tpl.render_unicode(**kwargs))


if __name__ == "__main__":
    main()
