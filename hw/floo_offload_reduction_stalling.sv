// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This module allows to stall a valid / ready handshake by delaying the ready signal
// to the source. Any valid signal acknowledged on the destination side will lead to
// the deassertion of said valid signal. The handshake to the source can be controlled
// by an external stalling signal.

// The stalling signal is not preemtive e.g. it needs to be asserted in either the cycle where
// the dst handshake occurs or after. A stalling signal befor will be ignored!

`include "common_cells/registers.svh"

module floo_offload_reduction_stalling #() (
    /// Control Inputs
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        flush_i,
    /// All Input Connections
    input  logic        src_valid_i,
    output logic        src_ready_o,
    /// Stop stalling the valid signal
    input logic         stalling_i,
    /// All Output Connections
    output logic        dst_valid_o,
    input logic         dst_ready_i
);

/* All local parameter */

/* All Typedef Vars */

// Var to track the state of the handshake
typedef enum logic [1:0] { 
    s_idle = 2'd0,
    s_forward = 2'd1,
    s_stalling = 2'd2
} state_t;

/* Variable declaration */
state_t sm_d, sm_q;

/* Module Declaration */
always_comb begin
    // Init all Vars
    sm_d = sm_q;

    dst_valid_o = 1'b0;
    src_ready_o = 1'b0;

    // Small State Machine
    case(sm_d)
        s_idle: begin
            dst_valid_o = src_valid_i;  // forward the valid signal

            if((src_valid_i == 1'b1) && (dst_ready_i == 1'b0)) begin
                sm_d = s_forward;
            end else if((src_valid_i == 1'b1) && (dst_ready_i == 1'b1) && (stalling_i == 1'b0)) begin
                sm_d = s_stalling;
            end else if((src_valid_i == 1'b1) && (dst_ready_i == 1'b1) && (stalling_i == 1'b1)) begin
                src_ready_o = 1'b1;
                sm_d = s_idle;
            end
        end        
        s_forward: begin
            dst_valid_o = src_valid_i;  // forward the valid signal

            if((src_valid_i == 1'b1) && (dst_ready_i == 1'b1) && (stalling_i == 1'b0)) begin
                sm_d = s_stalling;
            end else if((src_valid_i == 1'b1) && (dst_ready_i == 1'b1) && (stalling_i == 1'b1)) begin
                src_ready_o = 1'b1;
                sm_d = s_idle;
            end
        end
        s_stalling: begin
            dst_valid_o = 1'b0; // the valid signal was already acked

            if(stalling_i == 1'b1) begin
                src_ready_o = 1'b1;
                sm_d = s_idle;
            end
        end
    endcase

    // Reset the state
    if(flush_i == 1'b1) begin
        sm_d = s_idle;
        dst_valid_o = 1'b0;
        src_ready_o = 1'b0;
    end
end


// Buffer the locked in signal
`FF(sm_q, sm_d, s_idle, clk_i, rst_ni)


endmodule
