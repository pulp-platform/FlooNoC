// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// sa local: choose a valid vc via rr arbitration
module floo_sa_local #(
  parameter int NumVC = 4,
  parameter int NumVCWidth = NumVC > 1 ? $clog2(NumVC) : 1,
  parameter int NumPorts = 5,
  parameter type hdr_t   = logic,
  parameter int HdrLength= $bits(hdr_t)
) (
  input  logic      [NumVC-1:0]         vc_ctrl_head_v_i,
  input  hdr_t      [NumVC-1:0]         vc_ctrl_head_i,

  output logic      [NumVCWidth-1:0]    sa_local_vc_id_o, // chosen id
  output logic      [NumVC-1:0]         sa_local_vc_id_oh_o,
  output hdr_t                          sa_local_sel_ctrl_head_o,

  output logic      [NumPorts-1:0]      sa_local_output_dir_oh_o, //chosen output: all 0 if none

  // when to update rr arbiter
  input logic                           update_rr_arb_i,

  input  logic                          clk_i,
  input  logic                          rst_ni
);

logic update_rr_arb;
// wormhole routing: dont update if not last
assign update_rr_arb = update_rr_arb_i & sa_local_sel_ctrl_head_o.last;
logic sa_local_v;

localparam int OptimalWidth = NumVC > 1 ? $clog2(NumVC) : 1;
// pick a valid vc via rr arbitration
floo_rr_arbiter #(
  .NumInputs        (NumVC)
) i_sa_local_rr_arbiter (
  .req_i            (vc_ctrl_head_v_i ),
  .update_i         (update_rr_arb),
  .grant_o          (sa_local_vc_id_oh_o),
  .grant_id_o       (sa_local_vc_id_o[OptimalWidth-1:0]),
  .rst_ni,
  .clk_i
);
if(OptimalWidth > NumVCWidth)
  assign sa_local_vc_id_o[NumVCWidth-1:OptimalWidth] = '0;


  floo_mux #(
    .NumInputs        (NumVC),
    .DataWidth        (HdrLength)
    ) i_floo_mux_select_head (
      .sel_i            (sa_local_vc_id_oh_o),
      .data_i           (vc_ctrl_head_i),
      .data_o           (sa_local_sel_ctrl_head_o)
      );

// set bit corresponding to correct direction in sa_local_output_dir_oh_o to 1 if a vc was chosen
always_comb begin
  sa_local_output_dir_oh_o = '0;
  sa_local_v = |vc_ctrl_head_v_i; //if any vc is valid, a vc will be chosen
  sa_local_output_dir_oh_o[sa_local_sel_ctrl_head_o.lookahead] = sa_local_v;
end

/*
// Other way of setting correct bit:
// might be faster since output_dir_per_vc can be calculated before rr arbitration is done

logic     [NumVC-1:0][NumPorts-1:0]           output_dir_per_vc;

for(genvar i = 0; i < NumPorts; i++) begin
  assign sa_local_output_dir_oh_o[i] = vc_ctrl_head_v_i[sa_local_vc_id_o] &
                                          output_dir_per_vc[sa_local_vc_id_o][i];
end

for(genvar i = 0; i < NumVC; i++) begin:
  for(genvar j = 0; j < NumPorts; j++) begin:
    assign output_dir_per_vc[i][j] =
                                vc_ctrl_head_i[i].lookahead == j[$bits(route_dir_e)-1:0];
  end
end
*/


endmodule
