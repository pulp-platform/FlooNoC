// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"

/// Simple credit counter module
module floo_credit_counter #(
  /// Number of virtual channels
  parameter int unsigned NumVC         = 32'd5,
  // Maximum number of bits to address the virtual channels
  parameter int unsigned VCIdxWidthMax = 32'd0,
  /// Number of entries in the virtual channel FIFO
  parameter int unsigned VCDepth       = 32'd2,
  /// The virtual channel to which the depth should be increased
  parameter int unsigned DeeperVCId    = 32'd0,
  /// The depth to which the virtual channel should be increased
  parameter int unsigned DeeperVCDepth = 32'd2,
  /// Number of bits to address the virtual channels
  parameter int unsigned VCIdxWidth    = cf_math_pkg::idx_width(NumVC),
  /// Number of bits to index the virtual channel FIFO
  parameter int unsigned VCDepthWidth  = $clog2(VCDepth+1)
) (
  input logic                     clk_i,
  input logic                     rst_ni,
  // Credit refill
  input logic                     credit_valid_i,
  input logic [VCIdxWidthMax-1:0] credit_id_i,
  /// Credit consumption
  input logic                     consume_credit_valid_i,
  input logic [VCIdxWidthMax-1:0] consume_credit_id_i,
  /// Credit status
  output logic  [NumVC-1:0]       vc_not_full_o
);

logic [NumVC-1:0][VCDepthWidth-1:0]               credit_cnt_d, credit_cnt_q;

for (genvar vc = 0; vc < NumVC; vc++) begin : gen_credit_cnts

  always_comb begin
    credit_cnt_d[vc] = credit_cnt_q[vc];
    if( (credit_valid_i & (credit_id_i == vc[VCIdxWidth-1:0])) &
       ~(consume_credit_valid_i & (consume_credit_id_i == vc[VCIdxWidth-1:0])))
      credit_cnt_d[vc] = credit_cnt_q[vc] + 1;
    else if(~(credit_valid_i & (credit_id_i == vc[VCIdxWidth-1:0])) &
        (consume_credit_valid_i & (consume_credit_id_i == vc[VCIdxWidth-1:0])))
      credit_cnt_d[vc] = credit_cnt_q[vc] - 1;
    end

  `FF(credit_cnt_q[vc], credit_cnt_d[vc], vc == DeeperVCId ? DeeperVCDepth : VCDepth)
end

for (genvar vc = 0; vc < NumVC; vc++) begin : gen_check_credit_cnt
  assign vc_not_full_o[vc] = |credit_cnt_q[vc];
end

endmodule
