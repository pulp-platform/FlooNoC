# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from importlib.resources import as_file, files
from typing import ClassVar

from mako.lookup import Template
from pydantic import BaseModel

import floogen.templates
from floogen.model.endpoint import EndpointDesc
from floogen.model.link import AxiLink, NarrowWideLink
from floogen.model.protocol import AXI4
from floogen.model.routing import AddrRange, Coord, RouteMap, RoutingDesc, SimpleId


class NetworkInterface(BaseModel):
    """NetworkInterface class to describe a network interface."""

    name: str
    endpoint: EndpointDesc
    description: str = ""
    routing: RoutingDesc
    table: RouteMap | None = None
    id: SimpleId | Coord | None = None
    uid: SimpleId | None = None
    arr_idx: SimpleId | Coord | None = None
    addr_range: list[AddrRange] | None = None

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

    def is_collective_ni(self) -> bool:
        """Return true if the network interface supports collective operations."""
        if not self.addr_range:
            return False
        return any(b.en_collective for b in self.addr_range)

    def render_enum_name(self) -> str:
        """Render the enum name."""
        name = f"{self.endpoint.name}"
        if isinstance(self.arr_idx, Coord):
            name += f"_x{self.arr_idx.x}_y{self.arr_idx.y}"
        elif isinstance(self.arr_idx, SimpleId):
            name += f"_{self.arr_idx.id}"
        return name


class AxiNI(NetworkInterface):
    """Axi Network Interface class."""

    with as_file(files(floogen.templates).joinpath("floo_axi_chimney.sv.mako")) as _tpl_path:
        tpl: ClassVar = Template(filename=str(_tpl_path))

    mgr_port: AXI4 | None = None
    sbr_port: AXI4 | None = None
    mgr_link: AxiLink
    sbr_link: AxiLink

    def render(self, **kwargs) -> str:
        """Render the network interface."""
        return self.tpl.render(ni=self, **kwargs)


class NarrowWideAxiNI(NetworkInterface):
    """ " NarrowWideNI class to describe a narrow-wide network interface."""

    with as_file(files(floogen.templates).joinpath("floo_nw_chimney.sv.mako")) as _tpl_path:
        tpl: ClassVar = Template(filename=str(_tpl_path))

    mgr_narrow_port: AXI4 | None = None
    sbr_narrow_port: AXI4 | None = None
    mgr_wide_port: AXI4 | None = None
    sbr_wide_port: AXI4 | None = None
    mgr_link: NarrowWideLink
    sbr_link: NarrowWideLink

    def render(self, **kwargs) -> str:
        """Render the network interface."""
        return self.tpl.render(ni=self, **kwargs)
