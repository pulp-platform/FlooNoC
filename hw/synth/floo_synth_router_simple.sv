// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

module floo_synth_router_simple
  import floo_pkg::*;
  import floo_axi_pkg::*;
  import floo_test_pkg::*;
#(
  parameter int unsigned DataWidth = 32,
  parameter type data_t = logic [DataWidth-1:0],
  parameter type flit_t = struct packed {
    data_t data;
    id_t id;
    logic  last;
  }
) (
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   test_enable_i,

  input  id_t xy_id_i,

  input  flit_t [NumRoutes-1:0] data_i,
  output  flit_t [NumRoutes-1:0] data_o,
  input  logic [NumRoutes-1:0] valid_i,
  output  logic [NumRoutes-1:0] valid_o,
  input  logic [NumRoutes-1:0] ready_i,
  output  logic [NumRoutes-1:0] ready_o
);

  floo_router #(
    .NumPhysChannels  ( 1         ),
    .NumVirtChannels  ( 1         ),
    .NumRoutes        ( NumRoutes ),
    .flit_t           ( flit_t    ),
    .ChannelFifoDepth ( 0         ),
    .OutputFifoDepth  ( 0         ),
    .RouteAlgo        ( XYRouting ),
    .IdWidth          ( 4         ),
    .id_t             ( id_t      ),
    .NumAddrRules     ( 1         )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i ('0),
    .valid_i,
    .ready_o,
    .data_i,
    .valid_o,
    .ready_i,
    .data_o
  );

endmodule
