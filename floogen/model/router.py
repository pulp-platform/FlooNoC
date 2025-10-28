#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>


from typing import Optional, List, ClassVar, Tuple, Union
from importlib.resources import files, as_file
from abc import ABC, abstractmethod

from pydantic import BaseModel, ConfigDict, field_validator, model_validator
from mako.lookup import Template

from floogen.model.routing import RouteMap, SimpleId, Coord, RouteAlgo
from floogen.model.link import Link
import floogen.templates


class RouterDesc(BaseModel):
    """Router class to describe (arrays of) a router"""

    model_config = ConfigDict(extra="forbid")

    name: str
    array: Optional[Union[Tuple[int], Tuple[int, int]]] = None
    tree: Optional[List[int]] = None
    xy_id_offset: Optional[Union[SimpleId, Coord]] = None
    auto_connect: Optional[bool] = True
    degree: Optional[int] = None

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

    @field_validator("xy_id_offset", mode="before")
    @classmethod
    def dict_to_coord_obj(cls, v):
        """Convert dict to Coord object."""
        return Coord.from_dict(v)

class Router(BaseModel, ABC):
    """Abstract router class of an actual router"""

    name: str
    incoming: List[Optional[Link]]
    outgoing: List[Optional[Link]]
    degree: int
    route_algo: RouteAlgo
    table: Optional[RouteMap] = None
    id: Optional[Coord] = None

    @abstractmethod
    def render(self):
        """Declare the router in the generated code."""

    @model_validator(mode="after")
    def check_links(self):
        """Check if the number of links is correct."""
        if len(self.incoming) != self.degree:
            raise ValueError(f"Router {self.name} has {self.incoming} " +
                             f"incoming links but should have {self.degree}")
        if len(self.outgoing) != self.degree:
            raise ValueError(f"Router {self.name} has {self.outgoing} " +
                             f"outgoing links but should have {self.degree}")
        return self

class AxiRouter(Router):
    """Router class to describe a single-AXI router"""

    with as_file(
        files(floogen.templates).joinpath("floo_axi_router.sv.mako")
    ) as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self, **kwargs):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self, **kwargs) + "\n"

class NarrowWideRouter(Router):
    """Router class to describe a narrow-wide router"""

    with as_file(
        files(floogen.templates).joinpath("floo_nw_router.sv.mako")
    ) as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self, **kwargs):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self, **kwargs) + "\n"
