# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

onerror {resume}
quietly WaveActivateNextPane {} 0

delete wave *

set num_phys_channels [expr [llength [find instances -bydu floo_wormhole_arbiter]] / 2 / 2]
set normal_rob [expr [llength [find instances -bydu floo_rob]] / 2 == 2]
set simple_rob [expr [llength [find instances -bydu floo_simple_rob]] / 2 == 2]

for {set i 0} {$i < 2} {incr i} {
    set group_name "Adapter $i"

    add wave -noupdate -expand -group $group_name -ports tb_floo_axi_chimney/i_floo_axi_chimney_${i}/*

    add wave -noupdate -expand -group $group_name -group Arbiter -group ArbiterReq -ports tb_floo_axi_chimney/i_floo_axi_chimney_${i}/i_req_wormhole_arbiter/*
    add wave -noupdate -expand -group $group_name -group Arbiter -group ArbiterRsp -ports tb_floo_axi_chimney/i_floo_axi_chimney_${i}/i_rsp_wormhole_arbiter/*

    add wave -noupdate -expand -group $group_name -group Arbiter tb_floo_axi_chimney/i_floo_axi_chimney_${i}/aw_w_sel_q
    add wave -noupdate -expand -group $group_name -group Arbiter tb_floo_axi_chimney/i_floo_axi_chimney_${i}/aw_w_sel_d

    add wave -noupdate -expand -group $group_name -group Packer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/floo_axi_aw
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/floo_axi_w
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/floo_axi_b
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/floo_axi_ar
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/floo_axi_r

    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_axi_chimney/i_floo_axi_chimney_${i}/axi_unpack_aw
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_axi_chimney/i_floo_axi_chimney_${i}/axi_unpack_w
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_axi_chimney/i_floo_axi_chimney_${i}/axi_unpack_ar
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_axi_chimney/i_floo_axi_chimney_${i}/axi_unpack_b
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_axi_chimney/i_floo_axi_chimney_${i}/axi_unpack_r

    add wave -noupdate -expand -group $group_name -group AwMetaBuffer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/i_aw_meta_buffer/*
    add wave -noupdate -expand -group $group_name -group ArMetaBuffer tb_floo_axi_chimney/i_floo_axi_chimney_${i}/i_ar_meta_buffer/*

    if {$normal_rob} {
        add wave -noupdate -expand -group $group_name -group R_RoB -group StatusTable tb_floo_axi_chimney/i_floo_axi_chimney_${i}/gen_rob/i_r_rob/i_floo_rob_status_table/*
        add wave -noupdate -expand -group $group_name -group R_RoB tb_floo_axi_chimney/i_floo_axi_chimney_${i}/gen_rob/i_r_rob/*
    } elseif {$simple_rob} {
        add wave -noupdate -expand -group $group_name -group R_RoB tb_floo_axi_chimney/i_floo_axi_chimney_${i}/gen_simple_rob/i_r_rob/*
    } else {
        add wave -noupdate -expand -group $group_name -group R_RoB tb_floo_axi_chimney/i_floo_axi_chimney_${i}/i_r_rob/*
    }

    add wave -noupdate -expand -group $group_name -group B_RoB tb_floo_axi_chimney/i_floo_axi_chimney_${i}/i_b_rob/*

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
