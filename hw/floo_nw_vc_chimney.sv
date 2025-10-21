// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

/// A bidirectional network interface for connecting narrow & wide AXI Buses to the multi-link NoC
module floo_nw_vc_chimney #(
  /// Config of the narrow AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfgN = '0,
  /// Config of the wide AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfgW = '0,
  /// Config of the narrow data path in the chimney (see floo_pkg::chimney_cfg_t for details)
  parameter floo_pkg::chimney_cfg_t ChimneyCfgN = floo_pkg::ChimneyDefaultCfg,
  /// Config of the wide data path in the chimney (see floo_pkg::chimney_cfg_t for details)
  parameter floo_pkg::chimney_cfg_t ChimneyCfgW = floo_pkg::ChimneyDefaultCfg,
  /// Config for routing information (see floo_pkg::route_cfg_t for details)
  parameter floo_pkg::route_cfg_t RouteCfg  = floo_pkg::RouteDefaultCfg,
  /// Atomic operation support, currently only implemented for
  /// the narrow network!
  parameter bit AtopSupport                      = 1'b1,
  /// Maximum number of oustanding Atomic transactions,
  /// must be smaller or equal to 2**`AxiCfgN.OutIdWidth`-1 since
  /// Every atomic transactions needs to have a unique ID
  /// and one ID is reserved for non-atomic transactions
  parameter int unsigned MaxAtomicTxns           = 1,
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
  /// VC ID type
  parameter type vc_id_t                                = logic,
  /// Header type for the flits
  parameter type hdr_t                                  = logic,
  /// Rule type for the System Address Map
  /// (only used if `RouteCfg.UseIdTable == 1'b1`)
  parameter type sam_rule_t                             = logic,
  /// The System Address Map (SAM) rules
  /// (only used if `RouteCfg.UseIdTable == 1'b1`)
  parameter sam_rule_t [RouteCfg.NumSamRules-1:0] Sam   = '0,
  /// Narrow AXI manager request channel type
  parameter type axi_narrow_in_req_t                    = logic,
  /// Narrow AXI manager response channel type
  parameter type axi_narrow_in_rsp_t                    = logic,
  /// Narrow AXI subordinate request channel type
  parameter type axi_narrow_out_req_t                   = logic,
  /// Narrow AXI subordinate response channel type
  parameter type axi_narrow_out_rsp_t                   = logic,
  /// Wide AXI manager request channel type
  parameter type axi_wide_in_req_t                      = logic,
  /// Wide AXI manager response channel type
  parameter type axi_wide_in_rsp_t                      = logic,
  /// Wide AXI subordinate request channel type
  parameter type axi_wide_out_req_t                     = logic,
  /// Wide AXI subordinate response channel type
  parameter type axi_wide_out_rsp_t                     = logic,
  /// Floo `req` link type
  parameter type floo_vc_req_t                          = logic,
  /// Floo `rsp` link type
  parameter type floo_vc_rsp_t                          = logic,
  /// Floo `wide` link type
  parameter type floo_vc_wide_t                         = logic,
  /// SRAM configuration type `tc_sram_impl` in RoB
  /// Only used if technology-dependent SRAM is used
  parameter type sram_cfg_t                             = logic,
  /// Address rule for the `id_route_map_i`
  parameter type addr_rule_t                            = logic,
  /// Number of Address Rules in the `id_route_map_i`
  parameter int unsigned NumAddrRules                   = 0,
  /// Which port the chimney is connected to the router (as seen from the router)
  parameter floo_pkg::route_direction_e OutputDir       = floo_pkg::Eject,
  /// Number of Virtual channels
  parameter int NumVC                            = 4, // as seen from chimney
  /// Number of bits to encode the VC
  parameter int NumVCWidth                       = cf_math_pkg::idx_width(NumVC),
  /// Enables faster return of credits to the source
  parameter int CreditShortcut                   = 1,
  /// Allow overflow to other VCs if the current VC is full
  parameter int AllowVCOverflow                  = 1,
  /// Depth of incoming VC link buffers
  parameter int InputFifoDepth                   = 3,
  /// Depth of outgoing VC link buffers
  parameter int VCDepth                          = 2,
  /// Enables Wormhole routing
  parameter int FixedWormholeVC                  = 1, // if 1, force wormhole flits to wormholeVCId
  /// VC ID to use for wormhole routing
  parameter int WormholeVCId                     = 0,
  /// Depth of the wormhole VC link buffers
  parameter int WormholeVCDepth                  = 3
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  /// SRAM configuration
  input  sram_cfg_t  sram_cfg_i,
  /// Narrow AXI4 side interfaces
  input  axi_narrow_in_req_t axi_narrow_in_req_i,
  output axi_narrow_in_rsp_t axi_narrow_in_rsp_o,
  output axi_narrow_out_req_t axi_narrow_out_req_o,
  input  axi_narrow_out_rsp_t axi_narrow_out_rsp_i,
  /// Wide AXI4 side interfaces
  input  axi_wide_in_req_t axi_wide_in_req_i,
  output axi_wide_in_rsp_t axi_wide_in_rsp_o,
  output axi_wide_out_req_t axi_wide_out_req_o,
  input  axi_wide_out_rsp_t axi_wide_out_rsp_i,
  /// Coordinates/ID of the current tile
  input  id_t id_i,
  /// Routing table for the current tile
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,
  /// Route map used by lookahead routing.
  /// (only used if `RouteCfg.RouteAlgo == IdTable`)
  input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,
  /// Output links to NoC
  output floo_vc_req_t   floo_req_o,
  output floo_vc_rsp_t   floo_rsp_o,
  output floo_vc_wide_t  floo_wide_o,
  /// Input links from NoC
  input  floo_vc_req_t   floo_req_i,
  input  floo_vc_rsp_t   floo_rsp_i,
  input  floo_vc_wide_t  floo_wide_i
);

  import floo_pkg::*;

  typedef logic [AxiCfgN.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfgN.InIdWidth-1:0] axi_narrow_in_id_t;
  typedef logic [AxiCfgN.UserWidth-1:0] axi_narrow_user_t;
  typedef logic [AxiCfgN.DataWidth-1:0] axi_narrow_data_t;
  typedef logic [AxiCfgN.DataWidth/8-1:0] axi_narrow_strb_t;
  typedef logic [AxiCfgW.InIdWidth-1:0] axi_wide_in_id_t;
  typedef logic [AxiCfgW.UserWidth-1:0] axi_wide_user_t;
  typedef logic [AxiCfgW.DataWidth-1:0] axi_wide_data_t;
  typedef logic [AxiCfgW.DataWidth/8-1:0] axi_wide_strb_t;

  // (Re-) definitons of `axi_in` and `floo` types, for transport
  `AXI_TYPEDEF_ALL_CT(axi_narrow, axi_narrow_req_t, axi_narrow_rsp_t, axi_addr_t,
      axi_narrow_in_id_t, axi_narrow_data_t, axi_narrow_strb_t, axi_narrow_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide, axi_wide_req_t, axi_wide_rsp_t, axi_addr_t,
      axi_wide_in_id_t, axi_wide_data_t, axi_wide_strb_t, axi_wide_user_t)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow, axi_wide, AxiCfgN, AxiCfgW, hdr_t)

  // Duplicate AXI port signals to degenerate ports
  // in case they are not used
  axi_narrow_req_t axi_narrow_req_in;
  axi_narrow_rsp_t axi_narrow_rsp_out;
  axi_wide_req_t axi_wide_req_in;
  axi_wide_rsp_t axi_wide_rsp_out;

  // AX queue
  axi_narrow_aw_chan_t axi_narrow_aw_queue;
  axi_narrow_ar_chan_t axi_narrow_ar_queue;
  axi_wide_aw_chan_t axi_wide_aw_queue;
  axi_wide_ar_chan_t axi_wide_ar_queue;
  logic axi_narrow_aw_queue_valid_out, axi_narrow_aw_queue_ready_in;
  logic axi_narrow_ar_queue_valid_out, axi_narrow_ar_queue_ready_in;
  logic axi_wide_aw_queue_valid_out, axi_wide_aw_queue_ready_in;
  logic axi_wide_ar_queue_valid_out, axi_wide_ar_queue_ready_in;

  floo_req_chan_t [WideAr:NarrowAw] floo_req_arb_in;
  floo_rsp_chan_t [WideB:NarrowB] floo_rsp_arb_in;
  floo_wide_chan_t [WideR:WideAw] floo_wide_arb_in;
  logic  [WideAr:NarrowAw] floo_req_arb_req_in, floo_req_arb_gnt_out, floo_req_arb_gnt;
  logic  [WideB:NarrowB]   floo_rsp_arb_req_in, floo_rsp_arb_gnt_out, floo_rsp_arb_gnt;
  logic  [WideR:WideAw]    floo_wide_arb_req_in, floo_wide_arb_gnt_out,  floo_wide_arb_gnt;

  // flit queue
  floo_req_chan_t floo_req_in;
  floo_rsp_chan_t floo_rsp_in;
  floo_wide_chan_t floo_wide_in;
  logic floo_req_in_valid, floo_rsp_in_valid, floo_wide_in_valid;
  logic floo_req_out_ready, floo_rsp_out_ready, floo_wide_out_ready;
  logic [NumNWAxiChannels-1:0] axi_valid_in, axi_ready_out;

  // Flit packing
  floo_axi_narrow_aw_flit_t floo_narrow_aw;
  floo_axi_narrow_ar_flit_t floo_narrow_ar;
  floo_axi_narrow_w_flit_t  floo_narrow_w;
  floo_axi_narrow_b_flit_t  floo_narrow_b;
  floo_axi_narrow_r_flit_t  floo_narrow_r;
  floo_axi_wide_aw_flit_t floo_wide_aw;
  floo_axi_wide_ar_flit_t floo_wide_ar;
  floo_axi_wide_w_flit_t  floo_wide_w;
  floo_axi_wide_b_flit_t  floo_wide_b;
  floo_axi_wide_r_flit_t  floo_wide_r;

  // Flit arbitration
  typedef enum logic {SelAw, SelW} aw_w_sel_e;
  aw_w_sel_e narrow_aw_w_sel_q, narrow_aw_w_sel_d;
  aw_w_sel_e wide_aw_w_sel_q, wide_aw_w_sel_d;

  // directly from arbiter
  hdr_t floo_req_arb_sel_hdr, floo_rsp_arb_sel_hdr, floo_wide_arb_sel_hdr;
  // after lookahead
  hdr_t floo_req_sel_hdr, floo_rsp_sel_hdr, floo_wide_sel_hdr;
  logic floo_req_arb_v, floo_rsp_arb_v, floo_wide_arb_v;
  route_direction_e floo_req_lookahead, floo_rsp_lookahead, floo_wide_lookahead;

  // Credit counting
  logic [NumVC-1:0]                 floo_req_vc_not_full;
  logic [NumVC-1:0]                 floo_rsp_vc_not_full;
  logic [NumVC-1:0]                 floo_wide_vc_not_full;

  // VC Selection / Assignment

  logic [NumVC-1:0] floo_req_vc_selection_v, floo_rsp_vc_selection_v, floo_wide_vc_selection_v;
  logic [NumVC-1:0][NumVCWidth-1:0] floo_req_vc_selection_id,
                                    floo_rsp_vc_selection_id,
                                    floo_wide_vc_selection_id;
  vc_id_t floo_req_pref_vc_id, floo_rsp_pref_vc_id, floo_wide_pref_vc_id;
  vc_id_t floo_req_vc_id, floo_rsp_vc_id, floo_wide_vc_id;

  // Wormhole detection
  logic floo_req_wh_detect, floo_req_wh_valid_d, floo_req_wh_valid,
        floo_rsp_wormhole_detected, floo_rsp_wh_valid_d, floo_rsp_wh_valid,
        floo_wide_wormhole_detected, floo_wide_wh_valid_d, floo_wide_wh_valid;

  // Flit unpacking
  axi_narrow_aw_chan_t axi_narrow_unpack_aw;
  axi_narrow_w_chan_t  axi_narrow_unpack_w;
  axi_narrow_b_chan_t  axi_narrow_unpack_b;
  axi_narrow_ar_chan_t axi_narrow_unpack_ar;
  axi_narrow_r_chan_t  axi_narrow_unpack_r;
  axi_wide_aw_chan_t   axi_wide_unpack_aw;
  axi_wide_w_chan_t    axi_wide_unpack_w;
  axi_wide_b_chan_t    axi_wide_unpack_b;
  axi_wide_ar_chan_t   axi_wide_unpack_ar;
  axi_wide_r_chan_t    axi_wide_unpack_r;
  floo_req_generic_flit_t   floo_req_unpack_generic;
  floo_rsp_generic_flit_t   floo_rsp_unpack_generic;
  floo_wide_generic_flit_t  floo_wide_unpack_generic;

  // Meta Buffers
  axi_narrow_in_req_t axi_narrow_meta_buf_req_in;
  axi_narrow_in_rsp_t axi_narrow_meta_buf_rsp_out;
  axi_wide_in_req_t   axi_wide_meta_buf_req_in;
  axi_wide_in_rsp_t   axi_wide_meta_buf_rsp_out;

  // ID tracking
  typedef struct packed {
    axi_narrow_in_id_t  id;
    hdr_t        hdr;
  } narrow_meta_buf_t;

  typedef struct packed {
    axi_wide_in_id_t  id;
    hdr_t        hdr;
  } wide_meta_buf_t;

  // Routing
  dst_t [NumNWAxiChannels-1:0] dst_id;
  dst_t narrow_aw_id_q, wide_aw_id_q;
  route_t [NumNWAxiChannels-1:0] route_out;
  id_t [NumNWAxiChannels-1:0] id_out;


  narrow_meta_buf_t narrow_aw_buf_hdr_in, narrow_aw_buf_hdr_out;
  narrow_meta_buf_t narrow_ar_buf_hdr_in, narrow_ar_buf_hdr_out;
  wide_meta_buf_t wide_aw_buf_hdr_in, wide_aw_buf_hdr_out;
  wide_meta_buf_t wide_ar_buf_hdr_in, wide_ar_buf_hdr_out;

  ///////////////////////
  //  Spill registers  //
  ///////////////////////

  if (ChimneyCfgN.EnMgrPort) begin : gen_narrow_sbr_port

    assign axi_narrow_req_in = axi_narrow_in_req_i;
    assign axi_narrow_in_rsp_o = axi_narrow_rsp_out;

    if (ChimneyCfgN.CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_narrow_aw_chan_t )
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
        .T ( axi_narrow_ar_chan_t )
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
      .AxiIdWidth ( AxiCfgN.InIdWidth   ),
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

  if (ChimneyCfgW.EnMgrPort) begin : gen_wide_sbr_port

    assign axi_wide_req_in = axi_wide_in_req_i;
    assign axi_wide_in_rsp_o = axi_wide_rsp_out;

    if (ChimneyCfgW.CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_wide_aw_chan_t )
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
        .T ( axi_wide_ar_chan_t )
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
      .AxiIdWidth ( AxiCfgW.InIdWidth ),
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

  if (ChimneyCfgN.CutRsp && ChimneyCfgW.CutRsp) begin : gen_floo_input_fifos
    floo_input_fifo #(
    .Depth  ( InputFifoDepth ),
    .type_t ( floo_req_chan_t )
    ) i_narrow_data_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_req_i.req      ),
      .valid_i    ( floo_req_i.valid    ),
      .data_o     ( floo_req_in         ),
      .valid_o    ( floo_req_in_valid   ),
      .ready_i    ( floo_req_out_ready  )
    );

    floo_input_fifo #(
    .Depth  ( InputFifoDepth ),
    .type_t ( floo_rsp_chan_t )
    ) i_narrow_data_rsp_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_rsp_i.rsp      ),
      .valid_i    ( floo_rsp_i.valid    ),
      .data_o     ( floo_rsp_in         ),
      .valid_o    ( floo_rsp_in_valid   ),
      .ready_i    ( floo_rsp_out_ready  )
    );

    floo_input_fifo #(
    .Depth  ( InputFifoDepth ),
    .type_t ( floo_wide_chan_t )
    ) i_wide_data_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_wide_i.wide    ),
      .valid_i    ( floo_wide_i.valid   ),
      .data_o     ( floo_wide_in        ),
      .valid_o    ( floo_wide_in_valid  ),
      .ready_i    ( floo_wide_out_ready )
    );

  end else begin : gen_no_rsp_cuts
    $fatal(1, "A credit based chimney requires a buffer");
  end

  ///////////////////////
  //  Reorder Buffers  //
  ///////////////////////

  // AW/B RoB
  axi_narrow_b_chan_t axi_narrow_b_rob_out, axi_narrow_b_rob_in;
  logic  narrow_aw_rob_req_out;
  rob_idx_t narrow_aw_rob_idx_out;
  logic narrow_aw_rob_valid_out, narrow_aw_rob_ready_in;
  logic narrow_aw_rob_valid_in, narrow_aw_rob_ready_out;
  logic narrow_b_rob_valid_in, narrow_b_rob_ready_out;
  logic narrow_b_rob_valid_out, narrow_b_rob_ready_in;
  axi_wide_b_chan_t axi_wide_b_rob_out, axi_wide_b_rob_in;
  logic  wide_aw_rob_req_out;
  rob_idx_t wide_aw_rob_idx_out;
  logic wide_aw_rob_valid_out, wide_aw_rob_ready_in;
  logic wide_b_rob_valid_in, wide_b_rob_ready_out;
  logic wide_b_rob_valid_out, wide_b_rob_ready_in;

  // AR/R RoB
  axi_narrow_r_chan_t axi_narrow_r_rob_out, axi_narrow_r_rob_in;
  logic  narrow_ar_rob_req_out;
  rob_idx_t narrow_ar_rob_idx_out;
  logic narrow_ar_rob_valid_out, narrow_ar_rob_ready_in;
  logic narrow_r_rob_valid_in, narrow_r_rob_ready_out;
  logic narrow_r_rob_valid_out, narrow_r_rob_ready_in;
  axi_wide_r_chan_t axi_wide_r_rob_out, axi_wide_r_rob_in;
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
    .RoBType            ( ChimneyCfgN.BRoBType      ),
    .RoBSize            ( ChimneyCfgN.BRoBSize      ),
    .MaxRoTxnsPerId     ( ChimneyCfgN.MaxTxnsPerId  ),
    .OnlyMetaData       ( 1'b1                      ),
    .ax_len_t           ( axi_pkg::len_t            ),
    .ax_id_t            ( axi_narrow_in_id_t        ),
    .rsp_chan_t         ( axi_narrow_b_chan_t       ),
    .rsp_meta_t         ( axi_narrow_b_chan_t       ),
    .rob_idx_t          ( rob_idx_t                 ),
    .dest_t             ( id_t                      ),
    .sram_cfg_t         ( sram_cfg_t                )
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
    .RoBType            ( ChimneyCfgW.BRoBType      ),
    .RoBSize            ( ChimneyCfgW.BRoBSize      ),
    .MaxRoTxnsPerId     ( ChimneyCfgW.MaxTxnsPerId  ),
    .OnlyMetaData       ( 1'b1                      ),
    .ax_len_t           ( axi_pkg::len_t            ),
    .ax_id_t            ( axi_wide_in_id_t          ),
    .rsp_chan_t         ( axi_wide_b_chan_t         ),
    .rsp_meta_t         ( axi_wide_b_chan_t         ),
    .rob_idx_t          ( rob_idx_t                 ),
    .dest_t             ( id_t                      ),
    .sram_cfg_t         ( sram_cfg_t                )
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
    axi_narrow_in_id_t  id;
    axi_narrow_user_t   user;
    axi_pkg::resp_t     resp;
    logic               last;
  } narrow_meta_t;

  typedef struct packed {
    axi_wide_in_id_t  id;
    axi_wide_user_t   user;
    axi_pkg::resp_t   resp;
    logic             last;
  } wide_meta_t;

  logic narrow_r_rob_rob_req;
  logic narrow_r_rob_last;
  rob_idx_t narrow_r_rob_rob_idx;
  assign narrow_r_rob_rob_req = floo_rsp_in.narrow_r.hdr.rob_req;
  assign narrow_r_rob_rob_idx = floo_rsp_in.narrow_r.hdr.rob_idx;
  assign narrow_r_rob_last = floo_rsp_in.narrow_r.payload.last;

  floo_rob_wrapper #(
    .RoBType            ( ChimneyCfgN.RRoBType      ),
    .RoBSize            ( ChimneyCfgN.RRoBSize      ),
    .MaxRoTxnsPerId     ( ChimneyCfgN.MaxTxnsPerId  ),
    .OnlyMetaData       ( 1'b0                      ),
    .ax_len_t           ( axi_pkg::len_t            ),
    .ax_id_t            ( axi_narrow_in_id_t        ),
    .rsp_chan_t         ( axi_narrow_r_chan_t       ),
    .rsp_data_t         ( axi_narrow_data_t         ),
    .rsp_meta_t         ( narrow_meta_t             ),
    .rob_idx_t          ( rob_idx_t                 ),
    .dest_t             ( id_t                      ),
    .sram_cfg_t         ( sram_cfg_t                )
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
  assign wide_r_rob_last = floo_wide_in.wide_r.payload.last;

  floo_rob_wrapper #(
    .RoBType            ( ChimneyCfgW.RRoBType      ),
    .RoBSize            ( ChimneyCfgW.RRoBSize      ),
    .MaxRoTxnsPerId     ( ChimneyCfgW.MaxTxnsPerId  ),
    .OnlyMetaData       ( 1'b0                      ),
    .ax_len_t           ( axi_pkg::len_t            ),
    .ax_id_t            ( axi_wide_in_id_t          ),
    .rsp_chan_t         ( axi_wide_r_chan_t         ),
    .rsp_data_t         ( axi_wide_data_t           ),
    .rsp_meta_t         ( wide_meta_t               ),
    .rob_idx_t          ( rob_idx_t                 ),
    .dest_t             ( id_t                      ),
    .sram_cfg_t         ( sram_cfg_t                )
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

  axi_addr_t [NumNWAxiChannels-1:0] axi_req_addr;
  id_t [NumNWAxiChannels-1:0] axi_rsp_src_id;

  assign axi_req_addr[NarrowAw] = axi_narrow_aw_queue.addr;
  assign axi_req_addr[NarrowAr] = axi_narrow_ar_queue.addr;
  assign axi_req_addr[WideAw]   = axi_wide_aw_queue.addr;
  assign axi_req_addr[WideAr]   = axi_wide_ar_queue.addr;

  assign axi_rsp_src_id[NarrowB] = narrow_aw_buf_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[NarrowR] = narrow_ar_buf_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[WideB]   = wide_aw_buf_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[WideR]   = wide_ar_buf_hdr_out.hdr.src_id;

  for (genvar ch = 0; ch < NumNWAxiChannels; ch++) begin : gen_route_comp
    localparam nw_ch_e Ch = nw_ch_e'(ch);
    if (Ch == NarrowAw || Ch == NarrowAr ||
        Ch == WideAw || Ch == WideAr) begin : gen_req_route_comp

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
        .route_o    ( route_out[ch]     ),
        .id_o       ( id_out[ch]        )
      );
    end else if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting &&
                 (Ch == NarrowB || Ch == NarrowR ||
                  Ch == WideB || Ch == WideR)) begin : gen_rsp_route_comp
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
        .addr_map_i ( '0                  ),
        .id_i       ( axi_rsp_src_id[ch]  ),
        .route_o    ( route_out[ch]       ),
        .id_o       ( id_out[ch]          )
      );
    end
  end

  if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting) begin : gen_route_field
    assign route_out[NarrowW] = narrow_aw_id_q;
    assign route_out[WideW]   = wide_aw_id_q;
    assign dst_id = route_out;
  end else begin : gen_dst_field
    assign dst_id[NarrowAw] = id_out[NarrowAw];
    assign dst_id[NarrowAr] = id_out[NarrowAr];
    assign dst_id[WideAw]   = id_out[WideAw];
    assign dst_id[WideAr]   = id_out[WideAr];
    assign dst_id[NarrowB]  = narrow_aw_buf_hdr_out.hdr.src_id;
    assign dst_id[NarrowR]  = narrow_ar_buf_hdr_out.hdr.src_id;
    assign dst_id[WideB]    = wide_aw_buf_hdr_out.hdr.src_id;
    assign dst_id[WideR]    = wide_ar_buf_hdr_out.hdr.src_id;
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
  localparam route_direction_e ChimneyOutDir = OutputDir >= Eject ? Eject :
                              route_direction_e'((OutputDir - 2) % 4);

  always_comb begin
    floo_narrow_aw              = '0;
    floo_narrow_aw.hdr.rob_req  = narrow_aw_rob_req_out;
    floo_narrow_aw.hdr.rob_idx  = rob_idx_t'(narrow_aw_rob_idx_out);
    floo_narrow_aw.hdr.dst_id   = dst_id[NarrowAw];
    floo_narrow_aw.hdr.src_id   = id_i;
    floo_narrow_aw.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_narrow_aw.hdr.last     = 1'b0;  // AW and W need to be sent together
    floo_narrow_aw.hdr.axi_ch   = NarrowAw;
    floo_narrow_aw.hdr.atop     = axi_narrow_aw_queue.atop != axi_pkg::ATOP_NONE;
    floo_narrow_aw.payload      = axi_narrow_aw_queue;
  end

  always_comb begin
    floo_narrow_w               = '0;
    floo_narrow_w.hdr.rob_req   = narrow_aw_rob_req_out;
    floo_narrow_w.hdr.rob_idx   = rob_idx_t'(narrow_aw_rob_idx_out);
    floo_narrow_w.hdr.dst_id    = dst_id[NarrowW];
    floo_narrow_w.hdr.src_id    = id_i;
    floo_narrow_w.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_narrow_w.hdr.last      = axi_narrow_req_in.w.last;
    floo_narrow_w.hdr.axi_ch    = NarrowW;
    floo_narrow_w.payload       = axi_narrow_req_in.w;
  end

  always_comb begin
    floo_narrow_ar              = '0;
    floo_narrow_ar.hdr.rob_req  = narrow_ar_rob_req_out;
    floo_narrow_ar.hdr.rob_idx  = rob_idx_t'(narrow_ar_rob_idx_out);
    floo_narrow_ar.hdr.dst_id   = dst_id[NarrowAr];
    floo_narrow_ar.hdr.src_id   = id_i;
    floo_narrow_ar.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_narrow_ar.hdr.last     = 1'b1;
    floo_narrow_ar.hdr.axi_ch   = NarrowAr;
    floo_narrow_ar.payload      = axi_narrow_ar_queue;
  end

  always_comb begin
    floo_narrow_b             = '0;
    floo_narrow_b.hdr.rob_req = narrow_aw_buf_hdr_out.hdr.rob_req;
    floo_narrow_b.hdr.rob_idx = rob_idx_t'(narrow_aw_buf_hdr_out.hdr.rob_idx);
    floo_narrow_b.hdr.dst_id  = dst_id[NarrowB];
    floo_narrow_b.hdr.src_id  = id_i;
    floo_narrow_b.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_narrow_b.hdr.last    = 1'b1;
    floo_narrow_b.hdr.axi_ch  = NarrowB;
    floo_narrow_b.hdr.atop    = narrow_aw_buf_hdr_out.hdr.atop;
    floo_narrow_b.payload     = axi_narrow_meta_buf_rsp_out.b;
    floo_narrow_b.payload.id  = narrow_aw_buf_hdr_out.id;
  end

  always_comb begin
    floo_narrow_r             = '0;
    floo_narrow_r.hdr.rob_req = narrow_ar_buf_hdr_out.hdr.rob_req;
    floo_narrow_r.hdr.rob_idx = rob_idx_t'(narrow_ar_buf_hdr_out.hdr.rob_idx);
    floo_narrow_r.hdr.dst_id  = dst_id[NarrowR];
    floo_narrow_r.hdr.src_id  = id_i;
    floo_narrow_r.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_narrow_r.hdr.axi_ch  = NarrowR;
    floo_narrow_r.hdr.last    = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_narrow_r.hdr.atop    = narrow_ar_buf_hdr_out.hdr.atop;
    floo_narrow_r.payload     = axi_narrow_meta_buf_rsp_out.r;
    floo_narrow_r.payload.id  = narrow_ar_buf_hdr_out.id;
  end

  always_comb begin
    floo_wide_aw              = '0;
    floo_wide_aw.hdr.rob_req  = wide_aw_rob_req_out;
    floo_wide_aw.hdr.rob_idx  = rob_idx_t'(wide_aw_rob_idx_out);
    floo_wide_aw.hdr.dst_id   = dst_id[WideAw];
    floo_wide_aw.hdr.src_id   = id_i;
    floo_wide_aw.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_wide_aw.hdr.last     = 1'b0;  // AW and W need to be sent together
    floo_wide_aw.hdr.axi_ch   = WideAw;
    floo_wide_aw.payload      = axi_wide_aw_queue;
  end

  always_comb begin
    floo_wide_w             = '0;
    floo_wide_w.hdr.rob_req = wide_aw_rob_req_out;
    floo_wide_w.hdr.rob_idx = rob_idx_t'(wide_aw_rob_idx_out);
    floo_wide_w.hdr.dst_id  = dst_id[WideW];
    floo_wide_w.hdr.src_id  = id_i;
    floo_wide_w.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_wide_w.hdr.last    = axi_wide_req_in.w.last;
    floo_wide_w.hdr.axi_ch  = WideW;
    floo_wide_w.payload     = axi_wide_req_in.w;
  end

  always_comb begin
    floo_wide_ar              = '0;
    floo_wide_ar.hdr.rob_req  = wide_ar_rob_req_out;
    floo_wide_ar.hdr.rob_idx  = rob_idx_t'(wide_ar_rob_idx_out);
    floo_wide_ar.hdr.dst_id   = dst_id[WideAr];
    floo_wide_ar.hdr.src_id   = id_i;
    floo_wide_ar.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_wide_ar.hdr.last     = 1'b1;
    floo_wide_ar.hdr.axi_ch   = WideAr;
    floo_wide_ar.payload      = axi_wide_ar_queue;
  end

  always_comb begin
    floo_wide_b             = '0;
    floo_wide_b.hdr.rob_req = wide_aw_buf_hdr_out.hdr.rob_req;
    floo_wide_b.hdr.rob_idx = rob_idx_t'(wide_aw_buf_hdr_out.hdr.rob_idx);
    floo_wide_b.hdr.dst_id  = dst_id[WideB];
    floo_wide_b.hdr.src_id  = id_i;
    floo_wide_b.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_wide_b.hdr.last    = 1'b1;
    floo_wide_b.hdr.axi_ch  = WideB;
    floo_wide_b.payload     = axi_wide_meta_buf_rsp_out.b;
    floo_wide_b.payload.id  = wide_aw_buf_hdr_out.id;
  end

  always_comb begin
    floo_wide_r             = '0;
    floo_wide_r.hdr.rob_req = wide_ar_buf_hdr_out.hdr.rob_req;
    floo_wide_r.hdr.rob_idx = rob_idx_t'(wide_ar_buf_hdr_out.hdr.rob_idx);
    floo_wide_r.hdr.dst_id  = dst_id[WideR];
    floo_wide_r.hdr.src_id  = id_i;
    floo_wide_r.hdr.lookahead = ChimneyOutDir; // such that lookahead calculates correctly
    floo_wide_r.hdr.axi_ch  = WideR;
    floo_wide_r.hdr.last    = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_wide_r.payload     = axi_wide_meta_buf_rsp_out.r;
    floo_wide_r.payload.id  = wide_ar_buf_hdr_out.id;
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

  assign narrow_aw_rob_ready_in     = floo_req_arb_gnt[NarrowW] &&
                                      (narrow_aw_w_sel_q == SelAw);
  assign axi_narrow_rsp_out.w_ready = floo_req_arb_gnt[NarrowW] &&
                                      (narrow_aw_w_sel_q == SelW);
  assign narrow_ar_rob_ready_in     = floo_req_arb_gnt[NarrowAr];
  assign wide_aw_rob_ready_in       = floo_wide_arb_gnt[WideW] &&
                                      (wide_aw_w_sel_q == SelAw);
  assign axi_wide_rsp_out.w_ready   = floo_wide_arb_gnt[WideW] &&
                                      (wide_aw_w_sel_q == SelW);
  assign wide_ar_rob_ready_in       = floo_req_arb_gnt[WideAr];

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
    .valid_i  ( floo_req_arb_req_in                                     ),
    .data_i   ( floo_req_arb_in                                         ),
    .ready_o  ( floo_req_arb_gnt_out                                    ),
    .data_o   ( {floo_req_arb_sel_hdr, floo_req_o.req.generic.payload}  ),
    .ready_i  ( floo_req_o.valid                                        ),
    .valid_o  ( floo_req_arb_v                                          )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( 3                       ),
    .flit_t     ( floo_rsp_generic_flit_t )
  ) i_rsp_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .valid_i  ( floo_rsp_arb_req_in                                   ),
    .data_i   ( floo_rsp_arb_in                                       ),
    .ready_o  ( floo_rsp_arb_gnt_out                                  ),
    .data_o   ( {floo_rsp_arb_sel_hdr,floo_rsp_o.rsp.generic.payload} ),
    .ready_i  ( floo_rsp_o.valid                                      ),
    .valid_o  ( floo_rsp_arb_v                                        )
  );

  floo_wormhole_arbiter #(
    .NumRoutes  ( 3                         ),
    .flit_t     ( floo_wide_generic_flit_t  )
  ) i_wide_wormhole_arbiter (
    .clk_i,
    .rst_ni,
    .valid_i  ( floo_wide_arb_req_in                                      ),
    .data_i   ( floo_wide_arb_in                                          ),
    .ready_o  ( floo_wide_arb_gnt_out                                     ),
    .data_o   ( {floo_wide_arb_sel_hdr, floo_wide_o.wide.generic.payload} ),
    .ready_i  ( floo_wide_o.valid                                         ),
    .valid_o  ( floo_wide_arb_v                                           )
  );

  assign floo_req_arb_gnt = floo_req_arb_gnt_out & {4{floo_req_o.valid}};
  assign floo_rsp_arb_gnt = floo_rsp_arb_gnt_out & {3{floo_rsp_o.valid}};
  assign floo_wide_arb_gnt= floo_wide_arb_gnt_out & {3{floo_wide_o.valid}};

  ///////////////////////
  // LOOKAHEAD ROUTING //
  ///////////////////////

  floo_look_ahead_routing #(
    .NumRoutes    ( RouteCfg.NumRoutes    ),
    .hdr_t        ( hdr_t                 ),
    .RouteAlgo    ( RouteCfg.RouteAlgo    ),
    .id_t         ( id_t                  ),
    .NumAddrRules ( RouteCfg.NumSamRules  ),
    .addr_rule_t  ( sam_rule_t            )
  ) i_floo_req_look_ahead_routing (
    .clk_i,
    .rst_ni,
    .id_route_map_i,
    .hdr_i      ( floo_req_arb_sel_hdr  ),
    .hdr_o      ( floo_req_sel_hdr      ),
    .la_route_o ( floo_req_lookahead    ),
    .xy_id_i    ( id_i                  )
  );

  floo_look_ahead_routing #(
    .NumRoutes    ( RouteCfg.NumRoutes    ),
    .hdr_t        ( hdr_t                 ),
    .RouteAlgo    ( RouteCfg.RouteAlgo    ),
    .id_t         ( id_t                  ),
    .NumAddrRules ( RouteCfg.NumSamRules  ),
    .addr_rule_t  ( sam_rule_t            )
  ) i_floo_rsp_look_ahead_routing (
    .clk_i,
    .rst_ni,
    .id_route_map_i,
    .hdr_i      ( floo_rsp_arb_sel_hdr  ),
    .hdr_o      ( floo_rsp_sel_hdr      ),
    .la_route_o ( floo_rsp_lookahead    ),
    .xy_id_i    ( id_i                  )
  );

  floo_look_ahead_routing #(
    .NumRoutes    ( RouteCfg.NumRoutes    ),
    .hdr_t        ( hdr_t                 ),
    .RouteAlgo    ( RouteCfg.RouteAlgo    ),
    .id_t         ( id_t                  ),
    .NumAddrRules ( RouteCfg.NumSamRules  ),
    .addr_rule_t  ( sam_rule_t            )
  ) i_floo_wide_look_ahead_routing (
    .clk_i,
    .rst_ni,
    .id_route_map_i,
    .hdr_i      ( floo_wide_arb_sel_hdr ),
    .hdr_o      ( floo_wide_sel_hdr     ),
    .la_route_o ( floo_wide_lookahead   ),
    .xy_id_i    ( id_i                  )
  );

  /////////////////////
  // CREDIT COUNTING //
  /////////////////////

  // these Credit counters count the credits (towards the input port of the router)
  floo_credit_counter #(
    .NumVC          ( NumVC           ),
    .VCIdxWidthMax  ( NumVCWidth      ),
    .VCDepth        ( VCDepth         ),
    .DeeperVCId     ( WormholeVCId    ),
    .DeeperVCDepth  ( WormholeVCDepth )
  ) i_floo_req_credit_counter (
    .clk_i,
    .rst_ni,
    .credit_valid_i         ( floo_req_i.credit_v                   ),
    .credit_id_i            ( floo_req_i.credit_id[NumVCWidth-1:0]  ),
    .consume_credit_valid_i ( floo_req_o.valid                      ),
    .consume_credit_id_i    ( floo_req_vc_id[NumVCWidth-1:0]        ),
    .vc_not_full_o          ( floo_req_vc_not_full                  )
  );

  floo_credit_counter #(
    .NumVC          ( NumVC           ),
    .VCIdxWidthMax  ( NumVCWidth      ),
    .VCDepth        ( VCDepth         ),
    .DeeperVCId     ( WormholeVCId    ),
    .DeeperVCDepth  ( WormholeVCDepth )
  ) i_floo_rsp_credit_counter (
    .clk_i,
    .rst_ni,
    .credit_valid_i         ( floo_rsp_i.credit_v                   ),
    .credit_id_i            ( floo_rsp_i.credit_id[NumVCWidth-1:0]  ),
    .consume_credit_valid_i ( floo_rsp_o.valid                      ),
    .consume_credit_id_i    ( floo_rsp_vc_id[NumVCWidth-1:0]        ),
    .vc_not_full_o          ( floo_rsp_vc_not_full                  )
  );

  floo_credit_counter #(
    .NumVC          ( NumVC           ),
    .VCIdxWidthMax  ( NumVCWidth      ),
    .VCDepth        ( VCDepth         ),
    .DeeperVCId     ( WormholeVCId    ),
    .DeeperVCDepth  ( WormholeVCDepth )
  ) i_floo_wide_credit_counter (
    .clk_i,
    .rst_ni,
    .credit_valid_i         ( floo_wide_i.credit_v                  ),
    .credit_id_i            ( floo_wide_i.credit_id[NumVCWidth-1:0] ),
    .consume_credit_valid_i ( floo_wide_o.valid                     ),
    .consume_credit_id_i    ( floo_wide_vc_id[NumVCWidth-1:0]       ),
    .vc_not_full_o          ( floo_wide_vc_not_full                 )
  );


  ////////////////////
  // CREDIT FREEING //
  ////////////////////

  // free credits when freeing a spot in the input buffer
  // id is always 0 since there is only one input buffer
  assign floo_req_o.credit_id  = '0;
  assign floo_rsp_o.credit_id  = '0;
  assign floo_wide_o.credit_id = '0;

  // free credit when spill register is read: when valid and output ready
  assign floo_req_o.credit_v  = floo_req_out_ready & floo_req_in_valid;
  assign floo_rsp_o.credit_v  = floo_rsp_out_ready & floo_rsp_in_valid;
  assign floo_wide_o.credit_v = floo_wide_out_ready & floo_wide_in_valid;


  ////////////////////////////////
  // VC SELECTION / ASSIGNMENT  //
  ////////////////////////////////

  // VC selection
  // find correct vc for each possible output dir, runs before/during arbiter
  for(genvar vc = 0; vc < NumVC; vc++) begin : gen_FVADA
    always_comb begin
      floo_req_vc_selection_v  [vc]      = '0;
      floo_req_vc_selection_id [vc]      = '0;
      floo_rsp_vc_selection_v  [vc]      = '0;
      floo_rsp_vc_selection_id [vc]      = '0;
      floo_wide_vc_selection_v  [vc]      = '0;
      floo_wide_vc_selection_id [vc]      = '0;
      if(floo_req_vc_not_full[vc]) begin // the preferred output port vc has space
        floo_req_vc_selection_v  [vc]    = 1'b1;
        floo_req_vc_selection_id [vc]    = vc[NumVCWidth-1:0];
      end else begin // the preferred output port vc has no space, try other vc
        for(int o_vc = 0; o_vc < NumVC; o_vc++) begin
          if(AllowVCOverflow && o_vc != vc) begin
            if(floo_req_vc_not_full[o_vc]) begin
              floo_req_vc_selection_v [vc] = 1'b1;
              floo_req_vc_selection_id[vc] = o_vc[NumVCWidth-1:0];
            end
          end
        end
      end
      if(floo_rsp_vc_not_full[vc]) begin // the preferred output port vc has space
        floo_rsp_vc_selection_v  [vc]    = 1'b1;
        floo_rsp_vc_selection_id [vc]    = vc[NumVCWidth-1:0];
      end else begin // the preferred output port vc has no space, try other vc
        for(int o_vc = 0; o_vc < NumVC; o_vc++) begin
          if(AllowVCOverflow && o_vc != vc) begin
            if(floo_rsp_vc_not_full[o_vc]) begin
              floo_rsp_vc_selection_v [vc] = 1'b1;
              floo_rsp_vc_selection_id[vc] = o_vc[NumVCWidth-1:0];
            end
          end
        end
      end
      if(floo_wide_vc_not_full[vc]) begin // the preferred output port vc has space
        floo_wide_vc_selection_v  [vc]    = 1'b1;
        floo_wide_vc_selection_id [vc]    = vc[NumVCWidth-1:0];
      end else begin // the preferred output port vc has no space, try other vc
        for(int o_vc = 0; o_vc < NumVC; o_vc++) begin
          if(AllowVCOverflow && o_vc != vc) begin
            if(floo_wide_vc_not_full[o_vc]) begin
              floo_wide_vc_selection_v [vc] = 1'b1;
              floo_wide_vc_selection_id[vc] = o_vc[NumVCWidth-1:0];
            end
          end
        end
      end
    end
  end

  // VC assignment
  // runs after arb & lookahead
  // Issue: this chimney might not be the only chimney connected to the router
  // Other Issue: if not connected to Eject, it is somewhat complicated:
  // N: S,Ej, E: N,S,W,Ej, S: N,Ej, W: N,E,S,Ej
  assign floo_req_pref_vc_id = (OutputDir >= Eject ?
        (floo_req_lookahead > OutputDir ? floo_req_lookahead - 1 : floo_req_lookahead) :
        floo_req_lookahead >= Eject ?
          (floo_req_lookahead - Eject + (OutputDir==North || OutputDir==South ? 1: 3)) :
          OutputDir==North || OutputDir==South ? 0 :
          floo_req_lookahead==North ? 0 :
          floo_req_lookahead==South ? (OutputDir==East ? 1 : 2) :
          OutputDir==East ? 2 : 1) % NumVC;
  always_comb begin
    if(FixedWormholeVC==1 && (~floo_req_arb_sel_hdr.last | floo_req_wh_valid)) begin
      floo_req_vc_id = WormholeVCId;
      floo_req_o.valid = floo_req_arb_v & (floo_req_vc_not_full[WormholeVCId] |
          (CreditShortcut==1 && floo_req_i.credit_v && floo_req_i.credit_id == WormholeVCId));
    end else begin
      if(CreditShortcut==1&&floo_req_i.credit_v &&floo_req_i.credit_id == floo_req_pref_vc_id) begin
        floo_req_vc_id = floo_req_pref_vc_id;
        floo_req_o.valid = floo_req_arb_v;
      end else begin
        floo_req_vc_id =
          {{($bits(vc_id_t)-NumVCWidth){1'b0}}, floo_req_vc_selection_id[floo_req_pref_vc_id]};
        // need the assigned vc_id to be the preffered one if not last or wormhole
        floo_req_o.valid  = floo_req_vc_selection_v[floo_req_pref_vc_id] & floo_req_arb_v
            & (FixedWormholeVC==1 | ~(~floo_req_arb_sel_hdr.last | floo_req_wh_valid) |
            (floo_req_vc_id == floo_req_pref_vc_id));
      end
    end
  end

  assign floo_rsp_pref_vc_id = (OutputDir >= Eject ?
        (floo_rsp_lookahead > OutputDir ? floo_rsp_lookahead - 1 : floo_rsp_lookahead) :
        floo_rsp_lookahead >= Eject ?
          (floo_rsp_lookahead - Eject + (OutputDir==North || OutputDir==South ? 1: 3)) :
          OutputDir==North || OutputDir==South ? 0 :
          floo_rsp_lookahead==North ? 0 :
          floo_rsp_lookahead==South ? (OutputDir==East ? 1 : 2) :
          OutputDir==East ? 2 : 1) % NumVC;
  always_comb begin
    if(FixedWormholeVC==1 && (~floo_rsp_arb_sel_hdr.last | floo_rsp_wh_valid)) begin
      floo_rsp_vc_id = WormholeVCId;
      floo_rsp_o.valid = floo_rsp_arb_v & (floo_rsp_vc_not_full[WormholeVCId] |
          (CreditShortcut==1 && floo_rsp_i.credit_v && floo_rsp_i.credit_id == WormholeVCId));
    end else begin
      if(CreditShortcut==1&&floo_rsp_i.credit_v &&floo_rsp_i.credit_id == floo_rsp_pref_vc_id) begin
        floo_rsp_vc_id = floo_rsp_pref_vc_id;
        floo_rsp_o.valid = floo_rsp_arb_v;
      end else begin
        floo_rsp_vc_id =
          {{($bits(vc_id_t)-NumVCWidth){1'b0}}, floo_rsp_vc_selection_id[floo_rsp_pref_vc_id]};
        // need the assigned vc_id to be the preffered one if not last or wormhole
        floo_rsp_o.valid  = floo_rsp_vc_selection_v[floo_rsp_pref_vc_id] & floo_rsp_arb_v
            & (FixedWormholeVC==1 | ~(~floo_rsp_arb_sel_hdr.last | floo_rsp_wh_valid) |
            (floo_rsp_vc_id == floo_rsp_pref_vc_id));
      end
    end
  end

  assign floo_wide_pref_vc_id = (OutputDir >= Eject ?
        (floo_wide_lookahead > OutputDir ? floo_wide_lookahead - 1 : floo_wide_lookahead) :
        floo_wide_lookahead >= Eject ?
          (floo_wide_lookahead - Eject + (OutputDir==North || OutputDir==South ? 1: 3)) :
          OutputDir==North || OutputDir==South ? 0 :
          floo_wide_lookahead==North ? 0 :
          floo_wide_lookahead==South ? (OutputDir==East ? 1 : 2) :
          OutputDir==East ? 2 : 1) % NumVC;
  always_comb begin
    if(FixedWormholeVC==1 && (~floo_wide_arb_sel_hdr.last | floo_wide_wh_valid)) begin
      floo_wide_vc_id = WormholeVCId;
      floo_wide_o.valid = floo_wide_arb_v & (floo_wide_vc_not_full[WormholeVCId] |
          (CreditShortcut==1 && floo_wide_i.credit_v && floo_wide_i.credit_id == WormholeVCId));
    end else begin
      if(CreditShortcut==1&&floo_wide_i.credit_v&&floo_wide_i.credit_id==floo_wide_pref_vc_id) begin
        floo_wide_vc_id = floo_wide_pref_vc_id;
        floo_wide_o.valid = floo_wide_arb_v;
      end else begin
        floo_wide_vc_id =
          {{($bits(vc_id_t)-NumVCWidth){1'b0}}, floo_wide_vc_selection_id[floo_wide_pref_vc_id]};
        // need the assigned vc_id to be the preffered one if not last or wormhole
        floo_wide_o.valid  = floo_wide_vc_selection_v[floo_wide_pref_vc_id] & floo_wide_arb_v
            & (FixedWormholeVC==1 | ~(~floo_wide_arb_sel_hdr.last | floo_wide_wh_valid) |
            (floo_wide_vc_id == floo_wide_pref_vc_id));
      end
    end
  end

  //////////////////
  // WRITE HEADER //
  //////////////////

  always_comb begin
    floo_req_o.req.generic.hdr            = floo_req_sel_hdr;
    floo_req_o.req.generic.hdr.lookahead  = floo_req_lookahead;
    floo_req_o.req.generic.hdr.vc_id      = floo_req_vc_id;

    floo_rsp_o.rsp.generic.hdr            = floo_rsp_sel_hdr;
    floo_rsp_o.rsp.generic.hdr.lookahead  = floo_rsp_lookahead;
    floo_rsp_o.rsp.generic.hdr.vc_id      = floo_rsp_vc_id;

    floo_wide_o.wide.generic.hdr          = floo_wide_sel_hdr;
    floo_wide_o.wide.generic.hdr.lookahead = floo_wide_lookahead;
    floo_wide_o.wide.generic.hdr.vc_id    = floo_wide_vc_id;
  end

  ////////////////////////
  // WORMHOLE DETECTION //
  ////////////////////////

  assign floo_req_wh_detect = ~floo_req_o.req.generic.hdr.last & floo_req_o.valid;
  assign floo_req_wh_valid_d = floo_req_wh_detect | (floo_req_wh_valid &
                                ~(floo_req_o.req.generic.hdr.last & floo_req_o.valid));
  assign floo_rsp_wormhole_detected = ~floo_rsp_o.rsp.generic.hdr.last & floo_rsp_o.valid;
  assign floo_rsp_wh_valid_d = floo_rsp_wormhole_detected | (floo_rsp_wh_valid &
                                ~(floo_rsp_o.rsp.generic.hdr.last & floo_rsp_o.valid));
  assign floo_wide_wormhole_detected = ~floo_wide_o.wide.generic.hdr.last & floo_wide_o.valid;
  assign floo_wide_wh_valid_d = floo_wide_wormhole_detected | (floo_wide_wh_valid &
                                ~(floo_wide_o.wide.generic.hdr.last & floo_wide_o.valid));
  `FF(floo_req_wh_valid, floo_req_wh_valid_d, '0)
  `FF(floo_rsp_wh_valid, floo_rsp_wh_valid_d, '0)
  `FF(floo_wide_wh_valid, floo_wide_wh_valid_d, '0)

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

  assign axi_narrow_unpack_aw = floo_req_in.narrow_aw.payload;
  assign axi_narrow_unpack_w  = floo_req_in.narrow_w.payload;
  assign axi_narrow_unpack_ar = floo_req_in.narrow_ar.payload;
  assign axi_narrow_unpack_r  = floo_rsp_in.narrow_r.payload;
  assign axi_narrow_unpack_b  = floo_rsp_in.narrow_b.payload;
  assign axi_wide_unpack_aw   = floo_wide_in.wide_aw.payload;
  assign axi_wide_unpack_w    = floo_wide_in.wide_w.payload;
  assign axi_wide_unpack_ar   = floo_req_in.wide_ar.payload;
  assign axi_wide_unpack_r    = floo_wide_in.wide_r.payload;
  assign axi_wide_unpack_b    = floo_rsp_in.wide_b.payload;
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
  assign axi_valid_in[NarrowB]  = ChimneyCfgN.EnMgrPort && floo_rsp_in_valid &&
                                  (floo_rsp_unpack_generic.hdr.axi_ch  == NarrowB);
  assign axi_valid_in[NarrowR]  = ChimneyCfgN.EnMgrPort && floo_rsp_in_valid &&
                                  (floo_rsp_unpack_generic.hdr.axi_ch  == NarrowR);
  assign axi_valid_in[WideB]    = ChimneyCfgW.EnMgrPort && floo_rsp_in_valid &&
                                  (floo_rsp_unpack_generic.hdr.axi_ch  == WideB);
  assign axi_valid_in[WideAw]   = floo_wide_in_valid &&
                                  (floo_wide_unpack_generic.hdr.axi_ch == WideAw);
  assign axi_valid_in[WideW]    = floo_wide_in_valid &&
                                  (floo_wide_unpack_generic.hdr.axi_ch  == WideW);
  assign axi_valid_in[WideR]    = ChimneyCfgW.EnMgrPort && floo_wide_in_valid &&
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
    b_ready   : floo_rsp_arb_gnt[NarrowB],
    ar        : axi_narrow_unpack_ar,
    ar_valid  : axi_valid_in[NarrowAr],
    r_ready   : floo_rsp_arb_gnt[NarrowR]
  };

  assign axi_wide_meta_buf_req_in ='{
    aw        : axi_wide_unpack_aw,
    aw_valid  : axi_valid_in[WideAw],
    w         : axi_wide_unpack_w,
    w_valid   : axi_valid_in[WideW],
    b_ready   : floo_rsp_arb_gnt[WideB],
    ar        : axi_wide_unpack_ar,
    ar_valid  : axi_valid_in[WideAr],
    r_ready   : floo_wide_arb_gnt[WideR]
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

  assign narrow_aw_buf_hdr_in = '{
    id: axi_narrow_unpack_aw.id,
    hdr: floo_req_unpack_generic.hdr
  };
  assign narrow_ar_buf_hdr_in = '{
    id: (is_atop && atop_has_r_rsp)? axi_narrow_unpack_aw.id : axi_narrow_unpack_ar.id,
    hdr: floo_req_unpack_generic.hdr
  };
  assign wide_aw_buf_hdr_in = '{
    id: axi_wide_unpack_aw.id,
    hdr: floo_wide_unpack_generic.hdr
  };
  assign wide_ar_buf_hdr_in = '{
    id: axi_wide_unpack_ar.id,
    hdr: floo_req_unpack_generic.hdr
  };

  if (ChimneyCfgN.EnSbrPort) begin : gen_narrow_mgr_port
    floo_meta_buffer #(
      .InIdWidth      ( AxiCfgN.InIdWidth         ),
      .OutIdWidth     ( AxiCfgN.OutIdWidth        ),
      .MaxTxns        ( ChimneyCfgN.MaxTxns       ),
      .MaxUniqueIds   ( ChimneyCfgN.MaxUniqueIds  ),
      .AtopSupport    ( AtopSupport               ),
      .MaxAtomicTxns  ( MaxAtomicTxns             ),
      .buf_t          ( narrow_meta_buf_t         ),
      .axi_in_req_t   ( axi_narrow_in_req_t       ),
      .axi_in_rsp_t   ( axi_narrow_in_rsp_t       ),
      .axi_out_req_t  ( axi_narrow_out_req_t      ),
      .axi_out_rsp_t  ( axi_narrow_out_rsp_t      ),
      .axi_aw_chan_t  ( axi_narrow_aw_chan_t      )
    ) i_narrow_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .axi_req_i  ( axi_narrow_meta_buf_req_in  ),
      .axi_rsp_o  ( axi_narrow_meta_buf_rsp_out ),
      .axi_req_o  ( axi_narrow_out_req_o        ),
      .axi_rsp_i  ( axi_narrow_out_rsp_i        ),
      .aw_buf_i   ( narrow_aw_buf_hdr_in        ),
      .ar_buf_i   ( narrow_ar_buf_hdr_in        ),
      .r_buf_o    ( narrow_ar_buf_hdr_out       ),
      .b_buf_o    ( narrow_aw_buf_hdr_out       )
    );
  end else begin : gen_no_narrow_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiCfgN.InIdWidth   ),
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
    assign axi_narrow_out_req_o = '0;
    assign narrow_ar_buf_hdr_out = '0;
    assign narrow_aw_buf_hdr_out = '0;
  end

  if (ChimneyCfgW.EnSbrPort) begin : gen_wide_mgr_port
    floo_meta_buffer #(
      .InIdWidth      ( AxiCfgW.InIdWidth         ),
      .OutIdWidth     ( AxiCfgW.OutIdWidth        ),
      .MaxTxns        ( ChimneyCfgW.MaxTxns       ),
      .MaxUniqueIds   ( ChimneyCfgW.MaxUniqueIds  ),
      .AtopSupport    ( 1'b0                      ),
      .MaxAtomicTxns  ( '0                        ),
      .buf_t          ( wide_meta_buf_t           ),
      .axi_in_req_t   ( axi_wide_in_req_t         ),
      .axi_in_rsp_t   ( axi_wide_in_rsp_t         ),
      .axi_out_req_t  ( axi_wide_out_req_t        ),
      .axi_out_rsp_t  ( axi_wide_out_rsp_t        ),
      .axi_aw_chan_t  ( axi_wide_aw_chan_t        )
    ) i_wide_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .axi_req_i  ( axi_wide_meta_buf_req_in  ),
      .axi_rsp_o  ( axi_wide_meta_buf_rsp_out ),
      .axi_req_o  ( axi_wide_out_req_o        ),
      .axi_rsp_i  ( axi_wide_out_rsp_i        ),
      .aw_buf_i   ( wide_aw_buf_hdr_in        ),
      .ar_buf_i   ( wide_ar_buf_hdr_in        ),
      .r_buf_o    ( wide_ar_buf_hdr_out       ),
      .b_buf_o    ( wide_aw_buf_hdr_out       )
    );
  end else begin : gen_no_wide_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiCfgN.InIdWidth ),
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
    assign axi_wide_out_req_o = '0;
    assign wide_ar_buf_hdr_out = '0;
    assign wide_aw_buf_hdr_out = '0;
  end

  // Registers
  `FF(b_rob_pending_q, narrow_b_rob_valid_out && !narrow_b_rob_ready_in && !is_atop_b_rsp, '0)
  `FF(r_rob_pending_q, narrow_r_rob_valid_out && !narrow_r_rob_ready_in && !is_atop_r_rsp, '0)


  /////////////////
  // ASSERTIONS  //
  /////////////////

  // Check that the Address Width of the narrow and Wide interfaces are the same
  `ASSERT_INIT(AddrWidthMatch, AxiCfgN.AddrWidth == AxiCfgW.AddrWidth)

  // Multiple outstanding atomics need to use different IDs
  // Non-atomic transactions all use the same ID
  `ASSERT_INIT(ToSmallIdWidth, 1 + AtopSupport * MaxAtomicTxns <= 2**AxiCfgN.OutIdWidth)

  // If Network Interface has no subordinate port, make sure that `RoBType` is `NoRoB`
  `ASSERT_INIT(NoNarrowMgrPortRobType, ChimneyCfgN.EnMgrPort ||
               (ChimneyCfgN.BRoBType == floo_pkg::NoRoB &&
                ChimneyCfgN.RRoBType == floo_pkg::NoRoB))
  `ASSERT_INIT(NoWideMgrPortRobType, ChimneyCfgW.EnMgrPort ||
               (ChimneyCfgW.BRoBType == floo_pkg::NoRoB &&
                ChimneyCfgW.RRoBType == floo_pkg::NoRoB))

  // Network Interface cannot accept any B and R responses if `En*MgrPort` are not set
  `ASSERT(NoNarrowMgrPortBResponse, ChimneyCfgN.EnMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == NarrowB)))
  `ASSERT(NoNarrowMgrPortRResponse, ChimneyCfgN.EnMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == NarrowR)))
  `ASSERT(NoWideMgrPortBResponse, ChimneyCfgW.EnMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == WideB)))
  `ASSERT(NoWideMgrPortRResponse, ChimneyCfgW.EnMgrPort || !(floo_wide_in_valid &&
                           (floo_wide_unpack_generic.hdr.axi_ch == WideR)))
  // Network Interface cannot accept any AW, AR and W requests if `En*SbrPort` is not set
  `ASSERT(NoNarrowSbrPortAwRequest, ChimneyCfgN.EnSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == NarrowAw)))
  `ASSERT(NoNarrowSbrPortArRequest, ChimneyCfgN.EnSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == NarrowAr)))
  `ASSERT(NoNarrowSbrPortWRequest,  ChimneyCfgN.EnSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == NarrowW)))
  `ASSERT(NoWideSbrPortAwRequest, ChimneyCfgW.EnSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == WideAw)))
  `ASSERT(NoWideSbrPortArRequest, ChimneyCfgW.EnSbrPort || !(floo_req_in_valid &&
                           (floo_req_unpack_generic.hdr.axi_ch == WideAr)))
  `ASSERT(NoWideSbrPortWRequest,  ChimneyCfgW.EnSbrPort || !(floo_wide_in_valid &&
                           (floo_wide_unpack_generic.hdr.axi_ch == WideW)))
  // all inputs need to go to vc 0 since there is only one vc
  `ASSERT(OnlyVC0Req, floo_req_i.req.generic.hdr.vc_id == '0 || !floo_req_i.valid)
  `ASSERT(OnlyVC0Rsp, floo_rsp_i.rsp.generic.hdr.vc_id == '0 || !floo_rsp_i.valid)
  `ASSERT(OnlyVC0Wide, floo_wide_i.wide.generic.hdr.vc_id == '0 || !floo_wide_i.valid)

endmodule
