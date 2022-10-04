onerror {resume}
quietly WaveActivateNextPane {} 0

delete wave *

set tb_name tb_floo_dma_mesh

set routers [find instances -bydu floo_narrow_wide_router -nodu]
set num_y [regexp -all {x\[0\]} $routers]
set num_x [regexp -all {y\[0\]} $routers]

for {set y 0} {$y < $num_y} {incr y} {
  for {set x 0} {$x < $num_x} {incr x} {
    add wave -noupdate -expand -group "Node" -group "X=${x}" -group "Y=${y}" -expand -group Chimney -ports $tb_name/gen_x[$x]/gen_y[$y]/i_dma_chimney/*
    add wave -noupdate -expand -group "Node" -group "X=${x}" -group "Y=${y}" -expand -group Router -ports $tb_name/gen_x[$x]/gen_y[$y]/i_router/*

    add wave -noupdate -expand -group "Node" -group "X=${x}" -group "Y=${y}" $tb_name/gen_x[$x]/gen_y[$y]/i_axi_narrow_bw_monitor/ar_in_flight_o
    add wave -noupdate -expand -group "Node" -group "X=${x}" -group "Y=${y}" $tb_name/gen_x[$x]/gen_y[$y]/i_axi_wide_bw_monitor/ar_in_flight_o
    add wave -noupdate -expand -group "Node" -group "X=${x}" -group "Y=${y}" $tb_name/gen_x[$x]/gen_y[$y]/i_axi_narrow_bw_monitor/aw_in_flight_o
    add wave -noupdate -expand -group "Node" -group "X=${x}" -group "Y=${y}" $tb_name/gen_x[$x]/gen_y[$y]/i_axi_wide_bw_monitor/aw_in_flight_o
  }
}

for {set y 0} {$y < $num_y} {incr y} {
  # East
  add wave -noupdate -expand -group HBM -group East -group "Channel ${y}" -ports $tb_name/gen_hbm_chimneys[2]/i_hbm_chimney[$y]/*
  # West
  add wave -noupdate -expand -group HBM -group West -group "Channel ${y}" -ports $tb_name/gen_hbm_chimneys[4]/i_hbm_chimney[$y]/*

}

for {set x 0} {$x < $num_x} {incr x} {
  # North
  add wave -noupdate -expand -group HBM -group North -group "Channel ${x}" -ports $tb_name/gen_hbm_chimneys[1]/i_hbm_chimney[$x]/*
  # South
  add wave -noupdate -expand -group HBM -group South -group "Channel ${x}" -ports $tb_name/gen_hbm_chimneys[3]/i_hbm_chimney[$x]/*
}

TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 110
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
