// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// Wrapper of a multi-link router for narrow and wide links
module floo_narrow_wide_router
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
  #(
    parameter int unsigned NumRoutes        = NumDirections,
    parameter int unsigned NumInputs        = NumRoutes,
    parameter int unsigned NumOutputs       = NumRoutes,
    parameter int unsigned ChannelFifoDepth = 0,
    parameter int unsigned OutputFifoDepth  = 0,
    parameter route_algo_e RouteAlgo        = XYRouting,
    /// Used for ID-based and XY routing
    parameter int unsigned IdWidth          = 0,
    parameter type         id_t             = logic[IdWidth-1:0],
    /// Used for ID-based routing
    parameter int unsigned NumAddrRules     = 0,
    parameter type         addr_rule_t      = logic
) (
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   test_enable_i,

  input  id_t xy_id_i,
  input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,

  input   logic [NumInputs-1:0] floo_req_valid_i,
  output  logic [NumInputs-1:0] floo_req_ready_o,
  input   floo_req_t [NumInputs-1:0] floo_req_i,
  input   logic [NumOutputs-1:0] floo_rsp_valid_i,
  output  logic [NumOutputs-1:0] floo_rsp_ready_o,
  input   floo_rsp_t [NumOutputs-1:0] floo_rsp_i,
  output  logic [NumOutputs-1:0] floo_req_valid_o,
  input   logic [NumOutputs-1:0] floo_req_ready_i,
  output  floo_req_t [NumOutputs-1:0] floo_req_o,
  output  logic [NumInputs-1:0] floo_rsp_valid_o,
  input   logic [NumInputs-1:0] floo_rsp_ready_i,
  output  floo_rsp_t [NumInputs-1:0] floo_rsp_o,
  input   logic [NumRoutes-1:0] floo_wide_valid_i,
  output  logic [NumRoutes-1:0] floo_wide_ready_o,
  input   floo_wide_t   [NumRoutes-1:0] floo_wide_i,
  output  logic [NumRoutes-1:0] floo_wide_valid_o,
  input   logic [NumRoutes-1:0] floo_wide_ready_i,
  output  floo_wide_t   [NumRoutes-1:0] floo_wide_o
);

  floo_router #(
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .flit_t           ( floo_req_generic_flit_t ),
    .ChannelFifoDepth ( ChannelFifoDepth        ),
    .OutputFifoDepth  ( OutputFifoDepth         ),
    .RouteAlgo        ( RouteAlgo               ),
    .IdWidth          ( IdWidth                 ),
    .id_t             ( id_t                    ),
    .NumAddrRules     ( NumAddrRules            )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i,
    .valid_i        ( floo_req_valid_i  ),
    .ready_o        ( floo_req_ready_o  ),
    .data_i         ( floo_req_i        ),
    .valid_o        ( floo_req_valid_o  ),
    .ready_i        ( floo_req_ready_i  ),
    .data_o         ( floo_req_o        )
  );


  floo_router #(
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .ChannelFifoDepth ( ChannelFifoDepth        ),
    .OutputFifoDepth  ( OutputFifoDepth         ),
    .RouteAlgo        ( RouteAlgo               ),
    .IdWidth          ( IdWidth                 ),
    .flit_t           ( floo_rsp_generic_flit_t ),
    .id_t             ( id_t                    ),
    .NumAddrRules     ( NumAddrRules            )
  ) i_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i,
    .valid_i        ( floo_rsp_valid_i  ),
    .ready_o        ( floo_rsp_ready_o  ),
    .data_i         ( floo_rsp_i        ),
    .valid_o        ( floo_rsp_valid_o  ),
    .ready_i        ( floo_rsp_ready_i  ),
    .data_o         ( floo_rsp_o        )
  );


  floo_router #(
    .NumPhysChannels  ( 1                         ),
    .NumVirtChannels  ( 1                         ),
    .NumRoutes        ( NumRoutes                 ),
    .flit_t           ( floo_wide_generic_flit_t  ),
    .ChannelFifoDepth ( ChannelFifoDepth          ),
    .OutputFifoDepth  ( OutputFifoDepth           ),
    .RouteAlgo        ( RouteAlgo                 ),
    .IdWidth          ( IdWidth                   ),
    .id_t             ( id_t                      ),
    .NumAddrRules     ( NumAddrRules              )
  ) i_wide_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i,
    .valid_i        ( floo_wide_valid_i ),
    .ready_o        ( floo_wide_ready_o ),
    .data_i         ( floo_wide_i       ),
    .valid_o        ( floo_wide_valid_o ),
    .ready_i        ( floo_wide_ready_i ),
    .data_o         ( floo_wide_o       )
  );

endmodule
