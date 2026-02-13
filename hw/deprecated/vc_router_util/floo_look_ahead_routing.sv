// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/// Look-ahead routing computation module
module floo_look_ahead_routing
  import floo_pkg::*;
#(
  /// Number of routes
  parameter int unsigned NumRoutes      = 0,
  /// Route algorithm
  parameter route_algo_e RouteAlgo      = IdTable,
  /// Src/Dst Id Width
  parameter int unsigned IdWidth        = 0,
  /// Src/Dst Id type
  parameter type id_t                   = logic[IdWidth-1:0],
  /// Number of address rules
  parameter int unsigned NumAddrRules   = 0,
  /// Address rule type
  parameter type addr_rule_t            = logic,
  /// Header Type
  parameter type hdr_t                  = logic
)(
  input   logic                               clk_i,
  input   logic                               rst_ni,
  /// Route map for `IdTable` based routing
  input   addr_rule_t [NumAddrRules-1:0]      id_route_map_i,
  /// Current XY address
  input   id_t                                xy_id_i,
  /// Input header
  input   hdr_t                               hdr_i,
  /// Output header
  output  hdr_t                               hdr_o,
  /// Computed output direction
  output  route_direction_e                   la_route_o
);
  typedef struct packed {
    hdr_t hdr;
  } dummy_flit_t;

  dummy_flit_t dummy_flit_in;
  dummy_flit_t dummy_flit_out;
  id_t id_nxt;
  logic [$clog2(NumRoutes)-1:0] route_sel;

  // Calculate next address:
  always_comb begin : gen_calculate_next_id
    id_nxt.x = xy_id_i.x;
    id_nxt.y = xy_id_i.y;
    unique case(hdr_i.lookahead)
      North: begin
        id_nxt.y = xy_id_i.y + 1;
      end
      South: begin
        id_nxt.y = xy_id_i.y - 1;
      end
      East: begin
        id_nxt.x = xy_id_i.x + 1;
      end
      West: begin
        id_nxt.x = xy_id_i.x - 1;
      end
      default: begin
      end
    endcase
  end

  assign dummy_flit_in.hdr.dst_id = hdr_i.dst_id;

  floo_route_select #(
    .NumRoutes    ( NumRoutes     ),
    .flit_t       ( dummy_flit_t  ),
    .RouteAlgo    ( RouteAlgo     ),
    .LockRouting  ( 0             ),
    .id_t         ( id_t          ),
    .NumAddrRules ( NumAddrRules  ),
    .addr_rule_t  ( addr_rule_t   )
  ) i_route_select (
    .clk_i,
    .rst_ni,
    .test_enable_i    ( '0              ),
    .xy_id_i          ( id_nxt          ),
    .id_route_map_i   ( id_route_map_i  ),
    .channel_i        ( dummy_flit_in   ),
    .valid_i          ( '0              ),
    .ready_i          ( '0              ),
    .channel_o        ( dummy_flit_out  ),
    .route_sel_o      (                 ),
    .route_sel_id_o   ( route_sel       )
  );

  assign la_route_o = route_direction_e'(route_sel);

  if(RouteAlgo == SourceRouting) begin : gen_source_routing
    always_comb begin
      hdr_o = hdr_i;
      hdr_o.dst_id = dummy_flit_out.hdr.dst_id;
    end
  end
  else begin : gen_other_routing
    assign hdr_o = hdr_i;
  end

endmodule
