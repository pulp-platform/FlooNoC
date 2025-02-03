#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from enum import Enum
from typing import Optional, List, Tuple
from abc import ABC, abstractmethod

from pydantic import BaseModel, Field, ConfigDict, model_validator, field_validator

from floogen.utils import (
    cdiv,
    sv_param_decl,
    sv_typedef,
    sv_struct_typedef,
    bool_to_sv,
    snake_to_camel,
    sv_struct_render
)


class RouteAlgo(Enum):
    """Routing algorithm enum."""

    XY = "XYRouting"
    YX = "YXRouting"
    ID = "IdTable"
    SRC = "SourceRouting"

    def __str__(self):
        return f"{self.name}"


class XYDirections(Enum):
    """XY directions enum."""

    NORTH = 0
    EAST = 1
    SOUTH = 2
    WEST = 3
    EJECT = 4

    @classmethod
    def reverse(cls, direction: int):
        """Reverse the direction."""
        return (direction + 2) % 4 if direction != 4 else 4

    @classmethod
    def to_coords(cls, direction: int):
        """Convert the direction to coordinates."""
        return {
            cls.NORTH.value: Coord(x=0, y=1),
            cls.EAST.value: Coord(x=1, y=0),
            cls.SOUTH.value: Coord(x=0, y=-1),
            cls.WEST.value: Coord(x=-1, y=0),
            cls.EJECT.value: Coord(x=0, y=0),
        }[direction]

    def __str__(self):
        return self.name

    def __int__(self):
        return self.value

class Id(BaseModel, ABC):
    """ID class."""

    @abstractmethod
    def render(self):
        """Declare the Id generated code."""

    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, value):
        if not issubclass(value, Id):
            raise ValueError("Invalid Object")
        return value


class SimpleId(Id):
    """ID class."""

    id: int

    def __hash__(self):
        return hash(self.id)

    def __add__(self, other):
        """Add the ID."""
        return self.id + other.id

    def __sub__(self, other):
        """Subtract the ID."""
        return self.id - other.id

    def __lt__(self, other):
        """Less than comparison."""
        return self.id < other.id

    @field_validator("id")
    @classmethod
    def validate_id(cls, v):
        """Validate the ID."""
        if v < 0:
            raise ValueError("ID must be positive")
        return v

    def render(self, as_index=False):
        """Render the SystemVerilog ID."""
        if not as_index:
            return f"{self.id}"
        return f"[{self.id}]"


class Coord(Id):
    """2D coordinate class."""

    x: int
    y: int
    port_id: int = 0

    def __hash__(self):
        return hash((self.x, self.y, self.port_id))

    def __add__(self, other):
        return Coord(x=self.x + other.x, y=self.y + other.y, port_id=self.port_id + other.port_id)

    def __sub__(self, other):
        return Coord(x=self.x - other.x, y=self.y - other.y, port_id=self.port_id - other.port_id)

    def __lt__(self, other):
        if self.y < other.y:
            return True
        if self.y == other.y:
            return self.x < other.x
        if self.x == other.x:
            return self.port_id < other.port_id
        return False

    def render(self, as_index=False):
        """Render the SystemVerilog coordinate."""
        if not as_index:
            return f"'{{x: {self.x}, y: {self.y}, port_id: {self.port_id}}}"
        return f"[{self.x}][{self.y}]"

    @staticmethod
    def get_dir(node, neighbor) -> XYDirections:
        """Get the direction from node to neighbor."""
        if node.x == neighbor.x and node.y == neighbor.y:
            return XYDirections.EJECT
        if node.x == neighbor.x:
            if node.y > neighbor.y:
                return XYDirections.SOUTH
            return XYDirections.NORTH
        if node.y == neighbor.y:
            if node.x > neighbor.x:
                return XYDirections.WEST
            return XYDirections.EAST
        raise ValueError("Invalid neighbor")


class AddrRange(BaseModel):
    """Address range class."""

    model_config = ConfigDict(extra="forbid")

    start: int = Field(ge=0)
    end: int = Field(ge=0)
    size: int
    base: Optional[int] = None
    idx: Optional[int] = None

    def __str__(self):
        return f"[{self.start:X}:{self.end:X}]"

    @model_validator(mode="before")
    def validate_input(self):
        """Validate the address range."""
        if not isinstance(self, dict):
            raise ValueError("Invalid address range specification")
        addr_dict = {k: v for k, v in self.items() if v is not None}
        match addr_dict:
            case {"size": size, "base": base, "idx": idx}:
                addr_dict["start"] = base + size * idx
                addr_dict["end"] = addr_dict["start"] + size
            case {"size": size, "base": base}:
                addr_dict["start"] = base
                addr_dict["end"] = base + size
            case {"start": start, "end": end, "size": size}:
                if end - start != size:
                    raise ValueError("Invalid address range specification")
            case {"start": start, "end": end}:
                addr_dict["size"] = end - start
            case {"start": start, "size": size}:
                addr_dict["end"] = start + size
            case _:
                raise ValueError("Invalid address range specification")
        return addr_dict

    @model_validator(mode="after")
    def validate_output(self):
        """Validate the address range."""
        if self.start >= self.end:
            raise ValueError("Address range start must be less than end")
        return self

    def set_idx(self, idx):
        """Update the address range with the given index."""
        self.idx = idx
        if self.base is not None:
            self.start = self.base + self.size * idx
            self.end = self.start + self.size
        else:
            raise ValueError("Address range base not set")
        return self


class RouteMapRule(BaseModel):
    """Routing rule class."""

    model_config = ConfigDict(arbitrary_types_allowed=True)

    dest: Id
    addr_range: AddrRange
    desc: Optional[str] = None

    def __str__(self):
        return f"{self.addr_range} -> {self.dest}"

    def __lt__(self, other):
        return self.addr_range.start < other.addr_range.start

    def render(self, aw=None):
        """Render the SystemVerilog routing rule."""
        if aw is not None:
            return (
                f"'{{idx: {self.dest.render()}, "
                f"start_addr: {aw}'h{self.addr_range.start:0{cdiv(aw,4)}x}, "
                f"end_addr: {aw}'h{self.addr_range.end:0{cdiv(aw,4)}x}}}"
            )
        return (
            f"'{{idx: {self.dest.render()}, "
            f"start_addr: {self.addr_range.start}, "
            f"end_addr: {self.addr_range.end}}}"
        )


class RouteRule(BaseModel):
    """Routing rule class."""

    route: Optional[List[Tuple[int, int]]]
    id: Id
    desc: Optional[str] = None

    def render(self, num_route_bits):
        """Render the SystemVerilog route."""
        route_str = ""
        route_bits_used = 0
        split_route = False
        if self.route is None:
            if split_route:
                return f"{num_route_bits}'d0"
            return f"{num_route_bits}'b{'0' * num_route_bits}"
        for port, num_bits in self.route:
            if split_route:
                route_str = f"{num_bits}'d{port}, " + route_str
            else:
                route_str = f"{port:0{num_bits}b}" + route_str
            route_bits_used += num_bits
        if route_bits_used > num_route_bits:
            raise ValueError("Not enough bits to encode the route")
        if route_bits_used < num_route_bits:
            if split_route:
                return f"{num_route_bits-route_bits_used}'d0, " + route_str[:-2]
            return f"{num_route_bits}'b{'0' * (num_route_bits-route_bits_used)}" + route_str
        if split_route:
            return route_str[:-2]
        return f"{num_route_bits}'b" + route_str


class RouteTable(BaseModel):
    """Route Table class, which can hold the route entries to each destination"""

    name: str
    routes: List[RouteRule]

    def __len__(self):
        return len(self.routes)

    @model_validator(mode="after")
    def sort_and_pad(self):
        """Sort by destination and fill in missing entries."""
        self.routes = sorted(self.routes, key=lambda x: x.id)
        for i, route in enumerate(self.routes):
            if i != route.id.id:
                self.routes.insert(i, RouteRule(route=None, id=SimpleId(id=i)))
        return self.routes.reverse()

    def render(self, num_route_bits, no_decl=False):
        """Render the SystemVerilog route table."""
        string = ""
        rules_str = ""
        if not self.routes:
            string += sv_param_decl(
                f"{snake_to_camel(self.name)}",
                value="'{default: 0}",
                dtype="route_t",
            )
            return string
        string += sv_param_decl(f"{snake_to_camel(self.name)}NumRoutes", len(self.routes)) + "\n"
        for i, rule in enumerate(self.routes):
            rules_str += f"{rule.render(num_route_bits)}"
            rules_str += "," if i != len(self.routes) - 1 else " "
            if rule.desc is not None:
                rules_str += f"// {rule.desc}"
            rules_str += "\n"
        if no_decl:
            return "'{\n" + rules_str + "}"
        string += sv_param_decl(
            f"{snake_to_camel(self.name)}",
            value="'{\n" + rules_str + "\n}",
            dtype="route_t",
            array_size=f"{snake_to_camel(self.name)}NumRoutes-1",
        )
        return string


class RouteMap(BaseModel):
    """Route Map class, which can represent the system address map (SAM),
    or a routing table of a router."""

    name: str
    rules: List[RouteMapRule]

    def __str__(self):
        return f"{self.rules}"

    def __len__(self):
        return len(self.rules)

    def rule_type(self):
        """Return the type of the rules."""
        return self.name + "_rule_t"

    @model_validator(mode="after")
    def check_no_overlapping_ranges(self):
        """Check if there are no overlapping ranges."""
        rules = sorted(self.rules)
        for i in range(len(rules) - 1):
            if rules[i].addr_range.end > rules[i + 1].addr_range.start:
                raise ValueError(
                    f"Overlapping ranges: {rules[i].addr_range} and {rules[i+1].addr_range}\n \
                    {self.pprint()}"
                )
        return self

    def trim(self):
        """Optimize the routing table."""
        # Separate the rules by destination
        rules_by_dest = {}
        for rule in self.rules:
            rules_by_dest.setdefault(rule.dest, []).append(rule)

        # Sort the rules by start address
        for dest, ranges in rules_by_dest.items():
            rules_by_dest[dest] = sorted(ranges)

        # Merge the rules if the end of one range is the start of the next
        for dest, ranges in rules_by_dest.items():
            i = 0
            while i < len(ranges) - 1:
                if ranges[i].addr_range.end == ranges[i + 1].addr_range.start:
                    ranges[i].addr_range.end = ranges[i + 1].addr_range.end
                    ranges[i].addr_range.size = (
                        ranges[i].addr_range.end - ranges[i].addr_range.start
                    )
                    del ranges[i + 1]
                else:
                    i += 1

        # Combine the rules into a single table again
        self.rules = []
        for dest, ranges in rules_by_dest.items():
            for rule in ranges:
                self.rules.append(rule)

        # Validate the routing table
        self.model_validate(self)

    def render(self, aw=None):
        """Render the SystemVerilog routing table."""
        string = ""
        rules = self.rules.copy()
        # typedef of the address rule
        string += sv_param_decl(f"{snake_to_camel(self.name)}NumRules", len(rules)) + "\n"
        addr_type = f"logic [{aw-1}:0]" if aw is not None else "id_t"
        rule_type_dict = {}
        rule_type_dict = {"idx": "id_t", "start_addr": addr_type, "end_addr": addr_type}
        string += sv_struct_typedef(self.rule_type(), rule_type_dict)
        rules_str = ""
        if not rules:
            string += sv_param_decl(
                f"{snake_to_camel(self.name)}",
                value="'{default: 0}",
                dtype=self.rule_type(),
            )
            return string
        for i, rule in enumerate(rules):
            rules_str += f"{rule.render(aw)}"
            rules_str += ',' if i != len(rules) - 1 else ' '
            if rule.desc is not None:
                rules_str += f"// {rule.desc}\n"
        string += sv_param_decl(
            f"{snake_to_camel(self.name)}",
            value="'{\n" + rules_str + "\n}",
            dtype=self.rule_type(),
            array_size=f"{snake_to_camel(self.name)}NumRules-1"
        )
        return string

    def pprint(self):
        """Pretty print the routing table."""
        for rule in self.rules:
            print(rule)


class Routing(BaseModel):
    """Routing Description class."""

    model_config = ConfigDict(arbitrary_types_allowed=True, extra="forbid")

    route_algo: RouteAlgo
    use_id_table: bool = True
    sam: Optional[RouteMap] = None
    table: Optional[RouteMap] = None
    addr_offset_bits: Optional[int] = None
    xy_id_offset: Optional[Id] = None
    num_endpoints: Optional[int] = None
    num_id_bits: Optional[int] = None
    num_x_bits: Optional[int] = None
    num_y_bits: Optional[int] = None
    num_route_bits: Optional[int] = None
    addr_width: Optional[int] = None
    rob_idx_bits: int = 1
    port_id_bits: int = 1
    num_vc_id_bits: int = 0

    @field_validator("route_algo", mode="before")
    @classmethod
    def validate_route_algo(cls, v):
        """Validate the routing algorithm."""
        if isinstance(v, str):
            v = RouteAlgo[v]
        return v

    def render_param_decl(self) -> str:
        """Render the SystemVerilog parameter declaration."""
        string = ""
        string += sv_param_decl("RouteAlgo", self.route_algo.value, dtype="route_algo_e")
        string += sv_param_decl("UseIdTable", bool_to_sv(self.use_id_table), dtype="bit")
        match (self.route_algo):
            case RouteAlgo.XY:
                string += sv_param_decl("NumXBits", self.num_x_bits)
                string += sv_param_decl("NumYBits", self.num_y_bits)
            case RouteAlgo.ID:
                string += sv_param_decl("NumIdBits", self.num_id_bits)
            case _:
                pass

        if self.route_algo == RouteAlgo.XY:
            string += sv_param_decl("XYAddrOffsetX", self.addr_offset_bits)
            string += sv_param_decl("XYAddrOffsetY", self.addr_offset_bits + self.num_x_bits)
        else:
            string += sv_param_decl("XYAddrOffsetX", 0)
            string += sv_param_decl("XYAddrOffsetY", 0)
        if self.route_algo == RouteAlgo.ID and not self.use_id_table:
            string += sv_param_decl("IdAddrOffset", self.addr_offset_bits)
        else:
            string += sv_param_decl("IdAddrOffset", 0)
        return string

    def render_typedefs(self) -> str:
        """Render the SystemVerilog typedefs."""
        string = ""
        string += sv_typedef("rob_idx_t", array_size=self.rob_idx_bits)
        if self.port_id_bits > 0:
            string += sv_typedef("port_id_t", array_size=self.port_id_bits)
        match self.route_algo:
            case RouteAlgo.XY:
                string += sv_typedef("x_bits_t", array_size=self.num_x_bits)
                string += sv_typedef("y_bits_t", array_size=self.num_y_bits)
                id_fields = {"x": "x_bits_t", "y": "y_bits_t"}
                if self.port_id_bits > 0:
                    id_fields["port_id"] = "port_id_t"
                string += sv_struct_typedef("id_t", id_fields)
                string += sv_typedef("route_t", "logic")
            case RouteAlgo.ID:
                string += sv_typedef("id_t", array_size=self.num_id_bits)
                string += sv_typedef("route_t", "logic")
            case RouteAlgo.SRC:
                string += sv_typedef("id_t", array_size=self.num_id_bits)
                string += sv_typedef("route_t", array_size=self.num_route_bits)
            case _:
                pass
        if self.num_vc_id_bits > 0:
            string += sv_typedef("vc_id_t", array_size=self.num_vc_id_bits)
        return string

    def render_hdr_typedef(self, network_type) -> str:
        """Render the SystemVerilog flit header."""

        dst_type = "route_t" if self.route_algo == RouteAlgo.SRC else "id_t"
        ch_type = "axi_ch_e" if network_type == "axi" else "nw_ch_e"

        if self.num_vc_id_bits == 0:
            return f"`FLOO_TYPEDEF_HDR_T(hdr_t, {dst_type}, id_t, {ch_type}, rob_idx_t)"
        return f"`FLOO_TYPEDEF_VC_HDR_T(hdr_t, {dst_type}, id_t, {ch_type}, rob_idx_t, vc_id_t)"

    def render_route_cfg(self, name) -> str:
        """Render the SystemVerilog routing configuration."""
        fields = {
            "RouteAlgo": self.route_algo.value,
            "UseIdTable": bool_to_sv(self.use_id_table),
            "XYAddrOffsetX": self.addr_offset_bits if self.route_algo == RouteAlgo.XY else 0,
            "XYAddrOffsetY": self.addr_offset_bits + self.num_x_bits if
                                self.route_algo == RouteAlgo.XY else 0,
            "IdAddrOffset": self.addr_offset_bits if
                                self.route_algo == RouteAlgo.ID and not self.use_id_table else 0,
            "NumSamRules": len(self.sam),
            "NumRoutes": self.num_endpoints if self.route_algo == RouteAlgo.SRC else 0,
        }
        return sv_param_decl(name, sv_struct_render(fields), dtype="route_cfg_t")
