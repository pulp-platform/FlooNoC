# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

set dotenv-load := true
set shell := ["bash", "-cu"]

bender        := env_var_or_default("BENDER", "bender")
vsim          := env_var_or_default("VSIM", "vsim")
vlogan        := env_var_or_default("VLOGAN", "vlogan")
vcs           := env_var_or_default("VCS", "vcs")
spyglass      := env_var_or_default("SPYGLASS", "sg_shell")

bender_flags  := "-t rtl -t test -t floo_test -t snitch_cluster -t idma_test"
extra_bender_flags := env_var_or_default("EXTRA_BENDER_FLAGS", "")
vlogan_args   := "-assert svaext -assert disable_cover -timescale=1ns/1ps"

# List all available recipes
default:
    @just --list

######################
# Traffic Generation #
######################

# Generate traffic jobs for simulation
[group("traffic")]
[arg('type', long)]
[arg('rw', long)]
jobs tb="dma_mesh" type="random" rw="read":
    mkdir -p hw/test/jobs
    util/gen_jobs.py --out_dir hw/test/jobs --tb {{ tb }} --traffic_type {{ type }} --rw {{ rw }}

# Remove generated traffic jobs
[group("traffic")]
clean-jobs:
    rm -rf hw/test/jobs

###############
# Simulation  #
###############

# Compile design (sim: vsim [default], vcs)
[group("sim")]
[arg('sim', pattern='vsim|vcs')]
[arg('tb', long)]
[arg('work', long)]
compile sim="vsim" tb="" work="work":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ sim }}" in
        vsim)
            mkdir -p scripts
            echo 'set ROOT [file normalize [file dirname [info script]]/..]' > scripts/compile_vsim.tcl
            {{ bender }} script vsim --vlog-arg="-suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale 1ns/1ps -work {{ work }}" {{ bender_flags }} {{ extra_bender_flags }} \
                | grep -v "set ROOT" >> scripts/compile_vsim.tcl
            {{ vsim }} -64 -c -do "source scripts/compile_vsim.tcl; quit" | tee scripts/vsim.log
            ! grep -P "Errors: [1-9]*," scripts/vsim.log
            ;;
        vcs)
            [ -n "{{ tb }}" ] || { echo "Error: tb is required for vcs compile"; exit 1; }
            mkdir -p scripts bin
            {{ bender }} script vcs --vlogan-args="{{ vlogan_args }}" {{ bender_flags }} {{ extra_bender_flags }} \
                --vlogan-bin "{{ vlogan }}" > scripts/compile_vcs.sh
            chmod +x scripts/compile_vcs.sh
            scripts/compile_vcs.sh | tee scripts/compile_vcs.log
            {{ vcs }} -Mlib={{ work }} -Mdir={{ work }} -j 8 {{ tb }} -o bin/{{ tb }}.vcs
            ;;
    esac

# Run simulation GUI (sim: vsim [default], vcs)
[group("sim")]
[arg('sim', pattern='vsim|vcs')]
[arg('tb', long)]
[arg('work', long)]
run sim="vsim" tb="" work="work":
    #!/usr/bin/env bash
    set -euo pipefail
    [ -n "{{ tb }}" ] || { echo "Error: tb is required"; exit 1; }
    case "{{ sim }}" in
        vsim)
            wave_args=""
            if [ -f "hw/tb/wave/{{ tb }}.wave.tcl" ]; then
                wave_args="-do 'source hw/tb/wave/{{ tb }}.wave.tcl'"
            fi
            {{ vsim }} -64 -t 1ps -sv_seed 0 -quiet -work {{ work }} -voptargs=+acc -do "log -r /*" $wave_args {{ tb }}
            ;;
        vcs)
            bin/{{ tb }}.vcs +permissive -exitstatus +permissive-off
            ;;
    esac

# Run simulation in batch mode (sim: vsim [default], vcs)
[group("sim")]
[arg('sim', pattern='vsim|vcs')]
[arg('tb', long)]
[arg('work', long)]
run-batch sim="vsim" tb="" work="work":
    #!/usr/bin/env bash
    set -euo pipefail
    [ -n "{{ tb }}" ] || { echo "Error: tb is required"; exit 1; }
    case "{{ sim }}" in
        vsim) {{ vsim }} -c -64 -t 1ps -sv_seed 0 -quiet -work {{ work }} {{ tb }} -do "run -all; quit" ;;
        vcs)  bin/{{ tb }}.vcs +permissive -exitstatus +permissive-off ;;
    esac

# Remove build artefacts (sim: vsim, vcs; default: all)
[group("sim")]
[arg('sim', pattern='vsim|vcs|all')]
clean sim="all":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ sim }}" in
        vsim) rm -rf scripts/compile_vsim.tcl work* transcript modelsim.ini scripts/vsim.log ;;
        vcs)  rm -rf AN.DB scripts/compile_vcs.sh bin ucli.key vc_hdrs.h scripts/compile_vcs.log ;;
        all)
            just clean vsim
            just clean vcs
            just clean-jobs
            just clean-spyglass
            ;;
    esac

####################
# Spyglass Linting #
####################

# Run Spyglass lint (top: floo_mesh [default])
[group("lint")]
spyglass top="floo_mesh":
    {{ bender }} script flist -t spyglass | grep -v "set ROOT" >> spyglass/sources.f
    echo "set TOP_MODULE {{ top }}" > spyglass/set_top.tcl
    cd spyglass && {{ spyglass }} -tcl set_top.tcl -tcl run_spyglass_lint.tcl
    rm spyglass/set_top.tcl

# Remove Spyglass artefacts
[group("lint")]
clean-spyglass:
    rm -f spyglass/sources.f
    rm -rf spyglass/reports
    rm -rf spyglass/floo_noc*
    rm -f spyglass/sg_shell_command.log
    rm -f spyglass/set_top.tcl

###################
# Physical Design #
###################

pd_remote := "git@iis-git.ee.ethz.ch:axi-noc/floo_noc_pd.git"
pd_branch  := "master"

# Clone physical design repository
[group("pd")]
init-pd:
    rm -rf pd
    git clone {{ pd_remote }} pd -b {{ pd_branch }}
