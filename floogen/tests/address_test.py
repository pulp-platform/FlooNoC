#!/usr/bin/env python3
# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

import pytest
from floogen.model.routing import AddrRange

def test_addr_range_creation1():
    '''Test the creation of an AddrRange object.'''
    addr_range = AddrRange(start=0, end=50)
    assert addr_range.start == 0
    assert addr_range.end == 50
    assert addr_range.size == 50
    assert addr_range.base is None
    assert addr_range.idx is None

def test_addr_range_creation2():
    '''Test the creation of an AddrRange object.'''
    addr_range = AddrRange(start=50, size=100)
    assert addr_range.start == 50
    assert addr_range.end == 150
    assert addr_range.size == 100
    assert addr_range.base is None
    assert addr_range.idx is None

def test_addr_range_creation3():
    '''Test the creation of an AddrRange object.'''
    addr_range = AddrRange(base=50, size=100, idx=5)
    assert addr_range.start == 550
    assert addr_range.end == 650
    assert addr_range.size == 100
    assert addr_range.base == 50
    assert addr_range.idx == 5

def test_addr_range_creation4():
    '''Test the creation of an AddrRange object.'''
    addr_range = AddrRange(base=50, size=100)
    assert addr_range.start == 50
    assert addr_range.end == 150
    assert addr_range.size == 100
    assert addr_range.base == 50
    assert addr_range.idx is None

def test_addr_range_set_idx():
    '''Test the set_idx method of an AddrRange object.'''
    addr_range = AddrRange(base=50, size=100)
    addr_range.set_idx(1)
    assert addr_range.start == 150
    assert addr_range.end == 250
    assert addr_range.size == 100
    assert addr_range.base == 50
    assert addr_range.idx == 1

def test_invalid_addr_range():
    '''Test the validation of an AddrRange object.'''
    with pytest.raises(ValueError):
        AddrRange(start=100, end=0, size=100)

    with pytest.raises(ValueError):
        AddrRange(start=0, end=100, size=0)

    with pytest.raises(ValueError):
        addr_range = AddrRange(start=0, end=100, size=100)
        addr_range.set_idx(2)
