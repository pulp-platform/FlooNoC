// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/assign.svh"

/// A bidirectional network interface for connecting AXI4 Buses to the NoC
module floo_axi_chimney
  import floo_pkg::*;
  import floo_axi_pkg::*;
#(
  /// Atomic operation support
  parameter bit AtopSupport                 = 1'b1,
  /// Maximum number of oustanding Atomic transactions,
  /// must be smaller or equal to 2**AxiOutIdWidth-1 since
  /// Every atomic transactions needs to have a unique ID
  /// and one ID is reserved for non-atomic transactions
  parameter int unsigned MaxAtomicTxns      = 1,
  /// Routing Algorithm
  parameter route_algo_e RouteAlgo          = IdTable,
  /// X Coordinate address offset for XY routing
  parameter int unsigned XYAddrOffsetX      = 0,
  /// Y Coordinate address offset for XY routing
  parameter int unsigned XYAddrOffsetY      = 0,
  /// ID address offset for ID routing
  parameter int unsigned IdTableAddrOffset  = 8,
  /// Number of maximum oustanding requests
  parameter int unsigned MaxTxns            = 32,
  /// Maximum number of outstanding requests per ID
  parameter int unsigned MaxTxnsPerId       = MaxTxns,
  /// Capacity of the reorder buffer
  parameter int unsigned ReorderBufferSize  = 32,
  /// Choice between simple or advanced reorder buffer,
  /// trade-off between area and performance
  parameter bit RoBSimple                   = 1'b0,
  /// Only used for XYRouting
  parameter type xy_id_t                    = logic,
  /// Cut timing paths of outgoing requests
  parameter bit CutAx                       = 1'b0,
  /// Cut timing paths of incoming responses
  parameter bit CutRsp                      = 1'b1,
  /// Type for implementation inputs and outputs
  parameter type         sram_cfg_t         = logic,
  /// RoB index type
  localparam type        rob_idx_t          = logic [$clog2(ReorderBufferSize)-1:0]
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  sram_cfg_t  sram_cfg_i,
  /// AXI4 side interfaces
  input  axi_in_req_t axi_in_req_i,
  output axi_in_rsp_t axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input  axi_out_rsp_t axi_out_rsp_i,
  /// Coordinates/ID of the current tile
  input  xy_id_t  xy_id_i,
  input  src_id_t id_i,
  /// Output to NoC
  output floo_req_t floo_req_o,
  output floo_rsp_t floo_rsp_o,
  /// Input from NoC
  input  floo_req_t floo_req_i,
  input  floo_rsp_t floo_rsp_i
);

  // AX queue
  axi_in_aw_chan_t axi_aw_queue;
  axi_in_ar_chan_t axi_ar_queue;
  logic axi_aw_queue_valid_out, axi_aw_queue_ready_in;
  logic axi_ar_queue_valid_out, axi_ar_queue_ready_in;

  axi_in_req_t axi_out_req_id_mapped;
  axi_in_rsp_t axi_out_rsp_id_mapped;
  `AXI_ASSIGN_REQ_STRUCT(axi_out_req_o, axi_out_req_id_mapped)
  `AXI_ASSIGN_RESP_STRUCT(axi_out_rsp_id_mapped, axi_out_rsp_i)

  floo_req_chan_t [AxiAw:AxiAr] floo_req_arb_in;
  floo_rsp_chan_t [AxiB:AxiR] floo_rsp_arb_in;
  logic  [AxiAw:AxiAr] floo_req_arb_req_in, floo_req_arb_gnt_out;
  logic  [AxiB:AxiR] floo_rsp_arb_req_in, floo_rsp_arb_gnt_out;

  // flit queue
  floo_req_chan_t floo_req_in;
  floo_rsp_chan_t floo_rsp_in;
  logic floo_req_in_valid, floo_rsp_in_valid;
  logic floo_req_out_ready, floo_rsp_out_ready;
  logic [NumAxiChannels-1:0] axi_valid_in, axi_ready_out;

  // Flit packing
  floo_axi_aw_flit_t floo_axi_aw;
  floo_axi_w_flit_t floo_axi_w;
  floo_axi_ar_flit_t  floo_axi_ar;
  floo_axi_b_flit_t  floo_axi_b;
  floo_axi_r_flit_t  floo_axi_r;
  axi_in_aw_chan_t axi_aw_id_mod;
  axi_in_ar_chan_t axi_ar_id_mod;

  // Flit unpacking
  axi_in_aw_chan_t axi_unpack_aw;
  axi_in_ar_chan_t axi_unpack_ar;
  axi_in_w_chan_t  axi_unpack_w;
  axi_in_b_chan_t  axi_unpack_b;
  axi_in_r_chan_t  axi_unpack_r;
  floo_req_generic_flit_t unpack_req_generic;
  floo_rsp_generic_flit_t unpack_rsp_generic;

  // Flit arbitration
  typedef enum logic {SelAw, SelW} aw_w_sel_e;
  aw_w_sel_e aw_w_sel_q, aw_w_sel_d;

  typedef dst_id_t id_t;

  // ID tracking
  typedef struct packed {
    axi_in_id_t id;
    logic       rob_req;
    rob_idx_t   rob_idx;
    id_t        src_id;
    logic       atop;
  } id_out_buf_t;

  // Routing
  id_t [NumAxiChannels-1:0] dst_id;
  id_t src_id;

  logic aw_out_push, aw_out_pop;
  logic ar_out_push, ar_out_pop;
  logic aw_out_full;
  logic ar_out_full;
  axi_out_id_t aw_out_id;
  axi_out_id_t ar_out_id;
  id_out_buf_t aw_out_data_in, aw_out_data_out;
  id_out_buf_t ar_out_data_in, ar_out_data_out;

  ///////////////////////
  //  Spill registers  //
  ///////////////////////

  if (CutAx) begin : gen_ax_cuts
    spill_register #(
      .T ( axi_in_aw_chan_t )
    ) i_aw_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( axi_in_req_i.aw         ),
      .valid_i    ( axi_in_req_i.aw_valid   ),
      .ready_o    ( axi_in_rsp_o.aw_ready   ),
      .data_o     ( axi_aw_queue            ),
      .valid_o    ( axi_aw_queue_valid_out  ),
      .ready_i    ( axi_aw_queue_ready_in   )
    );

    spill_register #(
      .T ( axi_in_ar_chan_t )
    ) i_ar_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( axi_in_req_i.ar         ),
      .valid_i    ( axi_in_req_i.ar_valid   ),
      .ready_o    ( axi_in_rsp_o.ar_ready   ),
      .data_o     ( axi_ar_queue            ),
      .valid_o    ( axi_ar_queue_valid_out  ),
      .ready_i    ( axi_ar_queue_ready_in   )
    );
  end else begin : gen_no_ax_cuts
    assign axi_aw_queue = axi_in_req_i.aw;
    assign axi_aw_queue_valid_out = axi_in_req_i.aw_valid;
    assign axi_in_rsp_o.aw_ready = axi_aw_queue_ready_in;

    assign axi_ar_queue = axi_in_req_i.ar;
    assign axi_ar_queue_valid_out = axi_in_req_i.ar_valid;
    assign axi_in_rsp_o.ar_ready = axi_ar_queue_ready_in;
  end

  if (CutRsp) begin : gen_rsp_cuts
    spill_register #(
      .T ( floo_req_chan_t )
    ) i_data_req_arb (
      .clk_i      ( clk_i               ),
      .rst_ni     ( rst_ni              ),
      .data_i     ( floo_req_i.req      ),
      .valid_i    ( floo_req_i.valid    ),
      .ready_o    ( floo_req_o.ready    ),
      .data_o     ( floo_req_in         ),
      .valid_o    ( floo_req_in_valid   ),
      .ready_i    ( floo_req_out_ready  )
    );

    spill_register #(
      .T ( floo_rsp_chan_t )
    ) i_data_rsp_arb (
      .clk_i      ( clk_i               ),
      .rst_ni     ( rst_ni              ),
      .data_i     ( floo_rsp_i.rsp      ),
      .valid_i    ( floo_rsp_i.valid    ),
      .ready_o    ( floo_rsp_o.ready    ),
      .data_o     ( floo_rsp_in         ),
      .valid_o    ( floo_rsp_in_valid   ),
      .ready_i    ( floo_rsp_out_ready  )
    );
  end else begin : gen_no_rsp_cuts
    assign floo_req_in = floo_req_i.req;
    assign floo_req_in_valid = floo_req_i.valid;
    assign floo_req_o.ready = floo_req_out_ready;
    assign floo_rsp_in = floo_rsp_i.rsp;
    assign floo_rsp_in_valid = floo_rsp_i.valid;
    assign floo_rsp_o.ready = floo_rsp_out_ready;
  end

  ///////////////////////
  //  Reorder Buffers  //
  ///////////////////////

  // AW/B RoB
  axi_in_b_chan_t axi_b_rob_out, axi_b_rob_in;
  logic aw_rob_req_out;
  rob_idx_t aw_rob_idx_out;
  logic aw_rob_valid_in, aw_rob_ready_out;
  logic aw_rob_valid_out, aw_rob_ready_in;
  logic b_rob_valid_in, b_rob_ready_out;
  logic b_rob_valid_out, b_rob_ready_in;

  // AR/R RoB
  axi_in_r_chan_t axi_r_rob_out, axi_r_rob_in;
  logic ar_rob_req_out;
  rob_idx_t ar_rob_idx_out;
  logic ar_rob_valid_out, ar_rob_ready_in;
  logic r_rob_valid_in, r_rob_ready_out;
  logic r_rob_valid_out, r_rob_ready_in;

  if (AtopSupport) begin : gen_atop_support
    // Bypass AW/B RoB
    assign aw_rob_valid_in = axi_aw_queue_valid_out && (axi_aw_queue.atop == axi_pkg::ATOP_NONE);
    assign axi_aw_queue_ready_in = (axi_aw_queue.atop == axi_pkg::ATOP_NONE)?
                                aw_rob_ready_out : aw_rob_ready_in;
  end else begin : gen_no_atop_support
    assign aw_rob_valid_in = axi_aw_queue_valid_out;
    assign axi_aw_queue_ready_in = aw_rob_ready_out;
    `ASSERT(NoAtopSupport, !(axi_aw_queue_valid_out && (axi_aw_queue.atop != axi_pkg::ATOP_NONE)))
  end

  floo_rob_wrapper #(
    .RoBType            ( NoRoB             ),
    .ReorderBufferSize  ( ReorderBufferSize ),
    .MaxRoTxnsPerId     ( MaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b1              ),
    .ax_len_t           ( axi_pkg::len_t    ),
    .ax_id_t            ( axi_in_id_t       ),
    .rsp_chan_t         ( axi_in_b_chan_t   ),
    .rsp_meta_t         ( axi_in_b_chan_t   ),
    .rob_idx_t          ( rob_idx_t         ),
    .dest_t             ( id_t              ),
    .sram_cfg_t         ( sram_cfg_t        )
  ) i_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( aw_rob_valid_in               ),
    .ax_ready_o     ( aw_rob_ready_out              ),
    .ax_len_i       ( axi_aw_queue.len              ),
    .ax_id_i        ( axi_aw_queue.id               ),
    .ax_dest_i      ( dst_id[AxiAw]                 ),
    .ax_valid_o     ( aw_rob_valid_out              ),
    .ax_ready_i     ( aw_rob_ready_in               ),
    .ax_rob_req_o   ( aw_rob_req_out                ),
    .ax_rob_idx_o   ( aw_rob_idx_out                ),
    .rsp_valid_i    ( b_rob_valid_in                ),
    .rsp_ready_o    ( b_rob_ready_out               ),
    .rsp_i          ( axi_b_rob_in                  ),
    .rsp_rob_req_i  ( floo_rsp_in.axi_b.hdr.rob_req ),
    .rsp_rob_idx_i  ( floo_rsp_in.axi_b.hdr.rob_idx ),
    .rsp_last_i     ( floo_rsp_in.axi_b.hdr.last    ),
    .rsp_valid_o    ( b_rob_valid_out               ),
    .rsp_ready_i    ( b_rob_ready_in                ),
    .rsp_o          ( axi_b_rob_out                 )
  );

  typedef logic [AxiInDataWidth-1:0] r_rob_data_t;
  typedef struct packed {
    axi_in_id_t     id;
    axi_in_user_t   user;
    axi_pkg::resp_t resp;
    logic           last;
  } r_rob_meta_t;


  floo_rob_wrapper #(
    .RoBType            ( NoRoB             ),
    .ReorderBufferSize  ( ReorderBufferSize ),
    .MaxRoTxnsPerId     ( MaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b0              ),
    .ax_len_t           ( axi_pkg::len_t    ),
    .ax_id_t            ( axi_in_id_t       ),
    .rsp_chan_t         ( axi_in_r_chan_t   ),
    .rsp_data_t         ( r_rob_data_t      ),
    .rsp_meta_t         ( r_rob_meta_t      ),
    .rob_idx_t          ( rob_idx_t         ),
    .dest_t             ( id_t              ),
    .sram_cfg_t         ( sram_cfg_t        )
  ) i_r_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( axi_ar_queue_valid_out        ),
    .ax_ready_o     ( axi_ar_queue_ready_in         ),
    .ax_len_i       ( axi_ar_queue.len              ),
    .ax_id_i        ( axi_ar_queue.id               ),
    .ax_dest_i      ( dst_id[AxiAr]                 ),
    .ax_valid_o     ( ar_rob_valid_out              ),
    .ax_ready_i     ( ar_rob_ready_in               ),
    .ax_rob_req_o   ( ar_rob_req_out                ),
    .ax_rob_idx_o   ( ar_rob_idx_out                ),
    .rsp_valid_i    ( r_rob_valid_in                ),
    .rsp_ready_o    ( r_rob_ready_out               ),
    .rsp_i          ( axi_r_rob_in                  ),
    .rsp_rob_req_i  ( floo_rsp_in.axi_r.hdr.rob_req ),
    .rsp_rob_idx_i  ( floo_rsp_in.axi_r.hdr.rob_idx ),
    .rsp_last_i     ( floo_rsp_in.axi_r.hdr.last    ),
    .rsp_valid_o    ( r_rob_valid_out               ),
    .rsp_ready_i    ( r_rob_ready_in                ),
    .rsp_o          ( axi_r_rob_out                 )
  );

  /////////////////
  //   ROUTING   //
  /////////////////


  if (RouteAlgo == XYRouting) begin : gen_xy_routing
    xy_id_t aw_xy_id_q, aw_xy_id, ar_xy_id;
    assign src_id = xy_id_i;
    assign aw_xy_id.x = axi_aw_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign aw_xy_id.y = axi_aw_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign ar_xy_id.x = axi_ar_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign ar_xy_id.y = axi_ar_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign dst_id[AxiAw] = aw_xy_id;
    assign dst_id[AxiAr] = ar_xy_id;
    assign dst_id[AxiW]  = aw_xy_id_q;
    assign dst_id[AxiB]  = aw_out_data_out.src_id;
    assign dst_id[AxiR]  = ar_out_data_out.src_id;
    `FFL(aw_xy_id_q, aw_xy_id, axi_aw_queue_valid_out && axi_aw_queue_ready_in, '0)
  end else if (RouteAlgo == IdTable) begin : gen_id_table_routing
    id_t aw_id_q, aw_id, ar_id;
    assign src_id = id_i;
    assign aw_id = axi_aw_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign ar_id = axi_ar_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign dst_id[AxiAw] = aw_id;
    assign dst_id[AxiAr] = ar_id;
    assign dst_id[AxiW]  = aw_id_q;
    assign dst_id[AxiB]  = aw_out_data_out.src_id;
    assign dst_id[AxiR]  = ar_out_data_out.src_id;
    `FFL(aw_id_q, aw_id, axi_aw_queue_valid_out && axi_aw_queue_ready_in, '0)
  end else begin : gen_no_routing
    // TODO: Implement other routing algorithms
    $fatal(1, "Routing algorithm not implemented");
  end

  ///////////////////
  // FLIT PACKING  //
  ///////////////////

  always_comb begin
    floo_axi_aw             = '0;
    floo_axi_aw.hdr.rob_req = aw_rob_req_out;
    floo_axi_aw.hdr.rob_idx = aw_rob_idx_out;
    floo_axi_aw.hdr.dst_id  = dst_id[AxiAw];
    floo_axi_aw.hdr.src_id  = src_id;
    floo_axi_aw.hdr.last    = 1'b1;
    floo_axi_aw.hdr.axi_ch  = AxiAw;
    floo_axi_aw.hdr.atop    = axi_aw_queue.atop != axi_pkg::ATOP_NONE;
    floo_axi_aw.aw          = axi_aw_queue;
  end

  always_comb begin
    floo_axi_w              = '0;
    floo_axi_w.hdr.rob_req  = aw_rob_req_out;
    floo_axi_w.hdr.rob_idx  = aw_rob_idx_out;
    floo_axi_w.hdr.dst_id   = dst_id[AxiW];
    floo_axi_w.hdr.src_id   = src_id;
    floo_axi_w.hdr.last     = axi_in_req_i.w.last;
    floo_axi_w.hdr.axi_ch   = AxiW;
    floo_axi_w.w            = axi_in_req_i.w;
  end

  always_comb begin
    floo_axi_ar             = '0;
    floo_axi_ar.hdr.rob_req = ar_rob_req_out;
    floo_axi_ar.hdr.rob_idx = ar_rob_idx_out;
    floo_axi_ar.hdr.dst_id  = dst_id[AxiAr];
    floo_axi_ar.hdr.src_id  = src_id;
    floo_axi_ar.hdr.last    = 1'b1;
    floo_axi_ar.hdr.axi_ch  = AxiAr;
    floo_axi_ar.ar          = axi_ar_queue;
  end

  always_comb begin
    floo_axi_b              = '0;
    floo_axi_b.hdr.rob_req  = aw_out_data_out.rob_req;
    floo_axi_b.hdr.rob_idx  = aw_out_data_out.rob_idx;
    floo_axi_b.hdr.dst_id   = aw_out_data_out.src_id;
    floo_axi_b.hdr.src_id   = src_id;
    floo_axi_b.hdr.last     = 1'b1;
    floo_axi_b.hdr.axi_ch   = AxiB;
    floo_axi_b.hdr.atop     = aw_out_data_out.atop;
    floo_axi_b.b            = axi_out_rsp_id_mapped.b;
    floo_axi_b.b.id         = aw_out_data_out.id;
  end

  always_comb begin
    floo_axi_r              = '0;
    floo_axi_r.hdr.rob_req  = ar_out_data_out.rob_req;
    floo_axi_r.hdr.rob_idx  = ar_out_data_out.rob_idx;
    floo_axi_r.hdr.dst_id   = ar_out_data_out.src_id;
    floo_axi_r.hdr.src_id   = src_id;
    floo_axi_r.hdr.last     = axi_out_rsp_i.r.last;
    floo_axi_r.hdr.axi_ch   = AxiR;
    floo_axi_r.hdr.atop     = ar_out_data_out.atop;
    floo_axi_r.r            = axi_out_rsp_id_mapped.r;
    floo_axi_r.r.id         = ar_out_data_out.id;
  end

  always_comb begin
    aw_w_sel_d = aw_w_sel_q;
    if (axi_aw_queue_valid_out && axi_aw_queue_ready_in) aw_w_sel_d = SelW;
    if (axi_in_req_i.w_valid && axi_in_rsp_o.w_ready && axi_in_req_i.w.last) aw_w_sel_d = SelAw;
  end

  `FF(aw_w_sel_q, aw_w_sel_d, SelAw)

  assign floo_req_arb_req_in[AxiAw] = (aw_w_sel_q == SelAw) && (aw_rob_valid_out ||
                                        ((axi_aw_queue.atop != axi_pkg::ATOP_NONE) &&
                                          axi_aw_queue_valid_out));
  assign floo_req_arb_req_in[AxiW]  = (aw_w_sel_q == SelW) && axi_in_req_i.w_valid;
  assign floo_req_arb_req_in[AxiAr] = ar_rob_valid_out;
  assign floo_rsp_arb_req_in[AxiB]  = axi_out_rsp_i.b_valid;
  assign floo_rsp_arb_req_in[AxiR]  = axi_out_rsp_i.r_valid;

  assign aw_rob_ready_in       = floo_req_arb_gnt_out[AxiAw] && (aw_w_sel_q == SelAw);
  assign axi_in_rsp_o.w_ready  = floo_req_arb_gnt_out[AxiW] && (aw_w_sel_q == SelW);
  assign ar_rob_ready_in       = floo_req_arb_gnt_out[AxiAr];
  assign axi_out_req_id_mapped.b_ready = floo_rsp_arb_gnt_out[AxiB];
  assign axi_out_req_id_mapped.r_ready = floo_rsp_arb_gnt_out[AxiR];

  assign floo_req_arb_in[AxiAw]  = floo_axi_aw;
  assign floo_req_arb_in[AxiW]   = floo_axi_w;
  assign floo_req_arb_in[AxiAr]  = floo_axi_ar;
  assign floo_rsp_arb_in[AxiB]   = floo_axi_b;
  assign floo_rsp_arb_in[AxiR]   = floo_axi_r;

  ///////////////////////
  // FLIT ARBITRATION  //
  ///////////////////////

  floo_wormhole_arbiter #(
    .NumRoutes  ( 3                       ),
    .flit_t     ( floo_req_generic_flit_t )
  ) i_req_wormhole_arbiter (
    .clk_i    ( clk_i                 ),
    .rst_ni   ( rst_ni                ),
    .valid_i  ( floo_req_arb_req_in   ),
    .data_i   ( floo_req_arb_in       ),
    .ready_o  ( floo_req_arb_gnt_out  ),
    .data_o   ( floo_req_o.req        ),
    .ready_i  ( floo_req_i.ready      ),
    .valid_o  ( floo_req_o.valid      )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( 2                       ),
    .flit_t     ( floo_rsp_generic_flit_t )
  ) i_rsp_wormhole_arbiter (
    .clk_i    ( clk_i                 ),
    .rst_ni   ( rst_ni                ),
    .valid_i  ( floo_rsp_arb_req_in   ),
    .data_i   ( floo_rsp_arb_in       ),
    .ready_o  ( floo_rsp_arb_gnt_out  ),
    .data_o   ( floo_rsp_o.rsp        ),
    .ready_i  ( floo_rsp_i.ready      ),
    .valid_o  ( floo_rsp_o.valid      )
  );

  ////////////////////
  // FLIT UNPACKER  //
  ////////////////////

  logic is_atop_b_rsp, is_atop_r_rsp;
  logic b_sel_atop, r_sel_atop;
  logic b_rob_pending_q, r_rob_pending_q;

  assign is_atop_b_rsp = AtopSupport && axi_valid_in[AxiB] && unpack_rsp_generic.hdr.atop;
  assign is_atop_r_rsp = AtopSupport && axi_valid_in[AxiR] && unpack_rsp_generic.hdr.atop;
  assign b_sel_atop = is_atop_b_rsp && !b_rob_pending_q;
  assign r_sel_atop = is_atop_r_rsp && !r_rob_pending_q;

  assign axi_unpack_aw = floo_req_in.axi_aw.aw;
  assign axi_unpack_w  = floo_req_in.axi_w.w;
  assign axi_unpack_ar = floo_req_in.axi_ar.ar;
  assign axi_unpack_r  = floo_rsp_in.axi_r.r;
  assign axi_unpack_b  = floo_rsp_in.axi_b.b;
  assign unpack_req_generic = floo_req_in.generic;
  assign unpack_rsp_generic = floo_rsp_in.generic;

  assign axi_valid_in[AxiAw] = floo_req_in_valid && (unpack_req_generic.hdr.axi_ch == AxiAw);
  assign axi_valid_in[AxiW]  = floo_req_in_valid && (unpack_req_generic.hdr.axi_ch == AxiW);
  assign axi_valid_in[AxiAr] = floo_req_in_valid && (unpack_req_generic.hdr.axi_ch == AxiAr);
  assign axi_valid_in[AxiB]  = floo_rsp_in_valid && (unpack_rsp_generic.hdr.axi_ch == AxiB);
  assign axi_valid_in[AxiR]  = floo_rsp_in_valid && (unpack_rsp_generic.hdr.axi_ch == AxiR);

  assign axi_ready_out[AxiAw] = axi_out_rsp_i.aw_ready && !aw_out_full;
  assign axi_ready_out[AxiW]  = axi_out_rsp_i.w_ready;
  assign axi_ready_out[AxiAr] = axi_out_rsp_i.ar_ready && !ar_out_full;
  assign axi_ready_out[AxiB]  = b_rob_ready_out || b_sel_atop && axi_in_req_i.b_ready;
  assign axi_ready_out[AxiR]  = r_rob_ready_out || r_sel_atop && axi_in_req_i.r_ready;

  assign floo_req_out_ready = axi_ready_out[unpack_req_generic.hdr.axi_ch];
  assign floo_rsp_out_ready = axi_ready_out[unpack_rsp_generic.hdr.axi_ch];

  /////////////////////////////
  // AXI req/rsp generation  //
  ////////////////////////////

  assign axi_out_req_id_mapped.aw_valid = axi_valid_in[AxiAw] && !aw_out_full;
  assign axi_out_req_id_mapped.w_valid  = axi_valid_in[AxiW];
  assign axi_out_req_id_mapped.ar_valid = axi_valid_in[AxiAr] && !ar_out_full;
  assign b_rob_valid_in         = axi_valid_in[AxiB] && !is_atop_b_rsp;
  assign r_rob_valid_in         = axi_valid_in[AxiR] && !is_atop_r_rsp;
  assign axi_in_rsp_o.b_valid   = b_rob_valid_out || is_atop_b_rsp;
  assign axi_in_rsp_o.r_valid   = r_rob_valid_out || is_atop_r_rsp;
  assign b_rob_ready_in         = axi_in_req_i.b_ready && !b_sel_atop;
  assign r_rob_ready_in         = axi_in_req_i.r_ready && !r_sel_atop;

  assign axi_out_req_id_mapped.aw = axi_aw_id_mod;
  assign axi_out_req_id_mapped.w  = axi_unpack_w;
  assign axi_out_req_id_mapped.ar = axi_ar_id_mod;
  assign axi_b_rob_in         = axi_unpack_b;
  assign axi_r_rob_in         = axi_unpack_r;
  assign axi_in_rsp_o.b   = (b_sel_atop)? axi_unpack_b : axi_b_rob_out;
  assign axi_in_rsp_o.r   = (r_sel_atop)? axi_unpack_r : axi_r_rob_out;

  logic is_atop, atop_has_r_rsp;
  assign is_atop = AtopSupport && axi_valid_in[AxiAw] &&
                    (axi_unpack_aw.atop != axi_pkg::ATOP_NONE);
  assign atop_has_r_rsp = AtopSupport && axi_valid_in[AxiAw] &&
                          axi_unpack_aw.atop[axi_pkg::ATOP_R_RESP];

  assign aw_out_push = axi_out_req_o.aw_valid && axi_out_rsp_i.aw_ready;
  assign ar_out_push = axi_out_req_o.ar_valid && axi_out_rsp_i.ar_ready ||
                       axi_out_req_o.aw_valid && axi_out_rsp_i.aw_ready &&
                      is_atop && atop_has_r_rsp;
  assign aw_out_pop = axi_out_rsp_i.b_valid && axi_out_req_o.b_ready;
  assign ar_out_pop = axi_out_rsp_i.r_valid && axi_out_req_o.r_ready && axi_out_rsp_i.r.last;

  assign aw_out_data_in = '{
    id: axi_unpack_aw.id,
    rob_req: unpack_req_generic.hdr.rob_req,
    rob_idx: unpack_req_generic.hdr.rob_idx,
    src_id: unpack_req_generic.hdr.src_id,
    atop: unpack_req_generic.hdr.atop
  };
  assign ar_out_data_in = '{
    id: (is_atop && atop_has_r_rsp)? axi_unpack_aw.id : axi_unpack_ar.id,
    rob_req: unpack_req_generic.hdr.rob_req,
    rob_idx: unpack_req_generic.hdr.rob_idx,
    src_id: unpack_req_generic.hdr.src_id,
    atop: unpack_req_generic.hdr.atop
  };

  floo_meta_buffer #(
    .MaxTxns        ( MaxTxns       ),
    .AtopSupport    ( AtopSupport   ),
    .MaxAtomicTxns  ( MaxAtomicTxns ),
    .buf_t          ( id_out_buf_t  ),
    .id_t           ( axi_out_id_t  )
  ) i_aw_meta_buffer (
    .clk_i          ( clk_i                   ),
    .rst_ni         ( rst_ni                  ),
    .test_enable_i  ( test_enable_i           ),
    .req_push_i     ( aw_out_push             ),
    .req_valid_i    ( axi_out_req_o.aw_valid  ),
    .req_buf_i      ( aw_out_data_in          ),
    .req_is_atop_i  ( is_atop                 ),
    .req_atop_id_i  ( '0                      ),
    .req_full_o     ( aw_out_full             ),
    .req_id_o       ( aw_out_id               ),
    .rsp_pop_i      ( aw_out_pop              ),
    .rsp_id_i       ( axi_out_rsp_i.b.id      ),
    .rsp_buf_o      ( aw_out_data_out         )
  );

  floo_meta_buffer #(
    .MaxTxns        ( MaxTxns       ),
    .AtopSupport    ( AtopSupport   ),
    .MaxAtomicTxns  ( MaxAtomicTxns ),
    .ExtAtomicId    ( 1'b1          ), // Use ID from AW channel
    .buf_t          ( id_out_buf_t  ),
    .id_t           ( axi_out_id_t  )
  ) i_ar_meta_buffer (
    .clk_i          ( clk_i                   ),
    .rst_ni         ( rst_ni                  ),
    .test_enable_i  ( test_enable_i           ),
    .req_push_i     ( ar_out_push             ),
    .req_valid_i    ( axi_out_req_o.ar_valid  ),
    .req_buf_i      ( ar_out_data_in          ),
    .req_is_atop_i  ( is_atop                 ),
    .req_atop_id_i  ( aw_out_id               ), // Use ID from AW channel
    .req_full_o     ( ar_out_full             ),
    .req_id_o       ( ar_out_id               ),
    .rsp_pop_i      ( ar_out_pop              ),
    .rsp_id_i       ( axi_out_rsp_i.r.id      ),
    .rsp_buf_o      ( ar_out_data_out         )
  );

  always_comb begin
    // Assign the outgoing AX an unique ID
    axi_aw_id_mod    = axi_unpack_aw;
    axi_ar_id_mod    = axi_unpack_ar;
    axi_aw_id_mod.id = aw_out_id;
    axi_ar_id_mod.id = ar_out_id;
  end

  // Registers
  `FF(b_rob_pending_q, b_rob_valid_out && !b_rob_ready_in && !is_atop_b_rsp, '0)
  `FF(r_rob_pending_q, r_rob_valid_out && !r_rob_ready_in && !is_atop_r_rsp, '0)

  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(ToSmallIdWidth, 1 + AtopSupport * MaxAtomicTxns <= 2**AxiOutIdWidth)

endmodule
