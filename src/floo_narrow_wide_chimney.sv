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
  import floo_narrow_wide_flit_pkg::*;
#(
  /// Atomic operation support, currently only implemented for
  /// the narrow network!
  parameter bit AtopSupport                 = 1'b1,
  /// Maximum number of oustanding Atomic transactions,
  /// must be smaller or equal to 2**AxiOutIdWidth-1 since
  /// Every atomic transactions needs to have a unique ID
  /// and one ID is reserved for non-atomic transactions
  parameter int unsigned MaxAtomicTxns      = 1,
  /// Routing Algorithm
  parameter route_algo_e RouteAlgo               = IdTable,
  /// X Coordinate address offset for XY routing
  parameter int unsigned XYAddrOffsetX           = 0,
  /// Y Coordinate address offset for XY routing
  parameter int unsigned XYAddrOffsetY           = 0,
  /// ID address offset for ID routing
  parameter int unsigned IdTableAddrOffset       = 8,
  /// Number of maximum oustanding requests on the narrow network
  parameter int unsigned NarrowMaxTxns           = 32,
  /// Number of maximum oustanding requests on the wide network
  parameter int unsigned WideMaxTxns             = 32,
  /// Maximum number of outstanding requests per ID on the narrow network
  parameter int unsigned NarrowMaxTxnsPerId      = NarrowMaxTxns,
  /// Maximum number of outstanding requests per ID on the wide network
  parameter int unsigned WideMaxTxnsPerId        = WideMaxTxns,
  /// Capacity of the narrow reorder buffers
  parameter int unsigned NarrowReorderBufferSize = 32,
  /// Capacity of the wide reorder buffers
  parameter int unsigned WideReorderBufferSize   = 32,
  /// Choice between simple or advanced narrow reorder buffers,
  /// trade-off between area and performance
  parameter bit NarrowRoBSimple                  = 1'b0,
  /// Choice between simple or advanced wide reorder buffers,
  /// trade-off between area and performance
  parameter bit WideRoBSimple                    = 1'b0,
  /// Cut timing paths of outgoing requests to the NoC
  parameter bit CutAx                            = 1'b1,
  /// Cut timing paths of incoming responses from the NoC
  parameter bit CutRsp                           = 1'b1,
  /// Only used for XYRouting
  parameter type xy_id_t                         = logic,
  /// Type for implementation inputs and outputs
  parameter type         sram_cfg_t  = logic,
  /// Derived parameters, do not change
  localparam type        narrow_rob_idx_t = logic [$clog2(NarrowReorderBufferSize)-1:0],
  localparam type        wide_rob_idx_t = logic [$clog2(WideReorderBufferSize)-1:0]
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  sram_cfg_t  sram_cfg_i,
  /// AXI4 side interfaces
  input  narrow_in_req_t narrow_in_req_i,
  output narrow_in_resp_t narrow_in_rsp_o,
  output narrow_out_req_t narrow_out_req_o,
  input  narrow_out_resp_t narrow_out_rsp_i,
  input  wide_in_req_t wide_in_req_i,
  output wide_in_resp_t wide_in_rsp_o,
  output wide_out_req_t wide_out_req_o,
  input  wide_out_resp_t wide_out_rsp_i,
  /// Coordinates/ID of the current tile
  input  xy_id_t  xy_id_i,
  input  src_id_t id_i,
  /// Output to NoC
  output narrow_req_flit_t      narrow_req_o,
  output narrow_rsp_flit_t      narrow_rsp_o,
  output wide_flit_t            wide_o,
  /// Input from NoC
  input  narrow_req_flit_t      narrow_req_i,
  input  narrow_rsp_flit_t      narrow_rsp_i,
  input  wide_flit_t            wide_i
);

  // AX queue
  narrow_in_aw_chan_t narrow_aw_queue;
  narrow_in_ar_chan_t narrow_ar_queue;
  wide_in_aw_chan_t wide_aw_queue;
  wide_in_ar_chan_t wide_ar_queue;
  logic narrow_aw_queue_valid_out, narrow_aw_queue_ready_in;
  logic narrow_ar_queue_valid_out, narrow_ar_queue_ready_in;
  logic wide_aw_queue_valid_out, wide_aw_queue_ready_in;
  logic wide_ar_queue_valid_out, wide_ar_queue_ready_in;

  narrow_in_req_t narrow_out_req_id_mapped;
  narrow_in_resp_t narrow_out_rsp_id_mapped;
  wide_in_req_t wide_out_req_id_mapped;
  wide_in_resp_t wide_out_rsp_id_mapped;
  `AXI_ASSIGN_REQ_STRUCT(narrow_out_req_o, narrow_out_req_id_mapped)
  `AXI_ASSIGN_RESP_STRUCT(narrow_out_rsp_id_mapped, narrow_out_rsp_i)
  `AXI_ASSIGN_REQ_STRUCT(wide_out_req_o, wide_out_req_id_mapped)
  `AXI_ASSIGN_RESP_STRUCT(wide_out_rsp_id_mapped, wide_out_rsp_i)

  narrow_req_data_t [WideInAw:NarrowInAw] narrow_req_data_arb_data_in;
  narrow_rsp_data_t [WideInB:NarrowInB] narrow_rsp_data_arb_data_in;
  wide_data_t [WideInR:WideInW] wide_data_arb_data_in;
  logic  [WideInAw:NarrowInAw] narrow_req_data_arb_req_in, narrow_req_data_arb_gnt_out;
  logic  [WideInB:NarrowInB] narrow_rsp_data_arb_req_in, narrow_rsp_data_arb_gnt_out;
  logic  [WideInR:WideInW] wide_data_arb_req_in, wide_data_arb_gnt_out;

  // flit queue
  narrow_req_flit_t narrow_req_in;
  narrow_rsp_flit_t narrow_rsp_in;
  wide_flit_t wide_in;
  logic narrow_req_ready_out, narrow_rsp_ready_out;
  logic wide_ready_out;
  logic [NumAxiChannels-1:0] axi_valid_in, axi_ready_out;

  // Flit packing
  narrow_in_aw_data_t narrow_aw_data;
  narrow_in_ar_data_t narrow_ar_data;
  narrow_in_w_data_t  narrow_w_data;
  narrow_in_b_data_t  narrow_b_data;
  narrow_in_r_data_t  narrow_r_data;
  narrow_in_aw_chan_t narrow_aw_id_mod;
  narrow_in_ar_chan_t narrow_ar_id_mod;
  wide_in_aw_data_t wide_aw_data;
  wide_in_ar_data_t wide_ar_data;
  wide_in_w_data_t  wide_w_data;
  wide_in_b_data_t  wide_b_data;
  wide_in_r_data_t  wide_r_data;
  wide_in_aw_chan_t wide_aw_id_mod;
  wide_in_ar_chan_t wide_ar_id_mod;

  // Flit arbitration
  typedef enum logic {SelAw, SelW} aw_w_sel_e;
  aw_w_sel_e narrow_aw_w_sel_q, narrow_aw_w_sel_d;
  aw_w_sel_e wide_aw_w_sel_q, wide_aw_w_sel_d;

  // Flit unpacking
  narrow_in_aw_chan_t  narrow_unpack_aw_data;
  narrow_in_w_chan_t   narrow_unpack_w_data;
  narrow_in_b_chan_t   narrow_unpack_b_data;
  narrow_in_ar_chan_t  narrow_unpack_ar_data;
  narrow_in_r_chan_t   narrow_unpack_r_data;
  wide_in_aw_chan_t    wide_unpack_aw_data;
  wide_in_w_chan_t     wide_unpack_w_data;
  wide_in_b_chan_t     wide_unpack_b_data;
  wide_in_ar_chan_t    wide_unpack_ar_data;
  wide_in_r_chan_t     wide_unpack_r_data;
  narrow_req_generic_t narrow_unpack_req_generic;
  narrow_rsp_generic_t narrow_unpack_rsp_generic;
  wide_generic_t       wide_unpack_generic;

  typedef dst_id_t id_t;

  // ID tracking
  typedef struct packed {
    narrow_in_id_t   id;
    logic            rob_req;
    narrow_rob_idx_t rob_idx;
    id_t             src_id;
    logic            atop;
  } narrow_id_out_buf_t;

  typedef struct packed {
    wide_in_id_t   id;
    logic          rob_req;
    wide_rob_idx_t rob_idx;
    id_t           src_id;
  } wide_id_out_buf_t;

  // Routing
  id_t [NumAxiChannels-1:0] dst_id;
  id_t src_id;

  logic narrow_aw_out_push, narrow_aw_out_pop;
  logic narrow_ar_out_push, narrow_ar_out_pop;
  logic narrow_aw_out_full;
  logic narrow_ar_out_full;
  narrow_out_id_t narrow_aw_out_id;
  narrow_out_id_t narrow_ar_out_id;
  narrow_id_out_buf_t narrow_aw_out_data_in, narrow_aw_out_data_out;
  narrow_id_out_buf_t narrow_ar_out_data_in, narrow_ar_out_data_out;
  logic wide_aw_out_push, wide_aw_out_pop;
  logic wide_ar_out_push, wide_ar_out_pop;
  logic wide_aw_out_full;
  logic wide_ar_out_full;
  wide_out_id_t wide_aw_out_id;
  wide_out_id_t wide_ar_out_id;
  wide_id_out_buf_t wide_aw_out_data_in, wide_aw_out_data_out;
  wide_id_out_buf_t wide_ar_out_data_in, wide_ar_out_data_out;

  ///////////////////////
  //  Spill registers  //
  ///////////////////////

  if (CutAx) begin : gen_ax_cuts
    spill_register #(
      .T ( narrow_in_aw_chan_t )
    ) i_narrow_aw_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( narrow_in_req_i.aw        ),
      .valid_i    ( narrow_in_req_i.aw_valid  ),
      .ready_o    ( narrow_in_rsp_o.aw_ready  ),
      .data_o     ( narrow_aw_queue           ),
      .valid_o    ( narrow_aw_queue_valid_out ),
      .ready_i    ( narrow_aw_queue_ready_in  )
    );

    spill_register #(
      .T ( narrow_in_ar_chan_t )
    ) i_narrow_ar_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( narrow_in_req_i.ar        ),
      .valid_i    ( narrow_in_req_i.ar_valid  ),
      .ready_o    ( narrow_in_rsp_o.ar_ready  ),
      .data_o     ( narrow_ar_queue           ),
      .valid_o    ( narrow_ar_queue_valid_out ),
      .ready_i    ( narrow_ar_queue_ready_in  )
    );

    spill_register #(
      .T ( wide_in_aw_chan_t )
    ) i_wide_aw_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( wide_in_req_i.aw        ),
      .valid_i    ( wide_in_req_i.aw_valid  ),
      .ready_o    ( wide_in_rsp_o.aw_ready  ),
      .data_o     ( wide_aw_queue           ),
      .valid_o    ( wide_aw_queue_valid_out ),
      .ready_i    ( wide_aw_queue_ready_in  )
    );

    spill_register #(
      .T ( wide_in_ar_chan_t )
    ) i_wide_ar_queue (
      .clk_i,
      .rst_ni,
      .data_i     ( wide_in_req_i.ar        ),
      .valid_i    ( wide_in_req_i.ar_valid  ),
      .ready_o    ( wide_in_rsp_o.ar_ready  ),
      .data_o     ( wide_ar_queue           ),
      .valid_o    ( wide_ar_queue_valid_out ),
      .ready_i    ( wide_ar_queue_ready_in  )
    );
  end else begin : gen_ax_no_cuts
    assign narrow_aw_queue = narrow_in_req_i.aw;
    assign narrow_aw_queue_valid_out = narrow_in_req_i.aw_valid;
    assign narrow_in_rsp_o.aw_ready = narrow_aw_queue_ready_in;
    assign narrow_ar_queue = narrow_in_req_i.ar;
    assign narrow_ar_queue_valid_out = narrow_in_req_i.ar_valid;
    assign narrow_in_rsp_o.ar_ready = narrow_ar_queue_ready_in;
    assign wide_aw_queue = wide_in_req_i.aw;
    assign wide_aw_queue_valid_out = wide_in_req_i.aw_valid;
    assign wide_in_rsp_o.aw_ready = wide_aw_queue_ready_in;
    assign wide_ar_queue = wide_in_req_i.ar;
    assign wide_ar_queue_valid_out = wide_in_req_i.ar_valid;
    assign wide_in_rsp_o.ar_ready = wide_ar_queue_ready_in;
  end

  if (CutRsp) begin : gen_rsp_cuts
    spill_register #(
      .T ( narrow_req_data_t )
    ) i_narrow_data_req_arb (
      .clk_i      ( clk_i                 ),
      .rst_ni     ( rst_ni                ),
      .data_i     ( narrow_req_i.data     ),
      .valid_i    ( narrow_req_i.valid    ),
      .ready_o    ( narrow_req_o.ready    ),
      .data_o     ( narrow_req_in.data    ),
      .valid_o    ( narrow_req_in.valid   ),
      .ready_i    ( narrow_req_ready_out  )
    );

    spill_register #(
      .T ( narrow_rsp_data_t )
    ) i_narrow_data_rsp_arb (
      .clk_i      ( clk_i                ),
      .rst_ni     ( rst_ni               ),
      .data_i     ( narrow_rsp_i.data    ),
      .valid_i    ( narrow_rsp_i.valid   ),
      .ready_o    ( narrow_rsp_o.ready   ),
      .data_o     ( narrow_rsp_in.data   ),
      .valid_o    ( narrow_rsp_in.valid  ),
      .ready_i    ( narrow_rsp_ready_out )
    );

    spill_register #(
      .T ( wide_data_t )
    ) i_wide_data_req_arb (
      .clk_i      ( clk_i           ),
      .rst_ni     ( rst_ni          ),
      .data_i     ( wide_i.data     ),
      .valid_i    ( wide_i.valid    ),
      .ready_o    ( wide_o.ready    ),
      .data_o     ( wide_in.data    ),
      .valid_o    ( wide_in.valid   ),
      .ready_i    ( wide_ready_out  )
    );

  end else begin : gen_no_rsp_cuts
    assign narrow_req_in = narrow_req_i;
    assign narrow_rsp_in = narrow_rsp_i;
    assign wide_in = wide_i;
    assign narrow_req_o.ready = narrow_req_ready_out;
    assign narrow_rsp_o.ready = narrow_rsp_ready_out;
    assign wide_o.ready = wide_ready_out;
  end

  ///////////////////////
  //  Reorder Buffers  //
  ///////////////////////

  // AW/B RoB
  narrow_in_b_chan_t narrow_b_rob_out, narrow_b_rob_in;
  logic  narrow_aw_rob_req_out;
  narrow_rob_idx_t narrow_aw_rob_idx_out;
  logic narrow_aw_rob_valid_out, narrow_aw_rob_ready_in;
  logic narrow_aw_rob_valid_in, narrow_aw_rob_ready_out;
  logic narrow_b_rob_valid_in, narrow_b_rob_ready_out;
  logic narrow_b_rob_valid_out, narrow_b_rob_ready_in;
  wide_in_b_chan_t wide_b_rob_out, wide_b_rob_in;
  logic  wide_aw_rob_req_out;
  narrow_rob_idx_t wide_aw_rob_idx_out;
  logic wide_aw_rob_valid_out, wide_aw_rob_ready_in;
  logic wide_b_rob_valid_in, wide_b_rob_ready_out;
  logic wide_b_rob_valid_out, wide_b_rob_ready_in;

  // AR/R RoB
  narrow_in_r_chan_t narrow_r_rob_out, narrow_r_rob_in;
  logic  narrow_ar_rob_req_out;
  narrow_rob_idx_t narrow_ar_rob_idx_out;
  logic narrow_ar_rob_valid_out, narrow_ar_rob_ready_in;
  logic narrow_r_rob_valid_in, narrow_r_rob_ready_out;
  logic narrow_r_rob_valid_out, narrow_r_rob_ready_in;
  wide_in_r_chan_t wide_r_rob_out, wide_r_rob_in;
  logic  wide_ar_rob_req_out;
  wide_rob_idx_t wide_ar_rob_idx_out;
  logic wide_ar_rob_valid_out, wide_ar_rob_ready_in;
  logic wide_r_rob_valid_in, wide_r_rob_ready_out;
  logic wide_r_rob_valid_out, wide_r_rob_ready_in;

  logic narrow_b_rob_rob_req;
  logic narrow_b_rob_last;
  narrow_rob_idx_t narrow_b_rob_rob_idx;
  assign narrow_b_rob_rob_req = narrow_rsp_in.data.narrow_in_b.rob_req;
  assign narrow_b_rob_rob_idx = narrow_rob_idx_t'(narrow_rsp_in.data.narrow_in_b.rob_idx);
  assign narrow_b_rob_last = narrow_rsp_in.data.narrow_in_b.last;

  if (AtopSupport) begin : gen_atop_support
    // Bypass AW/B RoB
    assign narrow_aw_rob_valid_in = narrow_aw_queue_valid_out &&
                                    (narrow_aw_queue.atop == axi_pkg::ATOP_NONE);
    assign narrow_aw_queue_ready_in = (narrow_aw_queue.atop == axi_pkg::ATOP_NONE)?
                                      narrow_aw_rob_ready_out : narrow_aw_rob_ready_in;
  end else begin : gen_no_atop_support
    assign narrow_aw_rob_valid_in = narrow_aw_queue_valid_out;
    assign narrow_aw_queue_ready_in = narrow_aw_rob_ready_in;
    `ASSERT(NoAtopSupport, !(narrow_aw_queue_valid_out &&
                             (narrow_aw_queue.atop != axi_pkg::ATOP_NONE)))
  end

  floo_simple_rob #(
    .ReorderBufferSize  ( NarrowReorderBufferSize ),
    .MaxRoTxnsPerId     ( NarrowMaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b1                    ),
    .ax_len_t           ( axi_pkg::len_t          ),
    .rsp_chan_t         ( narrow_in_b_chan_t      ),
    .rsp_meta_t         ( narrow_in_b_chan_t      ),
    .rob_idx_t          ( narrow_rob_idx_t        ),
    .dest_t             ( id_t                    ),
    .sram_cfg_t         ( sram_cfg_t              )
  ) i_narrow_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( narrow_aw_rob_valid_in  ),
    .ax_ready_o     ( narrow_aw_rob_ready_out ),
    .ax_len_i       ( narrow_aw_queue.len     ),
    .ax_dest_i      ( dst_id[NarrowInAw]      ),
    .ax_valid_o     ( narrow_aw_rob_valid_out ),
    .ax_ready_i     ( narrow_aw_rob_ready_in  ),
    .ax_rob_req_o   ( narrow_aw_rob_req_out   ),
    .ax_rob_idx_o   ( narrow_aw_rob_idx_out   ),
    .rsp_valid_i    ( narrow_b_rob_valid_in   ),
    .rsp_ready_o    ( narrow_b_rob_ready_out  ),
    .rsp_i          ( narrow_b_rob_in         ),
    .rsp_rob_req_i  ( narrow_b_rob_rob_req    ),
    .rsp_rob_idx_i  ( narrow_b_rob_rob_idx    ),
    .rsp_last_i     ( narrow_b_rob_last       ),
    .rsp_valid_o    ( narrow_b_rob_valid_out  ),
    .rsp_ready_i    ( narrow_b_rob_ready_in   ),
    .rsp_o          ( narrow_b_rob_out        )
  );

  logic wide_b_rob_rob_req;
  logic wide_b_rob_last;
  narrow_rob_idx_t wide_b_rob_rob_idx;
  assign wide_b_rob_rob_req = narrow_rsp_in.data.wide_in_b.rob_req;
  assign wide_b_rob_rob_idx = narrow_rob_idx_t'(narrow_rsp_in.data.wide_in_b.rob_idx);
  assign wide_b_rob_last = narrow_rsp_in.data.wide_in_b.last;

  floo_simple_rob #(
    .ReorderBufferSize  ( WideReorderBufferSize ),
    .MaxRoTxnsPerId     ( WideMaxTxnsPerId      ),
    .OnlyMetaData       ( 1'b1                  ),
    .ax_len_t           ( axi_pkg::len_t        ),
    .rsp_chan_t         ( wide_in_b_chan_t      ),
    .rsp_meta_t         ( wide_in_b_chan_t      ),
    .rob_idx_t          ( narrow_rob_idx_t      ),
    .dest_t             ( id_t                  ),
    .sram_cfg_t         ( sram_cfg_t            )
  ) i_wide_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( wide_aw_queue_valid_out ),
    .ax_ready_o     ( wide_aw_queue_ready_in  ),
    .ax_len_i       ( wide_aw_queue.len       ),
    .ax_dest_i      ( dst_id[WideInAw]        ),
    .ax_valid_o     ( wide_aw_rob_valid_out   ),
    .ax_ready_i     ( wide_aw_rob_ready_in    ),
    .ax_rob_req_o   ( wide_aw_rob_req_out     ),
    .ax_rob_idx_o   ( wide_aw_rob_idx_out     ),
    .rsp_valid_i    ( wide_b_rob_valid_in     ),
    .rsp_ready_o    ( wide_b_rob_ready_out    ),
    .rsp_i          ( wide_b_rob_in           ),
    .rsp_rob_req_i  ( wide_b_rob_rob_req      ),
    .rsp_rob_idx_i  ( wide_b_rob_rob_idx      ),
    .rsp_last_i     ( wide_b_rob_last         ),
    .rsp_valid_o    ( wide_b_rob_valid_out    ),
    .rsp_ready_i    ( wide_b_rob_ready_in     ),
    .rsp_o          ( wide_b_rob_out          )
  );

  typedef struct packed {
    narrow_in_id_t    id;
    narrow_in_user_t  user;
    axi_pkg::resp_t   resp;
    logic             last;
  } narrow_meta_t;

  typedef struct packed {
    wide_in_id_t    id;
    wide_in_user_t  user;
    axi_pkg::resp_t resp;
    logic           last;
  } wide_meta_t;

  logic narrow_r_rob_rob_req;
  logic narrow_r_rob_last;
  narrow_rob_idx_t narrow_r_rob_rob_idx;
  assign narrow_r_rob_rob_req = narrow_rsp_in.data.narrow_in_r.rob_req;
  assign narrow_r_rob_rob_idx = narrow_rob_idx_t'(narrow_rsp_in.data.narrow_in_r.rob_idx);
  assign narrow_r_rob_last = narrow_rsp_in.data.narrow_in_r.last;

  if (NarrowRoBSimple) begin : gen_narrow_simple_rob
    floo_simple_rob #(
      .ReorderBufferSize  ( NarrowReorderBufferSize ),
      .MaxRoTxnsPerId     ( NarrowMaxTxnsPerId      ),
      .OnlyMetaData       ( 1'b0                    ),
      .ax_len_t           ( axi_pkg::len_t          ),
      .rsp_chan_t         ( narrow_in_r_chan_t      ),
      .rsp_data_t         ( narrow_in_data_t        ),
      .rsp_meta_t         ( narrow_meta_t           ),
      .rob_idx_t          ( narrow_rob_idx_t        ),
      .dest_t             ( id_t                    ),
      .sram_cfg_t         ( sram_cfg_t              )
    ) i_narrow_r_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i     ( narrow_ar_queue_valid_out ),
      .ax_ready_o     ( narrow_ar_queue_ready_in  ),
      .ax_len_i       ( narrow_ar_queue.len       ),
      .ax_dest_i      ( dst_id[NarrowInAr]        ),
      .ax_valid_o     ( narrow_ar_rob_valid_out   ),
      .ax_ready_i     ( narrow_ar_rob_ready_in    ),
      .ax_rob_req_o   ( narrow_ar_rob_req_out     ),
      .ax_rob_idx_o   ( narrow_ar_rob_idx_out     ),
      .rsp_valid_i    ( narrow_r_rob_valid_in     ),
      .rsp_ready_o    ( narrow_r_rob_ready_out    ),
      .rsp_i          ( narrow_r_rob_in           ),
      .rsp_rob_req_i  ( narrow_r_rob_rob_req      ),
      .rsp_rob_idx_i  ( narrow_r_rob_rob_idx      ),
      .rsp_last_i     ( narrow_r_rob_last         ),
      .rsp_valid_o    ( narrow_r_rob_valid_out    ),
      .rsp_ready_i    ( narrow_r_rob_ready_in     ),
      .rsp_o          ( narrow_r_rob_out          )
    );
  end else begin : gen_narrow_rob
    floo_rob #(
      .ReorderBufferSize  ( NarrowReorderBufferSize ),
      .MaxRoTxnsPerId     ( NarrowMaxTxnsPerId      ),
      .OnlyMetaData       ( 1'b0                    ),
      .ax_len_t           ( axi_pkg::len_t          ),
      .ax_id_t            ( narrow_in_id_t          ),
      .rsp_chan_t         ( narrow_in_r_chan_t      ),
      .rsp_data_t         ( narrow_in_data_t        ),
      .rsp_meta_t         ( narrow_meta_t           ),
      .rob_idx_t          ( narrow_rob_idx_t        ),
      .dest_t             ( id_t                    ),
      .sram_cfg_t         ( sram_cfg_t              )
    ) i_narrow_r_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i     ( narrow_ar_queue_valid_out ),
      .ax_ready_o     ( narrow_ar_queue_ready_in  ),
      .ax_len_i       ( narrow_ar_queue.len       ),
      .ax_id_i        ( narrow_ar_queue.id        ),
      .ax_dest_i      ( dst_id[NarrowInAr]        ),
      .ax_valid_o     ( narrow_ar_rob_valid_out   ),
      .ax_ready_i     ( narrow_ar_rob_ready_in    ),
      .ax_rob_req_o   ( narrow_ar_rob_req_out     ),
      .ax_rob_idx_o   ( narrow_ar_rob_idx_out     ),
      .rsp_valid_i    ( narrow_r_rob_valid_in     ),
      .rsp_ready_o    ( narrow_r_rob_ready_out    ),
      .rsp_i          ( narrow_r_rob_in           ),
      .rsp_rob_req_i  ( narrow_r_rob_rob_req      ),
      .rsp_rob_idx_i  ( narrow_r_rob_rob_idx      ),
      .rsp_last_i     ( narrow_r_rob_last         ),
      .rsp_valid_o    ( narrow_r_rob_valid_out    ),
      .rsp_ready_i    ( narrow_r_rob_ready_in     ),
      .rsp_o          ( narrow_r_rob_out          )
    );
  end

  logic wide_r_rob_rob_req;
  logic wide_r_rob_last;
  wide_rob_idx_t wide_r_rob_rob_idx;
  assign wide_r_rob_rob_req = wide_in.data.wide_in_r.rob_req;
  assign wide_r_rob_rob_idx = wide_rob_idx_t'(wide_in.data.wide_in_r.rob_idx);
  assign wide_r_rob_last = wide_in.data.wide_in_r.last;

  if (WideRoBSimple) begin : gen_wide_simple_rob
    floo_simple_rob #(
      .ReorderBufferSize  ( WideReorderBufferSize ),
      .MaxRoTxnsPerId     ( WideMaxTxnsPerId      ),
      .OnlyMetaData       ( 1'b0                  ),
      .ax_len_t           ( axi_pkg::len_t        ),
      .rsp_chan_t         ( wide_in_r_chan_t      ),
      .rsp_data_t         ( wide_in_data_t        ),
      .rsp_meta_t         ( wide_meta_t           ),
      .rob_idx_t          ( wide_rob_idx_t        ),
      .dest_t             ( id_t                  ),
      .sram_cfg_t         ( sram_cfg_t            )
    ) i_wide_r_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i     ( wide_ar_queue_valid_out ),
      .ax_ready_o     ( wide_ar_queue_ready_in  ),
      .ax_len_i       ( wide_ar_queue.len       ),
      .ax_dest_i      ( dst_id[WideInAr]        ),
      .ax_valid_o     ( wide_ar_rob_valid_out   ),
      .ax_ready_i     ( wide_ar_rob_ready_in    ),
      .ax_rob_req_o   ( wide_ar_rob_req_out     ),
      .ax_rob_idx_o   ( wide_ar_rob_idx_out     ),
      .rsp_valid_i    ( wide_r_rob_valid_in     ),
      .rsp_ready_o    ( wide_r_rob_ready_out    ),
      .rsp_i          ( wide_r_rob_in           ),
      .rsp_rob_req_i  ( wide_r_rob_rob_req      ),
      .rsp_rob_idx_i  ( wide_r_rob_rob_idx      ),
      .rsp_last_i     ( wide_r_rob_last         ),
      .rsp_valid_o    ( wide_r_rob_valid_out    ),
      .rsp_ready_i    ( wide_r_rob_ready_in     ),
      .rsp_o          ( wide_r_rob_out          )
    );
  end else begin : gen_wide_rob
    floo_rob #(
      .ReorderBufferSize  ( WideReorderBufferSize ),
      .MaxRoTxnsPerId     ( WideMaxTxnsPerId      ),
      .OnlyMetaData       ( 1'b0                  ),
      .ax_len_t           ( axi_pkg::len_t        ),
      .ax_id_t            ( wide_in_id_t          ),
      .rsp_chan_t         ( wide_in_r_chan_t      ),
      .rsp_data_t         ( wide_in_data_t        ),
      .rsp_meta_t         ( wide_meta_t           ),
      .rob_idx_t          ( wide_rob_idx_t        ),
      .dest_t             ( id_t                  ),
      .sram_cfg_t         ( sram_cfg_t            )
    ) i_wide_r_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i     ( wide_ar_queue_valid_out ),
      .ax_ready_o     ( wide_ar_queue_ready_in  ),
      .ax_len_i       ( wide_ar_queue.len       ),
      .ax_id_i        ( wide_ar_queue.id        ),
      .ax_dest_i      ( dst_id[WideInAr]        ),
      .ax_valid_o     ( wide_ar_rob_valid_out   ),
      .ax_ready_i     ( wide_ar_rob_ready_in    ),
      .ax_rob_req_o   ( wide_ar_rob_req_out     ),
      .ax_rob_idx_o   ( wide_ar_rob_idx_out     ),
      .rsp_valid_i    ( wide_r_rob_valid_in     ),
      .rsp_ready_o    ( wide_r_rob_ready_out    ),
      .rsp_i          ( wide_r_rob_in           ),
      .rsp_rob_req_i  ( wide_r_rob_rob_req      ),
      .rsp_rob_idx_i  ( wide_r_rob_rob_idx      ),
      .rsp_last_i     ( wide_r_rob_last         ),
      .rsp_valid_o    ( wide_r_rob_valid_out    ),
      .rsp_ready_i    ( wide_r_rob_ready_in     ),
      .rsp_o          ( wide_r_rob_out          )
    );
  end

  /////////////////
  //   ROUTING   //
  /////////////////


  if (RouteAlgo == XYRouting) begin : gen_xy_routing
    xy_id_t narrow_aw_xy_id_q, narrow_aw_xy_id, narrow_ar_xy_id;
    xy_id_t wide_aw_xy_id_q, wide_aw_xy_id, wide_ar_xy_id;
    assign src_id = xy_id_i;
    assign narrow_aw_xy_id.x = narrow_aw_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign narrow_aw_xy_id.y = narrow_aw_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign narrow_ar_xy_id.x = narrow_ar_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign narrow_ar_xy_id.y = narrow_ar_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign wide_aw_xy_id.x = wide_aw_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign wide_aw_xy_id.y = wide_aw_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign wide_ar_xy_id.x = wide_ar_queue.addr[XYAddrOffsetX+:$bits(xy_id_i.x)];
    assign wide_ar_xy_id.y = wide_ar_queue.addr[XYAddrOffsetY+:$bits(xy_id_i.y)];
    assign dst_id[NarrowInAw] = narrow_aw_xy_id;
    assign dst_id[NarrowInAr] = narrow_ar_xy_id;
    assign dst_id[NarrowInW]  = narrow_aw_xy_id_q;
    assign dst_id[NarrowInB]  = narrow_aw_out_data_out.src_id;
    assign dst_id[NarrowInR]  = narrow_ar_out_data_out.src_id;
    assign dst_id[WideInAw] = wide_aw_xy_id;
    assign dst_id[WideInAr] = wide_ar_xy_id;
    assign dst_id[WideInW]  = wide_aw_xy_id_q;
    assign dst_id[WideInB]  = wide_aw_out_data_out.src_id;
    assign dst_id[WideInR]  = wide_ar_out_data_out.src_id;
    `FFL(narrow_aw_xy_id_q,narrow_aw_xy_id,narrow_aw_queue_valid_out && narrow_aw_queue_ready_in,'0)
    `FFL(wide_aw_xy_id_q, wide_aw_xy_id, wide_aw_queue_valid_out && wide_aw_queue_ready_in, '0)
  end else if (RouteAlgo == IdTable) begin : gen_id_table_routing
    id_t narrow_aw_id_q, narrow_aw_id, narrow_ar_id;
    id_t wide_aw_id_q, wide_aw_id, wide_ar_id;
    assign src_id = id_i;
    assign narrow_aw_id = narrow_aw_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign narrow_ar_id = narrow_ar_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign wide_aw_id = wide_aw_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign wide_ar_id = wide_ar_queue.addr[IdTableAddrOffset+:$bits(id_i)];
    assign dst_id[NarrowInAw] = narrow_aw_id;
    assign dst_id[NarrowInAr] = narrow_ar_id;
    assign dst_id[NarrowInW]  = narrow_aw_id_q;
    assign dst_id[NarrowInB]  = narrow_aw_out_data_out.src_id;
    assign dst_id[NarrowInR]  = narrow_ar_out_data_out.src_id;
    assign dst_id[WideInAw] = wide_aw_id;
    assign dst_id[WideInAr] = wide_ar_id;
    assign dst_id[WideInW]  = wide_aw_id_q;
    assign dst_id[WideInB]  = wide_aw_out_data_out.src_id;
    assign dst_id[WideInR]  = wide_ar_out_data_out.src_id;
    `FFL(narrow_aw_id_q, narrow_aw_id, narrow_aw_queue_valid_out && narrow_aw_queue_ready_in, '0)
    `FFL(wide_aw_id_q, wide_aw_id, wide_aw_queue_valid_out && wide_aw_queue_ready_in, '0)
  end else begin : gen_no_routing
    // TODO: Implement other routing algorithms
    $fatal(1, "Routing algorithm not implemented");
  end

  ///////////////////
  // FLIT PACKING  //
  ///////////////////

  always_comb begin
    narrow_aw_data          = '0;
    narrow_aw_data.rob_req  = narrow_aw_rob_req_out;
    narrow_aw_data.rob_idx  = rob_idx_t'(narrow_aw_rob_idx_out);
    narrow_aw_data.dst_id   = dst_id[NarrowInAw];
    narrow_aw_data.src_id   = src_id;
    narrow_aw_data.last     = 1'b1;
    narrow_aw_data.axi_ch   = NarrowInAw;
    narrow_aw_data.aw       = narrow_aw_queue;
    narrow_aw_data.atop     = narrow_aw_queue.atop != axi_pkg::ATOP_NONE;
  end

  always_comb begin
    narrow_w_data           = '0;
    narrow_w_data.rob_req   = narrow_aw_rob_req_out;
    narrow_w_data.rob_idx   = rob_idx_t'(narrow_aw_rob_idx_out);
    narrow_w_data.dst_id    = dst_id[NarrowInW];
    narrow_w_data.src_id    = src_id;
    narrow_w_data.last      = narrow_in_req_i.w.last;
    narrow_w_data.axi_ch    = NarrowInW;
    narrow_w_data.w         = narrow_in_req_i.w;
  end

  always_comb begin
    narrow_ar_data          = '0;
    narrow_ar_data.rob_req  = narrow_ar_rob_req_out;
    narrow_ar_data.rob_idx  = rob_idx_t'(narrow_ar_rob_idx_out);
    narrow_ar_data.dst_id   = dst_id[NarrowInAr];
    narrow_ar_data.src_id   = src_id;
    narrow_ar_data.last     = 1'b1;
    narrow_ar_data.axi_ch   = NarrowInAr;
    narrow_ar_data.ar       = narrow_ar_queue;
  end

  always_comb begin
    narrow_b_data           = '0;
    narrow_b_data.rob_req   = narrow_aw_out_data_out.rob_req;
    narrow_b_data.rob_idx   = rob_idx_t'(narrow_aw_out_data_out.rob_idx);
    narrow_b_data.dst_id        = narrow_aw_out_data_out.src_id;
    narrow_b_data.src_id    = src_id;
    narrow_b_data.last      = 1'b1;
    narrow_b_data.axi_ch    = NarrowInB;
    narrow_b_data.b         = narrow_out_rsp_id_mapped.b;
    narrow_b_data.b.id      = narrow_aw_out_data_out.id;
    narrow_b_data.atop      = narrow_aw_out_data_out.atop;
  end

  always_comb begin
    narrow_r_data           = '0;
    narrow_r_data.rob_req   = narrow_ar_out_data_out.rob_req;
    narrow_r_data.rob_idx   = rob_idx_t'(narrow_ar_out_data_out.rob_idx);
    narrow_r_data.dst_id        = narrow_ar_out_data_out.src_id;
    narrow_r_data.src_id    = src_id;
    narrow_r_data.axi_ch    = NarrowInR;
    narrow_r_data.last      = narrow_out_rsp_i.r.last;
    narrow_r_data.r         = narrow_out_rsp_id_mapped.r;
    narrow_r_data.r.id      = narrow_ar_out_data_out.id;
    narrow_r_data.atop      = narrow_ar_out_data_out.atop;
  end

  always_comb begin
    wide_aw_data            = '0;
    wide_aw_data.rob_req    = wide_aw_rob_req_out;
    wide_aw_data.rob_idx    = rob_idx_t'(wide_aw_rob_idx_out);
    wide_aw_data.dst_id     = dst_id[WideInAw];
    wide_aw_data.src_id     = src_id;
    wide_aw_data.last       = 1'b1;
    wide_aw_data.axi_ch     = WideInAw;
    wide_aw_data.aw         = wide_aw_queue;
  end

  always_comb begin
    wide_w_data             = '0;
    wide_w_data.rob_req     = wide_aw_rob_req_out;
    wide_w_data.rob_idx     = rob_idx_t'(wide_aw_rob_idx_out);
    wide_w_data.dst_id      = dst_id[WideInW];
    wide_w_data.src_id      = src_id;
    wide_w_data.last        = wide_in_req_i.w.last;
    wide_w_data.axi_ch      = WideInW;
    wide_w_data.w           = wide_in_req_i.w;
  end

  always_comb begin
    wide_ar_data            = '0;
    wide_ar_data.rob_req    = wide_ar_rob_req_out;
    wide_ar_data.rob_idx    = rob_idx_t'(wide_ar_rob_idx_out);
    wide_ar_data.dst_id     = dst_id[WideInAr];
    wide_ar_data.src_id     = src_id;
    wide_ar_data.last       = 1'b1;
    wide_ar_data.axi_ch     = WideInAr;
    wide_ar_data.ar         = wide_ar_queue;
  end

  always_comb begin
    wide_b_data             = '0;
    wide_b_data.rob_req     = wide_aw_out_data_out.rob_req;
    wide_b_data.rob_idx     = rob_idx_t'(wide_aw_out_data_out.rob_idx);
    wide_b_data.dst_id      = wide_aw_out_data_out.src_id;
    wide_b_data.src_id      = src_id;
    wide_b_data.last        = 1'b1;
    wide_b_data.axi_ch      = WideInB;
    wide_b_data.b           = wide_out_rsp_id_mapped.b;
    wide_b_data.b.id        = wide_aw_out_data_out.id;
  end

  always_comb begin
    wide_r_data             = '0;
    wide_r_data.rob_req     = wide_ar_out_data_out.rob_req;
    wide_r_data.rob_idx     = rob_idx_t'(wide_ar_out_data_out.rob_idx);
    wide_r_data.dst_id          = wide_ar_out_data_out.src_id;
    wide_r_data.src_id      = src_id;
    wide_r_data.axi_ch      = WideInR;
    wide_r_data.last        = wide_out_rsp_i.r.last;
    wide_r_data.r           = wide_out_rsp_id_mapped.r;
    wide_r_data.r.id        = wide_ar_out_data_out.id;
  end

  always_comb begin
    narrow_aw_w_sel_d = narrow_aw_w_sel_q;
    wide_aw_w_sel_d = wide_aw_w_sel_q;
    if (narrow_aw_queue_valid_out && narrow_aw_queue_ready_in) begin
      narrow_aw_w_sel_d = SelW;
    end
    if (narrow_in_req_i.w_valid && narrow_in_rsp_o.w_ready && narrow_in_req_i.w.last) begin
      narrow_aw_w_sel_d = SelAw;
    end
    if (wide_aw_queue_valid_out && wide_aw_queue_ready_in) begin
      wide_aw_w_sel_d = SelW;
    end
    if (wide_in_req_i.w_valid && wide_in_rsp_o.w_ready && wide_in_req_i.w.last) begin
      wide_aw_w_sel_d = SelAw;
    end
  end

  `FF(narrow_aw_w_sel_q, narrow_aw_w_sel_d, SelAw)
  `FF(wide_aw_w_sel_q, wide_aw_w_sel_d, SelAw)

  assign narrow_req_data_arb_req_in[NarrowInAw] = (narrow_aw_w_sel_q == SelAw) &&
                                                  (narrow_aw_rob_valid_out ||
                                                  ((narrow_aw_queue.atop != axi_pkg::ATOP_NONE) &&
                                                  narrow_aw_queue_valid_out));
  assign narrow_req_data_arb_req_in[NarrowInW]  = (narrow_aw_w_sel_q == SelW) &&
                                                  narrow_in_req_i.w_valid;
  assign narrow_req_data_arb_req_in[NarrowInAr] = narrow_ar_rob_valid_out;
  assign narrow_req_data_arb_req_in[WideInAw]   = (wide_aw_w_sel_q == SelAw) &&
                                                  wide_aw_rob_valid_out;
  assign narrow_req_data_arb_req_in[WideInAr]   = wide_ar_rob_valid_out;
  assign narrow_rsp_data_arb_req_in[NarrowInB]  = narrow_out_rsp_i.b_valid;
  assign narrow_rsp_data_arb_req_in[NarrowInR]  = narrow_out_rsp_i.r_valid;
  assign narrow_rsp_data_arb_req_in[WideInB]    = wide_out_rsp_i.b_valid;
  assign wide_data_arb_req_in[WideInW]          = (wide_aw_w_sel_q == SelW) &&
                                                  wide_in_req_i.w_valid;
  assign wide_data_arb_req_in[WideInR]          = wide_out_rsp_i.r_valid;

  assign narrow_aw_rob_ready_in             = narrow_req_data_arb_gnt_out[NarrowInAw] &&
                                              (narrow_aw_w_sel_q == SelAw);
  assign narrow_in_rsp_o.w_ready            = narrow_req_data_arb_gnt_out[NarrowInW] &&
                                              (narrow_aw_w_sel_q == SelW);
  assign narrow_ar_rob_ready_in             = narrow_req_data_arb_gnt_out[NarrowInAr];
  assign narrow_out_req_id_mapped.b_ready   = narrow_rsp_data_arb_gnt_out[NarrowInB];
  assign narrow_out_req_id_mapped.r_ready   = narrow_rsp_data_arb_gnt_out[NarrowInR];
  assign wide_aw_rob_ready_in               = narrow_req_data_arb_gnt_out[WideInAw] &&
                                              (wide_aw_w_sel_q == SelAw);
  assign wide_in_rsp_o.w_ready              = wide_data_arb_gnt_out[WideInW] &&
                                              (wide_aw_w_sel_q == SelW);
  assign wide_ar_rob_ready_in               = narrow_req_data_arb_gnt_out[WideInAr];
  assign wide_out_req_id_mapped.b_ready     = narrow_rsp_data_arb_gnt_out[WideInB];
  assign wide_out_req_id_mapped.r_ready     = wide_data_arb_gnt_out[WideInR];

  assign narrow_req_data_arb_data_in[NarrowInAw].narrow_in_aw  = narrow_aw_data;
  assign narrow_req_data_arb_data_in[NarrowInW].narrow_in_w    = narrow_w_data;
  assign narrow_req_data_arb_data_in[NarrowInAr].narrow_in_ar  = narrow_ar_data;
  assign narrow_req_data_arb_data_in[WideInAw].wide_in_aw      = wide_aw_data;
  assign narrow_req_data_arb_data_in[WideInAr].wide_in_ar      = wide_ar_data;
  assign narrow_rsp_data_arb_data_in[NarrowInB].narrow_in_b    = narrow_b_data;
  assign narrow_rsp_data_arb_data_in[NarrowInR].narrow_in_r    = narrow_r_data;
  assign narrow_rsp_data_arb_data_in[WideInB].wide_in_b        = wide_b_data;
  assign wide_data_arb_data_in[WideInW].wide_in_w              = wide_w_data;
  assign wide_data_arb_data_in[WideInR].wide_in_r              = wide_r_data;

  ///////////////////////
  // FLIT ARBITRATION  //
  ///////////////////////

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumVirtPerPhys[PhysNarrowReq] ),
    .flit_t     ( narrow_req_generic_t     )
  ) i_narrow_req_wormhole_arbiter (
    .clk_i    ( clk_i                       ),
    .rst_ni   ( rst_ni                      ),
    .valid_i  ( narrow_req_data_arb_req_in  ),
    .data_i   ( narrow_req_data_arb_data_in ),
    .ready_o  ( narrow_req_data_arb_gnt_out ),
    .data_o   ( narrow_req_o.data           ),
    .ready_i  ( narrow_req_i.ready          ),
    .valid_o  ( narrow_req_o.valid          )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumVirtPerPhys[PhysNarrowRsp] ),
    .flit_t     ( narrow_rsp_generic_t     )
  ) i_narrow_rsp_wormhole_arbiter (
    .clk_i    ( clk_i                       ),
    .rst_ni   ( rst_ni                      ),
    .valid_i  ( narrow_rsp_data_arb_req_in  ),
    .data_i   ( narrow_rsp_data_arb_data_in ),
    .ready_o  ( narrow_rsp_data_arb_gnt_out ),
    .data_o   ( narrow_rsp_o.data           ),
    .ready_i  ( narrow_rsp_i.ready          ),
    .valid_o  ( narrow_rsp_o.valid          )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumVirtPerPhys[PhysWide] ),
    .flit_t     ( wide_generic_t     )
  ) i_wide_wormhole_arbiter (
    .clk_i    ( clk_i                 ),
    .rst_ni   ( rst_ni                ),
    .valid_i  ( wide_data_arb_req_in  ),
    .data_i   ( wide_data_arb_data_in ),
    .ready_o  ( wide_data_arb_gnt_out ),
    .data_o   ( wide_o.data           ),
    .ready_i  ( wide_i.ready          ),
    .valid_o  ( wide_o.valid          )
  );

  ////////////////////
  // FLIT UNPACKER  //
  ////////////////////

  logic is_atop_b_rsp, is_atop_r_rsp;
  logic b_sel_atop, r_sel_atop;
  logic b_rob_pending_q, r_rob_pending_q;

  assign is_atop_b_rsp = AtopSupport && axi_valid_in[NarrowInB] && narrow_unpack_rsp_generic.atop;
  assign is_atop_r_rsp = AtopSupport && axi_valid_in[NarrowInR] && narrow_unpack_rsp_generic.atop;
  assign b_sel_atop = is_atop_b_rsp && !b_rob_pending_q;
  assign r_sel_atop = is_atop_r_rsp && !r_rob_pending_q;

  assign narrow_unpack_aw_data = narrow_req_in.data.narrow_in_aw.aw;
  assign narrow_unpack_w_data  = narrow_req_in.data.narrow_in_w.w;
  assign narrow_unpack_ar_data = narrow_req_in.data.narrow_in_ar.ar;
  assign narrow_unpack_r_data  = narrow_rsp_in.data.narrow_in_r.r;
  assign narrow_unpack_b_data  = narrow_rsp_in.data.narrow_in_b.b;
  assign wide_unpack_aw_data   = narrow_req_in.data.wide_in_aw.aw;
  assign wide_unpack_w_data    = wide_in.data.wide_in_w.w;
  assign wide_unpack_ar_data   = narrow_req_in.data.wide_in_ar.ar;
  assign wide_unpack_r_data    = wide_in.data.wide_in_r.r;
  assign wide_unpack_b_data    = narrow_rsp_in.data.wide_in_b.b;
  assign narrow_unpack_req_generic  = narrow_req_in.data.gen;
  assign narrow_unpack_rsp_generic  = narrow_rsp_in.data.gen;
  assign wide_unpack_generic  = wide_in.data.gen;


  assign axi_valid_in[NarrowInAw] = narrow_req_in.valid &&
                                  (narrow_unpack_req_generic.axi_ch == NarrowInAw);
  assign axi_valid_in[NarrowInW]  = narrow_req_in.valid &&
                                  (narrow_unpack_req_generic.axi_ch  == NarrowInW);
  assign axi_valid_in[NarrowInAr] = narrow_req_in.valid &&
                                  (narrow_unpack_req_generic.axi_ch == NarrowInAr);
  assign axi_valid_in[WideInAw]   = narrow_req_in.valid &&
                                  (narrow_unpack_req_generic.axi_ch == WideInAw);
  assign axi_valid_in[WideInAr]   = narrow_req_in.valid &&
                                  (narrow_unpack_req_generic.axi_ch == WideInAr);
  assign axi_valid_in[NarrowInB]  = narrow_rsp_in.valid &&
                                  (narrow_unpack_rsp_generic.axi_ch  == NarrowInB);
  assign axi_valid_in[NarrowInR]  = narrow_rsp_in.valid &&
                                  (narrow_unpack_rsp_generic.axi_ch  == NarrowInR);
  assign axi_valid_in[WideInB]    = narrow_rsp_in.valid &&
                                  (narrow_unpack_rsp_generic.axi_ch  == WideInB);
  assign axi_valid_in[WideInW]    = wide_in.valid &&
                                  (wide_unpack_generic.axi_ch  == WideInW);
  assign axi_valid_in[WideInR]    = wide_in.valid &&
                                  (wide_unpack_generic.axi_ch  == WideInR);

  assign axi_ready_out[NarrowInAw]  = narrow_out_rsp_i.aw_ready && !narrow_aw_out_full;
  assign axi_ready_out[NarrowInW]   = narrow_out_rsp_i.w_ready;
  assign axi_ready_out[NarrowInAr]  = narrow_out_rsp_i.ar_ready && !narrow_ar_out_full;
  assign axi_ready_out[NarrowInB]   = narrow_b_rob_ready_out ||
                                      b_sel_atop && narrow_in_req_i.b_ready;
  assign axi_ready_out[NarrowInR]   = narrow_r_rob_ready_out ||
                                      r_sel_atop && narrow_in_req_i.r_ready;
  assign axi_ready_out[WideInAw]    = wide_out_rsp_i.aw_ready && !wide_aw_out_full;
  assign axi_ready_out[WideInW]     = wide_out_rsp_i.w_ready;
  assign axi_ready_out[WideInAr]    = wide_out_rsp_i.ar_ready&& !wide_ar_out_full;
  assign axi_ready_out[WideInB]     = wide_b_rob_ready_out;
  assign axi_ready_out[WideInR]     = wide_r_rob_ready_out;

  assign narrow_req_ready_out = axi_ready_out[narrow_unpack_req_generic.axi_ch];
  assign narrow_rsp_ready_out = axi_ready_out[narrow_unpack_rsp_generic.axi_ch];
  assign wide_ready_out = axi_ready_out[wide_unpack_generic.axi_ch];

  /////////////////////////////
  // AXI req/rsp generation  //
  ////////////////////////////

  assign narrow_out_req_id_mapped.aw_valid  = axi_valid_in[NarrowInAw] && !narrow_aw_out_full;
  assign narrow_out_req_id_mapped.w_valid   = axi_valid_in[NarrowInW];
  assign narrow_out_req_id_mapped.ar_valid  = axi_valid_in[NarrowInAr] && !narrow_ar_out_full;
  assign narrow_b_rob_valid_in              = axi_valid_in[NarrowInB] && !is_atop_b_rsp;
  assign narrow_r_rob_valid_in              = axi_valid_in[NarrowInR] && !is_atop_r_rsp;
  assign narrow_in_rsp_o.b_valid            = narrow_b_rob_valid_out || is_atop_b_rsp;
  assign narrow_in_rsp_o.r_valid            = narrow_r_rob_valid_out || is_atop_r_rsp;
  assign narrow_b_rob_ready_in              = narrow_in_req_i.b_ready && !b_sel_atop;
  assign narrow_r_rob_ready_in              = narrow_in_req_i.r_ready && !r_sel_atop;
  assign wide_out_req_id_mapped.aw_valid    = axi_valid_in[WideInAw] && !wide_aw_out_full;
  assign wide_out_req_id_mapped.w_valid     = axi_valid_in[WideInW];
  assign wide_out_req_id_mapped.ar_valid    = axi_valid_in[WideInAr] && !wide_ar_out_full;
  assign wide_b_rob_valid_in                = axi_valid_in[WideInB];
  assign wide_r_rob_valid_in                = axi_valid_in[WideInR];
  assign wide_in_rsp_o.b_valid              = wide_b_rob_valid_out;
  assign wide_in_rsp_o.r_valid              = wide_r_rob_valid_out;
  assign wide_b_rob_ready_in                = wide_in_req_i.b_ready;
  assign wide_r_rob_ready_in                = wide_in_req_i.r_ready;

  assign narrow_out_req_id_mapped.aw  = narrow_aw_id_mod;
  assign narrow_out_req_id_mapped.w   = narrow_unpack_w_data;
  assign narrow_out_req_id_mapped.ar  = narrow_ar_id_mod;
  assign narrow_b_rob_in              = narrow_unpack_b_data;
  assign narrow_r_rob_in              = narrow_unpack_r_data;
  assign narrow_in_rsp_o.b            = (b_sel_atop)? narrow_unpack_b_data : narrow_b_rob_out;
  assign narrow_in_rsp_o.r            = (r_sel_atop)? narrow_unpack_r_data : narrow_r_rob_out;
  assign wide_out_req_id_mapped.aw    = wide_aw_id_mod;
  assign wide_out_req_id_mapped.w     = wide_unpack_w_data;
  assign wide_out_req_id_mapped.ar    = wide_ar_id_mod;
  assign wide_b_rob_in                = wide_unpack_b_data;
  assign wide_r_rob_in                = wide_unpack_r_data;
  assign wide_in_rsp_o.b              = wide_b_rob_out;
  assign wide_in_rsp_o.r              = wide_r_rob_out;

  logic is_atop, atop_has_r_rsp;
  assign is_atop = AtopSupport && axi_valid_in[NarrowInAw] &&
                   (narrow_unpack_aw_data.atop != axi_pkg::ATOP_NONE);
  assign atop_has_r_rsp = AtopSupport && axi_valid_in[NarrowInAw] &&
                          narrow_unpack_aw_data.atop[axi_pkg::ATOP_R_RESP];

  assign narrow_aw_out_push = narrow_out_req_o.aw_valid && narrow_out_rsp_i.aw_ready;
  assign narrow_ar_out_push = narrow_out_req_o.ar_valid && narrow_out_rsp_i.ar_ready ||
                              narrow_out_req_o.aw_valid && narrow_out_rsp_i.aw_ready &&
                              is_atop && atop_has_r_rsp;
  assign narrow_aw_out_pop  = narrow_out_rsp_i.b_valid && narrow_out_req_o.b_ready;
  assign narrow_ar_out_pop  = narrow_out_rsp_i.r_valid && narrow_out_req_o.r_ready &
                              narrow_out_rsp_i.r.last;

  assign wide_aw_out_push   = wide_out_req_o.aw_valid && wide_out_rsp_i.aw_ready;
  assign wide_ar_out_push   = wide_out_req_o.ar_valid && wide_out_rsp_i.ar_ready;
  assign wide_aw_out_pop    = wide_out_rsp_i.b_valid && wide_out_req_o.b_ready;
  assign wide_ar_out_pop    = wide_out_rsp_i.r_valid && wide_out_req_o.r_ready &&
                              wide_out_rsp_i.r.last;


  assign narrow_aw_out_data_in = '{
    id: narrow_unpack_aw_data.id,
    rob_req: narrow_unpack_req_generic.rob_req,
    rob_idx: narrow_unpack_req_generic.rob_idx,
    src_id: narrow_unpack_req_generic.src_id,
    atop: narrow_unpack_req_generic.atop
  };
  assign narrow_ar_out_data_in = '{
    id: narrow_unpack_ar_data.id,
    rob_req: narrow_unpack_req_generic.rob_req,
    rob_idx: narrow_unpack_req_generic.rob_idx,
    src_id: narrow_unpack_req_generic.src_id,
    atop: narrow_unpack_req_generic.atop
  };
  assign wide_aw_out_data_in = '{
    id: wide_unpack_aw_data.id,
    rob_req: narrow_unpack_req_generic.rob_req,
    rob_idx: narrow_unpack_req_generic.rob_idx,
    src_id: narrow_unpack_req_generic.src_id
  };
  assign wide_ar_out_data_in = '{
    id: wide_unpack_ar_data.id,
    rob_req: narrow_unpack_req_generic.rob_req,
    rob_idx: narrow_unpack_req_generic.rob_idx,
    src_id: narrow_unpack_req_generic.src_id
  };

  floo_meta_buffer #(
    .MaxTxns        ( NarrowMaxTxns       ),
    .AtopSupport    ( AtopSupport         ),
    .MaxAtomicTxns  ( MaxAtomicTxns       ),
    .buf_t          ( narrow_id_out_buf_t ),
    .id_t           ( narrow_out_id_t     )
  ) i_narrow_aw_meta_buffer (
    .clk_i          ( clk_i                     ),
    .rst_ni         ( rst_ni                    ),
    .test_enable_i  ( test_enable_i             ),
    .req_push_i     ( narrow_aw_out_push        ),
    .req_valid_i    ( narrow_out_req_o.aw_valid ),
    .req_buf_i      ( narrow_aw_out_data_in     ),
    .req_is_atop_i  ( is_atop                   ),
    .req_atop_id_i  ( '0                        ),
    .req_full_o     ( narrow_aw_out_full        ),
    .req_id_o       ( narrow_aw_out_id          ),
    .rsp_pop_i      ( narrow_aw_out_pop         ),
    .rsp_id_i       ( narrow_out_rsp_i.b.id     ),
    .rsp_buf_o      ( narrow_aw_out_data_out    )
  );


  floo_meta_buffer #(
    .MaxTxns        ( NarrowMaxTxns       ),
    .AtopSupport    ( AtopSupport         ),
    .MaxAtomicTxns  ( MaxAtomicTxns       ),
    .ExtAtomicId    ( 1'b1                ), // Use ID from AW channel
    .buf_t          ( narrow_id_out_buf_t ),
    .id_t           ( narrow_out_id_t     )
  ) i_narrow_ar_meta_buffer (
    .clk_i          ( clk_i                     ),
    .rst_ni         ( rst_ni                    ),
    .test_enable_i  ( test_enable_i             ),
    .req_push_i     ( narrow_ar_out_push        ),
    .req_valid_i    ( narrow_out_req_o.ar_valid ),
    .req_buf_i      ( narrow_ar_out_data_in     ),
    .req_is_atop_i  ( is_atop                   ),
    .req_atop_id_i  ( narrow_aw_out_id          ), // Use ID from AW channel
    .req_full_o     ( narrow_ar_out_full        ),
    .req_id_o       ( narrow_ar_out_id          ),
    .rsp_pop_i      ( narrow_ar_out_pop         ),
    .rsp_id_i       ( narrow_out_rsp_i.r.id     ),
    .rsp_buf_o      ( narrow_ar_out_data_out    )
  );

  floo_meta_buffer #(
    .MaxTxns        ( NarrowMaxTxns     ),
    .AtopSupport    ( 1'b0              ),
    .buf_t          ( wide_id_out_buf_t ),
    .id_t           ( wide_out_id_t     )
  ) i_wide_aw_meta_buffer (
    .clk_i          ( clk_i                   ),
    .rst_ni         ( rst_ni                  ),
    .test_enable_i  ( test_enable_i           ),
    .req_push_i     ( wide_aw_out_push        ),
    .req_valid_i    ( wide_out_req_o.aw_valid ),
    .req_buf_i      ( wide_aw_out_data_in     ),
    .req_is_atop_i  ( 1'b0                    ),
    .req_atop_id_i  ( '0                      ),
    .req_full_o     ( wide_aw_out_full        ),
    .req_id_o       ( wide_aw_out_id          ),
    .rsp_pop_i      ( wide_aw_out_pop         ),
    .rsp_id_i       ( wide_out_rsp_i.b.id     ),
    .rsp_buf_o      ( wide_aw_out_data_out    )
  );

  floo_meta_buffer #(
    .MaxTxns        ( NarrowMaxTxns     ),
    .AtopSupport    ( 1'b0              ),
    .buf_t          ( wide_id_out_buf_t ),
    .id_t           ( wide_out_id_t     )
  ) i_wide_ar_meta_buffer (
    .clk_i          ( clk_i                   ),
    .rst_ni         ( rst_ni                  ),
    .test_enable_i  ( test_enable_i           ),
    .req_push_i     ( wide_ar_out_push        ),
    .req_valid_i    ( wide_out_req_o.ar_valid ),
    .req_buf_i      ( wide_ar_out_data_in     ),
    .req_is_atop_i  ( 1'b0                    ),
    .req_atop_id_i  ( '0                      ),
    .req_full_o     ( wide_ar_out_full        ),
    .req_id_o       ( wide_ar_out_id          ),
    .rsp_pop_i      ( wide_ar_out_pop         ),
    .rsp_id_i       ( wide_out_rsp_i.r.id     ),
    .rsp_buf_o      ( wide_ar_out_data_out    )
  );

  always_comb begin
    // Assign the outgoing AX an unique ID
    narrow_aw_id_mod    = narrow_unpack_aw_data;
    narrow_ar_id_mod    = narrow_unpack_ar_data;
    wide_aw_id_mod      = wide_unpack_aw_data;
    wide_ar_id_mod      = wide_unpack_ar_data;
    narrow_aw_id_mod.id = narrow_aw_out_id;
    narrow_ar_id_mod.id = narrow_ar_out_id;
    wide_aw_id_mod.id   = wide_aw_out_id;
    wide_ar_id_mod.id   = wide_ar_out_id;
  end

  // Registers
  `FF(b_rob_pending_q, narrow_b_rob_valid_out && !narrow_b_rob_ready_in && !is_atop_b_rsp, '0)
  `FF(r_rob_pending_q, narrow_r_rob_valid_out && !narrow_r_rob_ready_in && !is_atop_r_rsp, '0)


  /////////////////
  // ASSERTIONS  //
  /////////////////

  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(ToSmallIdWidth, 1 + AtopSupport * MaxAtomicTxns <= 2**NarrowOutIdWidth)

  // Data and valid signals must be stable/asserted when ready is low
  // `ASSERT(NarrowReqOutStableData, narrow_req_o.valid && !narrow_req_i.ready
  //                                 |=> $stable(narrow_req_o.data))
  // `ASSERT(NarrowReqInStableData, narrow_req_i.valid && !narrow_req_o.ready
  //                                 |=> $stable(narrow_req_i.data))
  // `ASSERT(NarrowRspOutStableData, narrow_rsp_o.valid && !narrow_rsp_i.ready
  //                                 |=> $stable(narrow_rsp_o.data))
  // `ASSERT(NarrowRspInStableData, narrow_rsp_i.valid && !narrow_rsp_o.ready
  //                                 |=> $stable(narrow_rsp_i.data))
  // `ASSERT(WideOutStableData, wide_o.valid && !wide_i.ready |=> $stable(wide_o.data))
  // `ASSERT(WideInStableData, wide_i.valid && !wide_o.ready |=> $stable(wide_i.data))
  `ASSERT(NarrowReqOutStableValid, narrow_req_o.valid && !narrow_req_i.ready |=> narrow_req_o.valid)
  `ASSERT(NarrowReqInStableValid, narrow_req_i.valid && !narrow_req_o.ready |=> narrow_req_i.valid)
  `ASSERT(NarrowRspOutStableValid, narrow_rsp_o.valid && !narrow_rsp_i.ready |=> narrow_rsp_o.valid)
  `ASSERT(NarrowRspInStableValid, narrow_rsp_i.valid && !narrow_rsp_o.ready |=> narrow_rsp_i.valid)
  `ASSERT(WideOutStableValid, wide_o.valid && !wide_i.ready |=> wide_o.valid)
  `ASSERT(WideInStableValid, wide_i.valid && !wide_o.ready |=> wide_i.valid)
endmodule
