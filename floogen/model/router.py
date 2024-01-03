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


from typing import Optional, List, ClassVar, Tuple, Union
from importlib import resources
from abc import ABC, abstractmethod

from pydantic import BaseModel, field_validator
from mako.lookup import Template

from floogen.model.routing import Routing, Id, Coord
from floogen.model.link import Link, XYLinks


class RouterDesc(BaseModel):
    """Router class to describe (arrays of) a router"""

    name: str
    array: Optional[Union[Tuple[int], Tuple[int, int]]] = None
    tree: Optional[List[int]] = None
    id_offset: Optional[Id] = None
    auto_connect: Optional[bool] = True

    @field_validator("array", mode="before")
    @classmethod
    def array_int_to_tuple(cls, v):
        """Convert array to tuple if it is an int"""
        if isinstance(v, int):
            return (v,)
        return v

    @field_validator("tree", mode="before")
    @classmethod
    def tree_int_to_tuple(cls, v):
        """Convert tree to tuple if it is an int"""
        if isinstance(v, int):
            return (v,)
        return v


class Router(BaseModel, ABC):
    """Abstract router class of an actual router"""

    name: str
    incoming: List[Link]
    outgoing: List[Link]
    degree: int
    routing: Routing

    @abstractmethod
    def render(self):
        """Declare the router in the generated code."""


class XYRouter(BaseModel, ABC):
    """Abstract router class of an actual router"""

    name: str
    incoming: XYLinks
    outgoing: XYLinks
    degree: int = 5  # XY router always has 5 links
    id: Coord

    @abstractmethod
    def render(self):
        """Declare the router in the generated code."""


class NarrowWideRouter(Router):
    """Router class to describe a narrow-wide router"""

    with resources.path("floogen.templates", "floo_narrow_wide_router.sv.mako") as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self) + "\n"


class NarrowWideXYRouter(XYRouter):
    """Router class to describe a narrow-wide router"""

    with resources.path("floogen.templates", "floo_narrow_wide_xy_router.sv.mako") as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self) + "\n"
