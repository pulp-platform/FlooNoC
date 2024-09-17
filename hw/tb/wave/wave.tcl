# Copyright 2024 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

proc floo_wave_init {} {
    onerror {resume}
    quietly WaveActivateNextPane {} 0

    delete wave *
}

proc floo_wave_style {} {
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
}

proc floo_add_wave {waves groups {ports 0} {expand 0}} {
    set args {}
    set i 0
    foreach group $groups {
        if {$i < $expand} {
            lappend args -expand -group $group
        } else {
            lappend args -group $group
        }
        incr i
    }

    if {$ports} {
        lappend args -ports
    }
    eval [concat [list add wave -noupdate] $args [list $waves]]
}

proc floo_rob_wave {dut {groups {}}} {

    # Normal RoB
    if {[expr [llength [find blocks $dut/gen_normal_rob]] > 0]} {
        floo_add_wave $dut/gen_normal_rob/i_rob/i_floo_rob_status_table/* [concat $groups [list StatusTable]]
        floo_add_wave $dut/gen_normal_rob/i_rob/* $groups
    }
    # Simple RoB
    if {[expr [llength [find blocks $dut/gen_simpl_rob]] > 0]} {
        floo_add_wave $dut/gen_simpl_rob/i_rob/* $groups
    }
    # No RoB
    if {[expr [llength [find blocks $dut/gen_no_rob]] > 0]} {
        floo_add_wave $dut/* $groups
    }

}

proc floo_meta_buffer_wave {dut {groups {}}} {
    floo_add_wave $dut/* $groups
    if {[expr [llength [find blocks $dut/gen_atop_support]]]} {
        floo_add_wave $dut/gen_atop_support/* $groups
    }
}

proc floo_axi_chimney_wave {dut groups {expand 1}} {

    floo_add_wave $dut/* $groups 1 $expand

    floo_add_wave $dut/i_req_wormhole_arbiter/* [concat $groups [list Arbiter ArbiterReq]] 1
    floo_add_wave $dut/i_rsp_wormhole_arbiter/* [concat $groups [list Arbiter ArbiterRsp]] 1
    floo_add_wave $dut/aw_w_sel_q [concat $groups [list Arbiter]]
    floo_add_wave $dut/aw_w_sel_d [concat $groups [list Arbiter]]

    floo_add_wave $dut/floo_axi_aw [concat $groups [list Packer]]
    floo_add_wave $dut/floo_axi_w [concat $groups [list Packer]]
    floo_add_wave $dut/floo_axi_b [concat $groups [list Packer]]
    floo_add_wave $dut/floo_axi_ar [concat $groups [list Packer]]
    floo_add_wave $dut/floo_axi_r [concat $groups [list Packer]]

    floo_add_wave $dut/axi_valid_in [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_ready_out [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_unpack_aw [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_unpack_w [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_unpack_ar [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_unpack_b [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_unpack_r [concat $groups [list Unpacker]]

    floo_rob_wave $dut/i_r_rob [concat $groups [list RRoB]]
    floo_rob_wave $dut/i_b_rob [concat $groups [list BRoB]]

    if {[expr [llength [find blocks $dut/gen_mgr_port]]] > 0} {
        floo_meta_buffer_wave $dut/gen_mgr_port/i_floo_meta_buffer [concat $groups [list MetaBuffer]]
    }
}

proc floo_narrow_wide_chimney_wave {dut groups {expand 1}} {

    floo_add_wave $dut/* $groups 1 $expand

    floo_add_wave $dut/i_req_wormhole_arbiter/* [concat $groups [list Arbiter ArbiterReq]] 1
    floo_add_wave $dut/i_rsp_wormhole_arbiter/* [concat $groups [list Arbiter ArbiterRsp]] 1
    floo_add_wave $dut/i_wide_wormhole_arbiter/* [concat $groups [list Arbiter ArbiterWide]] 1

    floo_add_wave $dut/floo_narrow_aw [concat $groups [list Packer]]
    floo_add_wave $dut/floo_narrow_w [concat $groups [list Packer]]
    floo_add_wave $dut/floo_narrow_b [concat $groups [list Packer]]
    floo_add_wave $dut/floo_narrow_ar [concat $groups [list Packer]]
    floo_add_wave $dut/floo_narrow_r [concat $groups [list Packer]]
    floo_add_wave $dut/floo_wide_aw [concat $groups [list Packer]]
    floo_add_wave $dut/floo_wide_w [concat $groups [list Packer]]
    floo_add_wave $dut/floo_wide_b [concat $groups [list Packer]]
    floo_add_wave $dut/floo_wide_ar [concat $groups [list Packer]]
    floo_add_wave $dut/floo_wide_r [concat $groups [list Packer]]

    floo_add_wave $dut/axi_valid_in [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_ready_out [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_narrow_unpack_aw [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_narrow_unpack_w [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_narrow_unpack_ar [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_narrow_unpack_b [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_narrow_unpack_r [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_wide_unpack_aw [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_wide_unpack_w [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_wide_unpack_ar [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_wide_unpack_b [concat $groups [list Unpacker]]
    floo_add_wave $dut/axi_wide_unpack_r [concat $groups [list Unpacker]]

    floo_rob_wave $dut/i_narrow_r_rob [concat $groups [list NarrowRRoB]]
    floo_rob_wave $dut/i_narrow_b_rob [concat $groups [list NarrowBRoB]]
    floo_rob_wave $dut/i_wide_r_rob [concat $groups [list WideRRoB]]
    floo_rob_wave $dut/i_wide_b_rob [concat $groups [list WideBRoB]]

    if {[expr [llength [find blocks $dut/gen_narrow_mgr_port]]] > 0} {
        floo_meta_buffer_wave $dut/gen_narrow_mgr_port/i_narrow_meta_buffer [concat $groups [list NarrowMetaBuffer]]
    }
    if {[expr [llength [find blocks $dut/gen_wide_mgr_port]]] > 0} {
        floo_meta_buffer_wave $dut/gen_wide_mgr_port/i_wide_meta_buffer [concat $groups [list WideMetaBuffer]]
    }
}

proc floo_vc_narrow_wide_chimney_wave {dut groups} {
    floo_add_wave $dut/* $groups
}

proc floo_router_wave {dut groups} {
    floo_add_wave $dut/* $groups
}
