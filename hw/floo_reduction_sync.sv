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
  output logic  [NumRoutes-1:0]  ready_o,
  input  id_t                    xy_id_i,
  output logic                   valid_o,
  input  logic                   ready_i,
  input logic  [NumRoutes-1:0]    in_route_mask_i
);

  logic [NumRoutes-1:0]  filtered_valid_in, filtered_local;


  logic [NumRoutes-1:0] filtered_route_mask;
  // The incoming mask is combinatorial. The valid is used to make sure the mask used in the following logic
  // is actually from a valid flit.
  assign filtered_route_mask = in_route_mask_i & {NumRoutes{valid_i[sel_i]}};


  // Filter valids from the expected input sources. If the collective targets
  // the local node and loopback is unsupported, also mark the local port as valid
  // so the flit can reach the endpoint and avoid deadlock.
  for (genvar in = 0; in < NumRoutes; in++) begin : gen_valid
    // Only valid form same reduction streams are propagated
    assign filtered_valid_in[in] =  valid_i[in] && (data_i[in].hdr.dst_id == data_i[sel_i].hdr.dst_id) &&
                                    (data_i[in].hdr.collective_mask == data_i[sel_i].hdr.collective_mask);

    // Mask local port if loopback is not supported
    if (!RdSupportLoopback) begin
      assign filtered_local[in] = filtered_valid_in[in] ||
                                  (data_i[sel_i].hdr.dst_id == xy_id_i && in == Eject);
    end else begin
      assign filtered_local[in] = filtered_valid_in[in];
    end
  end

  stream_join_dynamic #(
    .N_INP ( NumRoutes )
  ) i_stream_join_dynamic (
    .inp_valid_i   ( filtered_local      ),
    .inp_ready_o   ( ready_o             ),
    .sel_i         ( filtered_route_mask ),
    .oup_valid_o   ( valid_o             ),
    .oup_ready_i   ( ready_i             )
  );

endmodule
