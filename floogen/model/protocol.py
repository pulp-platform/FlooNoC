#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import Optional, List, TypeVar, Union
from typing_extensions import Annotated
from pydantic import BaseModel, StringConstraints, model_validator

from floogen.utils import short_dir, snake_to_camel, sv_param_decl, sv_typedef

class ProtocolDesc(BaseModel):
    """Protocol class to describe a protocol."""

    name: str
    description: Optional[str] = ""
    type: str
    direction: Annotated[str, StringConstraints(pattern=r'manager|subordinate')]
    svdirection: str

    @model_validator(mode="before")
    def set_svdirection(self):
        """Set the SystemVerilog direction."""
        self['svdirection'] =  "input" if self['direction'] == "manager" else "output"
        return self

class AXI4(ProtocolDesc):
    """AXI4 protocol class."""

    data_width: int
    addr_width: int
    id_width: int
    user_width: int

    def get_axi_channel_sizes(self) -> dict: # pylint: disable=too-many-locals
        """Return the sizes of each of the AXI channels."""

        burst = 2
        resp = 2
        cache = 4
        prot = 3
        qos = 4
        region = 4
        length = 8
        size = 3
        atop = 6
        last = 1
        lock = 1

        # Variable widths
        iw = self.id_width
        aw = self.addr_width
        dw = self.data_width
        uw = self.user_width

        axi_ch_size = {}
        axi_ch_size["aw"] = (
            iw + aw + length + size + burst + lock + cache + prot + qos + region + atop + uw
        )
        axi_ch_size["w"] = dw + dw // 8 + last + uw
        axi_ch_size["b"] = iw + resp + uw
        axi_ch_size["ar"] = (
            iw + aw + length + size + burst + lock + cache + prot + qos + region + uw
        )
        axi_ch_size["r"] = iw + dw + resp + last + uw

        return axi_ch_size

    def full_name(self) -> str:
        """Return the name of the protocol."""
        return f"axi_{self.name}_{short_dir(self.svdirection)}"

    def render_params(self) -> str:
        """Render the parameters of the protocol."""
        cfull_name = snake_to_camel(self.full_name())
        string = sv_param_decl(cfull_name + "AddrWidth", self.addr_width)
        string += sv_param_decl(cfull_name + "DataWidth", self.data_width)
        string += sv_param_decl(cfull_name + "IdWidth", self.id_width)
        string += sv_param_decl(cfull_name + "UserWidth", self.user_width)
        return string + "\n"

    def render_typedefs(self) -> str:
        """Render the typedefs of the protocol."""
        full_name = self.full_name()
        string = sv_typedef(full_name + "_addr_t", array_size=self.addr_width)
        string += sv_typedef(full_name + "_data_t", array_size=self.data_width)
        string += sv_typedef(full_name + "_strb_t", array_size=self.data_width // 8)
        string += sv_typedef(full_name + "_id_t", array_size=self.id_width)
        string += sv_typedef(full_name + "_user_t", array_size=self.user_width)
        string += f"`AXI_TYPEDEF_ALL_CT({full_name}, \
            {full_name}_req_t, \
            {full_name}_rsp_t, \
            {full_name}_addr_t, \
            {full_name}_id_t, \
            {full_name}_data_t, \
            {full_name}_strb_t, \
            {full_name}_user_t)\n\n"
        return string


class AXI4Bus(AXI4):
    """AXI4 bus protocol class."""

    base_name: str
    source: Union[str, List[str]]
    dest: Union[str, List[str]]
    array: Optional[List[int]] = None
    arr_idx: Optional[List[int]] = None
    is_declared: bool = False
    subtype: str = ""
    type_prefix: str = "axi"


    def _invert_dir(self):
        """Invert the direction of the protocol."""
        return "input" if self.svdirection == "output" else "output"

    def _type_name(self):
        """Return the type name of the protocol."""
        short_dir = "in" if self.svdirection == "input" else "out"
        return f"{self.type_prefix}_{self.name}_{short_dir}"

    def _array_to_sv_array(self):
        """Convert the array to a SystemVerilog array."""
        if self.array is not None:
            return "".join([f"[{i-1}:0]" if i != 1 else "" for i in self.array])
        return ""

    def _idx_to_sv_idx(self):
        """Convert the array to a SystemVerilog array."""
        if self.arr_idx is not None:
            string = ""
            for idx, val in zip(self.arr_idx, self.array):
                if val != 1:
                    string += f"[{idx}]"
            return string
        return ""

    def typedef(self) -> str:
        """Return the typedef of the protocol."""
        return f"`AXI_TYPEDEF_ALL_CT({self._type_name()}, \
            {self._type_name()}_req_t, \
            {self._type_name()}_rsp_t, \
            logic[{self.addr_width-1}:0], \
            logic[{self.id_width-1}:0], \
            logic[{self.data_width-1}:0], \
            logic[{self.data_width//8-1}:0], \
            logic[{self.user_width-1}:0])"

    def req_type(self) -> str:
        """Return the request type of the protocol."""
        return f"{self._type_name()}_req_t"

    def rsp_type(self) -> str:
        """Return the response type of the protocol."""
        return f"{self._type_name()}_rsp_t"

    def req_name(self, port=False, idx=False) -> str:
        """Return the request name of the protocol."""
        idx = self._idx_to_sv_idx() if idx else ""
        if port:
            return f"{self.base_name}_req_{self.svdirection[0]}{idx}"
        return f"{self.source}_to_{self.dest}_req"

    def rsp_name(self, port=False, idx=False) -> str:
        """Return the response name of the protocol."""
        idx = self._idx_to_sv_idx() if idx else ""
        if port:
            return f"{self.base_name}_rsp_{self._invert_dir()[0]}{idx}"
        return f"{self.dest}_to_{self.source}_rsp"

    def declare(self) -> str:
        """Declare the protocol."""
        string = f"{self.req_type()} {self.req_name()};\n"
        string += f"{self.rsp_type()} {self.rsp_name()};\n"
        return string + "\n"

    def render_port(self) -> List[str]:
        """Render the port of the protocol."""
        rev_direction = self._invert_dir()
        ports = []
        ports.append(
            f"{self.svdirection} {self.req_type()} \
            {self._array_to_sv_array()} {self.req_name(port=True)}"
        )
        ports.append(
            f"{rev_direction} {self.rsp_type()} \
            {self._array_to_sv_array()} {self.rsp_name(port=True)}"
        )
        return ports



Protocols = TypeVar("Protocols", bound=ProtocolDesc)
