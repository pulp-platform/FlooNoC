# Copyright 2023 ETH Zurich and University of Bologna
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from typing import Optional, List, Tuple, Dict
from pydantic import BaseModel, field_validator, model_validator


class ConnectionDesc(BaseModel):
    """Connection class to describe a connection between routers and endpoints."""

    description: Optional[str] = ""
    src: str
    dst: str
    src_range: Optional[List[Tuple[int, int]]] = None
    dst_range: Optional[List[Tuple[int, int]]] = None
    src_idx: Optional[List[int]] = None
    dst_idx: Optional[List[int]] = None
    src_lvl: Optional[int] = None
    dst_lvl: Optional[int] = None
    coord_offset: Optional[Dict] = None
    allow_multi: Optional[bool] = False
    bidirectional: Optional[bool] = False

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
