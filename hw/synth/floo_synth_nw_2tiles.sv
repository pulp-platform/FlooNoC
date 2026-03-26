// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>
//
// This wrapper wants to simulate a floorplan with 2 tiles. It basically conenct the two routers
// west <-> east ports together. For this reason, at the interface there will be twice the number of
// ports compared to a single tile.
//
module floo_synth_nw_2tiles
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
#(
  parameter int unsigned NumPorts          = int'(floo_pkg::NumDirections),
  parameter int unsigned WideRwDecouple    = int'(floo_pkg::Phys),
  parameter int unsigned VcImpl            = int'(floo_pkg::VcNaive)
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  input  id_t id_1_i,
  input logic id_route_map_1_i,

  input  id_t id_0_i,
  input logic id_route_map_0_i,

  input  floo_req_t  [NumPorts-2:0] floo_req_1_i,
  input  floo_rsp_t  [NumPorts-2:0] floo_rsp_1_i,
  output floo_req_t  [NumPorts-2:0] floo_req_1_o,
  output floo_rsp_t  [NumPorts-2:0] floo_rsp_1_o,
  input  floo_wide_t [NumPorts-2:0] floo_wide_1_i,
  output floo_wide_t [NumPorts-2:0] floo_wide_1_o,
  input  floo_req_t  [NumPorts-2:0] floo_req_0_i,
  input  floo_rsp_t  [NumPorts-2:0] floo_rsp_0_i,
  output floo_req_t  [NumPorts-2:0] floo_req_0_o,
  output floo_rsp_t  [NumPorts-2:0] floo_rsp_0_o,
  input  floo_wide_t [NumPorts-2:0] floo_wide_0_i,
  output floo_wide_t [NumPorts-2:0] floo_wide_0_o
);

// Intermediate signals to connect the two virtual tiles
floo_req_t  [NumPorts-1:0] floo_req_1_in;
floo_rsp_t  [NumPorts-1:0] floo_rsp_1_in;
floo_req_t  [NumPorts-1:0] floo_req_1_out;
floo_rsp_t  [NumPorts-1:0] floo_rsp_1_out;
floo_wide_t [NumPorts-1:0] floo_wide_1_in;
floo_wide_t [NumPorts-1:0] floo_wide_1_out;

floo_req_t  [NumPorts-1:0] floo_req_0_in;
floo_rsp_t  [NumPorts-1:0] floo_rsp_0_in;
floo_req_t  [NumPorts-1:0] floo_req_0_out;
floo_rsp_t  [NumPorts-1:0] floo_rsp_0_out;
floo_wide_t [NumPorts-1:0] floo_wide_0_in;
floo_wide_t [NumPorts-1:0] floo_wide_0_out;

// Tile 1
for (genvar p = 0; p < NumPorts; p++) begin: gen_tile1_connect
  if (p != West) begin: gen_nes_conn
    assign floo_req_1_in[p] = floo_req_1_i[tile1_idx_map(p)];
    assign floo_rsp_1_in[p] = floo_rsp_1_i[tile1_idx_map(p)];
    assign floo_rsp_1_o[tile1_idx_map(p)] = floo_rsp_1_out[p];
    assign floo_req_1_o[tile1_idx_map(p)] = floo_req_1_out[p];

    assign floo_wide_1_in[p] = floo_wide_1_i[tile1_idx_map(p)];
    assign floo_wide_1_o[tile1_idx_map(p)] = floo_wide_1_out[p];
  end
end

// Tile 0
for (genvar p = 0; p < NumPorts; p++) begin: gen_tile0_connect
  if (p != East) begin: gen_nws_conn
    assign floo_req_0_in[p] = floo_req_0_i[tile0_idx_map(p)];
    assign floo_rsp_0_in[p] = floo_rsp_0_i[tile0_idx_map(p)];
    assign floo_rsp_0_o[tile0_idx_map(p)] = floo_rsp_0_out[p];
    assign floo_req_0_o[tile0_idx_map(p)] = floo_req_0_out[p];

    assign floo_wide_0_in[p] = floo_wide_0_i[tile0_idx_map(p)];
    assign floo_wide_0_o[tile0_idx_map(p)] = floo_wide_0_out[p];
  end
end

assign floo_req_0_in[East] = floo_req_1_out[West];
assign floo_rsp_1_in[West] = floo_rsp_0_out[East];
assign floo_req_1_in[West] = floo_req_0_out[East];
assign floo_rsp_0_in[East] = floo_rsp_1_out[West];

assign floo_wide_0_in[East] = floo_wide_1_out[West];
assign floo_wide_1_in[West] = floo_wide_0_out[East];

floo_nw_router #(
  .AxiCfgN          ( AxiCfgN                                      ),
  .AxiCfgW          ( AxiCfgW                                      ),
  .RouteAlgo        ( RouteCfg.RouteAlgo                           ),
  .NumRoutes        ( NumPorts                                      ),
  .NumAddrRules     ( 1                                            ),
  .InFifoDepth      ( InFifoDepth                                  ),
  .OutFifoDepth     ( OutFifoDepth                                 ),
  .XYRouteOpt       ( 1'b0                                         ),
  .WideRwDecouple   ( floo_pkg::wide_rw_decouple_e'(WideRwDecouple) ),
  .VcImpl           ( floo_pkg::vc_impl_e'(VcImpl)                 ),
  .NoLoopback       ( 1'b0                                         ),
  .id_t             ( id_t                                         ),
  .hdr_t            ( hdr_t                                        ),
  .floo_req_t       ( floo_req_t                                   ),
  .floo_rsp_t       ( floo_rsp_t                                   ),
  .floo_wide_t      ( floo_wide_t                                  ),
  .red_wide_req_t   ( red_wide_req_t                               ),
  .red_wide_rsp_t   ( red_wide_rsp_t                               ),
  .red_narrow_req_t ( red_narrow_req_t                             ),
  .red_narrow_rsp_t ( red_narrow_rsp_t                             )
) i_floo_nw_router1 (
  .clk_i                ( clk_i              ),
  .rst_ni               ( rst_ni             ),
  .test_enable_i        ( test_enable_i      ),
  .id_i                 ( id_1_i             ),
  .id_route_map_i       ( id_route_map_1_i   ),
  .floo_req_i           ( floo_req_1_in      ),
  .floo_rsp_i           ( floo_rsp_1_in      ),
  .floo_req_o           ( floo_req_1_out     ),
  .floo_rsp_o           ( floo_rsp_1_out     ),
  .floo_wide_i          ( floo_wide_1_in     ),
  .floo_wide_o          ( floo_wide_1_out    ),
  .offload_wide_req_o   (                    ),
  .offload_wide_rsp_i   ( '0                 ),
  .offload_narrow_req_o (                    ),
  .offload_narrow_rsp_i ( '0                 )
);

floo_nw_router #(
  .AxiCfgN          ( AxiCfgN                                      ),
  .AxiCfgW          ( AxiCfgW                                      ),
  .RouteAlgo        ( RouteCfg.RouteAlgo                           ),
  .NumRoutes        ( NumPorts                                      ),
  .NumAddrRules     ( 1                                            ),
  .InFifoDepth      ( InFifoDepth                                  ),
  .OutFifoDepth     ( OutFifoDepth                                 ),
  .XYRouteOpt       ( 1'b0                                         ),
  .WideRwDecouple   ( floo_pkg::wide_rw_decouple_e'(WideRwDecouple) ),
  .VcImpl           ( floo_pkg::vc_impl_e'(VcImpl)                 ),
  .NoLoopback       ( 1'b0                                         ),
  .id_t             ( id_t                                         ),
  .hdr_t            ( hdr_t                                        ),
  .floo_req_t       ( floo_req_t                                   ),
  .floo_rsp_t       ( floo_rsp_t                                   ),
  .floo_wide_t      ( floo_wide_t                                  ),
  .red_wide_req_t   ( red_wide_req_t                               ),
  .red_wide_rsp_t   ( red_wide_rsp_t                               ),
  .red_narrow_req_t ( red_narrow_req_t                             ),
  .red_narrow_rsp_t ( red_narrow_rsp_t                             )
) i_floo_nw_router0 (
  .clk_i                ( clk_i              ),
  .rst_ni               ( rst_ni             ),
  .test_enable_i        ( test_enable_i      ),
  .id_i                 ( id_0_i             ),
  .id_route_map_i       ( id_route_map_0_i   ),
  .floo_req_i           ( floo_req_0_in      ),
  .floo_rsp_i           ( floo_rsp_0_in      ),
  .floo_req_o           ( floo_req_0_out     ),
  .floo_rsp_o           ( floo_rsp_0_out     ),
  .floo_wide_i          ( floo_wide_0_in     ),
  .floo_wide_o          ( floo_wide_0_out    ),
  .offload_wide_req_o   (                    ),
  .offload_wide_rsp_i   ( '0                 ),
  .offload_narrow_req_o (                    ),
  .offload_narrow_rsp_i ( '0                 )
);

function automatic int tile0_idx_map(route_direction_e dir);
  case (dir)
    North: return 0;
    // East:  return 1;
    South: return 1;
    West:  return 2;
    Eject: return 3;
    default: return 0;
  endcase
endfunction

function automatic int tile1_idx_map(route_direction_e dir);
  case (dir)
    North: return 0;
    East:  return 1;
    South: return 2;
    // West:  return 2;
    Eject: return 3;
    default: return 0;
  endcase
endfunction

endmodule
