// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// perform FVADA for each possible next hop dir
module floo_vc_selection #(
  parameter int NumVC         = 4,    // = possible number of next hop directions
  parameter int NumVCWidth    = NumVC > 1 ? $clog2(NumVC) : 1,
  parameter int VCDepth       = 2,
  parameter int VCDepthWidth  = $clog2(VCDepth+1)
) (
  input logic   [NumVC-1:0][VCDepthWidth-1:0]   credit_counter_i,
  input logic   [NumVC-1:0]                     vc_selection_v_o, //for each dir, found a vc?
  output logic  [NumVC-1:0][NumVCWidth-1:0]     vc_selection_id_o //for each dir, which vc assigned?
);


logic [NumVC-1:0] vc_not_full;

for (genvar vc = 0; vc < NumVC; vc++) begin : gen_check_credit_counter
  assign vc_not_full[vc] = |credit_counter_i[vc];
end


for(genvar vc = 0; vc < NumVC; vc++) begin : gen_FVADA
  always_comb begin
    vc_selection_v_o  [vc]      = '0;
    vc_selection_id_o [vc]      = '0;
    if(vc_not_full[vc]) begin // the preferred output port vc has space
      vc_selection_v_o  [vc]    = 1'b1;
      vc_selection_id_o [vc]    = vc[NumVCWidth-1:0];
    end else begin // the preferred output port vc has no space, try other vc
      for(int o_vc = 0; o_vc < NumVC; o_vc++) begin
        if(o_vc != vc) begin
          if(vc_not_full[o_vc]) begin
            vc_selection_v_o [vc] = 1'b1;
            vc_selection_id_o[vc] = o_vc[NumVCWidth-1:0];
          end
        end
      end
    end
  end
end


endmodule
