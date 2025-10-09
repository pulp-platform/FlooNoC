// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// To be able to have multiple infligth reduction at the same time we need to track each element
// belonging to an individal reduction. Only elements with equal tag will be reduced together.
// This separation into a seperate module allows to reduce the tracking effort inside the rest
// of the system. Depending on the system restriction we can have a more sophiticated tag
// generator implementation. In the most general case we would support reduction of
// out-of-order arriving elements (NOT SUPPORTED!)

// Current Implementation:
// We want to support the most general input pattern without the overhead of out-of-order
// tracking. The main problem is that the tag can never be out of sync in respect for all
// inputs. If one element is excpected from a certain input direction then it is only allowed
// to increment the Tag if the element actually arrives (and not sooner!) therefor we count
// pending elements on each input. If no element is excpected from one direction then the Tag
// should be incremented immidiatly.

// Example:
// We have 3 different inputs (A,B & C) for two reductions:
// - Reduction 1 with 2 (1.1 + 1.2) Flits from dir A & B
// - Reduction 2 with 3 (2.1 + 2.2 + 2.3) Flits from dir B & C

// Cycle 0  A > Flit 1.1A arrives --> gets Tag 1 --> internal Tag set to 2
//          B > Flit expected but not here yet --> internal Tag remains 1 (pending counter = 1)
//          C > No Flit expected --> internal Tag set to 2
//
// Cycle 1  A > Flit 1.2A arrives --> gets Tag 2 --> internal Tag set to 3
//          B > Flit 1.1B arrives --> gets Tag 1 --> internal Tag set to 2 (pending counter = 1)
//          C > No Flit expected --> internal Tag set to 3
//
// Cycle 2  None
//
// Cycle 3  A > No Flit --> internal Tag remains 3
//          B > Flit 1.2B arrives --> gets Tag 2 --> internal Tag set to 3 (pending counter = 0)
//          C > No Flit --> internal Tag remains 3
//
// Cycle 4  None
//
// Cycle 5  A > No Flit expected --> internal Tag set to 4
//          B > Flit 2.1B arrives --> gets Tag 3 --> internal Tag set to 4
//          C > Flit 2.1C arrives --> gets Tag 3 --> internal Tag set to 4
//
// Cycle 6  None*
//
// Cycle 7  A > No Flit expected --> internal Tag set to 5
//          B > Flit 2.2B arrives --> gets Tag 4 --> internal Tag set to 5
//          C > Flit expected but not here yet --> internal Tag remains 4 (pending counter = 1)
//
// Cycle 8  A > No Flit expected --> internal Tag set to 6
//          B > Flit 2.3B arrives --> gets Tag 5 --> internal Tag set to 6
//          C > Flit expected but not here yet --> internal Tag remains 4 (pending counter = 2)
//
// Cycle 9  A > No Flit --> internal Tag remains 6
//          B > No Flit --> internal Tag remains 6
//          C > Flit 2.2C arrives --> gets Tag 4 --> internal Tag set to 5 (pending counter = 1)
//
// Cycle 10 A > No Flit --> internal Tag remains 6
//          B > No Flit --> internal Tag remains 6
//          C > Flit 2.3C arrives --> gets Tag 5 --> internal Tag set to 6 (pending counter = 0)
//
// * At this point we have finished reduction threfor all internal tag are required to be on the
//   same internal level because we do not know from where the next flits will arrive from.

// Restriction:
// - With the current implementation it is impossible to handle two different incoming reduction
//   (different target address) request in the same cycle. However it should work if a pending
//   elements incomes together with an new reduction request (Not tested!).
// - All inputs needs to be strictly in order.

// Open Points:
// - Check if the module works with backpressure or not. Maybe necessary to introduce output
//   stage if valid is asserted but not accepted by ready yet.
// - Evaluate the target adress to allow for more than one incoming reduction at the same time

`include "common_cells/registers.svh"

module floo_offload_reduction_taggen #(
    /// Number of input routes
    parameter int unsigned NumRoutes                    = 1,
    /// Typedef for the Tag
    parameter type TAG_T                                = logic,
    /// Bit-Width of the TAG_T
    parameter int unsigned RdTagBits                    = 1
) (
    /// Control Inputs
    input  logic                                clk_i,
    input  logic                                rst_ni,
    input  logic                                flush_i,
    /// All Input directions
    input logic [NumRoutes-1:0][NumRoutes-1:0]  mask_i,
    input logic [NumRoutes-1:0]                 valid_i,
    input logic [NumRoutes-1:0]                 ready_i,
    /// Generated Tag for each output
    output TAG_T [NumRoutes-1:0]                tag_o
);

/* All local parameter */
localparam int unsigned  MaxNumberofOutstandingRed = 1 << RdTagBits;

/* All Typedef Vars */

/* Variable declaration */
logic [NumRoutes-1:0] inc_pending;
logic [NumRoutes-1:0] dec_pending;
logic [NumRoutes-1:0] outstanding_pending;

logic [NumRoutes-1:0][NumRoutes-1:0] gen_mask_with_pending;

logic [NumRoutes-1:0] inc_tag;
logic [NumRoutes-1:0] inc_tag_pending_src;
logic [NumRoutes-1:0] general_mask;

TAG_T [NumRoutes-1:0] tag_q, tag_d;

logic [NumRoutes-1:0] handshake;

logic new_reduction_incoming;

/* Module Declaration */

// determint if we have a active valid handshake
assign handshake = valid_i & ready_i;

// Generate Credit Counter once per input
for (genvar i = 0; i < NumRoutes; i++) begin : gen_pending_tracker
    credit_counter #(
        .NumCredits         (MaxNumberofOutstandingRed),
        .InitCreditEmpty    (1'b1)
    ) i_credit_counter (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .credit_o           (),
        .credit_give_i      (inc_pending[i]),
        .credit_take_i      (dec_pending[i]),
        .credit_init_i      (1'b0),
        .credit_left_o      (outstanding_pending[i]),   // == 1'b1 if credits are available
        .credit_crit_o      (),  // Giving one more credit will fill the credits
        .credit_full_o      ()
    );
end

// TODO(lleone): Transpose input mask to gen_mask_with_pending. WHY? IS IT REALLY NECESSARY?
// Generate the mask - if no pending incoming req then forward the mask, otherwise set to 0!
for (genvar i = 0; i < NumRoutes; i++) begin
    for (genvar j = 0; j < NumRoutes; j++) begin
        assign gen_mask_with_pending[j][i] =
                ((outstanding_pending[i] == 1'b0) && (handshake[i] == 1'b1)) ? mask_i[i][j] : 1'b0;
    end
end

// The general mask indicates if the router excpect an element on this input. The or-connection
// between all inputs is to receive the first handshake on any interface availble.
// The mask is only taken into consideration in the general mask if no pending element exists on
// the input as the strict in-order-requiremnt determines that the next incoming element
// belongs to an "old" reduction.

// Here is also the problematic part when two different reductions arrive at the same time:
// the generated mask would be the combination of the two and the tag would be mixed up!

// Generate the General Mask (OR-Connect all 1 bit / 2 bit etc.)
for (genvar i = 0; i < NumRoutes; i++) begin : gen_reduce_bitwise_outer
    assign general_mask[i] = |gen_mask_with_pending[i];
end

// Generate the Signal where we indicate if a new reduction is incoming
assign new_reduction_incoming = (|handshake) & (|general_mask);

always_comb begin
    // Init all Vars
    inc_pending = '0;
    dec_pending = '0;
    inc_tag = '0;
    inc_tag_pending_src = '0;

    // Iterate over all inputs
    for (int i = 0; i < NumRoutes;i++) begin
        // Increment the Tag if we have a valid handshake and the bit in the general mask is set
        // (Element expected from this input and element is actually there)
        if((general_mask[i] == 1'b1) && (handshake[i] == 1'b1) && (new_reduction_incoming == 1'b1)) begin
            // Edge case: On another input we have new incoming request but we have also a pending one
            // with the same mask on this input therefore the received entry is the pending one
            // (handled further down) and not the "new" one - so increment the pending one
            if(outstanding_pending[i] == 1'b1) begin
                inc_pending[i] = 1'b1;
            end else begin
                inc_tag[i] = 1'b1;
            end
        end

        // Increment the Pending for this Input when the general mask bit is set but we do not have a hs
        // (Element expected from this input but element is not there)
        if((general_mask[i] == 1'b1) && (handshake[i] == 1'b0) && (new_reduction_incoming == 1'b1)) begin
            inc_pending[i] = 1'b1;
        end

        // Increment the Tag if the general mask bit is clear but somewhere exists a hs
        // (No Element expected from this input - make sure to only increment by 1)
        // However if this entry is backpressured then add a pending
        if((general_mask[i] == 1'b0) && (new_reduction_incoming == 1'b1)) begin
            if(valid_i[i] == 1'b0) begin
                inc_tag[i] = 1'b1;
            end else begin
                inc_pending[i] = 1'b1;
            end
        end

        // Decrement the Pending for this Input if we have a pending incoming element and a valid hs
        // (Element arrives from a erlier handled request but was pending)
        if((outstanding_pending[i] == 1'b1) && (handshake[i] == 1'b1)) begin
            dec_pending[i] = 1'b1;
            inc_tag_pending_src[i] = 1'b1;
        end
    end
end

// TODO(lleone): WHY NOT USING A NORMAL COUNTER? In this code you might inceremnet twice if both signals are asseretd? If so use delta counter?
// Generate the Tag's here!
always_comb begin
    // Init all Vars
    tag_d = tag_q;

    // Iterate over all inputs
    for (int i = 0; i < NumRoutes;i++) begin

        // Increment the Tag
        if(inc_tag[i] == 1'b1) begin
            tag_d[i] = tag_d[i] + 1;
        end

        // Increment the Tag again if we have a second HS
        if(inc_tag_pending_src[i] == 1'b1) begin
            tag_d[i] = tag_d[i] + 1;
        end
    end
end

// Assign the output tag
assign tag_o = tag_q;

// buffer the tag
`FF(tag_q, tag_d, '0, clk_i, rst_ni)

/* ASSERTION Checks */
endmodule
