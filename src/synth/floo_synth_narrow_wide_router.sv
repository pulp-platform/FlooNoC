// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_narrow_wide_router
  import floo_pkg::*;
  import floo_narrow_wide_flit_pkg::*;
  import floo_param_pkg::*;
(
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   test_enable_i,

  input  xy_id_t xy_id_i,

  input   narrow_req_flit_t [NumRoutes-1:0] narrow_req_i,
  input   narrow_rsp_flit_t [NumRoutes-1:0] narrow_rsp_i,
  output  narrow_req_flit_t [NumRoutes-1:0] narrow_req_o,
  output  narrow_rsp_flit_t [NumRoutes-1:0] narrow_rsp_o,
  input   wide_flit_t   [NumRoutes-1:0] wide_i,
  output  wide_flit_t   [NumRoutes-1:0] wide_o
);

  floo_narrow_wide_router #(
    .NumRoutes        ( NumRoutes         ),
    .ChannelFifoDepth ( ChannelFifoDepth  ),
    .OutputFifoDepth  ( OutputFifoDepth   ),
    .RouteAlgo        ( RouteAlgo         ),
    .id_t             ( xy_id_t           )
  ) i_floo_narrow_wide_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i ('0),
    .narrow_req_i,
    .narrow_req_o,
    .narrow_rsp_i,
    .narrow_rsp_o,
    .wide_i,
    .wide_o
  );

endmodule
