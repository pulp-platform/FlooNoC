#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import ClassVar, List, Union, Dict, Optional, NamedTuple
from abc import ABC, abstractmethod
from pydantic import BaseModel


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

    @abstractmethod
    def declare(self):
        """Declare the link in the generated code."""

    @abstractmethod
    def render_ports(self):
        """Declare the ports of the link."""


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
        "req": {"narrow": ["aw", "w", "ar"], "wide": ["aw", "ar"]},
        "rsp": {"narrow": ["b", "r"], "wide": ["b"]},
        "wide": {"wide": ["w", "r"]},
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

    @classmethod
    def get_inverted_mapping(cls):
        """Return the mapping of the link."""
        mappings = {}
        for phys_ch, ch_types in cls.channel_mapping.items():
            for ch_type, axi_chs in ch_types.items():
                for axi_ch in axi_chs:
                    mappings.setdefault(ch_type, {})[axi_ch] = phys_ch
        return mappings

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

    def declare(self):
        """Declare the link in the generated code."""
        string = ""
        string += f"req_t {self.source}_to_{self.dest}_req;\n"
        string += f"rsp_t {self.source}_to_{self.dest}_rsp;\n\n"
        return string

    def render_ports(self):
        """Declare the ports of the link."""
        raise NotImplementedError
