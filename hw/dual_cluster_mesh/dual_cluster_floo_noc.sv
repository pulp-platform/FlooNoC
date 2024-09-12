// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

package dual_cluster_floo_noc_pkg;

  import floo_narrow_wide_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

  typedef enum logic[3:0] {
    CheshireNi = 0,
    Cluster0Ni = 1,
    Cluster1Ni = 2,
    DramNi = 3,
    L2Port0Ni = 4,
    L2Port1Ni = 5,
    MboxNi = 6,
    OpentitanDmaNi = 7,
    OpentitanMainNi = 8,
    PeripheralsNi = 9,
    NumEndpoints = 10} ep_id_e;



  localparam int unsigned SamNumRules = 8;

typedef struct packed {
    id_t idx;
    logic [47:0] start_addr;
    logic [47:0] end_addr;
} sam_rule_t;

localparam sam_rule_t[SamNumRules-1:0] Sam = '{
'{idx: 1, start_addr: 48'h000050000000, end_addr: 48'h000050800000},// cluster_0_ni
'{idx: 2, start_addr: 48'h000050800000, end_addr: 48'h000051000000},// cluster_1_ni
'{idx: 3, start_addr: 48'h000080000000, end_addr: 48'h002080000000},// dram_ni
'{idx: 4, start_addr: 48'h000078000000, end_addr: 48'h000078200000},// l2_port0_ni
'{idx: 5, start_addr: 48'h000078200000, end_addr: 48'h000078400000},// l2_port1_ni
'{idx: 0, start_addr: 48'h000000000000, end_addr: 48'h000020000000},// cheshire_ni
'{idx: 9, start_addr: 48'h000020000000, end_addr: 48'h000040000000},// peripherals_ni
'{idx: 6, start_addr: 48'h000040000000, end_addr: 48'h000040003000} // mbox_ni

};



endpackage

module dual_cluster_floo_noc
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
  import dual_cluster_floo_noc_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  input axi_axi_in_req_t              cluster_0_axi_req_i,
  output axi_axi_in_rsp_t              cluster_0_axi_rsp_o,
  output axi_axi_out_req_t              cluster_0_axi_req_o,
  input axi_axi_out_rsp_t              cluster_0_axi_rsp_i,
  input axi_axi_in_req_t              cluster_1_axi_req_i,
  output axi_axi_in_rsp_t              cluster_1_axi_rsp_o,
  output axi_axi_out_req_t              cluster_1_axi_req_o,
  input axi_axi_out_rsp_t              cluster_1_axi_rsp_i,
  output axi_axi_out_req_t              dram_axi_req_o,
  input axi_axi_out_rsp_t              dram_axi_rsp_i,
  output axi_axi_out_req_t              l2_port0_axi_req_o,
  input axi_axi_out_rsp_t              l2_port0_axi_rsp_i,
  output axi_axi_out_req_t              l2_port1_axi_req_o,
  input axi_axi_out_rsp_t              l2_port1_axi_rsp_i,
  input axi_axi_in_req_t              cheshire_axi_req_i,
  output axi_axi_in_rsp_t              cheshire_axi_rsp_o,
  output axi_axi_out_req_t              cheshire_axi_req_o,
  input axi_axi_out_rsp_t              cheshire_axi_rsp_i,
  input axi_axi_in_req_t              opentitan_main_axi_req_i,
  output axi_axi_in_rsp_t              opentitan_main_axi_rsp_o,
  input axi_axi_in_req_t              opentitan_dma_axi_req_i,
  output axi_axi_in_rsp_t              opentitan_dma_axi_rsp_o,
  input axi_axi_in_req_t              peripherals_axi_req_i,
  output axi_axi_in_rsp_t              peripherals_axi_rsp_o,
  output axi_axi_out_req_t              peripherals_axi_req_o,
  input axi_axi_out_rsp_t              peripherals_axi_rsp_i,
  output axi_axi_out_req_t              mbox_axi_req_o,
  input axi_axi_out_rsp_t              mbox_axi_rsp_i

);

floo_req_t router_to_cluster_0_ni_req;
floo_rsp_t cluster_0_ni_to_router_rsp;
floo_wide_t router_to_cluster_0_ni_wide;

floo_req_t router_to_cluster_1_ni_req;
floo_rsp_t cluster_1_ni_to_router_rsp;
floo_wide_t router_to_cluster_1_ni_wide;

floo_req_t router_to_dram_ni_req;
floo_rsp_t dram_ni_to_router_rsp;
floo_wide_t router_to_dram_ni_wide;

floo_req_t router_to_l2_port0_ni_req;
floo_rsp_t l2_port0_ni_to_router_rsp;
floo_wide_t router_to_l2_port0_ni_wide;

floo_req_t router_to_l2_port1_ni_req;
floo_rsp_t l2_port1_ni_to_router_rsp;
floo_wide_t router_to_l2_port1_ni_wide;

floo_req_t router_to_cheshire_ni_req;
floo_rsp_t cheshire_ni_to_router_rsp;
floo_wide_t router_to_cheshire_ni_wide;

floo_req_t router_to_opentitan_main_ni_req;
floo_rsp_t opentitan_main_ni_to_router_rsp;
floo_wide_t router_to_opentitan_main_ni_wide;

floo_req_t router_to_opentitan_dma_ni_req;
floo_rsp_t opentitan_dma_ni_to_router_rsp;
floo_wide_t router_to_opentitan_dma_ni_wide;

floo_req_t router_to_peripherals_ni_req;
floo_rsp_t peripherals_ni_to_router_rsp;
floo_wide_t router_to_peripherals_ni_wide;

floo_req_t router_to_mbox_ni_req;
floo_rsp_t mbox_ni_to_router_rsp;
floo_wide_t router_to_mbox_ni_wide;

floo_req_t cluster_0_ni_to_router_req;
floo_rsp_t router_to_cluster_0_ni_rsp;
floo_wide_t cluster_0_ni_to_router_wide;

floo_req_t cluster_1_ni_to_router_req;
floo_rsp_t router_to_cluster_1_ni_rsp;
floo_wide_t cluster_1_ni_to_router_wide;

floo_req_t dram_ni_to_router_req;
floo_rsp_t router_to_dram_ni_rsp;
floo_wide_t dram_ni_to_router_wide;

floo_req_t l2_port0_ni_to_router_req;
floo_rsp_t router_to_l2_port0_ni_rsp;
floo_wide_t l2_port0_ni_to_router_wide;

floo_req_t l2_port1_ni_to_router_req;
floo_rsp_t router_to_l2_port1_ni_rsp;
floo_wide_t l2_port1_ni_to_router_wide;

floo_req_t cheshire_ni_to_router_req;
floo_rsp_t router_to_cheshire_ni_rsp;
floo_wide_t cheshire_ni_to_router_wide;

floo_req_t opentitan_main_ni_to_router_req;
floo_rsp_t router_to_opentitan_main_ni_rsp;
floo_wide_t opentitan_main_ni_to_router_wide;

floo_req_t opentitan_dma_ni_to_router_req;
floo_rsp_t router_to_opentitan_dma_ni_rsp;
floo_wide_t opentitan_dma_ni_to_router_wide;

floo_req_t peripherals_ni_to_router_req;
floo_rsp_t router_to_peripherals_ni_rsp;
floo_wide_t peripherals_ni_to_router_wide;

floo_req_t mbox_ni_to_router_req;
floo_rsp_t router_to_mbox_ni_rsp;
floo_wide_t mbox_ni_to_router_wide;



floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) cluster_0_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(1) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cluster_0_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster_0_ni_rsp   ),
  .floo_wide_o      ( cluster_0_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cluster_0_ni_req   ),
  .floo_rsp_o       ( cluster_0_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cluster_0_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) cluster_1_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(2) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cluster_1_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster_1_ni_rsp   ),
  .floo_wide_o      ( cluster_1_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cluster_1_ni_req   ),
  .floo_rsp_o       ( cluster_1_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cluster_1_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) dram_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(3) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( dram_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_dram_ni_rsp   ),
  .floo_wide_o      ( dram_ni_to_router_wide  ),
  .floo_req_i       ( router_to_dram_ni_req   ),
  .floo_rsp_o       ( dram_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_dram_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) l2_port0_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(4) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( l2_port0_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_l2_port0_ni_rsp   ),
  .floo_wide_o      ( l2_port0_ni_to_router_wide  ),
  .floo_req_i       ( router_to_l2_port0_ni_req   ),
  .floo_rsp_o       ( l2_port0_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_l2_port0_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) l2_port1_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(5) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( l2_port1_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_l2_port1_ni_rsp   ),
  .floo_wide_o      ( l2_port1_ni_to_router_wide  ),
  .floo_req_i       ( router_to_l2_port1_ni_req   ),
  .floo_rsp_o       ( l2_port1_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_l2_port1_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) cheshire_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(0) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cheshire_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cheshire_ni_rsp   ),
  .floo_wide_o      ( cheshire_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cheshire_ni_req   ),
  .floo_rsp_o       ( cheshire_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cheshire_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) opentitan_main_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(8) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( opentitan_main_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_opentitan_main_ni_rsp   ),
  .floo_wide_o      ( opentitan_main_ni_to_router_wide  ),
  .floo_req_i       ( router_to_opentitan_main_ni_req   ),
  .floo_rsp_o       ( opentitan_main_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_opentitan_main_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) opentitan_dma_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(7) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( opentitan_dma_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_opentitan_dma_ni_rsp   ),
  .floo_wide_o      ( opentitan_dma_ni_to_router_wide  ),
  .floo_req_i       ( router_to_opentitan_dma_ni_req   ),
  .floo_rsp_o       ( opentitan_dma_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_opentitan_dma_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) peripherals_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(9) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( peripherals_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_peripherals_ni_rsp   ),
  .floo_wide_o      ( peripherals_ni_to_router_wide  ),
  .floo_req_i       ( router_to_peripherals_ni_req   ),
  .floo_rsp_o       ( peripherals_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_peripherals_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .SamNumRules(8),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .EnNarrowSbrPort(1'b0),
  .EnNarrowMgrPort(1'b0),
  .EnWideSbrPort(1'b0),
  .EnWideMgrPort(1'b0)
) mbox_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
  .id_i             ( id_t'(6) ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( mbox_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_mbox_ni_rsp   ),
  .floo_wide_o      ( mbox_ni_to_router_wide  ),
  .floo_req_i       ( router_to_mbox_ni_req   ),
  .floo_rsp_o       ( mbox_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_mbox_ni_wide  )
);

localparam int unsigned RouterMapNumRules = 8;

typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
} router_map_rule_t;

localparam router_map_rule_t[RouterMapNumRules-1:0] RouterMap = '{
'{idx: 0, start_addr: 1, end_addr: 2},// cluster_0_ni
'{idx: 1, start_addr: 2, end_addr: 3},// cluster_1_ni
'{idx: 2, start_addr: 3, end_addr: 4},// dram_ni
'{idx: 3, start_addr: 4, end_addr: 5},// l2_port0_ni
'{idx: 4, start_addr: 5, end_addr: 6},// l2_port1_ni
'{idx: 5, start_addr: 0, end_addr: 1},// cheshire_ni
'{idx: 8, start_addr: 9, end_addr: 10},// peripherals_ni
'{idx: 9, start_addr: 6, end_addr: 7} // mbox_ni

};


floo_req_t [9:0] router_req_in;
floo_rsp_t [9:0] router_rsp_out;
floo_req_t [9:0] router_req_out;
floo_rsp_t [9:0] router_rsp_in;
floo_wide_t [9:0] router_wide_in;
floo_wide_t [9:0] router_wide_out;

    assign router_req_in[0] = cluster_0_ni_to_router_req;
    assign router_req_in[1] = cluster_1_ni_to_router_req;
    assign router_req_in[2] = dram_ni_to_router_req;
    assign router_req_in[3] = l2_port0_ni_to_router_req;
    assign router_req_in[4] = l2_port1_ni_to_router_req;
    assign router_req_in[5] = cheshire_ni_to_router_req;
    assign router_req_in[6] = opentitan_main_ni_to_router_req;
    assign router_req_in[7] = opentitan_dma_ni_to_router_req;
    assign router_req_in[8] = peripherals_ni_to_router_req;
    assign router_req_in[9] = mbox_ni_to_router_req;

    assign router_to_cluster_0_ni_rsp = router_rsp_out[0];
    assign router_to_cluster_1_ni_rsp = router_rsp_out[1];
    assign router_to_dram_ni_rsp = router_rsp_out[2];
    assign router_to_l2_port0_ni_rsp = router_rsp_out[3];
    assign router_to_l2_port1_ni_rsp = router_rsp_out[4];
    assign router_to_cheshire_ni_rsp = router_rsp_out[5];
    assign router_to_opentitan_main_ni_rsp = router_rsp_out[6];
    assign router_to_opentitan_dma_ni_rsp = router_rsp_out[7];
    assign router_to_peripherals_ni_rsp = router_rsp_out[8];
    assign router_to_mbox_ni_rsp = router_rsp_out[9];

    assign router_to_cluster_0_ni_req = router_req_out[0];
    assign router_to_cluster_1_ni_req = router_req_out[1];
    assign router_to_dram_ni_req = router_req_out[2];
    assign router_to_l2_port0_ni_req = router_req_out[3];
    assign router_to_l2_port1_ni_req = router_req_out[4];
    assign router_to_cheshire_ni_req = router_req_out[5];
    assign router_to_opentitan_main_ni_req = router_req_out[6];
    assign router_to_opentitan_dma_ni_req = router_req_out[7];
    assign router_to_peripherals_ni_req = router_req_out[8];
    assign router_to_mbox_ni_req = router_req_out[9];

    assign router_rsp_in[0] = cluster_0_ni_to_router_rsp;
    assign router_rsp_in[1] = cluster_1_ni_to_router_rsp;
    assign router_rsp_in[2] = dram_ni_to_router_rsp;
    assign router_rsp_in[3] = l2_port0_ni_to_router_rsp;
    assign router_rsp_in[4] = l2_port1_ni_to_router_rsp;
    assign router_rsp_in[5] = cheshire_ni_to_router_rsp;
    assign router_rsp_in[6] = opentitan_main_ni_to_router_rsp;
    assign router_rsp_in[7] = opentitan_dma_ni_to_router_rsp;
    assign router_rsp_in[8] = peripherals_ni_to_router_rsp;
    assign router_rsp_in[9] = mbox_ni_to_router_rsp;

    assign router_wide_in[0] = cluster_0_ni_to_router_wide;
    assign router_wide_in[1] = cluster_1_ni_to_router_wide;
    assign router_wide_in[2] = dram_ni_to_router_wide;
    assign router_wide_in[3] = l2_port0_ni_to_router_wide;
    assign router_wide_in[4] = l2_port1_ni_to_router_wide;
    assign router_wide_in[5] = cheshire_ni_to_router_wide;
    assign router_wide_in[6] = opentitan_main_ni_to_router_wide;
    assign router_wide_in[7] = opentitan_dma_ni_to_router_wide;
    assign router_wide_in[8] = peripherals_ni_to_router_wide;
    assign router_wide_in[9] = mbox_ni_to_router_wide;

    assign router_to_cluster_0_ni_wide = router_wide_out[0];
    assign router_to_cluster_1_ni_wide = router_wide_out[1];
    assign router_to_dram_ni_wide = router_wide_out[2];
    assign router_to_l2_port0_ni_wide = router_wide_out[3];
    assign router_to_l2_port1_ni_wide = router_wide_out[4];
    assign router_to_cheshire_ni_wide = router_wide_out[5];
    assign router_to_opentitan_main_ni_wide = router_wide_out[6];
    assign router_to_opentitan_dma_ni_wide = router_wide_out[7];
    assign router_to_peripherals_ni_wide = router_wide_out[8];
    assign router_to_mbox_ni_wide = router_wide_out[9];

floo_narrow_wide_router #(
  .NumRoutes (10),
  .NumInputs (10),
  .NumOutputs (10),
  .ChannelFifoDepth (2),
  .OutputFifoDepth (2),
  .id_t(id_t),
  .NumAddrRules (8),
  .addr_rule_t (router_map_rule_t),
  .RouteAlgo (IdTable)
) router (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i ('0),
  .id_route_map_i (RouterMap),
  .floo_req_i (router_req_in),
  .floo_rsp_o (router_rsp_out),
  .floo_req_o (router_req_out),
  .floo_rsp_i (router_rsp_in),
  .floo_wide_i (router_wide_in),
  .floo_wide_o (router_wide_out)
);



endmodule
