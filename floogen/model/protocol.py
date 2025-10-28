#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import Optional, List, TypeVar, Union
from typing_extensions import Annotated
from pydantic import BaseModel, StringConstraints

from floogen.utils import snake_to_camel, sv_param_decl, sv_typedef, sv_struct_render

class ProtocolDesc(BaseModel):
    """Protocol class to describe a protocol."""

    name: str
    description: Optional[str] = ""
    protocol: Annotated[str, StringConstraints(pattern=r"AXI4")]
    type: Optional[Annotated[str, StringConstraints(pattern=r"narrow|wide")]] = None
    direction: Optional[str] = None

class AXI4(ProtocolDesc):
    """AXI4 protocol class."""

    data_width: int
    addr_width: int
    id_width: int
    user_width: int
    type_prefix: Optional[str] = "axi"

    def type_name(self) -> str:
        """Return the full name of the protocol."""
        if self.type_prefix is not None:
            return f"{self.type_prefix}_{self.name}"
        return self.name

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
        name_t = self.type_name()
        string = sv_typedef(name_t + "_addr_t", array_size=self.addr_width)
        string += sv_typedef(name_t + "_data_t", array_size=self.data_width)
        string += sv_typedef(name_t + "_strb_t", array_size=self.data_width // 8)
        string += sv_typedef(name_t + "_id_t", array_size=self.id_width)
        string += sv_typedef(name_t + "_user_t", array_size=self.user_width)
        string += f"`AXI_TYPEDEF_ALL_CT({name_t}, \
            {name_t}_req_t, \
            {name_t}_rsp_t, \
            {name_t}_addr_t, \
            {name_t}_id_t, \
            {name_t}_data_t, \
            {name_t}_strb_t, \
            {name_t}_user_t)\n\n"
        return string

    @classmethod
    def render_cfg(cls, name, mgr_axi, sbr_axi) -> str:
        """Render the configuration of the protocol."""
        fields = {
            "AddrWidth": mgr_axi.addr_width,
            "DataWidth": mgr_axi.data_width,
            "UserWidth": mgr_axi.user_width,
            "InIdWidth": mgr_axi.id_width,
            "OutIdWidth": sbr_axi.id_width,
        }
        return sv_param_decl(name, sv_struct_render(fields), dtype="axi_cfg_t")


class AXI4Bus(AXI4):
    """AXI4 bus protocol class."""

    base_name: str
    source: Union[str, List[str]]
    dest: Union[str, List[str]]
    arr_dim: Optional[List[int]] = None
    arr_idx: Optional[List[int]] = None
    is_declared: bool = False
    subtype: str = ""

    def _invert_dir(self):
        """Returns the inverted direction of the protocol port."""
        return "input" if self.direction == "output" else "output"

    def _array_to_sv_array(self):
        """Convert the array to a SystemVerilog array."""
        if self.arr_dim is not None:
            return "".join([f"[{i-1}:0]" if i != 1 else "" for i in self.arr_dim])
        return ""

    def _idx_to_sv_idx(self):
        """Convert the array to a SystemVerilog array."""
        if self.arr_idx is not None:
            string = ""
            for idx, val in zip(self.arr_idx, self.arr_dim):
                if val != 1:
                    string += f"[{idx}]"
            return string
        return ""

    def req_type(self) -> str:
        """Return the request type of the protocol."""
        return f"{self.type_name()}_req_t"

    def rsp_type(self) -> str:
        """Return the response type of the protocol."""
        return f"{self.type_name()}_rsp_t"

    def req_name(self, port=False, idx=False) -> str:
        """Return the request name of the protocol."""
        idx = self._idx_to_sv_idx() if idx else ""
        if port:
            return f"{self.base_name}_req_{str(self.direction)[0]}{idx}"
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

    def render_port(self, pkg_name="") -> List[str]:
        """Render the port of the protocol."""
        rev_direction = self._invert_dir()
        ports = []
        ports.append(
            f"{self.direction} {pkg_name}{self.req_type()} \
            {self._array_to_sv_array()} {self.req_name(port=True)}"
        )
        ports.append(
            f"{rev_direction} {pkg_name}{self.rsp_type()} \
            {self._array_to_sv_array()} {self.rsp_name(port=True)}"
        )
        return ports


Protocols = TypeVar("Protocols", bound=ProtocolDesc)
