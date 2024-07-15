// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

/// A wormhole arbiter
module floo_wormhole_arbiter import floo_pkg::*;
#(
  parameter int unsigned NumRoutes  = 1,
  // parameter int unsigned NumDst     = 1,
  parameter type         flit_t     = logic
  // parameter type         arb_idx_t  = logic
) (
  input  logic                   clk_i,
  input  logic                   rst_ni,
  /// Ports towards the input routes
  input  logic  [NumRoutes-1:0]  valid_i,
  output logic  [NumRoutes-1:0]  ready_o,
  input  flit_t [NumRoutes-1:0]  data_i,
  /// Ports towards the output route
  output logic                   valid_o,
  input  logic                   ready_i,
  output flit_t                  data_o
  // output logic [cf_math_pkg::idx_width(NumRoutes)-1:0] selected_idx_o
);
  typedef logic [cf_math_pkg::idx_width(NumRoutes)-1:0] arb_idx_t;

  logic last_out, last_q;
  arb_idx_t selected_idx, valid_selected_idx;
  // arb_idx_t valid_selected_idx;

  logic [NumRoutes-1:0] valid_d, valid_q;

  // Use arbiter to determine overall packet arbitration
  rr_arb_tree #(
    .NumIn    ( NumRoutes ),
    .DataType ( logic     ),
    .ExtPrio  ( 1'b0      ),
    .AxiVldRdy( 1'b1      ),
    .LockIn   ( 1'b1      ), // Ensure LockIn to avoid changing priority
    .FairArb  ( 1'b1      )
  ) i_rr_arb_packets (
    .clk_i,
    .rst_ni,
    .flush_i( 1'b0 ),
    .rr_i   ( '0 ),
    .req_i  ( valid_d ),
    .gnt_o  (),
    .data_i ( '0 ),
    .req_o  (),
    .gnt_i  ( ready_i & last_out ),
    .data_o (),
    .idx_o  ( selected_idx )
  );    

  assign valid_selected_idx = (|valid_i) ? selected_idx : '0;

  // Manually connect handshake and data signals
  assign valid_o = valid_i[valid_selected_idx];
  assign data_o  = data_i [valid_selected_idx];
  always_comb begin : proc_ready_o
    ready_o = '0;
    ready_o[valid_selected_idx] = ready_i;
  end

  assign last_out = data_o.hdr.last & valid_o;

  always_comb begin : proc_valid
    valid_d = valid_q;
    if (valid_q == '0 || last_q) begin
      valid_d = valid_i;
    end
  end

  `FF(valid_q, valid_d, '0)
  `FF(last_q, last_out & ready_i, '0)

endmodule
