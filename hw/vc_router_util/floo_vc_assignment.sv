// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// runs after sa global: assign precalculated vc to selected flow
module floo_vc_assignment import floo_pkg::*;#(
  parameter int NumVC         = 4,    // = possible number of next hop directions
  parameter int NumVCWidth    = NumVC > 1 ? $clog2(NumVC) : 1,
  parameter int NumVCWidthMax = 2,
  parameter int NumInputs     = 4,
  parameter route_algo_e RouteAlgo = XYRouting,
  parameter int OutputId      = 0
) (
  input logic                                   sa_global_v_i,
  input logic   [NumInputs-1:0]                 sa_global_input_dir_oh_i,
  input route_direction_e [NumInputs-1:0]       look_ahead_routing_i,
  input logic   [NumVC-1:0]                     vc_selection_v_i, //for each dir, found a vc?
  input logic   [NumVC-1:0][NumVCWidthMax-1:0]  vc_selection_id_i, //for each dir which vc assigned?
  input logic                                   require_correct_vc_i,
  input logic                                   credit_v_i,
  input logic   [NumVCWidthMax-1:0]             credit_id_i,

  output logic                                  vc_assignment_v_o,
  output logic [NumVCWidthMax-1:0]              vc_assignment_id_o,
  output route_direction_e                      look_ahead_routing_sel_o
);
logic [$bits(route_direction_e)-1:0] preferred_vc_id;

// handle size differences
logic [NumVCWidth-1:0]              vc_assignment_id;
logic [NumVC-1:0][NumVCWidth-1:0]   vc_selection_id;
if(NumVCWidth == NumVCWidthMax) begin : gen_width_is_max
  assign vc_selection_id = vc_selection_id_i;
  assign vc_assignment_id_o = vc_assignment_id;
end else begin : gen_width_is_not_max
  for(genvar vc = 0; vc < NumVC; vc++) begin : gen_width_not_max_vc
    assign vc_selection_id[vc] = vc_selection_id_i[vc][NumVCWidth-1:0];
  end
  assign vc_assignment_id_o = {{(NumVCWidthMax-NumVCWidth){1'b0}},vc_assignment_id};
end

logic [$bits(route_direction_e)-1:0] look_ahead_routing_sel;
floo_mux #(
  .NumInputs(NumInputs),
  .DataWidth($bits(route_direction_e))
) i_floo_mux_select_vc_id (
  .sel_i    (sa_global_input_dir_oh_i),
  .data_i   (look_ahead_routing_i),
  .data_o   (look_ahead_routing_sel)
);
assign look_ahead_routing_sel_o = route_direction_e'(look_ahead_routing_sel);


/*
next hop direction we want: look_ahead_routing_sel
but: vc_selection inputs are by preferred vc id

mapping of dir to id is depending on dir
*/


if(NumVC == 1) begin : gen_only_one_vc
  assign vc_assignment_id = vc_selection_id;
  assign vc_assignment_v_o  = vc_selection_v_i & sa_global_v_i;
end else begin : gen_multiple_vcs

  if(RouteAlgo != XYRouting) begin : gen_not_xy_routing_optimized
    // since ports dont have a vc towards their own direction, calculate id
    // N->S,E->W,S->N,W->E,L1->L1,...
    // 0->2,1->3,2->0,3->1, 4-> 4,...
    localparam int InputIdOnNextRouter = OutputId < 4 ? (OutputId + 2) % 4 : OutputId;
    assign preferred_vc_id = look_ahead_routing_sel > InputIdOnNextRouter ?
                    look_ahead_routing_sel - 3'b001 : look_ahead_routing_sel;
  end
  else begin : gen_xy_routing_optimized
    // N: N,Ej, E: N,E,S,Ej, S: S,Ej, W: N,S,W,Ej
    assign preferred_vc_id = (NumVCWidth)'(OutputId >= Eject ? 0 :
          look_ahead_routing_sel >= Eject ?
            (OutputId==North || OutputId==South ? look_ahead_routing_sel - Eject + 1 :
                                                  look_ahead_routing_sel - Eject + 3) :
            OutputId==North || OutputId==South ? 0 :
            look_ahead_routing_sel==North ? 0 :
            look_ahead_routing_sel==South ? (OutputId==East ? 2 : 1) :
            OutputId==East ? 1 : 2);
  end

  always_comb begin
    vc_assignment_v_o = '0;
    vc_assignment_id = '0;
    if(sa_global_v_i) begin
      if(credit_v_i && credit_id_i == preferred_vc_id) begin : credit_shortcut
        vc_assignment_id = preferred_vc_id[NumVCWidth-1:0];
        vc_assignment_v_o = 1'b1;
      end else begin
        vc_assignment_id = vc_selection_id[preferred_vc_id];
        vc_assignment_v_o  = vc_selection_v_i[preferred_vc_id]
              & (~require_correct_vc_i | (vc_assignment_id == preferred_vc_id));
      end
    end
  end
end



endmodule
