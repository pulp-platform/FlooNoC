// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/// SA local: choose a valid VC with rr-arbitration and output direction
module floo_sa_local #(
  parameter int unsigned NumVC      = 4,
  parameter int unsigned NumPorts   = 5,
  parameter type hdr_t              = logic,
  localparam int unsigned HdrLength = $bits(hdr_t)
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  /// Input VC: one-hot encoding of valid VCs
  input  logic  [NumVC-1:0]     vc_hdr_valid_i,
  /// Input header: the headers of the VCs
  input  hdr_t  [NumVC-1:0]     vc_hdr_i,
  /// Output VC: one-hot encoding of the chosen VC
  output logic  [NumVC-1:0]     sa_local_vc_id_oh_o,
  /// Output header: the chosen header
  output hdr_t                  sa_local_sel_hdr_o,
  /// Output direction: one-hot encoding of the chosen output port
  output logic  [NumPorts-1:0]  sa_local_output_dir_oh_o,
  // When to update round-robin arbiter
  input  logic                  sent_i,
  input  logic                  update_rr_arb_i
);

// Pick a valid vc via rr arbitration
  floo_rr_arbiter #(
    .NumInputs  ( NumVC )
  ) i_sa_local_rr_arbiter (
    .clk_i,
    .rst_ni,
    .req_i      ( vc_hdr_valid_i      ),
    .update_i   ( update_rr_arb_i     ),
    .grant_i    ( sent_i              ),
    .grant_o    ( sa_local_vc_id_oh_o ),
    .grant_id_o (                     )
  );


  floo_mux #(
    .NumInputs  ( NumVC     ),
    .DataWidth  ( HdrLength )
  ) i_floo_mux_select_head (
    .sel_i  ( sa_local_vc_id_oh_o ),
    .data_i ( vc_hdr_i            ),
    .data_o ( sa_local_sel_hdr_o  )
  );

  // Set bit corresponding to correct direction in sa_local_output_dir_oh_o to 1 if a vc was chosen
  always_comb begin
    sa_local_output_dir_oh_o = '0;
    sa_local_output_dir_oh_o[sa_local_sel_hdr_o.lookahead] = |vc_hdr_valid_i;
  end

endmodule
