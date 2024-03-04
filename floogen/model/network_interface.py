#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import Optional, ClassVar
from importlib.resources import files, as_file

from pydantic import BaseModel
from mako.lookup import Template

from floogen.model.routing import Id, AddrRange, Routing, RouteMap
from floogen.model.protocol import AXI4
from floogen.model.link import NarrowWideLink
from floogen.model.endpoint import EndpointDesc
import floogen.templates


class NetworkInterface(BaseModel):
    """NetworkInterface class to describe a network interface."""

    name: str
    endpoint: EndpointDesc
    description: str = ""
    routing: Routing
    table: Optional[RouteMap] = None
    id: Optional[Id] = None
    arr_idx: Optional[Id] = None
    addr_range: Optional[AddrRange] = None

    def is_sbr(self) -> bool:
        """Return true if the network interface is a subordinate."""
        return self.endpoint.is_sbr()

    def is_mgr(self) -> bool:
        """Return true if the network interface is a manager."""
        return self.endpoint.is_mgr()

    def is_only_sbr(self) -> bool:
        """Return true if the network interface is only a subordinate."""
        return self.endpoint.is_sbr() and not self.endpoint.is_mgr()

    def is_only_mgr(self) -> bool:
        """Return true if the network interface is only a manager."""
        return self.endpoint.is_mgr() and not self.endpoint.is_sbr()


class NarrowWideAxiNI(NetworkInterface):
    """ " NarrowWideNI class to describe a narrow-wide network interface."""

    with as_file(
        files(floogen.templates).joinpath("floo_narrow_wide_chimney.sv.mako")
    ) as _tpl_path:
        tpl: ClassVar = Template(filename=str(_tpl_path))

    mgr_narrow_port: Optional[AXI4] = None
    sbr_narrow_port: Optional[AXI4] = None
    mgr_wide_port: Optional[AXI4] = None
    sbr_wide_port: Optional[AXI4] = None
    mgr_link: NarrowWideLink
    sbr_link: NarrowWideLink

    def render(self, **kwargs) -> str:
        """Render the network interface."""
        return self.tpl.render(ni=self, **kwargs)
