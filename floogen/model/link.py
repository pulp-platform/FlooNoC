#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import ClassVar, List, Union, Dict
from abc import ABC, abstractmethod
from pydantic import BaseModel

from floogen.utils import sv_struct_typedef


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

class AxiLink(Link):
    """Link class to describe a AxiLink."""

    req_type: ClassVar[str] = "floo_req_t"
    rsp_type: ClassVar[str] = "floo_rsp_t"

    def req_name(self):
        """Return the narrow request name."""
        return f"{self.source}_to_{self.dest}_req"

    def rsp_name(self):
        """Return the narrow response name."""
        return f"{self.dest}_to_{self.source}_rsp"

    @classmethod
    def render_typedefs(cls, axi, cfg):
        """Render the typedefs of the links."""
        string = f"`FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, {axi}, {cfg}, hdr_t)\n\n"
        string += "`FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)\n"
        return string

    def declare(self):
        """Declare the link in the generated code."""
        string = f"{self.req_type} {self.req_name()};\n"
        string += f"{self.rsp_type} {self.rsp_name()};\n"
        return string + "\n"

    def render_ports(self, direction="input"):
        """Declare the ports of the link."""
        reverse_direction = "output" if direction == "input" else "input"
        ports = []
        ports.append(f"{direction} {self.req_type} {self.req_name()}")
        ports.append(f"{reverse_direction} {self.rsp_type} {self.rsp_name()}")
        return ports

class NarrowWideLink(Link):
    """Link class to describe a NarrowWidelink."""

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
    def render_typedefs(cls, axi_narrow, axi_wide, cfg_n, cfg_w):
        """Render the typedefs of the links."""
        string = f"`FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, \
            {axi_narrow}, {axi_wide}, {cfg_n}, {cfg_w}, hdr_t)\n\n"
        string += "`FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, req, rsp, wide)\n"
        return string

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

class NarrowWideVCLink(NarrowWideLink):
    '''Link class to describe a NarrowWideVCLink.'''

    @classmethod
    def render_link_typedefs(cls) -> str:
        """Render the typedefs of the protocol."""
        string = ""
        for phys_ch in cls.channel_mapping:
            struct_dict = {"valid": "logic",
                           "credit_v": "logic",
                           "credit_id": "vc_id_t",
                           phys_ch: f"floo_{phys_ch}_chan_t"}
            string += sv_struct_typedef(f"floo_vc_{phys_ch}_t", struct_dict)
        return string

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

class NarrowVCLink(NarrowLink):
    '''Link class to describe a NarrowVCLink.'''

    @classmethod
    def render_link_typedefs(cls) -> str:
        """Render the typedefs of the protocol."""
        string = ""
        for phys_ch in cls.channel_mapping:
            struct_dict = {"valid": "logic",
                           "credit_v": "logic",
                           "credit_id": "vc_id_t",
                           phys_ch: f"floo_{phys_ch}_chan_t"}
            string += sv_struct_typedef(f"floo_vc_{phys_ch}_t", struct_dict)
        return string
