# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Tests for the JSON schema emitted by `floogen schema`.

The schema is only useful if it agrees with the validation the models actually
perform. The coercions that let a config write `route_algo: XY` or
`dst_dir: Eject` are invisible to pydantic's schema generation unless they are
declared, so the load-bearing test here is that every shipped example validates.
"""

import pathlib

import pytest
import ruamel.yaml
from jsonschema import Draft202012Validator

from floogen.model.network import config_json_schema

EXAMPLES = sorted((pathlib.Path(__file__).parents[1] / "examples").glob("*.yml"))


@pytest.fixture(scope="module")
def validator():
    # No return annotation: `jsonschema` builds its validator classes dynamically, so
    # `Draft202012Validator` is a variable rather than a type as far as `ty` is concerned.
    schema = config_json_schema()
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def test_examples_exist():
    """Guard against the parametrised test below silently covering nothing."""
    assert EXAMPLES


@pytest.mark.parametrize("example", EXAMPLES, ids=lambda p: p.name)
def test_example_config_validates_against_schema(validator, example):
    config = ruamel.yaml.YAML(typ="safe").load(example.read_text())
    errors = sorted(validator.iter_errors(config), key=lambda e: list(e.path))
    assert not errors, "\n".join(f"/{'/'.join(map(str, e.path))}: {e.message}" for e in errors)


def test_unknown_top_level_key_is_rejected(validator):
    """`extra="forbid"` must reach the schema as `additionalProperties: false`."""
    config = ruamel.yaml.YAML(typ="safe").load(EXAMPLES[0].read_text())
    config["not_a_real_key"] = 1
    assert list(validator.iter_errors(config))


def test_enum_schema_lists_names_as_well_as_values(validator):
    """Configs select enum members by name, so the schema has to accept those."""
    route_algo = validator.schema["$defs"]["RouteAlgo"]["enum"]
    assert {"XY", "XYRouting", "SRC", "SourceRouting"} <= set(route_algo)


def test_decouple_rw_schema_keeps_the_bool_shorthand(validator):
    decouple_rw = validator.schema["$defs"]["WideRwDecouple"]["enum"]
    assert {"Phys", "PHYS", True, False} <= set(decouple_rw)


def test_graph_is_not_part_of_the_schema(validator):
    """`graph` is elaboration state, not something a config file declares."""
    assert "graph" not in validator.schema["properties"]
