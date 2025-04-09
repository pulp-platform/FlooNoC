// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>

module floo_reduction_sync import floo_pkg::*;
# (
  parameter int unsigned NumRoutes  = 1,
  parameter type         arb_idx_t  = logic,
  parameter type         flit_t     = logic,
  parameter type         id_t       = logic
) (
  input  arb_idx_t               index,
  input  flit_t [NumRoutes-1:0]  data_i,
  input  logic  [NumRoutes-1:0]  valid_i,
  input  id_t                    node_id_i,
  output logic                   valid_o,
  output logic  [NumRoutes-1:0]  in_route_mask_o
);

  logic [NumRoutes-1:0]  compare_same, same_and_valid;

  floo_route_xymask #(
    .NumRoutes ( NumRoutes ),
    .flit_t    ( flit_t    ),
    .id_t      ( id_t      ),
    .Mode      ( 0         ) // Mode 0 for spefifying the expected input directions
  ) i_route_xymask (
    .channel_i ( data_i[index] ),
    .xy_id_i   ( node_id_i     ),
    .route_sel_o( in_route_mask_o )
  );

  id_t mask_in, src_id, dst_id;
  assign mask_in = id_t'(data_i[index].hdr.mask);
  assign src_id = id_t'(data_i[index].hdr.src_id);
  assign dst_id = id_t'(data_i[index].hdr.dst_id);

  always_comb begin
    for (int in_route = 0; in_route < NumRoutes; in_route++) begin
      id_t current_src_id, current_mask;
      current_src_id = id_t'(data_i[in_route].hdr.src_id);
      current_mask = id_t'(data_i[in_route].hdr.mask);
      // only compare whether the same mask and dst_id
      compare_same[in_route] = ((current_mask == mask_in)
                                && (id_t'(data_i[in_route].hdr.dst_id) == dst_id));
      same_and_valid[in_route] = (dst_id == node_id_i && in_route == Eject)?
                                1 : (compare_same[in_route] & valid_i[in_route]);
    end
    valid_o = in_route_mask_o=='0? 0 : &(same_and_valid | ~in_route_mask_o);
  end

endmodule
