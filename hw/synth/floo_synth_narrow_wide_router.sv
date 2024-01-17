// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_narrow_wide_router
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
  import floo_test_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  input  id_t id_i,

  input  floo_req_t [NumRoutes-1:0] floo_req_i,
  input  floo_rsp_t [NumRoutes-1:0] floo_rsp_i,
  output floo_req_t [NumRoutes-1:0] floo_req_o,
  output floo_rsp_t [NumRoutes-1:0] floo_rsp_o,
  input  floo_wide_t [NumRoutes-1:0] floo_wide_i,
  output floo_wide_t [NumRoutes-1:0] floo_wide_o
);

  floo_narrow_wide_router #(
    .NumRoutes        ( NumRoutes         ),
    .ChannelFifoDepth ( ChannelFifoDepth  ),
    .OutputFifoDepth  ( OutputFifoDepth   ),
    .RouteAlgo        ( XYRouting         ),
    .id_t             ( id_t              )
  ) i_floo_narrow_wide_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .id_i(id_i),
    .id_route_map_i ('0),
    .floo_req_i,
    .floo_req_o,
    .floo_rsp_i,
    .floo_rsp_o,
    .floo_wide_i,
    .floo_wide_o
  );

endmodule
