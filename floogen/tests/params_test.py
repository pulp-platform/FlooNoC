# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Tests for generation-time configuration parameters.

The load-bearing cases here are the ones that fail silently rather than loudly: a
`${...}` that keeps or loses its type, a `-P` typo that would otherwise be ignored, and
substitution destroying the line information that config error reporting depends on.
"""

import pathlib
import textwrap

import pytest
import ruamel.yaml

from floogen.config_parser import ConfigError, parse_config
from floogen.model.network import Network
from floogen.params import ParamError, parse_overrides, resolve_params

EXAMPLE = pathlib.Path(__file__).parents[1] / "examples" / "single_cluster.yml"


def load(text: str):
    """Load a YAML snippet the way `parse_config` does, preserving line information."""
    return ruamel.yaml.YAML(typ="rt").load(textwrap.dedent(text))


def resolve(text: str, overrides=None):
    """Load and resolve a YAML snippet, returning the resolved tree."""
    data = load(text)
    resolve_params(data, overrides)
    return data


class TestSubstitution:
    """`${...}` resolution in the configuration tree."""

    def test_whole_scalar_reference_keeps_the_referenced_type(self):
        """The key distinction: a lone reference is a value, not a string."""
        data = resolve("""
            params:
              size: 4096
              enabled: true
            a: "${size}"
            b: "${enabled}"
        """)
        assert data["a"] == 4096
        assert isinstance(data["a"], int)
        assert data["b"] is True

    def test_embedded_reference_interpolates_into_a_string(self):
        data = resolve("""
            params:
              n: 4
            desc: "cluster with ${n} cores"
        """)
        assert data["desc"] == "cluster with 4 cores"

    def test_multiple_references_in_one_scalar_do_not_become_arithmetic(self):
        """`"${a}-${b}"` is text. Only the inside of the braces is an expression."""
        data = resolve("""
            params:
              a: 1
              b: 2
            name: "${a}-${b}"
        """)
        assert data["name"] == "1-2"

    def test_expressions_live_inside_the_braces(self):
        data = resolve("""
            params:
              num_x: 4
              num_y: 8
            total: "${num_x * num_y}"
            shifted: "${1 << 10}"
            compared: "${num_x < num_y}"
        """)
        assert data["total"] == 32
        assert data["shifted"] == 1024
        assert data["compared"] is True

    def test_substitution_reaches_into_lists_and_nested_mappings(self):
        data = resolve("""
            params:
              base: 16
            endpoints:
              - addr_range:
                  start: "${base}"
                  end: "${base * 2}"
        """)
        assert data["endpoints"][0]["addr_range"] == {"start": 16, "end": 32}

    def test_config_without_params_is_untouched(self):
        data = resolve("""
            name: plain
            value: 3
        """)
        assert data == {"name": "plain", "value": 3}

    def test_a_lone_dollar_brace_free_string_is_left_alone(self):
        data = resolve("""
            params:
              n: 1
            desc: "costs $5 {maybe}"
        """)
        assert data["desc"] == "costs $5 {maybe}"


class TestDeclarations:
    """The `params` block itself."""

    def test_params_may_reference_each_other_in_any_order(self):
        """Resolution is recursive, so a declaration may use one written below it."""
        data = resolve("""
            params:
              total: "${per_cluster * clusters}"
              per_cluster: 8
              clusters: 4
        """)
        assert data["params"]["total"] == 32

    def test_resolved_values_are_written_back_into_the_block(self):
        data = resolve("""
            params:
              n: "${2 * 3}"
        """)
        assert data["params"]["n"] == 6

    def test_cycle_is_reported_rather_than_hanging(self):
        with pytest.raises(ParamError, match="cycle"):
            resolve("""
                params:
                  a: "${b}"
                  b: "${a}"
            """)

    def test_reference_to_an_undeclared_param_is_an_error(self):
        with pytest.raises(ParamError, match="Undeclared parameter 'nope'"):
            resolve("""
                params:
                  a: 1
                value: "${nope}"
            """)

    def test_params_block_must_be_a_mapping(self):
        with pytest.raises(ParamError, match="must be a mapping"):
            resolve("""
                params:
                  - a
            """)

    def test_param_name_must_be_an_identifier(self):
        with pytest.raises(ParamError, match="not a valid identifier"):
            resolve("""
                params:
                  "not a name": 1
            """)


class TestExpressionSafety:
    """The expression allowlist."""

    @pytest.mark.parametrize(
        "expr",
        [
            "__import__('os').system('true')",
            "open('/etc/passwd')",
            "n.__class__",
            "[x for x in range(3)]",
            "n if n else 0",
            "lambda: 1",
        ],
    )
    def test_unsupported_syntax_is_rejected(self, expr):
        with pytest.raises(ParamError):
            resolve(f"""
                params:
                  n: 1
                value: "${{{expr}}}"
            """)

    def test_huge_exponent_is_rejected_rather_than_hanging(self):
        with pytest.raises(ParamError, match="Exponent"):
            resolve("""
                params:
                  n: "${2 ** 10000000}"
            """)

    def test_malformed_expression_is_reported(self):
        with pytest.raises(ParamError, match="Could not parse"):
            resolve("""
                params:
                  n: 1
                value: "${n +}"
            """)


class TestOverrides:
    """`-P NAME=VALUE` handling."""

    def test_override_replaces_the_declared_value(self):
        data = resolve(
            """
            params:
              n: 4
            value: "${n}"
            """,
            {"n": "16"},
        )
        assert data["value"] == 16

    def test_override_is_parsed_as_the_inferred_type(self):
        data = resolve(
            """
            params:
              n: 4
              flag: true
              name: "a"
            """,
            {"n": "0x10", "flag": "false", "name": "b"},
        )
        assert data["params"] == {"n": 16, "flag": False, "name": "b"}

    def test_overriding_an_undeclared_param_is_an_error_not_a_no_op(self):
        """A `-P` typo has to be reported; silently ignoring it is the failure mode."""
        with pytest.raises(ParamError, match="undeclared parameter"):
            resolve(
                """
                params:
                  num_cores: 4
                """,
                {"num_core": "8"},
            )

    def test_override_of_the_wrong_type_is_reported(self):
        with pytest.raises(ParamError, match="is an integer"):
            resolve("params:\n  n: 4\n", {"n": "lots"})

    def test_override_propagates_through_dependent_params(self):
        data = resolve(
            """
            params:
              clusters: 2
              cores: "${clusters * 4}"
            """,
            {"clusters": "8"},
        )
        assert data["params"]["cores"] == 32

    @pytest.mark.parametrize(
        ("raw", "expected"),
        [
            ("a=1", {"a": "1"}),
            ("a=0x10", {"a": "0x10"}),
            ("a=", {"a": ""}),
            ("a=b=c", {"a": "b=c"}),
        ],
    )
    def test_parse_overrides_accepts_name_value(self, raw, expected):
        assert parse_overrides([raw]) == expected

    @pytest.mark.parametrize("raw", ["novalue", "=1", ""])
    def test_parse_overrides_rejects_malformed_input(self, raw):
        with pytest.raises(ParamError, match="Invalid parameter override"):
            parse_overrides([raw])


class TestYamlAnchors:
    """Anchors make one object reachable by several paths; substitution must cope."""

    def test_shared_subtree_is_substituted_once_and_correctly(self):
        data = resolve("""
            params:
              size: 4096
            base: &shared
              size: "${size}"
            alias: *shared
        """)
        assert data["base"]["size"] == 4096
        assert data["alias"]["size"] == 4096


class TestConfigIntegration:
    """End-to-end behaviour through `parse_config`."""

    @pytest.fixture
    def config_with_params(self, tmp_path):
        text = (
            EXAMPLE.read_text()
            .replace(
                'network_type: "narrow-wide"',
                'network_type: "narrow-wide"\n\nparams:\n  hbm_size: 0x0000_4000_0000\n',
            )
            .replace("      size: 0x0000_4000_0000", '      size: "${hbm_size}"')
        )
        path = tmp_path / "config.yml"
        path.write_text(text)
        return path

    def test_parsed_config_exposes_resolved_params(self, config_with_params):
        network = parse_config(Network, config_with_params)
        assert network.params == {"hbm_size": 0x4000_0000}

    def test_override_reaches_the_address_map(self, config_with_params):
        network = parse_config(Network, config_with_params, {"hbm_size": "0x8000_0000"})
        hbm = next(ep for ep in network.endpoints if ep.name == "hbm")
        assert [r.size for r in hbm.addr_range] == [0x8000_0000]

    def test_param_error_is_surfaced_as_a_config_error(self, config_with_params):
        with pytest.raises(ConfigError, match="Could not resolve the parameters"):
            parse_config(Network, config_with_params, {"nope": "1"})

    def test_validation_errors_still_report_the_right_line(self, tmp_path, caplog):
        """Substitution mutates the tree in place so `ruamel`'s line info survives.

        Rebuilding it into plain dicts would silently drop `lc.data` and degrade every
        configuration error message, without failing any other test.
        """
        text = (
            EXAMPLE.read_text()
            .replace(
                'network_type: "narrow-wide"',
                'network_type: "narrow-wide"\n\nparams:\n  n: 1\n',
            )
            .replace('route_algo: "ID"', 'route_algo: "NOT_AN_ALGO"')
        )
        path = tmp_path / "config.yml"
        path.write_text(text)

        expected_line = next(
            i for i, line in enumerate(text.splitlines(), start=1) if "NOT_AN_ALGO" in line
        )
        with pytest.raises(ConfigError):
            parse_config(Network, path)
        assert f"Line {expected_line}," in caplog.text

    def test_a_model_level_validation_error_is_reported(self, tmp_path, caplog):
        """A `model_validator` on the whole config reports an empty error location.

        The reporter used to index into it unconditionally and die with an `IndexError`,
        burying the actual problem.
        """
        text = EXAMPLE.read_text().replace("    addr_width: 48", "    addr_width: 32", 1)
        path = tmp_path / "config.yml"
        path.write_text(text)

        with pytest.raises(ConfigError):
            parse_config(Network, path)
        assert "All protocols must have the same address width" in caplog.text


class TestSvRendering:
    """Parameters emitted as package localparams."""

    @pytest.mark.parametrize(
        ("value", "expected"),
        [
            (4, "localparam int unsigned NumCores = 4;"),
            (0xFFFF_FFFF, "localparam int unsigned NumCores = 4294967295;"),
            (0x1_0000_0000, "localparam longint unsigned NumCores = 4294967296;"),
            (-1, "localparam int NumCores = -1;"),
            (True, "localparam bit NumCores = 1'b1;"),
            (False, "localparam bit NumCores = 1'b0;"),
            ("occamy", 'localparam string NumCores = "occamy";'),
        ],
    )
    def test_param_renders_with_a_type_inferred_from_its_value(self, value, expected):
        network = Network.model_construct(params={"num_cores": value})
        assert network.render_params().strip() == expected

    def test_unused_params_are_emitted_too(self):
        network = Network.model_construct(params={"never_referenced": 1})
        assert "NeverReferenced" in network.render_params()
