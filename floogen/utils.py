# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import math
import shutil
import subprocess
import sysconfig


def cdiv(x: float, y: float) -> int:
    """Compute the ceiling of x / y.

    Examples:
        >>> cdiv(7, 2)
        4

    Args:
        x (int, float): Numerator.
        y (int, float): Denominator.

    Returns:
        int: Ceiling of x / y.
    """
    return int(-(-x // y))


def clog2(x: float) -> int:
    """Returns the ceiling of log2(x).

    Examples:
        >>> clog2(7)
        3

    Args:
        x (int): Input value.

    Returns:
        int: Ceiling of log2(x).
    """

    return math.ceil(math.log2(x))


def camel_to_snake(name: str) -> str:
    """Converts a camel case string to snake case.

    Examples:
        >>> camel_to_snake("CamelCase")
        'camel_case'

    Args:
        name (str): Input camel case string.

    Returns:
        str: Converted snake case string.
    """
    return "".join(["_" + i.lower() if i.isupper() else i for i in name]).lstrip("_")


def snake_to_camel(name: str) -> str:
    """Converts a snake case string to camel case.

    Examples:
        >>> snake_to_camel("snake_case")
        'SnakeCase'

    Args:
        name (str): Input snake case string.

    Returns:
        str: Converted camel case string.
    """
    return "".join([i.capitalize() for i in name.split("_")])


def short_dir(direction: str) -> str:
    """Returns the short direction string.

    Args:
        direction (str): "input" or "output".

    Returns:
        str: "in" or "out".
    """
    return "in" if direction == "input" else "out"


def bool_to_sv(value: bool) -> str:
    """Converts a boolean to a SystemVerilog string.

    Examples:
        >>> bool_to_sv(True)
        "1'b1"

    Args:
        value (bool): Input boolean value.

    Returns:
        str: "1'b1" if True, "1'b0" if False.
    """
    return "1'b1" if value else "1'b0"


def int_to_hex(value: int, width: int) -> str:
    """Converts an integer to a hex string.

    Examples:
        >>> int_to_hex(255, 8)
        "8'hff"

    Args:
        value (int): Input integer value.
        width (int): Bit width of the value.

    Returns:
        str: Hex string representation of the integer.
    """
    return f"{width}'h{value:0{width // 4}x}"


def sv_param_decl(
    name: str,
    value: int | str,
    ptype: str = "localparam",
    dtype: str = "int unsigned",
    array_size: int | str | list[int | str] | None = None,
) -> str:
    """Declare a SystemVerilog parameter.

    Examples:
        >>> sv_param_decl("Width", 8)
        "localparam int unsigned Width = 8;"
        >>> sv_param_decl("Depth", 16, ptype="parameter", dtype="my_type_t", array_size=4)
        "parameter my_type_t [3:0] Depth = 16;"

    Args:
        name (str): Name of the parameter.
        value (int, str): Value of the parameter.
        ptype (str, optional): Type of the parameter, either "localparam" or "parameter". Defaults to "localparam".
        dtype (str, optional): Data type of the parameter. Defaults to "int unsigned".
        array_size (int, str, list, optional): Size of the array. Can be an integer, a string (for expressions), or a list of integers/strings for multi-dimensional arrays. Defaults to None.

    Returns:
        str: SystemVerilog parameter declaration.
    """
    assert ptype in ["localparam", "parameter"]

    def _array_fmt(size):
        if isinstance(size, int):
            return f"[{size - 1}:0]"
        return f"[{size}:0]"

    if array_size is None:
        return f"{ptype} {dtype} {name} = {value};\n"
    if isinstance(array_size, (int, str)):
        return f"{ptype} {dtype}{_array_fmt(array_size)} {name} = {value};\n"
    if isinstance(array_size, list):
        array_fmt = "".join([_array_fmt(size) for size in array_size])
        return f"{ptype} {dtype}{array_fmt} {name} = {value};\n"
    raise ValueError("array_size must be int, str, or list.")


def sv_typedef(name: str, dtype: str = "logic", array_size: int | None = None) -> str:
    """Declare a SystemVerilog typedef.

    Examples:
        >>> sv_typedef("my_type_t", "logic", 8)
        "typedef logic[7:0] my_type_t;"

    Args:
        name (str): Name of the typedef.
        dtype (str, optional): Data type of the typedef. Defaults to "logic".
        array_size (int, optional): Size of the array. If None, a scalar type is declared. Defaults to None.

    Returns:
        str: SystemVerilog typedef declaration.
    """
    assert array_size is None or isinstance(array_size, int)
    if array_size is None:
        return f"typedef {dtype} {name};\n"
    return f"typedef {dtype}[{array_size - 1}:0] {name};\n"


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


def sv_enum_typedef(
    name: str, fields_dict: dict | None = None, fields_list: list | None = None
) -> str:
    """Declare a SystemVerilog enum typedef.

    Examples:
        >>> sv_enum_typedef("my_enum_e", fields_list=["field_one", "field_two"])
        "typedef enum logic[0:0] {
            FieldOne = 0,
            FieldTwo = 1
        } my_enum_e;"
        >>> sv_enum_typedef("my_enum_e", fields_dict={"field_one": 4, "field_two": 6})
        "typedef enum logic[2:0] {
            FieldOne = 4,
            FieldTwo = 6
        } my_enum_e;"

    Args:
        name (str): Name of the enum typedef.
        fields_dict (dict, optional): Dictionary of field names and their corresponding values. Defaults to None.
        fields_list (list, optional): List of field names. Values will be assigned automatically starting from 0. Defaults to None.

    Returns:
        str: SystemVerilog enum typedef declaration.
    """
    if fields_dict is not None:
        bitwidth = clog2(max(fields_dict.values()) + 1)
        typedef = f"typedef enum logic[{bitwidth - 1}:0] {{\n"
        for field, value in fields_dict.items():
            typedef += f"    {snake_to_camel(field)} = {value},\n"
        typedef = typedef[:-2] + f"}} {name};\n\n"
    elif fields_list is not None:
        bitwidth = clog2(len(fields_list))
        typedef = f"typedef enum logic[{bitwidth - 1}:0] {{\n"
        for i, field in enumerate(fields_list):
            typedef += f"    {snake_to_camel(field)} = {i},\n"
        typedef += f"}} {name};\n\n"
    else:
        raise ValueError("fields_dict or fields_list must be provided.")
    return typedef


def find_astli_bin() -> str:
    """Locate the `astli` binary installed alongside floogen.

    The `astli` wheel only ships a binary, which lands in the scripts directory of the
    interpreter's environment. That directory is not on the `PATH` if the environment
    is not activated, so it is searched first before falling back to the `PATH`.

    Returns:
        str: Path to the `astli` binary.

    Raises:
        FileNotFoundError: If the binary can be found neither in the scripts directory
            nor in the `PATH`.
    """
    astli_bin = shutil.which("astli", path=sysconfig.get_path("scripts")) or shutil.which("astli")
    if astli_bin is None:
        raise FileNotFoundError(
            "`astli` was not found, which is required to format the output. "
            "Reinstall floogen or use the `--no-format` flag to skip formatting."
        )
    return astli_bin


def astli_format(string: str) -> str:
    """Format the string using astli.

    Args:
        string (str): Input string to format.

    Returns:
        str: Formatted string.
    """
    # Format the output using astli, by piping it into the stdin
    # of the formatter and capturing the stdout
    return subprocess.run(
        [find_astli_bin(), "fmt", "-"],
        input=string,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
