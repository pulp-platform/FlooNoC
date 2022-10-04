// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

module floo_synth_router
  import floo_pkg::*;
  import floo_axi_flit_pkg::*;
  import floo_param_pkg::*;
(
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   test_enable_i,

  input  xy_id_t xy_id_i,

  input  req_flit_t [NumRoutes-1:0] req_i,
  input  rsp_flit_t [NumRoutes-1:0] rsp_i,
  output  req_flit_t [NumRoutes-1:0] req_o,
  output  rsp_flit_t [NumRoutes-1:0] rsp_o
);

  req_data_t [NumRoutes-1:0]    req_in, req_out;
  rsp_data_t [NumRoutes-1:0]    rsp_in, rsp_out;
  logic [NumRoutes-1:0]         req_valid_in, req_valid_out;
  logic [NumRoutes-1:0]         rsp_valid_in, rsp_valid_out;
  logic [NumRoutes-1:0]         req_ready_in, rsp_ready_in;
  logic [NumRoutes-1:0]         req_ready_out, rsp_ready_out;

  for (genvar i = 0; i < NumRoutes; i++) begin : gen_chimney_req
    assign req_o[i].data = req_out[i];
    assign rsp_o[i].data = rsp_out[i];
    assign req_in[i] = req_i[i].data;
    assign rsp_in[i] = rsp_i[i].data;
    assign req_valid_in[i] = req_i[i].valid;
    assign rsp_valid_in[i] = rsp_i[i].valid;
    assign req_ready_in[i] = req_i[i].ready;
    assign rsp_ready_in[i] = rsp_i[i].ready;
    assign req_o[i].valid = req_valid_out[i];
    assign rsp_o[i].valid = rsp_valid_out[i];
    assign req_o[i].ready = req_ready_out[i];
    assign rsp_o[i].ready = rsp_ready_out[i];
  end

  floo_router #(
    .NumPhysChannels  ( 1                   ),
    .NumVirtChannels  ( 1                   ),
    .NumRoutes        ( NumRoutes           ),
    .flit_t           ( req_generic_t       ),
    .ChannelFifoDepth ( ChannelFifoDepth    ),
    .RouteAlgo        ( XYRouting           ),
    .IdWidth          ( 4                   ),
    .id_t             ( xy_id_t             ),
    .NumAddrRules     ( 1                   )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i ('0             ),
    .valid_i        ( req_valid_in  ),
    .ready_o        ( req_ready_out ),
    .data_i         ( req_in        ),
    .valid_o        ( req_valid_out ),
    .ready_i        ( req_ready_in  ),
    .data_o         ( req_out       )
  );


  floo_router #(
    .NumPhysChannels  ( 1                 ),
    .NumVirtChannels  ( 1                 ),
    .NumRoutes        ( NumRoutes         ),
    .flit_t           ( rsp_generic_t     ),
    .ChannelFifoDepth ( ChannelFifoDepth  ),
    .RouteAlgo        ( XYRouting         ),
    .IdWidth          ( 4                 ),
    .id_t             ( xy_id_t           ),
    .NumAddrRules     ( 1                 )
  ) i_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i ('0             ),
    .valid_i        ( rsp_valid_in  ),
    .ready_o        ( rsp_ready_out ),
    .data_i         ( rsp_in        ),
    .valid_o        ( rsp_valid_out ),
    .ready_i        ( rsp_ready_in  ),
    .data_o         ( rsp_out       )
  );

endmodule
