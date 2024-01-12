#!/bin/bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

if [ -z "$VSIM" ]; then
  VSIM="vsim"
fi

if [ -z "$BENDER" ]; then
  BENDER="bender"
fi

VSIM_FLAGS+=" -t 1ps"

VSIM_TB_DUT=$1

$VSIM -c $VSIM_FLAGS -do "run -all; quit -f" $VSIM_TB_DUT
