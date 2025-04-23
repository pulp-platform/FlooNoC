// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

/// This module returns the bits of the input data that are set in the mask.
/// For instance, if the mask is `4'b1010` and the input data is `4'b1101`, the output
/// will be `2'b10` (the first and third bits of the input data).
module floo_mask_extract #(
  /// The width of the mask and the input data
  parameter int unsigned MaskWidth = 1,
  /// The mask/input type
  parameter type in_t = logic [MaskWidth-1:0],
  /// The resulting output type, typically `logic[$countones(Mask)-1:0]`
  parameter type out_t = logic,
  /// The mask to select the bits that should be extracted
  parameter in_t Mask = '0
) (
  input in_t data_i,
  output out_t data_o
);

  always_comb begin : gen_mask_extract
    automatic int incr = 0;
    for (int i = 0; i < MaskWidth; i++) begin
      if (Mask[i]) begin
        data_o[incr] = data_i[i];
        incr++;
      end
    end
  end

  // Assert that the output width is equal to the number of bits set in the mask
  `ASSERT_INIT(CountOnes, $countones(Mask) == $bits(out_t),
      "Number of bits set in the mask and output width don't match")

endmodule
