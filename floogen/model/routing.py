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

from enum import Enum
from typing import Optional, List
from abc import ABC, abstractmethod

from pydantic import BaseModel, Field, ConfigDict, model_validator, field_validator

from floogen.model.utils import cdiv


class RouteAlgo(Enum):
    """Routing algorithm enum."""

    XY = "XYRouting"
    YX = "YXRouting"
    ID = "IdTable"

    def __str__(self):
        return f"{self.name}"


class XYDirections(Enum):
    """XY directions enum."""

    EJECT = "Eject"
    NORTH = "North"
    EAST = "East"
    SOUTH = "South"
    WEST = "West"

    def __str__(self):
        return self.name


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

    def __hash__(self):
        return hash((self.x, self.y))

    def __add__(self, other):
        return Coord(x=self.x + other.x, y=self.y + other.y)

    def __sub__(self, other):
        return Coord(x=self.x - other.x, y=self.y - other.y)

    def render(self, as_index=False):
        """Render the SystemVerilog coordinate."""
        if not as_index:
            return f"'{{x: {self.x}, y: {self.y}}}"
        return f"[{self.x}][{self.y}]"

    @staticmethod
    def get_dir(node, neighbor) -> XYDirections:
        """Get the direction from node to neighbor."""
        if node == neighbor:
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
            raise ValueError("Invalid address range")
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


class RoutingRule(BaseModel):
    """Routing rule class."""

    model_config = ConfigDict(arbitrary_types_allowed=True)

    dest: Id
    addr_range: AddrRange

    def __str__(self):
        return f"{self.addr_range} -> {self.dest}"

    def __lt__(self, other):
        return self.addr_range.start < other.addr_range.start

    def render(self, aw=None):
        """Render the SystemVerilog routing rule."""
        if aw is not None:
            return f"'{{idx: {self.dest.render()}, \
                start_addr: {aw}'h{self.addr_range.start:0{cdiv(aw,4)}x}, \
                end_addr: {aw}'h{self.addr_range.end:0{cdiv(aw,4)}x}}}"
        return f"'{{idx: {self.dest.render()}, \
            start_addr: {self.addr_range.start}, \
            end_addr: {self.addr_range.end}}}"


class RoutingTable(BaseModel):
    """Routing table class."""

    rules: List[RoutingRule]

    def __str__(self):
        return f"{self.rules}"

    def __len__(self):
        return len(self.rules)

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
        return rules

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

    def render(self, name, aw=None, id_offset=None):
        """Render the SystemVerilog routing table."""
        if id_offset is not None:
            for rule in self.rules:
                rule.dest -= id_offset
        addr_type = f"logic [{aw-1}:0]" if aw is not None else "id_t"
        rule_type_str = f"typedef struct packed {{id_t idx; {addr_type} \
            start_addr; {addr_type} end_addr;}} {name}_table_rule_t;\n\n"
        decl_str = f"{name}_table_rule_t [{len(self.rules)-1}:0] {name}_table;\n"
        for i, rule in enumerate(self.rules):
            decl_str += f"assign {name}_table[{i}] = {rule.render(aw)};\n"
        return rule_type_str + decl_str

    def pprint(self):
        """Pretty print the routing table."""
        for rule in self.rules:
            print(rule)


class Routing(BaseModel):
    """Routing Description class."""

    model_config = ConfigDict(arbitrary_types_allowed=True)

    route_algo: RouteAlgo
    use_id_table: bool = True
    table: Optional[RoutingTable] = None
    addr_offset_bits: Optional[int] = None
    id_offset: Optional[Id] = None
    num_endpoints: Optional[int] = None
    num_id_bits: Optional[int] = None
    num_x_bits: Optional[int] = None
    num_y_bits: Optional[int] = None
    addr_width: Optional[int] = None
    rob_idx_bits: int = 4

    @field_validator("route_algo", mode="before")
    @classmethod
    def validate_route_algo(cls, v):
        """Validate the routing algorithm."""
        if isinstance(v, str):
            v = RouteAlgo[v]
        return v
