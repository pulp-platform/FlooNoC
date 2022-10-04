// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// Wrapper of a multi-link router for narrow and wide links
module floo_narrow_wide_router
  import floo_pkg::*;
  import floo_narrow_wide_flit_pkg::*;
  #(
    parameter int unsigned NumRoutes        = NumDirections,
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

  input   narrow_req_flit_t [NumRoutes-1:0] narrow_req_i,
  input   narrow_rsp_flit_t [NumRoutes-1:0] narrow_rsp_i,
  output  narrow_req_flit_t [NumRoutes-1:0] narrow_req_o,
  output  narrow_rsp_flit_t [NumRoutes-1:0] narrow_rsp_o,
  input   wide_flit_t   [NumRoutes-1:0] wide_i,
  output  wide_flit_t   [NumRoutes-1:0] wide_o
);

  narrow_req_data_t [NumRoutes-1:0] narrow_req_in, narrow_req_out;
  narrow_rsp_data_t [NumRoutes-1:0] narrow_rsp_in, narrow_rsp_out;
  logic [NumRoutes-1:0]             narrow_req_valid_in, narrow_req_valid_out;
  logic [NumRoutes-1:0]             narrow_rsp_valid_in, narrow_rsp_valid_out;
  logic [NumRoutes-1:0]             narrow_req_ready_in, narrow_rsp_ready_in;
  logic [NumRoutes-1:0]             narrow_req_ready_out, narrow_rsp_ready_out;
  wide_data_t [NumRoutes-1:0]       wide_in, wide_out;
  logic [NumRoutes-1:0]             wide_valid_in, wide_valid_out;
  logic [NumRoutes-1:0]             wide_ready_in, wide_ready_out;

  for (genvar i = 0; i < NumRoutes; i++) begin : gen_chimney_req
    assign narrow_req_o[i].data   = narrow_req_out[i];
    assign narrow_rsp_o[i].data   = narrow_rsp_out[i];
    assign narrow_req_in[i]       = narrow_req_i[i].data;
    assign narrow_rsp_in[i]       = narrow_rsp_i[i].data;
    assign narrow_req_valid_in[i] = narrow_req_i[i].valid;
    assign narrow_rsp_valid_in[i] = narrow_rsp_i[i].valid;
    assign narrow_req_ready_in[i] = narrow_req_i[i].ready;
    assign narrow_rsp_ready_in[i] = narrow_rsp_i[i].ready;
    assign narrow_req_o[i].valid  = narrow_req_valid_out[i];
    assign narrow_rsp_o[i].valid  = narrow_rsp_valid_out[i];
    assign narrow_req_o[i].ready  = narrow_req_ready_out[i];
    assign narrow_rsp_o[i].ready  = narrow_rsp_ready_out[i];
    assign wide_o[i].data         = wide_out[i];
    assign wide_in[i]             = wide_i[i].data;
    assign wide_valid_in[i]       = wide_i[i].valid;
    assign wide_ready_in[i]       = wide_i[i].ready;
    assign wide_o[i].valid        = wide_valid_out[i];
    assign wide_o[i].ready        = wide_ready_out[i];
  end



  floo_router #(
    .NumPhysChannels  ( 1                     ),
    .NumVirtChannels  ( 1                     ),
    .NumRoutes        ( NumRoutes             ),
    .flit_t           ( narrow_req_generic_t  ),
    .ChannelFifoDepth ( ChannelFifoDepth      ),
    .OutputFifoDepth  ( OutputFifoDepth       ),
    .RouteAlgo        ( RouteAlgo             ),
    .IdWidth          ( IdWidth               ),
    .id_t             ( id_t                  ),
    .NumAddrRules     ( NumAddrRules          )
  ) i_narrow_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i,
    .valid_i        ( narrow_req_valid_in  ),
    .ready_o        ( narrow_req_ready_out ),
    .data_i         ( narrow_req_in        ),
    .valid_o        ( narrow_req_valid_out ),
    .ready_i        ( narrow_req_ready_in  ),
    .data_o         ( narrow_req_out       )
  );


  floo_router #(
    .NumPhysChannels  ( 1                     ),
    .NumVirtChannels  ( 1                     ),
    .NumRoutes        ( NumRoutes             ),
    .flit_t           ( narrow_rsp_generic_t  ),
    .ChannelFifoDepth ( ChannelFifoDepth      ),
    .OutputFifoDepth  ( OutputFifoDepth       ),
    .RouteAlgo        ( RouteAlgo             ),
    .IdWidth          ( IdWidth               ),
    .id_t             ( id_t                  ),
    .NumAddrRules     ( NumAddrRules          )
  ) i_narrow_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i,
    .valid_i        ( narrow_rsp_valid_in   ),
    .ready_o        ( narrow_rsp_ready_out  ),
    .data_i         ( narrow_rsp_in         ),
    .valid_o        ( narrow_rsp_valid_out  ),
    .ready_i        ( narrow_rsp_ready_in   ),
    .data_o         ( narrow_rsp_out        )
  );


  floo_router #(
    .NumPhysChannels  ( 1                 ),
    .NumVirtChannels  ( 1                 ),
    .NumRoutes        ( NumRoutes         ),
    .flit_t           ( wide_generic_t    ),
    .ChannelFifoDepth ( ChannelFifoDepth  ),
    .OutputFifoDepth  ( OutputFifoDepth   ),
    .RouteAlgo        ( RouteAlgo         ),
    .IdWidth          ( IdWidth           ),
    .id_t             ( id_t              ),
    .NumAddrRules     ( NumAddrRules      )
  ) i_wide_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i,
    .valid_i        ( wide_valid_in   ),
    .ready_o        ( wide_ready_out  ),
    .data_i         ( wide_in         ),
    .valid_o        ( wide_valid_out  ),
    .ready_i        ( wide_ready_in   ),
    .data_o         ( wide_out        )
  );

endmodule
