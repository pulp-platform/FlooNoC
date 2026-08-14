# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import logging
from collections.abc import Mapping
from pathlib import Path
from typing import TypeVar

import ruamel.yaml
from pydantic import BaseModel, ValidationError
from ruamel.yaml import YAMLError
from ruamel.yaml.comments import CommentedMap

from floogen.params import ParamError, resolve_params

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


class ConfigError(Exception):
    """Raised when a configuration file cannot be parsed or validated.

    The specific problems are reported through `logger` before this is raised, so callers
    should report only this exception's message rather than a traceback.
    """


def parse_config(
    cls: type[T], config_file: Path, param_overrides: dict[str, str] | None = None
) -> T:
    """Parses a configuration file and returns a validated model.

    `${...}` parameter references are resolved between loading and validation, so the
    models only ever see plain values. See `floogen.params` for the reference syntax.

    Args:
        cls: The model to validate the configuration against.
        config_file: Path to the configuration file.
        param_overrides: Raw `-P NAME=VALUE` overrides keyed by parameter name.

    Raises:
        ConfigError: If the file is not valid YAML, has unresolvable parameters, or does
            not validate against `cls`.
    """
    with config_file.open() as file:
        try:
            config_data = ruamel.yaml.YAML(typ="rt").load(file)
        except YAMLError as e:
            logger.error("Error while parsing config_file:\n %s", e)
            raise ConfigError(f"Could not parse '{config_file}' as YAML") from e

    try:
        resolve_params(config_data, param_overrides)
    except ParamError as e:
        logger.error("Error while resolving the parameters of '%s':", config_file)
        logger.error("Error: %s", e)
        raise ConfigError(f"Could not resolve the parameters of '{config_file}'") from e

    try:
        return cls.model_validate(config_data)
    except ValidationError as e:
        logger.error(
            "Encountered %s validation errors while parsing the configuration file:",
            len(e.errors()),
        )
        for error in e.errors():
            # A `model_validator` on the top-level model reports an empty location: the
            # error belongs to the configuration as a whole rather than to any one field.
            field = error["loc"][-1] if error["loc"] else None
            if field is None:
                pass
            elif error["type"] == "extra_forbidden":
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
        raise ConfigError(f"{len(e.errors())} validation error(s) in '{config_file}'") from e
