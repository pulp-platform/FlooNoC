// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_floo_narrow_wide_chimney;

  import floo_pkg::*;
  import floo_narrow_wide_flit_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam NarrowNumReads = 1000;
  localparam NarrowNumWrites = 1000;
  localparam WideNumReads = 1000;
  localparam WideNumWrites = 1000;

  localparam NumTargets = 2;

  localparam int unsigned ReorderBufferSize = 128;
  localparam int unsigned MaxTxns = 32;
  localparam int unsigned MaxTxnsPerId = 32;

  logic clk, rst_n;

  narrow_in_req_t [NumTargets-1:0] narrow_man_req;
  narrow_in_resp_t [NumTargets-1:0] narrow_man_rsp;
  wide_in_req_t [NumTargets-1:0] wide_man_req;
  wide_in_resp_t [NumTargets-1:0] wide_man_rsp;

  narrow_out_req_t [NumTargets-1:0] narrow_sub_req;
  narrow_out_resp_t [NumTargets-1:0] narrow_sub_rsp;
  wide_out_req_t [NumTargets-1:0] wide_sub_req;
  wide_out_resp_t [NumTargets-1:0] wide_sub_rsp;

  narrow_in_req_t [NumTargets-1:0] narrow_sub_req_id_mapped;
  narrow_in_resp_t [NumTargets-1:0] narrow_sub_rsp_id_mapped;
  wide_in_req_t [NumTargets-1:0] wide_sub_req_id_mapped;
  wide_in_resp_t [NumTargets-1:0] wide_sub_rsp_id_mapped;

  for (genvar i = 0; i < NumDirections; i++) begin : gen_dir
    `AXI_ASSIGN_REQ_STRUCT(narrow_sub_req_id_mapped[i], narrow_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(narrow_sub_rsp_id_mapped[i], narrow_sub_rsp[i])
    `AXI_ASSIGN_REQ_STRUCT(wide_sub_req_id_mapped[i], wide_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(wide_sub_rsp_id_mapped[i], wide_sub_rsp[i])
  end

  narrow_req_flit_t [NumTargets-1:0] narrow_chimney_req;
  narrow_rsp_flit_t [NumTargets-1:0] narrow_chimney_rsp;
  wide_flit_t [NumTargets-1:0] wide_chimney;

  logic [NumTargets*3-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  typedef struct packed {
    logic [NarrowInAddrWidth-1:0] start_addr;
    logic [NarrowInAddrWidth-1:0] end_addr;
  } node_addr_region_t;

  localparam int unsigned NumAddrRegions = 1;
  localparam node_addr_region_t [NumAddrRegions-1:0] AddrRegions = '{
    '{start_addr: 48'h000_0000_0000, end_addr: 48'h000_0000_8000}
  };

  floo_axi_test_node #(
    .AxiAddrWidth   ( NarrowInAddrWidth   ),
    .AxiDataWidth   ( NarrowInDataWidth   ),
    .AxiIdInWidth   ( NarrowOutIdWidth    ),
    .AxiIdOutWidth  ( NarrowInIdWidth     ),
    .AxiUserWidth   ( NarrowInUserWidth   ),
    .mst_req_t      ( narrow_in_req_t     ),
    .mst_rsp_t      ( narrow_in_resp_t    ),
    .slv_req_t      ( narrow_out_req_t    ),
    .slv_rsp_t      ( narrow_out_resp_t   ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .Atops          ( 1'b1                ),
    .AxiMaxBurstLen ( ReorderBufferSize   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( NarrowNumReads      ),
    .NumWrites      ( NarrowNumWrites     )
  ) i_narrow_test_node_0 (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .mst_port_req_o ( narrow_man_req[0] ),
    .mst_port_rsp_i ( narrow_man_rsp[0] ),
    .slv_port_req_i ( narrow_sub_req[0] ),
    .slv_port_rsp_o ( narrow_sub_rsp[0] ),
    .end_of_sim     ( end_of_sim[0]     )
  );

  floo_axi_test_node #(
    .AxiAddrWidth   ( WideInAddrWidth     ),
    .AxiDataWidth   ( WideInDataWidth     ),
    .AxiIdInWidth   ( WideOutIdWidth      ),
    .AxiIdOutWidth  ( WideInIdWidth       ),
    .AxiUserWidth   ( WideInUserWidth     ),
    .mst_req_t      ( wide_in_req_t       ),
    .mst_rsp_t      ( wide_in_resp_t      ),
    .slv_req_t      ( wide_out_req_t      ),
    .slv_rsp_t      ( wide_out_resp_t     ),
    .Atops          ( 1'b0                ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .AxiMaxBurstLen ( ReorderBufferSize   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( WideNumReads        ),
    .NumWrites      ( WideNumWrites       )
  ) i_wide_test_node_0 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .mst_port_req_o ( wide_man_req[0] ),
    .mst_port_rsp_i ( wide_man_rsp[0] ),
    .slv_port_req_i ( wide_sub_req[0] ),
    .slv_port_rsp_o ( wide_sub_rsp[0] ),
    .end_of_sim     ( end_of_sim[1]   )
  );

  axi_reorder_remap_compare #(
    .AxiInIdWidth   ( NarrowInIdWidth     ),
    .AxiOutIdWidth  ( NarrowOutIdWidth    ),
    .aw_chan_t      ( narrow_in_aw_chan_t ),
    .w_chan_t       ( narrow_in_w_chan_t  ),
    .b_chan_t       ( narrow_in_b_chan_t  ),
    .ar_chan_t      ( narrow_in_ar_chan_t ),
    .r_chan_t       ( narrow_in_r_chan_t  ),
    .req_t          ( narrow_in_req_t     ),
    .rsp_t          ( narrow_in_resp_t    )
  ) i_narrow_channel_compare_0 (
    .clk_i          ( clk                         ),
    .mon_mst_req_i  ( narrow_man_req[0]           ),
    .mon_mst_rsp_i  ( narrow_man_rsp[0]           ),
    .mon_slv_req_i  ( narrow_sub_req_id_mapped[1] ),
    .mon_slv_rsp_i  ( narrow_sub_rsp_id_mapped[1] ),
    .end_of_sim_o   ( end_of_sim[2]               )
  );

  axi_channel_compare #(
    .aw_chan_t  ( wide_in_aw_chan_t ),
    .w_chan_t   ( wide_in_w_chan_t  ),
    .b_chan_t   ( wide_in_b_chan_t  ),
    .ar_chan_t  ( wide_in_ar_chan_t ),
    .r_chan_t   ( wide_in_r_chan_t  ),
    .req_t      ( wide_in_req_t     ),
    .resp_t     ( wide_in_resp_t    )
  ) i_wide_channel_compare_0 (
    .clk_i      ( clk             ),
    .axi_a_req  ( wide_man_req[0] ),
    .axi_a_res  ( wide_man_rsp[0] ),
    .axi_b_req  ( wide_sub_req_id_mapped[1] ),
    .axi_b_res  ( wide_sub_rsp_id_mapped[1] )
  );

  floo_narrow_wide_chimney #(
    .AtopSupport              ( 1'b1                ),
    .MaxAtomicTxns            ( 1                   ),
    .RouteAlgo                ( floo_pkg::IdTable   ),
    .NarrowMaxTxns            ( MaxTxns             ),
    .NarrowMaxTxnsPerId       ( MaxTxnsPerId        ),
    .NarrowReorderBufferSize  ( ReorderBufferSize   ),
    .WideMaxTxns              ( MaxTxns             ),
    .WideMaxTxnsPerId         ( MaxTxnsPerId        ),
    .WideReorderBufferSize    ( ReorderBufferSize   )
  ) i_floo_narrow_wide_chimney_0 (
    .clk_i            ( clk                   ),
    .rst_ni           ( rst_n                 ),
    .sram_cfg_i       ( '0                    ),
    .test_enable_i    ( 1'b0                  ),
    .narrow_in_req_i  ( narrow_man_req[0]     ),
    .narrow_in_rsp_o  ( narrow_man_rsp[0]     ),
    .narrow_out_req_o ( narrow_sub_req[0]     ),
    .narrow_out_rsp_i ( narrow_sub_rsp[0]     ),
    .wide_in_req_i    ( wide_man_req[0]       ),
    .wide_in_rsp_o    ( wide_man_rsp[0]       ),
    .wide_out_req_o   ( wide_sub_req[0]       ),
    .wide_out_rsp_i   ( wide_sub_rsp[0]       ),
    .xy_id_i          ( '0                    ),
    .id_i             ( '0                    ),
    .narrow_req_o     ( narrow_chimney_req[0] ),
    .narrow_rsp_o     ( narrow_chimney_rsp[0] ),
    .wide_o           ( wide_chimney[0]       ),
    .narrow_req_i     ( narrow_chimney_req[1] ),
    .narrow_rsp_i     ( narrow_chimney_rsp[1] ),
    .wide_i           ( wide_chimney[1]       )
    );

  floo_narrow_wide_chimney #(
    .AtopSupport              ( 1'b1                ),
    .MaxAtomicTxns            ( 1                   ),
    .RouteAlgo                ( floo_pkg::IdTable   ),
    .NarrowMaxTxns            ( MaxTxns             ),
    .NarrowMaxTxnsPerId       ( MaxTxnsPerId        ),
    .NarrowReorderBufferSize  ( ReorderBufferSize   ),
    .WideMaxTxns              ( MaxTxns             ),
    .WideMaxTxnsPerId         ( MaxTxnsPerId        ),
    .WideReorderBufferSize    ( ReorderBufferSize   )
  ) i_floo_narrow_wide_chimney_1 (
    .clk_i            ( clk                   ),
    .rst_ni           ( rst_n                 ),
    .sram_cfg_i       ( '0                    ),
    .test_enable_i    ( 1'b0                  ),
    .narrow_in_req_i  ( narrow_man_req[1]     ),
    .narrow_in_rsp_o  ( narrow_man_rsp[1]     ),
    .narrow_out_req_o ( narrow_sub_req[1]     ),
    .narrow_out_rsp_i ( narrow_sub_rsp[1]     ),
    .wide_in_req_i    ( wide_man_req[1]       ),
    .wide_in_rsp_o    ( wide_man_rsp[1]       ),
    .wide_out_req_o   ( wide_sub_req[1]       ),
    .wide_out_rsp_i   ( wide_sub_rsp[1]       ),
    .xy_id_i          ( '0                    ),
    .id_i             ( '0                    ),
    .narrow_req_o     ( narrow_chimney_req[1] ),
    .narrow_rsp_o     ( narrow_chimney_rsp[1] ),
    .wide_o           ( wide_chimney[1]       ),
    .narrow_req_i     ( narrow_chimney_req[0] ),
    .narrow_rsp_i     ( narrow_chimney_rsp[0] ),
    .wide_i           ( wide_chimney[0]       )
  );

  axi_reorder_remap_compare #(
    .AxiInIdWidth   ( NarrowInIdWidth     ),
    .AxiOutIdWidth  ( NarrowOutIdWidth    ),
    .aw_chan_t      ( narrow_in_aw_chan_t ),
    .w_chan_t       ( narrow_in_w_chan_t  ),
    .b_chan_t       ( narrow_in_b_chan_t  ),
    .ar_chan_t      ( narrow_in_ar_chan_t ),
    .r_chan_t       ( narrow_in_r_chan_t  ),
    .req_t          ( narrow_in_req_t     ),
    .rsp_t          ( narrow_in_resp_t    )
  ) i_narrow_channel_compare_1 (
    .clk_i          ( clk                         ),
    .mon_mst_req_i  ( narrow_man_req[1]           ),
    .mon_mst_rsp_i  ( narrow_man_rsp[1]           ),
    .mon_slv_req_i  ( narrow_sub_req_id_mapped[0] ),
    .mon_slv_rsp_i  ( narrow_sub_rsp_id_mapped[0] ),
    .end_of_sim_o   ( end_of_sim[3]               )
  );

  axi_channel_compare #(
    .aw_chan_t  ( wide_in_aw_chan_t ),
    .w_chan_t   ( wide_in_w_chan_t  ),
    .b_chan_t   ( wide_in_b_chan_t  ),
    .ar_chan_t  ( wide_in_ar_chan_t ),
    .r_chan_t   ( wide_in_r_chan_t  ),
    .req_t      ( wide_in_req_t     ),
    .resp_t     ( wide_in_resp_t    )
  ) i_wide_channel_compare_1 (
    .clk_i      ( clk             ),
    .axi_a_req  ( wide_man_req[1] ),
    .axi_a_res  ( wide_man_rsp[1] ),
    .axi_b_req  ( wide_sub_req_id_mapped[0] ),
    .axi_b_res  ( wide_sub_rsp_id_mapped[0] )
  );

  floo_axi_test_node #(
    .AxiAddrWidth   ( NarrowInAddrWidth   ),
    .AxiDataWidth   ( NarrowInDataWidth   ),
    .AxiIdOutWidth  ( NarrowInIdWidth     ),
    .AxiIdInWidth   ( NarrowOutIdWidth    ),
    .AxiUserWidth   ( NarrowInUserWidth   ),
    .mst_req_t      ( narrow_in_req_t     ),
    .mst_rsp_t      ( narrow_in_resp_t    ),
    .slv_req_t      ( narrow_out_req_t    ),
    .slv_rsp_t      ( narrow_out_resp_t   ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .Atops          ( 1'b1                ),
    .AxiMaxBurstLen ( ReorderBufferSize   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( NarrowNumReads      ),
    .NumWrites      ( NarrowNumWrites     )
  ) i_narrow_test_node_1 (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .mst_port_req_o ( narrow_man_req[1] ),
    .mst_port_rsp_i ( narrow_man_rsp[1] ),
    .slv_port_req_i ( narrow_sub_req[1] ),
    .slv_port_rsp_o ( narrow_sub_rsp[1] ),
    .end_of_sim     ( end_of_sim[4]     )
  );

  floo_axi_test_node #(
    .AxiAddrWidth   ( WideInAddrWidth     ),
    .AxiDataWidth   ( WideInDataWidth     ),
    .AxiIdInWidth   ( WideOutIdWidth      ),
    .AxiIdOutWidth  ( WideInIdWidth       ),
    .AxiUserWidth   ( WideInUserWidth     ),
    .mst_req_t      ( wide_in_req_t       ),
    .mst_rsp_t      ( wide_in_resp_t      ),
    .slv_req_t      ( wide_out_req_t      ),
    .slv_rsp_t      ( wide_out_resp_t     ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .AxiMaxBurstLen ( ReorderBufferSize   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( WideNumReads        ),
    .NumWrites      ( WideNumWrites       )
  ) i_wide_test_node_1 (
    .clk_i          ( clk             ),
    .rst_ni         ( rst_n           ),
    .mst_port_req_o ( wide_man_req[1] ),
    .mst_port_rsp_i ( wide_man_rsp[1] ),
    .slv_port_req_i ( wide_sub_req[1] ),
    .slv_port_rsp_o ( wide_sub_rsp[1] ),
    .end_of_sim     ( end_of_sim[5]   )
  );

  initial begin
    wait(&end_of_sim);
    $stop;
  end


endmodule
