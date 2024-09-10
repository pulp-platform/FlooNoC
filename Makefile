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

.PHONY: all clean compile-sim run-sim run-sim-batch
all: compile-sim
clean: clean-vsim clean-spyglass clean-jobs clean-sources clean-vcs
compile-sim: compile-vsim
run-sim: run-vsim
run-sim-batch: run-vsim-batch

############
# Programs #
############

BENDER     	?= bender
VSIM       	?= vsim
SPYGLASS   	?= sg_shell
VERIBLE_FMT	?= verible-verilog-format
VCS		      ?= vcs-2022.06 vcs
VLOGAN  	  ?= vcs-2022.06 vlogan

#####################
# Compilation Flags #
#####################

BENDER_FLAGS += -t rtl
BENDER_FLAGS += -t test
BENDER_FLAGS += -t floo_test
BENDER_FLAGS += -t snitch_cluster
BENDER_FLAGS += -t idma_test
BENDER_FLAGS := $(BENDER_FLAGS) $(EXTRA_BENDER_FLAGS)

WORK 	 		?= work
TB_DUT 		?= floo_noc_router_test

VLOG_ARGS += -suppress vlog-2583
VLOG_ARGS += -suppress vlog-13314
VLOG_ARGS += -suppress vlog-13233
VLOG_ARGS += -timescale \"1 ns / 1 ps\"
VLOG_ARGS += -work $(WORK)

VSIM_FLAGS += -64
VSIM_FLAGS += -t 1ps
VSIM_FLAGS += -sv_seed 0
VSIM_FLAGS += -quiet
VSIM_FLAGS += -work $(WORK)

VLOGAN_ARGS := -assert svaext
VLOGAN_ARGS += -assert disable_cover
VLOGAN_ARGS += -timescale=1ns/1ps

VCS_ARGS    += -Mlib=$(WORK)
VCS_ARGS    += -Mdir=$(WORK)
VCS_ARGS    += -j 8

# Set the job name and directory if specified
ifdef JOB_NAME
		VSIM_FLAGS += +JOB_NAME=$(JOB_NAME)
endif
ifdef TRAFFIC_INJ_RATIO
		VSIM_FLAGS += +TRAFFIC_INJ_RATIO=$(TRAFFIC_INJ_RATIO)
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
ifneq ("$(wildcard hw/tb/wave/$(TB_DUT).wave.tcl)","")
    VSIM_FLAGS_GUI += -do "source hw/tb/wave/$(TB_DUT).wave.tcl"
endif

###########
# FlooGen #
###########

FLOOGEN ?= floogen
FLOO_CFG_DIR ?= $(MKFILE_DIR)floogen/examples
FLOOGEN_CFG ?= $(FLOO_CFG_DIR)/single_cluster.yml

FLOOGEN_OUT_DIR ?= $(MKFILE_DIR)generated

.PHONY: install-floogen pkg-sources sources clean-sources

check-floogen:
	@which $(FLOOGEN) > /dev/null || (echo "Error: floogen not found. Please install floogen." && exit 1)

install-floogen:
	@which $(FLOOGEN) > /dev/null || (echo "Installing floogen..." && pip install .)

sources: check-floogen
	$(FLOOGEN) -c $(FLOOGEN_CFG) -o $(FLOOGEN_OUT_DIR) $(FLOOGEN_ARGS)

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

.PHONY: compile-vsim run-vsim run-vsim-batch clean-vsim

scripts/compile_vsim.tcl: Bender.yml
	mkdir -p scripts
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > scripts/compile_vsim.tcl
	$(BENDER) script vsim --vlog-arg="$(VLOG_ARGS)" $(BENDER_FLAGS) | grep -v "set ROOT" >> scripts/compile_vsim.tcl
	echo >> scripts/compile_vsim.tcl

compile-vsim: scripts/compile_vsim.tcl
	$(VSIM) -64 -c -do "source scripts/compile_vsim.tcl; quit"

run-vsim:
	$(VSIM) $(VSIM_FLAGS) $(VSIM_FLAGS_GUI) $(TB_DUT)

run-vsim-batch:
	$(VSIM) -c $(VSIM_FLAGS) $(TB_DUT) -do "run -all; quit"

clean-vsim:
	rm -rf scripts/compile_vsim.tcl
	rm -rf modelsim.ini
	rm -rf transcript
	rm -rf work*

##################
# VCS Simulation #
##################

.PHONY: compile-vcs clean-vcs run-vcs run-vcs-batch

scripts/compile_vcs.sh: Bender.yml Bender.lock
	@mkdir -p scripts
	$(BENDER) script vcs --vlog-arg "\$(VLOGAN_ARGS)" $(BENDER_FLAGS) --vlogan-bin "$(VLOGAN)" > $@
	chmod +x $@

compile-vcs: scripts/compile_vcs.sh
	$< | tee scripts/compile_vcs.log

bin/%.vcs: scripts/compile_vcs.sh compile-vcs
	mkdir -p bin
	$(VCS) $(VCS_ARGS) $(VCS_PARAMS) $* -o $@

run-vcs run-vcs-batch:
	bin/$(TB_DUT).vcs +permissive -exitstatus +permissive-off

clean-vcs:
	@rm -rf AN.DB
	@rm -f  scripts/compile_vcs.sh
	@rm -rf bin
	@rm -rf work-vcs
	@rm -f  ucli.key
	@rm -f  vc_hdrs.h
	@rm -f  logs/*.vcs.log
	@rm -f  scripts/compile_vcs.log

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
