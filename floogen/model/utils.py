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

import math

def cdiv(x, y):
    """Returns the ceiling of x/y."""
    return -(-x // y)

def clog2(x):
    """Returns the ceiling of log2(x)."""
    return math.ceil(math.log2(x))

def camel_to_snake(name):
    """Converts a camel case string to snake case."""
    return "".join(["_" + i.lower() if i.isupper() else i for i in name]).lstrip("_")

def snake_to_camel(name):
    """Converts a snake case string to camel case."""
    return "".join([i.capitalize() for i in name.split("_")])
