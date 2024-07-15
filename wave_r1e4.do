onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/clk_i
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/rst_ni
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/test_enable_i
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/xy_id_i
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/id_route_map_i
add wave -noupdate -group rsp_router -expand /tb_r1e4/i_dut/router/i_rsp_floo_router/valid_i
add wave -noupdate -group rsp_router -expand /tb_r1e4/i_dut/router/i_rsp_floo_router/ready_o
add wave -noupdate -group rsp_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_rsp_floo_router/data_i[4]} -expand {/tb_r1e4/i_dut/router/i_rsp_floo_router/data_i[3]} -expand {/tb_r1e4/i_dut/router/i_rsp_floo_router/data_i[2]} -expand} /tb_r1e4/i_dut/router/i_rsp_floo_router/data_i
add wave -noupdate -group rsp_router -expand /tb_r1e4/i_dut/router/i_rsp_floo_router/valid_o
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/ready_i
add wave -noupdate -group rsp_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_rsp_floo_router/data_o[1]} -expand} /tb_r1e4/i_dut/router/i_rsp_floo_router/data_o
add wave -noupdate -group rsp_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_rsp_floo_router/in_data[2]} -expand} /tb_r1e4/i_dut/router/i_rsp_floo_router/in_data
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/in_routed_data
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/in_valid
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/in_ready
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/route_mask
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/route_mask_q
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/mcast_flag
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/all_hs_complete
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/masked_valid
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/masked_ready
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/masked_all_ready
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/masked_all_ready_q
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/masked_valid_mcast
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/all_mcast_flag_q
add wave -noupdate -group rsp_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_rsp_floo_router/masked_data[1]} -expand} /tb_r1e4/i_dut/router/i_rsp_floo_router/masked_data
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/hs_flag_d
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/hs_flag_q
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/ready_monitor
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/hs_state_d
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/hs_state_q
add wave -noupdate -group rsp_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_rsp_floo_router/out_data[1]} -expand} /tb_r1e4/i_dut/router/i_rsp_floo_router/out_data
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/out_buffered_data
add wave -noupdate -group rsp_router -expand /tb_r1e4/i_dut/router/i_rsp_floo_router/out_valid
add wave -noupdate -group rsp_router -expand /tb_r1e4/i_dut/router/i_rsp_floo_router/out_ready
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/out_buffered_valid
add wave -noupdate -group rsp_router /tb_r1e4/i_dut/router/i_rsp_floo_router/out_buffered_ready
add wave -noupdate -expand -group cluster1 -expand -group {id_counter[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/cnt_en}
add wave -noupdate -expand -group cluster1 -expand -group {id_counter[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/cnt_down}
add wave -noupdate -expand -group cluster1 -expand -group {id_counter[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/overflow}
add wave -noupdate -expand -group cluster1 -expand -group {id_counter[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/cnt_delta}
add wave -noupdate -expand -group cluster1 -expand -group {id_counter[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/in_flight}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/clk_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/rst_ni}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/clear_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/en_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/load_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/down_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/rep_coeff_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/delta_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/d_i}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/q_o}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/overflow_o}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/merged_pop_o}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/counter_q}
add wave -noupdate -expand -group cluster1 -expand -group {in_flight[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/counter_d}
add wave -noupdate -expand -group cluster1 {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/rsp_rep_coeff}
add wave -noupdate -expand -group cluster1 {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/rsp_cnt_d}
add wave -noupdate -expand -group cluster1 {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/rsp_cnt_q}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/clk_i}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/rst_ni}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/flush_i}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/testmode_i}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/full_o}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/empty_o}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/usage_o}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/data_i}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/push_i}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/data_o}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/pop_i}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/gate_clock}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/read_pointer_n}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/read_pointer_q}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/write_pointer_n}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/write_pointer_q}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/status_cnt_n}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/status_cnt_q}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/mem_n}
add wave -noupdate -expand -group cluster1 -expand -group {nrsp_buffer[4]} {/tb_r1e4/i_dut/cluster1_ni/i_wide_b_rob/gen_no_rob/i_axi_demux_id_counters/gen_counters[4]/i_in_flight_cnt/Mcast/i_nrsp_buffer/mem_q}
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/clk_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/rst_ni
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/test_enable_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/sram_cfg_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_in_req_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_in_rsp_o
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_out_req_o
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_out_rsp_i
add wave -noupdate -expand -group cluster1 -expand -subitemconfig {/tb_r1e4/i_dut/cluster1_ni/axi_wide_in_req_i.aw -expand} /tb_r1e4/i_dut/cluster1_ni/axi_wide_in_req_i
add wave -noupdate -expand -group cluster1 -expand -subitemconfig {/tb_r1e4/i_dut/cluster1_ni/axi_wide_in_rsp_o.b -expand} /tb_r1e4/i_dut/cluster1_ni/axi_wide_in_rsp_o
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_out_req_o
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_out_rsp_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/id_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/route_table_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_o
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_o
add wave -noupdate -expand -group cluster1 -expand -subitemconfig {/tb_r1e4/i_dut/cluster1_ni/floo_wide_o.wide -expand} /tb_r1e4/i_dut/cluster1_ni/floo_wide_o
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_i
add wave -noupdate -expand -group cluster1 -expand -subitemconfig {/tb_r1e4/i_dut/cluster1_ni/floo_rsp_i.rsp -expand} /tb_r1e4/i_dut/cluster1_ni/floo_rsp_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_i
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_req_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_rsp_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_req_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_rsp_out
add wave -noupdate -expand -group cluster1 -expand /tb_r1e4/i_dut/cluster1_ni/axi_narrow_aw_queue
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_ar_queue
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_aw_queue
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_ar_queue
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_aw_queue_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_aw_queue_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_ar_queue_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_ar_queue_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_aw_queue_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_aw_queue_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_ar_queue_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_ar_queue_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_arb_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_arb_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_arb_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_arb_req_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_arb_gnt_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_arb_req_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_arb_gnt_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_arb_req_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_arb_gnt_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_in
add wave -noupdate -expand -group cluster1 -expand -subitemconfig {/tb_r1e4/i_dut/cluster1_ni/floo_rsp_in.wide_b -expand /tb_r1e4/i_dut/cluster1_ni/floo_rsp_in.generic -expand} /tb_r1e4/i_dut/cluster1_ni/floo_rsp_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_in_valid
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_in_valid
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_in_valid
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_out_ready
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_out_ready
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_out_ready
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_valid_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_ready_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_narrow_aw
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_narrow_ar
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_narrow_w
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_narrow_b
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_narrow_r
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_aw
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_ar
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_w
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_b
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_r
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_w_sel_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_w_sel_d
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_w_sel_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_w_sel_d
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_unpack_aw
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_unpack_w
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_unpack_b
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_unpack_ar
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_unpack_r
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_unpack_aw
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_unpack_w
add wave -noupdate -expand -group cluster1 -expand /tb_r1e4/i_dut/cluster1_ni/axi_wide_unpack_b
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_unpack_ar
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_unpack_r
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_req_unpack_generic
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_rsp_unpack_generic
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/floo_wide_unpack_generic
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_meta_buf_req_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_meta_buf_req_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_meta_buf_rsp_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_meta_buf_rsp_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_meta_buf_req_in
add wave -noupdate -expand -group cluster1 -expand /tb_r1e4/i_dut/cluster1_ni/axi_wide_meta_buf_req_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_meta_buf_rsp_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_meta_buf_rsp_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/dst_id
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_id_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_id_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/route_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/id_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/id_lut
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_out_data_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_out_data_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_ar_out_data_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_ar_out_data_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_out_data_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_out_data_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_ar_out_data_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_ar_out_data_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_b_rob_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_b_rob_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_rob_req_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_rob_idx_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_rob_valid_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_aw_rob_ready_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_valid_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_ready_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_b_rob_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_b_rob_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_rob_req_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_rob_idx_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_aw_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_valid_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_ready_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_r_rob_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_narrow_r_rob_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_ar_rob_req_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_ar_rob_idx_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_ar_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_ar_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_valid_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_ready_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_r_rob_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/axi_wide_r_rob_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_ar_rob_req_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_ar_rob_idx_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_ar_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_ar_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_valid_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_ready_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_valid_out
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_ready_in
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_rob_req
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_last
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_b_rob_rob_idx
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_mcast_flag
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_mcast_flag_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_mcast_flag
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_mcast_flag_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_route_select
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_route_select
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_select_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_select_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_rep_coeff
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_rep_coeff
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_rob_req
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_last
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_b_rob_rob_idx
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_rob_req
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_last
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_r_rob_rob_idx
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_rob_req
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_last
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_r_rob_rob_idx
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_last_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_last_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/narrow_flit_end_flag
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/wide_flit_end_flag
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/is_atop_b_rsp
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/is_atop_r_rsp
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/b_sel_atop
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/r_sel_atop
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/b_rob_pending_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/r_rob_pending_q
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/is_atop
add wave -noupdate -expand -group cluster1 /tb_r1e4/i_dut/cluster1_ni/atop_has_r_rsp
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/clk_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/rst_ni
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/test_enable_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/sram_cfg_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_in_req_i
add wave -noupdate -group cluster2 -expand -subitemconfig {/tb_r1e4/i_dut/cluster2_ni/axi_narrow_in_rsp_o.r -expand} /tb_r1e4/i_dut/cluster2_ni/axi_narrow_in_rsp_o
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_out_req_o
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_out_rsp_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_in_req_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_in_rsp_o
add wave -noupdate -group cluster2 -expand -subitemconfig {/tb_r1e4/i_dut/cluster2_ni/axi_wide_out_req_o.w -expand} /tb_r1e4/i_dut/cluster2_ni/axi_wide_out_req_o
add wave -noupdate -group cluster2 -expand /tb_r1e4/i_dut/cluster2_ni/axi_wide_out_rsp_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/id_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/route_table_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_o
add wave -noupdate -group cluster2 -expand -subitemconfig {/tb_r1e4/i_dut/cluster2_ni/floo_rsp_o.rsp -expand} /tb_r1e4/i_dut/cluster2_ni/floo_rsp_o
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_o
add wave -noupdate -group cluster2 -expand -subitemconfig {/tb_r1e4/i_dut/cluster2_ni/floo_req_i.req -expand} /tb_r1e4/i_dut/cluster2_ni/floo_req_i
add wave -noupdate -group cluster2 -expand -subitemconfig {/tb_r1e4/i_dut/cluster2_ni/floo_rsp_i.rsp -expand} /tb_r1e4/i_dut/cluster2_ni/floo_rsp_i
add wave -noupdate -group cluster2 -expand -subitemconfig {/tb_r1e4/i_dut/cluster2_ni/floo_wide_i.wide -expand} /tb_r1e4/i_dut/cluster2_ni/floo_wide_i
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_rsp_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_rsp_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_aw_queue
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_ar_queue
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_aw_queue
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_ar_queue
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_aw_queue_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_aw_queue_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_ar_queue_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_ar_queue_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_aw_queue_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_aw_queue_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_ar_queue_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_ar_queue_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_arb_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_arb_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_arb_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_arb_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_arb_gnt_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_arb_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_arb_gnt_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_arb_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_arb_gnt_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_in_valid
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_in_valid
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_in_valid
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_out_ready
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_out_ready
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_out_ready
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_valid_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_ready_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_narrow_aw
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_narrow_ar
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_narrow_w
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_narrow_b
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_narrow_r
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_aw
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_ar
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_w
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_b
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_r
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_w_sel_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_w_sel_d
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_w_sel_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_w_sel_d
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_unpack_aw
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_unpack_w
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_unpack_b
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_unpack_ar
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_unpack_r
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_unpack_aw
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_unpack_w
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_unpack_b
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_unpack_ar
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_unpack_r
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_req_unpack_generic
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_rsp_unpack_generic
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/floo_wide_unpack_generic
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_meta_buf_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_meta_buf_req_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_meta_buf_rsp_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_meta_buf_rsp_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_meta_buf_req_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_meta_buf_req_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_meta_buf_rsp_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_meta_buf_rsp_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/dst_id
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_id_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_id_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/route_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/id_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/id_lut
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_out_data_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_out_data_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_ar_out_data_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_ar_out_data_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_out_data_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_out_data_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_ar_out_data_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_ar_out_data_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_b_rob_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_b_rob_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_rob_req_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_rob_idx_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_rob_valid_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_aw_rob_ready_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_valid_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_ready_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_b_rob_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_b_rob_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_rob_req_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_rob_idx_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_aw_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_valid_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_ready_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_r_rob_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_narrow_r_rob_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_ar_rob_req_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_ar_rob_idx_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_ar_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_ar_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_valid_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_ready_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_r_rob_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/axi_wide_r_rob_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_ar_rob_req_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_ar_rob_idx_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_ar_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_ar_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_valid_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_ready_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_valid_out
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_ready_in
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_rob_req
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_last
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_b_rob_rob_idx
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_mcast_flag
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_mcast_flag_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_mcast_flag
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_mcast_flag_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_route_select
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_route_select
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/no_use_0
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/no_use_1
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_select_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_select_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_rep_coeff
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_rep_coeff
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/no_use_2
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/no_use_3
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_rob_req
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_last
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_b_rob_rob_idx
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_rob_req
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_last
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_r_rob_rob_idx
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_rob_req
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_last
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_r_rob_rob_idx
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_last_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_last_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/narrow_flit_end_flag
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/wide_flit_end_flag
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/is_atop_b_rsp
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/is_atop_r_rsp
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/b_sel_atop
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/r_sel_atop
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/b_rob_pending_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/r_rob_pending_q
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/is_atop
add wave -noupdate -group cluster2 /tb_r1e4/i_dut/cluster2_ni/atop_has_r_rsp
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/clk_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/rst_ni
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/test_enable_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/sram_cfg_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_in_req_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_in_rsp_o
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_out_req_o
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_out_rsp_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_in_req_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_in_rsp_o
add wave -noupdate -expand -group cluster3 -expand -subitemconfig {/tb_r1e4/i_dut/cluster3_ni/axi_wide_out_req_o.w -expand} /tb_r1e4/i_dut/cluster3_ni/axi_wide_out_req_o
add wave -noupdate -expand -group cluster3 -expand /tb_r1e4/i_dut/cluster3_ni/axi_wide_out_rsp_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/id_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/route_table_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_o
add wave -noupdate -expand -group cluster3 -expand -subitemconfig {/tb_r1e4/i_dut/cluster3_ni/floo_rsp_o.rsp -expand} /tb_r1e4/i_dut/cluster3_ni/floo_rsp_o
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_o.rsp.narrow_b.b
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_o
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_i
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_rsp_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_rsp_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_aw_queue
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_ar_queue
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_aw_queue
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_ar_queue
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_aw_queue_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_aw_queue_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_ar_queue_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_ar_queue_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_aw_queue_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_aw_queue_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_ar_queue_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_ar_queue_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_arb_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_arb_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_arb_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_arb_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_arb_gnt_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_arb_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_arb_gnt_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_arb_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_arb_gnt_out
add wave -noupdate -expand -group cluster3 -expand -subitemconfig {/tb_r1e4/i_dut/cluster3_ni/floo_req_in.narrow_aw -expand /tb_r1e4/i_dut/cluster3_ni/floo_req_in.narrow_w -expand} /tb_r1e4/i_dut/cluster3_ni/floo_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_in_valid
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_in_valid
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_in_valid
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_out_ready
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_out_ready
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_out_ready
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_valid_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_ready_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_narrow_aw
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_narrow_ar
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_narrow_w
add wave -noupdate -expand -group cluster3 -expand -subitemconfig {/tb_r1e4/i_dut/cluster3_ni/floo_narrow_b.hdr -expand} /tb_r1e4/i_dut/cluster3_ni/floo_narrow_b
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_narrow_r
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_aw
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_ar
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_w
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_b
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_r
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_w_sel_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_w_sel_d
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_w_sel_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_w_sel_d
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_unpack_aw
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_unpack_w
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_unpack_b
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_unpack_ar
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_unpack_r
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_unpack_aw
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_unpack_w
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_unpack_b
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_unpack_ar
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_unpack_r
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_req_unpack_generic
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_rsp_unpack_generic
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/floo_wide_unpack_generic
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_meta_buf_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_meta_buf_req_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_meta_buf_rsp_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_meta_buf_rsp_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_meta_buf_req_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_meta_buf_req_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_meta_buf_rsp_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_meta_buf_rsp_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/dst_id
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_id_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_id_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/route_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/id_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/id_lut
add wave -noupdate -expand -group cluster3 -expand /tb_r1e4/i_dut/cluster3_ni/narrow_aw_out_data_in
add wave -noupdate -expand -group cluster3 -expand /tb_r1e4/i_dut/cluster3_ni/narrow_aw_out_data_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_ar_out_data_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_ar_out_data_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_out_data_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_out_data_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_ar_out_data_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_ar_out_data_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_b_rob_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_b_rob_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_rob_req_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_rob_idx_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_rob_valid_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_aw_rob_ready_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_valid_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_ready_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_b_rob_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_b_rob_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_rob_req_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_rob_idx_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_aw_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_valid_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_ready_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_r_rob_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_narrow_r_rob_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_ar_rob_req_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_ar_rob_idx_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_ar_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_ar_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_valid_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_ready_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_r_rob_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/axi_wide_r_rob_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_ar_rob_req_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_ar_rob_idx_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_ar_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_ar_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_valid_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_ready_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_valid_out
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_ready_in
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_rob_req
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_last
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_b_rob_rob_idx
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_mcast_flag
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_mcast_flag_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_mcast_flag
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_mcast_flag_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_route_select
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_route_select
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/no_use_0
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/no_use_1
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_select_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_select_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_rep_coeff
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_rep_coeff
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/no_use_2
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/no_use_3
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_rob_req
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_last
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_b_rob_rob_idx
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_rob_req
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_last
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_r_rob_rob_idx
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_rob_req
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_last
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_r_rob_rob_idx
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_last_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_last_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/narrow_flit_end_flag
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/wide_flit_end_flag
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/is_atop_b_rsp
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/is_atop_r_rsp
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/b_sel_atop
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/r_sel_atop
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/b_rob_pending_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/r_rob_pending_q
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/is_atop
add wave -noupdate -expand -group cluster3 /tb_r1e4/i_dut/cluster3_ni/atop_has_r_rsp
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/clk_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/rst_ni
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/test_enable_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/sram_cfg_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_in_req_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_in_rsp_o
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/axi_narrow_out_req_o.w -expand} /tb_r1e4/i_dut/cluster4_ni/axi_narrow_out_req_o
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/axi_narrow_out_rsp_i.b -expand} /tb_r1e4/i_dut/cluster4_ni/axi_narrow_out_rsp_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_in_req_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_in_rsp_o
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/axi_wide_out_req_o.w -expand} /tb_r1e4/i_dut/cluster4_ni/axi_wide_out_req_o
add wave -noupdate -expand -group cluster4 -expand /tb_r1e4/i_dut/cluster4_ni/axi_wide_out_rsp_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/id_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/route_table_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_o
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/floo_rsp_o.rsp -expand} /tb_r1e4/i_dut/cluster4_ni/floo_rsp_o
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_o
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/floo_req_i.req -expand} /tb_r1e4/i_dut/cluster4_ni/floo_req_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_i
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_rsp_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_rsp_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_aw_queue
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_ar_queue
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_aw_queue
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_ar_queue
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_aw_queue_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_aw_queue_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_ar_queue_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_ar_queue_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_aw_queue_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_aw_queue_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_ar_queue_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_ar_queue_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_arb_in
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {{/tb_r1e4/i_dut/cluster4_ni/floo_rsp_arb_in[4]} -expand} /tb_r1e4/i_dut/cluster4_ni/floo_rsp_arb_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_arb_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_arb_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_arb_gnt_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_arb_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_arb_gnt_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_arb_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_arb_gnt_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_in
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/floo_wide_in.wide_aw -expand} /tb_r1e4/i_dut/cluster4_ni/floo_wide_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_in_valid
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_in_valid
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_in_valid
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_out_ready
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_out_ready
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_out_ready
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_valid_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_ready_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_narrow_aw
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_narrow_ar
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_narrow_w
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/floo_narrow_b.hdr -expand /tb_r1e4/i_dut/cluster4_ni/floo_narrow_b.b -expand} /tb_r1e4/i_dut/cluster4_ni/floo_narrow_b
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_narrow_r
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_aw
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_ar
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_w
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_b
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_r
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_w_sel_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_w_sel_d
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_w_sel_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_w_sel_d
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_unpack_aw
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_unpack_w
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_unpack_b
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_unpack_ar
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_unpack_r
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_unpack_aw
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_unpack_w
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_unpack_b
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_unpack_ar
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_unpack_r
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_req_unpack_generic
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_rsp_unpack_generic
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/floo_wide_unpack_generic
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_meta_buf_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_meta_buf_req_out
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/axi_narrow_meta_buf_rsp_in.b -expand} /tb_r1e4/i_dut/cluster4_ni/axi_narrow_meta_buf_rsp_in
add wave -noupdate -expand -group cluster4 -expand -subitemconfig {/tb_r1e4/i_dut/cluster4_ni/axi_narrow_meta_buf_rsp_out.b -expand} /tb_r1e4/i_dut/cluster4_ni/axi_narrow_meta_buf_rsp_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_meta_buf_req_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_meta_buf_req_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_meta_buf_rsp_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_meta_buf_rsp_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/dst_id
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_id_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_id_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/route_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/id_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/id_lut
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_out_data_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_out_data_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_ar_out_data_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_ar_out_data_out
add wave -noupdate -expand -group cluster4 -expand /tb_r1e4/i_dut/cluster4_ni/wide_aw_out_data_in
add wave -noupdate -expand -group cluster4 -expand /tb_r1e4/i_dut/cluster4_ni/wide_aw_out_data_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_ar_out_data_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_ar_out_data_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_b_rob_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_b_rob_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_rob_req_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_rob_idx_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_rob_valid_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_aw_rob_ready_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_valid_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_ready_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_b_rob_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_b_rob_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_rob_req_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_rob_idx_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_aw_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_valid_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_ready_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_r_rob_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_narrow_r_rob_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_ar_rob_req_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_ar_rob_idx_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_ar_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_ar_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_valid_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_ready_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_r_rob_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/axi_wide_r_rob_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_ar_rob_req_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_ar_rob_idx_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_ar_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_ar_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_valid_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_ready_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_valid_out
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_ready_in
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_rob_req
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_last
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_b_rob_rob_idx
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_mcast_flag
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_mcast_flag_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_mcast_flag
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_mcast_flag_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_route_select
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_route_select
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/no_use_0
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/no_use_1
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_select_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_select_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_rep_coeff
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_rep_coeff
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/no_use_2
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/no_use_3
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_rob_req
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_last
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_b_rob_rob_idx
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_rob_req
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_last
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_r_rob_rob_idx
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_rob_req
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_last
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_r_rob_rob_idx
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_last_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_last_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/narrow_flit_end_flag
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/wide_flit_end_flag
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/is_atop_b_rsp
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/is_atop_r_rsp
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/b_sel_atop
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/r_sel_atop
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/b_rob_pending_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/r_rob_pending_q
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/is_atop
add wave -noupdate -expand -group cluster4 /tb_r1e4/i_dut/cluster4_ni/atop_has_r_rsp
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/clk_i
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/rst_ni
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/test_enable_i
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/xy_id_i
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/id_route_map_i
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/valid_i
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/ready_o
add wave -noupdate -expand -group wide_router -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[4]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[4][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[4][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[3][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[3][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[2]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[2][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[2][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[1]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[1][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i[1][0].hdr} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/data_i
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/valid_o
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/ready_i
add wave -noupdate -expand -group wide_router -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[4]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[4][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[4][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[3][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[3][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[2]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[2][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[2][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[1]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[1][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o[1][0].hdr} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/data_o
add wave -noupdate -expand -group wide_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data[4]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data[3][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data[3][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data[2]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data[1]} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/in_data
add wave -noupdate -expand -group wide_router -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_routed_data[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/in_routed_data[3][0]} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/in_routed_data
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/in_valid
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/in_ready
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_flag
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/all_hs_complete
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/masked_valid
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/masked_ready
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/masked_all_ready
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/masked_all_ready_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/masked_valid_mcast
add wave -noupdate -expand -group wide_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/all_mcast_flag_q[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/all_mcast_flag_q[3][0]} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/all_mcast_flag_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/hs_flag_d
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/hs_flag_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/ready_monitor
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/hs_state_d
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/hs_state_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/masked_data
add wave -noupdate -expand -group wide_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/route_mask[3]} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/route_mask
add wave -noupdate -expand -group wide_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/route_mask_q[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/route_mask_q[3][0]} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/route_mask_q
add wave -noupdate -expand -group wide_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[4]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[4][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[4][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[3]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[3][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[3][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[2]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[2][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[2][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[1]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[1][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data[1][0].hdr} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_data
add wave -noupdate -expand -group wide_router -subitemconfig {{/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[4]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[4][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[4][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[2]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[2][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[2][0].hdr} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[1]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[1][0]} -expand {/tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data[1][0].hdr} -expand} /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_data
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_valid
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_ready
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_valid
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_buffered_ready
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_port_state_d
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/out_port_state_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_trans_d
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_trans_q
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_trans_comp_0
add wave -noupdate -expand -group wide_router -expand /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_trans_comp_1
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/prior_input_idx_d
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/prior_input_idx_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/prior_vc_idx_d
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/prior_vc_idx_q
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/idle_monitor_vc
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/idle_monitor
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_monitor
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/all_idle
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/conflict
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/mcast_exist
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/first_mcast_d
add wave -noupdate -expand -group wide_router /tb_r1e4/i_dut/router/i_wide_req_floo_router/first_mcast_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/clk_i
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/rst_ni
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/test_enable_i
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/xy_id_i
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/id_route_map_i
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/valid_i
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/ready_o
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/data_i
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/valid_o
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/ready_i
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/data_o[4]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/data_o[3]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/data_o[2]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/data_o[1]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/data_o
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/in_data[4]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/in_data[3]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/in_data[2]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/in_data[1]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/in_data
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/in_routed_data
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/in_valid
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/in_ready
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/route_mask[2]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/route_mask
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/route_mask_q[2]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/route_mask_q
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/mcast_flag
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/all_hs_complete
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/masked_valid[1]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/masked_valid
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/masked_ready
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/masked_all_ready
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/masked_all_ready_q
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/masked_valid_mcast[2]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/masked_valid_mcast
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/all_mcast_flag_q[1]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/all_mcast_flag_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/masked_data
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/mcast_trans_comp_0
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/mcast_trans_comp_1
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/mcast_trans_d
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/mcast_trans_q
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/hs_flag_d[2]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/hs_flag_d
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/hs_flag_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/ready_monitor
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/hs_state_d
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/hs_state_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/idle_monitor_vc
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/idle_monitor
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/all_idle
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/conflict
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/prior_input_idx_d
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/prior_input_idx_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/prior_vc_idx_d
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/prior_vc_idx_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/out_port_state_d
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/out_port_state_q
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/out_port_mcast
add wave -noupdate -group req_router -expand -subitemconfig {{/tb_r1e4/i_dut/router/i_req_floo_router/out_data[4]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/out_data[3]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/out_data[2]} -expand {/tb_r1e4/i_dut/router/i_req_floo_router/out_data[1]} -expand} /tb_r1e4/i_dut/router/i_req_floo_router/out_data
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/out_buffered_data
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/out_valid
add wave -noupdate -group req_router -expand /tb_r1e4/i_dut/router/i_req_floo_router/out_ready
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/out_buffered_valid
add wave -noupdate -group req_router /tb_r1e4/i_dut/router/i_req_floo_router/out_buffered_ready
add wave -noupdate -expand /tb_r1e4/end_of_sim
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/clk_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/rst_ni
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/lookup_axi_id_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/lookup_mst_select_o
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/lookup_mcast_select_o
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/lookup_mst_select_occupied_o
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/full_o
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/push_axi_id_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/push_mst_select_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/push_mcast_select_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/push_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/rep_coeff_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/inject_axi_id_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/inject_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/pop_axi_id_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/pop_i
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/merged_pop_o
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/mst_select_q
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/mcast_mst_select_q
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/push_en
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/inject_en
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/pop_en
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/occupied
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/cnt_full
add wave -noupdate -group ni3_narrowR_rob_cnt /tb_r1e4/i_dut/cluster3_ni/i_narrow_r_rob/gen_no_rob/i_axi_demux_id_counters/merged_pop
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/clk_i
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/rst_ni
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/test_enable_i
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/axi_req_i
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/axi_rsp_o
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/axi_req_o
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/axi_rsp_i
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/aw_buf_i
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/ar_buf_i
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/r_buf_o
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/b_buf_o
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/ar_no_atop_buf_full
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/aw_no_atop_buf_full
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/ar_no_atop_push
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/aw_no_atop_push
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/ar_no_atop_pop
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/aw_no_atop_pop
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/is_atop_r_rsp
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/is_atop_b_rsp
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/is_atop_aw
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/atop_has_r_rsp
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/no_atop_r_buf
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/no_atop_b_buf
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/atop_r_buf
add wave -noupdate -group ni3_mb /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/atop_b_buf
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/clk_i
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/rst_ni
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/flush_i
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/testmode_i
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/full_o
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/empty_o
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/usage_o
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/data_i
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/push_i
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/data_o
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/pop_i
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/gate_clock
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/read_pointer_n
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/read_pointer_q
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/write_pointer_n
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/write_pointer_q
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/status_cnt_n
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/status_cnt_q
add wave -noupdate -group ni3_mb -expand -group fifo /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/mem_n
add wave -noupdate -group ni3_mb -expand -group fifo -expand /tb_r1e4/i_dut/cluster3_ni/gen_narrow_mgr_port/i_narrow_meta_buffer/i_aw_no_atop_fifo/mem_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {b1 {4173613827 ps} 1} {b2 {4201850000 ps} 1} {{Cursor 9} {4152436497 ps} 0}
quietly wave cursor active 3
configure wave -namecolwidth 277
configure wave -valuecolwidth 138
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
WaveRestoreZoom {4152321322 ps} {4152589076 ps}
