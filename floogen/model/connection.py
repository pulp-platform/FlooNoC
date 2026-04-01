#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

from typing import Optional, List, Tuple
from pydantic import BaseModel, ConfigDict, field_validator, model_validator

from floogen.model.routing import XYDirections


class ConnectionDesc(BaseModel):
    """Connection class to describe a connection between routers and endpoints.

    Attributes:
        src (str): Name of the source component (Endpoint or Router).
        dst (str): Name of the destination component (Endpoint or Router).
        bidirectional (Optional[bool]): If true, creates a full-duplex link (Request and Response channels). Currently, only bidirectional links are supported.
        dst_dir (Optional[int]): Specifies the port direction on the destination router (e.g., `"North"`, `"Local"`, `"Eject"`).
        src_range (Optional[List[Tuple[int, int]]]): Selects a range of indices from the source array to connect. Format: `[(start, end)]` or `[(start_x, end_x), (start_y, end_y)]`.
        dst_range (Optional[List[Tuple[int, int]]]): Selects a range of indices from the destination array to connect.
        src_idx (Optional[List[int]]): Selects specific indices from the source array.
        dst_idx (Optional[List[int]]): Selects specific indices from the destination array.
        allow_multi (Optional[bool]): Allows multiple connections to/from the same port (useful for complex topologies).
        description (Optional[str]): Optional description of the connection.
    """

    model_config = ConfigDict(extra="forbid")

    description: Optional[str] = ""
    src: str
    dst: str
    src_range: Optional[List[Tuple[int, int]]] = None
    dst_range: Optional[List[Tuple[int, int]]] = None
    src_idx: Optional[List[int]] = None
    dst_idx: Optional[List[int]] = None
    src_lvl: Optional[int] = None
    dst_lvl: Optional[int] = None
    dst_dir: Optional[int] = None
    src_dir: Optional[int] = None
    allow_multi: Optional[bool] = False
    bidirectional: Optional[bool] = True

    @field_validator("src_idx", "dst_idx", mode="before")
    @classmethod
    def int_to_list(cls, v):
        """Convert int to list."""
        if isinstance(v, int):
            return [v]
        return v

    @model_validator(mode="after")
    def check_indexing(self):
        """Check if the indexing is valid."""
        if self.src_idx and self.src_lvl:
            raise ValueError("src_idx and src_lvl are mutually exclusive")
        if self.dst_idx and self.dst_lvl:
            raise ValueError("dst_idx and dst_lvl are mutually exclusive")
        return self

    @field_validator("src_dir", "dst_dir", mode="before")
    @classmethod
    def str_to_int(cls, v):
        """Convert str to int."""
        if isinstance(v, str):
            return XYDirections[v.upper()].value
        return v

    @field_validator("bidirectional", mode="after")
    @classmethod
    def check_bidirectional(cls, v):
        """Check if bidirectional is valid."""
        if not v:
            raise NotImplementedError("Unidirectional connections are not supported yet.")
        return v
