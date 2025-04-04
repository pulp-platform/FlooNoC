#!/usr/bin/env python3
# Copyright 2025 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>


def handle_query(network, expr):
    """Safely evaluates an expression within the context of the network."""
    data = network.dict() if hasattr(network, "dict") else network.__dict__

    class ConfigNS:
        """Namespace for configuration data to allow attribute access."""

        def __init__(self, obj):
            self._obj = obj

        def __getitem__(self, key):
            return self._wrap(self._obj[key])

        def __getattr__(self, key):
            if isinstance(self._obj, dict):
                return self._wrap(self._obj[key])
            if isinstance(self._obj, list):
                for item in self._obj:
                    if hasattr(item, "name") and getattr(item, "name") == key:
                        return self._wrap(item)
                # Try again if items were not yet wrapped
                for item in self._wrap(self._obj):
                    if hasattr(item, "name") and getattr(item, "name") == key:
                        return item
                raise AttributeError(f"No item with name '{key}' in list")
            if hasattr(self._obj, key):
                return self._wrap(getattr(self._obj, key))
            raise AttributeError(key)

        def _wrap(self, val):
            if isinstance(val, dict):
                return ConfigNS(val)
            if isinstance(val, list):
                return [ConfigNS(item) if isinstance(item, (dict, list)) else item for item in val]
            return val

        def __repr__(self):
            return repr(self._obj)

        def __iter__(self):
            return iter(self._obj)

        def __len__(self):
            return len(self._obj)

    safe_builtins = {
        "len": len,
        "int": int,
        "float": float,
        "min": min,
        "max": max,
        "sum": sum,
        "abs": abs,
    }

    env = dict(safe_builtins)
    env.update({k: ConfigNS(v) for k, v in data.items()})

    try:
        result = eval(expr, {"__builtins__": {}}, env)
        print(result)
    except Exception as e:
        print(f"Query evaluation error: {e}")
        exit(1)
