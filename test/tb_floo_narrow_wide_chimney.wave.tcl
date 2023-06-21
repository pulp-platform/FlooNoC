# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

onerror {resume}
quietly WaveActivateNextPane {} 0

delete wave *

set num_phys_channels [expr [llength [find instances -bydu floo_wormhole_arbiter]] / 2 / 2]
set simple_rob [expr [llength [find instances -bydu floo_simple_rob]] / 2 == 4]

for {set i 0} {$i < 2} {incr i} {
    set group_name "Adapter $i"

    add wave -noupdate -expand -group $group_name -ports tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/*

    add wave -noupdate -expand -group $group_name -group Arbiter -group ArbiterNarrowReq -ports tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/i_narrow_req_wormhole_arbiter/*
    add wave -noupdate -expand -group $group_name -group Arbiter -group ArbiterNarrowRsp -ports tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/i_narrow_rsp_wormhole_arbiter/*
    add wave -noupdate -expand -group $group_name -group Arbiter -group ArbiterWideReq -ports tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/i_wide_wormhole_arbiter/*

    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_aw_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_w_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_b_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_ar_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_r_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_aw_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_w_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_b_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_ar_data
    add wave -noupdate -expand -group $group_name -group Packer tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_r_data

    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_unpack_aw_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_unpack_w_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_unpack_ar_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_unpack_b_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/narrow_unpack_r_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_unpack_aw_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_unpack_w_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_unpack_ar_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_unpack_b_data
    add wave -noupdate -expand -group $group_name -group Unpacker tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/wide_unpack_r_data

    if {!$simple_rob} {
        add wave -noupdate -expand -group $group_name -group NarrowR_RoB -group StatusTable tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/gen_narrow_rob/i_narrow_r_rob/i_floo_rob_status_table/*
        add wave -noupdate -expand -group $group_name -group NarrowR_RoB tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/gen_narrow_rob/i_narrow_r_rob/*
        add wave -noupdate -expand -group $group_name -group WideR_RoB -group StatusTable tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/gen_wide_rob/i_wide_r_rob/i_floo_rob_status_table/*
        add wave -noupdate -expand -group $group_name -group WideR_RoB tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/gen_wide_rob/i_wide_r_rob/*
    } else {
        add wave -noupdate -expand -group $group_name -group NarrowR_RoB tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/gen_simple_rob/i_narrow_r_rob/*
        add wave -noupdate -expand -group $group_name -group WideR_RoB tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/gen_simple_rob/i_wide_r_rob/*
    }

    add wave -noupdate -expand -group $group_name -group NarrowB_RoB tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/i_narrow_b_rob/*
    add wave -noupdate -expand -group $group_name -group WideB_RoB tb_floo_narrow_wide_chimney/i_floo_narrow_wide_chimney_${i}/i_wide_b_rob/*

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
