// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module mcast_mesh_floo_noc
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
(
    input  logic                           clk_i,
    input  logic                           rst_ni,
    input  logic                           test_enable_i,
    input  axi_narrow_in_req_t  [3:0][3:0] cluster_narrow_req_i,
    output axi_narrow_in_rsp_t  [3:0][3:0] cluster_narrow_rsp_o,
    input  axi_wide_in_req_t    [3:0][3:0] cluster_wide_req_i,
    output axi_wide_in_rsp_t    [3:0][3:0] cluster_wide_rsp_o,
    output axi_narrow_out_req_t [3:0][3:0] cluster_narrow_req_o,
    input  axi_narrow_out_rsp_t [3:0][3:0] cluster_narrow_rsp_i,
    output axi_wide_out_req_t   [3:0][3:0] cluster_wide_req_o,
    input  axi_wide_out_rsp_t   [3:0][3:0] cluster_wide_rsp_i

);

  floo_req_t  router_0_0_to_router_0_1_req;
  floo_rsp_t  router_0_1_to_router_0_0_rsp;
  floo_wide_t router_0_0_to_router_0_1_wide;

  floo_req_t  router_0_0_to_router_1_0_req;
  floo_rsp_t  router_1_0_to_router_0_0_rsp;
  floo_wide_t router_0_0_to_router_1_0_wide;

  floo_req_t  router_0_0_to_cluster_ni_0_0_req;
  floo_rsp_t  cluster_ni_0_0_to_router_0_0_rsp;
  floo_wide_t router_0_0_to_cluster_ni_0_0_wide;

  floo_req_t  router_0_1_to_router_0_0_req;
  floo_rsp_t  router_0_0_to_router_0_1_rsp;
  floo_wide_t router_0_1_to_router_0_0_wide;

  floo_req_t  router_0_1_to_router_0_2_req;
  floo_rsp_t  router_0_2_to_router_0_1_rsp;
  floo_wide_t router_0_1_to_router_0_2_wide;

  floo_req_t  router_0_1_to_router_1_1_req;
  floo_rsp_t  router_1_1_to_router_0_1_rsp;
  floo_wide_t router_0_1_to_router_1_1_wide;

  floo_req_t  router_0_1_to_cluster_ni_0_1_req;
  floo_rsp_t  cluster_ni_0_1_to_router_0_1_rsp;
  floo_wide_t router_0_1_to_cluster_ni_0_1_wide;

  floo_req_t  router_0_2_to_router_0_1_req;
  floo_rsp_t  router_0_1_to_router_0_2_rsp;
  floo_wide_t router_0_2_to_router_0_1_wide;

  floo_req_t  router_0_2_to_router_0_3_req;
  floo_rsp_t  router_0_3_to_router_0_2_rsp;
  floo_wide_t router_0_2_to_router_0_3_wide;

  floo_req_t  router_0_2_to_router_1_2_req;
  floo_rsp_t  router_1_2_to_router_0_2_rsp;
  floo_wide_t router_0_2_to_router_1_2_wide;

  floo_req_t  router_0_2_to_cluster_ni_0_2_req;
  floo_rsp_t  cluster_ni_0_2_to_router_0_2_rsp;
  floo_wide_t router_0_2_to_cluster_ni_0_2_wide;

  floo_req_t  router_0_3_to_router_0_2_req;
  floo_rsp_t  router_0_2_to_router_0_3_rsp;
  floo_wide_t router_0_3_to_router_0_2_wide;

  floo_req_t  router_0_3_to_router_1_3_req;
  floo_rsp_t  router_1_3_to_router_0_3_rsp;
  floo_wide_t router_0_3_to_router_1_3_wide;

  floo_req_t  router_0_3_to_cluster_ni_0_3_req;
  floo_rsp_t  cluster_ni_0_3_to_router_0_3_rsp;
  floo_wide_t router_0_3_to_cluster_ni_0_3_wide;

  floo_req_t  router_1_0_to_router_0_0_req;
  floo_rsp_t  router_0_0_to_router_1_0_rsp;
  floo_wide_t router_1_0_to_router_0_0_wide;

  floo_req_t  router_1_0_to_router_1_1_req;
  floo_rsp_t  router_1_1_to_router_1_0_rsp;
  floo_wide_t router_1_0_to_router_1_1_wide;

  floo_req_t  router_1_0_to_router_2_0_req;
  floo_rsp_t  router_2_0_to_router_1_0_rsp;
  floo_wide_t router_1_0_to_router_2_0_wide;

  floo_req_t  router_1_0_to_cluster_ni_1_0_req;
  floo_rsp_t  cluster_ni_1_0_to_router_1_0_rsp;
  floo_wide_t router_1_0_to_cluster_ni_1_0_wide;

  floo_req_t  router_1_1_to_router_0_1_req;
  floo_rsp_t  router_0_1_to_router_1_1_rsp;
  floo_wide_t router_1_1_to_router_0_1_wide;

  floo_req_t  router_1_1_to_router_1_0_req;
  floo_rsp_t  router_1_0_to_router_1_1_rsp;
  floo_wide_t router_1_1_to_router_1_0_wide;

  floo_req_t  router_1_1_to_router_1_2_req;
  floo_rsp_t  router_1_2_to_router_1_1_rsp;
  floo_wide_t router_1_1_to_router_1_2_wide;

  floo_req_t  router_1_1_to_router_2_1_req;
  floo_rsp_t  router_2_1_to_router_1_1_rsp;
  floo_wide_t router_1_1_to_router_2_1_wide;

  floo_req_t  router_1_1_to_cluster_ni_1_1_req;
  floo_rsp_t  cluster_ni_1_1_to_router_1_1_rsp;
  floo_wide_t router_1_1_to_cluster_ni_1_1_wide;

  floo_req_t  router_1_2_to_router_0_2_req;
  floo_rsp_t  router_0_2_to_router_1_2_rsp;
  floo_wide_t router_1_2_to_router_0_2_wide;

  floo_req_t  router_1_2_to_router_1_1_req;
  floo_rsp_t  router_1_1_to_router_1_2_rsp;
  floo_wide_t router_1_2_to_router_1_1_wide;

  floo_req_t  router_1_2_to_router_1_3_req;
  floo_rsp_t  router_1_3_to_router_1_2_rsp;
  floo_wide_t router_1_2_to_router_1_3_wide;

  floo_req_t  router_1_2_to_router_2_2_req;
  floo_rsp_t  router_2_2_to_router_1_2_rsp;
  floo_wide_t router_1_2_to_router_2_2_wide;

  floo_req_t  router_1_2_to_cluster_ni_1_2_req;
  floo_rsp_t  cluster_ni_1_2_to_router_1_2_rsp;
  floo_wide_t router_1_2_to_cluster_ni_1_2_wide;

  floo_req_t  router_1_3_to_router_0_3_req;
  floo_rsp_t  router_0_3_to_router_1_3_rsp;
  floo_wide_t router_1_3_to_router_0_3_wide;

  floo_req_t  router_1_3_to_router_1_2_req;
  floo_rsp_t  router_1_2_to_router_1_3_rsp;
  floo_wide_t router_1_3_to_router_1_2_wide;

  floo_req_t  router_1_3_to_router_2_3_req;
  floo_rsp_t  router_2_3_to_router_1_3_rsp;
  floo_wide_t router_1_3_to_router_2_3_wide;

  floo_req_t  router_1_3_to_cluster_ni_1_3_req;
  floo_rsp_t  cluster_ni_1_3_to_router_1_3_rsp;
  floo_wide_t router_1_3_to_cluster_ni_1_3_wide;

  floo_req_t  router_2_0_to_router_1_0_req;
  floo_rsp_t  router_1_0_to_router_2_0_rsp;
  floo_wide_t router_2_0_to_router_1_0_wide;

  floo_req_t  router_2_0_to_router_2_1_req;
  floo_rsp_t  router_2_1_to_router_2_0_rsp;
  floo_wide_t router_2_0_to_router_2_1_wide;

  floo_req_t  router_2_0_to_router_3_0_req;
  floo_rsp_t  router_3_0_to_router_2_0_rsp;
  floo_wide_t router_2_0_to_router_3_0_wide;

  floo_req_t  router_2_0_to_cluster_ni_2_0_req;
  floo_rsp_t  cluster_ni_2_0_to_router_2_0_rsp;
  floo_wide_t router_2_0_to_cluster_ni_2_0_wide;

  floo_req_t  router_2_1_to_router_1_1_req;
  floo_rsp_t  router_1_1_to_router_2_1_rsp;
  floo_wide_t router_2_1_to_router_1_1_wide;

  floo_req_t  router_2_1_to_router_2_0_req;
  floo_rsp_t  router_2_0_to_router_2_1_rsp;
  floo_wide_t router_2_1_to_router_2_0_wide;

  floo_req_t  router_2_1_to_router_2_2_req;
  floo_rsp_t  router_2_2_to_router_2_1_rsp;
  floo_wide_t router_2_1_to_router_2_2_wide;

  floo_req_t  router_2_1_to_router_3_1_req;
  floo_rsp_t  router_3_1_to_router_2_1_rsp;
  floo_wide_t router_2_1_to_router_3_1_wide;

  floo_req_t  router_2_1_to_cluster_ni_2_1_req;
  floo_rsp_t  cluster_ni_2_1_to_router_2_1_rsp;
  floo_wide_t router_2_1_to_cluster_ni_2_1_wide;

  floo_req_t  router_2_2_to_router_1_2_req;
  floo_rsp_t  router_1_2_to_router_2_2_rsp;
  floo_wide_t router_2_2_to_router_1_2_wide;

  floo_req_t  router_2_2_to_router_2_1_req;
  floo_rsp_t  router_2_1_to_router_2_2_rsp;
  floo_wide_t router_2_2_to_router_2_1_wide;

  floo_req_t  router_2_2_to_router_2_3_req;
  floo_rsp_t  router_2_3_to_router_2_2_rsp;
  floo_wide_t router_2_2_to_router_2_3_wide;

  floo_req_t  router_2_2_to_router_3_2_req;
  floo_rsp_t  router_3_2_to_router_2_2_rsp;
  floo_wide_t router_2_2_to_router_3_2_wide;

  floo_req_t  router_2_2_to_cluster_ni_2_2_req;
  floo_rsp_t  cluster_ni_2_2_to_router_2_2_rsp;
  floo_wide_t router_2_2_to_cluster_ni_2_2_wide;

  floo_req_t  router_2_3_to_router_1_3_req;
  floo_rsp_t  router_1_3_to_router_2_3_rsp;
  floo_wide_t router_2_3_to_router_1_3_wide;

  floo_req_t  router_2_3_to_router_2_2_req;
  floo_rsp_t  router_2_2_to_router_2_3_rsp;
  floo_wide_t router_2_3_to_router_2_2_wide;

  floo_req_t  router_2_3_to_router_3_3_req;
  floo_rsp_t  router_3_3_to_router_2_3_rsp;
  floo_wide_t router_2_3_to_router_3_3_wide;

  floo_req_t  router_2_3_to_cluster_ni_2_3_req;
  floo_rsp_t  cluster_ni_2_3_to_router_2_3_rsp;
  floo_wide_t router_2_3_to_cluster_ni_2_3_wide;

  floo_req_t  router_3_0_to_router_2_0_req;
  floo_rsp_t  router_2_0_to_router_3_0_rsp;
  floo_wide_t router_3_0_to_router_2_0_wide;

  floo_req_t  router_3_0_to_router_3_1_req;
  floo_rsp_t  router_3_1_to_router_3_0_rsp;
  floo_wide_t router_3_0_to_router_3_1_wide;

  floo_req_t  router_3_0_to_cluster_ni_3_0_req;
  floo_rsp_t  cluster_ni_3_0_to_router_3_0_rsp;
  floo_wide_t router_3_0_to_cluster_ni_3_0_wide;

  floo_req_t  router_3_1_to_router_2_1_req;
  floo_rsp_t  router_2_1_to_router_3_1_rsp;
  floo_wide_t router_3_1_to_router_2_1_wide;

  floo_req_t  router_3_1_to_router_3_0_req;
  floo_rsp_t  router_3_0_to_router_3_1_rsp;
  floo_wide_t router_3_1_to_router_3_0_wide;

  floo_req_t  router_3_1_to_router_3_2_req;
  floo_rsp_t  router_3_2_to_router_3_1_rsp;
  floo_wide_t router_3_1_to_router_3_2_wide;

  floo_req_t  router_3_1_to_cluster_ni_3_1_req;
  floo_rsp_t  cluster_ni_3_1_to_router_3_1_rsp;
  floo_wide_t router_3_1_to_cluster_ni_3_1_wide;

  floo_req_t  router_3_2_to_router_2_2_req;
  floo_rsp_t  router_2_2_to_router_3_2_rsp;
  floo_wide_t router_3_2_to_router_2_2_wide;

  floo_req_t  router_3_2_to_router_3_1_req;
  floo_rsp_t  router_3_1_to_router_3_2_rsp;
  floo_wide_t router_3_2_to_router_3_1_wide;

  floo_req_t  router_3_2_to_router_3_3_req;
  floo_rsp_t  router_3_3_to_router_3_2_rsp;
  floo_wide_t router_3_2_to_router_3_3_wide;

  floo_req_t  router_3_2_to_cluster_ni_3_2_req;
  floo_rsp_t  cluster_ni_3_2_to_router_3_2_rsp;
  floo_wide_t router_3_2_to_cluster_ni_3_2_wide;

  floo_req_t  router_3_3_to_router_2_3_req;
  floo_rsp_t  router_2_3_to_router_3_3_rsp;
  floo_wide_t router_3_3_to_router_2_3_wide;

  floo_req_t  router_3_3_to_router_3_2_req;
  floo_rsp_t  router_3_2_to_router_3_3_rsp;
  floo_wide_t router_3_3_to_router_3_2_wide;

  floo_req_t  router_3_3_to_cluster_ni_3_3_req;
  floo_rsp_t  cluster_ni_3_3_to_router_3_3_rsp;
  floo_wide_t router_3_3_to_cluster_ni_3_3_wide;

  floo_req_t  cluster_ni_0_0_to_router_0_0_req;
  floo_rsp_t  router_0_0_to_cluster_ni_0_0_rsp;
  floo_wide_t cluster_ni_0_0_to_router_0_0_wide;

  floo_req_t  cluster_ni_0_1_to_router_0_1_req;
  floo_rsp_t  router_0_1_to_cluster_ni_0_1_rsp;
  floo_wide_t cluster_ni_0_1_to_router_0_1_wide;

  floo_req_t  cluster_ni_0_2_to_router_0_2_req;
  floo_rsp_t  router_0_2_to_cluster_ni_0_2_rsp;
  floo_wide_t cluster_ni_0_2_to_router_0_2_wide;

  floo_req_t  cluster_ni_0_3_to_router_0_3_req;
  floo_rsp_t  router_0_3_to_cluster_ni_0_3_rsp;
  floo_wide_t cluster_ni_0_3_to_router_0_3_wide;

  floo_req_t  cluster_ni_1_0_to_router_1_0_req;
  floo_rsp_t  router_1_0_to_cluster_ni_1_0_rsp;
  floo_wide_t cluster_ni_1_0_to_router_1_0_wide;

  floo_req_t  cluster_ni_1_1_to_router_1_1_req;
  floo_rsp_t  router_1_1_to_cluster_ni_1_1_rsp;
  floo_wide_t cluster_ni_1_1_to_router_1_1_wide;

  floo_req_t  cluster_ni_1_2_to_router_1_2_req;
  floo_rsp_t  router_1_2_to_cluster_ni_1_2_rsp;
  floo_wide_t cluster_ni_1_2_to_router_1_2_wide;

  floo_req_t  cluster_ni_1_3_to_router_1_3_req;
  floo_rsp_t  router_1_3_to_cluster_ni_1_3_rsp;
  floo_wide_t cluster_ni_1_3_to_router_1_3_wide;

  floo_req_t  cluster_ni_2_0_to_router_2_0_req;
  floo_rsp_t  router_2_0_to_cluster_ni_2_0_rsp;
  floo_wide_t cluster_ni_2_0_to_router_2_0_wide;

  floo_req_t  cluster_ni_2_1_to_router_2_1_req;
  floo_rsp_t  router_2_1_to_cluster_ni_2_1_rsp;
  floo_wide_t cluster_ni_2_1_to_router_2_1_wide;

  floo_req_t  cluster_ni_2_2_to_router_2_2_req;
  floo_rsp_t  router_2_2_to_cluster_ni_2_2_rsp;
  floo_wide_t cluster_ni_2_2_to_router_2_2_wide;

  floo_req_t  cluster_ni_2_3_to_router_2_3_req;
  floo_rsp_t  router_2_3_to_cluster_ni_2_3_rsp;
  floo_wide_t cluster_ni_2_3_to_router_2_3_wide;

  floo_req_t  cluster_ni_3_0_to_router_3_0_req;
  floo_rsp_t  router_3_0_to_cluster_ni_3_0_rsp;
  floo_wide_t cluster_ni_3_0_to_router_3_0_wide;

  floo_req_t  cluster_ni_3_1_to_router_3_1_req;
  floo_rsp_t  router_3_1_to_cluster_ni_3_1_rsp;
  floo_wide_t cluster_ni_3_1_to_router_3_1_wide;

  floo_req_t  cluster_ni_3_2_to_router_3_2_req;
  floo_rsp_t  router_3_2_to_cluster_ni_3_2_rsp;
  floo_wide_t cluster_ni_3_2_to_router_3_2_wide;

  floo_req_t  cluster_ni_3_3_to_router_3_3_req;
  floo_rsp_t  router_3_3_to_cluster_ni_3_3_rsp;
  floo_wide_t cluster_ni_3_3_to_router_3_3_wide;




  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b1),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b1)
  ) cluster_ni_0_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[0][0]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[0][0]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[0][0]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[0][0]),
      .axi_wide_in_req_i   (cluster_wide_req_i[0][0]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[0][0]),
      .axi_wide_out_req_o  (cluster_wide_req_o[0][0]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[0][0]),
      .id_i                ('{x: 0, y: 0}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_0_0_to_router_0_0_req),
      .floo_rsp_i          (router_0_0_to_cluster_ni_0_0_rsp),
      .floo_wide_o         (cluster_ni_0_0_to_router_0_0_wide),
      .floo_req_i          (router_0_0_to_cluster_ni_0_0_req),
      .floo_rsp_o          (cluster_ni_0_0_to_router_0_0_rsp),
      .floo_wide_i         (router_0_0_to_cluster_ni_0_0_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_0_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[0][1]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[0][1]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[0][1]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[0][1]),
      .axi_wide_in_req_i   (cluster_wide_req_i[0][1]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[0][1]),
      .axi_wide_out_req_o  (cluster_wide_req_o[0][1]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[0][1]),
      .id_i                ('{x: 0, y: 1}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_0_1_to_router_0_1_req),
      .floo_rsp_i          (router_0_1_to_cluster_ni_0_1_rsp),
      .floo_wide_o         (cluster_ni_0_1_to_router_0_1_wide),
      .floo_req_i          (router_0_1_to_cluster_ni_0_1_req),
      .floo_rsp_o          (cluster_ni_0_1_to_router_0_1_rsp),
      .floo_wide_i         (router_0_1_to_cluster_ni_0_1_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_0_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[0][2]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[0][2]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[0][2]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[0][2]),
      .axi_wide_in_req_i   (cluster_wide_req_i[0][2]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[0][2]),
      .axi_wide_out_req_o  (cluster_wide_req_o[0][2]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[0][2]),
      .id_i                ('{x: 0, y: 2}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_0_2_to_router_0_2_req),
      .floo_rsp_i          (router_0_2_to_cluster_ni_0_2_rsp),
      .floo_wide_o         (cluster_ni_0_2_to_router_0_2_wide),
      .floo_req_i          (router_0_2_to_cluster_ni_0_2_req),
      .floo_rsp_o          (cluster_ni_0_2_to_router_0_2_rsp),
      .floo_wide_i         (router_0_2_to_cluster_ni_0_2_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_0_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[0][3]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[0][3]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[0][3]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[0][3]),
      .axi_wide_in_req_i   (cluster_wide_req_i[0][3]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[0][3]),
      .axi_wide_out_req_o  (cluster_wide_req_o[0][3]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[0][3]),
      .id_i                ('{x: 0, y: 3}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_0_3_to_router_0_3_req),
      .floo_rsp_i          (router_0_3_to_cluster_ni_0_3_rsp),
      .floo_wide_o         (cluster_ni_0_3_to_router_0_3_wide),
      .floo_req_i          (router_0_3_to_cluster_ni_0_3_req),
      .floo_rsp_o          (cluster_ni_0_3_to_router_0_3_rsp),
      .floo_wide_i         (router_0_3_to_cluster_ni_0_3_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_1_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[1][0]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[1][0]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[1][0]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[1][0]),
      .axi_wide_in_req_i   (cluster_wide_req_i[1][0]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[1][0]),
      .axi_wide_out_req_o  (cluster_wide_req_o[1][0]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[1][0]),
      .id_i                ('{x: 1, y: 0}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_1_0_to_router_1_0_req),
      .floo_rsp_i          (router_1_0_to_cluster_ni_1_0_rsp),
      .floo_wide_o         (cluster_ni_1_0_to_router_1_0_wide),
      .floo_req_i          (router_1_0_to_cluster_ni_1_0_req),
      .floo_rsp_o          (cluster_ni_1_0_to_router_1_0_rsp),
      .floo_wide_i         (router_1_0_to_cluster_ni_1_0_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_1_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[1][1]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[1][1]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[1][1]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[1][1]),
      .axi_wide_in_req_i   (cluster_wide_req_i[1][1]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[1][1]),
      .axi_wide_out_req_o  (cluster_wide_req_o[1][1]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[1][1]),
      .id_i                ('{x: 1, y: 1}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_1_1_to_router_1_1_req),
      .floo_rsp_i          (router_1_1_to_cluster_ni_1_1_rsp),
      .floo_wide_o         (cluster_ni_1_1_to_router_1_1_wide),
      .floo_req_i          (router_1_1_to_cluster_ni_1_1_req),
      .floo_rsp_o          (cluster_ni_1_1_to_router_1_1_rsp),
      .floo_wide_i         (router_1_1_to_cluster_ni_1_1_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_1_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[1][2]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[1][2]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[1][2]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[1][2]),
      .axi_wide_in_req_i   (cluster_wide_req_i[1][2]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[1][2]),
      .axi_wide_out_req_o  (cluster_wide_req_o[1][2]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[1][2]),
      .id_i                ('{x: 1, y: 2}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_1_2_to_router_1_2_req),
      .floo_rsp_i          (router_1_2_to_cluster_ni_1_2_rsp),
      .floo_wide_o         (cluster_ni_1_2_to_router_1_2_wide),
      .floo_req_i          (router_1_2_to_cluster_ni_1_2_req),
      .floo_rsp_o          (cluster_ni_1_2_to_router_1_2_rsp),
      .floo_wide_i         (router_1_2_to_cluster_ni_1_2_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_1_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[1][3]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[1][3]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[1][3]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[1][3]),
      .axi_wide_in_req_i   (cluster_wide_req_i[1][3]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[1][3]),
      .axi_wide_out_req_o  (cluster_wide_req_o[1][3]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[1][3]),
      .id_i                ('{x: 1, y: 3}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_1_3_to_router_1_3_req),
      .floo_rsp_i          (router_1_3_to_cluster_ni_1_3_rsp),
      .floo_wide_o         (cluster_ni_1_3_to_router_1_3_wide),
      .floo_req_i          (router_1_3_to_cluster_ni_1_3_req),
      .floo_rsp_o          (cluster_ni_1_3_to_router_1_3_rsp),
      .floo_wide_i         (router_1_3_to_cluster_ni_1_3_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_2_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[2][0]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[2][0]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[2][0]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[2][0]),
      .axi_wide_in_req_i   (cluster_wide_req_i[2][0]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[2][0]),
      .axi_wide_out_req_o  (cluster_wide_req_o[2][0]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[2][0]),
      .id_i                ('{x: 2, y: 0}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_2_0_to_router_2_0_req),
      .floo_rsp_i          (router_2_0_to_cluster_ni_2_0_rsp),
      .floo_wide_o         (cluster_ni_2_0_to_router_2_0_wide),
      .floo_req_i          (router_2_0_to_cluster_ni_2_0_req),
      .floo_rsp_o          (cluster_ni_2_0_to_router_2_0_rsp),
      .floo_wide_i         (router_2_0_to_cluster_ni_2_0_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_2_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[2][1]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[2][1]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[2][1]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[2][1]),
      .axi_wide_in_req_i   (cluster_wide_req_i[2][1]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[2][1]),
      .axi_wide_out_req_o  (cluster_wide_req_o[2][1]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[2][1]),
      .id_i                ('{x: 2, y: 1}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_2_1_to_router_2_1_req),
      .floo_rsp_i          (router_2_1_to_cluster_ni_2_1_rsp),
      .floo_wide_o         (cluster_ni_2_1_to_router_2_1_wide),
      .floo_req_i          (router_2_1_to_cluster_ni_2_1_req),
      .floo_rsp_o          (cluster_ni_2_1_to_router_2_1_rsp),
      .floo_wide_i         (router_2_1_to_cluster_ni_2_1_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_2_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[2][2]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[2][2]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[2][2]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[2][2]),
      .axi_wide_in_req_i   (cluster_wide_req_i[2][2]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[2][2]),
      .axi_wide_out_req_o  (cluster_wide_req_o[2][2]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[2][2]),
      .id_i                ('{x: 2, y: 2}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_2_2_to_router_2_2_req),
      .floo_rsp_i          (router_2_2_to_cluster_ni_2_2_rsp),
      .floo_wide_o         (cluster_ni_2_2_to_router_2_2_wide),
      .floo_req_i          (router_2_2_to_cluster_ni_2_2_req),
      .floo_rsp_o          (cluster_ni_2_2_to_router_2_2_rsp),
      .floo_wide_i         (router_2_2_to_cluster_ni_2_2_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_2_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[2][3]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[2][3]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[2][3]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[2][3]),
      .axi_wide_in_req_i   (cluster_wide_req_i[2][3]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[2][3]),
      .axi_wide_out_req_o  (cluster_wide_req_o[2][3]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[2][3]),
      .id_i                ('{x: 2, y: 3}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_2_3_to_router_2_3_req),
      .floo_rsp_i          (router_2_3_to_cluster_ni_2_3_rsp),
      .floo_wide_o         (cluster_ni_2_3_to_router_2_3_wide),
      .floo_req_i          (router_2_3_to_cluster_ni_2_3_req),
      .floo_rsp_o          (cluster_ni_2_3_to_router_2_3_rsp),
      .floo_wide_i         (router_2_3_to_cluster_ni_2_3_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_3_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[3][0]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[3][0]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[3][0]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[3][0]),
      .axi_wide_in_req_i   (cluster_wide_req_i[3][0]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[3][0]),
      .axi_wide_out_req_o  (cluster_wide_req_o[3][0]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[3][0]),
      .id_i                ('{x: 3, y: 0}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_3_0_to_router_3_0_req),
      .floo_rsp_i          (router_3_0_to_cluster_ni_3_0_rsp),
      .floo_wide_o         (cluster_ni_3_0_to_router_3_0_wide),
      .floo_req_i          (router_3_0_to_cluster_ni_3_0_req),
      .floo_rsp_o          (cluster_ni_3_0_to_router_3_0_rsp),
      .floo_wide_i         (router_3_0_to_cluster_ni_3_0_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_3_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[3][1]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[3][1]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[3][1]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[3][1]),
      .axi_wide_in_req_i   (cluster_wide_req_i[3][1]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[3][1]),
      .axi_wide_out_req_o  (cluster_wide_req_o[3][1]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[3][1]),
      .id_i                ('{x: 3, y: 1}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_3_1_to_router_3_1_req),
      .floo_rsp_i          (router_3_1_to_cluster_ni_3_1_rsp),
      .floo_wide_o         (cluster_ni_3_1_to_router_3_1_wide),
      .floo_req_i          (router_3_1_to_cluster_ni_3_1_req),
      .floo_rsp_o          (cluster_ni_3_1_to_router_3_1_rsp),
      .floo_wide_i         (router_3_1_to_cluster_ni_3_1_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_3_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[3][2]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[3][2]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[3][2]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[3][2]),
      .axi_wide_in_req_i   (cluster_wide_req_i[3][2]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[3][2]),
      .axi_wide_out_req_o  (cluster_wide_req_o[3][2]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[3][2]),
      .id_i                ('{x: 3, y: 2}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_3_2_to_router_3_2_req),
      .floo_rsp_i          (router_3_2_to_cluster_ni_3_2_rsp),
      .floo_wide_o         (cluster_ni_3_2_to_router_3_2_wide),
      .floo_req_i          (router_3_2_to_cluster_ni_3_2_req),
      .floo_rsp_o          (cluster_ni_3_2_to_router_3_2_rsp),
      .floo_wide_i         (router_3_2_to_cluster_ni_3_2_wide)
  );


  floo_narrow_wide_chimney #(
      .EnNarrowSbrPort(1'b1),
      .EnNarrowMgrPort(1'b0),
      .EnWideSbrPort  (1'b1),
      .EnWideMgrPort  (1'b0)
  ) cluster_ni_3_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i          ('0),
      .axi_narrow_in_req_i (cluster_narrow_req_i[3][3]),
      .axi_narrow_in_rsp_o (cluster_narrow_rsp_o[3][3]),
      .axi_narrow_out_req_o(cluster_narrow_req_o[3][3]),
      .axi_narrow_out_rsp_i(cluster_narrow_rsp_i[3][3]),
      .axi_wide_in_req_i   (cluster_wide_req_i[3][3]),
      .axi_wide_in_rsp_o   (cluster_wide_rsp_o[3][3]),
      .axi_wide_out_req_o  (cluster_wide_req_o[3][3]),
      .axi_wide_out_rsp_i  (cluster_wide_rsp_i[3][3]),
      .id_i                ('{x: 3, y: 3}),
      .route_table_i       ('0),
      .floo_req_o          (cluster_ni_3_3_to_router_3_3_req),
      .floo_rsp_i          (router_3_3_to_cluster_ni_3_3_rsp),
      .floo_wide_o         (cluster_ni_3_3_to_router_3_3_wide),
      .floo_req_i          (router_3_3_to_cluster_ni_3_3_req),
      .floo_rsp_o          (cluster_ni_3_3_to_router_3_3_rsp),
      .floo_wide_i         (router_3_3_to_cluster_ni_3_3_wide)
  );


  floo_req_t  [NumDirections-1:0] router_0_0_req_in;
  floo_rsp_t  [NumDirections-1:0] router_0_0_rsp_out;
  floo_req_t  [NumDirections-1:0] router_0_0_req_out;
  floo_rsp_t  [NumDirections-1:0] router_0_0_rsp_in;
  floo_wide_t [NumDirections-1:0] router_0_0_wide_in;
  floo_wide_t [NumDirections-1:0] router_0_0_wide_out;

  assign router_0_0_req_in[Eject] = cluster_ni_0_0_to_router_0_0_req;
  assign router_0_0_req_in[East] = router_1_0_to_router_0_0_req;
  assign router_0_0_req_in[North] = router_0_1_to_router_0_0_req;
  assign router_0_0_req_in[South] = '0;
  assign router_0_0_req_in[West] = '0;

  assign router_0_0_to_cluster_ni_0_0_rsp = router_0_0_rsp_out[Eject];
  assign router_0_0_to_router_1_0_rsp = router_0_0_rsp_out[East];
  assign router_0_0_to_router_0_1_rsp = router_0_0_rsp_out[North];

  assign router_0_0_to_cluster_ni_0_0_req = router_0_0_req_out[Eject];
  assign router_0_0_to_router_1_0_req = router_0_0_req_out[East];
  assign router_0_0_to_router_0_1_req = router_0_0_req_out[North];

  assign router_0_0_rsp_in[Eject] = cluster_ni_0_0_to_router_0_0_rsp;
  assign router_0_0_rsp_in[East] = router_1_0_to_router_0_0_rsp;
  assign router_0_0_rsp_in[North] = router_0_1_to_router_0_0_rsp;
  assign router_0_0_rsp_in[South] = '0;
  assign router_0_0_rsp_in[West] = '0;

  assign router_0_0_wide_in[Eject] = cluster_ni_0_0_to_router_0_0_wide;
  assign router_0_0_wide_in[East] = router_1_0_to_router_0_0_wide;
  assign router_0_0_wide_in[North] = router_0_1_to_router_0_0_wide;
  assign router_0_0_wide_in[South] = '0;
  assign router_0_0_wide_in[West] = '0;

  assign router_0_0_to_cluster_ni_0_0_wide = router_0_0_wide_out[Eject];
  assign router_0_0_to_router_1_0_wide = router_0_0_wide_out[East];
  assign router_0_0_to_router_0_1_wide = router_0_0_wide_out[North];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_0_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 0, y: 0}),
      .id_route_map_i('0),
      .floo_req_i(router_0_0_req_in),
      .floo_rsp_o(router_0_0_rsp_out),
      .floo_req_o(router_0_0_req_out),
      .floo_rsp_i(router_0_0_rsp_in),
      .floo_wide_i(router_0_0_wide_in),
      .floo_wide_o(router_0_0_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_0_1_req_in;
  floo_rsp_t  [NumDirections-1:0] router_0_1_rsp_out;
  floo_req_t  [NumDirections-1:0] router_0_1_req_out;
  floo_rsp_t  [NumDirections-1:0] router_0_1_rsp_in;
  floo_wide_t [NumDirections-1:0] router_0_1_wide_in;
  floo_wide_t [NumDirections-1:0] router_0_1_wide_out;

  assign router_0_1_req_in[Eject] = cluster_ni_0_1_to_router_0_1_req;
  assign router_0_1_req_in[East] = router_1_1_to_router_0_1_req;
  assign router_0_1_req_in[North] = router_0_2_to_router_0_1_req;
  assign router_0_1_req_in[South] = router_0_0_to_router_0_1_req;
  assign router_0_1_req_in[West] = '0;

  assign router_0_1_to_cluster_ni_0_1_rsp = router_0_1_rsp_out[Eject];
  assign router_0_1_to_router_1_1_rsp = router_0_1_rsp_out[East];
  assign router_0_1_to_router_0_2_rsp = router_0_1_rsp_out[North];
  assign router_0_1_to_router_0_0_rsp = router_0_1_rsp_out[South];

  assign router_0_1_to_cluster_ni_0_1_req = router_0_1_req_out[Eject];
  assign router_0_1_to_router_1_1_req = router_0_1_req_out[East];
  assign router_0_1_to_router_0_2_req = router_0_1_req_out[North];
  assign router_0_1_to_router_0_0_req = router_0_1_req_out[South];

  assign router_0_1_rsp_in[Eject] = cluster_ni_0_1_to_router_0_1_rsp;
  assign router_0_1_rsp_in[East] = router_1_1_to_router_0_1_rsp;
  assign router_0_1_rsp_in[North] = router_0_2_to_router_0_1_rsp;
  assign router_0_1_rsp_in[South] = router_0_0_to_router_0_1_rsp;
  assign router_0_1_rsp_in[West] = '0;

  assign router_0_1_wide_in[Eject] = cluster_ni_0_1_to_router_0_1_wide;
  assign router_0_1_wide_in[East] = router_1_1_to_router_0_1_wide;
  assign router_0_1_wide_in[North] = router_0_2_to_router_0_1_wide;
  assign router_0_1_wide_in[South] = router_0_0_to_router_0_1_wide;
  assign router_0_1_wide_in[West] = '0;

  assign router_0_1_to_cluster_ni_0_1_wide = router_0_1_wide_out[Eject];
  assign router_0_1_to_router_1_1_wide = router_0_1_wide_out[East];
  assign router_0_1_to_router_0_2_wide = router_0_1_wide_out[North];
  assign router_0_1_to_router_0_0_wide = router_0_1_wide_out[South];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_0_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 0, y: 1}),
      .id_route_map_i('0),
      .floo_req_i(router_0_1_req_in),
      .floo_rsp_o(router_0_1_rsp_out),
      .floo_req_o(router_0_1_req_out),
      .floo_rsp_i(router_0_1_rsp_in),
      .floo_wide_i(router_0_1_wide_in),
      .floo_wide_o(router_0_1_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_0_2_req_in;
  floo_rsp_t  [NumDirections-1:0] router_0_2_rsp_out;
  floo_req_t  [NumDirections-1:0] router_0_2_req_out;
  floo_rsp_t  [NumDirections-1:0] router_0_2_rsp_in;
  floo_wide_t [NumDirections-1:0] router_0_2_wide_in;
  floo_wide_t [NumDirections-1:0] router_0_2_wide_out;

  assign router_0_2_req_in[Eject] = cluster_ni_0_2_to_router_0_2_req;
  assign router_0_2_req_in[East] = router_1_2_to_router_0_2_req;
  assign router_0_2_req_in[North] = router_0_3_to_router_0_2_req;
  assign router_0_2_req_in[South] = router_0_1_to_router_0_2_req;
  assign router_0_2_req_in[West] = '0;

  assign router_0_2_to_cluster_ni_0_2_rsp = router_0_2_rsp_out[Eject];
  assign router_0_2_to_router_1_2_rsp = router_0_2_rsp_out[East];
  assign router_0_2_to_router_0_3_rsp = router_0_2_rsp_out[North];
  assign router_0_2_to_router_0_1_rsp = router_0_2_rsp_out[South];

  assign router_0_2_to_cluster_ni_0_2_req = router_0_2_req_out[Eject];
  assign router_0_2_to_router_1_2_req = router_0_2_req_out[East];
  assign router_0_2_to_router_0_3_req = router_0_2_req_out[North];
  assign router_0_2_to_router_0_1_req = router_0_2_req_out[South];

  assign router_0_2_rsp_in[Eject] = cluster_ni_0_2_to_router_0_2_rsp;
  assign router_0_2_rsp_in[East] = router_1_2_to_router_0_2_rsp;
  assign router_0_2_rsp_in[North] = router_0_3_to_router_0_2_rsp;
  assign router_0_2_rsp_in[South] = router_0_1_to_router_0_2_rsp;
  assign router_0_2_rsp_in[West] = '0;

  assign router_0_2_wide_in[Eject] = cluster_ni_0_2_to_router_0_2_wide;
  assign router_0_2_wide_in[East] = router_1_2_to_router_0_2_wide;
  assign router_0_2_wide_in[North] = router_0_3_to_router_0_2_wide;
  assign router_0_2_wide_in[South] = router_0_1_to_router_0_2_wide;
  assign router_0_2_wide_in[West] = '0;

  assign router_0_2_to_cluster_ni_0_2_wide = router_0_2_wide_out[Eject];
  assign router_0_2_to_router_1_2_wide = router_0_2_wide_out[East];
  assign router_0_2_to_router_0_3_wide = router_0_2_wide_out[North];
  assign router_0_2_to_router_0_1_wide = router_0_2_wide_out[South];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_0_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 0, y: 2}),
      .id_route_map_i('0),
      .floo_req_i(router_0_2_req_in),
      .floo_rsp_o(router_0_2_rsp_out),
      .floo_req_o(router_0_2_req_out),
      .floo_rsp_i(router_0_2_rsp_in),
      .floo_wide_i(router_0_2_wide_in),
      .floo_wide_o(router_0_2_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_0_3_req_in;
  floo_rsp_t  [NumDirections-1:0] router_0_3_rsp_out;
  floo_req_t  [NumDirections-1:0] router_0_3_req_out;
  floo_rsp_t  [NumDirections-1:0] router_0_3_rsp_in;
  floo_wide_t [NumDirections-1:0] router_0_3_wide_in;
  floo_wide_t [NumDirections-1:0] router_0_3_wide_out;

  assign router_0_3_req_in[Eject] = cluster_ni_0_3_to_router_0_3_req;
  assign router_0_3_req_in[East] = router_1_3_to_router_0_3_req;
  assign router_0_3_req_in[North] = '0;
  assign router_0_3_req_in[South] = router_0_2_to_router_0_3_req;
  assign router_0_3_req_in[West] = '0;

  assign router_0_3_to_cluster_ni_0_3_rsp = router_0_3_rsp_out[Eject];
  assign router_0_3_to_router_1_3_rsp = router_0_3_rsp_out[East];
  assign router_0_3_to_router_0_2_rsp = router_0_3_rsp_out[South];

  assign router_0_3_to_cluster_ni_0_3_req = router_0_3_req_out[Eject];
  assign router_0_3_to_router_1_3_req = router_0_3_req_out[East];
  assign router_0_3_to_router_0_2_req = router_0_3_req_out[South];

  assign router_0_3_rsp_in[Eject] = cluster_ni_0_3_to_router_0_3_rsp;
  assign router_0_3_rsp_in[East] = router_1_3_to_router_0_3_rsp;
  assign router_0_3_rsp_in[North] = '0;
  assign router_0_3_rsp_in[South] = router_0_2_to_router_0_3_rsp;
  assign router_0_3_rsp_in[West] = '0;

  assign router_0_3_wide_in[Eject] = cluster_ni_0_3_to_router_0_3_wide;
  assign router_0_3_wide_in[East] = router_1_3_to_router_0_3_wide;
  assign router_0_3_wide_in[North] = '0;
  assign router_0_3_wide_in[South] = router_0_2_to_router_0_3_wide;
  assign router_0_3_wide_in[West] = '0;

  assign router_0_3_to_cluster_ni_0_3_wide = router_0_3_wide_out[Eject];
  assign router_0_3_to_router_1_3_wide = router_0_3_wide_out[East];
  assign router_0_3_to_router_0_2_wide = router_0_3_wide_out[South];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_0_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 0, y: 3}),
      .id_route_map_i('0),
      .floo_req_i(router_0_3_req_in),
      .floo_rsp_o(router_0_3_rsp_out),
      .floo_req_o(router_0_3_req_out),
      .floo_rsp_i(router_0_3_rsp_in),
      .floo_wide_i(router_0_3_wide_in),
      .floo_wide_o(router_0_3_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_1_0_req_in;
  floo_rsp_t  [NumDirections-1:0] router_1_0_rsp_out;
  floo_req_t  [NumDirections-1:0] router_1_0_req_out;
  floo_rsp_t  [NumDirections-1:0] router_1_0_rsp_in;
  floo_wide_t [NumDirections-1:0] router_1_0_wide_in;
  floo_wide_t [NumDirections-1:0] router_1_0_wide_out;

  assign router_1_0_req_in[Eject] = cluster_ni_1_0_to_router_1_0_req;
  assign router_1_0_req_in[East] = router_2_0_to_router_1_0_req;
  assign router_1_0_req_in[North] = router_1_1_to_router_1_0_req;
  assign router_1_0_req_in[South] = '0;
  assign router_1_0_req_in[West] = router_0_0_to_router_1_0_req;

  assign router_1_0_to_cluster_ni_1_0_rsp = router_1_0_rsp_out[Eject];
  assign router_1_0_to_router_2_0_rsp = router_1_0_rsp_out[East];
  assign router_1_0_to_router_1_1_rsp = router_1_0_rsp_out[North];
  assign router_1_0_to_router_0_0_rsp = router_1_0_rsp_out[West];

  assign router_1_0_to_cluster_ni_1_0_req = router_1_0_req_out[Eject];
  assign router_1_0_to_router_2_0_req = router_1_0_req_out[East];
  assign router_1_0_to_router_1_1_req = router_1_0_req_out[North];
  assign router_1_0_to_router_0_0_req = router_1_0_req_out[West];

  assign router_1_0_rsp_in[Eject] = cluster_ni_1_0_to_router_1_0_rsp;
  assign router_1_0_rsp_in[East] = router_2_0_to_router_1_0_rsp;
  assign router_1_0_rsp_in[North] = router_1_1_to_router_1_0_rsp;
  assign router_1_0_rsp_in[South] = '0;
  assign router_1_0_rsp_in[West] = router_0_0_to_router_1_0_rsp;

  assign router_1_0_wide_in[Eject] = cluster_ni_1_0_to_router_1_0_wide;
  assign router_1_0_wide_in[East] = router_2_0_to_router_1_0_wide;
  assign router_1_0_wide_in[North] = router_1_1_to_router_1_0_wide;
  assign router_1_0_wide_in[South] = '0;
  assign router_1_0_wide_in[West] = router_0_0_to_router_1_0_wide;

  assign router_1_0_to_cluster_ni_1_0_wide = router_1_0_wide_out[Eject];
  assign router_1_0_to_router_2_0_wide = router_1_0_wide_out[East];
  assign router_1_0_to_router_1_1_wide = router_1_0_wide_out[North];
  assign router_1_0_to_router_0_0_wide = router_1_0_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_1_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 1, y: 0}),
      .id_route_map_i('0),
      .floo_req_i(router_1_0_req_in),
      .floo_rsp_o(router_1_0_rsp_out),
      .floo_req_o(router_1_0_req_out),
      .floo_rsp_i(router_1_0_rsp_in),
      .floo_wide_i(router_1_0_wide_in),
      .floo_wide_o(router_1_0_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_1_1_req_in;
  floo_rsp_t  [NumDirections-1:0] router_1_1_rsp_out;
  floo_req_t  [NumDirections-1:0] router_1_1_req_out;
  floo_rsp_t  [NumDirections-1:0] router_1_1_rsp_in;
  floo_wide_t [NumDirections-1:0] router_1_1_wide_in;
  floo_wide_t [NumDirections-1:0] router_1_1_wide_out;

  assign router_1_1_req_in[Eject] = cluster_ni_1_1_to_router_1_1_req;
  assign router_1_1_req_in[East] = router_2_1_to_router_1_1_req;
  assign router_1_1_req_in[North] = router_1_2_to_router_1_1_req;
  assign router_1_1_req_in[South] = router_1_0_to_router_1_1_req;
  assign router_1_1_req_in[West] = router_0_1_to_router_1_1_req;

  assign router_1_1_to_cluster_ni_1_1_rsp = router_1_1_rsp_out[Eject];
  assign router_1_1_to_router_2_1_rsp = router_1_1_rsp_out[East];
  assign router_1_1_to_router_1_2_rsp = router_1_1_rsp_out[North];
  assign router_1_1_to_router_1_0_rsp = router_1_1_rsp_out[South];
  assign router_1_1_to_router_0_1_rsp = router_1_1_rsp_out[West];

  assign router_1_1_to_cluster_ni_1_1_req = router_1_1_req_out[Eject];
  assign router_1_1_to_router_2_1_req = router_1_1_req_out[East];
  assign router_1_1_to_router_1_2_req = router_1_1_req_out[North];
  assign router_1_1_to_router_1_0_req = router_1_1_req_out[South];
  assign router_1_1_to_router_0_1_req = router_1_1_req_out[West];

  assign router_1_1_rsp_in[Eject] = cluster_ni_1_1_to_router_1_1_rsp;
  assign router_1_1_rsp_in[East] = router_2_1_to_router_1_1_rsp;
  assign router_1_1_rsp_in[North] = router_1_2_to_router_1_1_rsp;
  assign router_1_1_rsp_in[South] = router_1_0_to_router_1_1_rsp;
  assign router_1_1_rsp_in[West] = router_0_1_to_router_1_1_rsp;

  assign router_1_1_wide_in[Eject] = cluster_ni_1_1_to_router_1_1_wide;
  assign router_1_1_wide_in[East] = router_2_1_to_router_1_1_wide;
  assign router_1_1_wide_in[North] = router_1_2_to_router_1_1_wide;
  assign router_1_1_wide_in[South] = router_1_0_to_router_1_1_wide;
  assign router_1_1_wide_in[West] = router_0_1_to_router_1_1_wide;

  assign router_1_1_to_cluster_ni_1_1_wide = router_1_1_wide_out[Eject];
  assign router_1_1_to_router_2_1_wide = router_1_1_wide_out[East];
  assign router_1_1_to_router_1_2_wide = router_1_1_wide_out[North];
  assign router_1_1_to_router_1_0_wide = router_1_1_wide_out[South];
  assign router_1_1_to_router_0_1_wide = router_1_1_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_1_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 1, y: 1}),
      .id_route_map_i('0),
      .floo_req_i(router_1_1_req_in),
      .floo_rsp_o(router_1_1_rsp_out),
      .floo_req_o(router_1_1_req_out),
      .floo_rsp_i(router_1_1_rsp_in),
      .floo_wide_i(router_1_1_wide_in),
      .floo_wide_o(router_1_1_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_1_2_req_in;
  floo_rsp_t  [NumDirections-1:0] router_1_2_rsp_out;
  floo_req_t  [NumDirections-1:0] router_1_2_req_out;
  floo_rsp_t  [NumDirections-1:0] router_1_2_rsp_in;
  floo_wide_t [NumDirections-1:0] router_1_2_wide_in;
  floo_wide_t [NumDirections-1:0] router_1_2_wide_out;

  assign router_1_2_req_in[Eject] = cluster_ni_1_2_to_router_1_2_req;
  assign router_1_2_req_in[East] = router_2_2_to_router_1_2_req;
  assign router_1_2_req_in[North] = router_1_3_to_router_1_2_req;
  assign router_1_2_req_in[South] = router_1_1_to_router_1_2_req;
  assign router_1_2_req_in[West] = router_0_2_to_router_1_2_req;

  assign router_1_2_to_cluster_ni_1_2_rsp = router_1_2_rsp_out[Eject];
  assign router_1_2_to_router_2_2_rsp = router_1_2_rsp_out[East];
  assign router_1_2_to_router_1_3_rsp = router_1_2_rsp_out[North];
  assign router_1_2_to_router_1_1_rsp = router_1_2_rsp_out[South];
  assign router_1_2_to_router_0_2_rsp = router_1_2_rsp_out[West];

  assign router_1_2_to_cluster_ni_1_2_req = router_1_2_req_out[Eject];
  assign router_1_2_to_router_2_2_req = router_1_2_req_out[East];
  assign router_1_2_to_router_1_3_req = router_1_2_req_out[North];
  assign router_1_2_to_router_1_1_req = router_1_2_req_out[South];
  assign router_1_2_to_router_0_2_req = router_1_2_req_out[West];

  assign router_1_2_rsp_in[Eject] = cluster_ni_1_2_to_router_1_2_rsp;
  assign router_1_2_rsp_in[East] = router_2_2_to_router_1_2_rsp;
  assign router_1_2_rsp_in[North] = router_1_3_to_router_1_2_rsp;
  assign router_1_2_rsp_in[South] = router_1_1_to_router_1_2_rsp;
  assign router_1_2_rsp_in[West] = router_0_2_to_router_1_2_rsp;

  assign router_1_2_wide_in[Eject] = cluster_ni_1_2_to_router_1_2_wide;
  assign router_1_2_wide_in[East] = router_2_2_to_router_1_2_wide;
  assign router_1_2_wide_in[North] = router_1_3_to_router_1_2_wide;
  assign router_1_2_wide_in[South] = router_1_1_to_router_1_2_wide;
  assign router_1_2_wide_in[West] = router_0_2_to_router_1_2_wide;

  assign router_1_2_to_cluster_ni_1_2_wide = router_1_2_wide_out[Eject];
  assign router_1_2_to_router_2_2_wide = router_1_2_wide_out[East];
  assign router_1_2_to_router_1_3_wide = router_1_2_wide_out[North];
  assign router_1_2_to_router_1_1_wide = router_1_2_wide_out[South];
  assign router_1_2_to_router_0_2_wide = router_1_2_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_1_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 1, y: 2}),
      .id_route_map_i('0),
      .floo_req_i(router_1_2_req_in),
      .floo_rsp_o(router_1_2_rsp_out),
      .floo_req_o(router_1_2_req_out),
      .floo_rsp_i(router_1_2_rsp_in),
      .floo_wide_i(router_1_2_wide_in),
      .floo_wide_o(router_1_2_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_1_3_req_in;
  floo_rsp_t  [NumDirections-1:0] router_1_3_rsp_out;
  floo_req_t  [NumDirections-1:0] router_1_3_req_out;
  floo_rsp_t  [NumDirections-1:0] router_1_3_rsp_in;
  floo_wide_t [NumDirections-1:0] router_1_3_wide_in;
  floo_wide_t [NumDirections-1:0] router_1_3_wide_out;

  assign router_1_3_req_in[Eject] = cluster_ni_1_3_to_router_1_3_req;
  assign router_1_3_req_in[East] = router_2_3_to_router_1_3_req;
  assign router_1_3_req_in[North] = '0;
  assign router_1_3_req_in[South] = router_1_2_to_router_1_3_req;
  assign router_1_3_req_in[West] = router_0_3_to_router_1_3_req;

  assign router_1_3_to_cluster_ni_1_3_rsp = router_1_3_rsp_out[Eject];
  assign router_1_3_to_router_2_3_rsp = router_1_3_rsp_out[East];
  assign router_1_3_to_router_1_2_rsp = router_1_3_rsp_out[South];
  assign router_1_3_to_router_0_3_rsp = router_1_3_rsp_out[West];

  assign router_1_3_to_cluster_ni_1_3_req = router_1_3_req_out[Eject];
  assign router_1_3_to_router_2_3_req = router_1_3_req_out[East];
  assign router_1_3_to_router_1_2_req = router_1_3_req_out[South];
  assign router_1_3_to_router_0_3_req = router_1_3_req_out[West];

  assign router_1_3_rsp_in[Eject] = cluster_ni_1_3_to_router_1_3_rsp;
  assign router_1_3_rsp_in[East] = router_2_3_to_router_1_3_rsp;
  assign router_1_3_rsp_in[North] = '0;
  assign router_1_3_rsp_in[South] = router_1_2_to_router_1_3_rsp;
  assign router_1_3_rsp_in[West] = router_0_3_to_router_1_3_rsp;

  assign router_1_3_wide_in[Eject] = cluster_ni_1_3_to_router_1_3_wide;
  assign router_1_3_wide_in[East] = router_2_3_to_router_1_3_wide;
  assign router_1_3_wide_in[North] = '0;
  assign router_1_3_wide_in[South] = router_1_2_to_router_1_3_wide;
  assign router_1_3_wide_in[West] = router_0_3_to_router_1_3_wide;

  assign router_1_3_to_cluster_ni_1_3_wide = router_1_3_wide_out[Eject];
  assign router_1_3_to_router_2_3_wide = router_1_3_wide_out[East];
  assign router_1_3_to_router_1_2_wide = router_1_3_wide_out[South];
  assign router_1_3_to_router_0_3_wide = router_1_3_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_1_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 1, y: 3}),
      .id_route_map_i('0),
      .floo_req_i(router_1_3_req_in),
      .floo_rsp_o(router_1_3_rsp_out),
      .floo_req_o(router_1_3_req_out),
      .floo_rsp_i(router_1_3_rsp_in),
      .floo_wide_i(router_1_3_wide_in),
      .floo_wide_o(router_1_3_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_2_0_req_in;
  floo_rsp_t  [NumDirections-1:0] router_2_0_rsp_out;
  floo_req_t  [NumDirections-1:0] router_2_0_req_out;
  floo_rsp_t  [NumDirections-1:0] router_2_0_rsp_in;
  floo_wide_t [NumDirections-1:0] router_2_0_wide_in;
  floo_wide_t [NumDirections-1:0] router_2_0_wide_out;

  assign router_2_0_req_in[Eject] = cluster_ni_2_0_to_router_2_0_req;
  assign router_2_0_req_in[East] = router_3_0_to_router_2_0_req;
  assign router_2_0_req_in[North] = router_2_1_to_router_2_0_req;
  assign router_2_0_req_in[South] = '0;
  assign router_2_0_req_in[West] = router_1_0_to_router_2_0_req;

  assign router_2_0_to_cluster_ni_2_0_rsp = router_2_0_rsp_out[Eject];
  assign router_2_0_to_router_3_0_rsp = router_2_0_rsp_out[East];
  assign router_2_0_to_router_2_1_rsp = router_2_0_rsp_out[North];
  assign router_2_0_to_router_1_0_rsp = router_2_0_rsp_out[West];

  assign router_2_0_to_cluster_ni_2_0_req = router_2_0_req_out[Eject];
  assign router_2_0_to_router_3_0_req = router_2_0_req_out[East];
  assign router_2_0_to_router_2_1_req = router_2_0_req_out[North];
  assign router_2_0_to_router_1_0_req = router_2_0_req_out[West];

  assign router_2_0_rsp_in[Eject] = cluster_ni_2_0_to_router_2_0_rsp;
  assign router_2_0_rsp_in[East] = router_3_0_to_router_2_0_rsp;
  assign router_2_0_rsp_in[North] = router_2_1_to_router_2_0_rsp;
  assign router_2_0_rsp_in[South] = '0;
  assign router_2_0_rsp_in[West] = router_1_0_to_router_2_0_rsp;

  assign router_2_0_wide_in[Eject] = cluster_ni_2_0_to_router_2_0_wide;
  assign router_2_0_wide_in[East] = router_3_0_to_router_2_0_wide;
  assign router_2_0_wide_in[North] = router_2_1_to_router_2_0_wide;
  assign router_2_0_wide_in[South] = '0;
  assign router_2_0_wide_in[West] = router_1_0_to_router_2_0_wide;

  assign router_2_0_to_cluster_ni_2_0_wide = router_2_0_wide_out[Eject];
  assign router_2_0_to_router_3_0_wide = router_2_0_wide_out[East];
  assign router_2_0_to_router_2_1_wide = router_2_0_wide_out[North];
  assign router_2_0_to_router_1_0_wide = router_2_0_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_2_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 2, y: 0}),
      .id_route_map_i('0),
      .floo_req_i(router_2_0_req_in),
      .floo_rsp_o(router_2_0_rsp_out),
      .floo_req_o(router_2_0_req_out),
      .floo_rsp_i(router_2_0_rsp_in),
      .floo_wide_i(router_2_0_wide_in),
      .floo_wide_o(router_2_0_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_2_1_req_in;
  floo_rsp_t  [NumDirections-1:0] router_2_1_rsp_out;
  floo_req_t  [NumDirections-1:0] router_2_1_req_out;
  floo_rsp_t  [NumDirections-1:0] router_2_1_rsp_in;
  floo_wide_t [NumDirections-1:0] router_2_1_wide_in;
  floo_wide_t [NumDirections-1:0] router_2_1_wide_out;

  assign router_2_1_req_in[Eject] = cluster_ni_2_1_to_router_2_1_req;
  assign router_2_1_req_in[East] = router_3_1_to_router_2_1_req;
  assign router_2_1_req_in[North] = router_2_2_to_router_2_1_req;
  assign router_2_1_req_in[South] = router_2_0_to_router_2_1_req;
  assign router_2_1_req_in[West] = router_1_1_to_router_2_1_req;

  assign router_2_1_to_cluster_ni_2_1_rsp = router_2_1_rsp_out[Eject];
  assign router_2_1_to_router_3_1_rsp = router_2_1_rsp_out[East];
  assign router_2_1_to_router_2_2_rsp = router_2_1_rsp_out[North];
  assign router_2_1_to_router_2_0_rsp = router_2_1_rsp_out[South];
  assign router_2_1_to_router_1_1_rsp = router_2_1_rsp_out[West];

  assign router_2_1_to_cluster_ni_2_1_req = router_2_1_req_out[Eject];
  assign router_2_1_to_router_3_1_req = router_2_1_req_out[East];
  assign router_2_1_to_router_2_2_req = router_2_1_req_out[North];
  assign router_2_1_to_router_2_0_req = router_2_1_req_out[South];
  assign router_2_1_to_router_1_1_req = router_2_1_req_out[West];

  assign router_2_1_rsp_in[Eject] = cluster_ni_2_1_to_router_2_1_rsp;
  assign router_2_1_rsp_in[East] = router_3_1_to_router_2_1_rsp;
  assign router_2_1_rsp_in[North] = router_2_2_to_router_2_1_rsp;
  assign router_2_1_rsp_in[South] = router_2_0_to_router_2_1_rsp;
  assign router_2_1_rsp_in[West] = router_1_1_to_router_2_1_rsp;

  assign router_2_1_wide_in[Eject] = cluster_ni_2_1_to_router_2_1_wide;
  assign router_2_1_wide_in[East] = router_3_1_to_router_2_1_wide;
  assign router_2_1_wide_in[North] = router_2_2_to_router_2_1_wide;
  assign router_2_1_wide_in[South] = router_2_0_to_router_2_1_wide;
  assign router_2_1_wide_in[West] = router_1_1_to_router_2_1_wide;

  assign router_2_1_to_cluster_ni_2_1_wide = router_2_1_wide_out[Eject];
  assign router_2_1_to_router_3_1_wide = router_2_1_wide_out[East];
  assign router_2_1_to_router_2_2_wide = router_2_1_wide_out[North];
  assign router_2_1_to_router_2_0_wide = router_2_1_wide_out[South];
  assign router_2_1_to_router_1_1_wide = router_2_1_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_2_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 2, y: 1}),
      .id_route_map_i('0),
      .floo_req_i(router_2_1_req_in),
      .floo_rsp_o(router_2_1_rsp_out),
      .floo_req_o(router_2_1_req_out),
      .floo_rsp_i(router_2_1_rsp_in),
      .floo_wide_i(router_2_1_wide_in),
      .floo_wide_o(router_2_1_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_2_2_req_in;
  floo_rsp_t  [NumDirections-1:0] router_2_2_rsp_out;
  floo_req_t  [NumDirections-1:0] router_2_2_req_out;
  floo_rsp_t  [NumDirections-1:0] router_2_2_rsp_in;
  floo_wide_t [NumDirections-1:0] router_2_2_wide_in;
  floo_wide_t [NumDirections-1:0] router_2_2_wide_out;

  assign router_2_2_req_in[Eject] = cluster_ni_2_2_to_router_2_2_req;
  assign router_2_2_req_in[East] = router_3_2_to_router_2_2_req;
  assign router_2_2_req_in[North] = router_2_3_to_router_2_2_req;
  assign router_2_2_req_in[South] = router_2_1_to_router_2_2_req;
  assign router_2_2_req_in[West] = router_1_2_to_router_2_2_req;

  assign router_2_2_to_cluster_ni_2_2_rsp = router_2_2_rsp_out[Eject];
  assign router_2_2_to_router_3_2_rsp = router_2_2_rsp_out[East];
  assign router_2_2_to_router_2_3_rsp = router_2_2_rsp_out[North];
  assign router_2_2_to_router_2_1_rsp = router_2_2_rsp_out[South];
  assign router_2_2_to_router_1_2_rsp = router_2_2_rsp_out[West];

  assign router_2_2_to_cluster_ni_2_2_req = router_2_2_req_out[Eject];
  assign router_2_2_to_router_3_2_req = router_2_2_req_out[East];
  assign router_2_2_to_router_2_3_req = router_2_2_req_out[North];
  assign router_2_2_to_router_2_1_req = router_2_2_req_out[South];
  assign router_2_2_to_router_1_2_req = router_2_2_req_out[West];

  assign router_2_2_rsp_in[Eject] = cluster_ni_2_2_to_router_2_2_rsp;
  assign router_2_2_rsp_in[East] = router_3_2_to_router_2_2_rsp;
  assign router_2_2_rsp_in[North] = router_2_3_to_router_2_2_rsp;
  assign router_2_2_rsp_in[South] = router_2_1_to_router_2_2_rsp;
  assign router_2_2_rsp_in[West] = router_1_2_to_router_2_2_rsp;

  assign router_2_2_wide_in[Eject] = cluster_ni_2_2_to_router_2_2_wide;
  assign router_2_2_wide_in[East] = router_3_2_to_router_2_2_wide;
  assign router_2_2_wide_in[North] = router_2_3_to_router_2_2_wide;
  assign router_2_2_wide_in[South] = router_2_1_to_router_2_2_wide;
  assign router_2_2_wide_in[West] = router_1_2_to_router_2_2_wide;

  assign router_2_2_to_cluster_ni_2_2_wide = router_2_2_wide_out[Eject];
  assign router_2_2_to_router_3_2_wide = router_2_2_wide_out[East];
  assign router_2_2_to_router_2_3_wide = router_2_2_wide_out[North];
  assign router_2_2_to_router_2_1_wide = router_2_2_wide_out[South];
  assign router_2_2_to_router_1_2_wide = router_2_2_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_2_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 2, y: 2}),
      .id_route_map_i('0),
      .floo_req_i(router_2_2_req_in),
      .floo_rsp_o(router_2_2_rsp_out),
      .floo_req_o(router_2_2_req_out),
      .floo_rsp_i(router_2_2_rsp_in),
      .floo_wide_i(router_2_2_wide_in),
      .floo_wide_o(router_2_2_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_2_3_req_in;
  floo_rsp_t  [NumDirections-1:0] router_2_3_rsp_out;
  floo_req_t  [NumDirections-1:0] router_2_3_req_out;
  floo_rsp_t  [NumDirections-1:0] router_2_3_rsp_in;
  floo_wide_t [NumDirections-1:0] router_2_3_wide_in;
  floo_wide_t [NumDirections-1:0] router_2_3_wide_out;

  assign router_2_3_req_in[Eject] = cluster_ni_2_3_to_router_2_3_req;
  assign router_2_3_req_in[East] = router_3_3_to_router_2_3_req;
  assign router_2_3_req_in[North] = '0;
  assign router_2_3_req_in[South] = router_2_2_to_router_2_3_req;
  assign router_2_3_req_in[West] = router_1_3_to_router_2_3_req;

  assign router_2_3_to_cluster_ni_2_3_rsp = router_2_3_rsp_out[Eject];
  assign router_2_3_to_router_3_3_rsp = router_2_3_rsp_out[East];
  assign router_2_3_to_router_2_2_rsp = router_2_3_rsp_out[South];
  assign router_2_3_to_router_1_3_rsp = router_2_3_rsp_out[West];

  assign router_2_3_to_cluster_ni_2_3_req = router_2_3_req_out[Eject];
  assign router_2_3_to_router_3_3_req = router_2_3_req_out[East];
  assign router_2_3_to_router_2_2_req = router_2_3_req_out[South];
  assign router_2_3_to_router_1_3_req = router_2_3_req_out[West];

  assign router_2_3_rsp_in[Eject] = cluster_ni_2_3_to_router_2_3_rsp;
  assign router_2_3_rsp_in[East] = router_3_3_to_router_2_3_rsp;
  assign router_2_3_rsp_in[North] = '0;
  assign router_2_3_rsp_in[South] = router_2_2_to_router_2_3_rsp;
  assign router_2_3_rsp_in[West] = router_1_3_to_router_2_3_rsp;

  assign router_2_3_wide_in[Eject] = cluster_ni_2_3_to_router_2_3_wide;
  assign router_2_3_wide_in[East] = router_3_3_to_router_2_3_wide;
  assign router_2_3_wide_in[North] = '0;
  assign router_2_3_wide_in[South] = router_2_2_to_router_2_3_wide;
  assign router_2_3_wide_in[West] = router_1_3_to_router_2_3_wide;

  assign router_2_3_to_cluster_ni_2_3_wide = router_2_3_wide_out[Eject];
  assign router_2_3_to_router_3_3_wide = router_2_3_wide_out[East];
  assign router_2_3_to_router_2_2_wide = router_2_3_wide_out[South];
  assign router_2_3_to_router_1_3_wide = router_2_3_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_2_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 2, y: 3}),
      .id_route_map_i('0),
      .floo_req_i(router_2_3_req_in),
      .floo_rsp_o(router_2_3_rsp_out),
      .floo_req_o(router_2_3_req_out),
      .floo_rsp_i(router_2_3_rsp_in),
      .floo_wide_i(router_2_3_wide_in),
      .floo_wide_o(router_2_3_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_3_0_req_in;
  floo_rsp_t  [NumDirections-1:0] router_3_0_rsp_out;
  floo_req_t  [NumDirections-1:0] router_3_0_req_out;
  floo_rsp_t  [NumDirections-1:0] router_3_0_rsp_in;
  floo_wide_t [NumDirections-1:0] router_3_0_wide_in;
  floo_wide_t [NumDirections-1:0] router_3_0_wide_out;

  assign router_3_0_req_in[Eject] = cluster_ni_3_0_to_router_3_0_req;
  assign router_3_0_req_in[East] = '0;
  assign router_3_0_req_in[North] = router_3_1_to_router_3_0_req;
  assign router_3_0_req_in[South] = '0;
  assign router_3_0_req_in[West] = router_2_0_to_router_3_0_req;

  assign router_3_0_to_cluster_ni_3_0_rsp = router_3_0_rsp_out[Eject];
  assign router_3_0_to_router_3_1_rsp = router_3_0_rsp_out[North];
  assign router_3_0_to_router_2_0_rsp = router_3_0_rsp_out[West];

  assign router_3_0_to_cluster_ni_3_0_req = router_3_0_req_out[Eject];
  assign router_3_0_to_router_3_1_req = router_3_0_req_out[North];
  assign router_3_0_to_router_2_0_req = router_3_0_req_out[West];

  assign router_3_0_rsp_in[Eject] = cluster_ni_3_0_to_router_3_0_rsp;
  assign router_3_0_rsp_in[East] = '0;
  assign router_3_0_rsp_in[North] = router_3_1_to_router_3_0_rsp;
  assign router_3_0_rsp_in[South] = '0;
  assign router_3_0_rsp_in[West] = router_2_0_to_router_3_0_rsp;

  assign router_3_0_wide_in[Eject] = cluster_ni_3_0_to_router_3_0_wide;
  assign router_3_0_wide_in[East] = '0;
  assign router_3_0_wide_in[North] = router_3_1_to_router_3_0_wide;
  assign router_3_0_wide_in[South] = '0;
  assign router_3_0_wide_in[West] = router_2_0_to_router_3_0_wide;

  assign router_3_0_to_cluster_ni_3_0_wide = router_3_0_wide_out[Eject];
  assign router_3_0_to_router_3_1_wide = router_3_0_wide_out[North];
  assign router_3_0_to_router_2_0_wide = router_3_0_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_3_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 3, y: 0}),
      .id_route_map_i('0),
      .floo_req_i(router_3_0_req_in),
      .floo_rsp_o(router_3_0_rsp_out),
      .floo_req_o(router_3_0_req_out),
      .floo_rsp_i(router_3_0_rsp_in),
      .floo_wide_i(router_3_0_wide_in),
      .floo_wide_o(router_3_0_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_3_1_req_in;
  floo_rsp_t  [NumDirections-1:0] router_3_1_rsp_out;
  floo_req_t  [NumDirections-1:0] router_3_1_req_out;
  floo_rsp_t  [NumDirections-1:0] router_3_1_rsp_in;
  floo_wide_t [NumDirections-1:0] router_3_1_wide_in;
  floo_wide_t [NumDirections-1:0] router_3_1_wide_out;

  assign router_3_1_req_in[Eject] = cluster_ni_3_1_to_router_3_1_req;
  assign router_3_1_req_in[East] = '0;
  assign router_3_1_req_in[North] = router_3_2_to_router_3_1_req;
  assign router_3_1_req_in[South] = router_3_0_to_router_3_1_req;
  assign router_3_1_req_in[West] = router_2_1_to_router_3_1_req;

  assign router_3_1_to_cluster_ni_3_1_rsp = router_3_1_rsp_out[Eject];
  assign router_3_1_to_router_3_2_rsp = router_3_1_rsp_out[North];
  assign router_3_1_to_router_3_0_rsp = router_3_1_rsp_out[South];
  assign router_3_1_to_router_2_1_rsp = router_3_1_rsp_out[West];

  assign router_3_1_to_cluster_ni_3_1_req = router_3_1_req_out[Eject];
  assign router_3_1_to_router_3_2_req = router_3_1_req_out[North];
  assign router_3_1_to_router_3_0_req = router_3_1_req_out[South];
  assign router_3_1_to_router_2_1_req = router_3_1_req_out[West];

  assign router_3_1_rsp_in[Eject] = cluster_ni_3_1_to_router_3_1_rsp;
  assign router_3_1_rsp_in[East] = '0;
  assign router_3_1_rsp_in[North] = router_3_2_to_router_3_1_rsp;
  assign router_3_1_rsp_in[South] = router_3_0_to_router_3_1_rsp;
  assign router_3_1_rsp_in[West] = router_2_1_to_router_3_1_rsp;

  assign router_3_1_wide_in[Eject] = cluster_ni_3_1_to_router_3_1_wide;
  assign router_3_1_wide_in[East] = '0;
  assign router_3_1_wide_in[North] = router_3_2_to_router_3_1_wide;
  assign router_3_1_wide_in[South] = router_3_0_to_router_3_1_wide;
  assign router_3_1_wide_in[West] = router_2_1_to_router_3_1_wide;

  assign router_3_1_to_cluster_ni_3_1_wide = router_3_1_wide_out[Eject];
  assign router_3_1_to_router_3_2_wide = router_3_1_wide_out[North];
  assign router_3_1_to_router_3_0_wide = router_3_1_wide_out[South];
  assign router_3_1_to_router_2_1_wide = router_3_1_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_3_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 3, y: 1}),
      .id_route_map_i('0),
      .floo_req_i(router_3_1_req_in),
      .floo_rsp_o(router_3_1_rsp_out),
      .floo_req_o(router_3_1_req_out),
      .floo_rsp_i(router_3_1_rsp_in),
      .floo_wide_i(router_3_1_wide_in),
      .floo_wide_o(router_3_1_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_3_2_req_in;
  floo_rsp_t  [NumDirections-1:0] router_3_2_rsp_out;
  floo_req_t  [NumDirections-1:0] router_3_2_req_out;
  floo_rsp_t  [NumDirections-1:0] router_3_2_rsp_in;
  floo_wide_t [NumDirections-1:0] router_3_2_wide_in;
  floo_wide_t [NumDirections-1:0] router_3_2_wide_out;

  assign router_3_2_req_in[Eject] = cluster_ni_3_2_to_router_3_2_req;
  assign router_3_2_req_in[East] = '0;
  assign router_3_2_req_in[North] = router_3_3_to_router_3_2_req;
  assign router_3_2_req_in[South] = router_3_1_to_router_3_2_req;
  assign router_3_2_req_in[West] = router_2_2_to_router_3_2_req;

  assign router_3_2_to_cluster_ni_3_2_rsp = router_3_2_rsp_out[Eject];
  assign router_3_2_to_router_3_3_rsp = router_3_2_rsp_out[North];
  assign router_3_2_to_router_3_1_rsp = router_3_2_rsp_out[South];
  assign router_3_2_to_router_2_2_rsp = router_3_2_rsp_out[West];

  assign router_3_2_to_cluster_ni_3_2_req = router_3_2_req_out[Eject];
  assign router_3_2_to_router_3_3_req = router_3_2_req_out[North];
  assign router_3_2_to_router_3_1_req = router_3_2_req_out[South];
  assign router_3_2_to_router_2_2_req = router_3_2_req_out[West];

  assign router_3_2_rsp_in[Eject] = cluster_ni_3_2_to_router_3_2_rsp;
  assign router_3_2_rsp_in[East] = '0;
  assign router_3_2_rsp_in[North] = router_3_3_to_router_3_2_rsp;
  assign router_3_2_rsp_in[South] = router_3_1_to_router_3_2_rsp;
  assign router_3_2_rsp_in[West] = router_2_2_to_router_3_2_rsp;

  assign router_3_2_wide_in[Eject] = cluster_ni_3_2_to_router_3_2_wide;
  assign router_3_2_wide_in[East] = '0;
  assign router_3_2_wide_in[North] = router_3_3_to_router_3_2_wide;
  assign router_3_2_wide_in[South] = router_3_1_to_router_3_2_wide;
  assign router_3_2_wide_in[West] = router_2_2_to_router_3_2_wide;

  assign router_3_2_to_cluster_ni_3_2_wide = router_3_2_wide_out[Eject];
  assign router_3_2_to_router_3_3_wide = router_3_2_wide_out[North];
  assign router_3_2_to_router_3_1_wide = router_3_2_wide_out[South];
  assign router_3_2_to_router_2_2_wide = router_3_2_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_3_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 3, y: 2}),
      .id_route_map_i('0),
      .floo_req_i(router_3_2_req_in),
      .floo_rsp_o(router_3_2_rsp_out),
      .floo_req_o(router_3_2_req_out),
      .floo_rsp_i(router_3_2_rsp_in),
      .floo_wide_i(router_3_2_wide_in),
      .floo_wide_o(router_3_2_wide_out)
  );


  floo_req_t  [NumDirections-1:0] router_3_3_req_in;
  floo_rsp_t  [NumDirections-1:0] router_3_3_rsp_out;
  floo_req_t  [NumDirections-1:0] router_3_3_req_out;
  floo_rsp_t  [NumDirections-1:0] router_3_3_rsp_in;
  floo_wide_t [NumDirections-1:0] router_3_3_wide_in;
  floo_wide_t [NumDirections-1:0] router_3_3_wide_out;

  assign router_3_3_req_in[Eject] = cluster_ni_3_3_to_router_3_3_req;
  assign router_3_3_req_in[East] = '0;
  assign router_3_3_req_in[North] = '0;
  assign router_3_3_req_in[South] = router_3_2_to_router_3_3_req;
  assign router_3_3_req_in[West] = router_2_3_to_router_3_3_req;

  assign router_3_3_to_cluster_ni_3_3_rsp = router_3_3_rsp_out[Eject];
  assign router_3_3_to_router_3_2_rsp = router_3_3_rsp_out[South];
  assign router_3_3_to_router_2_3_rsp = router_3_3_rsp_out[West];

  assign router_3_3_to_cluster_ni_3_3_req = router_3_3_req_out[Eject];
  assign router_3_3_to_router_3_2_req = router_3_3_req_out[South];
  assign router_3_3_to_router_2_3_req = router_3_3_req_out[West];

  assign router_3_3_rsp_in[Eject] = cluster_ni_3_3_to_router_3_3_rsp;
  assign router_3_3_rsp_in[East] = '0;
  assign router_3_3_rsp_in[North] = '0;
  assign router_3_3_rsp_in[South] = router_3_2_to_router_3_3_rsp;
  assign router_3_3_rsp_in[West] = router_2_3_to_router_3_3_rsp;

  assign router_3_3_wide_in[Eject] = cluster_ni_3_3_to_router_3_3_wide;
  assign router_3_3_wide_in[East] = '0;
  assign router_3_3_wide_in[North] = '0;
  assign router_3_3_wide_in[South] = router_3_2_to_router_3_3_wide;
  assign router_3_3_wide_in[West] = router_2_3_to_router_3_3_wide;

  assign router_3_3_to_cluster_ni_3_3_wide = router_3_3_wide_out[Eject];
  assign router_3_3_to_router_3_2_wide = router_3_3_wide_out[South];
  assign router_3_3_to_router_2_3_wide = router_3_3_wide_out[West];

  floo_narrow_wide_router #(
      .NumRoutes(NumDirections),
      .ChannelFifoDepth(2),
      .OutputFifoDepth(2),
      .RouteAlgo(XYRouting),
      .id_t(id_t)
  ) router_3_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('{x: 3, y: 3}),
      .id_route_map_i('0),
      .floo_req_i(router_3_3_req_in),
      .floo_rsp_o(router_3_3_rsp_out),
      .floo_req_o(router_3_3_req_out),
      .floo_rsp_i(router_3_3_rsp_in),
      .floo_wide_i(router_3_3_wide_in),
      .floo_wide_o(router_3_3_wide_out)
  );



endmodule
