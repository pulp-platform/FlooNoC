// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"

module floo_credit_counter #(
  parameter int NumVC         = 4,
  parameter int NumVCWidth    = NumVC > 1 ? $clog2(NumVC) : 1,
  parameter int NumVCWidthMax = 2,
  parameter int VCDepth       = 2,
  parameter int VCDepthWidth  = $clog2(VCDepth+1)
) (
  input logic                                     credit_v_i,
  input logic       [NumVCWidthMax-1:0]           credit_id_i,

  input logic                                     consume_credit_v_i,
  input logic       [NumVCWidthMax-1:0]           consume_credit_id_i,

  output logic      [NumVC-1:0][VCDepthWidth-1:0] credit_counter_o,

  input logic                                     clk_i,
  input logic                                     rst_ni
);

logic [NumVC-1:0][VCDepthWidth-1:0]               credit_counter_d, credit_counter_q;

for (genvar vc = 0; vc < NumVC; vc++) begin : gen_credit_counters
  always_comb begin
    credit_counter_d[vc] = credit_counter_q[vc];
    if( (credit_v_i & (credit_id_i == vc[NumVCWidth-1:0])) &
       ~(consume_credit_v_i & (consume_credit_id_i == vc[NumVCWidth-1:0])))
      credit_counter_d[vc] = credit_counter_q[vc] + 1;
    else if(~(credit_v_i & (credit_id_i == vc[NumVCWidth-1:0])) &
        (consume_credit_v_i & (consume_credit_id_i == vc[NumVCWidth-1:0])))
      credit_counter_d[vc] = credit_counter_q[vc] - 1;
    end

  `FF(credit_counter_q[vc], credit_counter_d[vc], VCDepth[VCDepthWidth-1:0])
end

assign credit_counter_o = credit_counter_q;


endmodule
