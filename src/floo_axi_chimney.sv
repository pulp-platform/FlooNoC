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
  import floo_axi_flit_pkg::*;
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
  output axi_in_resp_t axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input  axi_out_resp_t axi_out_rsp_i,
  /// Coordinates/ID of the current tile
  input  xy_id_t  xy_id_i,
  input  src_id_t id_i,
  /// Output to NoC
  output req_flit_t req_o,
  output rsp_flit_t rsp_o,
  /// Input from NoC
  input  req_flit_t req_i,
  input  rsp_flit_t rsp_i
);

  // AX queue
  axi_in_aw_chan_t aw_queue;
  axi_in_ar_chan_t ar_queue;
  logic aw_queue_valid_out, aw_queue_ready_in;
  logic ar_queue_valid_out, ar_queue_ready_in;

  axi_in_req_t axi_out_req_id_mapped;
  axi_in_resp_t axi_out_rsp_id_mapped;
  `AXI_ASSIGN_REQ_STRUCT(axi_out_req_o, axi_out_req_id_mapped)
  `AXI_ASSIGN_RESP_STRUCT(axi_out_rsp_id_mapped, axi_out_rsp_i)

  req_data_t [AxiInAw:AxiInAr] req_data_arb_data_in;
  rsp_data_t [AxiInB:AxiInR] rsp_data_arb_data_in;
  logic  [AxiInAw:AxiInAr] req_data_arb_req_in, req_data_arb_gnt_out;
  logic  [AxiInB:AxiInR] rsp_data_arb_req_in, rsp_data_arb_gnt_out;

  // flit queue
  req_flit_t req_in;
  rsp_flit_t rsp_in;
  logic req_ready_out, rsp_ready_out;
  logic [NumAxiChannels-1:0] axi_valid_in, axi_ready_out;

  // Flit packing
  axi_in_aw_data_t aw_data;
  axi_in_w_data_t w_data;
  axi_in_ar_data_t  ar_data;
  axi_in_b_data_t  b_data;
  axi_in_r_data_t  r_data;
  axi_in_aw_chan_t aw_id_mod;
  axi_in_ar_chan_t ar_id_mod;

  // Flit unpacking
  axi_in_aw_chan_t unpack_aw_data;
  axi_in_ar_chan_t unpack_ar_data;
  axi_in_w_chan_t  unpack_w_data;
  axi_in_b_chan_t  unpack_b_data;
  axi_in_r_chan_t  unpack_r_data;
  req_generic_t unpack_req_generic;
  rsp_generic_t unpack_rsp_generic;

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
      .data_i     ( axi_in_req_i.aw       ),
      .valid_i    ( axi_in_req_i.aw_valid ),
      .ready_o    ( axi_in_rsp_o.aw_ready ),
      .data_o     ( aw_queue              ),
      .valid_o    ( aw_queue_valid_out    ),
      .ready_i    ( aw_queue_ready_in     )
    );

    spill_register #(
      .T ( axi_in_ar_chan_t )
    ) i_ar_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( axi_in_req_i.ar       ),
      .valid_i    ( axi_in_req_i.ar_valid ),
      .ready_o    ( axi_in_rsp_o.ar_ready ),
      .data_o     ( ar_queue              ),
      .valid_o    ( ar_queue_valid_out    ),
      .ready_i    ( ar_queue_ready_in     )
    );
  end else begin : gen_no_ax_cuts
    assign aw_queue = axi_in_req_i.aw;
    assign aw_queue_valid_out = axi_in_req_i.aw_valid;
    assign axi_in_rsp_o.aw_ready = aw_queue_ready_in;

    assign ar_queue = axi_in_req_i.ar;
    assign ar_queue_valid_out = axi_in_req_i.ar_valid;
    assign axi_in_rsp_o.ar_ready = ar_queue_ready_in;
  end

  if (CutRsp) begin : gen_rsp_cuts
    spill_register #(
      .T ( req_data_t )
    ) i_data_req_arb (
      .clk_i      ( clk_i               ),
      .rst_ni     ( rst_ni              ),
      .data_i     ( req_i.data          ),
      .valid_i    ( req_i.valid         ),
      .ready_o    ( req_o.ready         ),
      .data_o     ( req_in.data         ),
      .valid_o    ( req_in.valid        ),
      .ready_i    ( req_ready_out       )
    );

    spill_register #(
      .T ( rsp_data_t )
    ) i_data_rsp_arb (
      .clk_i      ( clk_i               ),
      .rst_ni     ( rst_ni              ),
      .data_i     ( rsp_i.data          ),
      .valid_i    ( rsp_i.valid         ),
      .ready_o    ( rsp_o.ready         ),
      .data_o     ( rsp_in.data         ),
      .valid_o    ( rsp_in.valid        ),
      .ready_i    ( rsp_ready_out       )
    );
  end else begin : gen_no_rsp_cuts
    assign req_in = req_i;
    assign req_o.ready = req_ready_out;
    assign rsp_in = rsp_i;
    assign rsp_o.ready = rsp_ready_out;
  end

  ///////////////////////
  //  Reorder Buffers  //
  ///////////////////////

  // AW/B RoB
  axi_in_b_chan_t b_rob_out, b_rob_in;
  logic aw_rob_req_out;
  rob_idx_t aw_rob_idx_out;
  logic aw_rob_valid_in, aw_rob_ready_out;
  logic aw_rob_valid_out, aw_rob_ready_in;
  logic b_rob_valid_in, b_rob_ready_out;
  logic b_rob_valid_out, b_rob_ready_in;

  // AR/R RoB
  axi_in_r_chan_t r_rob_out, r_rob_in;
  logic ar_rob_req_out;
  rob_idx_t ar_rob_idx_out;
  logic ar_rob_valid_out, ar_rob_ready_in;
  logic r_rob_valid_in, r_rob_ready_out;
  logic r_rob_valid_out, r_rob_ready_in;

  if (AtopSupport) begin : gen_atop_support
    // Bypass AW/B RoB
    assign aw_rob_valid_in = aw_queue_valid_out && (aw_queue.atop == axi_pkg::ATOP_NONE);
    assign aw_queue_ready_in = (aw_queue.atop == axi_pkg::ATOP_NONE)?
                                aw_rob_ready_out : aw_rob_ready_in;
  end else begin : gen_no_atop_support
    assign aw_rob_valid_in = aw_queue_valid_out;
    assign aw_queue_ready_in = aw_rob_ready_out;
    `ASSERT(NoAtopSupport, !(aw_queue_valid_out && (aw_queue.atop != axi_pkg::ATOP_NONE)))
  end

  floo_simple_rob #(
    .ReorderBufferSize  ( ReorderBufferSize ),
    .MaxRoTxnsPerId     ( MaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b1              ),
    .ax_len_t           ( axi_pkg::len_t    ),
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
    .ax_len_i       ( aw_queue.len                  ),
    .ax_dest_i      ( dst_id[AxiInAw]               ),
    .ax_valid_o     ( aw_rob_valid_out              ),
    .ax_ready_i     ( aw_rob_ready_in               ),
    .ax_rob_req_o   ( aw_rob_req_out                ),
    .ax_rob_idx_o   ( aw_rob_idx_out                ),
    .rsp_valid_i    ( b_rob_valid_in                ),
    .rsp_ready_o    ( b_rob_ready_out               ),
    .rsp_i          ( b_rob_in                      ),
    .rsp_rob_req_i  ( rsp_in.data.axi_in_b.rob_req  ),
    .rsp_rob_idx_i  ( rsp_in.data.axi_in_b.rob_idx  ),
    .rsp_last_i     ( rsp_in.data.axi_in_b.last     ),
    .rsp_valid_o    ( b_rob_valid_out               ),
    .rsp_ready_i    ( b_rob_ready_in                ),
    .rsp_o          ( b_rob_out                     )
  );

  typedef logic [AxiInDataWidth-1:0] r_rob_data_t;
  typedef struct packed {
    axi_in_id_t     id;
    axi_in_user_t   user;
    axi_pkg::resp_t resp;
    logic           last;
  } r_rob_meta_t;

  if (RoBSimple) begin : gen_simple_rob
    floo_simple_rob #(
      .ReorderBufferSize  ( ReorderBufferSize ),
      .MaxRoTxnsPerId     ( MaxTxnsPerId      ),
      .OnlyMetaData       ( 1'b0              ),
      .ax_len_t           ( axi_pkg::len_t    ),
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
      .ax_valid_i     ( ar_queue_valid_out            ),
      .ax_ready_o     ( ar_queue_ready_in             ),
      .ax_len_i       ( ar_queue.len                  ),
      .ax_dest_i      ( dst_id[AxiInAr]               ),
      .ax_valid_o     ( ar_rob_valid_out              ),
      .ax_ready_i     ( ar_rob_ready_in               ),
      .ax_rob_req_o   ( ar_rob_req_out                ),
      .ax_rob_idx_o   ( ar_rob_idx_out                ),
      .rsp_valid_i    ( r_rob_valid_in                ),
      .rsp_ready_o    ( r_rob_ready_out               ),
      .rsp_i          ( r_rob_in                      ),
      .rsp_rob_req_i  ( rsp_in.data.axi_in_r.rob_req  ),
      .rsp_rob_idx_i  ( rsp_in.data.axi_in_r.rob_idx  ),
      .rsp_last_i     ( rsp_in.data.axi_in_r.last     ),
      .rsp_valid_o    ( r_rob_valid_out               ),
      .rsp_ready_i    ( r_rob_ready_in                ),
      .rsp_o          ( r_rob_out                     )
    );
  end else begin : gen_rob
    floo_rob #(
      .ReorderBufferSize  ( ReorderBufferSize ),
      .MaxRoTxnsPerId     ( MaxTxnsPerId      ),
      .OnlyMetaData       ( 1'b0              ),
      .ax_len_t           ( axi_pkg::len_t    ),
      .ax_id_t            ( axi_in_id_t       ),
      .rsp_chan_t         ( axi_in_r_chan_t   ),
      .rsp_data_t         ( r_rob_data_t      ),
      .rsp_meta_t         ( r_rob_meta_t      ),
      .dest_t             ( id_t              ),
      .sram_cfg_t         ( sram_cfg_t        )
    ) i_r_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i     ( ar_queue_valid_out            ),
      .ax_ready_o     ( ar_queue_ready_in             ),
      .ax_len_i       ( ar_queue.len                  ),
      .ax_id_i        ( ar_queue.id                   ),
      .ax_dest_i      ( dst_id[AxiInAr]               ),
      .ax_valid_o     ( ar_rob_valid_out              ),
      .ax_ready_i     ( ar_rob_ready_in               ),
      .ax_rob_req_o   ( ar_rob_req_out                ),
      .ax_rob_idx_o   ( ar_rob_idx_out                ),
      .rsp_valid_i    ( r_rob_valid_in                ),
      .rsp_ready_o    ( r_rob_ready_out               ),
      .rsp_i          ( r_rob_in                      ),
      .rsp_rob_req_i  ( rsp_in.data.axi_in_r.rob_req  ),
      .rsp_rob_idx_i  ( rsp_in.data.axi_in_r.rob_idx  ),
      .rsp_last_i     ( rsp_in.data.axi_in_r.last     ),
      .rsp_valid_o    ( r_rob_valid_out               ),
      .rsp_ready_i    ( r_rob_ready_in                ),
      .rsp_o          ( r_rob_out                     )
    );
  end

  /////////////////
  //   ROUTING   //
  /////////////////


  if (RouteAlgo == XYRouting) begin : gen_xy_routing
    xy_id_t aw_xy_id_q, aw_xy_id, ar_xy_id;
    assign src_id = xy_id_i;
    assign aw_xy_id.x = aw_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign aw_xy_id.y = aw_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign ar_xy_id.x = ar_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign ar_xy_id.y = ar_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign dst_id[AxiInAw] = aw_xy_id;
    assign dst_id[AxiInAr] = ar_xy_id;
    assign dst_id[AxiInW]  = aw_xy_id_q;
    assign dst_id[AxiInB]  = aw_out_data_out.src_id;
    assign dst_id[AxiInR]  = ar_out_data_out.src_id;
    `FFL(aw_xy_id_q, aw_xy_id, aw_queue_valid_out && aw_queue_ready_in, '0)
  end else if (RouteAlgo == IdTable) begin : gen_id_table_routing
    id_t aw_id_q, aw_id, ar_id;
    assign src_id = id_i;
    assign aw_id = aw_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign ar_id = ar_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign dst_id[AxiInAw] = aw_id;
    assign dst_id[AxiInAr] = ar_id;
    assign dst_id[AxiInW]  = aw_id_q;
    assign dst_id[AxiInB]  = aw_out_data_out.src_id;
    assign dst_id[AxiInR]  = ar_out_data_out.src_id;
    `FFL(aw_id_q, aw_id, aw_queue_valid_out && aw_queue_ready_in, '0)
  end else begin : gen_no_routing
    // TODO: Implement other routing algorithms
    $fatal(1, "Routing algorithm not implemented");
  end

  ///////////////////
  // FLIT PACKING  //
  ///////////////////

  always_comb begin
    aw_data         = '0;
    aw_data.rob_req = aw_rob_req_out;
    aw_data.rob_idx = aw_rob_idx_out;
    aw_data.dst_id  = dst_id[AxiInAw];
    aw_data.src_id  = src_id;
    aw_data.last    = 1'b1;
    aw_data.axi_ch  = AxiInAw;
    aw_data.aw      = aw_queue;
    aw_data.atop    = aw_queue.atop != axi_pkg::ATOP_NONE;
  end

  always_comb begin
    w_data          = '0;
    w_data.rob_req  = aw_rob_req_out;
    w_data.rob_idx  = aw_rob_idx_out;
    w_data.dst_id   = dst_id[AxiInW];
    w_data.src_id   = src_id;
    w_data.last     = axi_in_req_i.w.last;
    w_data.axi_ch   = AxiInW;
    w_data.w        = axi_in_req_i.w;
  end

  always_comb begin
    ar_data         = '0;
    ar_data.rob_req = ar_rob_req_out;
    ar_data.rob_idx = ar_rob_idx_out;
    ar_data.dst_id  = dst_id[AxiInAr];
    ar_data.src_id  = src_id;
    ar_data.last    = 1'b1;
    ar_data.axi_ch  = AxiInAr;
    ar_data.ar      = ar_queue;
  end

  always_comb begin
    b_data          = '0;
    b_data.rob_req  = aw_out_data_out.rob_req;
    b_data.rob_idx  = aw_out_data_out.rob_idx;
    b_data.dst_id   = aw_out_data_out.src_id;
    b_data.src_id   = src_id;
    b_data.last     = 1'b1;
    b_data.axi_ch   = AxiInB;
    b_data.b        = axi_out_rsp_id_mapped.b;
    b_data.b.id     = aw_out_data_out.id;
    b_data.atop     = aw_out_data_out.atop;
  end

  always_comb begin
    r_data        = '0;
    r_data.rob_req    = ar_out_data_out.rob_req;
    r_data.rob_idx    = ar_out_data_out.rob_idx;
    r_data.dst_id = ar_out_data_out.src_id;
    r_data.src_id = src_id;
    r_data.last   = axi_out_rsp_i.r.last;
    r_data.axi_ch = AxiInR;
    r_data.r      = axi_out_rsp_id_mapped.r;
    r_data.r.id   = ar_out_data_out.id;
    r_data.atop   = ar_out_data_out.atop;
  end

  always_comb begin
    aw_w_sel_d = aw_w_sel_q;
    if (aw_queue_valid_out && aw_queue_ready_in) aw_w_sel_d = SelW;
    if (axi_in_req_i.w_valid && axi_in_rsp_o.w_ready && axi_in_req_i.w.last) aw_w_sel_d = SelAw;
  end

  `FF(aw_w_sel_q, aw_w_sel_d, SelAw)

  assign req_data_arb_req_in[AxiInAw] = (aw_w_sel_q == SelAw) && (aw_rob_valid_out ||
                                        ((aw_queue.atop != axi_pkg::ATOP_NONE) &&
                                          aw_queue_valid_out));
  assign req_data_arb_req_in[AxiInW]  = (aw_w_sel_q == SelW) && axi_in_req_i.w_valid;
  assign req_data_arb_req_in[AxiInAr] = ar_rob_valid_out;
  assign rsp_data_arb_req_in[AxiInB]  = axi_out_rsp_i.b_valid;
  assign rsp_data_arb_req_in[AxiInR]  = axi_out_rsp_i.r_valid;

  assign aw_rob_ready_in       = req_data_arb_gnt_out[AxiInAw] && (aw_w_sel_q == SelAw);
  assign axi_in_rsp_o.w_ready  = req_data_arb_gnt_out[AxiInW] && (aw_w_sel_q == SelW);
  assign ar_rob_ready_in       = req_data_arb_gnt_out[AxiInAr];
  assign axi_out_req_id_mapped.b_ready = rsp_data_arb_gnt_out[AxiInB];
  assign axi_out_req_id_mapped.r_ready = rsp_data_arb_gnt_out[AxiInR];

  assign req_data_arb_data_in[AxiInAw]  = aw_data;
  assign req_data_arb_data_in[AxiInW]   = w_data;
  assign req_data_arb_data_in[AxiInAr]  = ar_data;
  assign rsp_data_arb_data_in[AxiInB]   = b_data;
  assign rsp_data_arb_data_in[AxiInR]   = r_data;

  ///////////////////////
  // FLIT ARBITRATION  //
  ///////////////////////

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumVirtPerPhys[PhysReq] ),
    .flit_t     ( req_generic_t           )
  ) i_req_wormhole_arbiter (
    .clk_i    ( clk_i                 ),
    .rst_ni   ( rst_ni                ),
    .valid_i  ( req_data_arb_req_in   ),
    .data_i   ( req_data_arb_data_in  ),
    .ready_o  ( req_data_arb_gnt_out  ),
    .data_o   ( req_o.data            ),
    .ready_i  ( req_i.ready           ),
    .valid_o  ( req_o.valid           )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumVirtPerPhys[PhysRsp] ),
    .flit_t     ( rsp_generic_t           )
  ) i_rsp_wormhole_arbiter (
    .clk_i    ( clk_i                 ),
    .rst_ni   ( rst_ni                ),
    .valid_i  ( rsp_data_arb_req_in   ),
    .data_i   ( rsp_data_arb_data_in  ),
    .ready_o  ( rsp_data_arb_gnt_out  ),
    .data_o   ( rsp_o.data            ),
    .ready_i  ( rsp_i.ready           ),
    .valid_o  ( rsp_o.valid           )
  );

  ////////////////////
  // FLIT UNPACKER  //
  ////////////////////

  logic is_atop_b_rsp, is_atop_r_rsp;
  logic b_sel_atop, r_sel_atop;
  logic b_rob_pending_q, r_rob_pending_q;

  assign is_atop_b_rsp = AtopSupport && axi_valid_in[AxiInB] && unpack_rsp_generic.atop;
  assign is_atop_r_rsp = AtopSupport && axi_valid_in[AxiInR] && unpack_rsp_generic.atop;
  assign b_sel_atop = is_atop_b_rsp && !b_rob_pending_q;
  assign r_sel_atop = is_atop_r_rsp && !r_rob_pending_q;

  assign unpack_aw_data = req_in.data.axi_in_aw.aw;
  assign unpack_w_data  = req_in.data.axi_in_w.w;
  assign unpack_ar_data = req_in.data.axi_in_ar.ar;
  assign unpack_r_data  = rsp_in.data.axi_in_r.r;
  assign unpack_b_data  = rsp_in.data.axi_in_b.b;
  assign unpack_req_generic = req_in.data.gen;
  assign unpack_rsp_generic = rsp_in.data.gen;

  assign axi_valid_in[AxiInAw] = req_in.valid && (unpack_req_generic.axi_ch == AxiInAw);
  assign axi_valid_in[AxiInW]  = req_in.valid && (unpack_req_generic.axi_ch == AxiInW);
  assign axi_valid_in[AxiInAr] = req_in.valid && (unpack_req_generic.axi_ch == AxiInAr);
  assign axi_valid_in[AxiInB]  = rsp_in.valid && (unpack_rsp_generic.axi_ch == AxiInB);
  assign axi_valid_in[AxiInR]  = rsp_in.valid && (unpack_rsp_generic.axi_ch == AxiInR);

  assign axi_ready_out[AxiInAw] = axi_out_rsp_i.aw_ready && !aw_out_full;
  assign axi_ready_out[AxiInW]  = axi_out_rsp_i.w_ready;
  assign axi_ready_out[AxiInAr] = axi_out_rsp_i.ar_ready && !ar_out_full;
  assign axi_ready_out[AxiInB]  = b_rob_ready_out || b_sel_atop && axi_in_req_i.b_ready;
  assign axi_ready_out[AxiInR]  = r_rob_ready_out || r_sel_atop && axi_in_req_i.r_ready;

  assign req_ready_out = axi_ready_out[unpack_req_generic.axi_ch];
  assign rsp_ready_out = axi_ready_out[unpack_rsp_generic.axi_ch];

  /////////////////////////////
  // AXI req/rsp generation  //
  ////////////////////////////

  assign axi_out_req_id_mapped.aw_valid = axi_valid_in[AxiInAw] && !aw_out_full;
  assign axi_out_req_id_mapped.w_valid  = axi_valid_in[AxiInW];
  assign axi_out_req_id_mapped.ar_valid = axi_valid_in[AxiInAr] && !ar_out_full;
  assign b_rob_valid_in         = axi_valid_in[AxiInB] && !is_atop_b_rsp;
  assign r_rob_valid_in         = axi_valid_in[AxiInR] && !is_atop_r_rsp;
  assign axi_in_rsp_o.b_valid   = b_rob_valid_out || is_atop_b_rsp;
  assign axi_in_rsp_o.r_valid   = r_rob_valid_out || is_atop_r_rsp;
  assign b_rob_ready_in         = axi_in_req_i.b_ready && !b_sel_atop;
  assign r_rob_ready_in         = axi_in_req_i.r_ready && !r_sel_atop;

  assign axi_out_req_id_mapped.aw = aw_id_mod;
  assign axi_out_req_id_mapped.w  = unpack_w_data;
  assign axi_out_req_id_mapped.ar = ar_id_mod;
  assign b_rob_in         = unpack_b_data;
  assign r_rob_in         = unpack_r_data;
  assign axi_in_rsp_o.b   = (b_sel_atop)? unpack_b_data : b_rob_out;
  assign axi_in_rsp_o.r   = (r_sel_atop)? unpack_r_data : r_rob_out;

  logic is_atop, atop_has_r_rsp;
  assign is_atop = AtopSupport && axi_valid_in[AxiInAw] &&
                    (unpack_aw_data.atop != axi_pkg::ATOP_NONE);
  assign atop_has_r_rsp = AtopSupport && axi_valid_in[AxiInAw] &&
                          unpack_aw_data.atop[axi_pkg::ATOP_R_RESP];

  assign aw_out_push = axi_out_req_o.aw_valid && axi_out_rsp_i.aw_ready;
  assign ar_out_push = axi_out_req_o.ar_valid && axi_out_rsp_i.ar_ready ||
                       axi_out_req_o.aw_valid && axi_out_rsp_i.aw_ready &&
                      is_atop && atop_has_r_rsp;
  assign aw_out_pop = axi_out_rsp_i.b_valid && axi_out_req_o.b_ready;
  assign ar_out_pop = axi_out_rsp_i.r_valid && axi_out_req_o.r_ready && axi_out_rsp_i.r.last;

  assign aw_out_data_in = '{
    id: unpack_aw_data.id,
    rob_req: unpack_req_generic.rob_req,
    rob_idx: unpack_req_generic.rob_idx,
    src_id: unpack_req_generic.src_id,
    atop: unpack_req_generic.atop
  };
  assign ar_out_data_in = '{
    id: (is_atop && atop_has_r_rsp)? unpack_aw_data.id : unpack_ar_data.id,
    rob_req: unpack_req_generic.rob_req,
    rob_idx: unpack_req_generic.rob_idx,
    src_id: unpack_req_generic.src_id,
    atop: unpack_req_generic.atop
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
    aw_id_mod    = unpack_aw_data;
    ar_id_mod    = unpack_ar_data;
    aw_id_mod.id = aw_out_id;
    ar_id_mod.id = ar_out_id;
  end

  // Registers
  `FF(b_rob_pending_q, b_rob_valid_out && !b_rob_ready_in && !is_atop_b_rsp, '0)
  `FF(r_rob_pending_q, r_rob_valid_out && !r_rob_ready_in && !is_atop_r_rsp, '0)

  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(ToSmallIdWidth, 1 + AtopSupport * MaxAtomicTxns <= 2**AxiOutIdWidth)

endmodule
