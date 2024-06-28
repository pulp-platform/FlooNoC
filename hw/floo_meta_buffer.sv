// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/assign.svh"

/// Queue to buffer meta information in the requests
/// that need to be stored until the response arrives.
/// Also supports atomics with unique IDs.
module floo_meta_buffer #(
  /// Maximum number of non-atomic outstanding requests
  parameter int MaxTxns       = 32'd0,
  /// Number of unique non-atomic IDs
  parameter int MaxUniqueIds  = 32'd1,
  /// Enable support for atomics
  parameter bit AtopSupport   = 1'b1,
  /// Number of outstanding atomic requests
  parameter int MaxAtomicTxns = 32'd1,
  /// AXI in request channel
  parameter type axi_in_req_t   = logic,
  /// AXI in response channel
  parameter type axi_in_rsp_t   = logic,
  /// AXI out request channel
  parameter type axi_out_req_t  = logic,
  /// AXI out response channel
  parameter type axi_out_rsp_t  = logic,
  /// Information to be buffered for responses
  parameter type buf_t          = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  axi_in_req_t axi_req_i,
  output axi_in_rsp_t axi_rsp_o,
  output axi_out_req_t axi_req_o,
  input  axi_out_rsp_t axi_rsp_i,
  input  buf_t aw_buf_i,
  input  buf_t ar_buf_i,
  output buf_t r_buf_o,
  output buf_t b_buf_o
);

  // AXI parameters
  localparam int unsigned IdInWidth = $bits(axi_req_i.aw.id);
  localparam int unsigned IdOutWidth = $bits(axi_req_o.aw.id);
  localparam int unsigned IdMinWidth = IdInWidth > IdOutWidth ? IdOutWidth : IdInWidth;
  typedef logic [IdInWidth-1:0] id_in_t;
  typedef logic [IdOutWidth-1:0] id_out_t;
  typedef logic [IdMinWidth-1:0] id_min_t;

  logic ar_no_atop_buf_full, aw_no_atop_buf_full;
  logic ar_no_atop_push, aw_no_atop_push;
  logic ar_no_atop_pop, aw_no_atop_pop;
  logic is_atop_r_rsp, is_atop_b_rsp;
  logic is_atop_aw, atop_has_r_rsp;

  buf_t no_atop_r_buf, no_atop_b_buf;
  buf_t [MaxAtomicTxns-1:0] atop_r_buf, atop_b_buf;

  id_out_t no_atop_aw_req_id, no_atop_ar_req_id;

  if (MaxUniqueIds == 1) begin : gen_no_atop_fifos

    // The ID is set to the constant '1 for non-atomic transactions
    assign no_atop_aw_req_id = '1;
    assign no_atop_ar_req_id = '1;

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

    id_out_t no_atop_aw_req_id_in, no_atop_ar_req_id_in;

    // Non-atomic transaction IDs are assigned to the range [MaxAtomicTxns, 2**IdOutWidth-1),
    // Therefore `MaxAtomicTxns` is added/subtracted to/from the ID to get the original ID
    assign no_atop_aw_req_id = id_min_t'(MaxAtomicTxns) + id_min_t'(axi_req_i.aw.id);
    assign no_atop_ar_req_id = id_min_t'(MaxAtomicTxns) + id_min_t'(axi_req_i.ar.id);
    assign no_atop_aw_req_id_in = axi_rsp_i.b.id - id_min_t'(MaxAtomicTxns);
    assign no_atop_ar_req_id_in = axi_rsp_i.r.id - id_min_t'(MaxAtomicTxns);
    `ASSERT_INIT(TooFewIdBits2, MaxAtomicTxns + id_min_t'('1) < 2**IdOutWidth)

    logic aw_no_atop_buf_not_full, ar_no_atop_buf_not_full;

    id_queue #(
      .ID_WIDTH ( IdMinWidth  ),
      .CAPACITY ( MaxTxns     ),
      .FULL_BW  ( 1'b1        ),
      .data_t   ( buf_t       )
    ) i_aw_no_atop_id_queue (
      .clk_i,
      .rst_ni,
      .inp_id_i         ( id_min_t'(axi_req_i.aw.id)  ),
      .inp_data_i       ( aw_buf_i                    ),
      .inp_req_i        ( aw_no_atop_push             ),
      .inp_gnt_o        ( aw_no_atop_buf_not_full     ),
      .exists_data_i    ( '0                          ),
      .exists_mask_i    ( '0                          ),
      .exists_req_i     ( '0                          ),
      .exists_o         (                             ),
      .exists_gnt_o     (                             ),
      .oup_id_i         ( no_atop_aw_req_id_in        ),
      .oup_pop_i        ( aw_no_atop_pop              ),
      .oup_req_i        ( axi_rsp_i.b_valid           ),
      .oup_data_o       ( no_atop_b_buf               ),
      .oup_data_valid_o ( b_oup_data_valid            ),
      .oup_gnt_o        ( b_outp_gnt                  )
    );

    id_queue #(
      .ID_WIDTH ( IdMinWidth  ),
      .CAPACITY ( MaxTxns     ),
      .FULL_BW  ( 1'b1        ),
      .data_t   ( buf_t       )
    ) i_ar_no_atop_id_queue (
      .clk_i,
      .rst_ni,
      .inp_id_i         ( id_min_t'(axi_req_i.ar.id)  ),
      .inp_data_i       ( ar_buf_i                    ),
      .inp_req_i        ( ar_no_atop_push             ),
      .inp_gnt_o        ( ar_no_atop_buf_not_full     ),
      .exists_data_i    ( '0                          ),
      .exists_mask_i    ( '0                          ),
      .exists_req_i     ( '0                          ),
      .exists_o         (                             ),
      .exists_gnt_o     (                             ),
      .oup_id_i         ( no_atop_ar_req_id_in        ),
      .oup_pop_i        ( ar_no_atop_pop              ),
      .oup_req_i        ( axi_rsp_i.r_valid           ),
      .oup_data_o       ( no_atop_r_buf               ),
      .oup_data_valid_o ( r_oup_data_valid            ),
      .oup_gnt_o        ( r_oup_gnt                   )
    );

    assign ar_no_atop_buf_full = !ar_no_atop_buf_not_full;
    assign aw_no_atop_buf_full = !aw_no_atop_buf_not_full;

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

  assign is_atop_r_rsp = AtopSupport && axi_rsp_i.r_valid && (axi_rsp_i.r.id < MaxAtomicTxns);
  assign is_atop_b_rsp = AtopSupport && axi_rsp_i.b_valid && (axi_rsp_i.b.id < MaxAtomicTxns);
  `ASSERT(NoAtopSupportAw, !(!AtopSupport && is_atop_aw),
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
      `AXI_SET_REQ_STRUCT(axi_req_o, axi_req_i)
      `AXI_SET_RESP_STRUCT(axi_rsp_o, axi_rsp_i)
      // Use fixed ID for non-atomic requests and unique ID for atomic requests
      axi_req_o.ar.id = no_atop_ar_req_id;
      axi_req_o.aw.id = (is_atop_aw)? atop_req_id : no_atop_aw_req_id;
      // Use original, buffered ID again for responses
      axi_rsp_o.r.id = (is_atop_r_rsp)? atop_r_buf[axi_rsp_i.r.id] : no_atop_r_buf.id;
      axi_rsp_o.b.id = (is_atop_b_rsp)? atop_b_buf[axi_rsp_i.b.id] : no_atop_b_buf.id;
      axi_req_o.ar_valid = axi_req_i.ar_valid && !ar_no_atop_buf_full;
      axi_rsp_o.ar_ready = axi_rsp_i.ar_ready && !ar_no_atop_buf_full;
      axi_req_o.aw_valid = axi_req_i.aw_valid && ((is_atop_aw)?
                            !no_atop_id_available : !aw_no_atop_buf_full);
      axi_rsp_o.aw_ready = axi_rsp_i.aw_ready && ((is_atop_aw)?
                            !no_atop_id_available : !aw_no_atop_buf_full);
    end
  end else begin : gen_no_atop_support
    always_comb begin
      `AXI_SET_REQ_STRUCT(axi_req_o, axi_req_i)
      `AXI_SET_RESP_STRUCT(axi_rsp_o, axi_rsp_i)
      // Use fixed ID for non-atomic requests and unique ID for atomic requests
      axi_req_o.ar.id = no_atop_ar_req_id;
      axi_req_o.aw.id = no_atop_aw_req_id;
      // Use original, buffered ID again for responses
      axi_rsp_o.r.id = no_atop_r_buf.id;
      axi_rsp_o.b.id = no_atop_b_buf.id;
      axi_req_o.ar_valid = axi_req_i.ar_valid && !ar_no_atop_buf_full;
      axi_rsp_o.ar_ready = axi_rsp_i.ar_ready && !ar_no_atop_buf_full;
      axi_req_o.aw_valid = axi_req_i.aw_valid && !aw_no_atop_buf_full;
      axi_rsp_o.aw_ready = axi_rsp_i.aw_ready && !aw_no_atop_buf_full;
    end
  end

  // Check that `MaxAtomicTxns` is zero if atomics are not supported
  `ASSERT_INIT(NoAtomicTxns, AtopSupport || (!AtopSupport && (MaxAtomicTxns == 0)))
  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(TooFewIdBits1, MaxUniqueIds + MaxAtomicTxns <= 2**IdOutWidth)

endmodule
