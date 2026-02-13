// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/// SA global: choose a valid VC via round-robin arbitration
module floo_sa_global #(
  parameter int NumInputs = 4
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  /// For each input: is their SA local in that dir valid
  input  logic [NumInputs-1:0]  sa_local_valid_i,
  /// Wormhole: bypass rr arbiter and use this input
  input  logic [NumInputs-1:0]  wh_sa_global_dir_oh_i,
  input  logic                  wh_valid_i,
  /// Output VC: one-hot encoding of the chosen VC
  output logic                  sa_global_valid_o,
  output logic [NumInputs-1:0]  sa_global_dir_oh_o,
  // When to update rr arbiter
  input  logic                  sent_i,
  input  logic                  update_rr_arb_i
);

  logic [NumInputs-1:0] arb_input_dir_oh;

  // pick a valid vc via rr arbitration
  floo_rr_arbiter #(
    .NumInputs  ( NumInputs )
  ) i_sa_global_rr_arbiter (
    .clk_i,
    .rst_ni,
    .req_i      ( sa_local_valid_i  ),
    .update_i   ( update_rr_arb_i   ),
    .grant_i    ( sent_i            ),
    .grant_o    ( arb_input_dir_oh  ),
    .grant_id_o (                   )
  );

  always_comb begin
    if(wh_valid_i) begin
      sa_global_dir_oh_o = wh_sa_global_dir_oh_i & sa_local_valid_i;
      sa_global_valid_o = |(wh_sa_global_dir_oh_i & sa_local_valid_i); // correct input valid
    end else begin
      sa_global_dir_oh_o = arb_input_dir_oh;
      sa_global_valid_o = |sa_local_valid_i; // any valid input -> a valid output exists
    end
  end

endmodule
