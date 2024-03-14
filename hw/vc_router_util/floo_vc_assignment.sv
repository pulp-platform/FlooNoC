// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// runs after sa global: assign precalculated vc to selected flow
module floo_vc_assignment import floo_pkg::*;#(
  parameter int NumVC         = 4,    // = possible number of next hop directions
  parameter int NumVCWidth    = NumVC > 1 ? $clog2(NumVC) : 1,
  parameter int NumInputs     = 4,
  parameter route_algo_e RouteAlgo = XYRouting,
  parameter int OutputId      = 0
) (
  input logic                                   sa_global_v_i,
  input logic   [NumInputs-1:0]                 sa_global_input_dir_oh_i,
  input route_direction_e [NumInputs-1:0]       look_ahead_routing_i,
  input logic   [NumVC-1:0]                     vc_selection_v_i, //for each dir, found a vc?
  input logic   [NumVC-1:0][NumVCWidth-1:0]     vc_selection_id_i, //for each dir which vc assigned?
  input logic                                   require_correct_vc_i,

  output logic                                  vc_assignment_v_o,
  output logic [NumVCWidth-1:0]                 vc_assignment_id_o,
  output route_direction_e                      look_ahead_routing_sel_o
);

route_direction_e look_ahead_routing_sel;
floo_mux #(
  .NumInputs(NumInputs),
  .DataWidth($bits(route_direction_e))
) i_floo_mux_select_vc_id (
  .sel_i    (sa_global_input_dir_oh_i),
  .data_i   (look_ahead_routing_i),
  .data_o   (look_ahead_routing_sel)
);
assign look_ahead_routing_sel_o = look_ahead_routing_sel;


/*
next hop direction we want: look_ahead_routing_sel
but: vc_selection inputs are by preferred vc id

mapping of dir to id is depending on dir
*/


if(NumVC == 1) begin : gen_only_one_vc
  assign vc_assignment_id_o = vc_selection_id_i;
  assign vc_assignment_v_o  = vc_selection_v_i & sa_global_v_i
        & (~require_correct_vc_i | (vc_assignment_id_o == vc_selection_v_i & sa_global_v_i));
end

if(RouteAlgo != XYRouting) begin : gen_not_xy_routing_optimized
  // since ports dont have a vc towards their own direction, calculate id
  // N->S,E->W,S->N,W->E,L1->L1,...
  // 0->2,1->3,2->0,3->1, 4-> 4,...
  localparam int InputIdOnNextRouter = OutputId < 4 ? (OutputId + 2) % 4 : OutputId;
  logic [$bits(route_direction_e)-1:0] preferred_vc_id;
  assign preferred_vc_id = look_ahead_routing_sel > InputIdOnNextRouter ?
                  look_ahead_routing_sel - 3'b001 : look_ahead_routing_sel;
  assign vc_assignment_id_o = vc_selection_id_i[preferred_vc_id];
  assign vc_assignment_v_o  = vc_selection_v_i[preferred_vc_id] & sa_global_v_i
                              & (~require_correct_vc_i | (vc_assignment_id_o == preferred_vc_id));
end

else begin : gen_xy_routing_optimized
case (OutputId)
  North: begin : gen_xy_routing_optimized_to_North
    always_comb begin
      vc_assignment_v_o = '0;
      vc_assignment_id_o = '0;
      if(sa_global_v_i) begin
        unique case(look_ahead_routing_sel)
          North: begin
            vc_assignment_id_o = vc_selection_id_i[0];
            vc_assignment_v_o  = vc_selection_v_i[0]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 0));
          end
          default: begin
            vc_assignment_id_o = vc_selection_id_i[look_ahead_routing_sel - Eject + 1];
            vc_assignment_v_o  = vc_selection_v_i[look_ahead_routing_sel - Eject + 1]
                  & (~require_correct_vc_i |
                        (vc_assignment_id_o == (look_ahead_routing_sel - Eject + 1)));
          end
        endcase
      end
    end
  end

  East: begin : gen_xy_routing_optimized_to_East
    always_comb begin
      vc_assignment_v_o = '0;
      vc_assignment_id_o = '0;
      if(sa_global_v_i) begin
        unique case(look_ahead_routing_sel)
          North: begin
            vc_assignment_id_o = vc_selection_id_i[0];
            vc_assignment_v_o  = vc_selection_v_i[0]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 0));
          end
          East: begin
            vc_assignment_id_o = vc_selection_id_i[1];
            vc_assignment_v_o  = vc_selection_v_i[1]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 1));
          end
          South: begin
            vc_assignment_id_o = vc_selection_id_i[2];
            vc_assignment_v_o  = vc_selection_v_i[2]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 2));
          end
          default: begin
            vc_assignment_id_o = vc_selection_id_i[look_ahead_routing_sel - Eject + 3];
            vc_assignment_v_o  = vc_selection_v_i[look_ahead_routing_sel - Eject + 3]
                  & (~require_correct_vc_i |
                        (vc_assignment_id_o == (look_ahead_routing_sel - Eject + 3)));
          end
        endcase
      end
    end
  end

  South: begin : gen_xy_routing_optimized_to_South
    always_comb begin
      vc_assignment_v_o = '0;
      vc_assignment_id_o = '0;
      if(sa_global_v_i) begin
        unique case(look_ahead_routing_sel)
          South: begin
            vc_assignment_id_o = vc_selection_id_i[0];
            vc_assignment_v_o  = vc_selection_v_i[0]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 0));
          end
          default: begin
            vc_assignment_id_o = vc_selection_id_i[look_ahead_routing_sel - Eject + 1];
            vc_assignment_v_o  = vc_selection_v_i[look_ahead_routing_sel - Eject + 1]
                  & (~require_correct_vc_i |
                        (vc_assignment_id_o == (look_ahead_routing_sel - Eject + 1)));
          end
        endcase
      end
    end
  end

  West: begin : gen_xy_routing_optimized_to_West
    always_comb begin
      vc_assignment_v_o = '0;
      vc_assignment_id_o = '0;
      if(sa_global_v_i) begin
        unique case(look_ahead_routing_sel)
          North: begin
            vc_assignment_id_o = vc_selection_id_i[0];
            vc_assignment_v_o  = vc_selection_v_i[0]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 0));
          end
          South: begin
            vc_assignment_id_o = vc_selection_id_i[1];
            vc_assignment_v_o  = vc_selection_v_i[1]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 1));
          end
          West: begin
            vc_assignment_id_o = vc_selection_id_i[2];
            vc_assignment_v_o  = vc_selection_v_i[2]
                  & (~require_correct_vc_i | (vc_assignment_id_o == 2));
          end
          default: begin
            vc_assignment_id_o = vc_selection_id_i[look_ahead_routing_sel - Eject + 3];
            vc_assignment_v_o  = vc_selection_v_i[look_ahead_routing_sel - Eject + 3]
                  & (~require_correct_vc_i |
                        (vc_assignment_id_o == (look_ahead_routing_sel - Eject + 3)));
          end
        endcase
      end
    end
  end

  default: begin : gen_xy_routing_optimized_to_Local
    $warning("Unimplemented!: Towards %d via port %d! Local Ports are assumed to have only one vc!",
              look_ahead_routing_sel, OutputId);
  end
endcase
end

endmodule
