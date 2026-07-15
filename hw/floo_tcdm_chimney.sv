// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Diyou Shen <diyou@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// A lightweight bidirectional network interface for connecting TCDM/REQRSP
/// buses to the FlooNoC. Unlike `floo_nw_chimney` (which handles full AXI
/// with RoBs, meta buffers, burst tracking, and dual narrow/wide paths),
/// this module targets single-flit request/response protocols where:
///
///  - Each request is a single flit (no bursts).
///  - No AXI ID tracking or reorder buffers are needed.
///
/// Typical use case: L2 cache refill mesh carrying REQRSP payloads between
/// compute groups and memory endpoints.
///
/// The module has two configurable ports:
///
///  - **Manager port** (`EnMgrPort`): Sends requests into the NoC and
///    receives responses. The chimney translates the request address to
///    a destination node ID (via SAM / `floo_id_translation`), looks up
///    the source route in `route_table_i`, and packs the flit header.
///    Incoming response flits are unpacked back to REQRSP.
///
///  - **Subordinate port** (`EnSbrPort`): Receives requests from the NoC
///    and sends responses back. The chimney unpacks request flits into
///    REQRSP. Response routing does not assume in-order completion by the
///    local slave: the caller supplies `sbr_txn_id_i`, the originator's
///    node ID for whichever response is currently on `sbr_rsp_i`, derived
///    from the response payload itself (not tracked locally).
///
module floo_tcdm_chimney
  import floo_pkg::*;
#(
  /// Config for routing information (see `floo_pkg::route_cfg_t`)
  parameter floo_pkg::route_cfg_t RouteCfg = floo_pkg::RouteDefaultCfg,
  /// Whether a manager port is attached (sends requests, receives responses)
  parameter bit EnMgrPort   = 1'b1,
  /// Whether a subordinate port is attached (receives requests, sends responses)
  parameter bit EnSbrPort   = 1'b0,
  /// Node ID type (XY coordinate or flat index, depending on routing algo)
  parameter type id_t       = logic,
  /// Source-route type — a packed bit vector consumed hop-by-hop.
  /// Only used when `RouteCfg.RouteAlgo == SourceRouting`.
  parameter type route_t    = logic,
  /// Destination ID type packed into the flit header.
  /// Equals `route_t` for source routing, `id_t` otherwise.
  parameter type dst_t      = id_t,
  /// Flit header type (must have `dst_id`, `src_id`, `last`, `collective_op`)
  parameter type hdr_t      = logic,
  /// REQRSP request channel type (e.g. `reqrsp_pkg::reqrsp_req_chan_t`)
  parameter type req_chan_t = logic,
  /// REQRSP response channel type (e.g. `reqrsp_pkg::reqrsp_rsp_chan_t`)
  parameter type rsp_chan_t = logic,
  /// Request flit type: `struct packed { req_chan_t payload; hdr_t hdr; }`
  parameter type floo_req_t = logic,
  /// Response flit type: `struct packed { rsp_chan_t payload; hdr_t hdr; }`
  parameter type floo_rsp_t = logic,
  /// Address type extracted from the request channel for SAM lookup
  parameter type addr_t     = logic,
  /// Rule type for the System Address Map
  parameter type sam_rule_t = logic,
  /// The System Address Map
  parameter sam_rule_t [RouteCfg.NumSamRules-1:0] Sam = '0
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  // --- REQRSP side ---

  /// Manager port: request in (from local master, e.g. refill xbar)
  input  req_chan_t mgr_req_i,
  input  logic      mgr_req_valid_i,
  output logic      mgr_req_ready_o,
  /// Manager port: response out (to local master)
  output rsp_chan_t mgr_rsp_o,
  output logic      mgr_rsp_valid_o,
  input  logic      mgr_rsp_ready_i,

  /// Subordinate port: request out (to local slave, e.g. HBM adapter)
  output req_chan_t sbr_req_o,
  output logic      sbr_req_valid_o,
  input  logic      sbr_req_ready_i,
  /// Subordinate port: response in (from local slave)
  input  rsp_chan_t sbr_rsp_i,
  input  logic      sbr_rsp_valid_i,
  output logic      sbr_rsp_ready_o,
  /// Subordinate port: source node ID for the response currently on
  /// `sbr_rsp_i`, used to route it back into the network. Supplied by the
  /// caller (extracted from the response payload) instead of tracked
  /// locally, since the local slave (e.g. HBM) may complete out of order.
  input  id_t        sbr_txn_id_i,

  // --- Routing ---

  /// Coordinates / ID of this node
  input  id_t    id_i,
  /// Routing table indexed by destination node ID.
  /// Only used when `RouteCfg.RouteAlgo == SourceRouting`.
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,

  // --- NoC links ---

  /// Request flit output (injected into network)
  output floo_req_t floo_req_o,
  output logic      floo_req_valid_o,
  input  logic      floo_req_ready_i,
  /// Request flit input (ejected from network)
  input  floo_req_t floo_req_i,
  input  logic      floo_req_valid_i,
  output logic      floo_req_ready_o,
  /// Response flit output (injected into network)
  output floo_rsp_t floo_rsp_o,
  output logic      floo_rsp_valid_o,
  input  logic      floo_rsp_ready_i,
  /// Response flit input (ejected from network)
  input  floo_rsp_t floo_rsp_i,
  input  logic      floo_rsp_valid_i,
  output logic      floo_rsp_ready_o
);

  // -----------------------------------------------
  //  Address → Destination ID translation
  // -----------------------------------------------

  id_t mgr_dst_id;

  if (EnMgrPort) begin : gen_mgr_id_translation
    // Translate the request address to a destination node ID via SAM.
    floo_id_translation #(
      .RouteCfg      ( RouteCfg        ),
      .Sam           ( Sam             ),
      .sam_idx_t     ( id_t            ),
      .id_t          ( id_t            ),
      .addr_t        ( addr_t          ),
      .addr_rule_t   ( sam_rule_t      ),
      .mask_sel_t    ( logic           )
    ) i_id_translation (
      .clk_i,
      .rst_ni,
      .valid_i       ( mgr_req_valid_i ),
      .addr_i        ( mgr_req_i.addr  ),
      .id_o          ( mgr_dst_id      ),
      .mask_addr_x_o (                 ),
      .mask_addr_y_o (                 )
    );
  end else begin : gen_no_mgr_id
    assign mgr_dst_id = '0;
  end

  // -----------------------------------------------
  //  Route lookup (source routing)
  // -----------------------------------------------

  dst_t mgr_route;

  if (EnMgrPort) begin : gen_mgr_route
    if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting) begin : gen_src_route
      assign mgr_route = route_table_i[mgr_dst_id];
    end else begin : gen_id_route
      assign mgr_route = mgr_dst_id;
    end
  end else begin : gen_no_mgr_route
    assign mgr_route = '0;
  end

  // -----------------------------------------------
  //  Manager port: request injection + response ejection
  // -----------------------------------------------

  if (EnMgrPort) begin : gen_mgr_port

    // --- Request injection ---
    assign floo_req_o = '{
      payload: mgr_req_i,
      hdr: '{
        dst_id:        mgr_route,
        src_id:        id_i,
        last:          1'b1,
        collective_op: '0
      }
    };
    assign floo_req_valid_o = mgr_req_valid_i;
    assign mgr_req_ready_o  = floo_req_ready_i;

    // --- Response ejection ---
    assign mgr_rsp_o        = floo_rsp_i.payload;
    assign mgr_rsp_valid_o  = floo_rsp_valid_i;
    assign floo_rsp_ready_o = mgr_rsp_ready_i;

  end else begin : gen_no_mgr_port
    assign floo_req_o       = '0;
    assign floo_req_valid_o = 1'b0;
    assign mgr_req_ready_o  = 1'b0;
    assign mgr_rsp_o        = '0;
    assign mgr_rsp_valid_o  = 1'b0;
    assign floo_rsp_ready_o = 1'b1;
  end

  // -----------------------------------------------
  //  Subordinate port: request ejection + response injection
  // -----------------------------------------------

  if (EnSbrPort) begin : gen_sbr_port

    // --- Request ejection ---
    assign sbr_req_o       = floo_req_i.payload;
    assign sbr_req_valid_o = floo_req_valid_i;
    assign floo_req_ready_o = sbr_req_ready_i;

    // --- Response injection ---
    // Route the response back to its originator using sbr_txn_id_i, which
    // the caller derives from the response payload itself rather than a
    // locally tracked dispatch order (the local slave, e.g. HBM, may
    // complete requests out of order).
    dst_t sbr_rsp_route;
    if (RouteCfg.RouteAlgo == floo_pkg::SourceRouting) begin : gen_sbr_src_route
      assign sbr_rsp_route = route_table_i[sbr_txn_id_i];
    end else begin : gen_sbr_id_route
      assign sbr_rsp_route = sbr_txn_id_i;
    end

    assign floo_rsp_o = '{
      payload: sbr_rsp_i,
      hdr: '{
        dst_id:        sbr_rsp_route,
        src_id:        id_i,
        last:          1'b1,
        collective_op: '0
      }
    };
    assign floo_rsp_valid_o = sbr_rsp_valid_i;
    assign sbr_rsp_ready_o  = floo_rsp_ready_i;

  end else begin : gen_no_sbr_port
    assign sbr_req_o        = '0;
    assign sbr_req_valid_o  = 1'b0;
    assign floo_req_ready_o = 1'b1;
    assign floo_rsp_o       = '0;
    assign floo_rsp_valid_o = 1'b0;
    assign sbr_rsp_ready_o  = 1'b0;
  end

  // -----------------------------------------------
  //  Assertions
  // -----------------------------------------------

  `ASSERT(MgrOrSbr, EnMgrPort || EnSbrPort, clk_i, !rst_ni,
      "At least one of EnMgrPort or EnSbrPort must be enabled.")
  `ASSERT(NotBothPorts, !(EnMgrPort && EnSbrPort), clk_i, !rst_ni,
      "Enabling both EnMgrPort and EnSbrPort is not supported.")

endmodule
