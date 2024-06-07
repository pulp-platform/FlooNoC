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
  /// Number of unique non-atomic IDs
  parameter int MaxUniqueIDs  = 32'd1,
  /// Enable support for atomics
  parameter bit AtopSupport   = 1'b1,
  /// Number of outstanding atomic requests
  parameter int MaxAtomicTxns = 32'd1,
  /// Information to be buffered for responses
  parameter type buf_t        = logic,
  /// ID width of incoming requests
  parameter int IdInWidth     = 32'd4,
  /// ID width of outgoing requests
  parameter int IdOutWidth    = 32'd2,
  /// AXI request channel
  parameter type axi_req_t    = logic,
  /// AXI response channel
  parameter type axi_rsp_t    = logic,
  /// ID type for incoming requests
  localparam type id_in_t      = logic[IdInWidth-1:0],
  /// ID type for outgoing responses
  localparam type id_out_t     = logic[IdOutWidth-1:0],
  /// Minimum IdWidth
  localparam int IdMinWidth    = (IdInWidth < IdOutWidth)? IdInWidth : IdOutWidth,
  /// Minimum ID type
  localparam type id_t         = logic[IdMinWidth-1:0],
  /// Constant ID for non-atomic requests
  localparam id_out_t  NonAtomicId = '1
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  axi_req_t axi_req_i,
  output axi_rsp_t axi_rsp_o,
  output axi_req_t axi_req_o,
  input  axi_rsp_t axi_rsp_i,
  input  buf_t aw_buf_i,
  input  buf_t ar_buf_i,
  output buf_t r_buf_o,
  output buf_t b_buf_o
);

  logic ar_no_atop_buf_full, aw_no_atop_buf_full;
  logic ar_no_atop_push, aw_no_atop_push;
  logic ar_no_atop_pop, aw_no_atop_pop;
  logic is_atop_r_rsp, is_atop_b_rsp;
  logic is_atop_aw, atop_has_r_rsp;

  buf_t no_atop_r_buf, no_atop_b_buf;
  buf_t [MaxAtomicTxns-1:0] atop_r_buf, atop_b_buf;

  id_t no_atop_aw_req_id, no_atop_ar_req_id;

  if (MaxUniqueIDs == 1) begin : gen_no_atop_fifos

    assign no_atop_aw_req_id = NonAtomicId;
    assign no_atop_ar_req_id = NonAtomicId;

    fifo_v3 #(
      .FALL_THROUGH ( 1'b0    ),
      .DEPTH        ( MaxTxns ),
      .dtype        ( buf_t   )
    ) i_ar_no_atop_fifo (
      .clk_i,
      .rst_ni,
      .flush_i    ( 1'b0                ),
      .testmode_i ( test_enable_i       ),
      .full_o     ( ar_no_atop_buf_full ),
      .empty_o    (                     ),
      .usage_o    (                     ),
      .data_i     ( ar_buf_i            ),
      .push_i     ( ar_no_atop_push     ),
      .data_o     ( no_atop_r_buf       ),
      .pop_i      ( ar_no_atop_pop      )
    );

    fifo_v3 #(
      .FALL_THROUGH ( 1'b0    ),
      .DEPTH        ( MaxTxns ),
      .dtype        ( buf_t   )
    ) i_aw_no_atop_fifo (
      .clk_i,
      .rst_ni,
      .flush_i    ( 1'b0                ),
      .testmode_i ( test_enable_i       ),
      .full_o     ( aw_no_atop_buf_full ),
      .empty_o    (                     ),
      .usage_o    (                     ),
      .data_i     ( aw_buf_i            ),
      .push_i     ( aw_no_atop_push     ),
      .data_o     ( no_atop_b_buf       ),
      .pop_i      ( aw_no_atop_pop      )
    );

  end else begin : gen_no_atop_id_queue

    logic b_outp_gnt, b_oup_data_valid;
    logic r_outp_gnt, r_oup_data_valid;

    assign no_atop_aw_req_id = NonAtomicId - id_t'(axi_req_i.aw.id);
    assign no_atop_ar_req_id = NonAtomicId - id_t'(axi_req_i.ar.id);

    id_queue #(
      .ID_WIDTH           (IdMinWidth),
      .CAPACITY           (MaxTxns),
      .FULL_BW            (1'b0),
      .data_t             (buf_t)
    ) i_aw_no_atop_id_queue (
      .clk_i,
      .rst_ni,
      .inp_id_i        (id_t'(axi_req_i.aw.id)),
      .inp_data_i      (aw_buf_i),
      .inp_req_i       (aw_no_atop_push),
      .inp_gnt_o       (aw_no_atop_buf_full),
      .exists_data_i   ('0),
      .exists_mask_i   ('0),
      .exists_req_i    ('0),
      .exists_o        (),
      .exists_gnt_o    (),
      .oup_id_i        (axi_rsp_i.b.id),
      .oup_pop_i       (aw_no_atop_pop),
      .oup_req_i       (axi_rsp_i.b_valid),
      .oup_data_o      (no_atop_b_buf),
      .oup_data_valid_o(b_oup_data_valid),
      .oup_gnt_o       (b_outp_gnt)
    );

    id_queue #(
      .ID_WIDTH           (IdMinWidth),
      .CAPACITY           (MaxTxns),
      .FULL_BW            (1'b0),
      .data_t             (buf_t)
    ) i_ar_no_atop_id_queue (
      .clk_i,
      .rst_ni,
      .inp_id_i        (id_t'(axi_req_i.ar.id)),
      .inp_data_i      (ar_buf_i),
      .inp_req_i       (ar_no_atop_push),
      .inp_gnt_o       (ar_no_atop_buf_full),
      .exists_data_i   ('0),
      .exists_mask_i   ('0),
      .exists_req_i    ('0),
      .exists_o        (),
      .exists_gnt_o    (),
      .oup_id_i        (axi_rsp_i.r.id),
      .oup_pop_i       (ar_no_atop_pop),
      .oup_req_i       (axi_rsp_i.r_valid),
      .oup_data_o      (no_atop_b_buf),
      .oup_data_valid_o(r_oup_data_valid),
      .oup_gnt_o       (r_oup_gnt)
    );

    `ASSERT(NoBResponseIdQueue, axi_rsp_i.b_valid -> (b_oup_data_valid && b_outp_gnt),
            "Meta data for B response must exist in Id Queue!")
    `ASSERT(NoRResponseIdQueue, axi_rsp_i.r_valid -> (r_oup_data_valid && r_oup_gnt),
            "Meta data for R response must exist in Id Queue!")
  end

  // Non-atomic AR's
  assign ar_no_atop_push = axi_req_o.ar_valid && axi_rsp_i.ar_ready;
  assign ar_no_atop_pop = axi_rsp_o.r_valid && axi_req_i.r_ready && axi_rsp_o.r.last &&
                          !is_atop_r_rsp;
  // Non-atomic AW's
  assign is_atop_aw = axi_req_i.aw_valid && axi_req_i.aw.atop[5:4] != axi_pkg::ATOP_NONE;
  assign aw_no_atop_push = axi_req_o.aw_valid && axi_rsp_i.aw_ready && !is_atop_aw;
  assign aw_no_atop_pop = axi_rsp_o.b_valid && axi_req_i.b_ready && !is_atop_b_rsp;

  assign is_atop_r_rsp = axi_rsp_i.r_valid && axi_rsp_i.r.id > MaxAtomicTxns;
  assign is_atop_b_rsp = axi_rsp_i.b_valid && axi_rsp_i.b.id > MaxAtomicTxns;
  `ASSERT(NoAtopSupport, !(!AtopSupport && is_atop_aw),
          "Atomics not supported, but atomic request received!")

  assign r_buf_o = (is_atop_r_rsp && AtopSupport)? atop_r_buf[axi_rsp_i.r.id] : no_atop_r_buf;
  assign b_buf_o = (is_atop_b_rsp && AtopSupport)? atop_b_buf[axi_rsp_i.b.id] : no_atop_b_buf;

  if (AtopSupport) begin : gen_atop_support

    logic [MaxAtomicTxns-1:0] ar_atop_reg_full, aw_atop_reg_full;
    logic [MaxAtomicTxns-1:0] ar_atop_reg_empty, aw_atop_reg_empty;
    logic [MaxAtomicTxns-1:0] ar_atop_reg_push, aw_atop_reg_push;
    logic [MaxAtomicTxns-1:0] ar_atop_reg_pop, aw_atop_reg_pop;
    logic [MaxAtomicTxns-1:0] available_atop_ids;
    logic no_atop_id_available;

    assign atop_has_r_rsp = axi_req_i.aw.atop[axi_pkg::ATOP_R_RESP];
    assign available_atop_ids = ar_atop_reg_empty & aw_atop_reg_empty;
    assign no_atop_id_available = (available_atop_ids == '0);

    stream_register #(
      .T(buf_t)
    ) i_ar_atop_regs [MaxAtomicTxns-1:0] (
      .clk_i,
      .rst_ni,
      .clr_i      ( '0                ),
      .testmode_i ( test_enable_i     ),
      .valid_i    ( ar_atop_reg_push  ),
      .ready_o    ( ar_atop_reg_empty ),
      .data_i     ( ar_buf_i          ),
      .valid_o    ( ar_atop_reg_full  ),
      .ready_i    ( ar_atop_reg_pop   ),
      .data_o     ( atop_r_buf        )
    );

    stream_register #(
      .T(buf_t)
    ) i_aw_atop_regs [MaxAtomicTxns-1:0] (
      .clk_i,
      .rst_ni,
      .clr_i      ( '0                ),
      .testmode_i ( test_enable_i     ),
      .valid_i    ( aw_atop_reg_push  ),
      .ready_o    ( aw_atop_reg_empty ),
      .data_i     ( aw_buf_i          ),
      .valid_o    ( aw_atop_reg_full  ),
      .ready_i    ( aw_atop_reg_pop   ),
      .data_o     ( atop_b_buf        )
    );

    typedef logic [cf_math_pkg::idx_width(MaxAtomicTxns)-1:0] atop_req_id_t;
    atop_req_id_t lzc_cnt_q, lzc_cnt_d;
    atop_req_id_t atop_req_id;
    logic atop_req_pending_q, atop_req_pending_d;

    lzc #(
      .WIDTH  (MaxAtomicTxns)
    ) i_lzc (
      .in_i     ( available_atop_ids  ),
      .cnt_o    ( lzc_cnt_d           ),
      .empty_o  (                     )
    );

    assign atop_req_id = (atop_req_pending_q)? lzc_cnt_q : lzc_cnt_d;
    assign atop_req_pending_d = is_atop_aw && axi_req_o.aw_valid && !axi_rsp_i.aw_ready;

    `FF(atop_req_pending_q, atop_req_pending_d, '0)
    `FFL(lzc_cnt_q, lzc_cnt_d, !atop_req_pending_q, '0)

    always_comb begin
      ar_atop_reg_push = '0;
      aw_atop_reg_push = '0;
      ar_atop_reg_pop = '0;
      aw_atop_reg_pop = '0;
      ar_atop_reg_push[atop_req_id] = is_atop_aw && atop_has_r_rsp &&
                                      axi_req_o.aw_valid && axi_rsp_i.aw_ready;
      aw_atop_reg_push[atop_req_id] = is_atop_aw && axi_req_o.aw_valid && axi_rsp_i.aw_ready;
      ar_atop_reg_pop[axi_rsp_i.r.id] = is_atop_r_rsp &&
                                        axi_rsp_o.r_valid && axi_req_i.r_ready && axi_rsp_o.r.last;
      aw_atop_reg_pop[axi_rsp_i.b.id] = is_atop_b_rsp && axi_rsp_o.b_valid && axi_req_i.b_ready;
    end

    always_comb begin
      axi_req_o = axi_req_i;
      axi_rsp_o = axi_rsp_i;
      // Use fixed ID for non-atomic requests and unique ID for atomic requests
      axi_req_o.ar.id = no_atop_ar_req_id;
      axi_req_o.aw.id = (is_atop_aw && AtopSupport)? atop_req_id : no_atop_aw_req_id;
      // Use original, buffered ID again for responses
      axi_rsp_o.r.id = (is_atop_r_rsp && AtopSupport)?
                        atop_r_buf[axi_rsp_i.r.id] : no_atop_r_buf.id;
      axi_rsp_o.b.id = (is_atop_b_rsp && AtopSupport)?
                        atop_b_buf[axi_rsp_i.b.id] : no_atop_b_buf.id;
      axi_req_o.ar_valid = axi_req_i.ar_valid && !ar_no_atop_buf_full;
      axi_rsp_o.ar_ready = axi_rsp_i.ar_ready && !ar_no_atop_buf_full;
      axi_req_o.aw_valid = axi_req_i.aw_valid && ((is_atop_aw && AtopSupport)?
                            !no_atop_id_available : !aw_no_atop_buf_full);
      axi_rsp_o.aw_ready = axi_rsp_i.aw_ready && ((is_atop_aw && AtopSupport)?
                            !no_atop_id_available : !aw_no_atop_buf_full);
    end
  end

  `ASSERT_INIT(InvalidMaxUniqueIDs, MaxUniqueIDs > 0)

endmodule
