onerror {resume}
quietly WaveActivateNextPane {} 0

delete wave *

set num_phys_channels [expr [llength [find instances i_flit_arb]] / 5]
set simple_rob [expr [llength [find instances -bydu floo_simple_rob]] / 5 == 2]

add wave -noupdate -expand -group MstChimney -ports tb_floo_rob/i_floo_axi_chimney/*

for {set p 0} {$p < $num_phys_channels} {incr p} {
    add wave -noupdate -expand -group MstChimney -group Arbiter -group Arbiter_${p} -ports tb_floo_rob/i_floo_axi_chimney/gen_phys_chan[${p}]/i_floo_wormhole_arbiter/*
}
add wave -noupdate -expand -group MstChimney -group Arbiter tb_floo_rob/i_floo_axi_chimney/aw_w_sel_q
add wave -noupdate -expand -group MstChimney -group Arbiter tb_floo_rob/i_floo_axi_chimney/aw_w_sel_d

add wave -noupdate -expand -group MstChimney -group Packer tb_floo_rob/i_floo_axi_chimney/aw_data
add wave -noupdate -expand -group MstChimney -group Packer tb_floo_rob/i_floo_axi_chimney/w_data
add wave -noupdate -expand -group MstChimney -group Packer tb_floo_rob/i_floo_axi_chimney/b_data
add wave -noupdate -expand -group MstChimney -group Packer tb_floo_rob/i_floo_axi_chimney/ar_data
add wave -noupdate -expand -group MstChimney -group Packer tb_floo_rob/i_floo_axi_chimney/r_data

add wave -noupdate -expand -group MstChimney -group Unpacker tb_floo_rob/i_floo_axi_chimney/unpack_aw_data
add wave -noupdate -expand -group MstChimney -group Unpacker tb_floo_rob/i_floo_axi_chimney/unpack_w_data
add wave -noupdate -expand -group MstChimney -group Unpacker tb_floo_rob/i_floo_axi_chimney/unpack_ar_data
add wave -noupdate -expand -group MstChimney -group Unpacker tb_floo_rob/i_floo_axi_chimney/unpack_b_data
add wave -noupdate -expand -group MstChimney -group Unpacker tb_floo_rob/i_floo_axi_chimney/unpack_r_data

if {$simple_rob} {
  add wave -noupdate -expand -group MstChimney -group R_RoB tb_floo_rob/i_floo_axi_chimney/gen_simple_rob/i_r_rob/*
} else {
  add wave -noupdate -expand -group MstChimney -group R_RoB -group StatusTable tb_floo_rob/i_floo_axi_chimney/gen_rob/i_r_rob/i_floo_rob_status_table/*
  add wave -noupdate -expand -group MstChimney -group R_RoB tb_floo_rob/i_floo_axi_chimney/gen_rob/i_r_rob/*
}
add wave -noupdate -expand -group MstChimney -group B_RoB tb_floo_rob/i_floo_axi_chimney/i_b_rob/*

for {set i 1} {$i <= 4} {incr i} {

  set i_slv [expr $i - 1]


  add wave -noupdate -group SlvChimney${i_slv} -ports tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/*

  for {set p 0} {$p < $num_phys_channels} {incr p} {
    add wave -noupdate -group SlvChimney${i_slv} -group Arbiter -group Arbiter_${p} -ports tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/gen_phys_chan[${p}]/i_floo_wormhole_arbiter/*
  }
  add wave -noupdate -group SlvChimney${i_slv} -group Arbiter tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/aw_w_sel_q
  add wave -noupdate -group SlvChimney${i_slv} -group Arbiter tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/aw_w_sel_d

  add wave -noupdate -group SlvChimney${i_slv} -group Packer tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/aw_data
  add wave -noupdate -group SlvChimney${i_slv} -group Packer tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/w_data
  add wave -noupdate -group SlvChimney${i_slv} -group Packer tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/b_data
  add wave -noupdate -group SlvChimney${i_slv} -group Packer tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/ar_data
  add wave -noupdate -group SlvChimney${i_slv} -group Packer tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/r_data

  add wave -noupdate -group SlvChimney${i_slv} -group Unpacker tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/unpack_aw_data
  add wave -noupdate -group SlvChimney${i_slv} -group Unpacker tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/unpack_w_data
  add wave -noupdate -group SlvChimney${i_slv} -group Unpacker tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/unpack_ar_data
  add wave -noupdate -group SlvChimney${i_slv} -group Unpacker tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/unpack_b_data
  add wave -noupdate -group SlvChimney${i_slv} -group Unpacker tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/unpack_r_data

  if {$simple_rob} {
    add wave -noupdate -group SlvChimney${i_slv} -group R_RoB tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/gen_simple_rob/i_r_rob/*
  } else {
    add wave -noupdate -group SlvChimney${i_slv} -group R_RoB tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/gen_rob/i_r_rob/*
  }
  add wave -noupdate -group SlvChimney${i_slv} -group B_RoB tb_floo_rob/gen_slaves[${i}]/i_floo_axi_chimney/i_b_rob/*

}

add wave -noupdate -expand -group AxiCompare tb_floo_rob/i_axi_reorder_compare/*

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
