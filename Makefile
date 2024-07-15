# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

##########
# Common #
##########

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
# MAKEFILE_LIST
MKFILE_DIR  := $(dir $(MKFILE_PATH))

.PHONY: all clean
all: compile-sim
clean: clean-sim clean-spyglass clean-jobs clean-sources

############
# Programs #
############

BENDER     	?= bender
VSIM       	?= questa-2023.4 vsim
SPYGLASS   	?= sg_shell
VERIBLE_FMT	?= verible-verilog-format

#####################
# Compilation Flags #
#####################

BENDER_FLAGS += -t rtl
BENDER_FLAGS += -t test

VLOG_ARGS += -suppress vlog-2583
VLOG_ARGS += -suppress vlog-13314
VLOG_ARGS += -suppress vlog-13233
VLOG_ARGS += -timescale \"1 ns / 1 ps\"

VSIM_TB_DUT ?= floo_noc_router_test

VSIM_FLAGS += -64
VSIM_FLAGS += -t 1ps
# VSIM_FLAGS += -sv_seed 0

# Set the job name and directory if specified
ifdef JOB_NAME
		VSIM_FLAGS += +JOB_NAME=$(JOB_NAME)
endif
ifdef JOB_DIR
		VSIM_FLAGS += +JOB_DIR=$(JOB_DIR)
endif
ifdef LOG_FILE
		VSIM_FLAGS += -l $(LOG_FILE)
		VSIM_FLAGS += -nostdout
endif

# Automatically open the waveform if a wave.tcl file is present
VSIM_FLAGS_GUI += -do "log -r /*"
VSIM_FLAGS_GUI += -voptargs=+acc
ifneq ("$(wildcard hw/tb/wave/$(VSIM_TB_DUT).wave.tcl)","")
    VSIM_FLAGS_GUI += -do "source hw/tb/wave/$(VSIM_TB_DUT).wave.tcl"
endif

###########
# FlooGen #
###########

FLOOGEN ?= floogen

FLOOGEN_OUT_DIR ?= $(MKFILE_DIR)generated
FLOOGEN_PKG_OUT_DIR ?= $(MKFILE_DIR)hw
FLOOGEN_CFG_DIR ?= $(MKFILE_DIR)floogen/examples
FLOOGEN_TPL_DIR ?= $(MKFILE_DIR)floogen/templates

FLOOGEN_PKG_CFG ?= $(shell find $(FLOOGEN_CFG_DIR) -name "*_pkg.yml")
FLOOGEN_PKG_SRC ?= $(patsubst $(FLOOGEN_CFG_DIR)/%_pkg.yml,$(FLOOGEN_PKG_OUT_DIR)/floo_%_pkg.sv,$(FLOOGEN_PKG_CFG))
FLOOGEN_TPL ?= $(shell find $(FLOOGEN_TPL_DIR) -name "*.mako")

.PHONY: install-floogen pkg-sources sources clean-sources

check-floogen:
	@which $(FLOOGEN) > /dev/null || (echo "Error: floogen not found. Please install floogen." && exit 1)

install-floogen:
	@which $(FLOOGEN) > /dev/null || (echo "Installing floogen..." && pip install .)

pkg-sources: check-floogen $(FLOOGEN_PKG_SRC)
$(FLOOGEN_PKG_OUT_DIR)/floo_%_pkg.sv: $(FLOOGEN_CFG_DIR)/%_pkg.yml $(FLOOGEN_TPL)
	$(FLOOGEN) -c $< --only-pkg --pkg-outdir $(FLOOGEN_PKG_OUT_DIR) $(FLOOGEN_ARGS)

sources: check-floogen
	$(FLOOGEN) -c $(FLOOGEN_CFG) -o $(FLOOGEN_OUT_DIR) --pkg-outdir $(FLOOGEN_PKG_OUT_DIR) $(FLOOGEN_ARGS)

clean-sources:
	rm -rf $(FLOOGEN_OUT_DIR)
	rm -f $(FLOOGEN_PKG_SRC)

######################
# Traffic Generation #
######################

TRAFFIC_GEN ?= util/gen_jobs.py
TRAFFIC_TB ?= dma_mesh
TRAFFIC_TYPE ?= random
TRAFFIC_RW ?= read
TRAFFIC_OUTDIR ?= hw/test/jobs

.PHONY: jobs clean-jobs
jobs: $(TRAFFIC_GEN)
	mkdir -p $(TRAFFIC_OUTDIR)
	$(TRAFFIC_GEN) --out_dir $(TRAFFIC_OUTDIR) --tb $(TRAFFIC_TB) --traffic_type $(TRAFFIC_TYPE) --rw $(TRAFFIC_RW)

clean-jobs:
	rm -rf $(TRAFFIC_OUTDIR)

########################
# QuestaSim Simulation #
########################

.PHONY: compile-sim run-sim run-sim-batch clean-sim

scripts/compile_vsim.tcl: Bender.yml
	mkdir -p scripts
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > scripts/compile_vsim.tcl
	$(BENDER) script vsim --vlog-arg="$(VLOG_ARGS)" $(BENDER_FLAGS) | grep -v "set ROOT" >> scripts/compile_vsim.tcl
	echo >> scripts/compile_vsim.tcl

compile-sim: scripts/compile_vsim.tcl
	$(VSIM) -64 -c -do "source scripts/compile_vsim.tcl; quit"

run-sim:
	$(VSIM) $(VSIM_FLAGS) $(VSIM_FLAGS_GUI) $(VSIM_TB_DUT)

run-sim-batch:
	$(VSIM) -c $(VSIM_FLAGS) $(VSIM_TB_DUT) -do "run -all; quit"

clean-sim:
	rm -rf scripts/compile_vsim.tcl
	rm -rf modelsim.ini
	rm -rf transcript
	rm -rf work*

####################
# Spyglass Linting #
####################

SP_TOP_MODULE ?= floo_mesh

.PHONY: run-spyglass clean-spyglass

spyglass/sources.f:
	$(BENDER) script flist -t spyglass | grep -v "set ROOT" >> spyglass/sources.f
	echo >> spyglass/sources.f

run-spyglass: spyglass/sources.f
	echo "set TOP_MODULE ${SP_TOP_MODULE}" > spyglass/set_top.tcl
	cd spyglass && $(SPYGLASS) -tcl set_top.tcl -tcl run_spyglass_lint.tcl
	rm spyglass/set_top.tcl

clean-spyglass:
	rm -f spyglass/sources.f
	rm -rf spyglass/reports
	rm -rf spyglass/floo_noc*
	rm -f spyglass/sg_shell_command.log
	rm -f spyglass/set_top.tcl
