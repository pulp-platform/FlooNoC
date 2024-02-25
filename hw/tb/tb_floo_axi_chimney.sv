// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_floo_axi_chimney;

  import floo_pkg::*;
  import floo_axi_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumReads0 = 1000;
  localparam int unsigned NumWrites0 = 1000;
  localparam int unsigned NumReads1 = 1000;
  localparam int unsigned NumWrites1 = 1000;

  localparam bit AtopSupport = 1'b1;

  localparam int unsigned NumTargets = 2;

  localparam int unsigned ReorderBufferSize = 64;
  localparam int unsigned MaxTxns = 32;
  localparam int unsigned MaxTxnsPerId = 32;

  logic clk, rst_n;

  axi_in_req_t [NumTargets-1:0] node_man_req;
  axi_in_rsp_t [NumTargets-1:0] node_man_rsp;

  axi_out_req_t [NumTargets-1:0] node_sub_req;
  axi_out_rsp_t [NumTargets-1:0] node_sub_rsp;

  axi_in_req_t [NumTargets-1:0] sub_req_id_assign;
  axi_in_rsp_t [NumTargets-1:0] sub_rsp_id_assign;

  for (genvar i = 0; i < NumTargets; i++) begin : gen_axi_assign
    `AXI_ASSIGN_REQ_STRUCT(sub_req_id_assign[i], node_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(sub_rsp_id_assign[i], node_sub_rsp[i])
  end

  floo_req_t [NumTargets-1:0] chimney_req;
  floo_rsp_t [NumTargets-1:0] chimney_rsp;

  logic [NumTargets*2-1:0] end_of_sim;

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

  localparam int unsigned NumAddrRegions = 1;
  localparam node_addr_region_t [NumAddrRegions-1:0] AddrRegions = '{
    '{start_addr: 32'h0000_0000, end_addr: 32'h0000_8000}
  };

  floo_axi_test_node #(
    .AxiAddrWidth   ( AxiInAddrWidth      ),
    .AxiDataWidth   ( AxiInDataWidth      ),
    .AxiIdOutWidth  ( AxiInIdWidth        ),
    .AxiIdInWidth   ( AxiOutIdWidth       ),
    .AxiUserWidth   ( AxiInUserWidth      ),
    .mst_req_t      ( axi_in_req_t        ),
    .mst_rsp_t      ( axi_in_rsp_t        ),
    .slv_req_t      ( axi_out_req_t       ),
    .slv_rsp_t      ( axi_out_rsp_t       ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .Atops          ( AtopSupport         ),
    .AxiMaxBurstLen ( ReorderBufferSize   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( NumReads0           ),
    .NumWrites      ( NumWrites0          )
  ) i_test_node_0 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .mst_port_req_o ( node_man_req[0] ),
    .mst_port_rsp_i ( node_man_rsp[0] ),
    .slv_port_req_i ( node_sub_req[0] ),
    .slv_port_rsp_o ( node_sub_rsp[0] ),
    .end_of_sim     ( end_of_sim[0]   )
  );

  axi_reorder_remap_compare #(
    .AxiInIdWidth   ( AxiInIdWidth      ),
    .AxiOutIdWidth  ( AxiOutIdWidth     ),
    .aw_chan_t      ( axi_in_aw_chan_t  ),
    .w_chan_t       ( axi_in_w_chan_t   ),
    .b_chan_t       ( axi_in_b_chan_t   ),
    .ar_chan_t      ( axi_in_ar_chan_t  ),
    .r_chan_t       ( axi_in_r_chan_t   ),
    .req_t          ( axi_in_req_t      ),
    .rsp_t          ( axi_in_rsp_t      )
  ) i_axi_chan_compare_0 (
    .clk_i          ( clk                   ),
    .mon_mst_req_i  ( node_man_req[0]       ),
    .mon_mst_rsp_i  ( node_man_rsp[0]       ),
    .mon_slv_req_i  ( sub_req_id_assign[1]  ),
    .mon_slv_rsp_i  ( sub_rsp_id_assign[1]  ),
    .end_of_sim_o   ( end_of_sim[1]         )
  );

  floo_axi_chimney #(
    .AtopSupport        ( AtopSupport         ),
    .MaxAtomicTxns      ( 4                   ),
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
    .AtopSupport        ( AtopSupport         ),
    .MaxAtomicTxns      ( 4                   ),
    .MaxTxns            ( MaxTxns             ),
    .MaxTxnsPerId       ( MaxTxnsPerId        ),
    .ReorderBufferSize  ( ReorderBufferSize   )
  ) i_floo_axi_chimney_1 (
    .clk_i          ( clk                   ),
    .rst_ni         ( rst_n                 ),
    .sram_cfg_i     ( '0                    ),
    .test_enable_i  ( 1'b0                  ),
    .axi_in_req_i   ( node_man_req[1]       ),
    .axi_in_rsp_o   ( node_man_rsp[1]       ),
    .axi_out_req_o  ( node_sub_req[1]       ),
    .axi_out_rsp_i  ( node_sub_rsp[1]       ),
    .id_i           ( '0                    ),
    .route_table_i  ( '0                    ),
    .floo_req_o     ( chimney_req[1]        ),
    .floo_rsp_o     ( chimney_rsp[1]        ),
    .floo_req_i     ( chimney_req[0]        ),
    .floo_rsp_i     ( chimney_rsp[0]        )
  );

  axi_reorder_remap_compare #(
    .AxiInIdWidth   ( AxiInIdWidth      ),
    .AxiOutIdWidth  ( AxiOutIdWidth     ),
    .aw_chan_t      ( axi_in_aw_chan_t  ),
    .w_chan_t       ( axi_in_w_chan_t   ),
    .b_chan_t       ( axi_in_b_chan_t   ),
    .ar_chan_t      ( axi_in_ar_chan_t  ),
    .r_chan_t       ( axi_in_r_chan_t   ),
    .req_t          ( axi_in_req_t      ),
    .rsp_t          ( axi_in_rsp_t      )
  ) i_axi_chan_compare_1 (
    .clk_i          ( clk                   ),
    .mon_mst_req_i  ( node_man_req[1]       ),
    .mon_mst_rsp_i  ( node_man_rsp[1]       ),
    .mon_slv_req_i  ( sub_req_id_assign[0]  ),
    .mon_slv_rsp_i  ( sub_rsp_id_assign[0]  ),
    .end_of_sim_o   ( end_of_sim[2]         )
  );

  floo_axi_test_node #(
    .AxiAddrWidth   ( AxiInAddrWidth      ),
    .AxiDataWidth   ( AxiInDataWidth      ),
    .AxiIdInWidth   ( AxiOutIdWidth       ),
    .AxiIdOutWidth  ( AxiInIdWidth        ),
    .AxiUserWidth   ( AxiInUserWidth      ),
    .mst_req_t      ( axi_in_req_t        ),
    .mst_rsp_t      ( axi_in_rsp_t        ),
    .slv_req_t      ( axi_out_req_t       ),
    .slv_rsp_t      ( axi_out_rsp_t       ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .Atops          ( AtopSupport         ),
    .AxiMaxBurstLen ( ReorderBufferSize   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( NumReads1           ),
    .NumWrites      ( NumWrites1          )
  ) i_test_node_1 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .mst_port_req_o ( node_man_req[1] ),
    .mst_port_rsp_i ( node_man_rsp[1] ),
    .slv_port_req_i ( node_sub_req[1] ),
    .slv_port_rsp_o ( node_sub_rsp[1] ),
    .end_of_sim     ( end_of_sim[3]   )
  );

  axi_bw_monitor #(
    .req_t      ( axi_in_req_t  ),
    .rsp_t      ( axi_in_rsp_t ),
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
