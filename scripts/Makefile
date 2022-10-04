# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

SNPS_SG     ?= spyglass-2022.06 sg_shell

# PHONY since these targets are all pretty fast compared to spyglass
.PHONY: lint gen_script

lint: gen_script spyglass/run_lint.tcl
	cd spyglass; $(SNPS_SG) -tcl run_lint.tcl

gen_script:
	mkdir -p spyglass/tmp
	bender script flist -t spyglass $(bender_defs) > spyglass/tmp/files
