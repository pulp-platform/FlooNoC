// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// sa local: choose a valid vc via rr arbitration
module floo_look_ahead_routing #(
  parameter int           NumRoutes         = 0,
  parameter route_algo_e  RouteAlgo         = IdTable,
  parameter int           IdWidth           = 0,
  parameter int           RouteDirWidth     = $bits(route_dir_e),
  parameter type          id_t              = logic[IdWidth-1:0],
  parameter int           NumAddrRules      = 0,
  parameter type          addr_rule_t       = logic
)(
  input   hdr_t                               vc_ctrl_head_i,
  output  route_dir_e                         look_ahead_routing_o,

  input   addr_rule_t [NumAddrRules-1:0]      id_route_map_i,

  input   id_t                                xy_id_i,

  input   logic                               clk_i,
  input   logic                               rst_ni
);
  typedef struct packed {
    hdr_t hdr;
  } empty_flit_t;
  empty_flit_t helper_flit_in; // the synthesizer should not synthesize the unused fields
  id_t xy_id_nxt;
  logic [NumRoutes-1:0] look_ahead_routing_oh;
  logic [RouteDirWidth-1:0][NumRoutes-1:0] id_mask;


  // if(xy_id_i == vc_ctrl_head_i.hdr.dst_id) begin : gen_no_lookahead_towards_local
  //   assign look_ahead_routing_o = '0;
  // end

  // calculate next address:
  always_comb begin : gen_calculate_next_id
    xy_id_nxt.x = xy_id_i.x;
    xy_id_nxt.y = xy_id_i.y;
    unique case(vc_ctrl_head_i.look_ahead_routing)
      North: begin
        xy_id_nxt.y = xy_id_i.y + 1;
      end
      South: begin
        xy_id_nxt.y = xy_id_i.y - 1;
      end
      East: begin
        xy_id_nxt.x = xy_id_i.x + 1;
      end
      West: begin
        xy_id_nxt.x = xy_id_i.x - 1;
      end
      default: begin
      end
    endcase
  end

  assign helper_flit.hdr.dst_id = vc_ctrl_head_i.dst_id;
  assign helper_flit.hdr.dst_port_id= vc_ctrl_head_i.dst_port_id;

  floo_route_select #(
    .NumRoutes    (NumOutput),
    .flit_t       (empty_flit_t),
    .RouteAlgo,
    .LockRouting  (0),  //since used for lookahead, this does not make sence
    .IdWidth,
    .id_t,
    .NumAddrRules,
    .ReturnIndex  (1),
    .ReturnOneHot (0),
    .UsePortId    (1),
    .addr_rule_t
    ) i_route_select (
    .clk_i,
    .rst_ni,
    .test_enable_i  ('0),

    .xy_id_i        (xy_id_nxt),
    .id_route_map_i (id_route_map_i),
    .channel_i      (helper_flit_in),
    .valid_i        ('0),
    .ready_i        ('0),
    .channel_o      (), // we dont even know if this route is taken, cant change anything in header
    .route_sel_o    (),
    .route_sel_id_o (look_ahead_routing_id_o)
  );


endmodule
