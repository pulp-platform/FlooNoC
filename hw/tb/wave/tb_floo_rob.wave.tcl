# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

source hw/tb/wave/wave.tcl

floo_wave_init

floo_axi_chimney_wave tb_floo_rob/i_floo_axi_chimney [list MstChimney]

for {set i 1} {$i <= 4} {incr i} {
    set id [expr $i - 1]
    set groups [list SlvChimney${id}]
    floo_axi_chimney_wave tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney $groups 0
}

floo_wave_style
