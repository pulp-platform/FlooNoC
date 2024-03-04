// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// sa local: choose a valid vc via rr arbitration
module floo_sa_global #(
  parameter int NumInputs = 4,
  parameter int NumVCWidth = 2,
  parameter int NumPorts = 5
) (
  // for each input: is their sa local in that dir valid
  input  logic [NumInputs-1:0]                  sa_local_v_i,
  input  logic [NumInputs-1:0][NumVCWidth-1:0]  sa_local_vc_id_i,

  output logic                              sa_global_v_o,
  output logic [NumPorts-1:0]               sa_global_input_dir_oh_o,
  output logic [VC_ID_NUM_MAX_W-1:0]        sa_global_input_vc_id_o,

  // when to update rr arbiter
  input  logic                              update_rr_arb_i,

  input  logic                              clk_i,
  input  logic                              rst_ni
);

// pick a valid vc via rr arbitration
floo_rr_arbiter #(
  .NumInputs,
) i_sa_global_rr_arbiter (
  .req_i            (sa_local_v_i),
  .update_i         (update_rr_arb_i),
  .grant_o          (sa_global_input_dir_oh_o),
  .grant_id_o       ( ),
  .rst_ni,
  .clk_i
);

assign sa_global_v_o = |sa_local_v_i; // any valid input -> a valid output exists

// get id of selected input vc
floo_mux #(
  .NumInputs,
  .DataWidth(NumVCWidth)
) i_floo_mux_select_vc_id (
  .sel_i    (sa_global_input_dir_oh_o),
  .data_i   (sa_local_vc_id_i),
  .data_o   (sa_global_input_vc_id_o)
);

endmodule
