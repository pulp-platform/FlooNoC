// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author:
// - Chen Wu <chenwu@student.ethz.ch>
// - Raphael Roth <raroth@student.ethz.ch>

// This module is the heartpiece for collective operation in the FlooNoC. When running a
// multicast / reduction it either determines the output direction of the filt
// (e.g. in which direction a copy of the filt has to be sent) or the expected
// input direction (e.g. which input provides a flit).

// Limitations:
// - It only supports xy routing
// - It only supports 5 in/out routes

`include "common_cells/assertions.svh"

module floo_route_xymask import floo_pkg::*; #(
  /// Number of collective routes, either output or input
  parameter int unsigned    NumRoutes   = 0,
  /// The type of mask to be computed
  /// 1: Determine output directions of the forward path in Multicast
  /// 0: Determine input directions of the backward path in Multicast i.e the reduction
  parameter bit             FwdMode     = 1'b1,
  /// type for data flit
  parameter type            flit_t      = logic,
  /// type for local id (router id)
  parameter type            id_t        = logic
) (
  // The input flit (only the header is used)
  input  flit_t                         channel_i,
  // The current XY-coordinate of the router
  input  id_t                           xy_id_i,
  // The calculated mask for the multicast/reduction
  output logic [NumRoutes-1:0]          route_sel_o
);

  // General Concept: In XY-Routing all flits travel first in X - direction until they arrive at the columne of the destination
  //                  and then travel in Y direction until they reach the destination. In the Multicast case we have to forward
  //                  them until the "most far away" x/y position (dst_id_max) determint by the mask!

  // We need to handle 4 different cases in this module:
  // ---------------------------------------------------
  // @ Multicast
  //
  // Request              - src (Single)
  //                      - dst (Multiple)
  //                      --> generate destination mask
  //
  // Collect B            - src (Multiple)
  //                      - dst (Single)
  //                      --> generate expected input mask
  // ---------------------------------------------------
  // @ Reduction
  //
  // Reduction            - src (Multiple)
  //                      - dst (Single)
  //                      --> generate expected input mask
  //
  // distribute B resp    - src (Single)
  //                      - dst (Multiple)
  //                      --> generate destination mask
  // ---------------------------------------------------

  // Two cases overlap themself e.g. when we want to have an expected input mask
  // we go from multiple sources to one destination (reduction). With the output mask it is
  // the opposite with single source to multiple destinations (multicast).

  // To improve readability of the code we generate both mask in parallel and only
  // mux them at the output.

/* Variable declaration */
  // generated routes
  logic [NumRoutes-1:0] route_output;
  logic [NumRoutes-1:0] route_expected_input;

  // Var for easier signal assignments
  id_t dst_id;
  id_t src_id;
  id_t mask;

  // Var to hold the maxium distribution distance for both source and destination
  id_t dst_id_max, dst_id_min;
  id_t src_id_max, src_id_min;

  // Var indicates if the current router lies in the same x/y axis as the source / destination
  logic x_matched_output;
  logic y_matched_output;
  logic x_matched_expected_input;
  logic y_matched_expected_input;

  // Signal assigments
  assign dst_id = channel_i.hdr.dst_id;
  assign src_id = channel_i.hdr.src_id;
  assign mask = channel_i.hdr.mask;

  // We compute minimum and maximum destination IDs, to decide whether
  // we need to send left and/or right resp. up and/or down.
  assign dst_id_max.x = dst_id.x | mask.x;
  assign dst_id_max.y = dst_id.y | mask.y;
  assign dst_id_min.x = dst_id.x & (~mask.x);
  assign dst_id_min.y = dst_id.y & (~mask.y);

  // We compute minimum and maximum source IDs, to decide whether
  // we need to send left and/or right resp. up and/or down.
  assign src_id_max.x = src_id.x | mask.x;
  assign src_id_max.y = src_id.y | mask.y;
  assign src_id_min.x = src_id.x & (~mask.x);
  assign src_id_min.y = src_id.y & (~mask.y);

  // `x/y_matched_output` means whether the current coordinate is a receiver of the the multicast.
  assign x_matched_output = &(mask.x | ~(xy_id_i.x ^ dst_id.x));
  assign y_matched_output = &(mask.y | ~(xy_id_i.y ^ dst_id.y));

  // `x/y_matched_expected_input` means the current coordinate provides one element to the reduction.
  assign x_matched_expected_input = &(mask.x | ~(xy_id_i.x ^ src_id.x));
  assign y_matched_expected_input = &(mask.y | ~(xy_id_i.y ^ src_id.y));


  // Generate the output mask
  if(FwdMode) begin : gen_output_mask
    always_comb begin
      route_output = '0;

      // If both direction match then the local port is member of the distribution
      if(x_matched_output && y_matched_output) begin
        route_output[Eject] = 1'b1;
      end

      // If the multicast was issued from an endpoint in the same row
      // i.e. the same Y-coordinate, we forward it to `East` if:
      // 1. The request is incoming from `West` or `Eject` and
      // 2. There are more multicast destinations in the `East` direction
      // The same applies to the `West` direction.
      if (xy_id_i.y == src_id.y) begin
        if (xy_id_i.x >= src_id.x && xy_id_i.x < dst_id_max.x) begin
          route_output[East] = 1;
        end
        if (xy_id_i.x <= src_id.x && xy_id_i.x > dst_id_min.x) begin
          route_output[West] = 1;
        end
      end

      // If there are multicast destinations in the current column,
      // We inject it to `North` if:
      // 1. The request is incoming from `South` or `Eject` and
      // 2. There are more multicast destinations in the `North` direction
      // The same applies to the `South` direction.
      if (x_matched_output) begin
        if (xy_id_i.y >= src_id.y && xy_id_i.y < dst_id_max.y) begin
          route_output[North] = 1;
        end
        if (xy_id_i.y <= src_id.y && xy_id_i.y > dst_id_min.y) begin
          route_output[South] = 1;
        end
      end
    end
  end

  // Generate the expected input mask
  if(!FwdMode) begin : gen_expected_input_mask
    always_comb begin
      route_expected_input = '0;

      // If both direction match then the local port is a member of the distribution
      if(x_matched_expected_input && y_matched_expected_input) begin
        route_expected_input[Eject] = 1'b1;
      end

      // In the case of an reduction we want to collect the source responses first in the x direction.
      // e.g. the North / South can only be selected if we are in the correct dst columne.
      // We expect a packet from the north if the current y id is higher/equal as the destination but still
      // inside the expected maximum range of the source reduction. Same for the South!
      if(xy_id_i.x == dst_id.x) begin
        if((xy_id_i.y >= dst_id.y) && (xy_id_i.y < src_id_max.y)) begin
          route_expected_input[North] = 1'b1;
        end
        if((xy_id_i.y <= dst_id.y) && (xy_id_i.y > src_id_min.y)) begin
          route_expected_input[South] = 1'b1;
        end
      end

      // If we have multiple sources in the same row we first have to collect them in x direction
      // therefor expecting inputs from either the east or west direction.
      // For all members of a rows involved in the reduction the flag y_matched_expected_input is set!
      // We expect a packet from the east if the current x id is higher/equal as the destination but still
      // inside the expected maximum range of the source reduction. Same for the West!
      if(y_matched_expected_input) begin
        if((xy_id_i.x >= dst_id.x) && (xy_id_i.x < src_id_max.x)) begin
          route_expected_input[East] = 1'b1;
        end
        if((xy_id_i.x <= dst_id.x) && (xy_id_i.x > src_id_min.x)) begin
          route_expected_input[West] = 1'b1;
        end
      end
    end
  end

  // Eiter assign the expected input or the output depending on the Mode
  assign route_sel_o = (FwdMode) ? route_output : route_expected_input;

  // We only support five input/output routes
  `ASSERT_INIT(NoMultiCastSupport, NumRoutes == 5)

endmodule
