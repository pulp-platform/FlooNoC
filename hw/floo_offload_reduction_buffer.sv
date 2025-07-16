// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This module creates a buffer in which all elements can be accessed from the outside.
// The module is implemented as a 0-cycle buffer where the current output is selected
// by an index input. This index is guarded with an valid signal so that the data only
// change if an valid is applied.

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

module floo_offload_reduction_buffer #(
    /// Parameter type for reduction
    parameter type data_mask_tag_t                      = logic,
    /// Tag type for the spyglass
    parameter type tag_t                                = logic,
    /// Number of elements for the partial result buffer
    parameter integer NElements                         = 0,
    /// Number of outputs for the buffer
    parameter integer NOutPorts                         = 1,
    /// Dependent parameters, DO NOT OVERRIDE!
    parameter integer LogNElements                      = (NElements > 32'd1) ? unsigned'($clog2(NElements)) : 1'b1
) (
    /// Control Inputs
    input  logic                                        clk_i,
    input  logic                                        rst_ni,
    input  logic                                        flush_i,
    /// All Input Connections
    input  data_mask_tag_t                              inp_data_i,
    input  logic                                        inp_valid_i,
    output logic                                        inp_ready_o,
    /// All Output Connections
    output data_mask_tag_t [NOutPorts-1:0]              oup_data_o,
    output logic  [NOutPorts-1:0]                       oup_valid_o,
    input  logic  [NOutPorts-1:0]                       oup_ready_i,
    /// Selections
    input  logic [NOutPorts-1:0]                        inp_sel_valid_i,
    input  logic [NOutPorts-1:0][LogNElements-1:0]      inp_sel_i,
    /// Spyglass to all entries of the Buffer
    output logic [NElements-1:0]                        spyglass_valid_o, 
    output tag_t [NElements-1:0]                        spyglass_tag_o
);

/* All Typedef Vars */

// a line of the buffer
typedef struct packed {
    data_mask_tag_t data;
    logic f_valid;
} buff_entry_t;

/* Variable declaration */
buff_entry_t [NElements-1:0] buffer_d, buffer_q; // Buffer to hold the data
logic empty_field_found;
logic [NElements-1:0] ready_sig_buf;

/* Description */

always_comb begin : partial_result_buffer
    buffer_d = buffer_q;    // Init the buffer with the old data

    // All Output signal
    inp_ready_o = 1'b0;
    oup_data_o = '0;
    oup_valid_o = '0;
    spyglass_tag_o = '0;
    spyglass_valid_o = '0;

    // Intermidiate signal
    empty_field_found = 1'b0;
    ready_sig_buf = '0;

    // Store the Data into the Buffer
    for(int i = 0; i < NElements; i++) begin
        if((buffer_d[i].f_valid == 1'b0) && (empty_field_found == 1'b0) && (inp_valid_i == 1'b1)) begin
            // Lock the Entry
            empty_field_found = 1'b1;

            // Ack the handshake
            inp_ready_o = 1'b1;

            // Copy the actual data
            buffer_d[i].data = inp_data_i;
            buffer_d[i].f_valid = 1'b1;
        end
    end

    // Implement the Spyglass here!
    for(int i = 0; i < NElements; i++) begin
        spyglass_tag_o[i] = buffer_d[i].data.tag;
        spyglass_valid_o[i] = buffer_d[i].f_valid;
    end

    // Assign the output for each defined port
    for(int i = 0; i < NOutPorts;i++) begin
        if(inp_sel_valid_i[i] == 1'b1) begin
            oup_data_o[i] = buffer_d[inp_sel_i[i]].data;
            oup_valid_o[i] = buffer_d[inp_sel_i[i]].f_valid;
            ready_sig_buf[inp_sel_i[i]] = oup_ready_i[i];
        end
    end

    // If we receive any valid handshake on any IF then reset the valid flag
    for(int i = 0; i < NElements; i++) begin
        if((ready_sig_buf[i] == 1'b1) && (buffer_d[i].f_valid == 1'b1)) begin
            buffer_d[i].f_valid = 1'b0;
        end
    end

    // Reset Buffer if flush is asserted & avoid piping data to the output
    if(flush_i == 1'b1) begin
        buffer_d = '0;
        oup_valid_o = '0;
    end
end

// Store the Buffer
`FF(buffer_q, buffer_d, '0, clk_i, rst_ni)

// We require at least a size of 2 for the partial result buffer (otherwise deadlock potential)
`ASSERT_INIT(WrongNumberOfElements, !(NElements < 2))


endmodule