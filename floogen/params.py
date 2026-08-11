# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

"""Generation-time parameters for configuration files.

A configuration may declare a `params` block and refer to those parameters from
anywhere else in the file through `${...}` references:

```yaml
params:
  num_clusters: 4
  cluster_size: 0x1000
  total_size: "${num_clusters * cluster_size}"
```

References are resolved *before* the configuration is validated, so by the time the
pydantic models see it the file contains plain values only. Parameters are therefore a
property of FlooGen's input, not of its output: nothing survives into the generated
SystemVerilog or SystemRDL as a parameter, it is all inlined. The declared values are
additionally emitted as `localparam`s in the generated package for reference.

The text inside `${...}` is an *expression* over the declared parameters, not just a
name, which is what keeps the two substitution modes unambiguous:

- a scalar that is exactly one reference keeps the referenced value's type
  (`size: "${cluster_size}"` yields the integer `4096`),
- a reference embedded in a longer string interpolates textually
  (`desc: "cluster ${num_clusters} regs"` yields a string).

Only a small allowlist of expression syntax is accepted - arithmetic, bit operations,
comparisons and boolean operators over declared parameters and literals. There are
deliberately no calls, attribute accesses, subscripts, comprehensions or conditionals:
a configuration file that can generate *structure* rather than values stops being
checkable against the JSON schema and stops being readable.
"""

import ast
import re
from collections.abc import Callable, MutableMapping, MutableSequence
from typing import Any, TypeAlias

ParamValue: TypeAlias = bool | int | float | str
"""The value a declared parameter may hold."""

PARAMS_KEY = "params"
"""Top-level configuration key holding the parameter declarations."""

_REF = re.compile(r"\$\{([^{}]*)\}")

# Guards `**`: a hardware configuration has no use for an exponent that large, while
# `2 ** 10**9` would otherwise hang the generator on an unbounded integer.
_MAX_EXPONENT = 64

_BIN_OPS: dict[type[ast.operator], Callable[[Any, Any], Any]] = {
    ast.Add: lambda a, b: a + b,
    ast.Sub: lambda a, b: a - b,
    ast.Mult: lambda a, b: a * b,
    ast.Div: lambda a, b: a / b,
    ast.FloorDiv: lambda a, b: a // b,
    ast.Mod: lambda a, b: a % b,
    ast.LShift: lambda a, b: a << b,
    ast.RShift: lambda a, b: a >> b,
    ast.BitOr: lambda a, b: a | b,
    ast.BitAnd: lambda a, b: a & b,
    ast.BitXor: lambda a, b: a ^ b,
}

_UNARY_OPS: dict[type[ast.unaryop], Callable[[Any], Any]] = {
    ast.UAdd: lambda a: +a,
    ast.USub: lambda a: -a,
    ast.Invert: lambda a: ~a,
    ast.Not: lambda a: not a,
}

_COMPARE_OPS: dict[type[ast.cmpop], Callable[[Any, Any], Any]] = {
    ast.Eq: lambda a, b: a == b,
    ast.NotEq: lambda a, b: a != b,
    ast.Lt: lambda a, b: a < b,
    ast.LtE: lambda a, b: a <= b,
    ast.Gt: lambda a, b: a > b,
    ast.GtE: lambda a, b: a >= b,
}


class ParamError(Exception):
    """Raised when a parameter cannot be declared, overridden or resolved."""


def _eval_node(node: ast.AST, lookup: Callable[[str], ParamValue]) -> Any:
    """Evaluate a single node of an allowlisted expression tree."""
    match node:
        case ast.Constant(value=bool() | int() | float() | str() as value):
            return value
        case ast.Name(id=name):
            return lookup(name)
        case ast.BinOp(left=left, op=op, right=right) if type(op) in _BIN_OPS:
            lhs, rhs = _eval_node(left, lookup), _eval_node(right, lookup)
            return _BIN_OPS[type(op)](lhs, rhs)
        case ast.BinOp(left=left, op=ast.Pow(), right=right):
            base, exponent = _eval_node(left, lookup), _eval_node(right, lookup)
            if isinstance(exponent, (int, float)) and abs(exponent) > _MAX_EXPONENT:
                raise ParamError(f"Exponent {exponent} exceeds the limit of {_MAX_EXPONENT}")
            return base**exponent
        case ast.UnaryOp(op=op, operand=operand) if type(op) in _UNARY_OPS:
            return _UNARY_OPS[type(op)](_eval_node(operand, lookup))
        case ast.BoolOp(op=ast.And(), values=values):
            result = True
            for value in values:
                result = _eval_node(value, lookup)
                if not result:
                    return result
            return result
        case ast.BoolOp(op=ast.Or(), values=values):
            result = False
            for value in values:
                result = _eval_node(value, lookup)
                if result:
                    return result
            return result
        case ast.Compare(left=left, ops=ops, comparators=comparators) if all(
            type(op) in _COMPARE_OPS for op in ops
        ):
            lhs = _eval_node(left, lookup)
            for op, comparator in zip(ops, comparators, strict=True):
                rhs = _eval_node(comparator, lookup)
                if not _COMPARE_OPS[type(op)](lhs, rhs):
                    return False
                lhs = rhs
            return True
        case _:
            raise ParamError(
                f"Unsupported expression syntax '{ast.dump(node)}'. Parameter expressions "
                "support arithmetic, bit operations, comparisons and boolean operators only"
            )


def eval_expr(expr: str, lookup: Callable[[str], ParamValue]) -> ParamValue:
    """Evaluate a `${...}` expression, resolving bare names through `lookup`."""
    try:
        tree = ast.parse(expr.strip(), mode="eval")
    except SyntaxError as e:
        raise ParamError(f"Could not parse parameter expression '{expr}': {e.msg}") from e
    return _eval_node(tree.body, lookup)


def substitute(value: str, lookup: Callable[[str], ParamValue]) -> ParamValue:
    """Resolve every `${...}` reference in a scalar.

    A scalar consisting of a single reference keeps the referenced value's type; a
    reference embedded in surrounding text is interpolated into a string.
    """
    if (whole := _REF.fullmatch(value)) is not None:
        return eval_expr(whole.group(1), lookup)
    if _REF.search(value) is None:
        return value
    return _REF.sub(lambda m: str(eval_expr(m.group(1), lookup)), value)


def _declared_params(config_data: Any) -> dict[str, Any]:
    """Extract and shallow-check the `params` block of a configuration."""
    if not isinstance(config_data, MutableMapping):
        return {}
    declared = config_data.get(PARAMS_KEY)
    if declared is None:
        return {}
    if not isinstance(declared, MutableMapping):
        raise ParamError(f"'{PARAMS_KEY}' must be a mapping of parameter names to values")
    for name, value in declared.items():
        if not isinstance(name, str) or not name.isidentifier():
            raise ParamError(f"Parameter name '{name}' is not a valid identifier")
        if not isinstance(value, (bool, int, float, str)):
            raise ParamError(
                f"Parameter '{name}' must be a boolean, number or string, "
                f"not a {type(value).__name__}"
            )
    return dict(declared)


def _coerce_override(name: str, raw: str, declared: ParamValue) -> ParamValue:
    """Parse a command line override into the type inferred from the declared value.

    `bool` is matched before `int` on purpose: it is a subclass of `int`, so the
    other order would parse `-P enable=false` as an integer and fail.
    """
    match declared:
        case bool():
            if raw.lower() in ("true", "1", "yes", "on"):
                return True
            if raw.lower() in ("false", "0", "no", "off"):
                return False
            raise ParamError(f"Parameter '{name}' is a boolean, but '{raw}' is not")
        case int():
            try:
                # base=0 so that `0x1000`, `0b1010` and `1_000` are all accepted.
                return int(raw, 0)
            except ValueError as e:
                raise ParamError(f"Parameter '{name}' is an integer, but '{raw}' is not") from e
        case float():
            try:
                return float(raw)
            except ValueError as e:
                raise ParamError(f"Parameter '{name}' is a number, but '{raw}' is not") from e
        case _:
            return raw


def _resolve_declarations(
    declared: dict[str, Any], overrides: dict[str, str]
) -> dict[str, ParamValue]:
    """Resolve the parameter declarations against each other and the overrides.

    Parameters may refer to earlier *and* later declarations, so resolution is
    recursive rather than ordered, with the recursion stack doubling as cycle detection.
    """
    unknown = set(overrides) - set(declared)
    if unknown:
        raise ParamError(
            f"Cannot override undeclared parameter(s): {', '.join(sorted(unknown))}. "
            f"Declared parameters are: {', '.join(sorted(declared)) or '<none>'}"
        )

    resolved: dict[str, ParamValue] = {}
    resolving: list[str] = []

    def lookup(name: str) -> ParamValue:
        if name in resolved:
            return resolved[name]
        if name not in declared:
            raise ParamError(
                f"Undeclared parameter '{name}'. "
                f"Declared parameters are: {', '.join(sorted(declared)) or '<none>'}"
            )
        if name in resolving:
            cycle = " -> ".join([*resolving[resolving.index(name) :], name])
            raise ParamError(f"Parameter declarations form a cycle: {cycle}")
        resolving.append(name)
        try:
            value = declared[name]
            if isinstance(value, str):
                value = substitute(value, lookup)
            # The declared value is resolved even when overridden: it is what the
            # override's type is inferred from, and resolving it still validates the
            # declaration itself.
            if name in overrides:
                value = _coerce_override(name, overrides[name], value)
            resolved[name] = value
        finally:
            resolving.pop()
        return resolved[name]

    for name in declared:
        lookup(name)
    return resolved


def _walk(node: Any, lookup: Callable[[str], ParamValue], seen: set[int]) -> None:
    """Substitute every string scalar below `node`, in place.

    Mutating the loaded tree rather than rebuilding it keeps `ruamel`'s line and column
    information intact, which `floogen.config_parser` needs to report validation errors
    against the right line of the file.

    YAML anchors make the same object reachable through several paths, so nodes are
    visited at most once - without that a shared subtree would be substituted repeatedly.
    """
    if isinstance(node, MutableMapping):
        if id(node) in seen:
            return
        seen.add(id(node))
        for key, value in node.items():
            if isinstance(value, str):
                node[key] = substitute(value, lookup)
            else:
                _walk(value, lookup, seen)
    elif isinstance(node, MutableSequence) and not isinstance(node, (str, bytes)):
        if id(node) in seen:
            return
        seen.add(id(node))
        for idx, value in enumerate(node):
            if isinstance(value, str):
                node[idx] = substitute(value, lookup)
            else:
                _walk(value, lookup, seen)


def resolve_params(config_data: Any, overrides: dict[str, str] | None = None) -> dict[str, Any]:
    """Resolve a configuration's `params` block and every `${...}` reference, in place.

    Args:
        config_data: The loaded configuration, mutated in place.
        overrides: Command line overrides, as raw strings keyed by parameter name. Every
            name must be declared in the configuration - overriding an undeclared
            parameter is an error rather than a silent no-op, so that a typo in `-P` is
            reported instead of being ignored.

    Returns:
        The resolved parameters.

    Raises:
        ParamError: If a parameter cannot be declared, overridden or resolved.
    """
    declared = _declared_params(config_data)
    resolved = _resolve_declarations(declared, overrides or {})

    seen: set[int] = set()
    if isinstance(config_data, MutableMapping) and PARAMS_KEY in config_data:
        params_block = config_data[PARAMS_KEY]
        # Write the resolved values back so the model sees values rather than expressions.
        for name, value in resolved.items():
            params_block[name] = value
        # The block is already resolved, so mark it seen to keep `_walk` off it.
        seen.add(id(params_block))

    def lookup(name: str) -> ParamValue:
        if name not in resolved:
            raise ParamError(
                f"Undeclared parameter '{name}'. "
                f"Declared parameters are: {', '.join(sorted(resolved)) or '<none>'}"
            )
        return resolved[name]

    _walk(config_data, lookup, seen)
    return resolved


def parse_overrides(raw_overrides: list[str]) -> dict[str, str]:
    """Parse `NAME=VALUE` command line overrides into a mapping.

    Raises:
        ParamError: If an override is not of the form `NAME=VALUE`.
    """
    overrides: dict[str, str] = {}
    for raw in raw_overrides:
        name, sep, value = raw.partition("=")
        if not sep or not name:
            raise ParamError(f"Invalid parameter override '{raw}', expected the form 'NAME=VALUE'")
        overrides[name.strip()] = value
    return overrides
