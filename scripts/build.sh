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

VLOG_ARGS+=" -suppress vlog-2583"
VLOG_ARGS+=" -suppress vlog-13314"
VLOG_ARGS+=" -suppress vlog-13233"

BENDER_FLAGS+=" -t rtl"
BENDER_FLAGS+=" -t test"

mkdir -p work
$BENDER script vsim $BENDER_FLAGS --vlog-arg="$VLOG_ARGS" > work/compile.tcl
$VSIM -c -do "source work/compile.tcl; quit -f"
