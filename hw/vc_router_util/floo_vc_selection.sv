// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// perform FVADA for each possible next hop dir
module floo_vc_selection #(
  parameter int NumVC         = 4,    // = possible number of next hop directions
  parameter int NumVCWidth    = NumVC > 1 ? $clog2(NumVC) : 1,
  parameter int NumVCWidthMax = 2,    // in order to pad if necessary
  parameter int VCDepth       = 2,
  parameter int AllowVCOverflow = 1,  // 1: FVADA, 0: fixed VC assignment
  parameter int VCDepthWidth  = $clog2(VCDepth+1),
  parameter int AllowOverflowFromDeeperVC = 0,
  parameter int DeeperVCId    = 0
) (
  input logic   [NumVC-1:0]                     vc_not_full_i,
  output logic  [NumVC-1:0]                     vc_selection_v_o, //for each dir, found a vc?
  output logic  [NumVC-1:0][NumVCWidthMax-1:0]  vc_selection_id_o //for each dir, which vc assigned?
);

for(genvar vc = 0; vc < NumVC; vc++) begin : gen_FVADA
  always_comb begin
    vc_selection_v_o  [vc]      = '0;
    vc_selection_id_o [vc]      = '0;
    if(vc_not_full_i[vc]) begin // the preferred output port vc has space
      vc_selection_v_o  [vc]    = 1'b1;
      vc_selection_id_o [vc]    = {{(NumVCWidthMax - NumVCWidth){1'b0}},vc[NumVCWidth-1:0]};
    end else begin // the preferred output port vc has no space, try other vc
      if(AllowVCOverflow && (AllowOverflowFromDeeperVC || vc != DeeperVCId)) begin
        for(int o_vc = 0; o_vc < NumVC; o_vc++) begin
          if(o_vc != vc) begin
            if(vc_not_full_i[o_vc]) begin
              vc_selection_v_o [vc] = 1'b1;
              vc_selection_id_o[vc] = {{(NumVCWidthMax - NumVCWidth){1'b0}},o_vc[NumVCWidth-1:0]};
            end
          end
        end
      end
    end
  end
end


endmodule
