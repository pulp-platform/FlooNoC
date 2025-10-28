// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>

module floo_route_xymask
  import floo_pkg::*;
#(
  /// Number of output ports
  parameter int unsigned NumRoutes     = 0,
  /// The type of mask to be computed
  /// 1: Determine output directions of the forward path in Multicast
  /// 0: Determine input directions of the backward path in Multicast i.e the reduction
  parameter bit       FwdMode          = 1'b1,
  /// Various types
  parameter type         flit_t        = logic,
  parameter type         id_t          = logic
) (
  // The input flit (only the header is used)
  input  flit_t                         channel_i,
  // The current XY-coordinate of the router
  input  id_t                           xy_id_i,
  // The calculated mask for the multicast/reduction
  output logic [NumRoutes-1:0]          route_sel_o
);

  logic [NumRoutes-1:0] route_sel;

  id_t dst_id, mask_in, src_id;
  id_t dst_id_max, dst_id_min;
  logic x_matched, y_matched;

  // In the forward path, we use the normal `dst_id` to compute the mask.
  // In the backward path, we use the `src_id` which was the original
  // `dst_id` in from the forward path.
  assign dst_id = (FwdMode)? channel_i.hdr.dst_id : channel_i.hdr.src_id;
  assign src_id = (FwdMode)? channel_i.hdr.src_id : channel_i.hdr.dst_id;
  // TODO(fischeti): Clarify with Chen why `ParallelReduction` are excluded
  assign mask_in = (FwdMode && channel_i.hdr.commtype==ParallelReduction)?
                    '0 : channel_i.hdr.mask;

  // We compute minimum and maximum destination IDs, to decide whether
  // we need to send left and/or right resp. up and/or down.
  assign dst_id_max.x = dst_id.x | mask_in.x;
  assign dst_id_max.y = dst_id.y | mask_in.y;
  assign dst_id_min.x = dst_id.x & (~mask_in.x);
  assign dst_id_min.y = dst_id.y & (~mask_in.y);

  // `x/y_matched` means whether the current coordinate is a
  // receiver of the the multicast.
  assign x_matched = &(mask_in.x | ~(xy_id_i.x ^ dst_id.x));
  assign y_matched = &(mask_in.y | ~(xy_id_i.y ^ dst_id.y));

  always_comb begin
    route_sel = '0;
    if (FwdMode) begin : gen_out_mask
      // If both x and y are matched, we eject the flit
      if (x_matched && y_matched) begin
        route_sel[Eject] = 1;
      end
      // If the multicast was issued from an endpoint in the same row
      // i.e. the same Y-coordinate, we forward it to `East` if:
      // 1. The request is incoming from `West` or `Eject` and
      // 2. There are more multicast destinations in the `East` direction
      // The same applies to the `West` direction.
      if (xy_id_i.y == src_id.y) begin
        if (xy_id_i.x >= src_id.x && xy_id_i.x < dst_id_max.x) begin
          route_sel[East] = 1;
        end
        if (xy_id_i.x <= src_id.x && xy_id_i.x > dst_id_min.x) begin
          route_sel[West] = 1;
        end
      end
      // If there are multicast destinations in the current column,
      // We inject it to `North` if:
      // 1. The request is incoming from `South` or `Eject` and
      // 2. There are more multicast destinations in the `North` direction
      // The same applies to the `South` direction.
      if (x_matched) begin
        if (xy_id_i.y >= src_id.y && xy_id_i.y < dst_id_max.y) begin
          route_sel[North] = 1;
        end
        if (xy_id_i.y <= src_id.y && xy_id_i.y > dst_id_min.y) begin
          route_sel[South] = 1;
        end
      end
    end

    // TODO(fischeti): Clarify with Chen why `YXRouting` is used
    // for the backward path
    else begin : gen_in_mask
      // If we previously ejected the flit, we expect one again
      if (x_matched && y_matched) begin
        route_sel[Eject] = 1;
      end
      // This is the same as the forward path, but we use the
      // `YXRouting` algorithm to compute the mask.
      if (xy_id_i.x == src_id.x) begin
        if (xy_id_i.y >= src_id.y && xy_id_i.y < dst_id_max.y) begin
          route_sel[North] = 1;
        end
        if (xy_id_i.y <= src_id.y && xy_id_i.y > dst_id_min.y) begin
          route_sel[South] = 1;
        end
      end
      if (y_matched) begin
        if (xy_id_i.x >= src_id.x && xy_id_i.x < dst_id_max.x) begin
          route_sel[East] = 1;
        end
        if (xy_id_i.x <= src_id.x && xy_id_i.x > dst_id_min.x) begin
          route_sel[West] = 1;
        end
      end
    end
  end
  assign route_sel_o = route_sel;
endmodule
