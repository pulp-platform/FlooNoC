#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import math
from typing import Union


def cdiv(x, y) -> int:
    """Returns the ceiling of x/y."""
    return -(-x // y)


def clog2(x) -> int:
    """Returns the ceiling of log2(x)."""
    return math.ceil(math.log2(x))


def camel_to_snake(name: str) -> str:
    """Converts a camel case string to snake case."""
    return "".join(["_" + i.lower() if i.isupper() else i for i in name]).lstrip("_")


def snake_to_camel(name: str) -> str:
    """Converts a snake case string to camel case."""
    return "".join([i.capitalize() for i in name.split("_")])


def short_dir(direction: str) -> str:
    """Returns the short direction string."""
    return "in" if direction == "input" else "out"


def sv_param_decl(
    name: str,
    value: Union[int, str],
    ptype: str = "localparam",
    dtype: str = "int unsigned",
    array_size: int = None,
) -> str:
    """Declare a SystemVerilog parameter."""
    assert ptype in ["localparam", "parameter"]
    assert array_size is None or isinstance(array_size, int)
    if array_size is None:
        return f"{ptype} {dtype} {name} = {value};\n"
    return f"{ptype} {dtype}[{array_size-1}:0] {name} = {value};\n"


def sv_typedef(name: str, dtype: str = "logic", array_size: int = None) -> str:
    """Declare a SystemVerilog typedef."""
    assert array_size is None or isinstance(array_size, int)
    if array_size is None:
        return f"typedef {dtype} {name};\n"
    return f"typedef {dtype}[{array_size-1}:0] {name};\n"


def sv_struct_typedef(name: str, fields: dict, union=False) -> str:
    """Declare a SystemVerilog struct typedef."""
    if union:
        typedef = "typedef union packed {\n"
    else:
        typedef = "typedef struct packed {\n"
    for field, dtype in fields.items():
        typedef += f"    {dtype} {field};\n"
    typedef += f"}} {name};\n\n"
    return typedef

