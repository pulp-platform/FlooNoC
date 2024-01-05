#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import math


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

