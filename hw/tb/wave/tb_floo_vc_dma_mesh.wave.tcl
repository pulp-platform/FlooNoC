# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

source hw/tb/wave/wave.tcl

floo_wave_init

set tb_name tb_floo_vc_dma_mesh

set routers [find instances -bydu floo_vc_narrow_wide_router -nodu]
set num_y [regexp -all {x\[0\]} $routers]
set num_x [regexp -all {y\[0\]} $routers]

for {set y 0} {$y < $num_y} {incr y} {
  for {set x 0} {$x < $num_x} {incr x} {
    set groups [list Node X=${x} Y=${y}]
    floo_vc_narrow_wide_chimney_wave $tb_name/gen_x[$x]/gen_y[$y]/i_dma_chimney [concat $groups [list Chimney]]
    floo_router_wave $tb_name/gen_x[$x]/gen_y[$y]/i_router [concat $groups [list Router]]

    floo_add_wave $tb_name/gen_x[$x]/gen_y[$y]/i_axi_narrow_bw_monitor/*in_flight_o $groups 1
    floo_add_wave $tb_name/gen_x[$x]/gen_y[$y]/i_axi_wide_bw_monitor/*in_flight_o $groups 1
  }
}

for {set y 0} {$y < $num_y} {incr y} {
  # East
  floo_vc_narrow_wide_chimney_wave $tb_name/gen_hbm_chimneys[1]/i_hbm_chimney[$y] [list HBM East "Channel ${y}" Chimney]
  # West
  floo_vc_narrow_wide_chimney_wave $tb_name/gen_hbm_chimneys[3]/i_hbm_chimney[$y] [list HBM West "Channel ${y}" Chimney]

}

for {set x 0} {$x < $num_x} {incr x} {
  # North
  floo_vc_narrow_wide_chimney_wave $tb_name/gen_hbm_chimneys[0]/i_hbm_chimney[$x] [list HBM North "Channel ${x}" Chimney]
  # South
  floo_vc_narrow_wide_chimney_wave $tb_name/gen_hbm_chimneys[2]/i_hbm_chimney[$x] [list HBM South "Channel ${x}" Chimney]
}

floo_wave_style
