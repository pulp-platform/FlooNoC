// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_floo_dma_chimney;

  import floo_pkg::*;
  import floo_axi_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 0ns;
  localparam time TestTime = 10ns;

  localparam int unsigned NumTargets = 2;

  localparam int unsigned ReorderBufferSize = 128;
  localparam int unsigned MaxTxns = 32;
  localparam int unsigned MaxTxnsPerId = 32;

  logic clk, rst_n;

  axi_in_req_t [NumTargets-1:0] node_man_req;
  axi_in_rsp_t [NumTargets-1:0] node_man_rsp;

  axi_in_req_t [NumTargets-1:0] node_sub_req;
  axi_in_rsp_t [NumTargets-1:0] node_sub_rsp;

  axi_in_req_t [NumTargets-1:0] sub_req_id_mapped;
  axi_in_rsp_t [NumTargets-1:0] sub_rsp_id_mapped;

  for (genvar i = 0; i < NumTargets; i++) begin : gen_axi_assign
    `AXI_ASSIGN_REQ_STRUCT(sub_req_id_mapped[i], node_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(sub_rsp_id_mapped[i], node_sub_rsp[i])
  end

  floo_req_t [NumTargets-1:0] chimney_req;
  floo_rsp_t [NumTargets-1:0] chimney_rsp;

  logic [NumTargets-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  typedef struct packed {
    logic [AxiInAddrWidth-1:0] start_addr;
    logic [AxiInAddrWidth-1:0] end_addr;
  } node_addr_region_t;

  localparam int unsigned MemBaseAddr = 32'h0000_0000;
  localparam int unsigned MemSize     = 32'h0001_0000;

  floo_dma_test_node #(
    .TA           ( ApplTime        ),
    .TT           ( TestTime        ),
    .DataWidth    ( AxiInDataWidth  ),
    .AddrWidth    ( AxiInAddrWidth  ),
    .UserWidth    ( AxiInUserWidth  ),
    .AxiIdWidth   ( AxiInIdWidth    ),
    .MemBaseAddr  ( MemBaseAddr     ),
    .MemSize      ( MemSize         ),
    .axi_req_t    ( axi_in_req_t    ),
    .axi_rsp_t    ( axi_in_rsp_t   ),
    .JobId        ( 0               )
  ) i_floo_dma_test_node_0 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .axi_in_req_i   ( node_sub_req[0] ),
    .axi_in_rsp_o   ( node_sub_rsp[0] ),
    .axi_out_req_o  ( node_man_req[0] ),
    .axi_out_rsp_i  ( node_man_rsp[0] ),
    .end_of_sim_o   ( end_of_sim[0]   )
  );

  axi_chan_compare #(
    .aw_chan_t  ( axi_in_aw_chan_t ),
    .w_chan_t   ( axi_in_w_chan_t  ),
    .b_chan_t   ( axi_in_b_chan_t  ),
    .ar_chan_t  ( axi_in_ar_chan_t ),
    .r_chan_t   ( axi_in_r_chan_t  ),
    .req_t      ( axi_in_req_t     ),
    .resp_t     ( axi_in_rsp_t     )
  ) i_axi_chan_compare_0 (
    .clk_a_i    ( clk                  ),
    .clk_b_i    ( clk                  ),
    .axi_a_req  ( node_man_req[0]      ),
    .axi_a_res  ( node_man_rsp[0]      ),
    .axi_b_req  ( sub_req_id_mapped[1] ),
    .axi_b_res  ( sub_rsp_id_mapped[1] )
    );

  floo_axi_chimney #(
    .AtopSupport        ( 1'b0                ),
    .MaxTxns            ( MaxTxns             ),
    .MaxTxnsPerId       ( MaxTxnsPerId        ),
    .ReorderBufferSize  ( ReorderBufferSize   )
  ) i_floo_axi_chimney_0 (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .sram_cfg_i     ( '0                ),
    .test_enable_i  ( 1'b0              ),
    .axi_in_req_i   ( node_man_req[0]   ),
    .axi_in_rsp_o   ( node_man_rsp[0]   ),
    .axi_out_req_o  ( node_sub_req[0]   ),
    .axi_out_rsp_i  ( node_sub_rsp[0]   ),
    .id_i           ( '0                ),
    .route_table_i  ( '0                ),
    .floo_req_o     ( chimney_req[0]    ),
    .floo_rsp_o     ( chimney_rsp[0]    ),
    .floo_req_i     ( chimney_req[1]    ),
    .floo_rsp_i     ( chimney_rsp[1]    )
  );

  floo_axi_chimney #(
    .AtopSupport        ( 1'b0                ),
    .MaxTxns            ( MaxTxns             ),
    .MaxTxnsPerId       ( MaxTxnsPerId        ),
    .ReorderBufferSize  ( ReorderBufferSize   )
  ) i_floo_axi_chimney_1 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .sram_cfg_i     ( '0              ),
    .test_enable_i  ( 1'b0            ),
    .axi_in_req_i   ( node_man_req[1] ),
    .axi_in_rsp_o   ( node_man_rsp[1] ),
    .axi_out_req_o  ( node_sub_req[1] ),
    .axi_out_rsp_i  ( node_sub_rsp[1] ),
    .id_i           ( '0              ),
    .route_table_i  ( '0              ),
    .floo_req_o     ( chimney_req[1]  ),
    .floo_rsp_o     ( chimney_rsp[1]  ),
    .floo_req_i     ( chimney_req[0]  ),
    .floo_rsp_i     ( chimney_rsp[0]  )
  );

  axi_chan_compare #(
    .aw_chan_t  ( axi_in_aw_chan_t ),
    .w_chan_t   ( axi_in_w_chan_t  ),
    .b_chan_t   ( axi_in_b_chan_t  ),
    .ar_chan_t  ( axi_in_ar_chan_t ),
    .r_chan_t   ( axi_in_r_chan_t  ),
    .req_t      ( axi_in_req_t     ),
    .resp_t     ( axi_in_rsp_t     )
  ) i_axi_chan_compare_1 (
    .clk_a_i    ( clk                  ),
    .clk_b_i    ( clk                  ),
    .axi_a_req  ( node_man_req[1]      ),
    .axi_a_res  ( node_man_rsp[1]      ),
    .axi_b_req  ( sub_req_id_mapped[0] ),
    .axi_b_res  ( sub_rsp_id_mapped[0] )
  );

  floo_dma_test_node #(
    .TA           ( ApplTime        ),
    .TT           ( TestTime        ),
    .DataWidth    ( AxiInDataWidth  ),
    .AddrWidth    ( AxiInAddrWidth  ),
    .UserWidth    ( AxiInUserWidth  ),
    .AxiIdWidth   ( AxiInIdWidth    ),
    .MemBaseAddr  ( MemBaseAddr     ),
    .MemSize      ( MemSize         ),
    .axi_req_t    ( axi_in_req_t    ),
    .axi_rsp_t    ( axi_in_rsp_t    ),
    .JobId        ( 1               )
  ) i_floo_dma_test_node_1 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .axi_in_req_i   ( node_sub_req[1] ),
    .axi_in_rsp_o   ( node_sub_rsp[1] ),
    .axi_out_req_o  ( node_man_req[1] ),
    .axi_out_rsp_i  ( node_man_rsp[1] ),
    .end_of_sim_o   ( end_of_sim[1]   )
  );

  axi_bw_monitor #(
    .req_t      ( axi_in_req_t  ),
    .rsp_t      ( axi_in_rsp_t  ),
    .AxiIdWidth ( AxiInIdWidth  )
  ) i_axi_bw_monitor (
    .clk_i          ( clk             ),
    .en_i           ( rst_n           ),
    .end_of_sim_i   ( &end_of_sim     ),
    .req_i          ( node_man_req[0] ),
    .rsp_i          ( node_man_rsp[0] ),
    .ar_in_flight_o (                 ),
    .aw_in_flight_o (                 )
  );

  initial begin
    wait(&end_of_sim);
    repeat (50) @(posedge clk);
    $stop;
  end

endmodule
