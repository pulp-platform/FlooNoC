// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module router1_endpoint4_floo_noc
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  input axi_narrow_in_req_t              cluster1_narrow_req_i,
  output axi_narrow_in_rsp_t              cluster1_narrow_rsp_o,
  input axi_wide_in_req_t              cluster1_wide_req_i,
  output axi_wide_in_rsp_t              cluster1_wide_rsp_o,
  output axi_narrow_out_req_t              cluster1_narrow_req_o,
  input axi_narrow_out_rsp_t              cluster1_narrow_rsp_i,
  output axi_wide_out_req_t              cluster1_wide_req_o,
  input axi_wide_out_rsp_t              cluster1_wide_rsp_i,
  input axi_narrow_in_req_t              cluster2_narrow_req_i,
  output axi_narrow_in_rsp_t              cluster2_narrow_rsp_o,
  input axi_wide_in_req_t              cluster2_wide_req_i,
  output axi_wide_in_rsp_t              cluster2_wide_rsp_o,
  output axi_narrow_out_req_t              cluster2_narrow_req_o,
  input axi_narrow_out_rsp_t              cluster2_narrow_rsp_i,
  output axi_wide_out_req_t              cluster2_wide_req_o,
  input axi_wide_out_rsp_t              cluster2_wide_rsp_i,
  input axi_narrow_in_req_t              cluster3_narrow_req_i,
  output axi_narrow_in_rsp_t              cluster3_narrow_rsp_o,
  input axi_wide_in_req_t              cluster3_wide_req_i,
  output axi_wide_in_rsp_t              cluster3_wide_rsp_o,
  output axi_narrow_out_req_t              cluster3_narrow_req_o,
  input axi_narrow_out_rsp_t              cluster3_narrow_rsp_i,
  output axi_wide_out_req_t              cluster3_wide_req_o,
  input axi_wide_out_rsp_t              cluster3_wide_rsp_i,
  input axi_narrow_in_req_t              cluster4_narrow_req_i,
  output axi_narrow_in_rsp_t              cluster4_narrow_rsp_o,
  input axi_wide_in_req_t              cluster4_wide_req_i,
  output axi_wide_in_rsp_t              cluster4_wide_rsp_o,
  output axi_narrow_out_req_t              cluster4_narrow_req_o,
  input axi_narrow_out_rsp_t              cluster4_narrow_rsp_i,
  output axi_wide_out_req_t              cluster4_wide_req_o,
  input axi_wide_out_rsp_t              cluster4_wide_rsp_i

);

floo_req_t router_to_cluster1_ni_req;
floo_rsp_t cluster1_ni_to_router_rsp;
floo_wide_t router_to_cluster1_ni_wide;

floo_req_t router_to_cluster2_ni_req;
floo_rsp_t cluster2_ni_to_router_rsp;
floo_wide_t router_to_cluster2_ni_wide;

floo_req_t router_to_cluster3_ni_req;
floo_rsp_t cluster3_ni_to_router_rsp;
floo_wide_t router_to_cluster3_ni_wide;

floo_req_t router_to_cluster4_ni_req;
floo_rsp_t cluster4_ni_to_router_rsp;
floo_wide_t router_to_cluster4_ni_wide;

floo_req_t cluster1_ni_to_router_req;
floo_rsp_t router_to_cluster1_ni_rsp;
floo_wide_t cluster1_ni_to_router_wide;

floo_req_t cluster2_ni_to_router_req;
floo_rsp_t router_to_cluster2_ni_rsp;
floo_wide_t cluster2_ni_to_router_wide;

floo_req_t cluster3_ni_to_router_req;
floo_rsp_t router_to_cluster3_ni_rsp;
floo_wide_t cluster3_ni_to_router_wide;

floo_req_t cluster4_ni_to_router_req;
floo_rsp_t router_to_cluster4_ni_rsp;
floo_wide_t cluster4_ni_to_router_wide;



floo_narrow_wide_chimney  #(
  .EnNarrowSbrPort(1'b1),
  .EnNarrowMgrPort(1'b1),
  .EnWideSbrPort(1'b1),
  .EnWideMgrPort(1'b1),
  .TileNameNarrowIn("ni_narrow_in_1"),
  .TileNameNarrowOut("ni_narrow_out_1"),
  .TileNameWideIn("ni_wide_in_1"),
  .TileNameWideOut("ni_wide_out_1"),
  .WideInAW("wide_in_aw_1"),
  .WideInB("wide_in_b_1"),
  .WideInAR("wide_in_ar_1"),
  .WideInR("wide_in_r_1")
) cluster1_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( cluster1_narrow_req_i ),
  .axi_narrow_in_rsp_o  ( cluster1_narrow_rsp_o ),
  .axi_narrow_out_req_o ( cluster1_narrow_req_o ),
  .axi_narrow_out_rsp_i ( cluster1_narrow_rsp_i ),
  .axi_wide_in_req_i  ( cluster1_wide_req_i ),
  .axi_wide_in_rsp_o  ( cluster1_wide_rsp_o ),
  .axi_wide_out_req_o ( cluster1_wide_req_o ),
  .axi_wide_out_rsp_i ( cluster1_wide_rsp_i ),
  .id_i             ( '{x: 1, y: 2}    ),
  .floo_req_o       ( cluster1_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster1_ni_rsp   ),
  .floo_wide_o      ( cluster1_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cluster1_ni_req   ),
  .floo_rsp_o       ( cluster1_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cluster1_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .EnNarrowSbrPort(1'b1),
  .EnNarrowMgrPort(1'b1),
  .EnWideSbrPort(1'b1),
  .EnWideMgrPort(1'b1),
  .TileNameNarrowIn("ni_narrow_in_2"),
  .TileNameNarrowOut("ni_narrow_out_2"),
  .TileNameWideIn("ni_wide_in_2"),
  .TileNameWideOut("ni_wide_out_2"),
  .WideInAW("wide_in_aw_2"),
  .WideInB("wide_in_b_2"),
  .WideInAR("wide_in_ar_2"),
  .WideInR("wide_in_r_2")
) cluster2_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( cluster2_narrow_req_i ),
  .axi_narrow_in_rsp_o  ( cluster2_narrow_rsp_o ),
  .axi_narrow_out_req_o ( cluster2_narrow_req_o ),
  .axi_narrow_out_rsp_i ( cluster2_narrow_rsp_i ),
  .axi_wide_in_req_i  ( cluster2_wide_req_i ),
  .axi_wide_in_rsp_o  ( cluster2_wide_rsp_o ),
  .axi_wide_out_req_o ( cluster2_wide_req_o ),
  .axi_wide_out_rsp_i ( cluster2_wide_rsp_i ),
  .id_i             ( '{x: 2, y: 1}   ),
  .floo_req_o       ( cluster2_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster2_ni_rsp   ),
  .floo_wide_o      ( cluster2_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cluster2_ni_req   ),
  .floo_rsp_o       ( cluster2_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cluster2_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .EnNarrowSbrPort(1'b1),
  .EnNarrowMgrPort(1'b1),
  .EnWideSbrPort(1'b1),
  .EnWideMgrPort(1'b1),
  .TileNameNarrowIn("ni_narrow_in_3"),
  .TileNameNarrowOut("ni_narrow_out_3"),
  .TileNameWideIn("ni_wide_in_3"),
  .TileNameWideOut("ni_wide_out_3"),
  .WideInAW("wide_in_aw_3"),
  .WideInB("wide_in_b_3"),
  .WideInAR("wide_in_ar_3"),
  .WideInR("wide_in_r_3")
) cluster3_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( cluster3_narrow_req_i ),
  .axi_narrow_in_rsp_o  ( cluster3_narrow_rsp_o ),
  .axi_narrow_out_req_o ( cluster3_narrow_req_o ),
  .axi_narrow_out_rsp_i ( cluster3_narrow_rsp_i ),
  .axi_wide_in_req_i  ( cluster3_wide_req_i ),
  .axi_wide_in_rsp_o  ( cluster3_wide_rsp_o ),
  .axi_wide_out_req_o ( cluster3_wide_req_o ),
  .axi_wide_out_rsp_i ( cluster3_wide_rsp_i ),
  .id_i             ( '{x: 1, y: 0}    ),
  .floo_req_o       ( cluster3_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster3_ni_rsp   ),
  .floo_wide_o      ( cluster3_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cluster3_ni_req   ),
  .floo_rsp_o       ( cluster3_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cluster3_ni_wide  )
);

floo_narrow_wide_chimney  #(
  .EnNarrowSbrPort(1'b1),
  .EnNarrowMgrPort(1'b1),
  .EnWideSbrPort(1'b1),
  .EnWideMgrPort(1'b1),
  .TileNameNarrowIn("ni_narrow_in_4"),
  .TileNameNarrowOut("ni_narrow_out_4"),
  .TileNameWideIn("ni_wide_in_4"),
  .TileNameWideOut("ni_wide_out_4"),
  .WideInAW("wide_in_aw_4"),
  .WideInB("wide_in_b_4"),
  .WideInAR("wide_in_ar_4"),
  .WideInR("wide_in_r_4")
) cluster4_ni (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_narrow_in_req_i  ( cluster4_narrow_req_i ),
  .axi_narrow_in_rsp_o  ( cluster4_narrow_rsp_o ),
  .axi_narrow_out_req_o ( cluster4_narrow_req_o ),
  .axi_narrow_out_rsp_i ( cluster4_narrow_rsp_i ),
  .axi_wide_in_req_i  ( cluster4_wide_req_i ),
  .axi_wide_in_rsp_o  ( cluster4_wide_rsp_o ),
  .axi_wide_out_req_o ( cluster4_wide_req_o ),
  .axi_wide_out_rsp_i ( cluster4_wide_rsp_i ),
  .id_i             ( '{x: 0, y: 1}    ),
  .floo_req_o       ( cluster4_ni_to_router_req   ),
  .floo_rsp_i       ( router_to_cluster4_ni_rsp   ),
  .floo_wide_o      ( cluster4_ni_to_router_wide  ),
  .floo_req_i       ( router_to_cluster4_ni_req   ),
  .floo_rsp_o       ( cluster4_ni_to_router_rsp   ),
  .floo_wide_i      ( router_to_cluster4_ni_wide  )
);


floo_req_t [NumDirections-1:0] router_req_in;
floo_rsp_t [NumDirections-1:0] router_rsp_out;
floo_req_t [NumDirections-1:0] router_req_out;
floo_rsp_t [NumDirections-1:0] router_rsp_in;
floo_wide_t [NumDirections-1:0] router_wide_in;
floo_wide_t [NumDirections-1:0] router_wide_out;

  assign router_req_in[Eject] = '0;
  assign router_req_in[East] = cluster2_ni_to_router_req;
  assign router_req_in[North] = cluster1_ni_to_router_req;
  assign router_req_in[South] = cluster3_ni_to_router_req;
  assign router_req_in[West] = cluster4_ni_to_router_req;

  assign router_to_cluster2_ni_rsp = router_rsp_out[East];
  assign router_to_cluster1_ni_rsp = router_rsp_out[North];
  assign router_to_cluster3_ni_rsp = router_rsp_out[South];
  assign router_to_cluster4_ni_rsp = router_rsp_out[West];

  assign router_to_cluster2_ni_req = router_req_out[East];
  assign router_to_cluster1_ni_req = router_req_out[North];
  assign router_to_cluster3_ni_req = router_req_out[South];
  assign router_to_cluster4_ni_req = router_req_out[West];

  assign router_rsp_in[Eject] = '0;
  assign router_rsp_in[East] = cluster2_ni_to_router_rsp;
  assign router_rsp_in[North] = cluster1_ni_to_router_rsp;
  assign router_rsp_in[South] = cluster3_ni_to_router_rsp;
  assign router_rsp_in[West] = cluster4_ni_to_router_rsp;

  assign router_wide_in[Eject] = '0;
  assign router_wide_in[East] = cluster2_ni_to_router_wide;
  assign router_wide_in[North] = cluster1_ni_to_router_wide;
  assign router_wide_in[South] = cluster3_ni_to_router_wide;
  assign router_wide_in[West] = cluster4_ni_to_router_wide;

  assign router_to_cluster2_ni_wide = router_wide_out[East];
  assign router_to_cluster1_ni_wide = router_wide_out[North];
  assign router_to_cluster3_ni_wide = router_wide_out[South];
  assign router_to_cluster4_ni_wide = router_wide_out[West];

id_t rt_pos = '{x: 1, y: 1};

floo_narrow_wide_router #(
  .NumRoutes (NumDirections),
  .ChannelFifoDepth (2),
  .OutputFifoDepth (2),
  .RouteAlgo (XYRouting),
  .XYRouteOpt      (1'b0),
  .id_t(id_t),
  .Mesh(1'b0)
) router (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i (rt_pos),
  .id_route_map_i ('0),
  .floo_req_i (router_req_in),
  .floo_rsp_o (router_rsp_out),
  .floo_req_o (router_req_out),
  .floo_rsp_i (router_rsp_in),
  .floo_wide_i (router_wide_in),
  .floo_wide_o (router_wide_out)
);



endmodule
