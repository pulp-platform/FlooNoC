# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

source hw/tb/wave/wave.tcl

floo_wave_init

set tb_name tb_floo_nw_mesh
set noc_name i_floo_nw_mesh_noc

set routers [find instances -bydu floo_nw_router -nodu]
set num_y [regexp -all {router_0} $routers]
set num_x [expr {[llength $routers] / $num_y}]

for {set y 0} {$y < $num_y} {incr y} {
  for {set x 0} {$x < $num_x} {incr x} {
    set groups [list Node X=${x} Y=${y}]
    floo_nw_chimney_wave $tb_name/$noc_name/cluster_ni_${x}_${y} [concat $groups [list Chimney]]
    floo_router_wave $tb_name/$noc_name/router_${x}_${y} [concat $groups [list Router]]

    floo_add_wave $tb_name/gen_x[$x]/gen_y[$y]/i_axi_narrow_bw_monitor/*in_flight_o $groups 1
    floo_add_wave $tb_name/gen_x[$x]/gen_y[$y]/i_axi_wide_bw_monitor/*in_flight_o $groups 1
  }
}

for {set y 0} {$y < $num_y} {incr y} {
  floo_nw_chimney_wave $tb_name/$noc_name/hbm_ni_${y} [list HBM West "Channel ${y}" Chimney] 1
}

floo_wave_style
