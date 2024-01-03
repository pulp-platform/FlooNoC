#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from pathlib import Path
import logging
from typing import List, Union, Tuple, Mapping, TypeVar

from pydantic import ValidationError, BaseModel

from ruamel.yaml.comments import CommentedMap
from ruamel.yaml import YAMLError
import ruamel.yaml

import click

logger = logging.getLogger("padrick.ConfigParser")


def get_error_context(config_file: Path, line, column, context_before=4, context_after=4):
    """Retrieves the context surrounding an error in a configuration file."""
    lines_to_return = []
    with config_file.open() as file:
        for line_idx, l in enumerate(file.readlines()):
            if line_idx + 1 == line:
                lines_to_return.append(l)
                lines_to_return.append(click.style(column * " " + "^\n", blink=True, fg="yellow"))
            elif line_idx + 1 >= line - context_before and line_idx + 1 <= line + context_after:
                lines_to_return.append(l)
    return "".join(lines_to_return)


def get_human_readable_error_path(config_data: dict, error_location: List[Union[str, int]]):
    """Transforms a list of path segments into a human readable string."""
    transformed_path_segments = []
    node = config_data
    for path_segment in error_location:
        try:
            node = node[path_segment]
        except KeyError:
            transformed_path_segments.append(path_segment)
            break
        if isinstance(path_segment, int):
            transformed_path_segments.append(node.get("name", path_segment))
        else:
            transformed_path_segments.append(path_segment)
    return "->".join(transformed_path_segments)


def get_file_location(
    config_data: CommentedMap, error_location: List[Union[str, int]]
) -> Tuple[Tuple[int, int], Mapping]:
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


def parse_config(cls: T, config_file: Path) -> Union[T, None]:
    """Parses a configuration file and returns a validated model."""
    with config_file.open() as file:
        try:
            yaml = ruamel.yaml.YAML(typ="rt")
            # enable support for !include directives (see pyyaml-include package)
            # if not include_base_dir:
            #     include_base_dir = config_file.parent
            # if not ignore_includes:
            #     include_constructor = YamlIncludeConstructor(base_dir=str(include_base_dir))
            # else:
            #     include_constructor = IgnoreIncludeConstructor
            # yaml.register_class(include_constructor)
            config_data = yaml.load(file)
            # config_data = ruamel.yaml.load(file, Loader=ruamel.yaml.RoundTripLoader)
        except YAMLError as e:
            logger.error("Error while parsing config_file:\n %s", e)
            return None
        try:
            model = cls.model_validate(config_data)
            return model
        except ValidationError as e:
            logger.error(
                "Encountered %s validation errors while parsing the configuration file:",
                len(e.errors()),
            )
            for error in e.errors():
                if error["type"] == "extra":
                    error[
                        "msg"
                    ] = f'Unknown field {error["loc"][-1]}. \
                        Did you mispell the field name?'
                if error["type"] == "missing":
                    error["msg"] = f'Missing field \'{error["loc"][-1]}\''
                else:
                    error["msg"] = f'{error["msg"]} (field \'{error["loc"][-1]}\')'
                # error_path = get_human_readable_error_path(config_data, error["loc"])
                (line, column), _ = get_file_location(config_data, error["loc"])
                error_context = get_error_context(config_file, line, column, context_after=10)
                logger.error("Line %s, Column %s:", line, column)
                logger.error("...\n%s\n...", error_context)
                logger.error("Error: %s", error["msg"])
            return None
