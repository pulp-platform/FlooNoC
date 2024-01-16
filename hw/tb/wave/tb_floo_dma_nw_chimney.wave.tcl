# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

source hw/tb/wave/wave.tcl

floo_wave_init

for {set i 0} {$i < 2} {incr i} {
    set name [list "Chimney $i"]
    set dut tb_floo_dma_nw_chimney/i_floo_narrow_wide_chimney_${i}
    floo_narrow_wide_chimney_wave $dut $name
}

floo_wave_style
