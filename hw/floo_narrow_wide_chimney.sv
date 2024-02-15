// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/assign.svh"

/// A bidirectional network interface for connecting narrow & wide AXI Buses to the multi-link NoC
module floo_narrow_wide_chimney
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
#(
  /// FlooNoC defines subordinate ports as requests that go out
  /// of the NoC to AXI subordinates (i.e. memories) that return
  /// a response, and manager ports as requests that come into the
  /// NoC from AXI managers (i.e. cores)
  /// Enable the subordinate port of the Narrow AXI4 interface
  parameter bit EnNarrowSbrPort                  = 1'b1,
  /// Enable the manager port of the Narrow AXI4 interface
  parameter bit EnNarrowMgrPort                  = 1'b1,
  /// Enable the subordinate port of the Wide AXI4 interface
  parameter bit EnWideSbrPort                    = 1'b1,
  /// Enable the manager port of the Wide AXI4 interface
  parameter bit EnWideMgrPort                    = 1'b1,
  /// Atomic operation support, currently only implemented for
  /// the narrow network!
  parameter bit AtopSupport                      = 1'b1,
  /// Maximum number of oustanding Atomic transactions,
  /// must be smaller or equal to 2**AxiOutIdWidth-1 since
  /// Every atomic transactions needs to have a unique ID
  /// and one ID is reserved for non-atomic transactions
  parameter int unsigned MaxAtomicTxns           = 1,
  /// Number of maximum oustanding requests on the narrow network
  parameter int unsigned NarrowMaxTxns           = 32,
  /// Number of maximum oustanding requests on the wide network
  parameter int unsigned WideMaxTxns             = 32,
  /// Maximum number of outstanding requests per ID on the narrow network
  parameter int unsigned NarrowMaxTxnsPerId      = NarrowMaxTxns,
  /// Maximum number of outstanding requests per ID on the wide network
  parameter int unsigned WideMaxTxnsPerId        = WideMaxTxns,
  /// Type of the narrow reorder buffer
  parameter rob_type_e NarrowRoBType             = NoRoB,
  /// Type of the wide reorder buffer
  parameter rob_type_e WideRoBType               = NoRoB,
  /// Capacity of the narrow reorder buffers
  parameter int unsigned NarrowReorderBufferSize = 256,
  /// Capacity of the wide reorder buffers
  parameter int unsigned WideReorderBufferSize   = 256,
  /// Cut timing paths of outgoing requests to the NoC
  parameter bit CutAx                            = 1'b1,
  /// Cut timing paths of incoming responses from the NoC
  parameter bit CutRsp                           = 1'b1,
  /// Type for implementation inputs and outputs
  parameter type sram_cfg_t                      = logic,
  /// Number of routes in the routing table
  parameter int unsigned NumRoutes               = 0
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  sram_cfg_t  sram_cfg_i,
  /// AXI4 side interfaces
  input  axi_narrow_in_req_t axi_narrow_in_req_i,
  output axi_narrow_in_rsp_t axi_narrow_in_rsp_o,
  output axi_narrow_out_req_t axi_narrow_out_req_o,
  input  axi_narrow_out_rsp_t axi_narrow_out_rsp_i,
  input  axi_wide_in_req_t axi_wide_in_req_i,
  output axi_wide_in_rsp_t axi_wide_in_rsp_o,
  output axi_wide_out_req_t axi_wide_out_req_o,
  input  axi_wide_out_rsp_t axi_wide_out_rsp_i,
  /// Coordinates/ID of the current tile
  input  id_t id_i,
  /// Routing table for the current tile
  input  route_t [NumRoutes-1:0] route_table_i,
  /// Output to NoC
  output floo_req_t   floo_req_o,
  output floo_rsp_t   floo_rsp_o,
  output floo_wide_t  floo_wide_o,
  /// Input from NoC
  input  floo_req_t   floo_req_i,
  input  floo_rsp_t   floo_rsp_i,
  input  floo_wide_t  floo_wide_i
);

  // Duplicate AXI port signals to degenerate ports
  // in case they are not used
  axi_narrow_in_req_t axi_narrow_req_in;
  axi_narrow_in_rsp_t axi_narrow_rsp_out;
  axi_wide_in_req_t axi_wide_req_in;
  axi_wide_in_rsp_t axi_wide_rsp_out;

  // AX queue
  axi_narrow_in_aw_chan_t axi_narrow_aw_queue;
  axi_narrow_in_ar_chan_t axi_narrow_ar_queue;
  axi_wide_in_aw_chan_t axi_wide_aw_queue;
  axi_wide_in_ar_chan_t axi_wide_ar_queue;
  logic axi_narrow_aw_queue_valid_out, axi_narrow_aw_queue_ready_in;
  logic axi_narrow_ar_queue_valid_out, axi_narrow_ar_queue_ready_in;
  logic axi_wide_aw_queue_valid_out, axi_wide_aw_queue_ready_in;
  logic axi_wide_ar_queue_valid_out, axi_wide_ar_queue_ready_in;

  floo_req_chan_t [WideAr:NarrowAw] floo_req_arb_in;
  floo_rsp_chan_t [WideB:NarrowB] floo_rsp_arb_in;
  floo_wide_chan_t [WideR:WideAw] floo_wide_arb_in;
  logic  [WideAr:NarrowAw] floo_req_arb_req_in, floo_req_arb_gnt_out;
  logic  [WideB:NarrowB]   floo_rsp_arb_req_in, floo_rsp_arb_gnt_out;
  logic  [WideR:WideAw]    floo_wide_arb_req_in, floo_wide_arb_gnt_out;

  // flit queue
  floo_req_chan_t floo_req_in;
  floo_rsp_chan_t floo_rsp_in;
  floo_wide_chan_t floo_wide_in;
  logic floo_req_in_valid, floo_rsp_in_valid, floo_wide_in_valid;
  logic floo_req_out_ready, floo_rsp_out_ready, floo_wide_out_ready;
  logic [NumAxiChannels-1:0] axi_valid_in, axi_ready_out;

  // Flit packing
  floo_narrow_aw_flit_t floo_narrow_aw;
  floo_narrow_ar_flit_t floo_narrow_ar;
  floo_narrow_w_flit_t  floo_narrow_w;
  floo_narrow_b_flit_t  floo_narrow_b;
  floo_narrow_r_flit_t  floo_narrow_r;
  floo_wide_aw_flit_t floo_wide_aw;
  floo_wide_ar_flit_t floo_wide_ar;
  floo_wide_w_flit_t  floo_wide_w;
  floo_wide_b_flit_t  floo_wide_b;
  floo_wide_r_flit_t  floo_wide_r;

  // Flit arbitration
  typedef enum logic {SelAw, SelW} aw_w_sel_e;
  aw_w_sel_e narrow_aw_w_sel_q, narrow_aw_w_sel_d;
  aw_w_sel_e wide_aw_w_sel_q, wide_aw_w_sel_d;

  // Flit unpacking
  axi_narrow_in_aw_chan_t axi_narrow_unpack_aw;
  axi_narrow_in_w_chan_t  axi_narrow_unpack_w;
  axi_narrow_in_b_chan_t  axi_narrow_unpack_b;
  axi_narrow_in_ar_chan_t axi_narrow_unpack_ar;
  axi_narrow_in_r_chan_t  axi_narrow_unpack_r;
  axi_wide_in_aw_chan_t   axi_wide_unpack_aw;
  axi_wide_in_w_chan_t    axi_wide_unpack_w;
  axi_wide_in_b_chan_t    axi_wide_unpack_b;
  axi_wide_in_ar_chan_t   axi_wide_unpack_ar;
  axi_wide_in_r_chan_t    axi_wide_unpack_r;
  floo_req_generic_flit_t   floo_req_unpack_generic;
  floo_rsp_generic_flit_t   floo_rsp_unpack_generic;
  floo_wide_generic_flit_t  floo_wide_unpack_generic;

  // Meta Buffers
  axi_narrow_in_req_t axi_narrow_meta_buf_req_in, axi_narrow_meta_buf_req_out;
  axi_narrow_in_rsp_t axi_narrow_meta_buf_rsp_in, axi_narrow_meta_buf_rsp_out;
  axi_wide_in_req_t   axi_wide_meta_buf_req_in, axi_wide_meta_buf_req_out;
  axi_wide_in_rsp_t   axi_wide_meta_buf_rsp_in, axi_wide_meta_buf_rsp_out;
  `AXI_ASSIGN_REQ_STRUCT(axi_narrow_out_req_o, axi_narrow_meta_buf_req_out)
  `AXI_ASSIGN_RESP_STRUCT(axi_narrow_meta_buf_rsp_in, axi_narrow_out_rsp_i)
  `AXI_ASSIGN_REQ_STRUCT(axi_wide_out_req_o, axi_wide_meta_buf_req_out)
  `AXI_ASSIGN_RESP_STRUCT(axi_wide_meta_buf_rsp_in, axi_wide_out_rsp_i)

  // ID tracking
  typedef struct packed {
    axi_narrow_in_id_t  id;
    logic               rob_req;
    rob_idx_t           rob_idx;
    id_t                src_id;
    logic               atop;
  } narrow_id_out_buf_t;

  typedef struct packed {
    axi_wide_in_id_t  id;
    logic             rob_req;
    rob_idx_t         rob_idx;
    id_t              src_id;
  } wide_id_out_buf_t;

  // Routing
  dst_t [NumAxiChannels-1:0] dst_id;
  dst_t narrow_aw_id_q, wide_aw_id_q;
  route_t [NumAxiChannels-1:0] route_out;
  id_t [NumAxiChannels-1:0] id_out;


  narrow_id_out_buf_t narrow_aw_out_data_in, narrow_aw_out_data_out;
  narrow_id_out_buf_t narrow_ar_out_data_in, narrow_ar_out_data_out;
  wide_id_out_buf_t wide_aw_out_data_in, wide_aw_out_data_out;
  wide_id_out_buf_t wide_ar_out_data_in, wide_ar_out_data_out;

  ///////////////////////
  //  Spill registers  //
  ///////////////////////

  if (EnNarrowMgrPort) begin : gen_narrow_sbr_port

    assign axi_narrow_req_in = axi_narrow_in_req_i;
    assign axi_narrow_in_rsp_o = axi_narrow_rsp_out;

    if (CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_narrow_in_aw_chan_t )
      ) i_narrow_aw_queue (
        .clk_i,
        .rst_ni,
        .data_i   ( axi_narrow_in_req_i.aw        ),
        .valid_i  ( axi_narrow_in_req_i.aw_valid  ),
        .ready_o  ( axi_narrow_rsp_out.aw_ready   ),
        .data_o   ( axi_narrow_aw_queue           ),
        .valid_o  ( axi_narrow_aw_queue_valid_out ),
        .ready_i  ( axi_narrow_aw_queue_ready_in  )
      );

      spill_register #(
        .T ( axi_narrow_in_ar_chan_t )
      ) i_narrow_ar_queue (
        .clk_i,
        .rst_ni,
        .data_i   ( axi_narrow_in_req_i.ar        ),
        .valid_i  ( axi_narrow_in_req_i.ar_valid  ),
        .ready_o  ( axi_narrow_rsp_out.ar_ready   ),
        .data_o   ( axi_narrow_ar_queue           ),
        .valid_o  ( axi_narrow_ar_queue_valid_out ),
        .ready_i  ( axi_narrow_ar_queue_ready_in  )
      );

    end else begin : gen_ax_no_cuts
      assign axi_narrow_aw_queue = axi_narrow_in_req_i.aw;
      assign axi_narrow_aw_queue_valid_out = axi_narrow_in_req_i.aw_valid;
      assign axi_narrow_rsp_out.aw_ready = axi_narrow_aw_queue_ready_in;
      assign axi_narrow_ar_queue = axi_narrow_in_req_i.ar;
      assign axi_narrow_ar_queue_valid_out = axi_narrow_in_req_i.ar_valid;
      assign axi_narrow_rsp_out.ar_ready = axi_narrow_ar_queue_ready_in;
    end

  end else begin : gen_narrow_err_slv_port
    axi_err_slv #(
      .AxiIdWidth ( AxiNarrowInIdWidth  ),
      .ATOPs      ( AtopSupport         ),
      .axi_req_t  ( axi_narrow_in_req_t ),
      .axi_resp_t ( axi_narrow_in_rsp_t )
    ) i_axi_err_slv (
      .clk_i      ( clk_i               ),
      .rst_ni     ( rst_ni              ),
      .test_i     ( test_enable_i       ),
      .slv_req_i  ( axi_narrow_in_req_i ),
      .slv_resp_o ( axi_narrow_in_rsp_o )
    );
    assign axi_narrow_req_in = '0;
    assign axi_narrow_aw_queue = '0;
    assign axi_narrow_ar_queue = '0;
    assign axi_narrow_aw_queue_valid_out = 1'b0;
    assign axi_narrow_ar_queue_valid_out = 1'b0;
  end

  if (EnWideMgrPort) begin : gen_wide_sbr_port

    assign axi_wide_req_in = axi_wide_in_req_i;
    assign axi_wide_in_rsp_o = axi_wide_rsp_out;

    if (CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_wide_in_aw_chan_t )
      ) i_wide_aw_queue (
        .clk_i,
        .rst_ni,
        .data_i   ( axi_wide_in_req_i.aw        ),
        .valid_i  ( axi_wide_in_req_i.aw_valid  ),
        .ready_o  ( axi_wide_rsp_out.aw_ready   ),
        .data_o   ( axi_wide_aw_queue           ),
        .valid_o  ( axi_wide_aw_queue_valid_out ),
        .ready_i  ( axi_wide_aw_queue_ready_in  )
      );

      spill_register #(
        .T ( axi_wide_in_ar_chan_t )
      ) i_wide_ar_queue (
        .clk_i,
        .rst_ni,
        .data_i   ( axi_wide_in_req_i.ar        ),
        .valid_i  ( axi_wide_in_req_i.ar_valid  ),
        .ready_o  ( axi_wide_rsp_out.ar_ready   ),
        .data_o   ( axi_wide_ar_queue           ),
        .valid_o  ( axi_wide_ar_queue_valid_out ),
        .ready_i  ( axi_wide_ar_queue_ready_in  )
      );
    end else begin : gen_ax_no_cuts
      assign axi_wide_aw_queue = axi_wide_in_req_i.aw;
      assign axi_wide_aw_queue_valid_out = axi_wide_in_req_i.aw_valid;
      assign axi_wide_rsp_out.aw_ready = axi_wide_aw_queue_ready_in;
      assign axi_wide_ar_queue = axi_wide_in_req_i.ar;
      assign axi_wide_ar_queue_valid_out = axi_wide_in_req_i.ar_valid;
      assign axi_wide_rsp_out.ar_ready = axi_wide_ar_queue_ready_in;
    end
  end else begin : gen_wide_err_slv_port
    axi_err_slv #(
      .AxiIdWidth ( AxiWideInIdWidth  ),
      .ATOPs      ( AtopSupport       ),
      .axi_req_t  ( axi_wide_in_req_t ),
      .axi_resp_t ( axi_wide_in_rsp_t )
    ) i_axi_err_slv (
      .clk_i      ( clk_i             ),
      .rst_ni     ( rst_ni            ),
      .test_i     ( test_enable_i     ),
      .slv_req_i  ( axi_wide_in_req_i ),
      .slv_resp_o ( axi_wide_in_rsp_o )
    );
    assign axi_wide_req_in = '0;
    assign axi_wide_aw_queue = '0;
    assign axi_wide_ar_queue = '0;
    assign axi_wide_aw_queue_valid_out = 1'b0;
    assign axi_wide_ar_queue_valid_out = 1'b0;
  end

  if (CutRsp) begin : gen_rsp_cuts
    spill_register #(
      .T ( floo_req_chan_t )
    ) i_narrow_data_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_req_i.req      ),
      .valid_i    ( floo_req_i.valid    ),
      .ready_o    ( floo_req_o.ready    ),
      .data_o     ( floo_req_in         ),
      .valid_o    ( floo_req_in_valid   ),
      .ready_i    ( floo_req_out_ready  )
    );

    spill_register #(
      .T ( floo_rsp_chan_t )
    ) i_narrow_data_rsp_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_rsp_i.rsp      ),
      .valid_i    ( floo_rsp_i.valid    ),
      .ready_o    ( floo_rsp_o.ready    ),
      .data_o     ( floo_rsp_in         ),
      .valid_o    ( floo_rsp_in_valid   ),
      .ready_i    ( floo_rsp_out_ready  )
    );

    spill_register #(
      .T ( floo_wide_chan_t )
    ) i_wide_data_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_wide_i.wide    ),
      .valid_i    ( floo_wide_i.valid   ),
      .ready_o    ( floo_wide_o.ready   ),
      .data_o     ( floo_wide_in        ),
      .valid_o    ( floo_wide_in_valid  ),
      .ready_i    ( floo_wide_out_ready )
    );

  end else begin : gen_no_rsp_cuts
    assign floo_req_in = floo_req_i.req;
    assign floo_rsp_in = floo_rsp_i.rsp;
    assign floo_wide_in = floo_wide_i.wide;
    assign floo_req_in_valid = floo_req_i.valid;
    assign floo_rsp_in_valid = floo_rsp_i.valid;
    assign floo_wide_in_valid = floo_wide_i.valid;
    assign floo_req_o.ready = floo_req_out_ready;
    assign floo_rsp_o.ready = floo_rsp_out_ready;
    assign floo_wide_o.ready = floo_wide_out_ready;
  end

  ///////////////////////
  //  Reorder Buffers  //
  ///////////////////////

  // AW/B RoB
  axi_narrow_in_b_chan_t axi_narrow_b_rob_out, axi_narrow_b_rob_in;
  logic  narrow_aw_rob_req_out;
  rob_idx_t narrow_aw_rob_idx_out;
  logic narrow_aw_rob_valid_out, narrow_aw_rob_ready_in;
  logic narrow_aw_rob_valid_in, narrow_aw_rob_ready_out;
  logic narrow_b_rob_valid_in, narrow_b_rob_ready_out;
  logic narrow_b_rob_valid_out, narrow_b_rob_ready_in;
  axi_wide_in_b_chan_t axi_wide_b_rob_out, axi_wide_b_rob_in;
  logic  wide_aw_rob_req_out;
  rob_idx_t wide_aw_rob_idx_out;
  logic wide_aw_rob_valid_out, wide_aw_rob_ready_in;
  logic wide_b_rob_valid_in, wide_b_rob_ready_out;
  logic wide_b_rob_valid_out, wide_b_rob_ready_in;

  // AR/R RoB
  axi_narrow_in_r_chan_t axi_narrow_r_rob_out, axi_narrow_r_rob_in;
  logic  narrow_ar_rob_req_out;
  rob_idx_t narrow_ar_rob_idx_out;
  logic narrow_ar_rob_valid_out, narrow_ar_rob_ready_in;
  logic narrow_r_rob_valid_in, narrow_r_rob_ready_out;
  logic narrow_r_rob_valid_out, narrow_r_rob_ready_in;
  axi_wide_in_r_chan_t axi_wide_r_rob_out, axi_wide_r_rob_in;
  logic  wide_ar_rob_req_out;
  rob_idx_t wide_ar_rob_idx_out;
  logic wide_ar_rob_valid_out, wide_ar_rob_ready_in;
  logic wide_r_rob_valid_in, wide_r_rob_ready_out;
  logic wide_r_rob_valid_out, wide_r_rob_ready_in;

  logic narrow_b_rob_rob_req;
  logic narrow_b_rob_last;
  rob_idx_t narrow_b_rob_rob_idx;
  assign narrow_b_rob_rob_req = floo_rsp_in.narrow_b.hdr.rob_req;
  assign narrow_b_rob_rob_idx = floo_rsp_in.narrow_b.hdr.rob_idx;
  assign narrow_b_rob_last = floo_rsp_in.narrow_b.hdr.last;

  if (AtopSupport) begin : gen_atop_support
    // Bypass AW/B RoB
    assign narrow_aw_rob_valid_in = axi_narrow_aw_queue_valid_out &&
                                    (axi_narrow_aw_queue.atop == axi_pkg::ATOP_NONE);
    assign axi_narrow_aw_queue_ready_in = (axi_narrow_aw_queue.atop == axi_pkg::ATOP_NONE)?
                                      narrow_aw_rob_ready_out : narrow_aw_rob_ready_in;
  end else begin : gen_no_atop_support
    assign narrow_aw_rob_valid_in = axi_narrow_aw_queue_valid_out;
    assign axi_narrow_aw_queue_ready_in = narrow_aw_rob_ready_in;
    `ASSERT(NoAtopSupport, !(axi_narrow_aw_queue_valid_out &&
                             (axi_narrow_aw_queue.atop != axi_pkg::ATOP_NONE)))
  end

  floo_rob_wrapper #(
    .RoBType            ( NarrowRoBType           ),
    .ReorderBufferSize  ( NarrowReorderBufferSize ),
    .MaxRoTxnsPerId     ( NarrowMaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b1                    ),
    .ax_len_t           ( axi_pkg::len_t          ),
    .ax_id_t            ( axi_narrow_in_id_t      ),
    .rsp_chan_t         ( axi_narrow_in_b_chan_t  ),
    .rsp_meta_t         ( axi_narrow_in_b_chan_t  ),
    .rob_idx_t          ( rob_idx_t               ),
    .dest_t             ( id_t                    ),
    .sram_cfg_t         ( sram_cfg_t              )
  ) i_narrow_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( narrow_aw_rob_valid_in  ),
    .ax_ready_o     ( narrow_aw_rob_ready_out ),
    .ax_len_i       ( axi_narrow_aw_queue.len ),
    .ax_id_i        ( axi_narrow_aw_queue.id  ),
    .ax_dest_i      ( id_out[NarrowAw]        ),
    .ax_valid_o     ( narrow_aw_rob_valid_out ),
    .ax_ready_i     ( narrow_aw_rob_ready_in  ),
    .ax_rob_req_o   ( narrow_aw_rob_req_out   ),
    .ax_rob_idx_o   ( narrow_aw_rob_idx_out   ),
    .rsp_valid_i    ( narrow_b_rob_valid_in   ),
    .rsp_ready_o    ( narrow_b_rob_ready_out  ),
    .rsp_i          ( axi_narrow_b_rob_in     ),
    .rsp_rob_req_i  ( narrow_b_rob_rob_req    ),
    .rsp_rob_idx_i  ( narrow_b_rob_rob_idx    ),
    .rsp_last_i     ( narrow_b_rob_last       ),
    .rsp_valid_o    ( narrow_b_rob_valid_out  ),
    .rsp_ready_i    ( narrow_b_rob_ready_in   ),
    .rsp_o          ( axi_narrow_b_rob_out    )
  );

  logic wide_b_rob_rob_req;
  logic wide_b_rob_last;
  rob_idx_t wide_b_rob_rob_idx;
  assign wide_b_rob_rob_req = floo_rsp_in.wide_b.hdr.rob_req;
  assign wide_b_rob_rob_idx = floo_rsp_in.wide_b.hdr.rob_idx;
  assign wide_b_rob_last = floo_rsp_in.wide_b.hdr.last;

  floo_rob_wrapper #(
    .RoBType            ( WideRoBType           ),
    .ReorderBufferSize  ( WideReorderBufferSize ),
    .MaxRoTxnsPerId     ( WideMaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b1                  ),
    .ax_len_t           ( axi_pkg::len_t        ),
    .ax_id_t            ( axi_wide_in_id_t      ),
    .rsp_chan_t         ( axi_wide_in_b_chan_t  ),
    .rsp_meta_t         ( axi_wide_in_b_chan_t  ),
    .rob_idx_t          ( rob_idx_t             ),
    .dest_t             ( id_t                  ),
    .sram_cfg_t         ( sram_cfg_t            )
  ) i_wide_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( axi_wide_aw_queue_valid_out ),
    .ax_ready_o     ( axi_wide_aw_queue_ready_in  ),
    .ax_len_i       ( axi_wide_aw_queue.len       ),
    .ax_id_i        ( axi_wide_aw_queue.id        ),
    .ax_dest_i      ( id_out[WideAw]              ),
    .ax_valid_o     ( wide_aw_rob_valid_out       ),
    .ax_ready_i     ( wide_aw_rob_ready_in        ),
    .ax_rob_req_o   ( wide_aw_rob_req_out         ),
    .ax_rob_idx_o   ( wide_aw_rob_idx_out         ),
    .rsp_valid_i    ( wide_b_rob_valid_in         ),
    .rsp_ready_o    ( wide_b_rob_ready_out        ),
    .rsp_i          ( axi_wide_b_rob_in           ),
    .rsp_rob_req_i  ( wide_b_rob_rob_req          ),
    .rsp_rob_idx_i  ( wide_b_rob_rob_idx          ),
    .rsp_last_i     ( wide_b_rob_last             ),
    .rsp_valid_o    ( wide_b_rob_valid_out        ),
    .rsp_ready_i    ( wide_b_rob_ready_in         ),
    .rsp_o          ( axi_wide_b_rob_out          )
  );

  typedef struct packed {
    axi_narrow_in_id_t    id;
    axi_narrow_in_user_t  user;
    axi_pkg::resp_t       resp;
    logic                 last;
  } narrow_meta_t;

  typedef struct packed {
    axi_wide_in_id_t    id;
    axi_wide_in_user_t  user;
    axi_pkg::resp_t     resp;
    logic               last;
  } wide_meta_t;

  logic narrow_r_rob_rob_req;
  logic narrow_r_rob_last;
  rob_idx_t narrow_r_rob_rob_idx;
  assign narrow_r_rob_rob_req = floo_rsp_in.narrow_r.hdr.rob_req;
  assign narrow_r_rob_rob_idx = floo_rsp_in.narrow_r.hdr.rob_idx;
  assign narrow_r_rob_last = floo_rsp_in.narrow_r.r.last;

  floo_rob_wrapper #(
    .RoBType            ( NarrowRoBType           ),
    .ReorderBufferSize  ( NarrowReorderBufferSize ),
    .MaxRoTxnsPerId     ( NarrowMaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b0                    ),
    .ax_len_t           ( axi_pkg::len_t          ),
    .ax_id_t            ( axi_narrow_in_id_t      ),
    .rsp_chan_t         ( axi_narrow_in_r_chan_t  ),
    .rsp_data_t         ( axi_narrow_in_data_t    ),
    .rsp_meta_t         ( narrow_meta_t           ),
    .rob_idx_t          ( rob_idx_t               ),
    .dest_t             ( id_t                    ),
    .sram_cfg_t         ( sram_cfg_t              )
  ) i_narrow_r_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( axi_narrow_ar_queue_valid_out ),
    .ax_ready_o     ( axi_narrow_ar_queue_ready_in  ),
    .ax_len_i       ( axi_narrow_ar_queue.len       ),
    .ax_id_i        ( axi_narrow_ar_queue.id        ),
    .ax_dest_i      ( id_out[NarrowAr]              ),
    .ax_valid_o     ( narrow_ar_rob_valid_out       ),
    .ax_ready_i     ( narrow_ar_rob_ready_in        ),
    .ax_rob_req_o   ( narrow_ar_rob_req_out         ),
    .ax_rob_idx_o   ( narrow_ar_rob_idx_out         ),
    .rsp_valid_i    ( narrow_r_rob_valid_in         ),
    .rsp_ready_o    ( narrow_r_rob_ready_out        ),
    .rsp_i          ( axi_narrow_r_rob_in           ),
    .rsp_rob_req_i  ( narrow_r_rob_rob_req          ),
    .rsp_rob_idx_i  ( narrow_r_rob_rob_idx          ),
    .rsp_last_i     ( narrow_r_rob_last             ),
    .rsp_valid_o    ( narrow_r_rob_valid_out        ),
    .rsp_ready_i    ( narrow_r_rob_ready_in         ),
    .rsp_o          ( axi_narrow_r_rob_out          )
  );

  logic wide_r_rob_rob_req;
  logic wide_r_rob_last;
  rob_idx_t wide_r_rob_rob_idx;
  assign wide_r_rob_rob_req = floo_wide_in.wide_r.hdr.rob_req;
  assign wide_r_rob_rob_idx = floo_wide_in.wide_r.hdr.rob_idx;
  assign wide_r_rob_last = floo_wide_in.wide_r.r.last;

  floo_rob_wrapper #(
    .RoBType            ( WideRoBType           ),
    .ReorderBufferSize  ( WideReorderBufferSize ),
    .MaxRoTxnsPerId     ( WideMaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b0                  ),
    .ax_len_t           ( axi_pkg::len_t        ),
    .ax_id_t            ( axi_wide_in_id_t      ),
    .rsp_chan_t         ( axi_wide_in_r_chan_t  ),
    .rsp_data_t         ( axi_wide_in_data_t    ),
    .rsp_meta_t         ( wide_meta_t           ),
    .rob_idx_t          ( rob_idx_t             ),
    .dest_t             ( id_t                  ),
    .sram_cfg_t         ( sram_cfg_t            )
  ) i_wide_r_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( axi_wide_ar_queue_valid_out ),
    .ax_ready_o     ( axi_wide_ar_queue_ready_in  ),
    .ax_len_i       ( axi_wide_ar_queue.len       ),
    .ax_id_i        ( axi_wide_ar_queue.id        ),
    .ax_dest_i      ( id_out[WideAr]              ),
    .ax_valid_o     ( wide_ar_rob_valid_out       ),
    .ax_ready_i     ( wide_ar_rob_ready_in        ),
    .ax_rob_req_o   ( wide_ar_rob_req_out         ),
    .ax_rob_idx_o   ( wide_ar_rob_idx_out         ),
    .rsp_valid_i    ( wide_r_rob_valid_in         ),
    .rsp_ready_o    ( wide_r_rob_ready_out        ),
    .rsp_i          ( axi_wide_r_rob_in           ),
    .rsp_rob_req_i  ( wide_r_rob_rob_req          ),
    .rsp_rob_idx_i  ( wide_r_rob_rob_idx          ),
    .rsp_last_i     ( wide_r_rob_last             ),
    .rsp_valid_o    ( wide_r_rob_valid_out        ),
    .rsp_ready_i    ( wide_r_rob_ready_in         ),
    .rsp_o          ( axi_wide_r_rob_out          )
  );

  /////////////////
  //   ROUTING   //
  /////////////////

  typedef axi_narrow_in_addr_t addr_t;

  floo_route_comp #(
    .RouteAlgo      ( RouteAlgo       ),
    .UseIdTable     ( UseIdTable      ),
    .XYAddrOffsetX  ( XYAddrOffsetX   ),
    .XYAddrOffsetY  ( XYAddrOffsetY   ),
    .IdAddrOffset   ( IdAddrOffset    ),
    .NumAddrRules   ( SamNumRules     ),
    .NumRoutes      ( NumRoutes       ),
    .id_t           ( id_t            ),
    .addr_t         ( addr_t          ),
    .addr_rule_t    ( sam_rule_t      ),
    .route_t        ( route_t         )
  ) i_floo_req_route_comp [3:0] (
    .clk_i,
    .rst_ni,
    .route_table_i,
    .addr_map_i ( Sam ),
    .id_i       ( '0  ),
    .addr_i ({
      axi_narrow_aw_queue.addr, axi_narrow_ar_queue.addr,
      axi_wide_aw_queue.addr, axi_wide_ar_queue.addr
    }),
    .route_o  ({route_out[NarrowAw], route_out[NarrowAr], route_out[WideAw], route_out[WideAr]} ),
    .id_o     ({id_out[NarrowAw], id_out[NarrowAr],id_out[WideAw], id_out[WideAr]}              )
  );

  if (RouteAlgo == SourceRouting) begin : gen_route_field
    floo_route_comp #(
      .RouteAlgo    ( RouteAlgo   ),
      .UseIdTable   ( 1'b0        ),
      .NumAddrRules ( SamNumRules ),
      .NumRoutes    ( NumRoutes   ),
      .id_t         ( id_t        ),
      .addr_t       ( addr_t      ),
      .addr_rule_t  ( sam_rule_t  ),
      .route_t      ( route_t     )
      ) i_floo_rsp_route_comp [3:0] (
      .clk_i,
      .rst_ni,
      .route_table_i,
      .addr_i     ( '0 ),
      .addr_map_i ( '0 ),
      .id_i ({
        narrow_aw_out_data_out.src_id, narrow_ar_out_data_out.src_id,
        wide_aw_out_data_out.src_id, wide_ar_out_data_out.src_id
      }),
      .route_o  ({route_out[NarrowB], route_out[NarrowR], route_out[WideB], route_out[WideR]} ),
      .id_o     ({id_out[NarrowB], id_out[NarrowR], id_out[WideB], id_out[WideR]}             )
    );
    assign route_out[NarrowW] = narrow_aw_id_q;
    assign route_out[WideW]   = wide_aw_id_q;
    assign dst_id = route_out;
  end else begin : gen_dst_field
    assign dst_id[NarrowAw] = id_out[NarrowAw];
    assign dst_id[NarrowAr] = id_out[NarrowAr];
    assign dst_id[WideAw]   = id_out[WideAw];
    assign dst_id[WideAr]   = id_out[WideAr];
    assign dst_id[NarrowB]  = narrow_aw_out_data_out.src_id;
    assign dst_id[NarrowR]  = narrow_ar_out_data_out.src_id;
    assign dst_id[WideB]    = wide_aw_out_data_out.src_id;
    assign dst_id[WideR]    = wide_ar_out_data_out.src_id;
    assign dst_id[NarrowW]  = narrow_aw_id_q;
    assign dst_id[WideW]    = wide_aw_id_q;
  end

  `FFL(narrow_aw_id_q, dst_id[NarrowAw], axi_narrow_aw_queue_valid_out &&
                                         axi_narrow_aw_queue_ready_in, '0)
  `FFL(wide_aw_id_q, dst_id[WideAw], axi_wide_aw_queue_valid_out &&
                                     axi_wide_aw_queue_ready_in, '0)

  ///////////////////
  // FLIT PACKING  //
  ///////////////////

  always_comb begin
    floo_narrow_aw              = '0;
    floo_narrow_aw.hdr.rob_req  = narrow_aw_rob_req_out;
    floo_narrow_aw.hdr.rob_idx  = rob_idx_t'(narrow_aw_rob_idx_out);
    floo_narrow_aw.hdr.dst_id   = dst_id[NarrowAw];
    floo_narrow_aw.hdr.src_id   = id_i;
    floo_narrow_aw.hdr.last     = 1'b0;  // AW and W need to be sent together
    floo_narrow_aw.hdr.axi_ch   = NarrowAw;
    floo_narrow_aw.hdr.atop     = axi_narrow_aw_queue.atop != axi_pkg::ATOP_NONE;
    floo_narrow_aw.aw           = axi_narrow_aw_queue;
  end

  always_comb begin
    floo_narrow_w               = '0;
    floo_narrow_w.hdr.rob_req   = narrow_aw_rob_req_out;
    floo_narrow_w.hdr.rob_idx   = rob_idx_t'(narrow_aw_rob_idx_out);
    floo_narrow_w.hdr.dst_id    = dst_id[NarrowW];
    floo_narrow_w.hdr.src_id    = id_i;
    floo_narrow_w.hdr.last      = axi_narrow_req_in.w.last;
    floo_narrow_w.hdr.axi_ch    = NarrowW;
    floo_narrow_w.w             = axi_narrow_req_in.w;
  end

  always_comb begin
    floo_narrow_ar              = '0;
    floo_narrow_ar.hdr.rob_req  = narrow_ar_rob_req_out;
    floo_narrow_ar.hdr.rob_idx  = rob_idx_t'(narrow_ar_rob_idx_out);
    floo_narrow_ar.hdr.dst_id   = dst_id[NarrowAr];
    floo_narrow_ar.hdr.src_id   = id_i;
    floo_narrow_ar.hdr.last     = 1'b1;
    floo_narrow_ar.hdr.axi_ch   = NarrowAr;
    floo_narrow_ar.ar           = axi_narrow_ar_queue;
  end

  always_comb begin
    floo_narrow_b             = '0;
    floo_narrow_b.hdr.rob_req = narrow_aw_out_data_out.rob_req;
    floo_narrow_b.hdr.rob_idx = rob_idx_t'(narrow_aw_out_data_out.rob_idx);
    floo_narrow_b.hdr.dst_id  = dst_id[NarrowB];
    floo_narrow_b.hdr.src_id  = id_i;
    floo_narrow_b.hdr.last    = 1'b1;
    floo_narrow_b.hdr.axi_ch  = NarrowB;
    floo_narrow_b.hdr.atop    = narrow_aw_out_data_out.atop;
    floo_narrow_b.b           = axi_narrow_meta_buf_rsp_out.b;
    floo_narrow_b.b.id        = narrow_aw_out_data_out.id;
  end

  always_comb begin
    floo_narrow_r             = '0;
    floo_narrow_r.hdr.rob_req = narrow_ar_out_data_out.rob_req;
    floo_narrow_r.hdr.rob_idx = rob_idx_t'(narrow_ar_out_data_out.rob_idx);
    floo_narrow_r.hdr.dst_id  = dst_id[NarrowR];
    floo_narrow_r.hdr.src_id  = id_i;
    floo_narrow_r.hdr.axi_ch  = NarrowR;
    floo_narrow_r.hdr.last    = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_narrow_r.hdr.atop    = narrow_ar_out_data_out.atop;
    floo_narrow_r.r           = axi_narrow_meta_buf_rsp_out.r;
    floo_narrow_r.r.id        = narrow_ar_out_data_out.id;
  end

  always_comb begin
    floo_wide_aw              = '0;
    floo_wide_aw.hdr.rob_req  = wide_aw_rob_req_out;
    floo_wide_aw.hdr.rob_idx  = rob_idx_t'(wide_aw_rob_idx_out);
    floo_wide_aw.hdr.dst_id   = dst_id[WideAw];
    floo_wide_aw.hdr.src_id   = id_i;
    floo_wide_aw.hdr.last     = 1'b0;  // AW and W need to be sent together
    floo_wide_aw.hdr.axi_ch   = WideAw;
    floo_wide_aw.aw           = axi_wide_aw_queue;
  end

  always_comb begin
    floo_wide_w             = '0;
    floo_wide_w.hdr.rob_req = wide_aw_rob_req_out;
    floo_wide_w.hdr.rob_idx = rob_idx_t'(wide_aw_rob_idx_out);
    floo_wide_w.hdr.dst_id  = dst_id[WideW];
    floo_wide_w.hdr.src_id  = id_i;
    floo_wide_w.hdr.last    = axi_wide_req_in.w.last;
    floo_wide_w.hdr.axi_ch  = WideW;
    floo_wide_w.w           = axi_wide_req_in.w;
  end

  always_comb begin
    floo_wide_ar              = '0;
    floo_wide_ar.hdr.rob_req  = wide_ar_rob_req_out;
    floo_wide_ar.hdr.rob_idx  = rob_idx_t'(wide_ar_rob_idx_out);
    floo_wide_ar.hdr.dst_id   = dst_id[WideAr];
    floo_wide_ar.hdr.src_id   = id_i;
    floo_wide_ar.hdr.last     = 1'b1;
    floo_wide_ar.hdr.axi_ch   = WideAr;
    floo_wide_ar.ar           = axi_wide_ar_queue;
  end

  always_comb begin
    floo_wide_b             = '0;
    floo_wide_b.hdr.rob_req = wide_aw_out_data_out.rob_req;
    floo_wide_b.hdr.rob_idx = rob_idx_t'(wide_aw_out_data_out.rob_idx);
    floo_wide_b.hdr.dst_id  = dst_id[WideB];
    floo_wide_b.hdr.src_id  = id_i;
    floo_wide_b.hdr.last    = 1'b1;
    floo_wide_b.hdr.axi_ch  = WideB;
    floo_wide_b.b           = axi_wide_meta_buf_rsp_out.b;
    floo_wide_b.b.id        = wide_aw_out_data_out.id;
  end

  always_comb begin
    floo_wide_r             = '0;
    floo_wide_r.hdr.rob_req = wide_ar_out_data_out.rob_req;
    floo_wide_r.hdr.rob_idx = rob_idx_t'(wide_ar_out_data_out.rob_idx);
    floo_wide_r.hdr.dst_id  = dst_id[WideR];
    floo_wide_r.hdr.src_id  = id_i;
    floo_wide_r.hdr.axi_ch  = WideR;
    floo_wide_r.hdr.last    = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_wide_r.r           = axi_wide_meta_buf_rsp_out.r;
    floo_wide_r.r.id        = wide_ar_out_data_out.id;
  end

  always_comb begin
    narrow_aw_w_sel_d = narrow_aw_w_sel_q;
    wide_aw_w_sel_d = wide_aw_w_sel_q;
    if (axi_narrow_aw_queue_valid_out && axi_narrow_aw_queue_ready_in) begin
      narrow_aw_w_sel_d = SelW;
    end
    if (axi_narrow_req_in.w_valid && axi_narrow_rsp_out.w_ready &&
        axi_narrow_req_in.w.last) begin
      narrow_aw_w_sel_d = SelAw;
    end
    if (axi_wide_aw_queue_valid_out && axi_wide_aw_queue_ready_in) begin
      wide_aw_w_sel_d = SelW;
    end
    if (axi_wide_req_in.w_valid && axi_wide_rsp_out.w_ready && axi_wide_req_in.w.last) begin
      wide_aw_w_sel_d = SelAw;
    end
  end

  `FF(narrow_aw_w_sel_q, narrow_aw_w_sel_d, SelAw)
  `FF(wide_aw_w_sel_q, wide_aw_w_sel_d, SelAw)

  assign floo_req_arb_req_in[NarrowW]  = (narrow_aw_w_sel_q == SelAw) &&
                                          (narrow_aw_rob_valid_out ||
                                          ((axi_narrow_aw_queue.atop != axi_pkg::ATOP_NONE) &&
                                          axi_narrow_aw_queue_valid_out)) ||
                                          (narrow_aw_w_sel_q == SelW) &&
                                          axi_narrow_req_in.w_valid;
  assign floo_req_arb_req_in[NarrowAw] = 1'b0; // AW and W need to be sent together
  assign floo_req_arb_req_in[NarrowAr]  = narrow_ar_rob_valid_out;
  assign floo_req_arb_req_in[WideAr]    = wide_ar_rob_valid_out;
  assign floo_rsp_arb_req_in[NarrowB]   = axi_narrow_meta_buf_rsp_out.b_valid;
  assign floo_rsp_arb_req_in[NarrowR]   = axi_narrow_meta_buf_rsp_out.r_valid;
  assign floo_rsp_arb_req_in[WideB]     = axi_wide_meta_buf_rsp_out.b_valid;
  assign floo_wide_arb_req_in[WideW]    = (wide_aw_w_sel_q == SelAw) &&
                                          wide_aw_rob_valid_out ||
                                          (wide_aw_w_sel_q == SelW) &&
                                          axi_wide_req_in.w_valid;
  assign floo_wide_arb_req_in[WideAw]   = 1'b0; // AW and W need to be sent together
  assign floo_wide_arb_req_in[WideR]    = axi_wide_meta_buf_rsp_out.r_valid;

  assign narrow_aw_rob_ready_in     = floo_req_arb_gnt_out[NarrowW] &&
                                      (narrow_aw_w_sel_q == SelAw);
  assign axi_narrow_rsp_out.w_ready = floo_req_arb_gnt_out[NarrowW] &&
                                      (narrow_aw_w_sel_q == SelW);
  assign narrow_ar_rob_ready_in     = floo_req_arb_gnt_out[NarrowAr];
  assign wide_aw_rob_ready_in       = floo_wide_arb_gnt_out[WideW] &&
                                      (wide_aw_w_sel_q == SelAw);
  assign axi_wide_rsp_out.w_ready   = floo_wide_arb_gnt_out[WideW] &&
                                      (wide_aw_w_sel_q == SelW);
  assign wide_ar_rob_ready_in       = floo_req_arb_gnt_out[WideAr];

  assign floo_req_arb_in[NarrowAw]            = '0;
  assign floo_req_arb_in[NarrowW]             = (narrow_aw_w_sel_q == SelAw)?
                                                floo_narrow_aw : floo_narrow_w;
  assign floo_req_arb_in[NarrowAr].narrow_ar  = floo_narrow_ar;
  assign floo_req_arb_in[WideAr].wide_ar      = floo_wide_ar;
  assign floo_rsp_arb_in[NarrowB].narrow_b    = floo_narrow_b;
  assign floo_rsp_arb_in[NarrowR].narrow_r    = floo_narrow_r;
  assign floo_rsp_arb_in[WideB].wide_b        = floo_wide_b;
  assign floo_wide_arb_in[WideAw]             = '0;
  assign floo_wide_arb_in[WideW]              = (wide_aw_w_sel_q == SelAw)?
                                                floo_wide_aw : floo_wide_w;
  assign floo_wide_arb_in[WideR].wide_r       = floo_wide_r;

  ///////////////////////
  // FLIT ARBITRATION  //
  ///////////////////////

  floo_wormhole_arbiter #(
    .NumRoutes  ( 4                       ),
    .flit_t     ( floo_req_generic_flit_t )
  ) i_req_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .valid_i  ( floo_req_arb_req_in   ),
    .data_i   ( floo_req_arb_in       ),
    .ready_o  ( floo_req_arb_gnt_out  ),
    .data_o   ( floo_req_o.req        ),
    .ready_i  ( floo_req_i.ready      ),
    .valid_o  ( floo_req_o.valid      )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( 3                       ),
    .flit_t     ( floo_rsp_generic_flit_t )
  ) i_rsp_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .valid_i  ( floo_rsp_arb_req_in   ),
    .data_i   ( floo_rsp_arb_in       ),
    .ready_o  ( floo_rsp_arb_gnt_out  ),
    .data_o   ( floo_rsp_o.rsp        ),
    .ready_i  ( floo_rsp_i.ready      ),
    .valid_o  ( floo_rsp_o.valid      )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( 3                         ),
    .flit_t     ( floo_wide_generic_flit_t  )
  ) i_wide_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .valid_i  ( floo_wide_arb_req_in  ),
    .data_i   ( floo_wide_arb_in      ),
    .ready_o  ( floo_wide_arb_gnt_out ),
    .data_o   ( floo_wide_o.wide      ),
    .ready_i  ( floo_wide_i.ready     ),
    .valid_o  ( floo_wide_o.valid     )
  );

  ////////////////////
  // FLIT UNPACKER  //
  ////////////////////

  logic is_atop_b_rsp, is_atop_r_rsp;
  logic b_sel_atop, r_sel_atop;
  logic b_rob_pending_q, r_rob_pending_q;

  assign is_atop_b_rsp = AtopSupport && axi_valid_in[NarrowB] &&
                         floo_rsp_unpack_generic.hdr.atop;
  assign is_atop_r_rsp = AtopSupport && axi_valid_in[NarrowR] &&
                         floo_rsp_unpack_generic.hdr.atop;
  assign b_sel_atop = is_atop_b_rsp && !b_rob_pending_q;
  assign r_sel_atop = is_atop_r_rsp && !r_rob_pending_q;

  assign axi_narrow_unpack_aw = floo_req_in.narrow_aw.aw;
  assign axi_narrow_unpack_w  = floo_req_in.narrow_w.w;
  assign axi_narrow_unpack_ar = floo_req_in.narrow_ar.ar;
  assign axi_narrow_unpack_r  = floo_rsp_in.narrow_r.r;
  assign axi_narrow_unpack_b  = floo_rsp_in.narrow_b.b;
  assign axi_wide_unpack_aw   = floo_wide_in.wide_aw.aw;
  assign axi_wide_unpack_w    = floo_wide_in.wide_w.w;
  assign axi_wide_unpack_ar   = floo_req_in.wide_ar.ar;
  assign axi_wide_unpack_r    = floo_wide_in.wide_r.r;
  assign axi_wide_unpack_b    = floo_rsp_in.wide_b.b;
  assign floo_req_unpack_generic  = floo_req_in.generic;
  assign floo_rsp_unpack_generic  = floo_rsp_in.generic;
  assign floo_wide_unpack_generic = floo_wide_in.generic;


  assign axi_valid_in[NarrowAw] = floo_req_in_valid &&
                                  (floo_req_unpack_generic.hdr.axi_ch == NarrowAw);
  assign axi_valid_in[NarrowW]  = floo_req_in_valid &&
                                  (floo_req_unpack_generic.hdr.axi_ch  == NarrowW);
  assign axi_valid_in[NarrowAr] = floo_req_in_valid &&
                                  (floo_req_unpack_generic.hdr.axi_ch == NarrowAr);
  assign axi_valid_in[WideAr]   = floo_req_in_valid &&
                                  (floo_req_unpack_generic.hdr.axi_ch == WideAr);
  assign axi_valid_in[NarrowB]  = EnNarrowMgrPort && floo_rsp_in_valid &&
                                  (floo_rsp_unpack_generic.hdr.axi_ch  == NarrowB);
  assign axi_valid_in[NarrowR]  = EnNarrowMgrPort && floo_rsp_in_valid &&
                                  (floo_rsp_unpack_generic.hdr.axi_ch  == NarrowR);
  assign axi_valid_in[WideB]    = EnWideMgrPort && floo_rsp_in_valid &&
                                  (floo_rsp_unpack_generic.hdr.axi_ch  == WideB);
  assign axi_valid_in[WideAw]   = floo_wide_in_valid &&
                                  (floo_wide_unpack_generic.hdr.axi_ch == WideAw);
  assign axi_valid_in[WideW]    = floo_wide_in_valid &&
                                  (floo_wide_unpack_generic.hdr.axi_ch  == WideW);
  assign axi_valid_in[WideR]    = EnWideMgrPort && floo_wide_in_valid &&
                                  (floo_wide_unpack_generic.hdr.axi_ch  == WideR);

  assign axi_ready_out[NarrowAw]  = axi_narrow_meta_buf_rsp_out.aw_ready;
  assign axi_ready_out[NarrowW]   = axi_narrow_meta_buf_rsp_out.w_ready;
  assign axi_ready_out[NarrowAr]  = axi_narrow_meta_buf_rsp_out.ar_ready;
  assign axi_ready_out[NarrowB]   = narrow_b_rob_ready_out ||
                                    b_sel_atop && axi_narrow_req_in.b_ready;
  assign axi_ready_out[NarrowR]   = narrow_r_rob_ready_out ||
                                    r_sel_atop && axi_narrow_req_in.r_ready;
  assign axi_ready_out[WideAw]    = axi_wide_meta_buf_rsp_out.aw_ready;
  assign axi_ready_out[WideW]     = axi_wide_meta_buf_rsp_out.w_ready;
  assign axi_ready_out[WideAr]    = axi_wide_meta_buf_rsp_out.ar_ready;
  assign axi_ready_out[WideB]     = wide_b_rob_ready_out;
  assign axi_ready_out[WideR]     = wide_r_rob_ready_out;

  assign floo_req_out_ready  = axi_ready_out[floo_req_unpack_generic.hdr.axi_ch];
  assign floo_rsp_out_ready  = axi_ready_out[floo_rsp_unpack_generic.hdr.axi_ch];
  assign floo_wide_out_ready = axi_ready_out[floo_wide_unpack_generic.hdr.axi_ch];

  /////////////////////////////
  // AXI req/rsp generation  //
  ////////////////////////////

  assign axi_narrow_meta_buf_req_in ='{
    aw        : axi_narrow_unpack_aw,
    aw_valid  : axi_valid_in[NarrowAw],
    w         : axi_narrow_unpack_w,
    w_valid   : axi_valid_in[NarrowW],
    b_ready   : floo_rsp_arb_gnt_out[NarrowB],
    ar        : axi_narrow_unpack_ar,
    ar_valid  : axi_valid_in[NarrowAr],
    r_ready   : floo_rsp_arb_gnt_out[NarrowR]
  };

  assign axi_wide_meta_buf_req_in ='{
    aw        : axi_wide_unpack_aw,
    aw_valid  : axi_valid_in[WideAw],
    w         : axi_wide_unpack_w,
    w_valid   : axi_valid_in[WideW],
    b_ready   : floo_rsp_arb_gnt_out[WideB],
    ar        : axi_wide_unpack_ar,
    ar_valid  : axi_valid_in[WideAr],
    r_ready   : floo_wide_arb_gnt_out[WideR]
  };

  assign narrow_b_rob_valid_in      = axi_valid_in[NarrowB] && !is_atop_b_rsp;
  assign narrow_r_rob_valid_in      = axi_valid_in[NarrowR] && !is_atop_r_rsp;
  assign axi_narrow_rsp_out.b_valid = narrow_b_rob_valid_out || is_atop_b_rsp;
  assign axi_narrow_rsp_out.r_valid = narrow_r_rob_valid_out || is_atop_r_rsp;
  assign narrow_b_rob_ready_in      = axi_narrow_req_in.b_ready && !b_sel_atop;
  assign narrow_r_rob_ready_in      = axi_narrow_req_in.r_ready && !r_sel_atop;
  assign wide_b_rob_valid_in        = axi_valid_in[WideB];
  assign wide_r_rob_valid_in        = axi_valid_in[WideR];
  assign axi_wide_rsp_out.b_valid   = wide_b_rob_valid_out;
  assign axi_wide_rsp_out.r_valid   = wide_r_rob_valid_out;
  assign wide_b_rob_ready_in        = axi_wide_req_in.b_ready;
  assign wide_r_rob_ready_in        = axi_wide_req_in.r_ready;

  assign axi_narrow_b_rob_in  = axi_narrow_unpack_b;
  assign axi_narrow_r_rob_in  = axi_narrow_unpack_r;
  assign axi_narrow_rsp_out.b = (b_sel_atop)? axi_narrow_unpack_b
                                : axi_narrow_b_rob_out;
  assign axi_narrow_rsp_out.r = (r_sel_atop)? axi_narrow_unpack_r
                                : axi_narrow_r_rob_out;
  assign axi_wide_b_rob_in    = axi_wide_unpack_b;
  assign axi_wide_r_rob_in    = axi_wide_unpack_r;
  assign axi_wide_rsp_out.b   = axi_wide_b_rob_out;
  assign axi_wide_rsp_out.r   = axi_wide_r_rob_out;

  logic is_atop, atop_has_r_rsp;
  assign is_atop = AtopSupport && axi_valid_in[NarrowAw] &&
                   (axi_narrow_unpack_aw.atop != axi_pkg::ATOP_NONE);
  assign atop_has_r_rsp = AtopSupport && axi_valid_in[NarrowAw] &&
                          axi_narrow_unpack_aw.atop[axi_pkg::ATOP_R_RESP];

  assign narrow_aw_out_data_in = '{
    id: axi_narrow_unpack_aw.id,
    rob_req: floo_req_in.narrow_aw.hdr.rob_req,
    rob_idx: floo_req_in.narrow_aw.hdr.rob_idx,
    src_id: floo_req_in.narrow_aw.hdr.src_id,
    atop: floo_req_in.narrow_aw.hdr.atop
  };
  assign narrow_ar_out_data_in = '{
    id: (is_atop && atop_has_r_rsp)? axi_narrow_unpack_aw.id : axi_narrow_unpack_ar.id,
    rob_req: floo_req_in.narrow_ar.hdr.rob_req,
    rob_idx: floo_req_in.narrow_ar.hdr.rob_idx,
    src_id: floo_req_in.narrow_ar.hdr.src_id,
    atop: floo_req_in.narrow_ar.hdr.atop
  };
  assign wide_aw_out_data_in = '{
    id: axi_wide_unpack_aw.id,
    rob_req: floo_wide_in.wide_aw.hdr.rob_req,
    rob_idx: floo_wide_in.wide_aw.hdr.rob_idx,
    src_id: floo_wide_in.wide_aw.hdr.src_id
  };
  assign wide_ar_out_data_in = '{
    id: axi_wide_unpack_ar.id,
    rob_req: floo_req_in.wide_ar.hdr.rob_req,
    rob_idx: floo_req_in.wide_ar.hdr.rob_idx,
    src_id: floo_req_in.wide_ar.hdr.src_id
  };

  if (EnNarrowSbrPort) begin : gen_narrow_mgr_port
    floo_meta_buffer #(
      .MaxTxns        ( NarrowMaxTxns       ),
      .AtopSupport    ( AtopSupport         ),
      .MaxAtomicTxns  ( MaxAtomicTxns       ),
      .buf_t          ( narrow_id_out_buf_t ),
      .IdInWidth      ( AxiNarrowInIdWidth  ),
      .IdOutWidth     ( AxiNarrowOutIdWidth ),
      .axi_req_t      ( axi_narrow_in_req_t ),
      .axi_rsp_t      ( axi_narrow_in_rsp_t )
    ) i_narrow_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .axi_req_i  ( axi_narrow_meta_buf_req_in   ),
      .axi_rsp_o  ( axi_narrow_meta_buf_rsp_out  ),
      .axi_req_o  ( axi_narrow_meta_buf_req_out  ),
      .axi_rsp_i  ( axi_narrow_meta_buf_rsp_in   ),
      .aw_buf_i   ( narrow_aw_out_data_in        ),
      .ar_buf_i   ( narrow_ar_out_data_in        ),
      .r_buf_o    ( narrow_ar_out_data_out       ),
      .b_buf_o    ( narrow_aw_out_data_out       )
    );
  end else begin : gen_no_narrow_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiNarrowInIdWidth  ),
      .ATOPs      ( AtopSupport         ),
      .axi_req_t  ( axi_narrow_in_req_t ),
      .axi_resp_t ( axi_narrow_in_rsp_t )
    ) i_axi_err_slv (
      .clk_i      ( clk_i                       ),
      .rst_ni     ( rst_ni                      ),
      .test_i     ( test_enable_i               ),
      .slv_req_i  ( axi_narrow_meta_buf_req_in  ),
      .slv_resp_o ( axi_narrow_meta_buf_rsp_out )
    );
    assign axi_narrow_meta_buf_req_out = '0;
    assign narrow_ar_out_data_out = '0;
    assign narrow_aw_out_data_out = '0;
  end

  if (EnWideSbrPort) begin : gen_wide_mgr_port
    floo_meta_buffer #(
      .MaxTxns        ( WideMaxTxns       ),
      .AtopSupport    ( 1'b1              ),
      .MaxAtomicTxns  ( MaxAtomicTxns     ),
      .buf_t          ( wide_id_out_buf_t ),
      .IdInWidth      ( AxiWideInIdWidth  ),
      .IdOutWidth     ( AxiWideOutIdWidth ),
      .axi_req_t      ( axi_wide_in_req_t ),
      .axi_rsp_t      ( axi_wide_in_rsp_t )
    ) i_wide_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .axi_req_i  ( axi_wide_meta_buf_req_in   ),
      .axi_rsp_o  ( axi_wide_meta_buf_rsp_out  ),
      .axi_req_o  ( axi_wide_meta_buf_req_out  ),
      .axi_rsp_i  ( axi_wide_meta_buf_rsp_in   ),
      .aw_buf_i   ( wide_aw_out_data_in        ),
      .ar_buf_i   ( wide_ar_out_data_in        ),
      .r_buf_o    ( wide_ar_out_data_out       ),
      .b_buf_o    ( wide_aw_out_data_out       )
    );
  end else begin : gen_no_wide_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiWideInIdWidth  ),
      .ATOPs      ( 1'b1              ),
      .axi_req_t  ( axi_wide_in_req_t ),
      .axi_resp_t ( axi_wide_in_rsp_t )
    ) i_axi_err_slv (
      .clk_i      ( clk_i                     ),
      .rst_ni     ( rst_ni                    ),
      .test_i     ( test_enable_i             ),
      .slv_req_i  ( axi_wide_meta_buf_req_in  ),
      .slv_resp_o ( axi_wide_meta_buf_rsp_out )
    );
    assign axi_wide_meta_buf_req_out = '0;
    assign wide_ar_out_data_out = '0;
    assign wide_aw_out_data_out = '0;
  end

  // Registers
  `FF(b_rob_pending_q, narrow_b_rob_valid_out && !narrow_b_rob_ready_in && !is_atop_b_rsp, '0)
  `FF(r_rob_pending_q, narrow_r_rob_valid_out && !narrow_r_rob_ready_in && !is_atop_r_rsp, '0)


  /////////////////
  // ASSERTIONS  //
  /////////////////

  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(ToSmallIdWidth, 1 + AtopSupport * MaxAtomicTxns <= 2**AxiNarrowOutIdWidth)

  // If Network Interface has no subordinate port, make sure that `RoBType` is `NoRoB`
  `ASSERT_INIT(NoNarrowMgrPortRobType, EnNarrowMgrPort || (NarrowRoBType == NoRoB))
  `ASSERT_INIT(NoWideMgrPortRobType, EnWideMgrPort || (WideRoBType == NoRoB))

  // Check that all addresses have the same width
  `ASSERT_INIT(SameAddrWidth1, AxiNarrowInAddrWidth == AxiNarrowOutAddrWidth)
  `ASSERT_INIT(SameAddrWidth2, AxiWideInAddrWidth == AxiNarrowOutAddrWidth)
  `ASSERT_INIT(SameAddrWidth3, AxiWideInAddrWidth == AxiWideOutAddrWidth)

  // Data and valid signals must be stable/asserted when ready is low
  `ASSERT(NarrowReqOutStableValid, floo_req_o.valid &&
                                   !floo_req_i.ready |=> floo_req_o.valid)
  `ASSERT(NarrowReqInStableValid, floo_req_i.valid &&
                                  !floo_req_o.ready |=> floo_req_i.valid)
  `ASSERT(NarrowRspOutStableValid, floo_rsp_o.valid &&
                                   !floo_rsp_i.ready |=> floo_rsp_o.valid)
  `ASSERT(NarrowRspInStableValid, floo_rsp_i.valid &&
                                  !floo_rsp_o.ready |=> floo_rsp_i.valid)
  `ASSERT(WideOutStableValid, floo_wide_o.valid &&
                              !floo_wide_i.ready |=> floo_wide_o.valid)
  `ASSERT(WideStableValid, floo_wide_i.valid &&
                           !floo_wide_o.ready |=> floo_wide_i.valid)

  // Network Interface cannot accept any B and R responses if `En*MgrPort` are not set
  `ASSERT(NoNarrowMgrPortBResponse, EnNarrowMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == NarrowB)))
  `ASSERT(NoNarrowMgrPortRResponse, EnNarrowMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == NarrowR)))
  `ASSERT(NoWideMgrPortBResponse, EnWideMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == WideB)))
  `ASSERT(NoWideMgrPortRResponse, EnWideMgrPort || !(floo_wide_in_valid &&
                           (floo_wide_unpack_generic.hdr.axi_ch == WideR)))
  // Network Interface cannot accept any AW, AR and W requests if `En*SbrPort` is not set
  `ASSERT(NoNarrowSbrPortAwRequest, EnNarrowSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == NarrowAw)))
  `ASSERT(NoNarrowSbrPortArRequest, EnNarrowSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == NarrowAr)))
  `ASSERT(NoNarrowSbrPortWRequest,  EnNarrowSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == NarrowW)))
  `ASSERT(NoWideSbrPortAwRequest, EnWideSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == WideAw)))
  `ASSERT(NoWideSbrPortArRequest, EnWideSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == WideAr)))
  `ASSERT(NoWideSbrPortWRequest,  EnWideSbrPort || !(floo_wide_in_valid &&
                           (floo_wide_unpack_generic.hdr.axi_ch == WideW)))

endmodule
