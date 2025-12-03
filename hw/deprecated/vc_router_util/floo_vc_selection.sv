// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/// Perform FVADA for each possible next hop dir
module floo_vc_selection #(
  /// Possible number of next hop directions
  parameter int unsigned NumVC                      = 4,
  /// Width of the VC index
  parameter int unsigned NumVCWidth                 = cf_math_pkg::idx_width(NumVC),
  /// Zero-padding if necessary
  parameter int unsigned NumVCWidthMax              = 2,
  /// Allow VC overflow, 1: FVADA, 0: fixed VC assignment
  parameter int unsigned AllowVCOverflow            = 1,
  /// Allow overflow from deeper VC
  parameter int unsigned AllowOverflowFromDeeperVC  = 0,
  /// Deeper VC ID
  parameter int unsigned DeeperVCId                 = 0
) (
  input logic   [NumVC-1:0]                     vc_not_full_i,
  output logic  [NumVC-1:0]                     vc_sel_valid_o,
  output logic  [NumVC-1:0][NumVCWidthMax-1:0]  vc_sel_id_o
);

for(genvar vc = 0; vc < NumVC; vc++) begin : gen_FVADA
  always_comb begin
    vc_sel_valid_o[vc]  = '0;
    vc_sel_id_o[vc] = '0;
    // The preferred output port VC has space
    if(vc_not_full_i[vc]) begin
      vc_sel_valid_o[vc]  = 1'b1;
      vc_sel_id_o[vc] = {{(NumVCWidthMax - NumVCWidth){1'b0}},vc[NumVCWidth-1:0]};
    end else begin
      // Otherwise, overflow to other VCs
      if(AllowVCOverflow && (AllowOverflowFromDeeperVC || vc != DeeperVCId)) begin
        for(int o_vc = 0; o_vc < NumVC; o_vc++) begin
          if(o_vc != vc) begin
            if(vc_not_full_i[o_vc]) begin
              vc_sel_valid_o [vc] = 1'b1;
              vc_sel_id_o[vc] = {{(NumVCWidthMax - NumVCWidth){1'b0}},o_vc[NumVCWidth-1:0]};
            end
          end
        end
      end
    end
  end
end


endmodule
