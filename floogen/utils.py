#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import math
import shutil
import subprocess
from typing import Union, List


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


def bool_to_sv(value: bool) -> str:
    """Converts a boolean to a SystemVerilog string."""
    return "1'b1" if value else "1'b0"


def int_to_hex(value: int, width: int) -> str:
    """Converts an integer to a hex string."""
    return f"{width}'h{value:0{width//4}x}"


def sv_param_decl(
    name: str,
    value: Union[int, str],
    ptype: str = "localparam",
    dtype: str = "int unsigned",
    array_size: Union[int, str, List[Union[int, str]]] = None,
) -> str:
    """Declare a SystemVerilog parameter."""
    assert ptype in ["localparam", "parameter"]
    def _array_fmt(size):
        if isinstance(size, int):
            return f"[{size-1}:0]"
        return f"[{size}:0]"

    if array_size is None:
        return f"{ptype} {dtype} {name} = {value};\n"
    if isinstance(array_size, (int, str)):
        return f"{ptype} {dtype}{_array_fmt(array_size)} {name} = {value};\n"
    if isinstance(array_size, list):
        array_fmt = "".join([_array_fmt(size) for size in array_size])
        return f"{ptype} {dtype}{array_fmt} {name} = {value};\n"
    raise ValueError("array_size must be int, str, or list.")


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

def sv_struct_render(fields: dict) -> str:
    """
        Declare a SystemVerilog struct based on a (nested) dictionary,
        where they keys of the dictionary are the field names, and the values are
        the actual values to assign.

        Example:
            fields = {'field1': '3'd0',
                      'field2': {'subfield1': 'some_signal',
                                 'subfield2': 'SomeParam'}}
            sv_struct_render(fields) ->
            '{
                field1: 3'd0,
                field2: '{
                    subfield1: some_signal,
                    subfield2: SomeParam
                },
            }'
    """
    decl = "'{"
    for field, value in fields.items():
        # If the `value` itself is a dict, recursively render it as a struct
        if isinstance(value, dict):
            value = sv_struct_render(value)
        decl += f"    {field}: {value},\n"
    return decl[:-2] + "}"

def sv_enum_typedef(name: str, fields_dict: dict=None, fields_list: list=None) -> str:
    """Declare a SystemVerilog enum typedef."""
    if fields_dict is not None:
        bitwidth = clog2(max(fields_dict.values()) + 1)
        typedef = f"typedef enum logic[{bitwidth-1}:0] {{\n"
        for field, value in fields_dict.items():
            typedef += f"    {snake_to_camel(field)} = {value},\n"
        typedef = typedef[:-2] + f"}} {name};\n\n"
    elif fields_list is not None:
        bitwidth = clog2(len(fields_list))
        typedef = f"typedef enum logic[{bitwidth-1}:0] {{\n"
        for i, field in enumerate(fields_list):
            typedef += f"    {snake_to_camel(field)} = {i},\n"
        typedef += f"}} {name};\n\n"
    else:
        raise ValueError("fields_dict or fields_list must be provided.")
    return typedef


def verible_format(string: str, verible_fmt_bin=None, verible_fmt_args=None) -> str:
    """Format the string using verible-verilog-format."""
    if verible_fmt_bin is None:
        verible_fmt_bin = shutil.which("verible-verilog-format")  # Fallback to `which`
    if verible_fmt_bin is None:
        print(
            "\033[93mWarning:\033[0m Output formatting is skipped because \
            `verible-verilog-format` was not found in the `PATH` \
             Please install it or use the `--no-format` flag to skip formatting. \
             Alternatively, you can also specify the path to the binary with the \
            `--verible-fmt-bin` flag."
        )
        return string

    if verible_fmt_args is None:
        verible_fmt_args = []
    else:
        verible_fmt_args = verible_fmt_args.split()

    # Format the output using verible-verilog-format, by piping it into the stdin
    # of the formatter and capturing the stdout
    return subprocess.run(
        verible_fmt_bin.split() + verible_fmt_args + ["-"],
        input=string,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
