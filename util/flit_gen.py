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


def clog2(x):
    """Compute the ceil of the log2 of x."""
    return int(math.ceil(math.log(x, 2)))


def calc_axi_ch_size(aw, dw, iw, uw):
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


def invert_map(map: list):
    """Invert a list of lists."""
    inv_map = {}
    for phys_chan, axi_chans in map.items():
        for axi_ch in axi_chans:
            inv_map[axi_ch] = phys_chan
    return inv_map


def axi_channel_ordering(map: list):
    """Return the ordering of the AXI channels."""
    ordering = []
    for phys_chan, axi_chans in map.items():
        for axi_ch in axi_chans:
            ordering.append(axi_ch)
    return ordering


def calc_channel_size(cfg):

    rsvd_bits = {}
    axi_ch_size = {}
    phys_ch_size = {}

    for axi_ch in cfg['axi_channels']:
        axi_ch_size[axi_ch['name']] = calc_axi_ch_size(**axi_ch['params'])

    for phys_ch, axi_chans in cfg['map'].items():
        axi_chans_size = []
        for axi_ch in axi_chans:
            type = '_'.join(axi_ch.split('_')[:2])
            ch = axi_ch.split("_")[-1]
            axi_chans_size.append(axi_ch_size[type][ch])
        phys_ch_size[phys_ch] = max(axi_chans_size)

    for axi_ch in cfg['axi_order']:
        type = '_'.join(axi_ch.split('_')[:2])
        ch = axi_ch.split("_")[-1]
        phys_ch = cfg['inv_map'][axi_ch]
        rsvd_bits[axi_ch] = phys_ch_size[phys_ch] - axi_ch_size[type][ch]

    return phys_ch_size, rsvd_bits


def main():
    """Generate a flit packet package."""

    # Path of the current script.
    script_path = pathlib.Path(__file__).parent

    parser = argparse.ArgumentParser(
        description="Generate flit files for a given configuration")
    parser.add_argument("--config", "-c", type=pathlib.Path, required=True, help="Path to the config file")
    parser.add_argument("--output", "-o", type=pathlib.Path, required=False,
                        default=script_path / '..' / 'src', help="Path to the output file")

    args = parser.parse_args()

    # Read HJSON description of System.
    with open(args.config, "r") as f:
        cfg = JsonRef.replace_refs(hjson.load(f))

    cfg['axi_order'] = axi_channel_ordering(cfg['map'])
    cfg['meta']['axi_ch'] = clog2(len(cfg['axi_order']))
    cfg['meta_bits'] = sum(cfg['meta'].values())
    cfg['inv_map'] = invert_map(cfg['map'])
    ch_sizes, rsvd_bits = calc_channel_size(cfg)
    cfg['phys_ch_sizes'] = ch_sizes
    cfg['rsvd_bits'] = rsvd_bits

    out_file = args.output / f"floo_{cfg['name']}_flit_pkg.sv"
    with open(out_file, "w") as f:
        tpl = templates.get_template("floo_flit_pkg.sv.tpl")
        f.write(tpl.render_unicode(cfg=cfg))


if __name__ == "__main__":
    main()
