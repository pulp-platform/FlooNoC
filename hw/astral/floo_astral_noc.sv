// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_astral_noc_pkg;

  import floo_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

  typedef enum logic[3:0] {
    CheshireNi = 0,
    ClusterNi = 1,
    DramNi = 2,
    EthernetNi = 3,
    L2Port0Ni = 4,
    L2Port1Ni = 5,
    MboxNi = 6,
    OpentitanDmaNi = 7,
    OpentitanMainNi = 8,
    PeripheralsNi = 9,
    NumEndpoints = 10} ep_id_e;



  typedef logic[0:0] rob_idx_t;
typedef logic[0:0] port_id_t;
typedef logic[3:0] id_t;
typedef logic[3:0] route_t;


  localparam int unsigned SamNumRules = 7;

typedef struct packed {
    id_t idx;
    logic [47:0] start_addr;
    logic [47:0] end_addr;
} sam_rule_t;

localparam sam_rule_t[SamNumRules-1:0] Sam = '{
'{idx: 2, start_addr: 48'h000080000000, end_addr: 48'h000100000000},// dram_ni
'{idx: 9, start_addr: 48'h000021000000, end_addr: 48'h000040000000},// peripherals_ni
'{idx: 6, start_addr: 48'h000040000000, end_addr: 48'h000040003000},// mbox_ni
'{idx: 1, start_addr: 48'h000050000000, end_addr: 48'h000050800000},// cluster_ni
'{idx: 5, start_addr: 48'h000078200000, end_addr: 48'h000078220000},// l2_port1_ni
'{idx: 4, start_addr: 48'h000078000000, end_addr: 48'h000078020000},// l2_port0_ni
'{idx: 0, start_addr: 48'h000000000000, end_addr: 48'h000020000000} // cheshire_ni

};


  localparam route_t[NumEndpoints-1:0][NumEndpoints-1:0] RoutingTables = '{
'{
4'b????,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b????,// -> mbox_ni
4'b????,// -> l2_port1_ni
4'b????,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b1000,// -> peripherals_ni
4'b????,// -> opentitan_main_ni
4'b????,// -> opentitan_dma_ni
4'b0111,// -> mbox_ni
4'b0100,// -> l2_port1_ni
4'b0011,// -> l2_port0_ni
4'b????,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b1000,// -> peripherals_ni
4'b????,// -> opentitan_main_ni
4'b????,// -> opentitan_dma_ni
4'b0111,// -> mbox_ni
4'b0100,// -> l2_port1_ni
4'b0011,// -> l2_port0_ni
4'b????,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b????,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b????,// -> mbox_ni
4'b????,// -> l2_port1_ni
4'b????,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b????,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b????,// -> mbox_ni
4'b????,// -> l2_port1_ni
4'b????,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b????,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b????,// -> mbox_ni
4'b????,// -> l2_port1_ni
4'b????,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b1000,// -> peripherals_ni
4'b????,// -> opentitan_main_ni
4'b????,// -> opentitan_dma_ni
4'b0111,// -> mbox_ni
4'b0100,// -> l2_port1_ni
4'b0011,// -> l2_port0_ni
4'b????,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b1000,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b0111,// -> mbox_ni
4'b0100,// -> l2_port1_ni
4'b0011,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b????,// -> dram_ni
4'b0101,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b1000,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b0111,// -> mbox_ni
4'b0100,// -> l2_port1_ni
4'b0011,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b????,// -> cluster_ni
4'b0000 // -> cheshire_ni
},
'{
4'b1000,// -> peripherals_ni
4'b0001,// -> opentitan_main_ni
4'b0010,// -> opentitan_dma_ni
4'b0111,// -> mbox_ni
4'b0100,// -> l2_port1_ni
4'b0011,// -> l2_port0_ni
4'b0110,// -> ethernet_ni
4'b1001,// -> dram_ni
4'b0101,// -> cluster_ni
4'b???? // -> cheshire_ni
}}
;


  localparam route_cfg_t RouteCfg = '{    RouteAlgo: SourceRouting,
    UseIdTable: 1'b1,
    XYAddrOffsetX: 0,
    XYAddrOffsetY: 0,
    IdAddrOffset: 0,
    NumSamRules: 7,
    NumRoutes: 10};


  typedef logic[47:0] in_axi_in_addr_t;
typedef logic[63:0] in_axi_in_data_t;
typedef logic[7:0] in_axi_in_strb_t;
typedef logic[5:0] in_axi_in_id_t;
typedef logic[9:0] in_axi_in_user_t;
`AXI_TYPEDEF_ALL_CT(in_axi_in,             in_axi_in_req_t,             in_axi_in_rsp_t,             in_axi_in_addr_t,             in_axi_in_id_t,             in_axi_in_data_t,             in_axi_in_strb_t,             in_axi_in_user_t)


  typedef logic[47:0] out_axi_out_addr_t;
typedef logic[63:0] out_axi_out_data_t;
typedef logic[7:0] out_axi_out_strb_t;
typedef logic[2:0] out_axi_out_id_t;
typedef logic[9:0] out_axi_out_user_t;
`AXI_TYPEDEF_ALL_CT(out_axi_out,             out_axi_out_req_t,             out_axi_out_rsp_t,             out_axi_out_addr_t,             out_axi_out_id_t,             out_axi_out_data_t,             out_axi_out_strb_t,             out_axi_out_user_t)



  `FLOO_TYPEDEF_HDR_T(hdr_t, route_t, id_t, axi_ch_e, rob_idx_t)
  localparam axi_cfg_t AxiCfg = '{    AddrWidth: 48,
    DataWidth: 64,
    UserWidth: 10,
    InIdWidth: 6,
    OutIdWidth: 3};
`FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, in_axi_in, AxiCfg, hdr_t)

`FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)


endpackage

module floo_astral_noc
  import floo_pkg::*;
  import floo_astral_noc_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  input in_axi_in_req_t              cheshire_axi_in_req_i,
  output in_axi_in_rsp_t              cheshire_axi_in_rsp_o,
  output out_axi_out_req_t              cheshire_axi_out_req_o,
  input out_axi_out_rsp_t              cheshire_axi_out_rsp_i,
  input in_axi_in_req_t              opentitan_main_axi_in_req_i,
  output in_axi_in_rsp_t              opentitan_main_axi_in_rsp_o,
  input in_axi_in_req_t              opentitan_dma_axi_in_req_i,
  output in_axi_in_rsp_t              opentitan_dma_axi_in_rsp_o,
  output out_axi_out_req_t              l2_port0_axi_out_req_o,
  input out_axi_out_rsp_t              l2_port0_axi_out_rsp_i,
  output out_axi_out_req_t              l2_port1_axi_out_req_o,
  input out_axi_out_rsp_t              l2_port1_axi_out_rsp_i,
  input in_axi_in_req_t              cluster_axi_in_req_i,
  output in_axi_in_rsp_t              cluster_axi_in_rsp_o,
  output out_axi_out_req_t              cluster_axi_out_req_o,
  input out_axi_out_rsp_t              cluster_axi_out_rsp_i,
  input in_axi_in_req_t              ethernet_axi_in_req_i,
  output in_axi_in_rsp_t              ethernet_axi_in_rsp_o,
  output out_axi_out_req_t              mbox_axi_out_req_o,
  input out_axi_out_rsp_t              mbox_axi_out_rsp_i,
  output out_axi_out_req_t              peripherals_axi_out_req_o,
  input out_axi_out_rsp_t              peripherals_axi_out_rsp_i,
  input in_axi_in_req_t              dram_axi_in_req_i,
  output in_axi_in_rsp_t              dram_axi_in_rsp_o,
  output out_axi_out_req_t              dram_axi_out_req_o,
  input out_axi_out_rsp_t              dram_axi_out_rsp_i

);

floo_req_t router_to_cheshire_ni_req;
floo_rsp_t cheshire_ni_to_router_rsp;

floo_req_t router_to_opentitan_main_ni_req;
floo_rsp_t opentitan_main_ni_to_router_rsp;

floo_req_t router_to_opentitan_dma_ni_req;
floo_rsp_t opentitan_dma_ni_to_router_rsp;

floo_req_t router_to_l2_port0_ni_req;
floo_rsp_t l2_port0_ni_to_router_rsp;

floo_req_t router_to_l2_port1_ni_req;
floo_rsp_t l2_port1_ni_to_router_rsp;

floo_req_t router_to_cluster_ni_req;
floo_rsp_t cluster_ni_to_router_rsp;

floo_req_t router_to_ethernet_ni_req;
floo_rsp_t ethernet_ni_to_router_rsp;

floo_req_t router_to_mbox_ni_req;
floo_rsp_t mbox_ni_to_router_rsp;

floo_req_t router_to_peripherals_ni_req;
floo_rsp_t peripherals_ni_to_router_rsp;

floo_req_t router_to_dram_ni_req;
floo_rsp_t dram_ni_to_router_rsp;

floo_req_t cheshire_ni_to_router_req;
floo_rsp_t router_to_cheshire_ni_rsp;

floo_req_t opentitan_main_ni_to_router_req;
floo_rsp_t router_to_opentitan_main_ni_rsp;

floo_req_t opentitan_dma_ni_to_router_req;
floo_rsp_t router_to_opentitan_dma_ni_rsp;

floo_req_t l2_port0_ni_to_router_req;
floo_rsp_t router_to_l2_port0_ni_rsp;

floo_req_t l2_port1_ni_to_router_req;
floo_rsp_t router_to_l2_port1_ni_rsp;

floo_req_t cluster_ni_to_router_req;
floo_rsp_t router_to_cluster_ni_rsp;

floo_req_t ethernet_ni_to_router_req;
floo_rsp_t router_to_ethernet_ni_rsp;

floo_req_t mbox_ni_to_router_req;
floo_rsp_t router_to_mbox_ni_rsp;

floo_req_t peripherals_ni_to_router_req;
floo_rsp_t router_to_peripherals_ni_rsp;

floo_req_t dram_ni_to_router_req;
floo_rsp_t router_to_dram_ni_rsp;



floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) cheshire_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( cheshire_axi_in_req_i ),
  .axi_in_rsp_o  ( cheshire_axi_in_rsp_o ),
  .axi_out_req_o ( cheshire_axi_out_req_o ),
  .axi_out_rsp_i ( cheshire_axi_out_rsp_i ),
  .id_i             ( id_t'(0) ),
  .route_table_i    ( RoutingTables[CheshireNi]  ),
  .floo_req_o       ( cheshire_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cheshire_ni_rsp   ),
  .floo_req_i       ( router_to_cheshire_ni_req   ),
  .floo_rsp_o       ( cheshire_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) opentitan_main_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( opentitan_main_axi_in_req_i ),
  .axi_in_rsp_o  ( opentitan_main_axi_in_rsp_o ),
  .axi_out_req_o (    ),
  .axi_out_rsp_i ( '0 ),
  .id_i             ( id_t'(8) ),
  .route_table_i    ( RoutingTables[OpentitanMainNi]  ),
  .floo_req_o       ( opentitan_main_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_opentitan_main_ni_rsp   ),
  .floo_req_i       ( router_to_opentitan_main_ni_req   ),
  .floo_rsp_o       ( opentitan_main_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) opentitan_dma_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( opentitan_dma_axi_in_req_i ),
  .axi_in_rsp_o  ( opentitan_dma_axi_in_rsp_o ),
  .axi_out_req_o (    ),
  .axi_out_rsp_i ( '0 ),
  .id_i             ( id_t'(7) ),
  .route_table_i    ( RoutingTables[OpentitanDmaNi]  ),
  .floo_req_o       ( opentitan_dma_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_opentitan_dma_ni_rsp   ),
  .floo_req_i       ( router_to_opentitan_dma_ni_req   ),
  .floo_rsp_o       ( opentitan_dma_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) l2_port0_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
  .axi_out_req_o ( l2_port0_axi_out_req_o ),
  .axi_out_rsp_i ( l2_port0_axi_out_rsp_i ),
  .id_i             ( id_t'(4) ),
  .route_table_i    ( RoutingTables[L2Port0Ni]  ),
  .floo_req_o       ( l2_port0_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_l2_port0_ni_rsp   ),
  .floo_req_i       ( router_to_l2_port0_ni_req   ),
  .floo_rsp_o       ( l2_port0_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) l2_port1_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
  .axi_out_req_o ( l2_port1_axi_out_req_o ),
  .axi_out_rsp_i ( l2_port1_axi_out_rsp_i ),
  .id_i             ( id_t'(5) ),
  .route_table_i    ( RoutingTables[L2Port1Ni]  ),
  .floo_req_o       ( l2_port1_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_l2_port1_ni_rsp   ),
  .floo_req_i       ( router_to_l2_port1_ni_req   ),
  .floo_rsp_o       ( l2_port1_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) cluster_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( cluster_axi_in_req_i ),
  .axi_in_rsp_o  ( cluster_axi_in_rsp_o ),
  .axi_out_req_o ( cluster_axi_out_req_o ),
  .axi_out_rsp_i ( cluster_axi_out_rsp_i ),
  .id_i             ( id_t'(1) ),
  .route_table_i    ( RoutingTables[ClusterNi]  ),
  .floo_req_o       ( cluster_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster_ni_rsp   ),
  .floo_req_i       ( router_to_cluster_ni_req   ),
  .floo_rsp_o       ( cluster_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) ethernet_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( ethernet_axi_in_req_i ),
  .axi_in_rsp_o  ( ethernet_axi_in_rsp_o ),
  .axi_out_req_o (    ),
  .axi_out_rsp_i ( '0 ),
  .id_i             ( id_t'(3) ),
  .route_table_i    ( RoutingTables[EthernetNi]  ),
  .floo_req_o       ( ethernet_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_ethernet_ni_rsp   ),
  .floo_req_i       ( router_to_ethernet_ni_req   ),
  .floo_rsp_o       ( ethernet_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) mbox_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
  .axi_out_req_o ( mbox_axi_out_req_o ),
  .axi_out_rsp_i ( mbox_axi_out_rsp_i ),
  .id_i             ( id_t'(6) ),
  .route_table_i    ( RoutingTables[MboxNi]  ),
  .floo_req_o       ( mbox_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_mbox_ni_rsp   ),
  .floo_req_i       ( router_to_mbox_ni_req   ),
  .floo_rsp_o       ( mbox_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) peripherals_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
  .axi_out_req_o ( peripherals_axi_out_req_o ),
  .axi_out_rsp_i ( peripherals_axi_out_rsp_i ),
  .id_i             ( id_t'(9) ),
  .route_table_i    ( RoutingTables[PeripheralsNi]  ),
  .floo_req_o       ( peripherals_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_peripherals_ni_rsp   ),
  .floo_req_i       ( router_to_peripherals_ni_req   ),
  .floo_rsp_o       ( peripherals_ni_to_router_rsp   )
);

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .route_t (route_t),
  .dst_t   (route_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(in_axi_in_req_t),
  .axi_in_rsp_t(in_axi_in_rsp_t),
  .axi_out_req_t(out_axi_out_req_t),
  .axi_out_rsp_t(out_axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) dram_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( dram_axi_in_req_i ),
  .axi_in_rsp_o  ( dram_axi_in_rsp_o ),
  .axi_out_req_o ( dram_axi_out_req_o ),
  .axi_out_rsp_i ( dram_axi_out_rsp_i ),
  .id_i             ( id_t'(2) ),
  .route_table_i    ( RoutingTables[DramNi]  ),
  .floo_req_o       ( dram_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_dram_ni_rsp   ),
  .floo_req_i       ( router_to_dram_ni_req   ),
  .floo_rsp_o       ( dram_ni_to_router_rsp   )
);


floo_req_t [9:0] router_req_in;
floo_rsp_t [9:0] router_rsp_out;
floo_req_t [9:0] router_req_out;
floo_rsp_t [9:0] router_rsp_in;

    assign router_req_in[0] = cheshire_ni_to_router_req;
    assign router_req_in[1] = opentitan_main_ni_to_router_req;
    assign router_req_in[2] = opentitan_dma_ni_to_router_req;
    assign router_req_in[3] = l2_port0_ni_to_router_req;
    assign router_req_in[4] = l2_port1_ni_to_router_req;
    assign router_req_in[5] = cluster_ni_to_router_req;
    assign router_req_in[6] = ethernet_ni_to_router_req;
    assign router_req_in[7] = mbox_ni_to_router_req;
    assign router_req_in[8] = peripherals_ni_to_router_req;
    assign router_req_in[9] = dram_ni_to_router_req;

    assign router_to_cheshire_ni_rsp = router_rsp_out[0];
    assign router_to_opentitan_main_ni_rsp = router_rsp_out[1];
    assign router_to_opentitan_dma_ni_rsp = router_rsp_out[2];
    assign router_to_l2_port0_ni_rsp = router_rsp_out[3];
    assign router_to_l2_port1_ni_rsp = router_rsp_out[4];
    assign router_to_cluster_ni_rsp = router_rsp_out[5];
    assign router_to_ethernet_ni_rsp = router_rsp_out[6];
    assign router_to_mbox_ni_rsp = router_rsp_out[7];
    assign router_to_peripherals_ni_rsp = router_rsp_out[8];
    assign router_to_dram_ni_rsp = router_rsp_out[9];

    assign router_to_cheshire_ni_req = router_req_out[0];
    assign router_to_opentitan_main_ni_req = router_req_out[1];
    assign router_to_opentitan_dma_ni_req = router_req_out[2];
    assign router_to_l2_port0_ni_req = router_req_out[3];
    assign router_to_l2_port1_ni_req = router_req_out[4];
    assign router_to_cluster_ni_req = router_req_out[5];
    assign router_to_ethernet_ni_req = router_req_out[6];
    assign router_to_mbox_ni_req = router_req_out[7];
    assign router_to_peripherals_ni_req = router_req_out[8];
    assign router_to_dram_ni_req = router_req_out[9];

    assign router_rsp_in[0] = cheshire_ni_to_router_rsp;
    assign router_rsp_in[1] = opentitan_main_ni_to_router_rsp;
    assign router_rsp_in[2] = opentitan_dma_ni_to_router_rsp;
    assign router_rsp_in[3] = l2_port0_ni_to_router_rsp;
    assign router_rsp_in[4] = l2_port1_ni_to_router_rsp;
    assign router_rsp_in[5] = cluster_ni_to_router_rsp;
    assign router_rsp_in[6] = ethernet_ni_to_router_rsp;
    assign router_rsp_in[7] = mbox_ni_to_router_rsp;
    assign router_rsp_in[8] = peripherals_ni_to_router_rsp;
    assign router_rsp_in[9] = dram_ni_to_router_rsp;

floo_axi_router #(
  .AxiCfg(AxiCfg),
  .RouteAlgo (SourceRouting),
  .NumRoutes (10),
  .NumInputs (10),
  .NumOutputs (10),
  .InFifoDepth (2),
  .OutFifoDepth (2),
  .id_t(id_t),
  .hdr_t(hdr_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) router (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i ('0),
  .id_route_map_i ('0),
  .floo_req_i (router_req_in),
  .floo_rsp_o (router_rsp_out),
  .floo_req_o (router_req_out),
  .floo_rsp_i (router_rsp_in)
);



endmodule
