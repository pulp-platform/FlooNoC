// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>

/// This module is similar to addr decoder
module floo_mask_decode #(
    parameter int unsigned NumSamRules = '0,
    parameter type         id_t        = logic,
    /// The type of the address rules
    parameter type         addr_rule_t = logic,
    parameter type         mask_sel_t  = logic
) (
    input  id_t                          id_i,
    input  addr_rule_t [NumSamRules-1:0] addr_map_i,
    output mask_sel_t                    mask_x_mask_o,
    output mask_sel_t                    mask_y_mask_o,
    output logic                         dec_error_o
);

  always_comb begin
    dec_error_o = 1;
    for (int unsigned i = 0; i < NumSamRules; i++) begin
      if (addr_map_i[i].id == id_i) begin
        mask_x_mask_o = addr_map_i[i].mask_x;
        mask_y_mask_o = addr_map_i[i].mask_y;
        dec_error_o   = 0;
      end
    end
  end
endmodule
