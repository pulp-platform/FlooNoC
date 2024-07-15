onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/clk_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/rst_ni
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/test_enable_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/sram_cfg_i
add wave -noupdate -group ni_0_0 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_in_req_i.aw -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_in_req_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_in_rsp_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_out_req_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_out_rsp_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_in_req_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_in_rsp_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_out_req_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_out_rsp_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/id_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/route_table_i
add wave -noupdate -group ni_0_0 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_o.req -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_o
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_i
add wave -noupdate -group ni_0_0 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_i.rsp -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_i
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_rsp_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_rsp_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_aw_queue
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_ar_queue
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_aw_queue
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_ar_queue
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_aw_queue_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_aw_queue_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_ar_queue_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_ar_queue_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_aw_queue_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_aw_queue_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_ar_queue_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_ar_queue_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_arb_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_arb_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_arb_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_arb_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_arb_gnt_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_arb_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_arb_gnt_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_arb_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_arb_gnt_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_in
add wave -noupdate -group ni_0_0 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_in_valid
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_in_valid
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_in_valid
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_out_ready
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_out_ready
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_out_ready
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_valid_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_ready_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_narrow_aw
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_narrow_ar
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_narrow_w
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_narrow_b
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_narrow_r
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_aw
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_ar
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_w
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_b
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_r
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_w_sel_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_w_sel_d
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_w_sel_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_w_sel_d
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_unpack_aw
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_unpack_w
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_unpack_b
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_unpack_ar
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_unpack_r
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_unpack_aw
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_unpack_w
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_unpack_b
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_unpack_ar
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_unpack_r
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_req_unpack_generic
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_rsp_unpack_generic
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/floo_wide_unpack_generic
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_meta_buf_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_meta_buf_req_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_meta_buf_rsp_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_meta_buf_rsp_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_meta_buf_req_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_meta_buf_req_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_meta_buf_rsp_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_meta_buf_rsp_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/dst_id
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_id_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_id_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/route_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/id_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/id_lut
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_out_data_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_out_data_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_ar_out_data_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_ar_out_data_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_out_data_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_out_data_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_ar_out_data_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_ar_out_data_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_b_rob_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_b_rob_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_rob_req_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_rob_idx_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_rob_valid_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_aw_rob_ready_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_valid_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_ready_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_b_rob_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_b_rob_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_rob_req_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_rob_idx_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_aw_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_valid_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_ready_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_r_rob_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_narrow_r_rob_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_ar_rob_req_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_ar_rob_idx_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_ar_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_ar_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_valid_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_ready_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_r_rob_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/axi_wide_r_rob_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_ar_rob_req_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_ar_rob_idx_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_ar_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_ar_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_valid_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_ready_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_valid_out
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_ready_in
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_rob_req
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_last
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_b_rob_rob_idx
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_mcast_flag
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_mcast_flag_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_mcast_flag
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_mcast_flag_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_route_select
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_route_select
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/no_use_0
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/no_use_1
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_select_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_select_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_rep_coeff
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_rep_coeff
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/no_use_2
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/no_use_3
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_rsp_rep_coeff
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_rsp_rep_coeff
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_rob_req
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_last
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_b_rob_rob_idx
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_rob_req
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_last
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_r_rob_rob_idx
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_rob_req
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_last
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_r_rob_rob_idx
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_last_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_last_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/narrow_flit_end_flag
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/wide_flit_end_flag
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/is_atop_b_rsp
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/is_atop_r_rsp
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/b_sel_atop
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/r_sel_atop
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/b_rob_pending_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/r_rob_pending_q
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/is_atop
add wave -noupdate -group ni_0_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/atop_has_r_rsp
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/clk_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/rst_ni}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/id_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/addr_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/mask_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/addr_map_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/mask_map_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/route_table_i}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/route_o}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/id_o}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/select_o}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/rep_coeff_o}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/addr_o}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/mask_o}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/gen_table_routing/dec_error}
add wave -noupdate -group route_comp_narrowAw {/tb_floo_mcast_mesh/i_dut/cluster_ni_0_0/i_floo_req_route_comp[3]/gen_table_routing/dec_error_mcast}
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/clk_i
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/rst_ni
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/test_enable_i
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/xy_id_i
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/id_route_map_i
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/valid_i
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/ready_o
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_i[0][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_i[0][0].hdr} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_i
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/valid_o
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/ready_i
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o[2][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o[2][0].hdr} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o[1]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o[1][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o[1][0].hdr} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/data_o
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/in_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/in_data
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/in_routed_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/in_routed_data
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/in_valid
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/in_ready
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/route_mask[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/route_mask
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/route_mask_q[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/route_mask_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/hs_state_d
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/hs_state_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_flag
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_flag_q
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/all_hs_complete
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid[2][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid[1]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_ready
add wave -noupdate -expand -group router_0_0 -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_all_ready[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_all_ready
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_all_ready_q
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid_mcast[0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid_mcast[0][0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_valid_mcast
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[2][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[2][0][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[2][0][0].hdr} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[1]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[1][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[1][0][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data[1][0][0].hdr} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/masked_data
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/is_occupied_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/is_occupied_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/hs_flag_d[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/hs_flag_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/hs_flag_q
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/ready_monitor
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_trans_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_trans_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_port_state_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_port_state_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_port_mcast
add wave -noupdate -expand -group router_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data[2][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data[2][0].hdr} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data[1]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data[1][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data[1][0].hdr} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_data
add wave -noupdate -expand -group router_0_0 -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data[2][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data[2][0].hdr} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data[1]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data[1][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data[1][0].hdr} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_data
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_valid
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_ready
add wave -noupdate -expand -group router_0_0 -expand /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_valid
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/out_buffered_ready
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/prior_input_idx_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/prior_input_idx_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/idle_monitor_vc
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/idle_monitor
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_monitor
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/all_idle
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/conflict
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/mcast_exist
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/first_mcast_d
add wave -noupdate -expand -group router_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_req_floo_router/first_mcast_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/clk_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/rst_ni
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/test_enable_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/sram_cfg_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_in_req_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_in_rsp_o
add wave -noupdate -group ni_2_0 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_out_req_o.w -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_out_req_o
add wave -noupdate -group ni_2_0 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_out_rsp_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_in_req_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_in_rsp_o
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_out_req_o
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_out_rsp_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/id_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/route_table_i
add wave -noupdate -group ni_2_0 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_o
add wave -noupdate -group ni_2_0 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_o
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_o
add wave -noupdate -group ni_2_0 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_i.req -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_i
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_rsp_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_rsp_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_aw_queue
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_ar_queue
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_aw_queue
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_ar_queue
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_aw_queue_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_aw_queue_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_ar_queue_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_ar_queue_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_aw_queue_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_aw_queue_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_ar_queue_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_ar_queue_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_arb_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_arb_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_arb_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_arb_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_arb_gnt_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_arb_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_arb_gnt_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_arb_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_arb_gnt_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_in_valid
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_in_valid
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_in_valid
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_out_ready
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_out_ready
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_out_ready
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_valid_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_ready_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_narrow_aw
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_narrow_ar
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_narrow_w
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_narrow_b
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_narrow_r
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_aw
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_ar
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_w
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_b
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_r
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_w_sel_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_w_sel_d
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_w_sel_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_w_sel_d
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_unpack_aw
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_unpack_w
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_unpack_b
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_unpack_ar
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_unpack_r
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_unpack_aw
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_unpack_w
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_unpack_b
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_unpack_ar
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_unpack_r
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_req_unpack_generic
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_rsp_unpack_generic
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/floo_wide_unpack_generic
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_meta_buf_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_meta_buf_req_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_meta_buf_rsp_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_meta_buf_rsp_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_meta_buf_req_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_meta_buf_req_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_meta_buf_rsp_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_meta_buf_rsp_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/dst_id
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_id_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_id_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/route_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/id_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/id_lut
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_out_data_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_out_data_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_ar_out_data_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_ar_out_data_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_out_data_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_out_data_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_ar_out_data_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_ar_out_data_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_b_rob_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_b_rob_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_rob_req_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_rob_idx_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_rob_valid_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_aw_rob_ready_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_valid_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_ready_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_b_rob_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_b_rob_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_rob_req_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_rob_idx_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_aw_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_valid_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_ready_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_r_rob_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_narrow_r_rob_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_ar_rob_req_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_ar_rob_idx_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_ar_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_ar_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_valid_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_ready_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_r_rob_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/axi_wide_r_rob_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_ar_rob_req_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_ar_rob_idx_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_ar_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_ar_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_valid_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_ready_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_valid_out
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_ready_in
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_rob_req
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_last
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_b_rob_rob_idx
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_mcast_flag
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_mcast_flag_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_mcast_flag
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_mcast_flag_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_route_select
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_route_select
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/no_use_0
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/no_use_1
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_select_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_select_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_rep_coeff
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_rep_coeff
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/no_use_2
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/no_use_3
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_rsp_rep_coeff
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_rsp_rep_coeff
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_rob_req
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_last
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_b_rob_rob_idx
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_rob_req
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_last
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_r_rob_rob_idx
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_rob_req
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_last
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_r_rob_rob_idx
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_last_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_last_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/narrow_flit_end_flag
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/wide_flit_end_flag
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/is_atop_b_rsp
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/is_atop_r_rsp
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/b_sel_atop
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/r_sel_atop
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/b_rob_pending_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/r_rob_pending_q
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/is_atop
add wave -noupdate -group ni_2_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_2_0/atop_has_r_rsp
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/clk_i
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/rst_ni
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/test_enable_i
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/xy_id_i
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/id_route_map_i
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/valid_i
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/ready_o
add wave -noupdate -group router_1_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_i[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_i
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/valid_o
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/ready_i
add wave -noupdate -group router_1_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_o[2]} -expand} /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_o
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_data
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_routed_data
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_valid
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_ready
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/route_mask
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/route_mask_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_state_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_state_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_flag
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_flag_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/all_hs_complete
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_valid
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_ready
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_all_ready
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_all_ready_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_valid_mcast
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_data
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/is_occupied_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/is_occupied_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_flag_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_flag_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/ready_monitor
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_port_state_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_port_state_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_port_mcast
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_data
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_buffered_data
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_valid
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_ready
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_buffered_valid
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_buffered_ready
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_input_idx_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_input_idx_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/idle_monitor_vc
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/idle_monitor
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_monitor
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/all_idle
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/conflict
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_exist
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/first_mcast_d
add wave -noupdate -group router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/first_mcast_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/clk_i
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/rst_ni
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/test_enable_i
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/xy_id_i
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/id_route_map_i
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/valid_i
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/ready_o
add wave -noupdate -expand -group router_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/data_i[3]} -expand {/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/data_i[3][0]} -expand {/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/data_i[3][0].hdr} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/data_i
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/valid_o
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/ready_i
add wave -noupdate -expand -group router_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/data_o[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/data_o
add wave -noupdate -expand -group router_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/in_data[3]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/in_data
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/in_routed_data
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/in_valid
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/in_ready
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/route_mask
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/route_mask_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/hs_state_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/hs_state_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_flag
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_flag_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/all_hs_complete
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/rep_coeff
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/masked_valid
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/masked_ready
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/masked_all_ready
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/masked_all_ready_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/masked_valid_mcast
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/masked_data
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/is_occupied_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/is_occupied_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/hs_flag_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/hs_flag_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/ready_monitor
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_trans_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_trans_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_port_state_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_port_state_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_port_mcast
add wave -noupdate -expand -group router_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_data
add wave -noupdate -expand -group router_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_buffered_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_buffered_data
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_valid
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_ready
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_buffered_valid
add wave -noupdate -expand -group router_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/out_buffered_ready
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/prior_input_idx_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/prior_input_idx_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/idle_monitor_vc
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/idle_monitor
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_monitor
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/all_idle
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/conflict
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/mcast_exist
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/first_mcast_d
add wave -noupdate -expand -group router_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_req_floo_router/first_mcast_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/clk_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/rst_ni
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/test_enable_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/sram_cfg_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_in_req_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_in_rsp_o
add wave -noupdate -group ni_3_3 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_out_req_o.w -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_out_req_o
add wave -noupdate -group ni_3_3 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_out_rsp_i.b -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_out_rsp_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_in_req_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_in_rsp_o
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_out_req_o
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_out_rsp_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/id_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/route_table_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_o
add wave -noupdate -group ni_3_3 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_o.rsp -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_o
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_o
add wave -noupdate -group ni_3_3 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_i
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_rsp_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_rsp_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_aw_queue
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_ar_queue
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_aw_queue
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_ar_queue
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_aw_queue_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_aw_queue_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_ar_queue_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_ar_queue_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_aw_queue_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_aw_queue_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_ar_queue_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_ar_queue_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_arb_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_arb_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_arb_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_arb_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_arb_gnt_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_arb_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_arb_gnt_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_arb_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_arb_gnt_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_in_valid
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_in_valid
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_in_valid
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_out_ready
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_out_ready
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_out_ready
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_valid_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_ready_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_narrow_aw
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_narrow_ar
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_narrow_w
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_narrow_b
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_narrow_r
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_aw
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_ar
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_w
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_b
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_r
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_w_sel_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_w_sel_d
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_w_sel_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_w_sel_d
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_unpack_aw
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_unpack_w
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_unpack_b
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_unpack_ar
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_unpack_r
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_unpack_aw
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_unpack_w
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_unpack_b
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_unpack_ar
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_unpack_r
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_req_unpack_generic
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_rsp_unpack_generic
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/floo_wide_unpack_generic
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_meta_buf_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_meta_buf_req_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_meta_buf_rsp_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_meta_buf_rsp_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_meta_buf_req_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_meta_buf_req_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_meta_buf_rsp_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_meta_buf_rsp_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/dst_id
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_id_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_id_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/route_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/id_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/id_lut
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_out_data_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_out_data_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_ar_out_data_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_ar_out_data_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_out_data_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_out_data_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_ar_out_data_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_ar_out_data_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_b_rob_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_b_rob_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_rob_req_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_rob_idx_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_rob_valid_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_aw_rob_ready_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_valid_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_ready_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_b_rob_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_b_rob_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_rob_req_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_rob_idx_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_aw_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_valid_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_ready_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_r_rob_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_narrow_r_rob_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_ar_rob_req_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_ar_rob_idx_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_ar_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_ar_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_valid_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_ready_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_r_rob_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/axi_wide_r_rob_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_ar_rob_req_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_ar_rob_idx_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_ar_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_ar_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_valid_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_ready_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_valid_out
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_ready_in
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_rob_req
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_last
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_b_rob_rob_idx
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_mcast_flag
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_mcast_flag_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_mcast_flag
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_mcast_flag_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_route_select
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_route_select
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/no_use_0
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/no_use_1
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_select_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_select_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_rep_coeff
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_rep_coeff
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/no_use_2
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/no_use_3
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_rsp_rep_coeff
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_rsp_rep_coeff
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_rob_req
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_last
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_b_rob_rob_idx
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_rob_req
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_last
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_r_rob_rob_idx
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_rob_req
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_last
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_r_rob_rob_idx
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_last_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_last_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/narrow_flit_end_flag
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/wide_flit_end_flag
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/is_atop_b_rsp
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/is_atop_r_rsp
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/b_sel_atop
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/r_sel_atop
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/b_rob_pending_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/r_rob_pending_q
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/is_atop
add wave -noupdate -group ni_3_3 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_3/atop_has_r_rsp
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/clk_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/rst_ni
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/test_enable_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/xy_id_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/id_route_map_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/valid_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/ready_o
add wave -noupdate -group router_rsp_0_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/data_i[1]} -expand} /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/data_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/valid_o
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/ready_i
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/data_o
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/in_data
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/in_routed_data
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/in_valid
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/in_ready
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/route_mask
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/route_mask_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/hs_state_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/hs_state_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_flag
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_flag_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/all_hs_complete
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/masked_valid
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/masked_ready
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/masked_all_ready
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/masked_all_ready_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/masked_valid_mcast
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/all_mcast_flag_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/masked_data
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/is_occupied_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/is_occupied_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/is_occupied_arbiter
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/hs_flag_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/hs_flag_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/ready_monitor
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_trans_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_trans_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_trans_comp_0
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_trans_comp_1
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_port_state_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_port_state_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_port_mcast
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_data
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_buffered_data
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_valid
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_ready
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_buffered_valid
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/out_buffered_ready
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/prior_input_idx_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/prior_input_idx_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/prior_vc_idx_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/prior_vc_idx_q
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/idle_monitor_vc
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/idle_monitor
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_monitor
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/all_idle
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/conflict
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/mcast_exist
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/first_mcast_d
add wave -noupdate -group router_rsp_0_0 /tb_floo_mcast_mesh/i_dut/router_0_0/i_rsp_floo_router/first_mcast_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/clk_i
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/rst_ni
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/test_enable_i
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/xy_id_i
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/id_route_map_i
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/valid_i
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/ready_o
add wave -noupdate -group router_rsp_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/data_i[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/data_i
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/valid_o
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/ready_i
add wave -noupdate -group router_rsp_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/data_o
add wave -noupdate -group router_rsp_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/in_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/in_data
add wave -noupdate -group router_rsp_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/in_routed_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/in_routed_data
add wave -noupdate -group router_rsp_3_3 -expand /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/in_valid
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/in_ready
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/route_mask
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/route_mask_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/hs_state_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/hs_state_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_flag
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_flag_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/all_hs_complete
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/masked_valid
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/masked_ready
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/masked_all_ready
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/masked_all_ready_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/masked_valid_mcast
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/all_mcast_flag_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/masked_data
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/is_occupied_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/is_occupied_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/is_occupied_arbiter
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/hs_flag_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/hs_flag_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/ready_monitor
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_trans_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_trans_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_trans_comp_0
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_trans_comp_1
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_port_state_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_port_state_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_port_mcast
add wave -noupdate -group router_rsp_3_3 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_data[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_data
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_buffered_data
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_valid
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_ready
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_buffered_valid
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/out_buffered_ready
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/prior_input_idx_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/prior_input_idx_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/prior_vc_idx_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/prior_vc_idx_q
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/idle_monitor_vc
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/idle_monitor
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_monitor
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/all_idle
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/conflict
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/mcast_exist
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/first_mcast_d
add wave -noupdate -group router_rsp_3_3 /tb_floo_mcast_mesh/i_dut/router_3_3/i_rsp_floo_router/first_mcast_q
add wave -noupdate /tb_floo_mcast_mesh/NarrowEOS
add wave -noupdate /tb_floo_mcast_mesh/WideEOS
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/clk_i
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/rst_ni
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/test_enable_i
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/xy_id_i
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/id_route_map_i
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/valid_i
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/ready_o
add wave -noupdate -group req_router_1_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_i[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_i
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/valid_o
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/ready_i
add wave -noupdate -group req_router_1_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_o[2]} -expand} /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/data_o
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_data
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_routed_data
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_valid
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/in_ready
add wave -noupdate -group req_router_1_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/route_mask[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/route_mask
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/route_mask_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_state_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_state_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_flag
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_flag_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/all_hs_complete
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_valid
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_ready
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_all_ready
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_all_ready_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_valid_mcast
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/masked_data
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/is_occupied_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/is_occupied_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/rep_coeff
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_flag_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/hs_flag_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/ready_monitor
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_port_state_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_port_state_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_port_mcast
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_data
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_buffered_data
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_valid
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_ready
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_buffered_valid
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/out_buffered_ready
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_input_idx_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_input_idx_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/idle_monitor_vc
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/idle_monitor
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_monitor
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/all_idle
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/conflict
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/mcast_exist
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/first_mcast_d
add wave -noupdate -group req_router_1_0 /tb_floo_mcast_mesh/i_dut/router_1_0/i_req_floo_router/first_mcast_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/clk_i
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/rst_ni
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/test_enable_i
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/xy_id_i
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/id_route_map_i
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/valid_i
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/ready_o
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/data_i[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/data_i
add wave -noupdate -group req_router_2_0 -expand /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/valid_o
add wave -noupdate -group req_router_2_0 -expand /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/ready_i
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/data_o[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/data_o[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/data_o
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/in_data[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/in_data
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/in_routed_data[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/in_routed_data
add wave -noupdate -group req_router_2_0 -expand /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/in_valid
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/in_ready
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/route_mask[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/route_mask
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/route_mask_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/hs_state_d
add wave -noupdate -group req_router_2_0 -expand /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/hs_state_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_flag
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_flag_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/all_hs_complete
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/rep_coeff
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_valid[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_valid[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_valid
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_ready
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_all_ready
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_all_ready_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_valid_mcast
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_data[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/masked_data
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/is_occupied_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/is_occupied_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/rep_coeff
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/hs_flag_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/hs_flag_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/ready_monitor
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_trans_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_trans_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_port_state_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_port_state_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_port_mcast
add wave -noupdate -group req_router_2_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_data[2]} -expand {/tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_data
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_buffered_data
add wave -noupdate -group req_router_2_0 -expand /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_valid
add wave -noupdate -group req_router_2_0 -expand /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_ready
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_buffered_valid
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/out_buffered_ready
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/prior_input_idx_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/prior_input_idx_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/idle_monitor_vc
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/idle_monitor
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_monitor
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/all_idle
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/conflict
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/mcast_exist
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/first_mcast_d
add wave -noupdate -group req_router_2_0 /tb_floo_mcast_mesh/i_dut/router_2_0/i_req_floo_router/first_mcast_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/clk_i
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/rst_ni
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/test_enable_i
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/xy_id_i
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/id_route_map_i
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/valid_i
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/ready_o
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/data_i[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/data_i
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/valid_o
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/ready_i
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/data_o[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/data_o
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/in_data[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/in_data
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/in_routed_data[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/in_routed_data
add wave -noupdate -group req_router_3_0 -expand /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/in_valid
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/in_ready
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/route_mask[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/route_mask
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/route_mask_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/hs_state_d
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/hs_state_q[4]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/hs_state_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_flag
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_flag_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/all_hs_complete
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_valid[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_valid
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_ready
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_all_ready
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_all_ready_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_valid_mcast
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/masked_data
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/is_occupied_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/is_occupied_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/rep_coeff
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/hs_flag_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/hs_flag_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/ready_monitor
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_trans_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_trans_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_port_state_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_port_state_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_port_mcast
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_data
add wave -noupdate -group req_router_3_0 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_buffered_data[0]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_buffered_data
add wave -noupdate -group req_router_3_0 -expand /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_valid
add wave -noupdate -group req_router_3_0 -expand /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_ready
add wave -noupdate -group req_router_3_0 -expand /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_buffered_valid
add wave -noupdate -group req_router_3_0 -expand /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/out_buffered_ready
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/prior_input_idx_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/prior_input_idx_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/idle_monitor_vc
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/idle_monitor
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_monitor
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/all_idle
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/conflict
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/mcast_exist
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/first_mcast_d
add wave -noupdate -group req_router_3_0 /tb_floo_mcast_mesh/i_dut/router_3_0/i_req_floo_router/first_mcast_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/clk_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/rst_ni
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/test_enable_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/sram_cfg_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_in_req_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_in_rsp_o
add wave -noupdate -group ni_3_0 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_out_req_o
add wave -noupdate -group ni_3_0 -expand /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_out_rsp_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_in_req_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_in_rsp_o
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_out_req_o
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_out_rsp_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/id_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/route_table_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_o
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_o
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_o
add wave -noupdate -group ni_3_0 -expand -subitemconfig {/tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_i.req -expand} /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_i
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_rsp_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_rsp_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_aw_queue
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_ar_queue
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_aw_queue
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_ar_queue
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_aw_queue_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_aw_queue_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_ar_queue_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_ar_queue_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_aw_queue_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_aw_queue_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_ar_queue_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_ar_queue_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_arb_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_arb_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_arb_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_arb_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_arb_gnt_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_arb_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_arb_gnt_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_arb_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_arb_gnt_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_in_valid
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_in_valid
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_in_valid
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_out_ready
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_out_ready
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_out_ready
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_valid_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_ready_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_narrow_aw
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_narrow_ar
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_narrow_w
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_narrow_b
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_narrow_r
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_aw
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_ar
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_w
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_b
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_r
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_w_sel_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_w_sel_d
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_w_sel_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_w_sel_d
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_unpack_aw
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_unpack_w
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_unpack_b
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_unpack_ar
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_unpack_r
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_unpack_aw
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_unpack_w
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_unpack_b
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_unpack_ar
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_unpack_r
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_req_unpack_generic
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_rsp_unpack_generic
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/floo_wide_unpack_generic
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_meta_buf_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_meta_buf_req_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_meta_buf_rsp_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_meta_buf_rsp_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_meta_buf_req_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_meta_buf_req_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_meta_buf_rsp_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_meta_buf_rsp_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/dst_id
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_id_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_id_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/route_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/id_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/id_lut
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_out_data_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_out_data_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_ar_out_data_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_ar_out_data_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_out_data_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_out_data_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_ar_out_data_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_ar_out_data_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_b_rob_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_b_rob_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_rob_req_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_rob_idx_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_rob_valid_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_aw_rob_ready_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_valid_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_ready_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_b_rob_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_b_rob_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_rob_req_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_rob_idx_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_aw_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_valid_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_ready_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_r_rob_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_narrow_r_rob_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_ar_rob_req_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_ar_rob_idx_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_ar_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_ar_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_valid_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_ready_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_r_rob_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/axi_wide_r_rob_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_ar_rob_req_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_ar_rob_idx_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_ar_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_ar_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_valid_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_ready_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_valid_out
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_ready_in
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_rob_req
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_last
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_b_rob_rob_idx
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_mcast_flag
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_mcast_flag_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_mcast_flag
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_mcast_flag_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_route_select
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_route_select
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/no_use_0
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/no_use_1
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_select_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_select_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_rep_coeff
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_rep_coeff
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/no_use_2
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/no_use_3
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_rsp_rep_coeff
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_rsp_rep_coeff
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_rob_req
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_last
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_b_rob_rob_idx
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_rob_req
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_last
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_r_rob_rob_idx
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_rob_req
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_last
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_r_rob_rob_idx
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_last_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_last_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/narrow_flit_end_flag
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/wide_flit_end_flag
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/is_atop_b_rsp
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/is_atop_r_rsp
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/b_sel_atop
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/r_sel_atop
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/b_rob_pending_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/r_rob_pending_q
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/is_atop
add wave -noupdate -group ni_3_0 /tb_floo_mcast_mesh/i_dut/cluster_ni_3_0/atop_has_r_rsp
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/clk_i
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/rst_ni
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/test_enable_i
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/xy_id_i
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/id_route_map_i
add wave -noupdate -group req_router_3_2 -expand /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/valid_i
add wave -noupdate -group req_router_3_2 -expand /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/ready_o
add wave -noupdate -group req_router_3_2 -expand -subitemconfig {{/tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/data_i[3]} -expand} /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/data_i
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/valid_o
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/ready_i
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/data_o
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/in_data
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/in_routed_data
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/in_valid
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/in_ready
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/route_mask
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/route_mask_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/rep_coeff
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/hs_state_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/hs_state_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_flag
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_flag_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/all_hs_complete
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/masked_valid
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/masked_ready
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/masked_all_ready
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/masked_all_ready_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/masked_valid_mcast
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/masked_data
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/is_occupied_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/is_occupied_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/is_occupied_arbiter
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/hs_flag_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/hs_flag_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/ready_monitor
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_trans_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_trans_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_port_state_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_port_state_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_port_mcast
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_data
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_buffered_data
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_valid
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_ready
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_buffered_valid
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/out_buffered_ready
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/prior_input_idx_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/prior_input_idx_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/idle_monitor_vc
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/idle_monitor
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_monitor
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/all_idle
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/conflict
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/mcast_exist
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/first_mcast_d
add wave -noupdate -group req_router_3_2 /tb_floo_mcast_mesh/i_dut/router_3_2/i_req_floo_router/first_mcast_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6675884 ps} 1} {{Cursor 2} {20444316 ps} 1} {in_valid=0 {20575256 ps} 1}
quietly wave cursor active 3
configure wave -namecolwidth 237
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {20471293 ps} {20729339 ps}
