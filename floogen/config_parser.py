#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from collections.abc import Mapping
from pathlib import Path
import logging
from typing import TypeVar

from pydantic import ValidationError, BaseModel

from ruamel.yaml.comments import CommentedMap
from ruamel.yaml import YAMLError
import ruamel.yaml

logger = logging.getLogger(__name__)

# ANSI escapes to highlight the error column with a yellow caret.
_YELLOW = "\033[33m"
_RESET = "\033[0m"


def get_error_context(
    config_file: Path, line: int, column: int, context_before: int = 4, context_after: int = 4
) -> str:
    """Return the lines surrounding `line`, with a caret marking `column`."""
    lines = config_file.read_text().splitlines()
    start = max(line - context_before, 1)
    end = min(line + context_after, len(lines))
    context = []
    for lineno in range(start, end + 1):
        context.append(lines[lineno - 1])
        if lineno == line:
            context.append(f"{_YELLOW}{column * ' '}^{_RESET}")
    return "\n".join(context)


def get_file_location(
    config_data: CommentedMap, error_location: tuple[str | int, ...]
) -> tuple[tuple[int, int], Mapping]:
    """Retrieves the location of an error in a configuration file."""
    node = config_data
    location = (node.lc.line + 1, node.lc.col)
    subtree = node
    for path_segment in error_location:
        try:
            location = (node.lc.data[path_segment][0] + 1, node.lc.data[path_segment][1])
            node = node[path_segment]
            if isinstance(node, Mapping):
                subtree = node
        except KeyError:
            break
    return location, subtree


T = TypeVar("T", bound=BaseModel)


def parse_config(cls: type[T], config_file: Path) -> T | None:
    """Parses a configuration file and returns a validated model."""
    with config_file.open() as file:
        try:
            config_data = ruamel.yaml.YAML(typ="rt").load(file)
        except YAMLError as e:
            logger.error("Error while parsing config_file:\n %s", e)
            return None

    try:
        return cls.model_validate(config_data)
    except ValidationError as e:
        logger.error(
            "Encountered %s validation errors while parsing the configuration file:",
            len(e.errors()),
        )
        for error in e.errors():
            field = error["loc"][-1]
            if error["type"] == "extra_forbidden":
                error["msg"] = f"Unknown field '{field}'. Did you misspell the field name?"
            elif error["type"] == "missing":
                error["msg"] = f"Missing field '{field}'"
            else:
                error["msg"] = f"{error['msg']} (field '{field}')"
            (line, column), _ = get_file_location(config_data, error["loc"])
            error_context = get_error_context(config_file, line, column, context_after=10)
            logger.error("Line %s, Column %s:", line, column)
            logger.error("...\n%s\n...", error_context)
            logger.error("Error: %s", error["msg"])
        return None
