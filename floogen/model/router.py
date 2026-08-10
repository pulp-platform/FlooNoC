# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>


from abc import ABC, abstractmethod
from importlib.resources import as_file, files
from typing import ClassVar

from mako.lookup import Template
from pydantic import BaseModel, model_validator

import floogen.templates
from floogen.model.config import ArrayDims, ConfigModel, OneOrMany
from floogen.model.link import Link
from floogen.model.routing import Coord, RouteAlgo, RouteMap, SimpleId


class RouterDesc(ConfigModel):
    """Router class to describe (arrays of) a router

    Attributes:
        name (str): Unique identifier for the router. Used in connection definitions.
        array (Optional[Union[Tuple[int], Tuple[int, int]]]): Defines a grid of routers (1D or 2D). E.g., `[4, 4]` creates a 4x4 mesh of routers.
        tree (Optional[List[int]]): Defines a tree topology structure. The list specifies the branching factor at each level.
        degree (Optional[int]): Override the number of input/output ports on the router.
        auto_connect (Optional[bool]): If true and `array` is specified, FlooGen automatically generates mesh connections (North, East, South, West) between the routers.
        xy_id_offset (Optional[Union[SimpleId, Coord]]): Offsets for XY coordinates or IDs, used to manually adjust the logical position of the routers in the network.
    """

    name: str
    array: ArrayDims | None = None
    tree: OneOrMany[int] | None = None
    xy_id_offset: SimpleId | Coord | None = None
    auto_connect: bool | None = True
    degree: int | None = None


class Router(BaseModel, ABC):
    """Abstract router class of an actual router"""

    name: str
    incoming: list[Link | None]
    outgoing: list[Link | None]
    degree: int
    route_algo: RouteAlgo
    table: RouteMap | None = None
    id: Coord | None = None

    @abstractmethod
    def render(self):
        """Declare the router in the generated code."""

    @model_validator(mode="after")
    def check_links(self):
        """Check if the number of links is correct."""
        if len(self.incoming) != self.degree:
            raise ValueError(
                f"Router {self.name} has {self.incoming} "
                + f"incoming links but should have {self.degree}"
            )
        if len(self.outgoing) != self.degree:
            raise ValueError(
                f"Router {self.name} has {self.outgoing} "
                + f"outgoing links but should have {self.degree}"
            )
        return self


class AxiRouter(Router):
    """Router class to describe a single-AXI router"""

    with as_file(files(floogen.templates).joinpath("floo_axi_router.sv.mako")) as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self, **kwargs):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self, **kwargs) + "\n"


class NarrowWideRouter(Router):
    """Router class to describe a narrow-wide router"""

    with as_file(files(floogen.templates).joinpath("floo_nw_router.sv.mako")) as _tpl_path:
        _tpl: ClassVar = Template(filename=str(_tpl_path))

    def render(self, **kwargs):
        """Declare the router in the generated code."""
        return self._tpl.render(router=self, **kwargs) + "\n"
