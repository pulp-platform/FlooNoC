// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A virtual channel arbiter
module floo_vc_arbiter import floo_pkg::*;
#(
  parameter int unsigned NumVirtChannels = 1,
  parameter type         flit_t          = logic,
  parameter int unsigned NumPhysChannels = 1
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  /// Ports towards the virtual channels
  input  logic  [NumVirtChannels-1:0] valid_i,
  output logic  [NumVirtChannels-1:0] ready_o,
  input  flit_t [NumVirtChannels-1:0] data_i,
  /// Ports towards the physical channels
  input  logic  [NumVirtChannels-1:0] ready_i,
  output logic  [NumVirtChannels-1:0] valid_o,
  output flit_t [NumPhysChannels-1:0] data_o
);

if (NumVirtChannels == NumPhysChannels) begin : gen_virt_eq_phys
  assign valid_o = valid_i;
  assign ready_o = ready_i;
  assign data_o  = data_i;
end else if (NumPhysChannels == 1) begin : gen_single_phys

    typedef logic [$clog2(NumVirtChannels)-1:0] arb_idx_t;
    arb_idx_t vc_arb_idx;

    logic [NumVirtChannels-1:0] vc_arb_req_in;
    logic                       vc_arb_req_out, vc_arb_gnt_in;

    // A Virtual channel is only considered for arbitration if the virtual
    // channel holds valid data `valid_i` and the next router is ready to
    // receive data on this virtual channel `ready_i`.
    assign vc_arb_req_in = valid_i & ready_i;

    // The arbitration tree only accepts a single grant signal. Therefore,
    // The grant of the channel that has won the arbitration is forwarded
    assign vc_arb_gnt_in = ready_i[vc_arb_idx];

    // One-hot encoding of the arbitration winning channel
    always_comb begin
      valid_o = '0;
      valid_o[vc_arb_idx] = vc_arb_req_out;
    end

    rr_arb_tree #(
      .NumIn      ( NumVirtChannels ),
      .DataType   ( flit_t          ),
      .AxiVldRdy  ( 1'b0            ), // fischeti: Don't think that applies
      .LockIn     ( 1'b0            )
    ) i_rr_vc_arbiter (
      .clk_i    ( clk_i             ),
      .rst_ni   ( rst_ni            ),
      .flush_i  ( 1'b0              ),
      .rr_i     ( '0                ),
      .req_i    ( vc_arb_req_in     ),
      .gnt_o    ( ready_o           ),
      .data_i   ( data_i            ),
      .req_o    ( vc_arb_req_out    ),
      .gnt_i    ( vc_arb_gnt_in     ),
      .data_o   ( data_o            ),
      .idx_o    ( vc_arb_idx        )
    );
  end else begin : gen_odd_phys
    $fatal(1, "unimplemented!");

    // multi-pick rr-arb

  end


endmodule
