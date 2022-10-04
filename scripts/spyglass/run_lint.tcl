# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

set PROJECT   floo_noc
set TIMESTAMP [exec date +%Y%m%d_%H%M%S]
set SG_TOP_MODULE $env(SG_TOP_MODULE)

# Add ignored files to this list
set IgnoredFiles [list [exec bender path apb]/src/*.sv]

new_project ${PROJECT}_${SG_TOP_MODULE}_${TIMESTAMP}
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

# Ignore re-defined files
foreach file $IgnoredFiles {
  set_option ignorefile $file
}

# Read the RTL
read_file -type sourcelist tmp/files

# Set options
set_option enableSV12 yes
set_option language_mode mixed
set_option designread_disable_flatten no
set_option mthresh 32768
set_option top ${SG_TOP_MODULE}

# Link Design
current_design ${SG_TOP_MODULE}
compile_design

# Set lint_rtl goal and run
current_goal lint/lint_rtl
run_goal

exec mkdir -p reports
write_report -reportdir reports moresimple > reports/lint.rpt
exit -force
