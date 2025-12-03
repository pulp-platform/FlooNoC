// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/// A simple one-hot encoded multiplexer
module floo_mux #(
  parameter int unsigned NumInputs = 0,
  parameter int unsigned DataWidth = 0,
  // Derived parameters
  localparam int unsigned InIdxWidth = cf_math_pkg::idx_width(NumInputs)
) (
  input  logic[NumInputs-1:0][DataWidth-1:0]  data_i,
  input  logic[NumInputs-1:0]                 sel_i,
  output logic[DataWidth-1:0]                 data_o
);

  logic [InIdxWidth-1:0] sel_idx;

  onehot_to_bin #(
    .ONEHOT_WIDTH ( NumInputs ),
    .BIN_WIDTH    ( InIdxWidth )
  ) i_onehot_to_bin (
    .onehot ( sel_i   ),
    .bin    ( sel_idx )
  );

  assign data_o = data_i[sel_idx];

endmodule
