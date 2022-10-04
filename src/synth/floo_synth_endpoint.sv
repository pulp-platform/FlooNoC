// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_endpoint
  import floo_pkg::*;
  import floo_axi_flit_pkg::*;
  import floo_param_pkg::*;
(
  input  logic      clk_i,
  input  logic      rst_ni,
  input  logic      test_enable_i,
  input  axi_in_req_t  axi_in_req_i,
  output axi_in_resp_t axi_in_rsp_o,
  output axi_out_req_t  axi_out_req_o,
  input  axi_out_resp_t axi_out_rsp_i,
  input  xy_id_t    xy_id_i,
  output  req_flit_t [NumRoutes-1:1] req_o,
  output  rsp_flit_t [NumRoutes-1:1] rsp_o,
  input  req_flit_t [NumRoutes-1:1]  req_i,
  input  rsp_flit_t [NumRoutes-1:1]  rsp_i
);

  req_flit_t                    chimney_req_in, chimney_req_out;
  rsp_flit_t                    chimney_rsp_in, chimney_rsp_out;
  req_data_t [NumRoutes-1:1]    req_in, req_out;
  rsp_data_t [NumRoutes-1:1]    rsp_in, rsp_out;
  logic [NumRoutes-1:1]         req_valid_in, req_valid_out;
  logic [NumRoutes-1:1]         rsp_valid_in, rsp_valid_out;
  logic [NumRoutes-1:1]         req_ready_in, rsp_ready_in;
  logic [NumRoutes-1:1]         req_ready_out, rsp_ready_out;


  for (genvar i = 1; i < NumRoutes; i++) begin : gen_chimney_req
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

  floo_axi_chimney #(
    .RouteAlgo          ( floo_pkg::XYRouting ),
    .XYAddrOffsetX      ( 32'd16              ),
    .XYAddrOffsetY      ( 32'd20              ),
    .MaxTxnsPerId       ( MaxTxnsPerId        ),
    .ReorderBufferSize  ( ReorderBufferSize   ),
    .xy_id_t            ( xy_id_t             ),
    .CutAx              ( CutAx               ),
    .CutRsp             ( CutRsp              )
  ) i_floo_axi_chimney (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .axi_in_req_i,
    .axi_in_rsp_o,
    .axi_out_req_o,
    .axi_out_rsp_i,
    .id_i('0),
    .xy_id_i,
    .req_o(chimney_req_out),
    .rsp_o(chimney_rsp_out),
    .req_i(chimney_req_in),
    .rsp_i(chimney_rsp_in)
  );

  floo_router #(
    .NumPhysChannels  ( 1                 ),
    .NumVirtChannels  ( 1                 ),
    .NumRoutes        ( NumRoutes         ),
    .flit_t           ( req_generic_t     ),
    .ChannelFifoDepth ( ChannelFifoDepth  ),
    .RouteAlgo        ( XYRouting         ),
    .IdWidth          ( 4                 ),
    .id_t             ( xy_id_t           ),
    .NumAddrRules     ( 1                 )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i,
    .id_route_map_i ('0                                     ),
    .valid_i        ( {req_valid_in, chimney_req_out.valid} ),
    .ready_o        ( {req_ready_out, chimney_req_in.ready} ),
    .data_i         ( {req_in, chimney_req_out.data}        ),
    .valid_o        ( {req_valid_out, chimney_req_in.valid} ),
    .ready_i        ( {req_ready_in, chimney_req_out.ready} ),
    .data_o         ( {req_out, chimney_req_in.data}        )
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
    .id_route_map_i ('0                                     ),
    .valid_i        ( {rsp_valid_in, chimney_rsp_out.valid} ),
    .ready_o        ( {rsp_ready_out, chimney_rsp_in.ready} ),
    .data_i         ( {rsp_in, chimney_rsp_out.data}        ),
    .valid_o        ( {rsp_valid_out, chimney_rsp_in.valid} ),
    .ready_i        ( {rsp_ready_in, chimney_rsp_out.ready} ),
    .data_o         ( {rsp_out, chimney_rsp_in.data}        )
  );

endmodule
