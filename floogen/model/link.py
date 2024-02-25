#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import ClassVar, List, Union, Dict, Optional, NamedTuple
from abc import ABC, abstractmethod
from pydantic import BaseModel

from floogen.utils import snake_to_camel, sv_struct_typedef, clog2


class Link(BaseModel, ABC):
    """
    Link class to describe a link with instantiation template and
    configuration parameters.
    """

    description: str = ""
    source: Union[str, List[str]]
    dest: Union[str, List[str]]
    source_type: str
    dest_type: str
    is_bidirectional: bool = False
    is_array: bool = False
    array: list = None

    channel_mapping: ClassVar[Dict] = {}

    @abstractmethod
    def declare(self):
        """Declare the link in the generated code."""

    @abstractmethod
    def render_ports(self):
        """Declare the ports of the link."""

    @classmethod
    def render_enum_decl(cls):
        """Render the enum declaration of the link."""
        i = 0
        string = ""
        for _, mapping in cls.channel_mapping.items():
            for ch_type, axi_chs in mapping.items():
                for axi_ch in axi_chs:
                    name = f"{ch_type}_{axi_ch}"
                    string += f"{snake_to_camel(name)} = {i},\n"
                    i += 1
        string = f"typedef enum logic [{clog2(i+1)-1}:0]{{" + string
        string += f"NumAxiChannels = {i}\n}} axi_ch_e;\n"
        return string

    @classmethod
    def get_inverted_mapping(cls):
        """Return the mapping from axi to physical channels."""
        mappings = {}
        for phys_ch, ch_types in cls.channel_mapping.items():
            for ch_type, axi_chs in ch_types.items():
                for axi_ch in axi_chs:
                    mappings.setdefault(ch_type, {})[axi_ch] = phys_ch
        return mappings

    @classmethod
    def calc_link_sizes(cls, protocols):
        """Infer the link sizes from the network."""
        link_sizes = {}
        for phys_ch, axi_chs in cls.channel_mapping.items():
            # Get all protocols that use this channel
            prots = [
                p
                for p in protocols
                if p.name in axi_chs and p.direction == "manager"
            ]
            # Get only the exact AXI channels that are used by the link
            used_axi_chs = [axi_chs[p.name] for p in prots]
            # Get the sizes of the AXI channels
            axi_ch_sizes = [p.get_axi_channel_sizes() for p in prots]
            link_message_sizes = []
            for used_axi_ch, axi_ch_size in zip(used_axi_chs, axi_ch_sizes):
                link_message_sizes += [axi_ch_size[ch] for ch in used_axi_ch]
            # Get the maximum size of the link
            link_sizes[phys_ch] = max(link_message_sizes)
        return link_sizes

    @classmethod
    def render_flit(cls, protocols):
        """Render the flit of the protocol."""
        string = ""
        inv_mapping = cls.get_inverted_mapping()
        link_sizes = cls.calc_link_sizes(protocols)
        for p in protocols:
            if p.direction == "manager":
                for axi_ch, size in p.get_axi_channel_sizes().items():
                    phys_ch = inv_mapping[p.name][axi_ch]
                    phys_ch_size = link_sizes[phys_ch]
                    rsvd_size = phys_ch_size - size
                    struct_dict = {
                        "hdr": "hdr_t",
                        axi_ch: f"{p.full_name()}_{axi_ch}_chan_t",
                    }
                    if phys_ch_size - size > 0:
                        struct_dict["rsvd"] = f"logic[{rsvd_size-1}:0]"
                    string += sv_struct_typedef(f"floo_{p.name}_{axi_ch}_flit_t", struct_dict)

        for phys_ch, size in link_sizes.items():
            struct_dict = {
                "hdr": "hdr_t",
                "rsvd": f"logic[{size-1}:0]",
            }
            string += sv_struct_typedef(f"floo_{phys_ch}_generic_flit_t", struct_dict)
        return string

    @classmethod
    def render_channels(cls) -> str:
        """Render the channels of the protocol."""
        string = ""
        for phys_ch, axi_chs in cls.channel_mapping.items():
            struct_dict = {}
            for axi_name, axi_chs in axi_chs.items():
                for axi_ch in axi_chs:
                    struct_dict[axi_name + '_' + axi_ch] = f"floo_{axi_name}_{axi_ch}_flit_t"
            struct_dict["generic"] = f"floo_{phys_ch}_generic_flit_t"
            string += sv_struct_typedef(f"floo_{phys_ch}_chan_t", struct_dict, union=True)
        return string

    @classmethod
    def render_link_typedefs(cls) -> str:
        """Render the typedefs of the protocol."""
        string = ""
        for phys_ch in cls.channel_mapping:
            struct_dict = {"valid": "logic", "ready": "logic", phys_ch: f"floo_{phys_ch}_chan_t"}
            string += sv_struct_typedef(f"floo_{phys_ch}_t", struct_dict)
        return string


class XYLinks(NamedTuple):
    """Class to describe the directed links of a router."""

    EJECT: Optional[Link] = None
    EAST: Optional[Link] = None
    NORTH: Optional[Link] = None
    SOUTH: Optional[Link] = None
    WEST: Optional[Link] = None


class NarrowWideLink(Link):
    """Link class to describe a NarrowWidelink."""

    channel_mapping: ClassVar[Dict] = {
        "req": {"narrow": ["aw", "w", "ar"], "wide": ["ar"]},
        "rsp": {"narrow": ["b", "r"], "wide": ["b"]},
        "wide": {"wide": ["aw", "w", "r"]},
    }

    req_type: ClassVar[str] = "floo_req_t"
    rsp_type: ClassVar[str] = "floo_rsp_t"
    wide_type: ClassVar[str] = "floo_wide_t"

    def req_name(self):
        """Return the narrow request name."""
        return f"{self.source}_to_{self.dest}_req"

    def rsp_name(self):
        """Return the narrow response name."""
        return f"{self.dest}_to_{self.source}_rsp"

    def wide_name(self, is_reversed=False):
        """Return the wide name."""
        if is_reversed:
            return f"{self.dest}_to_{self.source}_wide"
        return f"{self.source}_to_{self.dest}_wide"

    @classmethod
    def get_axi_chs(cls):
        """Return all the AXI channels."""
        channels = []
        for axi_chs in cls.channel_mapping.values():
            for key, values in axi_chs.items():
                for v in values:
                    channels.append(f"{key}_{v}")
        return channels

    @classmethod
    def get_mapping(cls):
        """Return the mapping of the link."""
        return cls.channel_mapping



    def declare(self):
        """Declare the link in the generated code."""
        string = f"{self.req_type} {self.req_name()};\n"
        string += f"{self.rsp_type} {self.rsp_name()};\n"
        string += f"{self.wide_type} {self.wide_name()};\n"
        if not self.is_bidirectional:
            string += f"{self.wide_type} {self.wide_name(is_reversed=True)};\n"
        return string + "\n"

    def render_ports(self, direction="input"):
        """Declare the ports of the link."""
        reverse_direction = "output" if direction == "input" else "input"
        ports = []
        ports.append(f"{direction} {self.req_type} {self.req_name()}")
        ports.append(f"{reverse_direction} {self.rsp_type} {self.rsp_name()}")
        ports.append(f"{direction} {self.wide_type} {self.wide_name()}")
        if not self.is_bidirectional:
            ports.append(
                f"{reverse_direction} {self.wide_type} \
                         {self.wide_name(is_reversed=True)}"
            )
        return ports


class NarrowLink(Link):
    """
    Link class to describe a link with instantiation template and
    configuration parameters.
    """

    channel_mapping: ClassVar[Dict] = {
        "req": {"axi": ["aw", "w", "ar"]},
        "rsp": {"axi": ["b", "r"]},
    }

    def declare(self):
        """Declare the link in the generated code."""
        string = ""
        string += f"req_t {self.source}_to_{self.dest}_req;\n"
        string += f"rsp_t {self.source}_to_{self.dest}_rsp;\n\n"
        return string

    def render_ports(self):
        """Declare the ports of the link."""
        raise NotImplementedError
