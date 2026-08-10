# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Shared building blocks for the models parsed from a configuration file.

`ConfigModel` is the base class those models derive from. The `Annotated` aliases
below carry the "the config file may also spell this as ..." coercions that would
otherwise be written out as a `field_validator` on every individual field.
"""

from enum import Enum
from typing import Annotated, Any, TypeVar

from pydantic import BaseModel, BeforeValidator, ConfigDict

T = TypeVar("T")


class ConfigModel(BaseModel):
    """Base class for every model that is parsed directly from a user configuration file.

    Models that only ever get built during elaboration (links, routers, network
    interfaces, ...) derive from `BaseModel` instead - they are constructed from
    known-good keyword arguments, so there is no untrusted input to reject.

    - `extra="forbid"` turns a misspelled key into a validation error, which
      `floogen.config_parser` reports against its exact line and column. Without it a
      typo silently falls back to the field default.
    - `use_attribute_docstrings=True` promotes the docstring written underneath a field
      into that field's schema description, so a generated JSON schema documents itself.
    """

    model_config = ConfigDict(extra="forbid", use_attribute_docstrings=True)


class ConfigEnum(Enum):
    """Enum whose members can also be selected by *name* in a configuration file.

    Several enums carry the SystemVerilog spelling as their value (`RouteAlgo.XY` is
    `"XYRouting"`) while configs refer to them by name (`route_algo: XY`). Resolving
    that here keeps it out of a `mode="before"` validator on every field that uses one.
    Matching is tried on the exact name first, then on the upper-cased name, so both
    `XY` and `xy` resolve.
    """

    @classmethod
    def _missing_(cls, value):
        if isinstance(value, str):
            return cls.__members__.get(value) or cls.__members__.get(value.upper())
        return None


def _as_list(v: Any) -> Any:
    """Wrap a lone item in a list. `None` is passed through so optional fields stay unset."""
    if v is None or isinstance(v, list):
        return v
    return [v]


def _as_tuple(v: Any) -> Any:
    """Wrap a lone integer in a 1-tuple, so `array: 4` means the same as `array: [4]`."""
    if isinstance(v, int):
        return (v,)
    return v


OneOrMany = Annotated[list[T], BeforeValidator(_as_list, json_schema_input_type=list[T] | T)]
"""`list[T]` that also accepts a single `T`, for config keys that are usually singular."""

ArrayDims = Annotated[
    tuple[int] | tuple[int, int],
    BeforeValidator(_as_tuple, json_schema_input_type=int | tuple[int] | tuple[int, int]),
]
"""1D or 2D array dimensions, which may be written as a bare `int` when 1D."""
