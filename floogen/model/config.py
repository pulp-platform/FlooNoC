# Copyright 2026 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from pydantic import BaseModel, ConfigDict


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
