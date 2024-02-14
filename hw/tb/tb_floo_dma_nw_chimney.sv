// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_floo_dma_nw_chimney;

  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumTargets = 2;

  localparam int unsigned ReorderBufferSize = 128;
  localparam int unsigned MaxTxns = 32;
  localparam int unsigned MaxTxnsPerId = 32;

  logic clk, rst_n;

  axi_narrow_in_req_t [NumTargets-1:0] narrow_man_req;
  axi_narrow_in_rsp_t [NumTargets-1:0] narrow_man_rsp;
  axi_wide_in_req_t [NumTargets-1:0] wide_man_req;
  axi_wide_in_rsp_t [NumTargets-1:0] wide_man_rsp;

  axi_narrow_out_req_t [NumTargets-1:0] narrow_sub_req;
  axi_narrow_out_rsp_t [NumTargets-1:0] narrow_sub_rsp;
  axi_wide_out_req_t [NumTargets-1:0] wide_sub_req;
  axi_wide_out_rsp_t [NumTargets-1:0] wide_sub_rsp;

  axi_narrow_in_req_t [NumTargets-1:0] narrow_sub_req_id_mapped;
  axi_narrow_in_rsp_t [NumTargets-1:0] narrow_sub_rsp_id_mapped;
  axi_wide_in_req_t [NumTargets-1:0] wide_sub_req_id_mapped;
  axi_wide_in_rsp_t [NumTargets-1:0] wide_sub_rsp_id_mapped;

  for (genvar i = 0; i < NumDirections; i++) begin : gen_dir
    `AXI_ASSIGN_REQ_STRUCT(narrow_sub_req_id_mapped[i], narrow_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(narrow_sub_rsp_id_mapped[i], narrow_sub_rsp[i])
    `AXI_ASSIGN_REQ_STRUCT(wide_sub_req_id_mapped[i], wide_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(wide_sub_rsp_id_mapped[i], wide_sub_rsp[i])
  end

  floo_req_t [NumTargets-1:0] chimney_req, chimney_req_cut;
  floo_rsp_t [NumTargets-1:0] chimney_rsp, chimney_rsp_cut;
  floo_wide_t [NumTargets-1:0] chimney_wide, chimney_wide_cut;

  logic [NumTargets*2-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  typedef struct packed {
    logic [AxiNarrowInAddrWidth-1:0] start_addr;
    logic [AxiNarrowInAddrWidth-1:0] end_addr;
  } node_addr_region_t;

  localparam int unsigned MemBaseAddr = 32'h0000_0000;
  localparam int unsigned MemSize     = 32'h0001_0000;

  floo_dma_test_node #(
    .TA             ( ApplTime              ),
    .TT             ( TestTime              ),
    .DataWidth      ( AxiNarrowInDataWidth  ),
    .AddrWidth      ( AxiNarrowInAddrWidth  ),
    .UserWidth      ( AxiNarrowInUserWidth  ),
    .AxiIdInWidth   ( AxiNarrowOutIdWidth   ),
    .AxiIdOutWidth  ( AxiNarrowInIdWidth    ),
    .MemBaseAddr    ( MemBaseAddr           ),
    .MemSize        ( MemSize               ),
    .axi_in_req_t   ( axi_narrow_out_req_t  ),
    .axi_in_rsp_t   ( axi_narrow_out_rsp_t  ),
    .axi_out_req_t  ( axi_narrow_in_req_t   ),
    .axi_out_rsp_t  ( axi_narrow_in_rsp_t   ),
    .JobId          ( 100                   )
  ) i_narrow_dma_node_0 (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .axi_in_req_i   ( narrow_sub_req[0] ),
    .axi_in_rsp_o   ( narrow_sub_rsp[0] ),
    .axi_out_req_o  ( narrow_man_req[0] ),
    .axi_out_rsp_i  ( narrow_man_rsp[0] ),
    .end_of_sim_o   ( end_of_sim[0]     )
  );

  floo_dma_test_node #(
    .TA             ( ApplTime            ),
    .TT             ( TestTime            ),
    .DataWidth      ( AxiWideInDataWidth  ),
    .AddrWidth      ( AxiWideInAddrWidth  ),
    .UserWidth      ( AxiWideInUserWidth  ),
    .AxiIdInWidth   ( AxiWideOutIdWidth   ),
    .AxiIdOutWidth  ( AxiWideInIdWidth    ),
    .MemBaseAddr    ( MemBaseAddr         ),
    .MemSize        ( MemSize             ),
    .axi_in_req_t   ( axi_wide_out_req_t  ),
    .axi_in_rsp_t   ( axi_wide_out_rsp_t  ),
    .axi_out_req_t  ( axi_wide_in_req_t   ),
    .axi_out_rsp_t  ( axi_wide_in_rsp_t   ),
    .JobId          ( 0                   )
  ) i_wide_dma_node_0 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .axi_in_req_i   ( wide_sub_req[0] ),
    .axi_in_rsp_o   ( wide_sub_rsp[0] ),
    .axi_out_req_o  ( wide_man_req[0] ),
    .axi_out_rsp_i  ( wide_man_rsp[0] ),
    .end_of_sim_o   ( end_of_sim[1]   )
  );

  axi_chan_compare #(
    .aw_chan_t  ( axi_narrow_in_aw_chan_t ),
    .w_chan_t   ( axi_narrow_in_w_chan_t  ),
    .b_chan_t   ( axi_narrow_in_b_chan_t  ),
    .ar_chan_t  ( axi_narrow_in_ar_chan_t ),
    .r_chan_t   ( axi_narrow_in_r_chan_t  ),
    .req_t      ( axi_narrow_in_req_t     ),
    .resp_t     ( axi_narrow_in_rsp_t     )
  ) i_narrow_channel_compare_0 (
    .clk_a_i    ( clk                         ),
    .clk_b_i    ( clk                         ),
    .axi_a_req  ( narrow_man_req[0]           ),
    .axi_a_res  ( narrow_man_rsp[0]           ),
    .axi_b_req  ( narrow_sub_req_id_mapped[1] ),
    .axi_b_res  ( narrow_sub_rsp_id_mapped[1] )
  );

  axi_chan_compare #(
    .aw_chan_t  ( axi_wide_in_aw_chan_t ),
    .w_chan_t   ( axi_wide_in_w_chan_t  ),
    .b_chan_t   ( axi_wide_in_b_chan_t  ),
    .ar_chan_t  ( axi_wide_in_ar_chan_t ),
    .r_chan_t   ( axi_wide_in_r_chan_t  ),
    .req_t      ( axi_wide_in_req_t     ),
    .resp_t     ( axi_wide_in_rsp_t     )
  ) i_wide_channel_compare_0 (
    .clk_a_i    ( clk             ),
    .clk_b_i    ( clk             ),
    .axi_a_req  ( wide_man_req[0] ),
    .axi_a_res  ( wide_man_rsp[0] ),
    .axi_b_req  ( wide_sub_req_id_mapped[1] ),
    .axi_b_res  ( wide_sub_rsp_id_mapped[1] )
  );

  floo_narrow_wide_chimney #(
    .NarrowMaxTxns            ( MaxTxns             ),
    .NarrowMaxTxnsPerId       ( MaxTxnsPerId        ),
    .NarrowReorderBufferSize  ( ReorderBufferSize   ),
    .WideMaxTxns              ( MaxTxns             ),
    .WideMaxTxnsPerId         ( MaxTxnsPerId        ),
    .WideReorderBufferSize    ( ReorderBufferSize   )
  ) i_floo_narrow_wide_chimney_0 (
    .clk_i                ( clk                 ),
    .rst_ni               ( rst_n               ),
    .sram_cfg_i           ( '0                  ),
    .test_enable_i        ( 1'b0                ),
    .axi_narrow_in_req_i  ( narrow_man_req[0]   ),
    .axi_narrow_in_rsp_o  ( narrow_man_rsp[0]   ),
    .axi_narrow_out_req_o ( narrow_sub_req[0]   ),
    .axi_narrow_out_rsp_i ( narrow_sub_rsp[0]   ),
    .axi_wide_in_req_i    ( wide_man_req[0]     ),
    .axi_wide_in_rsp_o    ( wide_man_rsp[0]     ),
    .axi_wide_out_req_o   ( wide_sub_req[0]     ),
    .axi_wide_out_rsp_i   ( wide_sub_rsp[0]     ),
    .id_i                 ( '0                  ),
    .route_table_i        ( '0                  ),
    .floo_req_o           ( chimney_req[0]      ),
    .floo_rsp_o           ( chimney_rsp[0]      ),
    .floo_wide_o          ( chimney_wide[0]     ),
    .floo_req_i           ( chimney_req_cut[1]  ),
    .floo_rsp_i           ( chimney_rsp_cut[1]  ),
    .floo_wide_i          ( chimney_wide_cut[1] )
    );

  floo_cut #(
    .NumChannels  ( 2               ),
    .NumCuts      ( 32'd7           ), // should simulate a hop with 2 routers
    .flit_t       ( floo_req_chan_t )
  ) i_floo_req_cut (
    .clk_i    ( clk                                                   ),
    .rst_ni   ( rst_n                                                 ),
    .valid_i  ( {chimney_req[1].valid, chimney_req[0].valid}          ),
    .ready_o  ( {chimney_req_cut[1].ready, chimney_req_cut[0].ready}  ),
    .data_i   ( {chimney_req[1].req, chimney_req[0].req}              ),
    .valid_o  ( {chimney_req_cut[1].valid, chimney_req_cut[0].valid}  ),
    .ready_i  ( {chimney_req[1].ready, chimney_req[0].ready}          ),
    .data_o   ( {chimney_req_cut[1].req, chimney_req_cut[0].req}      )
  );

  floo_cut #(
    .NumChannels  ( 2               ),
    .NumCuts      ( 32'd7           ), // should simulate a hop with 2 routers
    .flit_t       ( floo_rsp_chan_t )
  ) i_floo_rsp_cut (
    .clk_i    ( clk                                                   ),
    .rst_ni   ( rst_n                                                 ),
    .valid_i  ( {chimney_rsp[1].valid, chimney_rsp[0].valid}          ),
    .ready_o  ( {chimney_rsp_cut[1].ready, chimney_rsp_cut[0].ready}  ),
    .data_i   ( {chimney_rsp[1].rsp, chimney_rsp[0].rsp}              ),
    .valid_o  ( {chimney_rsp_cut[1].valid, chimney_rsp_cut[0].valid}  ),
    .ready_i  ( {chimney_rsp[1].ready, chimney_rsp[0].ready}          ),
    .data_o   ( {chimney_rsp_cut[1].rsp, chimney_rsp_cut[0].rsp}      )
  );

  floo_cut #(
    .NumChannels  ( 2                 ),
    .NumCuts      ( 32'd4             ), // should simulate a hop with 2 routers
    .flit_t       ( floo_wide_chan_t  )
  ) i_floo_wide_cut (
    .clk_i    ( clk                                                     ),
    .rst_ni   ( rst_n                                                   ),
    .valid_i  ( {chimney_wide[1].valid, chimney_wide[0].valid}          ),
    .ready_o  ( {chimney_wide_cut[1].ready, chimney_wide_cut[0].ready}  ),
    .data_i   ( {chimney_wide[1].wide, chimney_wide[0].wide}            ),
    .valid_o  ( {chimney_wide_cut[1].valid, chimney_wide_cut[0].valid}  ),
    .ready_i  ( {chimney_wide[1].ready, chimney_wide[0].ready}          ),
    .data_o   ( {chimney_wide_cut[1].wide, chimney_wide_cut[0].wide}    )
  );

  floo_narrow_wide_chimney #(
    .NarrowMaxTxns            ( MaxTxns             ),
    .NarrowMaxTxnsPerId       ( MaxTxnsPerId        ),
    .NarrowReorderBufferSize  ( ReorderBufferSize   ),
    .WideMaxTxns              ( MaxTxns             ),
    .WideMaxTxnsPerId         ( MaxTxnsPerId        ),
    .WideReorderBufferSize    ( ReorderBufferSize   )
  ) i_floo_narrow_wide_chimney_1 (
    .clk_i                ( clk                 ),
    .rst_ni               ( rst_n               ),
    .sram_cfg_i           ( '0                  ),
    .test_enable_i        ( 1'b0                ),
    .axi_narrow_in_req_i  ( narrow_man_req[1]   ),
    .axi_narrow_in_rsp_o  ( narrow_man_rsp[1]   ),
    .axi_narrow_out_req_o ( narrow_sub_req[1]   ),
    .axi_narrow_out_rsp_i ( narrow_sub_rsp[1]   ),
    .axi_wide_in_req_i    ( wide_man_req[1]     ),
    .axi_wide_in_rsp_o    ( wide_man_rsp[1]     ),
    .axi_wide_out_req_o   ( wide_sub_req[1]     ),
    .axi_wide_out_rsp_i   ( wide_sub_rsp[1]     ),
    .id_i                 ( '0                  ),
    .route_table_i        ( '0                  ),
    .floo_req_o           ( chimney_req[1]      ),
    .floo_rsp_o           ( chimney_rsp[1]      ),
    .floo_wide_o          ( chimney_wide[1]     ),
    .floo_req_i           ( chimney_req_cut[0]  ),
    .floo_rsp_i           ( chimney_rsp_cut[0]  ),
    .floo_wide_i          ( chimney_wide_cut[0] )
  );

  axi_chan_compare #(
    .aw_chan_t  ( axi_narrow_in_aw_chan_t ),
    .w_chan_t   ( axi_narrow_in_w_chan_t  ),
    .b_chan_t   ( axi_narrow_in_b_chan_t  ),
    .ar_chan_t  ( axi_narrow_in_ar_chan_t ),
    .r_chan_t   ( axi_narrow_in_r_chan_t  ),
    .req_t      ( axi_narrow_in_req_t     ),
    .resp_t     ( axi_narrow_in_rsp_t     )
  ) i_narrow_channel_compare_1 (
    .clk_a_i    ( clk                         ),
    .clk_b_i    ( clk                         ),
    .axi_a_req  ( narrow_man_req[1]           ),
    .axi_a_res  ( narrow_man_rsp[1]           ),
    .axi_b_req  ( narrow_sub_req_id_mapped[0] ),
    .axi_b_res  ( narrow_sub_rsp_id_mapped[0] )
  );

  axi_chan_compare #(
    .aw_chan_t  ( axi_wide_in_aw_chan_t ),
    .w_chan_t   ( axi_wide_in_w_chan_t  ),
    .b_chan_t   ( axi_wide_in_b_chan_t  ),
    .ar_chan_t  ( axi_wide_in_ar_chan_t ),
    .r_chan_t   ( axi_wide_in_r_chan_t  ),
    .req_t      ( axi_wide_in_req_t     ),
    .resp_t     ( axi_wide_in_rsp_t     )
  ) i_wide_channel_compare_1 (
    .clk_a_i    ( clk                       ),
    .clk_b_i    ( clk                       ),
    .axi_a_req  ( wide_man_req[1]           ),
    .axi_a_res  ( wide_man_rsp[1]           ),
    .axi_b_req  ( wide_sub_req_id_mapped[0] ),
    .axi_b_res  ( wide_sub_rsp_id_mapped[0] )
  );

  floo_dma_test_node #(
    .TA             ( ApplTime              ),
    .TT             ( TestTime              ),
    .DataWidth      ( AxiNarrowInDataWidth  ),
    .AddrWidth      ( AxiNarrowInAddrWidth  ),
    .UserWidth      ( AxiNarrowInUserWidth  ),
    .AxiIdInWidth   ( AxiNarrowOutIdWidth   ),
    .AxiIdOutWidth  ( AxiNarrowInIdWidth    ),
    .MemBaseAddr    ( MemBaseAddr           ),
    .MemSize        ( MemSize               ),
    .axi_in_req_t   ( axi_narrow_out_req_t  ),
    .axi_in_rsp_t   ( axi_narrow_out_rsp_t  ),
    .axi_out_req_t  ( axi_narrow_in_req_t   ),
    .axi_out_rsp_t  ( axi_narrow_in_rsp_t   ),
    .JobId          ( 101                   )
  ) i_narrow_dma_node_1 (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .axi_in_req_i   ( narrow_sub_req[1] ),
    .axi_in_rsp_o   ( narrow_sub_rsp[1] ),
    .axi_out_req_o  ( narrow_man_req[1] ),
    .axi_out_rsp_i  ( narrow_man_rsp[1] ),
    .end_of_sim_o   ( end_of_sim[2]     )
  );

  floo_dma_test_node #(
    .TA             ( ApplTime            ),
    .TT             ( TestTime            ),
    .DataWidth      ( AxiWideInDataWidth  ),
    .AddrWidth      ( AxiWideInAddrWidth  ),
    .UserWidth      ( AxiWideInUserWidth  ),
    .AxiIdInWidth   ( AxiWideOutIdWidth   ),
    .AxiIdOutWidth  ( AxiWideInIdWidth    ),
    .MemBaseAddr    ( MemBaseAddr         ),
    .MemSize        ( MemSize             ),
    .axi_in_req_t   ( axi_wide_out_req_t  ),
    .axi_in_rsp_t   ( axi_wide_out_rsp_t  ),
    .axi_out_req_t  ( axi_wide_in_req_t   ),
    .axi_out_rsp_t  ( axi_wide_in_rsp_t   ),
    .JobId          ( 1                   )
  ) i_wide_dma_node_1 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .axi_in_req_i   ( wide_sub_req[1] ),
    .axi_in_rsp_o   ( wide_sub_rsp[1] ),
    .axi_out_req_o  ( wide_man_req[1] ),
    .axi_out_rsp_i  ( wide_man_rsp[1] ),
    .end_of_sim_o   ( end_of_sim[3]   )
  );

  axi_bw_monitor #(
    .req_t      ( axi_narrow_in_req_t ),
    .rsp_t      ( axi_narrow_in_rsp_t ),
    .AxiIdWidth ( AxiNarrowInIdWidth  ),
    .Name       ( "narrow 0"          )
    ) i_axi_narrow_bw_monitor_0 (
      .clk_i          ( clk               ),
      .en_i           ( rst_n             ),
      .end_of_sim_i   ( &end_of_sim       ),
      .req_i          ( narrow_man_req[0] ),
      .rsp_i          ( narrow_man_rsp[0] ),
      .ar_in_flight_o (                   ),
      .aw_in_flight_o (                   )
    );

  axi_bw_monitor #(
    .req_t      ( axi_narrow_in_req_t ),
    .rsp_t      ( axi_narrow_in_rsp_t ),
    .AxiIdWidth ( AxiNarrowInIdWidth  ),
    .Name       ( "narrow 1"          )
  ) i_axi_narrow_bw_monitor_1 (
    .clk_i          ( clk               ),
    .en_i           ( rst_n             ),
    .end_of_sim_i   ( &end_of_sim       ),
    .req_i          ( narrow_man_req[1] ),
    .rsp_i          ( narrow_man_rsp[1] ),
    .ar_in_flight_o (                   ),
    .aw_in_flight_o (                   )
    );

  axi_bw_monitor #(
    .req_t      ( axi_wide_in_req_t ),
    .rsp_t      ( axi_wide_in_rsp_t ),
    .AxiIdWidth ( AxiWideInIdWidth  ),
    .Name       ( "wide 0"          )
  ) i_axi_wide_bw_monitor_0 (
    .clk_i          ( clk             ),
    .en_i           ( rst_n           ),
    .end_of_sim_i   ( &end_of_sim     ),
    .req_i          ( wide_man_req[0] ),
    .rsp_i          ( wide_man_rsp[0] ),
    .ar_in_flight_o (                 ),
    .aw_in_flight_o (                 )
    );

  axi_bw_monitor #(
    .req_t      ( axi_wide_in_req_t ),
    .rsp_t      ( axi_wide_in_rsp_t ),
    .AxiIdWidth ( AxiWideInIdWidth  ),
    .Name       ( "wide 1"          )
  ) i_axi_wide_bw_monitor_1 (
    .clk_i          ( clk             ),
    .en_i           ( rst_n           ),
    .end_of_sim_i   ( &end_of_sim     ),
    .req_i          ( wide_man_req[1] ),
    .rsp_i          ( wide_man_rsp[1] ),
    .ar_in_flight_o (                 ),
    .aw_in_flight_o (                 )
    );

  initial begin
    wait(&end_of_sim);
    // Wait for some time
    #100ns;
    // Stop the simulation
    $stop;
  end


endmodule
