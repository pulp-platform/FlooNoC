// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

// similar to spill_register, but writeable while full if ready_i
module floo_input_fifo #(
  parameter int Depth     = 2,
  parameter type type_t        = logic
) (
  input  logic clk_i   ,
  input  logic rst_ni  ,
  input  logic valid_i ,
  input  type_t     data_i  ,
  output logic valid_o ,
  input  logic ready_i ,
  output type_t     data_o
);
  if(Depth == 2) begin : gen_fifo
    logic ready_for_input;
    // The A register.
    type_t a_data_q;
    logic a_full_q;
    logic a_fill, a_drain;
    `FFL(a_data_q, data_i, a_fill, '0)
    `FFL(a_full_q, a_fill, a_fill || a_drain, '0)

    // The B register.
    type_t b_data_q;
    logic b_full_q;
    logic b_fill, b_drain;
    `FFL(b_data_q, a_data_q, b_fill, '0)
    `FFL(b_full_q, b_fill, b_fill || b_drain, '0)


    // Fill the A register when being filled. Drain the A register
    // whenever data is popped or more space needed.
    // If data is written to B or not (not -> data is output) is decided there
    assign a_fill = valid_i & ready_for_input;
    assign a_drain = ready_i | a_fill;

    // Fill the B register when A is filled but already full.
    // B full but A empty is impossible
    assign b_fill = a_fill & (b_drain | (a_full_q & ~ready_i));
    assign b_drain = b_full_q & ready_i;

    // can accept input while full, if being read
    assign ready_for_input = ~a_full_q | ~b_full_q | ready_i;

    // The unit provides output as long as one of the registers is filled.
    assign valid_o = a_full_q | b_full_q;

    // Empty reg B before A
    assign data_o = b_full_q ? b_data_q : a_data_q;

    `ASSERT(RegFullWrite, ready_for_input | !valid_i)
    `ASSERT(RegEmptyPop, valid_o | !ready_i)
  end
  else begin : gen_fifo_not_depth_2
    logic reg_ready;
    $warning("if depth != 2, write and read is not possible at same time while full");
    stream_fifo_optimal_wrap #(
      .Depth  (Depth),
      .type_t (type_t)
    ) i_fifo (
      .clk_i,
      .rst_ni,
      .testmode_i ('0),
      .flush_i    ('0),
      .usage_o    (),
      .data_i,
      .valid_i,
      .ready_o    (reg_ready),
      .data_o,
      .valid_o,
      .ready_i
    );
    `ASSERT(RegNotReadyWrite, reg_ready | !valid_i)
  end

endmodule
