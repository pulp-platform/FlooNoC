// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>
//         Raphael Roth <raroth@student.ethz.ch>

module floo_reduction_sync import floo_pkg::*;
#(
  /// Number of input ports
  parameter int unsigned NumRoutes  = 1,
  /// Do we support local loopback e.g. should the logic expect the local flit or not
  parameter bit          RdSupportLoopback    = 1'b0,
  /// Type definitions
  parameter type         arb_idx_t  = logic,
  parameter type         flit_t     = logic,
  parameter type         id_t       = logic
) (
  input  arb_idx_t               sel_i,
  input  flit_t [NumRoutes-1:0]  data_i,
  input  logic  [NumRoutes-1:0]  valid_i,
  input  id_t                    xy_id_i,
  output logic                   valid_o,
  output logic  [NumRoutes-1:0]  in_route_mask_o
);

  logic [NumRoutes-1:0]  compare_same, same_and_valid;
  logic all_reduction_srcs_valid;

  // Compute the input mask based on the selected input port's destination and mask fields.
  // This determines which input ports are expected to participate in the reduction.
  floo_route_xymask #(
    .NumRoutes ( NumRoutes ),
    .flit_t    ( flit_t    ),
    .id_t      ( id_t      ),
    .FwdMode   ( 0         ) // We enable the backward mode for reduction
  ) i_route_xymask (
    .channel_i    ( data_i[sel_i]   ),
    .xy_id_i      ( xy_id_i         ),
    .route_sel_o  ( in_route_mask_o )
  );

  for (genvar in = 0; in < NumRoutes; in++) begin : gen_routes
    // Compare whether the `mask` and `dst_id` are equal to the selected input port
    assign compare_same[in] = ((data_i[in].hdr.mask == data_i[sel_i].hdr.mask) &&
                               (data_i[in].hdr.dst_id == data_i[sel_i].hdr.dst_id));

    // Determine if this input should be considered valid for the reduction:
    assign same_and_valid[in] = RdSupportLoopback ? (compare_same[in] & valid_i[in]) :
                                (data_i[sel_i].hdr.dst_id == xy_id_i && in == Eject) ||
                                (compare_same[in] & valid_i[in]);
  end

  // Reduction is valid only if all expected inputs [in_route_mask_o] are valid.
  // Inputs not involved in the reduction are ignored [~(in_route_mask_o)].
  assign all_reduction_srcs_valid = &(same_and_valid | ~in_route_mask_o);

  // To have a valid output at least one input must be valid.
  assign valid_o = (in_route_mask_o == '0)? 1'b0 : (|valid_i & all_reduction_srcs_valid);
endmodule
