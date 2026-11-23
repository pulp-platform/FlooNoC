// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Chen Wu <chenwu@student.ethz.ch>
// Raphael Roth <raroth@student.ethz.ch>
// Lorenzo Leone <lleone@iis.ee.ethz.ch>

// The purpose of the slave ports is to merge data from port's which are not mapped in the "normal" way.
// An example would be the output of the reduction logic!
// These ports cannot be reduced!

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"
`include "floo_noc/typedef.svh"

module floo_output_arbiter import floo_pkg::*;
#(
  /// Number of total input ports
  parameter int unsigned NumRoutes  = 1,
  /// Number of paraellel reduction capable ports
  parameter int unsigned NumParallelRedRoutes = 0,
  /// Collective ops configuration
  parameter collect_op_be_cfg_t  CollectOpCfg    = CollectiveSupportDefaultCfg,
  /// Routing algorithm
  parameter route_algo_e    RouteAlgo   = XYRouting,
  /// Type definitions
  parameter type          flit_t               = logic,
  parameter type          hdr_t                = logic,
  parameter type          id_t                 = logic,
  parameter type          collect_op_t         = logic,
  parameter axi_cfg_t     AxiCfg               = '0
) (
  input  logic                      clk_i,
  input  logic                      rst_ni,
  /// Current XY-coordinate of the router
  input  id_t                       xy_id_i,
  /// Input ports
  input  logic  [NumRoutes-1:0]   valid_i,
  output logic  [NumRoutes-1:0]   ready_o,
  input  flit_t [NumRoutes-1:0]   data_i,
  /// Output port
  output logic                      valid_o,
  input  logic                      ready_i,
  output flit_t                     data_o
);

  `FLOO_COLLECT_OP_HELPERS(collect_op_t)

  flit_t                  reduce_data_out, unicast_data_out;
  logic [NumRoutes-1:0]   reduce_valid_in, unicast_valid_in;
  logic [NumRoutes-1:0]   reduce_ready_out, unicast_ready_out;
  logic                   reduce_valid_out, unicast_valid_out;
  logic                   reduce_ready_in, unicast_ready_in;

  logic [NumRoutes-1:0]   reduce_mask;

  localparam bit EnParallelReduction = NumParallelRedRoutes > 1;

  // Determine which input ports are to be reduced in parallel
  // ignore the local ports
  always_comb begin: gen_reduce_mask
    reduce_mask = '0;
    if (EnParallelReduction) begin
      for (int i = 0; i < NumParallelRedRoutes; i++) begin
        reduce_mask[i] = (is_parallel_reduction_op(data_i[i].hdr.collective_op));
      end
    end
  end

  // Arbitrate unicasts and sequential reductions already computed by the offload unit
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
  if (EnParallelReduction) begin: gen_parallel_reduction
    // Var to separate Non-Slave ports if they have to go to the reduction arbiter!
    flit_t [NumParallelRedRoutes-1:0]    parallel_red_data;
    logic [NumParallelRedRoutes-1:0]     parallel_red_valid;
    logic [NumParallelRedRoutes-1:0]     parallel_red_ready;

    // Arbiter to be instantiated for reduction operations.
    // Responses from a multicast request are also treated as reductions.
    // TODO: fix these flags here - RdCfg... is used (mostly) in the offload
    //       reduction rather the parallel reduction - maybe we could make
    //       another configuration?
    assign reduce_valid_in = valid_i & reduce_mask;

    // The reduction support only the "original" configuration of NumRoutes!
    // Therefore NumRoutes port are connected into the reduction arbiter
    assign parallel_red_data = data_i[NumParallelRedRoutes-1:0];
    assign parallel_red_valid = reduce_valid_in[NumParallelRedRoutes-1:0];
    assign reduce_ready_out[NumParallelRedRoutes-1:0] = parallel_red_ready;
    if(NumRoutes > NumParallelRedRoutes) begin: gen_paral_route_tied
      assign reduce_ready_out[NumRoutes-1:NumParallelRedRoutes] = '0;
    end

    floo_reduction_arbiter #(
      .NumRoutes            ( NumParallelRedRoutes ),
      .CollectOpCfg         ( CollectOpCfg  ),
      .flit_t               ( flit_t               ),
      .hdr_t                ( hdr_t                ),
      .id_t                 ( id_t                 ),
      .RouteAlgo            ( RouteAlgo            ),
      .collect_op_t         ( collect_op_t         ),
      .AxiCfg               ( AxiCfg               )
    ) i_reduction_arbiter (
      .xy_id_i,
      .data_i    ( parallel_red_data   ),
      .valid_i   ( parallel_red_valid  ),
      .ready_o   ( parallel_red_ready  ),
      .valid_o   ( reduce_valid_out ),
      .ready_i   ( reduce_ready_in  ),
      .data_o    ( reduce_data_out  )
    );

    // A packet keeps the output from its first flit to its last. The next router locks the
    // route of its input on the first flit of a packet (`floo_route_select`), so a flit of the
    // other stream sent in between would follow that route to the wrong port.
    logic hold_q, hold_d;           // the output carries an unfinished packet
    logic hold_red_q, hold_red_d;   // that packet comes from the reduction arbiter
    logic reduce_valid_arb, unicast_valid_arb, reduce_ready_arb, unicast_ready_arb;

    // Mask both valid and ready of the stream that waits: the arbiter can grant an input
    // whose valid is low (`AxiVldRdy`), and that stream would then hand over a flit that is
    // never sent.
    assign reduce_valid_arb  = reduce_valid_out  & ~(hold_q & ~hold_red_q);
    assign unicast_valid_arb = unicast_valid_out & ~(hold_q &  hold_red_q);
    assign reduce_ready_in   = reduce_ready_arb  & ~(hold_q & ~hold_red_q);
    assign unicast_ready_in  = unicast_ready_arb & ~(hold_q &  hold_red_q);

    always_comb begin : proc_hold
      hold_d     = hold_q;
      hold_red_d = hold_red_q;
      if (valid_o && ready_i) begin
        hold_d     = !data_o.hdr.last;
        hold_red_d = reduce_valid_arb && reduce_ready_in;
      end
    end

    `FF(hold_q, hold_d, 1'b0)
    `FF(hold_red_q, hold_red_d, 1'b0)

    // Arbitrate between wormhole and reduction arbiter
    // Reductions have higher priority than unicasts (index 0)
    cc_stream_arbiter #(
      .NumInp  (2),
      .ArbMode (cc_pkg::ARB_PRIO),
      .data_t  (flit_t)
    ) i_stream_arbiter (
      .clk_i,
      .rst_ni,
      .clr_i      (1'b0),
      .inp_data_i ({unicast_data_out, reduce_data_out}),
      .inp_valid_i({unicast_valid_arb, reduce_valid_arb}),
      .inp_ready_o({unicast_ready_arb, reduce_ready_arb}),
      .oup_data_o (data_o),
      .oup_valid_o(valid_o),
      .oup_ready_i(ready_i)
    );

    // Use reduce_mask (derived from data opcode) instead of reduce_valid_out
    // (derived from valid_i) to avoid valid-to-ready combinational dependency
    assign ready_o = (reduce_mask & reduce_ready_out) | (~reduce_mask & unicast_ready_out);

  end else begin : gen_no_parallel_reduction
    assign data_o  = unicast_data_out;
    assign valid_o = unicast_valid_out;
    assign unicast_ready_in = ready_i;
    assign ready_o = unicast_ready_out;
  end

  // Cannot have an output valid without at least one input valid
  `ASSERT(ValidOutInvalidIn, valid_o |-> |valid_i)

  `ASSERT_INIT(InvalidNumParallelRedRoutes, !(NumParallelRedRoutes == 1),
               "Number of parallel reduction routes cannot be 1")
endmodule
