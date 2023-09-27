// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// Queue to buffer meta information in the requests
/// that need to be stored until the response arrives.
/// Also supports atomics with unique IDs.
module floo_meta_buffer #(
  /// Maximum number of non-atomic outstanding requests
  parameter int MaxTxns       = 32'd0,
  /// Enable support for atomics
  parameter bit AtopSupport   = 1'b1,
  /// Number of outstanding atomic requests
  parameter int MaxAtomicTxns = 32'd1,
  /// External Atomic ID
  parameter bit ExtAtomicId   = 1'b0,
  /// Information to be buffered for responses
  parameter type buf_t        = logic,
  /// ID width
  parameter int IdWidth       = 32'd1,
  /// ID type for outgoing requests
  parameter type id_t         = logic [IdWidth-1:0],
  /// Constant ID for non-atomic requests
  localparam id_t  NonAtomicId = '1,
  /// mask of available Atomic IDs
  localparam type id_mask_t    = logic [MaxAtomicTxns-1:0]
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  logic req_push_i,
  input  logic req_valid_i,
  input  buf_t req_buf_i,
  input  logic req_is_atop_i,
  input  id_t  req_atop_id_i,
  input  id_mask_t avl_atop_ids_i,
  output id_mask_t avl_atop_ids_o,
  output logic req_full_o,
  output id_t  req_id_o,
  input  logic rsp_pop_i,
  input  id_t  rsp_id_i,
  output buf_t rsp_buf_o
);

  buf_t no_atop_buf_out;
  logic no_atop_buf_full;
  logic rsp_is_atop;

  assign rsp_is_atop = AtopSupport && (rsp_id_i != NonAtomicId);

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0    ),
    .DEPTH        ( MaxTxns ),
    .dtype        ( buf_t   )
  ) i_no_atop_fifo (
    .clk_i,
    .rst_ni,
    .flush_i    ( 1'b0                          ),
    .testmode_i ( test_enable_i                 ),
    .full_o     ( no_atop_buf_full              ),
    .empty_o    (                               ),
    .usage_o    (                               ),
    .data_i     ( req_buf_i                     ),
    .push_i     ( req_push_i && !req_is_atop_i  ),
    .data_o     ( no_atop_buf_out               ),
    .pop_i      ( rsp_pop_i && !rsp_is_atop     )
  );

  if (AtopSupport) begin : gen_atop_support

    logic [MaxAtomicTxns-1:0] atop_req_out_push;
    logic [MaxAtomicTxns-1:0] atop_req_out_pop;
    logic [MaxAtomicTxns-1:0] atop_req_out_full;
    logic [MaxAtomicTxns-1:0] atop_req_out_empty;
    buf_t [MaxAtomicTxns-1:0] atop_data_out;

    id_t req_atop_id;


    stream_register #(
      .T(buf_t)
    ) i_atop_regs [MaxAtomicTxns-1:0] (
      .clk_i,
      .rst_ni,
      .clr_i      ( '0                  ),
      .testmode_i ( test_enable_i       ),
      .valid_i    ( atop_req_out_push   ),
      .ready_o    ( atop_req_out_empty  ),
      .data_i     ( req_buf_i           ),
      .valid_o    ( atop_req_out_full   ),
      .ready_i    ( atop_req_out_pop    ),
      .data_o     ( atop_data_out       )
    );

    assign avl_atop_ids_o = ~atop_req_out_full;

    `ASSERT(PushingToPendingAtomicTxns, (atop_req_out_push & atop_req_out_full) == '0)

    if (ExtAtomicId) begin : gen_ext_atop_id
      // Atomics need to register an r response with the same ID
      // as the B response. The ID is given by the AW buffer from externally.
      assign req_atop_id = req_atop_id_i;
    end else begin : gen_atop_id
      typedef logic [cf_math_pkg::idx_width(MaxAtomicTxns)-1:0] lzc_cnt_t;
      lzc_cnt_t lzc_cnt, lzc_cnt_q;
      logic [MaxAtomicTxns-1:0] next_free_slots;
      assign next_free_slots = ~(atop_req_out_full | atop_req_out_push) | atop_req_out_pop;
      lzc #(
        .WIDTH  (MaxAtomicTxns)
      ) i_lzc (
        .in_i     ( next_free_slots & avl_atop_ids_i  ),
        .cnt_o    ( lzc_cnt                                 ),
        .empty_o  (                                         )
      );
      // Next free slot needs to be registered to have a stable ID at the AXI interface
      assign req_atop_id = lzc_cnt_q;
      `FFL(lzc_cnt_q, lzc_cnt, req_push_i && req_is_atop_i || !req_valid_i, '0, clk_i, rst_ni)
    end

    always_comb begin
      atop_req_out_push = '0;
      atop_req_out_pop = '0;
      atop_req_out_push[req_atop_id] = req_push_i && req_is_atop_i;
      atop_req_out_pop[rsp_id_i] = rsp_pop_i && rsp_is_atop;
    end

    // Atomics: The ID is the first empty slot in the buffer
    // Non-atomics: The ID is the constant `NonAtomicId`
    assign req_id_o = (req_is_atop_i)? req_atop_id : NonAtomicId;
    assign rsp_buf_o = (rsp_is_atop)? atop_data_out[rsp_id_i] : no_atop_buf_out;
    assign req_full_o = (req_is_atop_i)? &atop_req_out_full : no_atop_buf_full;
  end else begin : gen_no_atop_support
    assign req_id_o = NonAtomicId;
    assign rsp_buf_o = no_atop_buf_out;
    assign req_full_o = no_atop_buf_full;
    assign avl_atop_ids_o = '0;
  end

  `ASSERT(NoAtopSupport, !(!AtopSupport && (req_push_i && req_is_atop_i)))

endmodule
