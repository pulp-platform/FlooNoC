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

from typing import Optional, ClassVar
from importlib import resources

from pydantic import BaseModel
from mako.lookup import Template

from floogen.model.routing import Id, AddrRange, Routing
from floogen.model.protocol import AXI4
from floogen.model.link import NarrowWideLink
from floogen.model.endpoint import EndpointDesc


class NetworkInterface(BaseModel):
    """NetworkInterface class to describe a network interface."""

    name: str
    endpoint: EndpointDesc
    description: str = ""
    routing: Routing
    id: Optional[Id] = None
    arr_idx: Optional[Id] = None
    addr_range: Optional[AddrRange] = None

    def is_sbr(self) -> bool:
        """Return true if the network interface is a subordinate."""
        return self.endpoint.is_sbr()

    def is_mgr(self) -> bool:
        """Return true if the network interface is a manager."""
        return self.endpoint.is_mgr()


class NarrowWideAxiNI(NetworkInterface):
    """ " NarrowWideNI class to describe a narrow-wide network interface."""

    with resources.path("floogen.templates", "floo_narrow_wide_chimney.sv.mako") as _tpl_path:
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
