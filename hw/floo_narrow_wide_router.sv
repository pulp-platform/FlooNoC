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
    parameter bit          XYRouteOpt       = 1'b1,
    /// Used for ID-based and XY routing
    parameter int unsigned IdWidth          = 0,
    parameter type         id_t             = logic[IdWidth-1:0],
    /// Used for ID-based routing
    parameter int unsigned NumAddrRules     = 0,
    parameter type         addr_rule_t      = logic,
    parameter  bit         Mesh             = 1'b1
) (
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   test_enable_i,

  input  id_t id_i,
  input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,

  input   floo_req_t [NumInputs-1:0] floo_req_i,
  input   floo_rsp_t [NumOutputs-1:0] floo_rsp_i,
  output  floo_req_t [NumOutputs-1:0] floo_req_o,
  output  floo_rsp_t [NumInputs-1:0] floo_rsp_o,
  input   floo_wide_t   [NumRoutes-1:0] floo_wide_i,
  output  floo_wide_t   [NumRoutes-1:0] floo_wide_o
);

  floo_req_chan_t [NumInputs-1:0] req_in;
  floo_rsp_chan_t [NumInputs-1:0] rsp_out;
  floo_req_chan_t [NumOutputs-1:0] req_out;
  floo_rsp_chan_t [NumOutputs-1:0] rsp_in;
  floo_wide_chan_t [NumRoutes-1:0] wide_in, wide_out;
  logic [NumInputs-1:0] req_valid_in, req_ready_out;
  logic [NumInputs-1:0] rsp_valid_out, rsp_ready_in;
  logic [NumOutputs-1:0] req_valid_out, req_ready_in;
  logic [NumOutputs-1:0] rsp_valid_in, rsp_ready_out;
  logic [NumRoutes-1:0] wide_valid_in, wide_valid_out;
  logic [NumRoutes-1:0] wide_ready_in, wide_ready_out;

  for (genvar i = 0; i < NumInputs; i++) begin : gen_chimney_req
    assign req_valid_in[i] = floo_req_i[i].valid;
    assign floo_req_o[i].ready = req_ready_out[i];
    assign req_in[i] = floo_req_i[i].req;
    assign floo_rsp_o[i].valid = rsp_valid_out[i];
    assign rsp_ready_in[i] = floo_rsp_i[i].ready;
    assign floo_rsp_o[i].rsp = rsp_out[i];
  end

  for (genvar i = 0; i < NumOutputs; i++) begin : gen_chimney_rsp
    assign floo_req_o[i].valid = req_valid_out[i];
    assign req_ready_in[i] = floo_req_i[i].ready;
    assign floo_req_o[i].req = req_out[i];
    assign rsp_valid_in[i] = floo_rsp_i[i].valid;
    assign floo_rsp_o[i].ready = rsp_ready_out[i];
    assign rsp_in[i] = floo_rsp_i[i].rsp;
  end

  for (genvar i = 0; i < NumRoutes; i++) begin : gen_chimney_wide
    assign wide_valid_in[i] = floo_wide_i[i].valid;
    assign floo_wide_o[i].ready = wide_ready_out[i];
    assign wide_in[i] = floo_wide_i[i].wide;
    assign floo_wide_o[i].valid = wide_valid_out[i];
    assign wide_ready_in[i] = floo_wide_i[i].ready;
    assign floo_wide_o[i].wide = wide_out[i];
  end

  floo_router #(
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .flit_t           ( floo_req_generic_flit_t ),
    .ChannelFifoDepth ( ChannelFifoDepth        ),
    .OutputFifoDepth  ( OutputFifoDepth         ),
    .RouteAlgo        ( RouteAlgo               ),
    .XYRouteOpt       ( XYRouteOpt              ),
    .IdWidth          ( IdWidth                 ),
    .id_t             ( id_t                    ),
    .NumAddrRules     ( NumAddrRules            ),
    .addr_rule_t      ( addr_rule_t             ),
    .Mesh             ( Mesh                    )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i(id_i),
    .id_route_map_i,
    .valid_i        ( req_valid_in  ),
    .ready_o        ( req_ready_out ),
    .data_i         ( req_in        ),
    .valid_o        ( req_valid_out ),
    .ready_i        ( req_ready_in  ),
    .data_o         ( req_out       )
  );


  floo_router #(
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .ChannelFifoDepth ( ChannelFifoDepth        ),
    .OutputFifoDepth  ( OutputFifoDepth         ),
    .RouteAlgo        ( RouteAlgo               ),
    .XYRouteOpt       ( XYRouteOpt              ),
    .IdWidth          ( IdWidth                 ),
    .flit_t           ( floo_rsp_generic_flit_t ),
    .id_t             ( id_t                    ),
    .NumAddrRules     ( NumAddrRules            ),
    .addr_rule_t      ( addr_rule_t             ),
    .Mesh             ( Mesh                    )
  ) i_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i(id_i),
    .id_route_map_i,
    .valid_i        ( rsp_valid_in  ),
    .ready_o        ( rsp_ready_out ),
    .data_i         ( rsp_in        ),
    .valid_o        ( rsp_valid_out ),
    .ready_i        ( rsp_ready_in  ),
    .data_o         ( rsp_out       )
  );


  floo_router #(
    .NumPhysChannels  ( 1                         ),
    .NumVirtChannels  ( 1                         ),
    .NumRoutes        ( NumRoutes                 ),
    .flit_t           ( floo_wide_generic_flit_t  ),
    .ChannelFifoDepth ( ChannelFifoDepth          ),
    .OutputFifoDepth  ( OutputFifoDepth           ),
    .RouteAlgo        ( RouteAlgo                 ),
    .XYRouteOpt       ( XYRouteOpt                ),
    .IdWidth          ( IdWidth                   ),
    .id_t             ( id_t                      ),
    .NumAddrRules     ( NumAddrRules              ),
    .addr_rule_t      ( addr_rule_t               ),
    .Mesh             ( Mesh                      )
  ) i_wide_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i(id_i),
    .id_route_map_i,
    .valid_i        ( wide_valid_in   ),
    .ready_o        ( wide_ready_out  ),
    .data_i         ( wide_in         ),
    .valid_o        ( wide_valid_out  ),
    .ready_i        ( wide_ready_in   ),
    .data_o         ( wide_out        )
  );

endmodule