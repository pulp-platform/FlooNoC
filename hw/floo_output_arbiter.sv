// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>

module floo_output_arbiter import floo_pkg::*;
#(
  /// Number of input ports
  parameter int unsigned NumRoutes  = 1,
  /// Type definitions
  parameter type         flit_t     = logic,
  parameter type         payload_t  = logic,
  parameter payload_t    NarrowRspMask = '0,
  parameter payload_t    WideRspMask = '0,
  parameter type         id_t       = logic
) (
  input  logic                   clk_i,
  input  logic                   rst_ni,
  /// Input ports
  input  logic  [NumRoutes-1:0]  valid_i,
  output logic  [NumRoutes-1:0]  ready_o,
  input  flit_t [NumRoutes-1:0]  data_i,
  input  id_t                    xy_id_i,
  /// Output port
  output logic                   valid_o,
  input  logic                   ready_i,
  output flit_t                  data_o
);

  flit_t[NumRoutes-1:0]  reduce_data_in, unicast_data_in;
  logic [NumRoutes-1:0]  reduce_valid_in, reduce_ready_in;
  logic [NumRoutes-1:0]  unicast_valid_in, unicast_ready_in;

  flit_t reduced_data_out, unicast_data_out;
  logic reduced_valid_out, unicast_valid_out;

  logic [NumRoutes-1:0]  reduce_mask;

  // Determine which input ports are to be reduced
  for (genvar i = 0; i < NumRoutes; i++) begin : gen_reduce_mask
    assign reduce_mask[i] = (data_i[i].hdr.commtype == CollectB);
  end

  // Arbitrate unicasts
  assign unicast_valid_in = valid_i & ~reduce_mask;
  assign unicast_data_in  = data_i;

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumRoutes ),
    .flit_t     ( flit_t    )
  ) i_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .valid_i ( unicast_valid_in  ),
    .ready_o ( unicast_ready_in  ),
    .data_i  ( unicast_data_in   ),
    .valid_o ( unicast_valid_out ),
    .ready_i ( ready_i           ),
    .data_o  ( unicast_data_out  )
  );

  // Arbitrate reductions
  assign reduce_valid_in = valid_i & reduce_mask;
  assign reduce_data_in  = data_i;

  floo_reduction_arbiter #(
    .NumRoutes      ( NumRoutes     ),
    .flit_t         ( flit_t        ),
    .payload_t      ( payload_t     ),
    .id_t           ( id_t          ),
    .NarrowRspMask  ( NarrowRspMask ),
    .WideRspMask    ( WideRspMask   )
  ) i_reduction_arbiter (
    .valid_i   ( reduce_valid_in   ),
    .ready_o   ( reduce_ready_in   ),
    .data_i    ( reduce_data_in    ),
    .node_id_i ( xy_id_i           ),
    .valid_o   ( reduced_valid_out ),
    .ready_i   ( ready_i           ),
    .data_o    ( reduced_data_out  )
  );

  // Arbitrate between wormhole and reduction arbiter
  // TODO(fischeti): Discuss with Chen if the handshaking is correctly handled
  // I believe that the `ready_i` of the two arbiters should be masked.
  assign valid_o = (reduced_valid_out & |reduce_valid_in) ? reduced_valid_out : unicast_valid_out;
  assign data_o  = (reduced_valid_out & |reduce_valid_in) ? reduced_data_out  : unicast_data_out;
  assign ready_o = (reduced_valid_out & |reduce_valid_in) ? reduce_ready_in : unicast_ready_in;

endmodule
