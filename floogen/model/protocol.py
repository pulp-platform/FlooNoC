# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import Annotated, TypeVar

from pydantic import BaseModel, StringConstraints

from floogen.utils import (
    sv_param_decl,
    sv_struct_render,
    sv_struct_typedef,
    sv_typedef,
)


class ProtocolDesc(BaseModel):
    """Protocol class to describe a protocol.

    Attributes:
        name (str): Unique identifier for the protocol. Used to reference it in endpoint configurations.
        protocol (str): The protocol standard. Must be set to `"AXI4"`.
        description (Optional[str]): Optional description of the protocol.
        type (Optional[str]): Sub-type classification, useful for heterogeneous networks (e.g., `"narrow"`, `"wide"`).
        direction (Optional[str]): The direction of the protocol interface.
    """

    name: str
    description: str | None = ""
    protocol: Annotated[str, StringConstraints(pattern=r"AXI4")]
    type: Annotated[str, StringConstraints(pattern=r"narrow|wide")] | None = None
    direction: str | None = None

    def render_port(self, pkg_name="", prefix="") -> list[str]:
        """Render the port of the protocol."""
        raise NotImplementedError


class AXI4(ProtocolDesc):
    """AXI4 protocol class.

    Attributes:
        data_width (int): Width of the data bus in bits.
        addr_width (int): Width of the address bus in bits.
        id_width (int): Width of the ID signals in bits.
        user_width (Union[int, Dict[str, int]]): Configuration for the AXI User signal. Can be a single integer (total width) or a dictionary mapping field names to bit widths.
        type_prefix (Optional[str]): Prefix for generated SystemVerilog types. Set to `None` or an empty string to remove the default `"axi"` prefix.
    """

    data_width: int
    addr_width: int
    id_width: int
    user_width: int | dict[str, int] = 1
    type_prefix: str | None = "axi"

    def type_name(self, prefix="") -> str:
        """Return the full name of the protocol."""
        return "_".join(filter(None, [prefix, self.type_prefix, self.name]))

    def render_typedefs(self, prefix="", ignored_user_fields=None) -> str:
        """Render the typedefs of the protocol."""
        if ignored_user_fields is None:
            ignored_user_fields = []
        name_t = self.type_name() if prefix == "" else f"{prefix}_{self.type_name()}"
        string = sv_typedef(name_t + "_addr_t", array_size=self.addr_width)
        string += sv_typedef(name_t + "_data_t", array_size=self.data_width)
        string += sv_typedef(name_t + "_strb_t", array_size=self.data_width // 8)
        string += sv_typedef(name_t + "_id_t", array_size=self.id_width)

        match self.user_width:
            case int(v):
                string += sv_typedef(name_t + "_user_t", array_size=v)
            case dict(d):
                fields = {k: f"logic [{v-1}:0]" for k, v in d.items() if k not in ignored_user_fields}
                if fields:
                    string += sv_struct_typedef(name_t + "_user_t", fields)
                else:
                    string += sv_typedef(name_t + "_user_t", array_size=1)

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
            "InIdWidth": mgr_axi.id_width,
            "OutIdWidth": sbr_axi.id_width,
        }
        match mgr_axi.user_width:
            case int(v):
                fields["UserWidth"] = v
            case dict(d):
                _collective_fields = {"collective_mask", "collective_op"}
                user_w = sum(v for k, v in d.items() if k not in _collective_fields)
                fields["UserWidth"] = max(user_w, 1)

        return sv_param_decl(name, sv_struct_render(fields), dtype="axi_cfg_t")


class AXI4Bus(AXI4):
    """AXI4 bus protocol class."""

    base_name: str
    source: str | list[str]
    dest: str | list[str]
    arr_dim: list[int] | None = None
    arr_idx: list[int] | None = None
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
        if self.arr_idx is not None and self.arr_dim is not None:
            string = ""
            for idx, val in zip(self.arr_idx, self.arr_dim):
                if val != 1:
                    string += f"[{idx}]"
            return string
        return ""

    def req_type(self, prefix="") -> str:
        """Return the request type of the protocol."""
        return f"{self.type_name(prefix=prefix)}_req_t"

    def rsp_type(self, prefix="") -> str:
        """Return the response type of the protocol."""
        return f"{self.type_name(prefix=prefix)}_rsp_t"

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

    def render_port(self, pkg_name="", prefix="") -> list[str]:
        """Render the port of the protocol."""
        rev_direction = self._invert_dir()
        ports = []
        ports.append(
            f"{self.direction} {pkg_name}{self.req_type(prefix=prefix)} \
            {self._array_to_sv_array()} {self.req_name(port=True)}"
        )
        ports.append(
            f"{rev_direction} {pkg_name}{self.rsp_type(prefix=prefix)} \
            {self._array_to_sv_array()} {self.rsp_name(port=True)}"
        )
        return ports


Protocols = TypeVar("Protocols", bound=ProtocolDesc)
