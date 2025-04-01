// Chen Wu

/// This module is similar to addr decoder
module floo_mask_decode
# (
    parameter int unsigned NumMaskRules = '0,
    parameter type id_t        = logic,
    parameter type mask_rule_t = logic,
    parameter type mask_sel_t  = logic
)(
    input id_t id_i,
    output mask_sel_t mask_x_mask,
    output mask_sel_t mask_y_mask,
    input  mask_rule_t [NumMaskRules-1:0] mask_map_i,
    output logic dec_error_o
);

  always_comb begin
    dec_error_o = 1;
    for (int unsigned i = 0; i < NumMaskRules; i++) begin
      if (mask_map_i[i].id == id_i) begin
        mask_x_mask = mask_map_i[i].mask_x;
        mask_y_mask = mask_map_i[i].mask_y;
        dec_error_o = 0;
      end
    end
  end
endmodule
