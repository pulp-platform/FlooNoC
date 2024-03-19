// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// a simple one-hot encoded multiplexer
module floo_mux #(
  parameter int unsigned NumInputs = 2,
  parameter int unsigned DataWidth = 1
) (
  input logic[NumInputs-1:0] sel_i,
  input logic[NumInputs-1:0][DataWidth-1:0] data_i,
  output logic[DataWidth-1:0] data_o
);

  logic[DataWidth-1:0][NumInputs-1:0] transposed_data;

  for(genvar i = 0 ; i < DataWidth; i++) begin : gen_transpose_DataWidth
    for(genvar j = 0 ; j < NumInputs; j++) begin : gen_transpose_NumInputs
      assign transposed_data[i][j] = data_i[j][i];
    end
  end

  for(genvar i = 0; i < DataWidth; i++) begin : gen_select_data
    assign data_o[i] = |(transposed_data[i] & sel_i);
  end

endmodule
