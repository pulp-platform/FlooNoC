// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>
// Lorenzo Leone <lleone@iis.ee.ethz.ch>
// Chen Wu <chenwu@student.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

/// A bidirectional network interface for connecting narrow & wide AXI Buses to the multi-link NoC
module floo_nw_chimney #(
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
  /// Enable support for decoupling read and write channels
  parameter bit EnDecoupledRW                      = 1'b0,
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
  /// SAM Index type to support multicast info
  parameter type sam_idx_t                              = id_t,
  /// Struct consisting of offset and len to speficy the position of the mask bits
  /// (only used if `EnMultiCast && RouteCfg.UseIdTable == 1'b1 && RouteCfg.RouteAlgo == XYRouting`)
  parameter type mask_sel_t                             = logic,
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
  parameter type floo_req_t                             = logic,
  /// Floo `rsp` link type
  parameter type floo_rsp_t                             = logic,
  /// Floo `wide` link type
  parameter type floo_wide_t                            = logic,
  /// SRAM configuration type `tc_sram_impl` in RoB
  /// Only used if technology-dependent SRAM is used
  parameter type sram_cfg_t                             = logic,
  /// Struct for the narrow user field in AXI
  parameter type user_narrow_struct_t                   = logic,
  /// Struct for the wide user field in AXI
  parameter type user_wide_struct_t                     = logic
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
  /// Output links to NoC
  output floo_req_t   floo_req_o,
  output floo_rsp_t   floo_rsp_o,
  output floo_wide_t  floo_wide_o,
  /// Input links from NoC
  input  floo_req_t   floo_req_i,
  input  floo_rsp_t   floo_rsp_i,
  input  floo_wide_t  floo_wide_i
);

  import floo_pkg::*;

  typedef logic [AxiCfgN.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfgN.InIdWidth-1:0] axi_narrow_in_id_t;
  typedef logic [AxiCfgN.OutIdWidth-1:0] axi_narrow_out_id_t;
  typedef logic [AxiCfgN.UserWidth-1:0] axi_narrow_user_t;
  typedef logic [AxiCfgN.DataWidth-1:0] axi_narrow_data_t;
  typedef logic [AxiCfgN.DataWidth/8-1:0] axi_narrow_strb_t;
  typedef logic [AxiCfgW.InIdWidth-1:0] axi_wide_in_id_t;
  typedef logic [AxiCfgW.OutIdWidth-1:0] axi_wide_out_id_t;
  typedef logic [AxiCfgW.UserWidth-1:0] axi_wide_user_t;
  typedef logic [AxiCfgW.DataWidth-1:0] axi_wide_data_t;
  typedef logic [AxiCfgW.DataWidth/8-1:0] axi_wide_strb_t;

  // (Re-) definitons of `axi_in` and `floo` types, for transport
  `AXI_TYPEDEF_ALL_CT(axi_narrow, axi_narrow_req_t, axi_narrow_rsp_t, axi_addr_t,
      axi_narrow_in_id_t, axi_narrow_data_t, axi_narrow_strb_t, axi_narrow_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide, axi_wide_req_t, axi_wide_rsp_t, axi_addr_t,
      axi_wide_in_id_t, axi_wide_data_t, axi_wide_strb_t, axi_wide_user_t)
  `AXI_TYPEDEF_AW_CHAN_T(axi_wide_out_aw_chan_t, axi_addr_t, axi_wide_out_id_t, axi_wide_user_t)
  `AXI_TYPEDEF_AW_CHAN_T(axi_narrow_out_aw_chan_t, axi_addr_t,
                         axi_narrow_out_id_t, axi_narrow_user_t)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow, axi_wide, AxiCfgN, AxiCfgW, hdr_t)

  // Type of the mask encoded in the user field.
  // It's always equal to the address field.
  // For future extension, add an extra opcode in the user_narrow_struct_t
  typedef axi_addr_t user_mask_t ;

  // Virtual channel enumeration
  typedef enum logic {
    VC_RD = 1'b1,
    VC_WR = 1'b0
  } vc_e;

  // Collective communication configuration
  localparam floo_pkg::collect_op_cfg_t CollectOpCfg = RouteCfg.CollectiveCfg.OpCfg;
  localparam int unsigned NumVirtualChannels = EnDecoupledRW ? 2 : 1;

  // Duplicate AXI port signals to degenerate ports
  // in case they are not used
  axi_narrow_req_t axi_narrow_req_in;
  axi_narrow_rsp_t axi_narrow_rsp_out;
  axi_wide_req_t axi_wide_req_in;
  axi_wide_rsp_t axi_wide_rsp_out;
  user_mask_t axi_narrow_req_in_mask, axi_wide_req_in_mask;
  floo_pkg::collect_op_e axi_narrow_req_in_red_op;
  floo_pkg::collect_op_e axi_wide_req_in_red_op;

  // AX queue
  axi_narrow_aw_chan_t axi_narrow_aw_queue;
  axi_narrow_ar_chan_t axi_narrow_ar_queue;
  axi_wide_aw_chan_t axi_wide_aw_queue;
  axi_wide_ar_chan_t axi_wide_ar_queue;
  logic axi_narrow_aw_queue_valid_out, axi_narrow_aw_queue_ready_in;
  logic axi_narrow_ar_queue_valid_out, axi_narrow_ar_queue_ready_in;
  logic axi_wide_aw_queue_valid_out, axi_wide_aw_queue_ready_in;
  logic axi_wide_ar_queue_valid_out, axi_wide_ar_queue_ready_in;
  user_mask_t axi_narrow_mask_queue, axi_wide_mask_queue;
  floo_pkg::collect_op_e axi_narrow_red_op_queue;
  floo_pkg::collect_op_e axi_wide_red_op_queue;

  // AXI req/rsp arbiter
  floo_req_chan_t [WideAr:NarrowAw] floo_req_arb_in;
  floo_rsp_chan_t [WideB:NarrowB] floo_rsp_arb_in;
  floo_wide_chan_t [WideR:WideAw] floo_wide_arb_in;
  logic  [WideAr:NarrowAw] floo_req_arb_req_in, floo_req_arb_gnt_out;
  logic  [WideB:NarrowB]   floo_rsp_arb_req_in, floo_rsp_arb_gnt_out;
  logic  [WideR:WideAw]    floo_wide_arb_req_in, floo_wide_arb_gnt_out;

  // flit queue
  floo_req_chan_t floo_req_in;
  floo_rsp_chan_t floo_rsp_in;
  floo_wide_chan_t floo_wide_in_q;
  logic floo_req_in_valid, floo_rsp_in_valid, floo_wide_in_valid_q;
  logic floo_req_out_ready, floo_rsp_out_ready, floo_wide_out_ready_q;
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
  floo_wide_generic_flit_t  floo_wide_unpack_generic_rd;
  floo_wide_generic_flit_t  floo_wide_unpack_generic_wr;

  // Meta Buffers
  axi_narrow_req_t axi_narrow_meta_buf_req_in;
  axi_narrow_rsp_t axi_narrow_meta_buf_rsp_out;
  axi_narrow_out_req_t axi_narrow_meta_buf_req_out;
  axi_narrow_out_rsp_t axi_narrow_meta_buf_rsp_in;
  axi_wide_req_t   axi_wide_meta_buf_req_in;
  axi_wide_rsp_t   axi_wide_meta_buf_rsp_out;
  axi_wide_out_req_t  axi_wide_meta_buf_req_out;
  axi_wide_out_rsp_t  axi_wide_meta_buf_rsp_in;

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
  id_t narrow_aw_mask_q, wide_aw_mask_q;
  id_t [NumNWAxiChannels-1:0] collective_mask;
  id_t [NumNWAxiChannels-1:0] id_out;
  id_t [NumNWAxiChannels-1:0] mask_id;


  narrow_meta_buf_t narrow_aw_buf_hdr_in, narrow_aw_buf_hdr_out;
  narrow_meta_buf_t narrow_ar_buf_hdr_in, narrow_ar_buf_hdr_out;
  wide_meta_buf_t wide_aw_buf_hdr_in, wide_aw_buf_hdr_out;
  wide_meta_buf_t wide_ar_buf_hdr_in, wide_ar_buf_hdr_out;

  // Virtual channel signals to decouple wide AW from wide AR
  logic floo_wide_req_arb_gnt_in, floo_wide_req_arb_valid_out;

  /////////////////////////////
  //  Virtual channel demux  //
  /////////////////////////////

  // VCs must be demuxed *before* the spill registers to avoid
  // head-of-line blocking between read and write channels.

  floo_wide_chan_t floo_wide_in_wr, floo_wide_in_rd;
  logic floo_wide_in_wr_valid, floo_wide_in_rd_valid;
  logic floo_wide_out_wr_ready, floo_wide_out_rd_ready;

  floo_wide_chan_t floo_wide_in;
  logic floo_wide_in_valid;
  logic floo_wide_out_ready;

  if (EnDecoupledRW) begin : gen_vc_demux
    assign floo_wide_in_wr_valid = floo_wide_i.valid[VC_WR] && (floo_wide_i.wide.generic.hdr.axi_ch != WideR);
    assign floo_wide_in_rd_valid = floo_wide_i.valid[VC_RD] && (floo_wide_i.wide.generic.hdr.axi_ch == WideR);
    assign floo_wide_o.ready[VC_WR] = floo_wide_out_wr_ready;
    assign floo_wide_o.ready[VC_RD] = floo_wide_out_rd_ready;
    assign floo_wide_in_wr = floo_wide_i.wide;
    assign floo_wide_in_rd = floo_wide_i.wide;
  end else begin : gen_no_vc_demux
    assign floo_wide_in = floo_wide_i.wide;
    assign floo_wide_in_valid = floo_wide_i.valid;
    assign floo_wide_o.ready = floo_wide_out_ready;
  end

  ///////////////////////
  //  Spill registers  //
  ///////////////////////

  if (ChimneyCfgN.EnMgrPort) begin : gen_narrow_sbr_port
    // We cast the incoming AXI types to the ones that are actually transported
    // If multicast is enabled, the bits holding the mask are dropped.
    `AXI_ASSIGN_REQ_STRUCT(axi_narrow_req_in, axi_narrow_in_req_i)
    `AXI_ASSIGN_RESP_STRUCT(axi_narrow_in_rsp_o, axi_narrow_rsp_out)

    // Extract the collective mask and opcode bits from the narrow AXI user bits
    if (is_en_narrow_collective(CollectOpCfg)) begin : gen_narrow_collective_info
      user_narrow_struct_t user;
      assign user = axi_narrow_in_req_i.aw.user;
      assign axi_narrow_req_in_mask = user.collective_mask;
      assign axi_narrow_req_in_red_op = user.collective_op;
    end else begin : gen_no_narrow_collective_info
      assign axi_narrow_req_in_mask = '0;
      assign axi_narrow_req_in_red_op = floo_pkg::collect_op_e'('0);
    end

    if (ChimneyCfgN.CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_narrow_aw_chan_t )
      ) i_narrow_aw_queue (
        .clk_i,
        .rst_ni,
        .data_i   ( axi_narrow_req_in.aw        ),
        .valid_i  ( axi_narrow_req_in.aw_valid  ),
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
        .data_i   ( axi_narrow_req_in.ar        ),
        .valid_i  ( axi_narrow_req_in.ar_valid  ),
        .ready_o  ( axi_narrow_rsp_out.ar_ready   ),
        .data_o   ( axi_narrow_ar_queue           ),
        .valid_o  ( axi_narrow_ar_queue_valid_out ),
        .ready_i  ( axi_narrow_ar_queue_ready_in  )
      );

      if (is_en_narrow_collective(CollectOpCfg)) begin : gen_collective_cuts
        spill_register #(
          .T (user_mask_t)
        ) i_narrow_usermask_queue (
          .clk_i,
          .rst_ni,
          .data_i   ( axi_narrow_req_in_mask ),
          .valid_i  ( axi_narrow_req_in.aw_valid ),
          .ready_o  (  ),
          .data_o   ( axi_narrow_mask_queue ),
          .valid_o  (  ),
          .ready_i  ( axi_narrow_aw_queue_ready_in )
        );
        spill_register #(
          .T (floo_pkg::collect_op_e)
        ) i_coll_operation_queue (
          .clk_i,
          .rst_ni,
          .data_i   ( axi_narrow_req_in_red_op ),
          .valid_i  ( axi_narrow_req_in.aw_valid ),
          .ready_o  (  ),
          .data_o   ( axi_narrow_red_op_queue ),
          .valid_o  (  ),
          .ready_i  ( axi_narrow_aw_queue_ready_in )
        );
      end else begin : gen_no_collective_cuts
        assign axi_narrow_mask_queue = '0;
        assign axi_narrow_red_op_queue = floo_pkg::collect_op_e'('0);
      end
    end else begin : gen_ax_no_cuts
      assign axi_narrow_aw_queue = axi_narrow_req_in.aw;
      assign axi_narrow_aw_queue_valid_out = axi_narrow_req_in.aw_valid;
      assign axi_narrow_rsp_out.aw_ready = axi_narrow_aw_queue_ready_in;
      assign axi_narrow_ar_queue = axi_narrow_req_in.ar;
      assign axi_narrow_ar_queue_valid_out = axi_narrow_req_in.ar_valid;
      assign axi_narrow_rsp_out.ar_ready = axi_narrow_ar_queue_ready_in;
      assign axi_narrow_mask_queue = axi_narrow_req_in_mask;
      assign axi_narrow_red_op_queue = axi_narrow_req_in_red_op;
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
    assign axi_narrow_mask_queue = '0;
    assign axi_narrow_red_op_queue = floo_pkg::collect_op_e'('0);
  end

  if (ChimneyCfgW.EnMgrPort) begin : gen_wide_sbr_port
    // We cast the incoming AXI types to the ones that are actually transported
    // If multicast is enabled, the bits holding the mask are dropped.
    `AXI_ASSIGN_REQ_STRUCT(axi_wide_req_in, axi_wide_in_req_i)
    `AXI_ASSIGN_RESP_STRUCT(axi_wide_in_rsp_o, axi_wide_rsp_out)

    // Extract the collective mask and opcode bits from the narrow AXI user bits
    if (is_en_wide_collective(CollectOpCfg)) begin : gen_wide_collective_info
      user_wide_struct_t user;
      assign user = axi_wide_in_req_i.aw.user;
      assign axi_wide_req_in_mask = user.collective_mask;
      assign axi_wide_req_in_red_op = user.collective_op;
    end else begin : gen_no_wide_collective_info
      assign axi_wide_req_in_mask = '0;
      assign axi_wide_req_in_red_op = floo_pkg::collect_op_e'('0);
    end

    if (ChimneyCfgW.CutAx) begin : gen_ax_cuts
      spill_register #(
        .T ( axi_wide_aw_chan_t )
      ) i_wide_aw_queue (
        .clk_i,
        .rst_ni,
        .data_i   ( axi_wide_req_in.aw          ),
        .valid_i  ( axi_wide_req_in.aw_valid    ),
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
        .data_i   ( axi_wide_req_in.ar          ),
        .valid_i  ( axi_wide_req_in.ar_valid    ),
        .ready_o  ( axi_wide_rsp_out.ar_ready   ),
        .data_o   ( axi_wide_ar_queue           ),
        .valid_o  ( axi_wide_ar_queue_valid_out ),
        .ready_i  ( axi_wide_ar_queue_ready_in  )
      );

      if (is_en_wide_collective(CollectOpCfg)) begin : gen_collective_cuts
        spill_register #(
          .T (user_mask_t)
        ) i_wide_usermask_queue (
          .clk_i,
          .rst_ni,
          .data_i   ( axi_wide_req_in_mask       ),
          .valid_i  ( axi_wide_req_in.aw_valid   ),
          .ready_o  (                            ),
          .data_o   ( axi_wide_mask_queue        ),
          .valid_o  (                            ),
          .ready_i  ( axi_wide_aw_queue_ready_in )
        );
        spill_register #(
          .T (floo_pkg::collect_op_e)
        ) i_coll_operation_queue (
          .clk_i,
          .rst_ni,
          .data_i   ( axi_wide_req_in_red_op ),
          .valid_i  ( axi_wide_req_in.aw_valid ),
          .ready_o  (  ),
          .data_o   ( axi_wide_red_op_queue ),
          .valid_o  (  ),
          .ready_i  ( axi_wide_aw_queue_ready_in )
        );
      end else begin : gen_no_collective_cuts
        assign axi_wide_mask_queue = '0;
        assign axi_wide_red_op_queue = floo_pkg::collect_op_e'('0);
      end

    end else begin : gen_ax_no_cuts
      assign axi_wide_aw_queue = axi_wide_req_in.aw;
      assign axi_wide_aw_queue_valid_out = axi_wide_req_in.aw_valid;
      assign axi_wide_rsp_out.aw_ready = axi_wide_aw_queue_ready_in;
      assign axi_wide_ar_queue = axi_wide_req_in.ar;
      assign axi_wide_ar_queue_valid_out = axi_wide_req_in.ar_valid;
      assign axi_wide_rsp_out.ar_ready = axi_wide_ar_queue_ready_in;
      assign axi_wide_mask_queue = axi_wide_req_in_mask;
      assign axi_wide_red_op_queue = axi_wide_req_in_red_op;
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
    assign axi_wide_mask_queue = '0;
    assign axi_wide_red_op_queue = floo_pkg::collect_op_e'('0);
  end

  spill_register #(
    .T      ( floo_req_chan_t ),
    .Bypass ( !(ChimneyCfgN.CutRsp && ChimneyCfgW.CutRsp) )
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
    .T      ( floo_rsp_chan_t ),
    .Bypass ( !(ChimneyCfgN.CutRsp && ChimneyCfgW.CutRsp) )
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

  floo_wide_chan_t floo_wide_in_wr_q, floo_wide_in_rd_q;
  logic floo_wide_in_wr_valid_q, floo_wide_in_rd_valid_q;
  logic floo_wide_out_wr_ready_q, floo_wide_out_rd_ready_q;

  if (EnDecoupledRW) begin : gen_spill_vc
    spill_register #(
      .T ( floo_wide_chan_t )
    ) i_wide_wr_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_wide_in_wr          ),
      .valid_i    ( floo_wide_in_wr_valid    ),
      .ready_o    ( floo_wide_out_wr_ready   ),
      .data_o     ( floo_wide_in_wr_q        ),
      .valid_o    ( floo_wide_in_wr_valid_q  ),
      .ready_i    ( floo_wide_out_wr_ready_q )
    );
    spill_register #(
      .T ( floo_wide_chan_t )
    ) i_wide_rd_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_wide_in_rd          ),
      .valid_i    ( floo_wide_in_rd_valid    ),
      .ready_o    ( floo_wide_out_rd_ready   ),
      .data_o     ( floo_wide_in_rd_q        ),
      .valid_o    ( floo_wide_in_rd_valid_q  ),
      .ready_i    ( floo_wide_out_rd_ready_q )
    );
  end else begin : gen_spill_wide
    spill_register #(
      .T      ( floo_wide_chan_t ),
      .Bypass ( !(ChimneyCfgN.CutRsp && ChimneyCfgW.CutRsp) )
    ) i_wide_data_req_arb (
      .clk_i,
      .rst_ni,
      .data_i     ( floo_wide_in          ),
      .valid_i    ( floo_wide_in_valid    ),
      .ready_o    ( floo_wide_out_ready   ),
      .data_o     ( floo_wide_in_q        ),
      .valid_o    ( floo_wide_in_valid_q  ),
      .ready_i    ( floo_wide_out_ready_q )
    );
  end

  logic narrow_aw_out_queue_valid, narrow_aw_out_queue_ready;
  logic wide_aw_out_queue_valid, wide_aw_out_queue_ready;
  axi_narrow_out_aw_chan_t axi_narrow_aw_queue_out, axi_narrow_aw_queue_in;
  axi_wide_out_aw_chan_t axi_wide_aw_queue_out, axi_wide_aw_queue_in;

  `AXI_ASSIGN_AW_STRUCT(axi_narrow_aw_queue_in, axi_narrow_meta_buf_req_out.aw)
  `AXI_ASSIGN_AW_STRUCT(axi_wide_aw_queue_in, axi_wide_meta_buf_req_out.aw)

  // Since AW and W are transferred over the same link, it can happen that
  // a downstream module does not accept the AW until the W is valid.
  // Therefore, we need to add a spill register for the AW channel.
  spill_register #(
    .T (axi_narrow_out_aw_chan_t)
  ) i_aw_narrow_out_queue (
    .clk_i    ( clk_i                                 ),
    .rst_ni   ( rst_ni                                ),
    .valid_i  ( axi_narrow_meta_buf_req_out.aw_valid  ),
    .ready_o  ( narrow_aw_out_queue_ready             ),
    .data_i   ( axi_narrow_aw_queue_in                ),
    .valid_o  ( narrow_aw_out_queue_valid             ),
    .ready_i  ( axi_narrow_out_rsp_i.aw_ready         ),
    .data_o   ( axi_narrow_aw_queue_out               )
  );

  spill_register #(
    .T (axi_wide_out_aw_chan_t)
  ) i_aw_out_queue (
    .clk_i    ( clk_i                               ),
    .rst_ni   ( rst_ni                              ),
    .valid_i  ( axi_wide_meta_buf_req_out.aw_valid  ),
    .ready_o  ( wide_aw_out_queue_ready             ),
    .data_i   ( axi_wide_aw_queue_in                ),
    .valid_o  ( wide_aw_out_queue_valid             ),
    .ready_i  ( axi_wide_out_rsp_i.aw_ready         ),
    .data_o   ( axi_wide_aw_queue_out               )
  );


  if (is_en_narrow_collective(CollectOpCfg)) begin
    user_narrow_struct_t user_aw;
    user_narrow_struct_t user_w;

    always_comb begin
      axi_narrow_out_req_o = axi_narrow_meta_buf_req_out;
      axi_narrow_out_req_o.aw_valid = narrow_aw_out_queue_valid;
      `AXI_SET_AW_STRUCT(axi_narrow_out_req_o.aw, axi_narrow_aw_queue_out);
      axi_narrow_meta_buf_rsp_in = axi_narrow_out_rsp_i;
      axi_narrow_meta_buf_rsp_in.aw_ready = narrow_aw_out_queue_ready;
      // If the option is enabled: mask the collective operation bits here
      // Do it in this way so potential future fields are passed without any problems

      // Mask the AW Channel
      user_aw = axi_narrow_out_req_o.aw.user;
      user_aw.collective_mask = '0;
      user_aw.collective_op = Unicast;
      axi_narrow_out_req_o.aw.user = user_aw;
      // Mask the W Channel
      user_w = axi_narrow_out_req_o.w.user;
      user_w.collective_mask = '0;
      user_w.collective_op = Unicast;
      axi_narrow_out_req_o.w.user = user_w;
    end

  end else begin
    always_comb begin
      axi_narrow_out_req_o = axi_narrow_meta_buf_req_out;
      axi_narrow_out_req_o.aw_valid = narrow_aw_out_queue_valid;
      `AXI_SET_AW_STRUCT(axi_narrow_out_req_o.aw, axi_narrow_aw_queue_out);
      axi_narrow_meta_buf_rsp_in = axi_narrow_out_rsp_i;
      axi_narrow_meta_buf_rsp_in.aw_ready = narrow_aw_out_queue_ready;
    end
  end

  if (is_en_wide_collective(CollectOpCfg)) begin
    user_wide_struct_t user_aw;
    user_wide_struct_t user_w;
    always_comb begin
      axi_wide_out_req_o = axi_wide_meta_buf_req_out;
      axi_wide_out_req_o.aw_valid = wide_aw_out_queue_valid;
      `AXI_SET_AW_STRUCT(axi_wide_out_req_o.aw, axi_wide_aw_queue_out);
      axi_wide_meta_buf_rsp_in = axi_wide_out_rsp_i;
      axi_wide_meta_buf_rsp_in.aw_ready = wide_aw_out_queue_ready;
      // Mask the AW Channel
      user_aw = axi_wide_out_req_o.aw.user;
      user_aw.collective_mask = '0;
      user_aw.collective_op = Unicast;
      axi_wide_out_req_o.aw.user = user_aw;
      // Mask the W Channel
      user_w = axi_wide_out_req_o.w.user;
      user_w.collective_mask = '0;
      user_w.collective_op = Unicast;
      axi_wide_out_req_o.w.user = user_w;
    end
  end else begin
    always_comb begin
      axi_wide_out_req_o = axi_wide_meta_buf_req_out;
      axi_wide_out_req_o.aw_valid = wide_aw_out_queue_valid;
      `AXI_SET_AW_STRUCT(axi_wide_out_req_o.aw, axi_wide_aw_queue_out);
      axi_wide_meta_buf_rsp_in = axi_wide_out_rsp_i;
      axi_wide_meta_buf_rsp_in.aw_ready = wide_aw_out_queue_ready;
    end
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
    .RoBType        ( ChimneyCfgN.BRoBType      ),
    .RoBSize        ( ChimneyCfgN.BRoBSize      ),
    .MaxRoTxnsPerId ( ChimneyCfgN.MaxTxnsPerId  ),
    .OnlyMetaData   ( 1'b1                      ),
    .ax_len_t       ( axi_pkg::len_t            ),
    .ax_id_t        ( axi_narrow_in_id_t        ),
    .rsp_chan_t     ( axi_narrow_b_chan_t       ),
    .rsp_meta_t     ( axi_narrow_b_chan_t       ),
    .rob_idx_t      ( rob_idx_t                 ),
    .dest_t         ( id_t                      ),
    .sram_cfg_t     ( sram_cfg_t                )
  ) i_narrow_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( narrow_aw_rob_valid_in  ),
    .ax_ready_o     ( narrow_aw_rob_ready_out ),
    .ax_len_i       ( '0                      ), // B responses are single-beat
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
    .RoBType        ( ChimneyCfgW.BRoBType      ),
    .RoBSize        ( ChimneyCfgW.BRoBSize      ),
    .MaxRoTxnsPerId ( ChimneyCfgW.MaxTxnsPerId  ),
    .OnlyMetaData   ( 1'b1                      ),
    .ax_len_t       ( axi_pkg::len_t            ),
    .ax_id_t        ( axi_wide_in_id_t          ),
    .rsp_chan_t     ( axi_wide_b_chan_t         ),
    .rsp_meta_t     ( axi_wide_b_chan_t         ),
    .rob_idx_t      ( rob_idx_t                 ),
    .dest_t         ( id_t                      ),
    .sram_cfg_t     ( sram_cfg_t                )
  ) i_wide_b_rob (
    .clk_i,
    .rst_ni,
    .sram_cfg_i,
    .ax_valid_i     ( axi_wide_aw_queue_valid_out ),
    .ax_ready_o     ( axi_wide_aw_queue_ready_in  ),
    .ax_len_i       ( '0                          ), // B responses are single-beat
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
  } narrow_r_rob_meta_t;

  typedef struct packed {
    axi_wide_in_id_t  id;
    axi_wide_user_t   user;
    axi_pkg::resp_t   resp;
    logic             last;
  } wide_r_rob_meta_t;

  logic narrow_r_rob_rob_req;
  logic narrow_r_rob_last;
  rob_idx_t narrow_r_rob_rob_idx;
  assign narrow_r_rob_rob_req = floo_rsp_in.narrow_r.hdr.rob_req;
  assign narrow_r_rob_rob_idx = floo_rsp_in.narrow_r.hdr.rob_idx;
  assign narrow_r_rob_last = floo_rsp_in.narrow_r.payload.last;

  floo_rob_wrapper #(
    .RoBType        ( ChimneyCfgN.RRoBType      ),
    .RoBSize        ( ChimneyCfgN.RRoBSize      ),
    .MaxRoTxnsPerId ( ChimneyCfgN.MaxTxnsPerId  ),
    .OnlyMetaData   ( 1'b0                      ),
    .ax_len_t       ( axi_pkg::len_t            ),
    .ax_id_t        ( axi_narrow_in_id_t        ),
    .rsp_chan_t     ( axi_narrow_r_chan_t       ),
    .rsp_data_t     ( axi_narrow_data_t         ),
    .rsp_meta_t     ( narrow_r_rob_meta_t       ),
    .rob_idx_t      ( rob_idx_t                 ),
    .dest_t         ( id_t                      ),
    .sram_cfg_t     ( sram_cfg_t                )
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
  assign wide_r_rob_rob_req = floo_wide_in_rd_q.wide_r.hdr.rob_req;
  assign wide_r_rob_rob_idx = floo_wide_in_rd_q.wide_r.hdr.rob_idx;
  assign wide_r_rob_last = floo_wide_in_rd_q.wide_r.payload.last;

  floo_rob_wrapper #(
    .RoBType        ( ChimneyCfgW.RRoBType      ),
    .RoBSize        ( ChimneyCfgW.RRoBSize      ),
    .MaxRoTxnsPerId ( ChimneyCfgW.MaxTxnsPerId  ),
    .OnlyMetaData   ( 1'b0                      ),
    .ax_len_t       ( axi_pkg::len_t            ),
    .ax_id_t        ( axi_wide_in_id_t          ),
    .rsp_chan_t     ( axi_wide_r_chan_t         ),
    .rsp_data_t     ( axi_wide_data_t           ),
    .rsp_meta_t     ( wide_r_rob_meta_t         ),
    .rob_idx_t      ( rob_idx_t                 ),
    .dest_t         ( id_t                      ),
    .sram_cfg_t     ( sram_cfg_t                )
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
  user_mask_t [NumNWAxiChannels-1:0] axi_req_user;
  id_t [NumNWAxiChannels-1:0] axi_rsp_src_id;
  mask_sel_t [NumNWAxiChannels-1:0] x_mask_sel, y_mask_sel;

  floo_pkg::collect_op_e [NumNWAxiChannels-1:0] red_coll_operation;
  floo_pkg::collect_op_e red_narrow_coll_operation_q;
  floo_pkg::collect_op_e red_wide_coll_operation_q;

  assign axi_req_addr[NarrowAw] = axi_narrow_aw_queue.addr;
  assign axi_req_addr[NarrowAr] = axi_narrow_ar_queue.addr;
  assign axi_req_addr[WideAw]   = axi_wide_aw_queue.addr;
  assign axi_req_addr[WideAr]   = axi_wide_ar_queue.addr;

  assign axi_rsp_src_id[NarrowB] = narrow_aw_buf_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[NarrowR] = narrow_ar_buf_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[WideB]   = wide_aw_buf_hdr_out.hdr.src_id;
  assign axi_rsp_src_id[WideR]   = wide_ar_buf_hdr_out.hdr.src_id;

  assign axi_req_user[NarrowAw] = axi_narrow_mask_queue;
  assign axi_req_user[NarrowAr] = '0;
  assign axi_req_user[WideAw]   = axi_wide_mask_queue;
  assign axi_req_user[WideAr]   = '0;

  for (genvar ch = 0; ch < NumNWAxiChannels; ch++) begin : gen_route
    localparam nw_ch_e Ch = nw_ch_e'(ch);
    if (Ch == NarrowAw || Ch == NarrowAr ||
        Ch == WideAw || Ch == WideAr) begin : gen_req_route

      // Translate the address from AXI requests to a destination ID
      floo_id_translation #(
        .RouteCfg   (RouteCfg),
        .Sam        (Sam),
        .sam_idx_t  (sam_idx_t),
        .id_t       (id_t),
        .addr_t     (axi_addr_t),
        .addr_rule_t(sam_rule_t),
        .mask_sel_t (mask_sel_t)
      ) i_floo_id_translation (
        .clk_i,
        .rst_ni,
        .valid_i       (axi_narrow_aw_queue_valid_out),
        .addr_i        (axi_req_addr[ch]),
        .id_o          (id_out[ch]),
        .mask_addr_x_o (x_mask_sel[ch]),
        .mask_addr_y_o (y_mask_sel[ch])
      );
    end else if ((Ch == NarrowB || Ch == NarrowR ||
                  Ch == WideB || Ch == WideR)) begin : gen_rsp_route
      // For responses, the `src_id` from the request is used to route back
      // the responses.
      assign id_out[ch] = axi_rsp_src_id[ch];
    end else if (Ch == NarrowW) begin : gen_w_narrow_route
      // The destination ID of Narrow W's is the previous Narrow AW's ID
      assign id_out[ch] = narrow_aw_id_q;
    end else if (Ch == WideW) begin : gen_w_wode_route
      // The destination ID of Wide W's is the previous Wide AW's ID
      assign id_out[ch] = wide_aw_id_q;
    end

    // The actual `dst_id` depends on the routing algorithm
    if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting) begin: gen_dst_srcroute
      // Look up the `route` in the routing table
      assign dst_id[ch] = route_table_i[id_out[ch]];
    end else begin : gen_no_dst_srcroute
      // Otherwise, assign the destination ID directly
      assign dst_id[ch] = id_out[ch];
    end
  end

  `FFL(narrow_aw_id_q, id_out[NarrowAw], axi_narrow_aw_queue_valid_out &&
                                         axi_narrow_aw_queue_ready_in, '0)
  `FFL(wide_aw_id_q, id_out[WideAw], axi_wide_aw_queue_valid_out &&
                                     axi_wide_aw_queue_ready_in, '0)

  if (is_en_collective(CollectOpCfg)) begin : gen_mask_collective
    localparam int unsigned AddrWidth = $bits(axi_addr_t);
    axi_addr_t [NumNWAxiChannels-1:0] x_addr_mask;
    axi_addr_t [NumNWAxiChannels-1:0] y_addr_mask;

    for (genvar ch = 0; ch < NumNWAxiChannels; ch++) begin : gen_id_mask
      localparam nw_ch_e Ch = nw_ch_e'(ch);
      if ((is_en_narrow_collective(CollectOpCfg) && Ch == NarrowAw) ||
          (is_en_wide_collective(CollectOpCfg) && Ch == WideAw)) begin : gen_req_id_mask
        // Evaluate the ID Mask according to the info read from the SAM through the flooo_id_translation module
        if (RouteCfg.UseIdTable &&
            RouteCfg.RouteAlgo == floo_pkg::XYRouting) begin: gen_collecttive_idtable
          assign x_addr_mask[ch] = (({AddrWidth{1'b1}} >> (AddrWidth - x_mask_sel[ch].len))
                                    << x_mask_sel[ch].offset);
          assign y_addr_mask[ch] = (({AddrWidth{1'b1}} >> (AddrWidth - y_mask_sel[ch].len))
                                    << y_mask_sel[ch].offset);
          assign mask_id[ch].x = (axi_req_user[ch] & x_addr_mask[ch]) >> x_mask_sel[ch].offset;
          assign mask_id[ch].y = (axi_req_user[ch] & y_addr_mask[ch]) >> y_mask_sel[ch].offset;
          assign mask_id[ch].port_id = '0;
        end else if (RouteCfg.RouteAlgo == floo_pkg::XYRouting) begin: gen_collective_noidtable
          assign mask_id[ch].x = axi_req_user[ch][RouteCfg.XYAddrOffsetX +: $bits(id_out[ch].x)];
          assign mask_id[ch].y = axi_req_user[ch][RouteCfg.XYAddrOffsetY +: $bits(id_out[ch].y)];
          assign mask_id[ch].port_id = '0;
        end else begin: gen_collective_nosupported
          assign mask_id[ch] = '0; // We don't support multicast for other routing algorithms
        end
      end else begin: gen_no_collective_mask
        assign mask_id[ch] = '0;
      end
    end

    assign collective_mask[NarrowAw] = mask_id[NarrowAw];
    assign collective_mask[NarrowAr] = '0;
    assign collective_mask[WideAw]   = mask_id[WideAw];
    assign collective_mask[WideAr]   = '0;
    assign collective_mask[NarrowW]  = narrow_aw_mask_q;
    assign collective_mask[WideW]    = wide_aw_mask_q;

    assign collective_mask[NarrowR] = narrow_ar_buf_hdr_out.hdr.collective_mask;
    assign collective_mask[NarrowB] = narrow_aw_buf_hdr_out.hdr.collective_mask;
    assign collective_mask[WideR]   = wide_ar_buf_hdr_out.hdr.collective_mask;
    assign collective_mask[WideB]   = wide_aw_buf_hdr_out.hdr.collective_mask;

    `FFL(narrow_aw_mask_q, collective_mask[NarrowAw], axi_narrow_aw_queue_valid_out &&
                                           axi_narrow_aw_queue_ready_in, '0)
    `FFL(wide_aw_mask_q, collective_mask[WideAw], axi_wide_aw_queue_valid_out &&
                                       axi_wide_aw_queue_ready_in, '0)

  end else begin: gen_no_collective_mask
    assign collective_mask = '0;
  end

  // Because the W doesn't have a user field it is required to store the AW user field
  // for all following W beats! For the collective operations this encompass the type and the
  // operation we want to apply to the data!

  // Currently any reduction have to either be on the AW/W channel
  // If the chimney receives a Multicast / Reduction it will automatically update the resonse
  // to the appropriate type:
  //  - Multicast => Paralle Reduction with CollectB
  //  - Reduction => Multicast B Response

  // Assign all collective operation (if not supported, tehy are already tied to zero)
  assign red_coll_operation[NarrowAw] = axi_narrow_red_op_queue;
  assign red_coll_operation[NarrowAr] = floo_pkg::collect_op_e'('0);
  assign red_coll_operation[WideAw]   = axi_wide_red_op_queue;
  assign red_coll_operation[WideAr]   = floo_pkg::collect_op_e'('0);
  assign red_coll_operation[NarrowW]  = red_narrow_coll_operation_q;
  assign red_coll_operation[WideW]    = red_wide_coll_operation_q;
  assign red_coll_operation[NarrowR]  = floo_pkg::collect_op_e'('0);
  assign red_coll_operation[NarrowB]  = floo_pkg::collect_op_e'('0);
  assign red_coll_operation[WideR]    = floo_pkg::collect_op_e'('0);
  assign red_coll_operation[WideB]    = floo_pkg::collect_op_e'('0);

  // Store the collective operation to be used for the incoming W beat!
  `FFL(red_narrow_coll_operation_q, axi_narrow_red_op_queue,
      axi_narrow_aw_queue_valid_out && axi_narrow_aw_queue_ready_in, floo_pkg::collect_op_e'('0))
  `FFL(red_wide_coll_operation_q, axi_wide_red_op_queue,
      axi_wide_aw_queue_valid_out && axi_wide_aw_queue_ready_in, floo_pkg::collect_op_e'('0))

  ///////////////////
  // FLIT PACKING  //
  ///////////////////

  always_comb begin
    floo_narrow_aw                     = '0;
    floo_narrow_aw.hdr.rob_req         = narrow_aw_rob_req_out;
    floo_narrow_aw.hdr.rob_idx         = rob_idx_t'(narrow_aw_rob_idx_out);
    floo_narrow_aw.hdr.dst_id          = dst_id[NarrowAw];
    // Make sure that the injected mask is zero when teh operation is Unicast
    floo_narrow_aw.hdr.collective_mask = (red_coll_operation[NarrowAw] == Unicast) ?
                                         '0 : collective_mask[NarrowAw];
    floo_narrow_aw.hdr.src_id          = id_i;
    floo_narrow_aw.hdr.last            = 1'b0;  // AW and W need to be sent together
    floo_narrow_aw.hdr.axi_ch          = NarrowAw;
    floo_narrow_aw.hdr.atop            = axi_narrow_aw_queue.atop != axi_pkg::ATOP_NONE;
    floo_narrow_aw.payload             = axi_narrow_aw_queue;
    // Assign the collective_op and operation to the narrow AW flit
    floo_narrow_aw.hdr.collective_op = red_coll_operation[NarrowAw];

    if (is_en_narrow_reduction(CollectOpCfg)) begin
      if (is_reduction_op(red_coll_operation[NarrowAw])) begin
        floo_narrow_aw.hdr.collective_op = is_sequential_reduction_op(red_coll_operation[NarrowAw]) ?
                                           SeqAW : SelectAW;
      end
    end
  end

  always_comb begin
    floo_narrow_w                     = '0;
    floo_narrow_w.hdr.rob_req         = narrow_aw_rob_req_out;
    floo_narrow_w.hdr.rob_idx         = rob_idx_t'(narrow_aw_rob_idx_out);
    floo_narrow_w.hdr.dst_id          = dst_id[NarrowW];
    floo_narrow_w.hdr.collective_mask = (red_coll_operation[NarrowW] == Unicast) ?
                                          '0 : collective_mask[NarrowW];
    floo_narrow_w.hdr.src_id          = id_i;
    floo_narrow_w.hdr.last            = axi_narrow_req_in.w.last;
    floo_narrow_w.hdr.axi_ch          = NarrowW;
    floo_narrow_w.payload             = axi_narrow_req_in.w;
    // Assign the collective_op and operation to the narrow W flit
    floo_narrow_w.hdr.collective_op   = red_coll_operation[NarrowW];
  end

  always_comb begin
    floo_narrow_ar                     = '0;
    floo_narrow_ar.hdr.rob_req         = narrow_ar_rob_req_out;
    floo_narrow_ar.hdr.rob_idx         = rob_idx_t'(narrow_ar_rob_idx_out);
    floo_narrow_ar.hdr.dst_id          = dst_id[NarrowAr];
    floo_narrow_ar.hdr.collective_mask = collective_mask[NarrowAr];
    floo_narrow_ar.hdr.src_id          = id_i;
    floo_narrow_ar.hdr.last            = 1'b1;
    floo_narrow_ar.hdr.axi_ch          = NarrowAr;
    floo_narrow_ar.payload             = axi_narrow_ar_queue;
    floo_narrow_ar.hdr.collective_op   = floo_pkg::collect_op_e'('0);
  end

  always_comb begin
    floo_narrow_b                     = '0;
    floo_narrow_b.hdr.rob_req         = narrow_aw_buf_hdr_out.hdr.rob_req;
    floo_narrow_b.hdr.rob_idx         = rob_idx_t'(narrow_aw_buf_hdr_out.hdr.rob_idx);
    floo_narrow_b.hdr.dst_id          = dst_id[NarrowB];
    floo_narrow_b.hdr.collective_mask = collective_mask[NarrowB];
    floo_narrow_b.hdr.src_id          = id_i;
    floo_narrow_b.hdr.last            = 1'b1;
    floo_narrow_b.hdr.axi_ch          = NarrowB;
    floo_narrow_b.hdr.atop            = narrow_aw_buf_hdr_out.hdr.atop;
    floo_narrow_b.payload             = axi_narrow_meta_buf_rsp_out.b;
    floo_narrow_b.payload.id          = narrow_aw_buf_hdr_out.id;
    // We need to adapt the B Response according to the previous AW Request
    // The AXI slave on the chimney should not be aware of a reduction / multicast!
    // Multicast --> Collect the B responses in a parallel reduction
    // Reduction --> Multicast the B response to all members
    floo_narrow_b.hdr.collective_op  = floo_pkg::collect_op_e'('0);
    if(is_en_narrow_collective(CollectOpCfg)) begin
      if(is_multicast_op(narrow_aw_buf_hdr_out.hdr.collective_op)) begin
        floo_narrow_b.hdr.collective_op = CollectB;
      end else if(is_reduction_op(narrow_aw_buf_hdr_out.hdr.collective_op)) begin
        floo_narrow_b.hdr.collective_op = Multicast;
      end
    end
  end

  always_comb begin
    floo_narrow_r                     = '0;
    floo_narrow_r.hdr.rob_req         = narrow_ar_buf_hdr_out.hdr.rob_req;
    floo_narrow_r.hdr.rob_idx         = rob_idx_t'(narrow_ar_buf_hdr_out.hdr.rob_idx);
    floo_narrow_r.hdr.dst_id          = dst_id[NarrowR];
    floo_narrow_r.hdr.collective_mask = collective_mask[NarrowR];
    floo_narrow_r.hdr.src_id          = id_i;
    floo_narrow_r.hdr.axi_ch          = NarrowR;
    floo_narrow_r.hdr.last            = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_narrow_r.hdr.atop            = narrow_ar_buf_hdr_out.hdr.atop;
    floo_narrow_r.payload             = axi_narrow_meta_buf_rsp_out.r;
    floo_narrow_r.payload.id          = narrow_ar_buf_hdr_out.id;
    floo_narrow_r.hdr.collective_op   = floo_pkg::collect_op_e'('0);
  end

  always_comb begin
    floo_wide_aw                     = '0;
    floo_wide_aw.hdr.rob_req         = wide_aw_rob_req_out;
    floo_wide_aw.hdr.rob_idx         = rob_idx_t'(wide_aw_rob_idx_out);
    floo_wide_aw.hdr.dst_id          = dst_id[WideAw];
    floo_wide_aw.hdr.collective_mask = (red_coll_operation[WideAw] == Unicast) ?
                                        '0 : collective_mask[WideAw];
    floo_wide_aw.hdr.src_id          = id_i;
    floo_wide_aw.hdr.last            = 1'b0;  // AW and W need to be sent together
    floo_wide_aw.hdr.axi_ch          = WideAw;
    floo_wide_aw.payload             = axi_wide_aw_queue;
    // Assign the collective_op to the wide AW flit
    floo_wide_aw.hdr.collective_op = red_coll_operation[WideAw];

    if (is_en_wide_reduction(CollectOpCfg)) begin
      if (is_reduction_op(red_coll_operation[WideAw])) begin
        floo_wide_aw.hdr.collective_op = is_sequential_reduction_op(red_coll_operation[WideAw]) ?
                                          SeqAW : SelectAW;
      end
    end
  end

  always_comb begin
    floo_wide_w                     = '0;
    floo_wide_w.hdr.rob_req         = wide_aw_rob_req_out;
    floo_wide_w.hdr.rob_idx         = rob_idx_t'(wide_aw_rob_idx_out);
    floo_wide_w.hdr.dst_id          = dst_id[WideW];
    floo_wide_w.hdr.collective_mask = (red_coll_operation[WideW] == Unicast) ?
                                      '0 : collective_mask[WideW];
    floo_wide_w.hdr.src_id          = id_i;
    floo_wide_w.hdr.last            = axi_wide_req_in.w.last;
    floo_wide_w.hdr.axi_ch          = WideW;
    floo_wide_w.payload             = axi_wide_req_in.w;
    // Assign the collective_op and operation to the wide W flit
    floo_wide_w.hdr.collective_op   = red_coll_operation[WideW];
  end

  always_comb begin
    floo_wide_ar                     = '0;
    floo_wide_ar.hdr.rob_req         = wide_ar_rob_req_out;
    floo_wide_ar.hdr.rob_idx         = rob_idx_t'(wide_ar_rob_idx_out);
    floo_wide_ar.hdr.dst_id          = dst_id[WideAr];
    floo_wide_ar.hdr.collective_mask = collective_mask[WideAr];
    floo_wide_ar.hdr.src_id          = id_i;
    floo_wide_ar.hdr.last            = 1'b1;
    floo_wide_ar.hdr.axi_ch          = WideAr;
    floo_wide_ar.payload             = axi_wide_ar_queue;
    floo_wide_ar.hdr.collective_op   = floo_pkg::collect_op_e'('0);
  end

  always_comb begin
    floo_wide_b                     = '0;
    floo_wide_b.hdr.rob_req         = wide_aw_buf_hdr_out.hdr.rob_req;
    floo_wide_b.hdr.rob_idx         = rob_idx_t'(wide_aw_buf_hdr_out.hdr.rob_idx);
    floo_wide_b.hdr.dst_id          = dst_id[WideB];
    floo_wide_b.hdr.collective_mask = collective_mask[WideB];
    floo_wide_b.hdr.src_id          = id_i;
    floo_wide_b.hdr.last            = 1'b1;
    floo_wide_b.hdr.axi_ch          = WideB;
    floo_wide_b.payload             = axi_wide_meta_buf_rsp_out.b;
    floo_wide_b.payload.id          = wide_aw_buf_hdr_out.id;

    // We need to adapt the B Response according to the previous AW Request
    // The AXI slave on the chimney should not be aware of a reduction / multicast!
    // Multicast --> Collect the B responses in a parallel reduction
    // Reduction --> Multicast the B response to all members
    floo_wide_b.hdr.collective_op  = Unicast;
    if(is_en_wide_collective(CollectOpCfg)) begin
      if(is_multicast_op(wide_aw_buf_hdr_out.hdr.collective_op)) begin
        floo_wide_b.hdr.collective_op = CollectB;
      end else if(is_reduction_op(wide_aw_buf_hdr_out.hdr.collective_op)) begin
        floo_wide_b.hdr.collective_op = Multicast;
      end
    end
  end

  always_comb begin
    floo_wide_r                      = '0;
    floo_wide_r.hdr.rob_req          = wide_ar_buf_hdr_out.hdr.rob_req;
    floo_wide_r.hdr.rob_idx          = rob_idx_t'(wide_ar_buf_hdr_out.hdr.rob_idx);
    floo_wide_r.hdr.dst_id           = dst_id[WideR];
    floo_wide_r.hdr.collective_mask  = collective_mask[WideR];
    floo_wide_r.hdr.src_id           = id_i;
    floo_wide_r.hdr.axi_ch           = WideR;
    floo_wide_r.hdr.last             = 1'b1; // There is no reason to do wormhole routing for R bursts
    floo_wide_r.payload              = axi_wide_meta_buf_rsp_out.r;
    floo_wide_r.payload.id           = wide_ar_buf_hdr_out.id;
    floo_wide_r.hdr.collective_op    = floo_pkg::collect_op_e'('0);
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
    .valid_i  ( floo_req_arb_req_in  ),
    .data_i   ( floo_req_arb_in      ),
    .ready_o  ( floo_req_arb_gnt_out ),
    .data_o   ( floo_req_o.req       ),
    .ready_i  ( floo_req_i.ready     ),
    .valid_o  ( floo_req_o.valid     )
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
    .valid_i  ( floo_wide_arb_req_in         ),
    .data_i   ( floo_wide_arb_in             ),
    .ready_o  ( floo_wide_arb_gnt_out        ),
    .data_o   ( floo_wide_o.wide             ),
    .ready_i  ( floo_wide_req_arb_gnt_in     ),
    .valid_o  ( floo_wide_req_arb_valid_out  )
  );

  // Mux the valid of the read and write channels to the ACK/NACK protocol
  // of the virtual channel for decoupled read and write output requests.
  // AW/W -> Virtual Channel 0
  // R -> Virtual Channel 1
  // TODO(lleone): check if this really solve DEADLOCK!!!!
  if (EnDecoupledRW) begin: gen_vc_rw_ack
    assign floo_wide_o.valid[0] = (floo_wide_o.wide.generic.hdr.axi_ch != WideR) ? floo_wide_req_arb_valid_out : 1'b0;
    assign floo_wide_o.valid[1] = (floo_wide_o.wide.generic.hdr.axi_ch == WideR) ? floo_wide_req_arb_valid_out : 1'b0;
    assign floo_wide_req_arb_gnt_in = (floo_wide_o.wide.generic.hdr.axi_ch != WideR) ?
                                       floo_wide_i.ready[0] : floo_wide_i.ready[1];
  end else begin: gen_no_vc_rw_ack
    assign floo_wide_o.valid = floo_wide_req_arb_valid_out;
    assign floo_wide_req_arb_gnt_in = floo_wide_i.ready;
  end


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
  assign axi_wide_unpack_aw   = floo_wide_in_wr_q.wide_aw.payload;
  assign axi_wide_unpack_w    = floo_wide_in_wr_q.wide_w.payload;
  assign axi_wide_unpack_ar   = floo_req_in.wide_ar.payload;
  assign axi_wide_unpack_r    = floo_wide_in_rd_q.wide_r.payload;
  assign axi_wide_unpack_b    = floo_rsp_in.wide_b.payload;
  assign floo_req_unpack_generic = floo_req_in.generic;
  assign floo_rsp_unpack_generic = floo_rsp_in.generic;

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

  // Flit unpacking on the wide interface
  if (EnDecoupledRW) begin

    assign floo_wide_unpack_generic_wr = floo_wide_in_wr_q.generic;
    assign floo_wide_unpack_generic_rd = floo_wide_in_rd_q.generic;

    // Directly connect read VC to AXI R channel
    assign axi_valid_in[WideR] = ChimneyCfgW.EnMgrPort && floo_wide_in_rd_valid_q;
    assign floo_wide_out_rd_ready_q = axi_ready_out[WideR];

    // Demux write VC to AXI AW and W channels
    stream_demux #(
      .N_OUP(NumVirtualChannels)
    ) i_wide_wr_flit_demux (
      .inp_valid_i(floo_wide_in_wr_valid_q),
      .inp_ready_o(floo_wide_out_wr_ready_q),
      .oup_sel_i  (floo_wide_unpack_generic_wr.hdr.axi_ch == WideAw ? 1'b1 : 1'b0),
      .oup_valid_o({axi_valid_in[WideAw], axi_valid_in[WideW]}),
      .oup_ready_i({axi_ready_out[WideAw], axi_ready_out[WideW]})
    );

  end else begin

    // Demux single physical channel to AXI AW, W and R channels
    assign floo_wide_out_ready_q = axi_ready_out[floo_wide_in_q.generic.hdr.axi_ch];
    assign axi_valid_in[WideR] = ChimneyCfgW.EnMgrPort && floo_wide_in_valid_q &&
                                 (floo_wide_in_q.generic.hdr.axi_ch == WideR);
    assign axi_valid_in[WideAw] = floo_wide_in_valid_q &&
                                  (floo_wide_in_q.generic.hdr.axi_ch == WideAw);
    assign axi_valid_in[WideW] = floo_wide_in_valid_q &&
                                 (floo_wide_in_q.generic.hdr.axi_ch == WideW);

    // Aliases to uniformly write downstream logic handling both cases, with and without VCs
    assign floo_wide_unpack_generic_wr = floo_wide_in_q.generic;
    assign floo_wide_unpack_generic_rd = floo_wide_in_q.generic;
    assign floo_wide_in_rd_valid_q = floo_wide_in_valid_q;
    assign floo_wide_in_wr_valid_q = floo_wide_in_valid_q;
  end

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
    hdr: floo_wide_unpack_generic_wr.hdr
  };
  assign wide_ar_buf_hdr_in = '{
    id: axi_wide_unpack_ar.id,
    hdr: floo_req_unpack_generic.hdr
  };

  if (ChimneyCfgN.EnSbrPort) begin : gen_narrow_mgr_port
    floo_meta_buffer #(
      .InIdWidth      ( AxiCfgN.InIdWidth        ),
      .OutIdWidth     ( AxiCfgN.OutIdWidth       ),
      .MaxTxns        ( ChimneyCfgN.MaxTxns      ),
      .MaxUniqueIds   ( ChimneyCfgN.MaxUniqueIds ),
      .AtopSupport    ( AtopSupport              ),
      .MaxAtomicTxns  ( MaxAtomicTxns            ),
      .Sam            ( Sam                      ),
      .buf_t          ( narrow_meta_buf_t        ),
      .axi_in_req_t   ( axi_narrow_req_t         ),
      .axi_in_rsp_t   ( axi_narrow_rsp_t         ),
      .axi_out_req_t  ( axi_narrow_out_req_t     ),
      .axi_out_rsp_t  ( axi_narrow_out_rsp_t     ),
      .RouteCfg       ( RouteCfg                 ),
      .addr_t         ( axi_addr_t               ),
      .sam_rule_t     ( sam_rule_t               ),
      .id_t           ( id_t                     ),
      .sam_idx_t      ( sam_idx_t                ),
      .mask_sel_t     ( mask_sel_t               )
    ) i_narrow_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i        ( id_i       ),
      .axi_req_i   ( axi_narrow_meta_buf_req_in  ),
      .axi_rsp_o   ( axi_narrow_meta_buf_rsp_out ),
      .axi_req_o   ( axi_narrow_meta_buf_req_out ),
      .axi_rsp_i   ( axi_narrow_meta_buf_rsp_in  ),
      .aw_buf_i    ( narrow_aw_buf_hdr_in        ),
      .ar_buf_i    ( narrow_ar_buf_hdr_in        ),
      .r_buf_o     ( narrow_ar_buf_hdr_out       ),
      .b_buf_o     ( narrow_aw_buf_hdr_out       )
    );
  end else begin : gen_no_narrow_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiCfgN.InIdWidth ),
      .ATOPs      ( AtopSupport       ),
      .axi_req_t  ( axi_narrow_req_t  ),
      .axi_resp_t ( axi_narrow_rsp_t  )
    ) i_axi_err_slv (
      .clk_i      ( clk_i                       ),
      .rst_ni     ( rst_ni                      ),
      .test_i     ( test_enable_i               ),
      .slv_req_i  ( axi_narrow_meta_buf_req_in  ),
      .slv_resp_o ( axi_narrow_meta_buf_rsp_out )
    );
    assign axi_narrow_meta_buf_req_out = '0;
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
      .Sam            ( Sam                       ),
      .buf_t          ( wide_meta_buf_t           ),
      .axi_in_req_t   ( axi_wide_req_t            ),
      .axi_in_rsp_t   ( axi_wide_rsp_t            ),
      .axi_out_req_t  ( axi_wide_out_req_t        ),
      .axi_out_rsp_t  ( axi_wide_out_rsp_t        ),
      .RouteCfg       ( RouteCfg                  ),
      .addr_t         ( axi_addr_t                ),
      .sam_rule_t     ( sam_rule_t               ),
      .id_t           ( id_t                      ),
      .sam_idx_t      ( sam_idx_t                 ),
      .mask_sel_t     ( mask_sel_t                )
    ) i_wide_meta_buffer (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i       ( id_i       ),
      .axi_req_i  ( axi_wide_meta_buf_req_in  ),
      .axi_rsp_o  ( axi_wide_meta_buf_rsp_out ),
      .axi_req_o  ( axi_wide_meta_buf_req_out ),
      .axi_rsp_i  ( axi_wide_meta_buf_rsp_in  ),
      .aw_buf_i   ( wide_aw_buf_hdr_in        ),
      .ar_buf_i   ( wide_ar_buf_hdr_in        ),
      .r_buf_o    ( wide_ar_buf_hdr_out       ),
      .b_buf_o    ( wide_aw_buf_hdr_out       )
    );
  end else begin : gen_no_wide_mgr_port
    axi_err_slv #(
      .AxiIdWidth ( AxiCfgW.InIdWidth ),
      .ATOPs      ( 1'b1              ),
      .axi_req_t  ( axi_wide_req_t ),
      .axi_resp_t ( axi_wide_rsp_t )
    ) i_axi_err_slv (
      .clk_i      ( clk_i                     ),
      .rst_ni     ( rst_ni                    ),
      .test_i     ( test_enable_i             ),
      .slv_req_i  ( axi_wide_meta_buf_req_in  ),
      .slv_resp_o ( axi_wide_meta_buf_rsp_out )
    );
    assign axi_wide_meta_buf_req_out = '0;
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

  // `CutRsp` of the narrow and wide config must be the same
  `ASSERT_INIT(CutRspMatch, ChimneyCfgN.CutRsp == ChimneyCfgW.CutRsp)

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
  `ASSERT(NoNarrowMgrPortBResponse, ChimneyCfgN.EnMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == NarrowB)))
  `ASSERT(NoNarrowMgrPortRResponse, ChimneyCfgN.EnMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == NarrowR)))
  `ASSERT(NoWideMgrPortBResponse, ChimneyCfgW.EnMgrPort || !(floo_rsp_in_valid &&
                           (floo_rsp_unpack_generic.hdr.axi_ch == WideB)))
  `ASSERT(NoWideMgrPortRResponse, ChimneyCfgW.EnMgrPort || !(floo_wide_in_rd_valid_q &&
                           (floo_wide_unpack_generic_rd.hdr.axi_ch == WideR)))
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
  `ASSERT(NoWideSbrPortWRequest,  ChimneyCfgW.EnSbrPort || !(floo_wide_in_wr_valid_q &&
                           (floo_wide_unpack_generic_wr.hdr.axi_ch == WideW)))

  // We do not support reduction with ROB Buffer
  `ASSERT_INIT(NoRobReduction,
              !(is_en_wide_reduction(CollectOpCfg) | is_en_narrow_reduction(CollectOpCfg)) ||
              (ChimneyCfgN.BRoBType == NoRoB && ChimneyCfgN.RRoBType == NoRoB &&
               ChimneyCfgW.BRoBType == NoRoB && ChimneyCfgW.RRoBType == NoRoB),
               "Invalid Chimney Cfg with reduction support")

  // When virtual channels for decoupled read and write is enabled,
  // req_i and req_o must have same amount of VCs, equal to NumVirtualChannels
  `ASSERT_INIT(VCMismatchInputReady, !EnDecoupledRW | ($bits(floo_wide_i.ready) == NumVirtualChannels),
    $sformatf("Input request must have %0d VCs when EnDecoupledRW==1", NumVirtualChannels));
  `ASSERT_INIT(VCMismatchOutputReady, !EnDecoupledRW | ($bits(floo_wide_o.ready) == NumVirtualChannels),
    $sformatf("Output request must have %0d VCs when EnDecoupledRW==1", NumVirtualChannels));
  `ASSERT_INIT(VCMismatchInputValid, !EnDecoupledRW | ($bits(floo_wide_i.valid) == NumVirtualChannels),
    $sformatf("Input request must have %0d VCs when EnDecoupledRW==1", NumVirtualChannels));
  `ASSERT_INIT(VCMismatchOutputValid, !EnDecoupledRW | ($bits(floo_wide_o.valid) == NumVirtualChannels),
    $sformatf("Output request must have %0d VCs when EnDecoupledRW==1", NumVirtualChannels));

endmodule
