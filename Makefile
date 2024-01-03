# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

##########
# Common #
##########

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))

.PHONY: all clean
all: compile-sim
clean: clean-sim clean-spyglass clean-jobs clean-sources

############
# Programs #
############

BENDER     	?= bender
VSIM       	?= questa-2022.3 vsim
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
VSIM_FLAGS += -sv_seed 0
VSIM_FLAGS += -voptargs=+acc

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
ifneq ("$(wildcard test/$(VSIM_TB_DUT).wave.tcl)","")
    VSIM_FLAGS_GUI += -do "source test/$(VSIM_TB_DUT).wave.tcl"
endif

###################
# Flit Generation #
###################

FLIT_OUT_DIR ?= hw
FLIT_CFG_DIR ?= util
FLIT_CFG ?= $(shell find $(FLIT_CFG_DIR) -name "*.hjson")
FLIT_SRC ?= $(patsubst $(FLIT_CFG_DIR)/%_cfg.hjson,$(FLIT_OUT_DIR)/floo_%_pkg.sv,$(FLIT_CFG))
FLIT_GEN ?= util/flit_gen.py
FLIT_TPL ?= util/floo_flit_pkg.sv.mako

.PHONY: sources clean-sources

sources: $(FLIT_SRC)
$(FLIT_OUT_DIR)/floo_%_pkg.sv: $(FLIT_CFG_DIR)/%_cfg.hjson $(FLIT_GEN) $(FLIT_TPL)
	$(FLIT_GEN) -c $< > $@
	$(VERIBLE_FMT) --inplace --try_wrap_long_lines $@

clean-sources:
	rm -f $(FLIT_SRC)

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

scripts/compile_vsim.tcl: Bender.yml sources
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
