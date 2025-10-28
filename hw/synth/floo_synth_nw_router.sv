// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_nw_router
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
#(
  parameter int unsigned NumPorts = int'(floo_pkg::NumDirections)
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  input  id_t id_i,
  input logic id_route_map_i,

  input  floo_req_t [NumPorts-1:0] floo_req_i,
  input  floo_rsp_t [NumPorts-1:0] floo_rsp_i,
  output floo_req_t [NumPorts-1:0] floo_req_o,
  output floo_rsp_t [NumPorts-1:0] floo_rsp_o,
  input  floo_wide_t [NumPorts-1:0] floo_wide_i,
  output floo_wide_t [NumPorts-1:0] floo_wide_o
);

  floo_nw_router #(
    .AxiCfgN      ( AxiCfgN             ),
    .AxiCfgW      ( AxiCfgW             ),
    .RouteAlgo    ( RouteCfg.RouteAlgo  ),
    .NumRoutes    ( NumPorts            ),
    .NumAddrRules ( 1                   ),
    .InFifoDepth  ( InFifoDepth         ),
    .OutFifoDepth ( OutFifoDepth        ),
    .XYRouteOpt   ( 1'b0                ),
    .id_t         ( id_t                ),
    .hdr_t        ( hdr_t               ),
    .floo_req_t   ( floo_req_t          ),
    .floo_rsp_t   ( floo_rsp_t          ),
    .floo_wide_t  ( floo_wide_t         )
  ) i_floo_nw_router (
    .clk_i          ( clk_i           ),
    .rst_ni         ( rst_ni          ),
    .test_enable_i  ( test_enable_i   ),
    .id_i           ( id_i            ),
    .id_route_map_i ( id_route_map_i  ),
    .floo_req_i     ( floo_req_i      ),
    .floo_rsp_i     ( floo_rsp_i      ),
    .floo_req_o     ( floo_req_o      ),
    .floo_rsp_o     ( floo_rsp_o      ),
    .floo_wide_i    ( floo_wide_i     ),
    .floo_wide_o    ( floo_wide_o     )
  );

endmodule
