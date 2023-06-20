# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Author: Michael Rogenmoser <michaero@iis.ee.ethz.ch>
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

BENDER ?= bender
VSIM ?= questa-2022.3 vsim
SPYGLASS ?= sg_shell
VERIBLE_FMT ?= verible-verilog-format

BENDER_FLAGS += -t rtl
BENDER_FLAGS += -t test

VLOG_ARGS += -suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale \"1 ns / 1 ps\"

VSIM_TB_DUT ?= floo_noc_router_test
VSIM_FLAGS += -64
VSIM_FLAGS += -t 1ps
VSIM_FLAGS += -sv_seed 0
VSIM_FLAGS += -voptargs=+acc
VSIM_FLAGS_GUI += -do "log -r /*"
ifneq ("$(wildcard test/$(VSIM_TB_DUT).wave.do)","")
    VSIM_FLAGS_GUI += -do "source test/$(VSIM_TB_DUT).wave.tcl"
endif

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


SP_TOP_MODULE ?= floo_mesh

.PHONY: sources
sources: util/flit_gen.py $(shell find util/*.hjson)
	./util/flit_gen.py -c util/axi_cfg.hjson
	./util/flit_gen.py -c util/narrow_wide_cfg.hjson
	$(VERIBLE_FMT) --inplace --try_wrap_long_lines src/*flit_pkg.sv

.PHONY: jobs
jobs: util/gen_jobs.py
	mkdir -p test/jobs
	./util/gen_jobs.py --out_dir test/jobs

scripts/compile_vsim.tcl: Bender.yml
	mkdir -p scripts
	echo 'set ROOT [file normalize [file dirname [info script]]/..]' > scripts/compile_vsim.tcl
	$(BENDER) script vsim --vlog-arg="$(VLOG_ARGS)" $(BENDER_FLAGS) | grep -v "set ROOT" >> scripts/compile_vsim.tcl
	echo >> scripts/compile_vsim.tcl

sim_compile: scripts/compile_vsim.tcl
	$(VSIM) -64 -c -do "source scripts/compile_vsim.tcl; quit"

sim_run:
	$(VSIM) $(VSIM_FLAGS) $(VSIM_FLAGS_GUI) $(VSIM_TB_DUT)

sim_run_c:
	$(VSIM) -c $(VSIM_FLAGS) $(VSIM_TB_DUT) -do "run -all; quit"

sim_clean:
	rm -rf scripts/compile_vsim.tcl
	rm -rf modelsim.ini
	rm -rf transcript
	rm -rf work*

spyglass/sources.f:
	$(BENDER) script flist -t spyglass | grep -v "set ROOT" >> spyglass/sources.f
	echo >> spyglass/sources.f

spyglass_run: spyglass/sources.f
	echo "set TOP_MODULE ${SP_TOP_MODULE}" > spyglass/set_top.tcl
	cd spyglass && $(SPYGLASS) -tcl set_top.tcl -tcl run_spyglass_lint.tcl
	rm spyglass/set_top.tcl

spyglass_clean:
	rm -f spyglass/sources.f
	rm -rf spyglass/reports
	rm -rf spyglass/floo_noc*
	rm -f spyglass/sg_shell_command.log
	rm -f spyglass/set_top.tcl

.PHONY: sim_clean sim_compile sim_run sim_run_c


.PHONY: clean
clean: sim_clean spyglass_clean
