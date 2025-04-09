// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_floo_nw_chimney;

  import floo_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NarrowNumReads = 1000;
  localparam int unsigned NarrowNumWrites = 1000;
  localparam int unsigned WideNumReads = 1000;
  localparam int unsigned WideNumWrites = 1000;

  localparam bit AtopSupport = 1'b1;
  localparam int unsigned MaxAtomicTxns = 3;

  // Function to generate a chimney config UniqueIds for testing
  function automatic chimney_cfg_t gen_wide_chimney_cfg();
    chimney_cfg_t cfg = ChimneyDefaultCfg;
    // cfg.MaxUniqueIds = 2;
    cfg.CutRsp = 1'b1; // Otherwise the compare will fail since it is a feedthrough
    return cfg;
  endfunction

  function automatic chimney_cfg_t gen_narrow_chimney_cfg();
    chimney_cfg_t cfg = ChimneyDefaultCfg;
    cfg.CutRsp = 1'b1; // Otherwise the compare will fail since it is a feedthrough
    return cfg;
  endfunction

  // Default chimney config with RoB for testing
  localparam chimney_cfg_t WideChimneyCfg = gen_wide_chimney_cfg();
  localparam chimney_cfg_t NarrowChimneyCfg = gen_narrow_chimney_cfg();

  localparam int unsigned NumTargets = 2;

  logic clk, rst_n;

  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)
  // `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic)
  `FLOO_TYPEDEF_MASK_HDR_T(hdr_t, id_t, id_t, id_t, floo_pkg::nw_ch_e, logic, floo_pkg::commtype_e)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, floo_test_pkg::AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, floo_test_pkg::AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in,
      floo_test_pkg::AxiCfgN, floo_test_pkg::AxiCfgW, hdr_t)
  `FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, req, rsp, wide)

  axi_narrow_in_req_t [NumTargets-1:0] narrow_man_req;
  axi_narrow_in_rsp_t [NumTargets-1:0] narrow_man_rsp;
  axi_wide_in_req_t [NumTargets-1:0] wide_man_req;
  axi_wide_in_rsp_t [NumTargets-1:0] wide_man_rsp;

  axi_narrow_out_req_t [NumTargets-1:0] narrow_sub_req, narrow_sub_req_sync;
  axi_narrow_out_rsp_t [NumTargets-1:0] narrow_sub_rsp, narrow_sub_rsp_sync;
  axi_wide_out_req_t [NumTargets-1:0] wide_sub_req;
  axi_wide_out_rsp_t [NumTargets-1:0] wide_sub_rsp;

  axi_narrow_in_req_t [NumTargets-1:0] narrow_sub_req_id_mapped;
  axi_narrow_in_rsp_t [NumTargets-1:0] narrow_sub_rsp_id_mapped;
  axi_wide_in_req_t [NumTargets-1:0] wide_sub_req_id_mapped;
  axi_wide_in_rsp_t [NumTargets-1:0] wide_sub_rsp_id_mapped;

  for (genvar i = 0; i < NumTargets; i++) begin : gen_dir
    `AXI_ASSIGN_REQ_STRUCT(narrow_sub_req_id_mapped[i], narrow_sub_req_sync[i])
    `AXI_ASSIGN_RESP_STRUCT(narrow_sub_rsp_id_mapped[i], narrow_sub_rsp_sync[i])
    `AXI_ASSIGN_REQ_STRUCT(wide_sub_req_id_mapped[i], wide_sub_req[i])
    `AXI_ASSIGN_RESP_STRUCT(wide_sub_rsp_id_mapped[i], wide_sub_rsp[i])
  end

  floo_req_t [NumTargets-1:0] chimney_req;
  floo_rsp_t [NumTargets-1:0] chimney_rsp;
  floo_wide_t [NumTargets-1:0] chimney_wide;

  logic [NumTargets*3-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  typedef struct packed {
    logic [floo_test_pkg::AxiCfg.AddrWidth-1:0] start_addr;
    logic [floo_test_pkg::AxiCfg.AddrWidth-1:0] end_addr;
  } node_addr_region_t;

  localparam int unsigned NumAddrRegions = 1;
  localparam node_addr_region_t [NumAddrRegions-1:0] AddrRegions = '{
    '{start_addr: 32'h0000_0000, end_addr: 32'h0000_8000}
  };

  floo_axi_test_node #(
    .AxiCfg         ( floo_test_pkg::AxiCfgN  ),
    .mst_req_t      ( axi_narrow_in_req_t     ),
    .mst_rsp_t      ( axi_narrow_in_rsp_t     ),
    .slv_req_t      ( axi_narrow_out_req_t    ),
    .slv_rsp_t      ( axi_narrow_out_rsp_t    ),
    .ApplTime       ( ApplTime                ),
    .TestTime       ( TestTime                ),
    .Atops          ( AtopSupport             ),
    .NumAddrRegions ( NumAddrRegions          ),
    .rule_t         ( node_addr_region_t      ),
    .AddrRegions    ( AddrRegions             ),
    .AxiMaxBurstLen ( 1                       ),
    .NumReads       ( NarrowNumReads          ),
    .NumWrites      ( NarrowNumWrites         )
  ) i_narrow_test_node_0 (
    .clk_i          ( clk                     ),
    .rst_ni         ( rst_n                   ),
    .mst_port_req_o ( narrow_man_req[0]       ),
    .mst_port_rsp_i ( narrow_man_rsp[0]       ),
    .slv_port_req_i ( narrow_sub_req_sync[0]  ),
    .slv_port_rsp_o ( narrow_sub_rsp_sync[0]  ),
    .end_of_sim     ( end_of_sim[0]           )
  );

  floo_axi_test_node #(
    .AxiCfg         ( floo_test_pkg::AxiCfg ),
    .mst_req_t      ( axi_wide_in_req_t     ),
    .mst_rsp_t      ( axi_wide_in_rsp_t     ),
    .slv_req_t      ( axi_wide_out_req_t    ),
    .slv_rsp_t      ( axi_wide_out_rsp_t    ),
    .Atops          ( 1'b0                  ),
    .NumAddrRegions ( NumAddrRegions        ),
    .rule_t         ( node_addr_region_t    ),
    .AddrRegions    ( AddrRegions           ),
    .ApplTime       ( ApplTime              ),
    .TestTime       ( TestTime              ),
    .NumReads       ( WideNumReads          ),
    .NumWrites      ( WideNumWrites         )
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
    .AxiInIdWidth   ( floo_test_pkg::AxiCfgN.InIdWidth  ),
    .AxiOutIdWidth  ( floo_test_pkg::AxiCfgN.OutIdWidth ),
    .aw_chan_t      ( axi_narrow_in_aw_chan_t           ),
    .w_chan_t       ( axi_narrow_in_w_chan_t            ),
    .b_chan_t       ( axi_narrow_in_b_chan_t            ),
    .ar_chan_t      ( axi_narrow_in_ar_chan_t           ),
    .r_chan_t       ( axi_narrow_in_r_chan_t            ),
    .req_t          ( axi_narrow_in_req_t               ),
    .rsp_t          ( axi_narrow_in_rsp_t               )
  ) i_narrow_channel_compare_0 (
    .clk_i          ( clk                         ),
    .mon_mst_req_i  ( narrow_man_req[0]           ),
    .mon_mst_rsp_i  ( narrow_man_rsp[0]           ),
    .mon_slv_req_i  ( narrow_sub_req_id_mapped[1] ),
    .mon_slv_rsp_i  ( narrow_sub_rsp_id_mapped[1] ),
    .end_of_sim_o   ( end_of_sim[2]               )
  );

  axi_chan_compare #(
    .IgnoreId   ( 1'b1                  ),
    .aw_chan_t  ( axi_wide_in_aw_chan_t ),
    .w_chan_t   ( axi_wide_in_w_chan_t  ),
    .b_chan_t   ( axi_wide_in_b_chan_t  ),
    .ar_chan_t  ( axi_wide_in_ar_chan_t ),
    .r_chan_t   ( axi_wide_in_r_chan_t  ),
    .req_t      ( axi_wide_in_req_t     ),
    .resp_t     ( axi_wide_in_rsp_t     )
  ) i_wide_channel_compare_0 (
    .clk_a_i    ( clk                       ),
    .clk_b_i    ( clk                       ),
    .axi_a_req  ( wide_man_req[0]           ),
    .axi_a_res  ( wide_man_rsp[0]           ),
    .axi_b_req  ( wide_sub_req_id_mapped[1] ),
    .axi_b_res  ( wide_sub_rsp_id_mapped[1] )
  );

  axi_aw_w_sync #(
    .axi_req_t  ( axi_narrow_out_req_t ),
    .axi_resp_t ( axi_narrow_out_rsp_t )
  ) i_axi_aw_w_sync_0 (
    .clk_i      ( clk                     ),
    .rst_ni     ( rst_n                   ),
    .slv_req_i  ( narrow_sub_req[0]       ),
    .slv_resp_o ( narrow_sub_rsp[0]       ),
    .mst_req_o  ( narrow_sub_req_sync[0]  ),
    .mst_resp_i ( narrow_sub_rsp_sync[0]  )
  );

  floo_nw_chimney #(
    .AxiCfgN              ( floo_test_pkg::AxiCfgN  ),
    .AxiCfgW              ( floo_test_pkg::AxiCfgW  ),
    .ChimneyCfgN          ( NarrowChimneyCfg        ),
    .ChimneyCfgW          ( WideChimneyCfg          ),
    .RouteCfg             ( floo_test_pkg::RouteCfg ),
    .AtopSupport          ( AtopSupport             ),
    .MaxAtomicTxns        ( MaxAtomicTxns           ),
    .hdr_t                ( hdr_t                   ),
    .id_t                 ( id_t                    ),
    .axi_narrow_in_req_t  ( axi_narrow_in_req_t     ),
    .axi_narrow_in_rsp_t  ( axi_narrow_in_rsp_t     ),
    .axi_narrow_out_req_t ( axi_narrow_out_req_t    ),
    .axi_narrow_out_rsp_t ( axi_narrow_out_rsp_t    ),
    .axi_wide_in_req_t    ( axi_wide_in_req_t       ),
    .axi_wide_in_rsp_t    ( axi_wide_in_rsp_t       ),
    .axi_wide_out_req_t   ( axi_wide_out_req_t      ),
    .axi_wide_out_rsp_t   ( axi_wide_out_rsp_t      ),
    .floo_req_t           ( floo_req_t              ),
    .floo_rsp_t           ( floo_rsp_t              ),
    .floo_wide_t          ( floo_wide_t             )
  ) i_floo_nw_chimney_0 (
    .clk_i                ( clk               ),
    .rst_ni               ( rst_n             ),
    .sram_cfg_i           ( '0                ),
    .test_enable_i        ( 1'b0              ),
    .axi_narrow_in_req_i  ( narrow_man_req[0] ),
    .axi_narrow_in_rsp_o  ( narrow_man_rsp[0] ),
    .axi_narrow_out_req_o ( narrow_sub_req[0] ),
    .axi_narrow_out_rsp_i ( narrow_sub_rsp[0] ),
    .axi_wide_in_req_i    ( wide_man_req[0]   ),
    .axi_wide_in_rsp_o    ( wide_man_rsp[0]   ),
    .axi_wide_out_req_o   ( wide_sub_req[0]   ),
    .axi_wide_out_rsp_i   ( wide_sub_rsp[0]   ),
    .id_i                 ( '0                ),
    .route_table_i        ( '0                ),
    .floo_req_o           ( chimney_req[0]    ),
    .floo_rsp_o           ( chimney_rsp[0]    ),
    .floo_wide_o          ( chimney_wide[0]   ),
    .floo_req_i           ( chimney_req[1]    ),
    .floo_rsp_i           ( chimney_rsp[1]    ),
    .floo_wide_i          ( chimney_wide[1]   )
    );

  floo_nw_chimney #(
    .AxiCfgN              ( floo_test_pkg::AxiCfgN  ),
    .AxiCfgW              ( floo_test_pkg::AxiCfgW  ),
    .ChimneyCfgN          ( NarrowChimneyCfg        ),
    .ChimneyCfgW          ( WideChimneyCfg          ),
    .RouteCfg             ( floo_test_pkg::RouteCfg ),
    .AtopSupport          ( AtopSupport             ),
    .MaxAtomicTxns        ( MaxAtomicTxns           ),
    .hdr_t                ( hdr_t                   ),
    .id_t                 ( id_t                    ),
    .axi_narrow_in_req_t  ( axi_narrow_in_req_t     ),
    .axi_narrow_in_rsp_t  ( axi_narrow_in_rsp_t     ),
    .axi_narrow_out_req_t ( axi_narrow_out_req_t    ),
    .axi_narrow_out_rsp_t ( axi_narrow_out_rsp_t    ),
    .axi_wide_in_req_t    ( axi_wide_in_req_t       ),
    .axi_wide_in_rsp_t    ( axi_wide_in_rsp_t       ),
    .axi_wide_out_req_t   ( axi_wide_out_req_t      ),
    .axi_wide_out_rsp_t   ( axi_wide_out_rsp_t      ),
    .floo_req_t           ( floo_req_t              ),
    .floo_rsp_t           ( floo_rsp_t              ),
    .floo_wide_t          ( floo_wide_t             )
  ) i_floo_nw_chimney_1 (
    .clk_i                ( clk               ),
    .rst_ni               ( rst_n             ),
    .sram_cfg_i           ( '0                ),
    .test_enable_i        ( 1'b0              ),
    .axi_narrow_in_req_i  ( narrow_man_req[1] ),
    .axi_narrow_in_rsp_o  ( narrow_man_rsp[1] ),
    .axi_narrow_out_req_o ( narrow_sub_req[1] ),
    .axi_narrow_out_rsp_i ( narrow_sub_rsp[1] ),
    .axi_wide_in_req_i    ( wide_man_req[1]   ),
    .axi_wide_in_rsp_o    ( wide_man_rsp[1]   ),
    .axi_wide_out_req_o   ( wide_sub_req[1]   ),
    .axi_wide_out_rsp_i   ( wide_sub_rsp[1]   ),
    .id_i                 ( '0                ),
    .route_table_i        ( '0                ),
    .floo_req_o           ( chimney_req[1]    ),
    .floo_rsp_o           ( chimney_rsp[1]    ),
    .floo_wide_o          ( chimney_wide[1]   ),
    .floo_req_i           ( chimney_req[0]    ),
    .floo_rsp_i           ( chimney_rsp[0]    ),
    .floo_wide_i          ( chimney_wide[0]   )
  );

  axi_aw_w_sync #(
    .axi_req_t  ( axi_narrow_out_req_t ),
    .axi_resp_t ( axi_narrow_out_rsp_t )
  ) i_axi_aw_w_sync_1 (
    .clk_i      ( clk                     ),
    .rst_ni     ( rst_n                   ),
    .slv_req_i  ( narrow_sub_req[1]       ),
    .slv_resp_o ( narrow_sub_rsp[1]       ),
    .mst_req_o  ( narrow_sub_req_sync[1]  ),
    .mst_resp_i ( narrow_sub_rsp_sync[1]  )
  );

  axi_reorder_remap_compare #(
    .AxiInIdWidth   ( floo_test_pkg::AxiCfgN.InIdWidth  ),
    .AxiOutIdWidth  ( floo_test_pkg::AxiCfgN.OutIdWidth ),
    .aw_chan_t      ( axi_narrow_in_aw_chan_t           ),
    .w_chan_t       ( axi_narrow_in_w_chan_t            ),
    .b_chan_t       ( axi_narrow_in_b_chan_t            ),
    .ar_chan_t      ( axi_narrow_in_ar_chan_t           ),
    .r_chan_t       ( axi_narrow_in_r_chan_t            ),
    .req_t          ( axi_narrow_in_req_t               ),
    .rsp_t          ( axi_narrow_in_rsp_t               )
  ) i_narrow_channel_compare_1 (
    .clk_i          ( clk                         ),
    .mon_mst_req_i  ( narrow_man_req[1]           ),
    .mon_mst_rsp_i  ( narrow_man_rsp[1]           ),
    .mon_slv_req_i  ( narrow_sub_req_id_mapped[0] ),
    .mon_slv_rsp_i  ( narrow_sub_rsp_id_mapped[0] ),
    .end_of_sim_o   ( end_of_sim[3]               )
  );

  axi_chan_compare #(
    .IgnoreId   ( 1'b1                  ),
    .aw_chan_t  ( axi_wide_in_aw_chan_t ),
    .w_chan_t   ( axi_wide_in_w_chan_t  ),
    .b_chan_t   ( axi_wide_in_b_chan_t  ),
    .ar_chan_t  ( axi_wide_in_ar_chan_t ),
    .r_chan_t   ( axi_wide_in_r_chan_t  ),
    .req_t      ( axi_wide_in_req_t     ),
    .resp_t     ( axi_wide_in_rsp_t     )
  ) i_wide_channel_compare_1 (
    .clk_a_i    ( clk             ),
    .clk_b_i    ( clk             ),
    .axi_a_req  ( wide_man_req[1] ),
    .axi_a_res  ( wide_man_rsp[1] ),
    .axi_b_req  ( wide_sub_req_id_mapped[0] ),
    .axi_b_res  ( wide_sub_rsp_id_mapped[0] )
  );

  floo_axi_test_node #(
    .AxiCfg         ( floo_test_pkg::AxiCfgN  ),
    .mst_req_t      ( axi_narrow_in_req_t     ),
    .mst_rsp_t      ( axi_narrow_in_rsp_t     ),
    .slv_req_t      ( axi_narrow_out_req_t    ),
    .slv_rsp_t      ( axi_narrow_out_rsp_t    ),
    .ApplTime       ( ApplTime                ),
    .TestTime       ( TestTime                ),
    .Atops          ( AtopSupport             ),
    .NumAddrRegions ( NumAddrRegions          ),
    .rule_t         ( node_addr_region_t      ),
    .AddrRegions    ( AddrRegions             ),
    .AxiMaxBurstLen ( 1                       ),
    .NumReads       ( NarrowNumReads          ),
    .NumWrites      ( NarrowNumWrites         )
  ) i_narrow_test_node_1 (
    .clk_i          ( clk                     ),
    .rst_ni         ( rst_n                   ),
    .mst_port_req_o ( narrow_man_req[1]       ),
    .mst_port_rsp_i ( narrow_man_rsp[1]       ),
    .slv_port_req_i ( narrow_sub_req_sync[1]  ),
    .slv_port_rsp_o ( narrow_sub_rsp_sync[1]  ),
    .end_of_sim     ( end_of_sim[4]           )
  );

  floo_axi_test_node #(
    .AxiCfg         ( floo_test_pkg::AxiCfgW ),
    .mst_req_t      ( axi_wide_in_req_t      ),
    .mst_rsp_t      ( axi_wide_in_rsp_t      ),
    .slv_req_t      ( axi_wide_out_req_t     ),
    .slv_rsp_t      ( axi_wide_out_rsp_t     ),
    .ApplTime       ( ApplTime               ),
    .TestTime       ( TestTime               ),
    .Atops          ( 1'b0                   ),
    .NumAddrRegions ( NumAddrRegions         ),
    .rule_t         ( node_addr_region_t     ),
    .AddrRegions    ( AddrRegions            ),
    .NumReads       ( WideNumReads           ),
    .NumWrites      ( WideNumWrites          )
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
