<%!
    import datetime
    from floogen.utils import snake_to_camel, bool_to_sv
    from floogen.model.routing import XYDirections
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module floo_${noc.name}_tile
  import floo_pkg::*;
  import floo_${noc.name}_noc_pkg::*;
#(
  parameter logic EnSbrPort = 1'b1,
  parameter logic EnMgrPort = 1'b1
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  // XY coordinate input
  input  id_t id_i,

  // AXI ports
<% in_prot = next((prot for prot in noc.protocols if prot.direction == "input"), None) %>\
<% out_prot = next((prot for prot in noc.protocols if prot.direction == "output"), None) %>\
% if in_prot is not None:
  input  ${in_prot.type_name()}_req_t axi_in_req_i,
  output ${in_prot.type_name()}_rsp_t axi_in_rsp_o,
% endif
% if out_prot is not None:
  output ${out_prot.type_name()}_req_t axi_out_req_o,
  input  ${out_prot.type_name()}_rsp_t axi_out_rsp_i,
% endif

  // Router links to neighbors (directly exposed)
  // North
  output floo_req_t floo_north_req_o,
  output floo_rsp_t floo_north_rsp_o,
  input  floo_req_t floo_north_req_i,
  input  floo_rsp_t floo_north_rsp_i,
  // East
  output floo_req_t floo_east_req_o,
  output floo_rsp_t floo_east_rsp_o,
  input  floo_req_t floo_east_req_i,
  input  floo_rsp_t floo_east_rsp_i,
  // South
  output floo_req_t floo_south_req_o,
  output floo_rsp_t floo_south_rsp_o,
  input  floo_req_t floo_south_req_i,
  input  floo_rsp_t floo_south_rsp_i,
  // West
  output floo_req_t floo_west_req_o,
  output floo_rsp_t floo_west_rsp_o,
  input  floo_req_t floo_west_req_i,
  input  floo_rsp_t floo_west_rsp_i
);

  // Internal links between chimney and router (Eject direction)
  floo_req_t chimney_to_router_req;
  floo_rsp_t router_to_chimney_rsp;
  floo_req_t router_to_chimney_req;
  floo_rsp_t chimney_to_router_rsp;

  // Router internal signals
  floo_req_t [4:0] router_req_in;
  floo_rsp_t [4:0] router_rsp_out;
  floo_req_t [4:0] router_req_out;
  floo_rsp_t [4:0] router_rsp_in;

  // Router input assignments (from neighbors and chimney)
  // Direction mapping: North=0, East=1, South=2, West=3, Eject=4
  assign router_req_in[0] = floo_north_req_i;  // North
  assign router_req_in[1] = floo_east_req_i;   // East
  assign router_req_in[2] = floo_south_req_i;  // South
  assign router_req_in[3] = floo_west_req_i;   // West
  assign router_req_in[4] = chimney_to_router_req;  // Eject (from local chimney)

  assign router_rsp_in[0] = floo_north_rsp_i;  // North
  assign router_rsp_in[1] = floo_east_rsp_i;   // East
  assign router_rsp_in[2] = floo_south_rsp_i;  // South
  assign router_rsp_in[3] = floo_west_rsp_i;   // West
  assign router_rsp_in[4] = chimney_to_router_rsp;  // Eject (from local chimney)

  // Router output assignments (to neighbors and chimney)
  assign floo_north_req_o = router_req_out[0];  // North
  assign floo_east_req_o  = router_req_out[1];  // East
  assign floo_south_req_o = router_req_out[2];  // South
  assign floo_west_req_o  = router_req_out[3];  // West
  assign router_to_chimney_req = router_req_out[4];  // Eject (to local chimney)

  assign floo_north_rsp_o = router_rsp_out[0];  // North
  assign floo_east_rsp_o  = router_rsp_out[1];  // East
  assign floo_south_rsp_o = router_rsp_out[2];  // South
  assign floo_west_rsp_o  = router_rsp_out[3];  // West
  assign router_to_chimney_rsp = router_rsp_out[4];  // Eject (to local chimney)

  // Router instantiation
  floo_axi_router #(
    .AxiCfg      ( AxiCfg     ),
    .RouteAlgo   ( RouteAlgo  ),
    .NumRoutes   ( 5          ),
    .NumInputs   ( 5          ),
    .NumOutputs  ( 5          ),
    .InFifoDepth ( 2          ),
    .OutFifoDepth( 2          ),
    .id_t        ( id_t       ),
    .hdr_t       ( hdr_t      ),
    .floo_req_t  ( floo_req_t ),
    .floo_rsp_t  ( floo_rsp_t )
  ) i_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .id_i           ( id_i          ),
    .id_route_map_i ( '0            ),
    .floo_req_i     ( router_req_in ),
    .floo_rsp_o     ( router_rsp_out),
    .floo_req_o     ( router_req_out),
    .floo_rsp_i     ( router_rsp_in )
  );

  // Chimney (Network Interface) instantiation
  floo_axi_chimney #(
    .AxiCfg       ( AxiCfg                                    ),
    .ChimneyCfg   ( set_ports(ChimneyDefaultCfg, EnSbrPort, EnMgrPort) ),
    .RouteCfg     ( RouteCfg                                  ),
    .id_t         ( id_t                                      ),
    .rob_idx_t    ( rob_idx_t                                 ),
    .hdr_t        ( hdr_t                                     ),
    .sam_rule_t   ( sam_rule_t                                ),
    .Sam          ( Sam                                       ),
    .axi_in_req_t ( ${in_prot.type_name()}_req_t              ),
    .axi_in_rsp_t ( ${in_prot.type_name()}_rsp_t              ),
    .axi_out_req_t( ${out_prot.type_name()}_req_t             ),
    .axi_out_rsp_t( ${out_prot.type_name()}_rsp_t             ),
    .floo_req_t   ( floo_req_t                                ),
    .floo_rsp_t   ( floo_rsp_t                                )
  ) i_chimney (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .sram_cfg_i    ( '0                    ),
    .axi_in_req_i  ( axi_in_req_i          ),
    .axi_in_rsp_o  ( axi_in_rsp_o          ),
    .axi_out_req_o ( axi_out_req_o         ),
    .axi_out_rsp_i ( axi_out_rsp_i         ),
    .id_i          ( id_i                  ),
    .route_table_i ( '0                    ),
    .floo_req_o    ( chimney_to_router_req ),
    .floo_rsp_i    ( router_to_chimney_rsp ),
    .floo_req_i    ( router_to_chimney_req ),
    .floo_rsp_o    ( chimney_to_router_rsp )
  );

endmodule
