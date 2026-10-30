// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>
//         Lorenzo Leone <lleone@iis.ee.ethz.ch>
//         Raphael Roth <raroth@student.ethz.ch>
//
// This module is responsible for synchronizing multiple input streams.
// IMPORTANT: This logic works only when loopback is enabled in the router,
//            because the destination node will also be part of the collective.
module floo_reduction_sync import floo_pkg::*;
#(
  /// Number of input ports
  parameter int unsigned NumRoutes  = 1,
  /// Type definitions
  parameter type         arb_idx_t  = logic,
  parameter type         flit_t     = logic
  ) (
  input  arb_idx_t               sel_i,
  input  flit_t [NumRoutes-1:0]  data_i,
  input  logic  [NumRoutes-1:0]  valid_i,
  output logic  [NumRoutes-1:0]  ready_o,
  output logic                   valid_o,
  input  logic                   ready_i,
  input logic  [NumRoutes-1:0]    in_route_mask_i
);

  logic [NumRoutes-1:0]  filtered_valid_in;
  logic [NumRoutes-1:0]  filtered_route_mask;

  // Keep this filter in a single process that samples the selected input once. The same logic,
  // written as parallel continuous assignments that each re-read `valid_i[sel_i]` and
  // `data_i[sel_i]`, stalls the reduction under QuestaSim's default optimization, with no
  // error or assertion to show it.
  always_comb begin : proc_filter
    logic  sel_valid;
    flit_t sel_flit;
    sel_valid = valid_i[sel_i];
    sel_flit  = data_i[sel_i];
    // The incoming mask is combinatorial. The valid is used to make sure the mask used in the
    // following logic is actually from a valid flit.
    filtered_route_mask = in_route_mask_i & {NumRoutes{sel_valid}};
    // Filter valids from the expected input sources.
    for (int unsigned in = 0; in < NumRoutes; in++) begin
      // Only valid from same reduction streams are propagated
      filtered_valid_in[in] = valid_i[in] && sel_valid &&
                              (data_i[in].hdr.dst_id == sel_flit.hdr.dst_id) &&
                              (data_i[in].hdr.collective_mask == sel_flit.hdr.collective_mask);
    end
  end

  cc_stream_join_dynamic #(
    .NumInp ( NumRoutes )
  ) i_stream_join_dynamic (
    .inp_valid_i   ( filtered_valid_in      ),
    .inp_ready_o   ( ready_o             ),
    .sel_i         ( filtered_route_mask ),
    .oup_valid_o   ( valid_o             ),
    .oup_ready_i   ( ready_i             )
  );

endmodule
