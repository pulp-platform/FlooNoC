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

module floo_output_arbiter import floo_pkg::*;
#(
  /// Number of total input ports
  parameter int unsigned NumRoutes  = 1,
  /// Number of paraellel reduction capable ports
  parameter int unsigned NumParallelRedRoutes = 0,
  /// Type definitions
  parameter type         flit_t               = logic,
  parameter type         hdr_t                = logic,
  parameter type         id_t                 = logic,
  /// Do we support local loopback e.g. should the logic expect the local flit or not
  parameter bit          RdSupportLoopback    = 1'b0,
  /// AXI dependent parameter
  parameter bit          RdSupportAxi         = 1'b1,
  parameter axi_cfg_t    AxiCfg               = '0
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

  flit_t                  reduce_data_out, unicast_data_out;
  logic [NumRoutes-1:0]   reduce_valid_in, unicast_valid_in;
  logic [NumRoutes-1:0]   reduce_ready_out, unicast_ready_out;
  logic                   reduce_valid_out, unicast_valid_out;
  logic                   reduce_ready_in, unicast_ready_in;

  logic [NumRoutes-1:0]   reduce_mask;

  localparam bit EnParallelReduction = (NumParallelRedRoutes > 1) ? 1'b1 : 1'b0;

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
    // Var to sparate Non-Slave ports if they have to go to the reduction arbiter!
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
    if(NumRoutes > NumParallelRedRoutes) begin
      assign reduce_ready_out[NumRoutes-1:NumParallelRedRoutes] = '0;
    end

    floo_reduction_arbiter #(
      .NumRoutes            ( NumParallelRedRoutes ),
      .EnParallelReduction  ( EnParallelReduction  ),
      .flit_t               ( flit_t               ),
      .hdr_t                ( hdr_t                ),
      .id_t                 ( id_t                 ),
      .RdSupportLoopback    ( RdSupportLoopback    ),
      .RdSupportAxi         ( RdSupportAxi         ),
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
