// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"

/// A virtual channel arbiter
module floo_vc_arbiter import floo_pkg::*;
#(
  parameter int unsigned NumVirtChannels  = 1,
  parameter type         flit_t           = logic,
  parameter int unsigned NumPhysChannels  = 1,
  parameter vc_impl_e    VcImpl           = VcNaive,
  parameter int unsigned NumCredits       = 3
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
  output flit_t [NumPhysChannels-1:0] data_o,
  input  logic  [NumVirtChannels-1:0] credit_i
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

    // Signals to support credit based arbitration
    logic [NumVirtChannels-1:0] credit_handshake, credit_left;

    // Mask used to switch VC requests
    logic [NumVirtChannels-1:0] mask_q, mask_d;

    ////////////////////////////////
    // Lock and mask update logic //
    ////////////////////////////////

    always_comb begin
      mask_d = mask_q;
      // If we have a valid request but no grant, and the
      // other VC has a grant, switch VC in the next cycle
      if (vc_arb_req_out) begin
        if (!vc_arb_gnt_in) begin
          if (ready_i[vc_arb_idx ? 0 : 1] && valid_i[vc_arb_idx ? 0 : 1]) begin: gen_valid_mask
              mask_d = ~(1'b1 << vc_arb_idx);
          end
        end else begin
          mask_d = '1;
        end
      end
    end

    `FF(mask_q, mask_d, '1, clk_i, rst_ni)

    //////////////////////////
    // VC arbitration logic //
    //////////////////////////

    if (VcImpl == VcPreemptValid) begin : gen_preempt_valid
      // Initially, any valid channel can request access to the physical channel.
      // However, to guarantee deadlock freedom, we must be able to preempt the
      // virtual channel holding the physical link and put the other channel on
      // the link. To do so, we mask the VC holding the link, when required.
      assign vc_arb_req_in = valid_i & mask_q;
    end else if (VcImpl == VcCreditBased) begin : gen_credit_based
      // In case of credit based approach, the valid is set only if there are credits left
      assign vc_arb_req_in = valid_i & credit_left;
    end else begin : gen_standard
      // A Virtual channel is only considered for arbitration if the virtual
      // channel holds valid data `valid_i` and the next router is ready to
      // receive data on this virtual channel `ready_i`.
      assign vc_arb_req_in = valid_i & ready_i;
    end

    // A credit is taken only after handshake has occured
    assign credit_handshake = valid_o & ready_o;

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

  if (VcImpl == VcCreditBased) begin: gen_credit
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_vc_credits
      credit_counter #(
        .NumCredits(NumCredits)
      ) i_vc_credit_counter (
        .clk_i            ( clk_i                     ),
        .rst_ni           ( rst_ni                    ),
        .credit_o         ( /* unused */              ),
        .credit_give_i    ( credit_i[v]               ),
        .credit_take_i    ( credit_handshake[v]       ),
        .credit_init_i    ( 1'b0                      ),
        .credit_left_o    ( credit_left[v]            ),
        .credit_crit_o    ( /* unused */              ),
        .credit_full_o    ( /* unused */              )
      );
    end
  end

  end else begin : gen_odd_phys
    $fatal(1, "unimplemented!");

    // multi-pick rr-arb

  end

  ////////////////
  // Assertions //
  ////////////////

  // Only one VC can access the physical link at a time
  `ASSERT(OneHotOutputValid, $onehot0(valid_o))

  // Currently only supports two virtual channels
  `ASSERT_INIT(SupportedNumVirtChannels, !VcImpl || (NumVirtChannels <= 2))

endmodule
