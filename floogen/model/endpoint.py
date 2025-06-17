#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>
from typing import Optional, List, Union, Tuple
from pydantic import BaseModel, ConfigDict, field_validator, model_validator

from floogen.model.routing import AddrRange, Id, Coord
from floogen.model.protocol import Protocols


class EndpointDesc(BaseModel):
    """
    Endpoint class to describe an endpoint with adress ranges and configuration parameters.
    """

    model_config = ConfigDict(extra="forbid")

    name: str
    description: Optional[str] = ""
    array: Optional[Union[Tuple[int], Tuple[int, int]]] = None
    num: Optional[int] = None
    addr_range: List[AddrRange] = []
    xy_id_offset: Optional[Id] = None
    mgr_port_protocol: Optional[List[str]] = None
    sbr_port_protocol: Optional[List[str]] = None

    @field_validator("array", mode="before")
    @classmethod
    def int_to_tuple(cls, v):
        """Convert int to tuple."""
        if isinstance(v, int):
            return (v,)
        return v

    @field_validator("xy_id_offset", mode="before")
    @classmethod
    def dict_to_coord_obj(cls, v):
        """Convert dict to Coord object."""
        return Coord.from_dict(v)

    @field_validator("addr_range", mode="before")
    @classmethod
    def addr_range_to_list(cls, v):
        """Convert single AddrRange to list."""
        if not isinstance(v, List):
            return [v]
        return v

    @model_validator(mode="after")
    def check_addr_range(self):
        """Check if the address range is valid."""
        # Manager-only endpoints do not need an address range
        match (self.sbr_port_protocol, self.addr_range):
            case (None, _):
                return self
            case (_, None):
                raise ValueError("Endpoint is a Subordinate and requires an address range")
        return self

    @model_validator(mode="after")
    def set_number_eps(self):
        """Set the number of endpoints based on `array`"""
        if self.array is None:
            self.num = 1
        elif len(self.array) == 1:
            self.num = self.array[0]
        elif len(self.array) == 2:
            self.num = self.array[0] * self.array[1]
        else:
            raise ValueError("Invalid array size")
        return self


    def is_sbr(self) -> bool:
        """Return true if the endpoint is a subordinate."""
        return self.sbr_port_protocol is not None

    def is_mgr(self) -> bool:
        """Return true if the endpoint is a manager."""
        return self.mgr_port_protocol is not None

    def is_only_sbr(self) -> bool:
        """Return true if the endpoint is only a subordinate."""
        return self.is_sbr() and not self.is_mgr()

    def is_only_mgr(self) -> bool:
        """Return true if the endpoint is only a manager."""
        return self.is_mgr() and not self.is_sbr()

    def get_ni_name(self, name: str) -> str:
        """Return the name of the NI."""
        return name.replace(self.name, f"{self.name}_ni")

    def render_ports(self):
        """Render the ports of the endpoint."""


class Endpoint(EndpointDesc):
    """Endpoint class to describe an endpoint with adress ranges and configuration parameters."""

    mgr_ports: List[Protocols] = []
    sbr_ports: List[Protocols] = []

    @classmethod
    def from_desc(cls, desc: EndpointDesc,
                  mgr_ports: List[Protocols],
                  sbr_ports: List[Protocols]):
        """Create an endpoint from a description."""
        return cls(**desc.model_dump(), mgr_ports=mgr_ports, sbr_ports=sbr_ports)

    def render_ports(self, pkg_name=""):
        """Render the ports of the endpoint."""
        ports = []
        for port in self.mgr_ports:
            ports += port.render_port(pkg_name)
        for port in self.sbr_ports:
            ports += port.render_port(pkg_name)
        return ports
