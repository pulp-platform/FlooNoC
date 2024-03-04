#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>


from typing import Optional, List, ClassVar, Tuple, Union
from importlib.resources import files, as_file
from abc import ABC, abstractmethod

from pydantic import BaseModel, field_validator
from mako.lookup import Template

from floogen.model.routing import RouteMap, Id, Coord, RouteAlgo
from floogen.model.link import Link, XYLinks
import floogen.templates


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
    route_algo: RouteAlgo
    table: Optional[RouteMap] = None

    @abstractmethod
    def render(self):
        """Declare the router in the generated code."""


class XYRouter(BaseModel, ABC):
    """Abstract router class of an actual router"""

    name: str
    incoming: XYLinks
    outgoing: XYLinks
    degree: int = 5  # XY router always has 5 links
    route_algo: RouteAlgo = RouteAlgo.XY
    id: Coord

    @abstractmethod
    def render(self):
        """Declare the router in the generated code."""


class NarrowWideRouter(Router):
    """Router class to describe a narrow-wide router"""

    with as_file(
        files(floogen.templates).joinpath("floo_narrow_wide_router.sv.mako")
    ) as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self) + "\n"


class NarrowWideXYRouter(XYRouter):
    """Router class to describe a narrow-wide router"""

    with as_file(
        files(floogen.templates).joinpath("floo_narrow_wide_xy_router.sv.mako")
    ) as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self) + "\n"
