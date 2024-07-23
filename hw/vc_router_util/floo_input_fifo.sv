// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// similar to spill_register, but can accept input while full, if
/// being read in the same cycle i.e. `ready_i` is high.
module floo_input_fifo #(
  /// Depth of the "FIFO"
  parameter int unsigned Depth  = 32'd2,
  /// Type of the data to be stored
  parameter type type_t         = logic
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  logic  valid_i,
  input  type_t data_i,
  output logic  valid_o,
  input  logic  ready_i,
  output type_t data_o
);
  if(Depth == 1) begin : gen_reg
    logic ready_out;
    stream_register #(
      .T(type_t)
    ) i_stream_register (
      .clk_i,
      .rst_ni,
      .clr_i      ( 1'b0      ),
      .testmode_i ( 1'b0      ),
      .valid_i,
      .ready_o    ( ready_out ),
      .data_i,
      .valid_o,
      .ready_i,
      .data_o
    );
    `ASSERT(RegFullWrite, ready_out | !valid_i)
  end else if(Depth == 2) begin : gen_fifo_2
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
    assign a_drain = (ready_i & ~b_full_q) | a_fill;

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
  end else if(Depth == 3) begin : gen_fifo_3
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

    // The C register.
    type_t c_data_q;
    logic c_full_q;
    logic c_fill, c_drain;
    `FFL(c_data_q, b_data_q, c_fill, '0)
    `FFL(c_full_q, c_fill, c_fill || c_drain, '0)


    // Fill the A register when being filled. Drain the A register
    // whenever data is popped or more space needed.
    // If data is written to B or not (not -> data is output) is decided there
    assign a_fill = valid_i & ready_for_input;
    // Drain A if need data from A or if filling B
    assign a_drain = (ready_i & ~b_full_q) | a_fill;

    // Fill the B register when A is filled but already full.
    // B full but A empty is impossible
    assign b_fill = a_fill & (b_full_q | (a_full_q & ~ready_i));
    // Drain B if need data from B or if filling B
    assign b_drain = (b_full_q & ready_i & ~c_full_q) | b_fill;

    // Fill the C register when B is filled but already full.
    // C full but B empty is impossible
    assign c_fill = b_fill & (c_drain | (b_full_q & ~ready_i));
    assign c_drain = c_full_q & ready_i;

    assign ready_for_input = ~a_full_q | ~b_full_q | ~c_full_q | ready_i;
    assign valid_o = a_full_q | b_full_q | c_full_q;
    assign data_o = c_full_q ? c_data_q : b_full_q ? b_data_q : a_data_q;

    `ASSERT(CFullBEmpty, !c_full_q | b_full_q)
    `ASSERT(CFullAEmpty, !c_full_q | a_full_q)
    `ASSERT(BFullAEmpty, !b_full_q | a_full_q)
    `ASSERT(RegFullWrite, ready_for_input | !valid_i)
  end else begin : gen_fifo_general
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
