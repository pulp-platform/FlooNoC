// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

/// A bidirectional network interface for connecting AXI4 Buses to the NoC
module floo_axi_chimney #(
  /// Config of the AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfg = '0,
  /// Config of the data path in the chimney (see floo_pkg::chimney_cfg_t for details)
  parameter floo_pkg::chimney_cfg_t ChimneyCfg = floo_pkg::ChimneyDefaultCfg,
  /// Config for routing information (see floo_pkg::route_cfg_t for details)
  parameter floo_pkg::route_cfg_t RouteCfg  = floo_pkg::RouteDefaultCfg,
  /// Atomic operation support
  parameter bit AtopSupport                 = 1'b1,
  /// Maximum number of oustanding Atomic transactions,
  /// must be smaller or equal to 2**AxiOutIdWidth-1 since
  /// Every atomic transactions needs to have a unique ID
  /// and one ID is reserved for non-atomic transactions
  parameter int unsigned MaxAtomicTxns      = 1,
  /// Node ID type for routing
  parameter type id_t                                   = logic,
  /// RoB index type for reordering.
  // (can be ignored if `RoBType == NoRoB`)
  parameter type rob_idx_t                              = logic,
  /// Route type for source-based routing
  /// (only used if `RouteCfg.RouteAlgo == SourceRouting`)
  parameter type route_t                                = logic,
  /// Destination ID type for routing
  /// The destination ID type is usually the same as the node ID type,
  /// except for the case of source-based routing, where the destination
  /// ID is the actual route to the destination i.e. `route_t`
  parameter type dst_t                                  = id_t,
  /// Header type for the flits
  parameter type hdr_t                                  = logic,
  /// Rule type for the System Address Map
  /// (only used if `RouteCfg.UseIdTable == 1'b1`)
  parameter type sam_rule_t                             = logic,
  /// The System Address Map (SAM) rules
  /// (only used if `RouteCfg.UseIdTable == 1'b1`)
  parameter sam_rule_t [RouteCfg.NumSamRules-1:0] Sam   = '0,
  /// AXI manager request channel type
  parameter type axi_in_req_t               = logic,
  /// AXI manager response channel type
  parameter type axi_in_rsp_t               = logic,
  /// AXI subordinate request channel type
  parameter type axi_out_req_t              = logic,
  // AXI subordinate response channel type
  parameter type axi_out_rsp_t              = logic,
  /// Floo `req` link type
  parameter type floo_req_t                 = logic,
  /// Floo `rsp` link type
  parameter type floo_rsp_t                 = logic,
  /// SRAM configuration type
  parameter type sram_cfg_t                 = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  /// SRAM configuration
  input  sram_cfg_t  sram_cfg_i,
  /// AXI4 side interfaces
  input  axi_in_req_t axi_in_req_i,
  output axi_in_rsp_t axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input  axi_out_rsp_t axi_out_rsp_i,
  /// Coordinates/ID of the current tile
  input  id_t id_i,
  /// Routing table for the current tile
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,
  /// Output links to NoC
  output floo_req_t floo_req_o,
  output floo_rsp_t floo_rsp_o,
  /// Input links from NoC
  input  floo_req_t floo_req_i,
  input  floo_rsp_t floo_rsp_i
);

  import floo_pkg::*;

  typedef logic [AxiCfg.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfg.InIdWidth-1:0] axi_in_id_t;
  typedef logic [AxiCfg.OutIdWidth-1:0] axi_out_id_t;
  typedef logic [AxiCfg.UserWidth-1:0] axi_user_t;
  typedef logic [AxiCfg.DataWidth-1:0] axi_data_t;
  typedef logic [AxiCfg.DataWidth/8-1:0] axi_strb_t;

  // (Re-) definitons of `axi_in` and `floo` types, for transport
  `AXI_TYPEDEF_ALL_CT(axi, axi_req_t, axi_rsp_t, axi_addr_t, axi_in_id_t,
                      axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_AW_CHAN_T(axi_out_aw_chan_t, axi_addr_t, axi_out_id_t, axi_user_t)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi, AxiCfg, hdr_t)

  // Duplicate AXI port signals to degenerate ports
  // in case they are not used
  axi_req_t axi_req_in;
  axi_rsp_t axi_rsp_out;

  // AX queue
  axi_aw_chan_t axi_aw_queue;
  axi_ar_chan_t axi_ar_queue;
  logic axi_aw_queue_valid_out, axi_aw_queue_ready_in;
  logic axi_ar_queue_valid_out, axi_ar_queue_ready_in;

  // AXI req/rsp arbiter
  floo_req_chan_t [AxiW:AxiAr] floo_req_arb_in;
  floo_rsp_chan_t [AxiB:AxiR] floo_rsp_arb_in;
  logic  [AxiW:AxiAr] floo_req_arb_req_in, floo_req_arb_gnt_out;
  logic  [AxiB:AxiR] floo_rsp_arb_req_in, floo_rsp_arb_gnt_out;

  // flit queue
  floo_req_chan_t floo_req_in;
  floo_rsp_chan_t floo_rsp_in;
  logic floo_req_in_valid, floo_rsp_in_valid;
  logic floo_req_out_ready, floo_rsp_out_ready;
  logic [NumAxiChannels-1:0] axi_valid_in, axi_ready_out;

  // Flit packing
  floo_axi_aw_flit_t  floo_axi_aw;
  floo_axi_w_flit_t   floo_axi_w;
  floo_axi_ar_flit_t  floo_axi_ar;
  floo_axi_b_flit_t   floo_axi_b;
  floo_axi_r_flit_t   floo_axi_r;

  // Flit unpacking
  axi_aw_chan_t axi_unpack_aw;
  axi_ar_chan_t axi_unpack_ar;
  axi_w_chan_t  axi_unpack_w;
  axi_b_chan_t  axi_unpack_b;
  axi_r_chan_t  axi_unpack_r;
  floo_req_generic_flit_t unpack_req_generic;
  floo_rsp_generic_flit_t unpack_rsp_generic;

  // Meta Buffer
  axi_req_t meta_buf_req_in;
  axi_rsp_t meta_buf_rsp_out;
  axi_out_req_t meta_buf_req_out;
  axi_out_rsp_t meta_buf_rsp_in;

  // Flit arbitration
  typedef enum logic {SelAw, SelW} aw_w_sel_e;
  aw_w_sel_e aw_w_sel_q, aw_w_sel_d;

  // ID tracking
  typedef struct packed {
    axi_in_id_t  id;
    hdr_t        hdr;
  } meta_buf_t;

  // Routing
  dst_t [NumAxiChannels-1:0] dst_id;
  dst_t axi_aw_id_q;
  id_t  [NumAxiChannels-1:0] mask;
  id_t  axi_aw_mask_q;

  route_t [NumAxiChannels-1:0] route_out;
  id_t [NumAxiChannels-1:0] id_out;
  id_t [NumAxiChannels-1:0] mask_out; // TODO is type correct?

  meta_buf_t aw_out_hdr_in, aw_out_hdr_out;
  meta_buf_t ar_out_hdr_in, ar_out_hdr_out;

  ///////////////////////
  //  Spill registers  //
  ///////////////////////

  if (ChimneyCfg.EnMgrPort) begin : gen_sbr_port

    assign axi_req_in = axi_in_req_i;
    assign axi_in_rsp_o = axi_rsp_out;

    if (ChimneyCfg.CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_aw_chan_t )
      ) i_aw_queue (
        .clk_i,
        .rst_ni,
        .data_i     ( axi_in_req_i.aw         ),
        .valid_i    ( axi_in_req_i.aw_valid   ),
        .ready_o    ( axi_rsp_out.aw_ready    ),
        .data_o     ( axi_aw_queue            ),
        .valid_o    ( axi_aw_queue_valid_out  ),
        .ready_i    ( axi_aw_queue_ready_in   )
      );

      spill_register #(
        .T ( axi_ar_chan_t )
      ) i_ar_queue (
        .clk_i,
        .rst_ni,
        .data_i     ( axi_in_req_i.ar         ),
        .valid_i    ( axi_in_req_i.ar_valid   ),
        .ready_o    ( axi_rsp_out.ar_ready    ),
        .data_o     ( axi_ar_queue            ),
        .valid_o    ( axi_ar_queue_valid_out  ),
        .ready_i    ( axi_ar_queue_ready_in   )
      );
    end else begin : gen_no_ax_cuts
      assign axi_aw_queue = axi_in_req_i.aw;
      assign axi_aw_queue_valid_out = axi_in_req_i.aw_valid;
      assign axi_rsp_out.aw_ready = axi_aw_queue_ready_in;

      assign axi_ar_queue = axi_in_req_i.ar;
      assign axi_ar_queue_valid_out = axi_in_req_i.ar_valid;
      assign axi_rsp_out.ar_ready = axi_ar_queue_ready_in;
    end

  end else begin : gen_err_slv_port
    axi_err_slv #(
      .AxiIdWidth ( AxiCfg.InIdWidth  ),
      .ATOPs      ( AtopSupport       ),
      .axi_req_t  ( axi_in_req_t      ),
      .axi_resp_t ( axi_in_rsp_t      )
    ) i_axi_err_slv (
      .clk_i      ( clk_i         ),
      .rst_ni     ( rst_ni        ),
      .test_i     ( test_enable_i ),
      .slv_req_i  ( axi_in_req_i  ),
      .slv_resp_o ( axi_in_rsp_o  )
    );
    assign axi_req_in = '0;
    assign axi_aw_queue = '0;
    assign axi_ar_queue = '0;
    assign axi_aw_queue_valid_out = 1'b0;
    assign axi_ar_queue_valid_out = 1'b0;
  end

  if (ChimneyCfg.CutRsp) begin : gen_rsp_cuts
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


  logic aw_out_queue_valid, aw_out_queue_ready;
  axi_out_aw_chan_t axi_aw_queue_out;

  // Since AW and W are transferred over the same link, it can happen that
  // a downstream module does not accept the AW until the W is valid.
  // Therefore, we need to add a spill register for the AW channel.
  spill_register #(
    .T (axi_out_aw_chan_t)
  ) i_aw_out_queue (
    .clk_i    ( clk_i                     ),
    .rst_ni   ( rst_ni                    ),
    .valid_i  ( meta_buf_req_out.aw_valid ),
    .ready_o  ( aw_out_queue_ready        ),
    .data_i   ( meta_buf_req_out.aw       ),
    .valid_o  ( aw_out_queue_valid        ),
    .ready_i  ( axi_out_rsp_i.aw_ready    ),
    .data_o   ( axi_aw_queue_out          )
  );

  always_comb begin
    axi_out_req_o = meta_buf_req_out;
    axi_out_req_o.aw_valid = aw_out_queue_valid;
    axi_out_req_o.aw = axi_aw_queue_out;
    meta_buf_rsp_in = axi_out_rsp_i;
    meta_buf_rsp_in.aw_ready = aw_out_queue_ready;
  end

  ///////////////////////
  //  Reorder Buffers  //
  ///////////////////////

  // AW/B RoB
  axi_b_chan_t axi_b_rob_out, axi_b_rob_in;
  logic aw_rob_req_out;
  rob_idx_t aw_rob_idx_out;
  logic aw_rob_valid_in, aw_rob_ready_out;
  logic aw_rob_valid_out, aw_rob_ready_in;
  logic b_rob_valid_in, b_rob_ready_out;
  logic b_rob_valid_out, b_rob_ready_in;

  // AR/R RoB
  axi_r_chan_t axi_r_rob_out, axi_r_rob_in;
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
    .RoBType        ( ChimneyCfg.BRoBType     ),
    .RoBSize        ( ChimneyCfg.BRoBSize     ),
    .MaxRoTxnsPerId ( ChimneyCfg.MaxTxnsPerId ),
    .OnlyMetaData   ( 1'b1                    ),
    .ax_len_t       ( axi_pkg::len_t          ),
    .ax_id_t        ( axi_in_id_t             ),
    .rsp_chan_t     ( axi_b_chan_t            ),
    .rsp_meta_t     ( axi_b_chan_t            ),
    .rob_idx_t      ( rob_idx_t               ),
    .dest_t         ( id_t                    ),
    .sram_cfg_t     ( sram_cfg_t              )
  ) i_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( aw_rob_valid_in               ),
    .ax_ready_o     ( aw_rob_ready_out              ),
    .ax_len_i       ( axi_aw_queue.len              ),
    .ax_id_i        ( axi_aw_queue.id               ),
    .ax_dest_i      ( id_out[AxiAw]                 ),
    .ax_valid_o     ( aw_rob_valid_out              ),
    .ax_ready_i     ( aw_rob_ready_in               ),
    .ax_rob_req_o   ( aw_rob_req_out                ),
    .ax_rob_idx_o   ( aw_rob_idx_out                ),
    .rsp_valid_i    ( b_rob_valid_in                ),
    .rsp_ready_o    ( b_rob_ready_out               ),
    .rsp_i          ( axi_b_rob_in                  ),
    .rsp_rob_req_i  ( floo_rsp_in.axi_b.hdr.rob_req ),
    .rsp_rob_idx_i  ( floo_rsp_in.axi_b.hdr.rob_idx ),
    .rsp_last_i     ( 1'b1                          ),
    .rsp_valid_o    ( b_rob_valid_out               ),
    .rsp_ready_i    ( b_rob_ready_in                ),
    .rsp_o          ( axi_b_rob_out                 )
  );

  typedef struct packed {
    axi_in_id_t     id;
    axi_user_t      user;
    axi_pkg::resp_t resp;
    logic           last;
  } r_rob_meta_t;


  floo_rob_wrapper #(
    .RoBType        ( ChimneyCfg.RRoBType     ),
    .RoBSize        ( ChimneyCfg.RRoBSize     ),
    .MaxRoTxnsPerId ( ChimneyCfg.MaxTxnsPerId ),
    .OnlyMetaData   ( 1'b0                    ),
    .ax_len_t       ( axi_pkg::len_t          ),
    .ax_id_t        ( axi_in_id_t             ),
    .rsp_chan_t     ( axi_r_chan_t            ),
    .rsp_data_t     ( axi_data_t              ),
    .rsp_meta_t     ( r_rob_meta_t            ),
    .rob_idx_t      ( rob_idx_t               ),
    .dest_t         ( id_t                    ),
    .sram_cfg_t     ( sram_cfg_t              )
  ) i_r_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( axi_ar_queue_valid_out          ),
    .ax_ready_o     ( axi_ar_queue_ready_in           ),
    .ax_len_i       ( axi_ar_queue.len                ),
    .ax_id_i        ( axi_ar_queue.id                 ),
    .ax_dest_i      ( id_out[AxiAr]                   ),
    .ax_valid_o     ( ar_rob_valid_out                ),
    .ax_ready_i     ( ar_rob_ready_in                 ),
    .ax_rob_req_o   ( ar_rob_req_out                  ),
    .ax_rob_idx_o   ( ar_rob_idx_out                  ),
    .rsp_valid_i    ( r_rob_valid_in                  ),
    .rsp_ready_o    ( r_rob_ready_out                 ),
    .rsp_i          ( axi_r_rob_in                    ),
    .rsp_rob_req_i  ( floo_rsp_in.axi_r.hdr.rob_req   ),
    .rsp_rob_idx_i  ( floo_rsp_in.axi_r.hdr.rob_idx   ),
    .rsp_last_i     ( floo_rsp_in.axi_r.payload.last  ),
    .rsp_valid_o    ( r_rob_valid_out                 ),
    .rsp_ready_i    ( r_rob_ready_in                  ),
    .rsp_o          ( axi_r_rob_out                   )
  );

  /////////////////
  //   ROUTING   //
  /////////////////

  axi_addr_t [NumAxiChannels-1:0] axi_req_addr;
  axi_addr_t [NumAxiChannels-1:0] axi_req_mask; // TODO is type correct?
  id_t [NumAxiChannels-1:0] axi_rsp_src_id;

  assign axi_req_addr[AxiAw] = axi_aw_queue.addr;
  assign axi_req_addr[AxiAr] = axi_ar_queue.addr;
  assign axi_req_mask[AxiAw] = axi_aw_queue.user;
  assign axi_req_mask[AxiAr] = axi_ar_queue.user;

  assign axi_rsp_src_id[AxiB] = aw_out_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[AxiR] = ar_out_hdr_out.hdr.src_id;

  for (genvar ch = 0; ch < NumAxiChannels; ch++) begin : gen_route_comp
    localparam axi_ch_e Ch = axi_ch_e'(ch);
    if (Ch == AxiAw || Ch == AxiAr) begin : gen_req_route_comp
      // Translate the address from AXI requests to a destination ID
      // (or route if `SourceRouting` is used)
      floo_route_comp #(
        .RouteCfg     ( RouteCfg    ),
        .id_t         ( id_t        ),
        .addr_t       ( axi_addr_t  ),
        .addr_rule_t  ( sam_rule_t  ),
        .route_t      ( route_t     )
      ) i_floo_req_route_comp (
        .clk_i,
        .rst_ni,
        .route_table_i,
        .addr_map_i ( Sam               ),
        .id_i       ( id_t'('0)         ),
        .addr_i     ( axi_req_addr[ch]  ),
        .mask_i     ( axi_req_mask[ch]  ),
        .route_o    ( route_out[ch]     ),
        .id_o       ( id_out[ch]        ),
        .mask_o     ( mask_out[ch]      )
      );
    end else if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting &&
                 (Ch == AxiB || Ch == AxiR)) begin : gen_rsp_route_comp
      // Generally, the source ID from the request is used to route back
      // the responses. However, in the case of `SourceRouting`, the source ID
      // first needs to be translated into a route.
      floo_route_comp #(
        .RouteCfg     ( RouteCfg    ),
        .UseIdTable   ( 1'b0        ), // Overwrite `RouteCfg`
        .id_t         ( id_t        ),
        .addr_t       ( axi_addr_t  ),
        .addr_rule_t  ( sam_rule_t  ),
        .route_t      ( route_t     )
      ) i_floo_rsp_route_comp (
        .clk_i,
        .rst_ni,
        .route_table_i,
        .addr_i     ( '0                  ),
        .mask_i     ( '0                  ),
        .addr_map_i ( '0                  ),
        .id_i       ( axi_rsp_src_id[ch]  ),
        .route_o    ( route_out[ch]       ),
        .id_o       ( id_out[ch]          ),
        .mask_o     (                     )
      );
    end
  end

  if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting) begin : gen_route_field
    assign route_out[AxiW] = axi_aw_id_q;
    assign dst_id = route_out;
    assign  mask = '0;
  end else begin : gen_dst_field
    assign dst_id[AxiAw] = id_out[AxiAw];
    assign dst_id[AxiAr] = id_out[AxiAr];
    assign dst_id[AxiB]  = aw_out_hdr_out.hdr.src_id;
    assign dst_id[AxiR]  = ar_out_hdr_out.hdr.src_id;
    assign dst_id[AxiW]  = axi_aw_id_q;

    assign mask[AxiAw] = mask_out[AxiAw];
    assign mask[AxiAr] = mask_out[AxiAr];
    assign mask[AxiB]  = '0;
    assign mask[AxiR]  = '0;
    assign mask[AxiW]  = axi_aw_mask_q;
  end

  `FFL(axi_aw_id_q, dst_id[AxiAw], axi_aw_queue_valid_out &&
                                   axi_aw_queue_ready_in, '0)
  `FFL(axi_aw_mask_q, mask[AxiAw], axi_aw_queue_valid_out &&
                                   axi_aw_queue_ready_in, '0)

  ///////////////////
  // FLIT PACKING  //
  ///////////////////

  always_comb begin
    floo_axi_aw             = '0;
    floo_axi_aw.hdr.rob_req = aw_rob_req_out;
    floo_axi_aw.hdr.rob_idx = aw_rob_idx_out;
    floo_axi_aw.hdr.dst_id  = dst_id[AxiAw];
    floo_axi_aw.hdr.mask    = mask[AxiAw];
    floo_axi_aw.hdr.src_id  = id_i;
    floo_axi_aw.hdr.last    = 1'b0;
    floo_axi_aw.hdr.axi_ch  = AxiAw;
    floo_axi_aw.hdr.atop    = axi_aw_queue.atop != axi_pkg::ATOP_NONE;
    floo_axi_aw.payload     = axi_aw_queue;
    floo_axi_aw.hdr.commtype = mask[AxiAw]!='0? Multicast : Unicast;
  end

  always_comb begin
    floo_axi_w              = '0;
    floo_axi_w.hdr.rob_req  = aw_rob_req_out;
    floo_axi_w.hdr.rob_idx  = aw_rob_idx_out;
    floo_axi_w.hdr.dst_id   = dst_id[AxiW];
    floo_axi_w.hdr.mask     = mask[AxiW];
    floo_axi_w.hdr.src_id   = id_i;
    floo_axi_w.hdr.last     = axi_req_in.w.last;
    floo_axi_w.hdr.axi_ch   = AxiW;
    floo_axi_w.payload      = axi_req_in.w;
    floo_axi_w.hdr.commtype = mask[AxiW]!='0? Multicast : Unicast;
  end

  always_comb begin
    floo_axi_ar             = '0;
    floo_axi_ar.hdr.rob_req = ar_rob_req_out;
    floo_axi_ar.hdr.rob_idx = ar_rob_idx_out;
    floo_axi_ar.hdr.dst_id  = dst_id[AxiAr];
    floo_axi_ar.hdr.mask    = mask[AxiAr];
    floo_axi_ar.hdr.src_id  = id_i;
    floo_axi_ar.hdr.last    = 1'b1;
    floo_axi_ar.hdr.axi_ch  = AxiAr;
    floo_axi_ar.payload     = axi_ar_queue;
  end

  always_comb begin
    floo_axi_b              = '0;
    floo_axi_b.hdr.rob_req  = aw_out_hdr_out.hdr.rob_req;
    floo_axi_b.hdr.rob_idx  = aw_out_hdr_out.hdr.rob_idx;
    floo_axi_b.hdr.dst_id   = dst_id[AxiB];
    floo_axi_b.hdr.mask     = aw_out_hdr_out.hdr.mask;
    floo_axi_b.hdr.src_id   = id_i;
    floo_axi_b.hdr.last     = 1'b1;
    floo_axi_b.hdr.axi_ch   = AxiB;
    floo_axi_b.hdr.atop     = aw_out_hdr_out.hdr.atop;
    floo_axi_b.payload      = meta_buf_rsp_out.b;
    floo_axi_b.payload.id   = aw_out_hdr_out.id;
    floo_axi_b.hdr.commtype = aw_out_hdr_out.hdr.commtype == Multicast? CollectB : Unicast;
  end

  always_comb begin
    floo_axi_r              = '0;
    floo_axi_r.hdr.rob_req  = ar_out_hdr_out.hdr.rob_req;
    floo_axi_r.hdr.rob_idx  = ar_out_hdr_out.hdr.rob_idx;
    floo_axi_r.hdr.dst_id   = dst_id[AxiR];
    floo_axi_r.hdr.mask     = mask[AxiR];
    floo_axi_r.hdr.src_id   = id_i;
    floo_axi_r.hdr.last     = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_axi_r.hdr.axi_ch   = AxiR;
    floo_axi_r.hdr.atop     = ar_out_hdr_out.hdr.atop;
    floo_axi_r.payload      = meta_buf_rsp_out.r;
    floo_axi_r.payload.id   = ar_out_hdr_out.id;
  end

  always_comb begin
    aw_w_sel_d = aw_w_sel_q;
    if (axi_aw_queue_valid_out && axi_aw_queue_ready_in) aw_w_sel_d = SelW;
    if (axi_req_in.w_valid && axi_rsp_out.w_ready && axi_req_in.w.last) aw_w_sel_d = SelAw;
  end

  `FF(aw_w_sel_q, aw_w_sel_d, SelAw)

  assign floo_req_arb_req_in[AxiW]  = (aw_w_sel_q == SelAw) && (aw_rob_valid_out ||
                                        ((axi_aw_queue.atop != axi_pkg::ATOP_NONE) &&
                                          axi_aw_queue_valid_out)) ||
                                      (aw_w_sel_q == SelW) && axi_req_in.w_valid;
  assign floo_req_arb_req_in[AxiAr] = ar_rob_valid_out;
  assign floo_rsp_arb_req_in[AxiB]  = meta_buf_rsp_out.b_valid;
  assign floo_rsp_arb_req_in[AxiR]  = meta_buf_rsp_out.r_valid;

  assign aw_rob_ready_in      = floo_req_arb_gnt_out[AxiW] && (aw_w_sel_q == SelAw);
  assign axi_rsp_out.w_ready  = floo_req_arb_gnt_out[AxiW] && (aw_w_sel_q == SelW);
  assign ar_rob_ready_in      = floo_req_arb_gnt_out[AxiAr];

  assign floo_req_arb_in[AxiW]  = (aw_w_sel_q == SelAw)? floo_axi_aw : floo_axi_w;
  assign floo_req_arb_in[AxiAr] = floo_axi_ar;
  assign floo_rsp_arb_in[AxiB]  = floo_axi_b;
  assign floo_rsp_arb_in[AxiR]  = floo_axi_r;

  ///////////////////////
  // FLIT ARBITRATION  //
  ///////////////////////

  floo_wormhole_arbiter #(
    .NumRoutes  ( 2                       ),
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

  assign axi_unpack_aw = floo_req_in.axi_aw.payload;
  assign axi_unpack_w  = floo_req_in.axi_w.payload;
  assign axi_unpack_ar = floo_req_in.axi_ar.payload;
  assign axi_unpack_r  = floo_rsp_in.axi_r.payload;
  assign axi_unpack_b  = floo_rsp_in.axi_b.payload;
  assign unpack_req_generic = floo_req_in.generic;
  assign unpack_rsp_generic = floo_rsp_in.generic;

  assign axi_valid_in[AxiAw] = floo_req_in_valid && (unpack_req_generic.hdr.axi_ch == AxiAw);
  assign axi_valid_in[AxiW]  = floo_req_in_valid && (unpack_req_generic.hdr.axi_ch == AxiW);
  assign axi_valid_in[AxiAr] = floo_req_in_valid && (unpack_req_generic.hdr.axi_ch == AxiAr);
  assign axi_valid_in[AxiB]  = ChimneyCfg.EnMgrPort && floo_rsp_in_valid &&
                               (unpack_rsp_generic.hdr.axi_ch == AxiB);
  assign axi_valid_in[AxiR]  = ChimneyCfg.EnMgrPort && floo_rsp_in_valid &&
                               (unpack_rsp_generic.hdr.axi_ch == AxiR);

  assign axi_ready_out[AxiAw] = meta_buf_rsp_out.aw_ready;
  assign axi_ready_out[AxiW]  = meta_buf_rsp_out.w_ready;
  assign axi_ready_out[AxiAr] = meta_buf_rsp_out.ar_ready;
  assign axi_ready_out[AxiB]  = b_rob_ready_out || b_sel_atop && axi_req_in.b_ready;
  assign axi_ready_out[AxiR]  = r_rob_ready_out || r_sel_atop && axi_req_in.r_ready;

  assign floo_req_out_ready = axi_ready_out[unpack_req_generic.hdr.axi_ch];
  assign floo_rsp_out_ready = axi_ready_out[unpack_rsp_generic.hdr.axi_ch];

  /////////////////////////////
  // AXI req/rsp generation  //
  ////////////////////////////

  assign meta_buf_req_in ='{
    aw        : axi_unpack_aw,
    aw_valid  : axi_valid_in[AxiAw],
    w         : axi_unpack_w,
    w_valid   : axi_valid_in[AxiW],
    b_ready   : floo_rsp_arb_gnt_out[AxiB],
    ar        : axi_unpack_ar,
    ar_valid  : axi_valid_in[AxiAr],
    r_ready   : floo_rsp_arb_gnt_out[AxiR]
  };

  assign b_rob_valid_in       = axi_valid_in[AxiB] && !is_atop_b_rsp;
  assign r_rob_valid_in       = axi_valid_in[AxiR] && !is_atop_r_rsp;
  assign axi_rsp_out.b_valid  = b_rob_valid_out || is_atop_b_rsp;
  assign axi_rsp_out.r_valid  = r_rob_valid_out || is_atop_r_rsp;
  assign b_rob_ready_in       = axi_req_in.b_ready && !b_sel_atop;
  assign r_rob_ready_in       = axi_req_in.r_ready && !r_sel_atop;

  assign axi_b_rob_in   = axi_unpack_b;
  assign axi_r_rob_in   = axi_unpack_r;
  assign axi_rsp_out.b  = (b_sel_atop)? axi_unpack_b : axi_b_rob_out;
  assign axi_rsp_out.r  = (r_sel_atop)? axi_unpack_r : axi_r_rob_out;

  logic is_atop, atop_has_r_rsp;
  assign is_atop = AtopSupport && axi_valid_in[AxiAw] &&
                    (axi_unpack_aw.atop != axi_pkg::ATOP_NONE);
  assign atop_has_r_rsp = AtopSupport && axi_valid_in[AxiAw] &&
                          axi_unpack_aw.atop[axi_pkg::ATOP_R_RESP];

  assign aw_out_hdr_in = '{
    id: axi_unpack_aw.id,
    hdr: unpack_req_generic.hdr
  };
  assign ar_out_hdr_in = '{
    id: (is_atop && atop_has_r_rsp)? axi_unpack_aw.id : axi_unpack_ar.id,
    hdr: unpack_req_generic.hdr
  };

  if (ChimneyCfg.EnSbrPort) begin : gen_mgr_port
    floo_meta_buffer #(
      .InIdWidth      ( AxiCfg.InIdWidth        ),
      .OutIdWidth     ( AxiCfg.OutIdWidth       ),
      .MaxTxns        ( ChimneyCfg.MaxTxns      ),
      .MaxUniqueIds   ( ChimneyCfg.MaxUniqueIds ),
      .AtopSupport    ( AtopSupport             ),
      .MaxAtomicTxns  ( MaxAtomicTxns           ),
      .buf_t          ( meta_buf_t              ),
      .axi_in_req_t   ( axi_in_req_t            ),
      .axi_in_rsp_t   ( axi_in_rsp_t            ),
      .axi_out_req_t  ( axi_out_req_t           ),
      .axi_out_rsp_t  ( axi_out_rsp_t           )
    ) i_floo_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .axi_req_i  ( meta_buf_req_in   ),
      .axi_rsp_o  ( meta_buf_rsp_out  ),
      .axi_req_o  ( meta_buf_req_out  ),
      .axi_rsp_i  ( meta_buf_rsp_in   ),
      .aw_buf_i   ( aw_out_hdr_in     ),
      .ar_buf_i   ( ar_out_hdr_in     ),
      .r_buf_o    ( ar_out_hdr_out    ),
      .b_buf_o    ( aw_out_hdr_out    )
    );
  end else begin : gen_no_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiCfg.InIdWidth  ),
      .ATOPs      ( AtopSupport       ),
      .axi_req_t  ( axi_in_req_t      ),
      .axi_resp_t ( axi_in_rsp_t      )
    ) i_axi_err_slv (
      .clk_i      ( clk_i             ),
      .rst_ni     ( rst_ni            ),
      .test_i     ( test_enable_i     ),
      .slv_req_i  ( meta_buf_req_in   ),
      .slv_resp_o ( meta_buf_rsp_out  )
    );
    assign meta_buf_req_out = '0;
    assign ar_out_hdr_out = '0;
    assign aw_out_hdr_out = '0;
  end

  // Registers
  `FF(b_rob_pending_q, b_rob_valid_out && !b_rob_ready_in && !is_atop_b_rsp, '0)
  `FF(r_rob_pending_q, r_rob_valid_out && !r_rob_ready_in && !is_atop_r_rsp, '0)

  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(ToSmallIdWidth, 1 + AtopSupport * MaxAtomicTxns <= 2**AxiCfg.OutIdWidth)

  // If Network Interface has no subordinate port, make sure that `RoBType` is `NoRoB`
  `ASSERT_INIT(NoMgrPortRobType, ChimneyCfg.EnMgrPort || (ChimneyCfg.BRoBType == NoRoB &&
                                                          ChimneyCfg.RRoBType == NoRoB))

  // Network Interface cannot accept any B and R responses if `EnMgrPort` is not set
  `ASSERT(NoMgrPortBResponse, ChimneyCfg.EnMgrPort || !(floo_rsp_in_valid &&
                                             (unpack_rsp_generic.hdr.axi_ch == AxiB)))
  `ASSERT(NoMgrPortRResponse, ChimneyCfg.EnMgrPort || !(floo_rsp_in_valid &&
                                             (unpack_rsp_generic.hdr.axi_ch == AxiR)))
  // Network Interface cannot accept any AW, AR and W requests if `EnSbrPort` is not set
  `ASSERT(NoSbrPortAwRequest, ChimneyCfg.EnSbrPort || !(floo_req_in_valid &&
                                             (unpack_req_generic.hdr.axi_ch == AxiAw)))
  `ASSERT(NoSbrPortArRequest, ChimneyCfg.EnSbrPort || !(floo_req_in_valid &&
                                             (unpack_req_generic.hdr.axi_ch == AxiAr)))
  `ASSERT(NoSbrPortWRequest,  ChimneyCfg.EnSbrPort || !(floo_req_in_valid &&
                                             (unpack_req_generic.hdr.axi_ch == AxiW)))

endmodule
