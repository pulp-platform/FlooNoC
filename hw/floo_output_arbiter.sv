// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>

`include "common_cells/assertions.svh"

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
  /// Current XY-coordinate of the router
  input  id_t                    xy_id_i,
  /// Input ports
  input  logic  [NumRoutes-1:0]  valid_i,
  output logic  [NumRoutes-1:0]  ready_o,
  input  flit_t [NumRoutes-1:0]  data_i,
  /// Output port
  output logic                   valid_o,
  input  logic                   ready_i,
  output flit_t                  data_o
);

  flit_t                 reduce_data_out, unicast_data_out;
  logic [NumRoutes-1:0]  reduce_valid_in, unicast_valid_in, reduce_ready_out, unicast_ready_out;
  logic                  reduce_valid_out, unicast_valid_out, reduce_ready_in, unicast_ready_in;

  logic [NumRoutes-1:0]  reduce_mask;

  // Determine which input ports are to be reduced
  for (genvar i = 0; i < NumRoutes; i++) begin : gen_reduce_mask
    assign reduce_mask[i] = (data_i[i].hdr.commtype == CollectB);
  end

  // Arbitrate unicasts
  assign unicast_valid_in = valid_i & ~reduce_mask;

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumRoutes ),
    .flit_t     ( flit_t    )
  ) i_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .data_i,
    .valid_i ( unicast_valid_in  ),
    .ready_o ( unicast_ready_out ),
    .valid_o ( unicast_valid_out ),
    .ready_i ( unicast_ready_in  ),
    .data_o  ( unicast_data_out  )
  );

  // Arbitrate reductions
  assign reduce_valid_in = valid_i & reduce_mask;

  floo_reduction_arbiter #(
    .NumRoutes      ( NumRoutes     ),
    .flit_t         ( flit_t        ),
    .payload_t      ( payload_t     ),
    .id_t           ( id_t          ),
    .NarrowRspMask  ( NarrowRspMask ),
    .WideRspMask    ( WideRspMask   )
  ) i_reduction_arbiter (
    .xy_id_i,
    .data_i,
    .valid_i   ( reduce_valid_in  ),
    .ready_o   ( reduce_ready_out ),
    .valid_o   ( reduce_valid_out ),
    .ready_i   ( reduce_ready_in  ),
    .data_o    ( reduce_data_out  )
  );

  // Arbitrate between wormhole and reduction arbiter
  // Reductions have higher priority than unicasts (index 0)
  stream_arbiter #(
    .N_INP  (2),
    .ARBITER("prio"),
    .DATA_T (flit_t)
  ) i_stream_arbiter (
    .clk_i,
    .rst_ni,
    .inp_data_i ({unicast_data_out, reduce_data_out}),
    .inp_valid_i({unicast_valid_out, reduce_valid_out}),
    .inp_ready_o({unicast_ready_in, reduce_ready_in}),
    .oup_data_o (data_o),
    .oup_valid_o(valid_o),
    .oup_ready_i(ready_i)
  );

  assign ready_o = (reduce_valid_out)? reduce_ready_out : unicast_ready_out;

  // Cannot have an output valid without at least one input valid
  `ASSERT(ValidOutInvalidIn, valid_o |-> |valid_i)

endmodule
