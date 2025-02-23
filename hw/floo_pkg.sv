// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>
// - Michael Rogenmoser <michaero@iis.ee.ethz.ch>

/// Currently only contains useful functions and some constants and typedefs
package floo_pkg;

  /// Currently Supported Routing Algorithms
  typedef enum logic[2:0] {
    /// `IdTable` routing uses a table of routing rules to determine to
    /// which output port a packet should be routed, based on the
    /// destination ID encoded in the header of the flit. Every router
    /// needs its own table, that is passed to `id_route_map_i`. The
    /// network interface only needs to convert the physical address to
    /// the destination ID, that is later used by the routers.
    IdTable,
    /// `SourceRouting` calculates the route to the destination in the
    /// source itself (i.e. the network interfaces). The route is encoded
    /// as a sequence of router ports that the packet should traverse. At
    /// every router hop, a port is popped from the route list. The routes
    /// need to be passed to the network interfaces `route_table_i`, whic
    /// is a table of routes that can be indexed with the destination ID.
    /// This algorithm is mainly useful for smaller networks with fewer
    /// hops where the encoding size of the route does not become too large.
    SourceRouting,
    /// `XYRouting` is a simple routing algorithm that routes packets
    /// based on the XY coordinates of current and destination node. Every
    /// router needs to be aware of its own XY coordinates and forwards
    /// packets based on the difference of the coordinates. The network
    /// interface needs to convert the physical address to the destination
    ///  XY coordinates, which can be done with addressoffsets `XYAddrOffsetX`
    /// and `XYAddrOffsetY`, or by indexing the system address map `Sam`. This
    /// is controlled with the `UseIdTable` parameter.
    XYRouting,
    YXRouting,
    O1Routing
  } route_algo_e;

  /// The directions in a 2D mesh network, mainly useful for indexing
  /// multi-directional arrays. If a router has more than one local
  /// port, the additional ports can be defined as `Eject+p`, where `p`
  /// is the local port index
  typedef enum logic[2:0] {
    North = 3'd0, // y increasing
    East  = 3'd1, // x increasing
    South = 3'd2, // y decreasing
    West  = 3'd3, // x decreasing
    Eject = 3'd4, // target/destination
    NumDirections
  } route_direction_e;

  /// The types of Reorder Buffers (RoBs) that can be used in the network interface
  typedef enum logic [1:0] {
    /// The most performant but also most complex RoB, which supports reodering
    /// of responses. This reorder buffer retains the out-of-order nature of
    /// AXI transactions with different IDs. Supports multiple outstanding
    /// transactions and bursts.
    NormalRoB,
    /// Simpler FIFO-like RoB, which does not support reordering of responses with
    /// the same AXI txnID. Transactions with different txnIDs are effectively
    /// serialized. Supports multiple outstanding transactions but currently does
    /// not support burst transactions. Mainly useful for B-responses which are
    /// single transactions.
    SimpleRoB,
    /// No RoB, which stalls transactions of the same ID going to different destinations
    /// until the previous transaction is completed. This is option is useful if the
    /// ordering of transactions is handled downstream, e.g. in the DMA by issuing AXI
    /// transactions with different txnIDs. The overhead of this RoB is very low, since
    /// it only requires counters for tracking the number of outstanding transactions of
    /// each txnID.
    NoRoB
  } rob_type_e;

  /// The types of AXI channels in single AXI network interfaces
  typedef enum logic [2:0] {
    AxiAw = 3'd0,
    AxiW = 3'd1,
    AxiAr = 3'd2,
    AxiB = 3'd3,
    AxiR = 3'd4,
    NumAxiChannels = 3'd5
  } axi_ch_e;

  /// The types of AXI channels in narrow-wide AXI network interfaces
  typedef enum logic [3:0] {
    NarrowAw = 4'd0,
    NarrowW = 4'd1,
    NarrowAr = 4'd2,
    WideAr = 4'd3,
    NarrowB = 4'd4,
    NarrowR = 4'd5,
    WideB = 4'd6,
    WideAw = 4'd7,
    WideW = 4'd8,
    WideR = 4'd9,
    NumNWAxiChannels = 4'd10
  } nw_ch_e;

  /// The link types in the Floo network
  typedef enum logic [1:0] {
    /// Request link of `AR, AW, W` type
    FlooReq = 2'd0,
    /// Response link of `R, B` type
    FlooRsp = 2'd1,
    /// Additional wide link for narrow-wide AXI interfaces
    FlooWide = 2'd2
  } floo_chan_e;

  /// Configuration for a bidirectional AXI interface
  typedef struct packed {
    /// Width of the address
    int unsigned AddrWidth;
    /// Width of the data
    int unsigned DataWidth;
    /// Width of the user signals
    int unsigned UserWidth;
    /// Width of the incoming txnID (i.e. the txnID of a manager port)
    int unsigned InIdWidth;
    /// Width of the outgoing txnID (i.e. the txnID of a subordinate port)
    int unsigned OutIdWidth;
  } axi_cfg_t;

  /// Configuration to pass routing information to the routers
  /// as well as network interfaces
  typedef struct packed {
    /// The routing algorithm that is used
    route_algo_e RouteAlgo;
    /// Whether to calculate the destination ID based based on
    /// the system address map or with XY offset values.
    bit UseIdTable;
    /// The offset of the X coordinate in request address,
    /// if `!UseIdTable && RouteAlgo == XYRouting`
    int unsigned XYAddrOffsetX;
    /// The offset of the Y coordinate in request address
    /// if `!UseIdTable && RouteAlgo == XYRouting`
    int unsigned XYAddrOffsetY;
    /// The offset of the id in the request address
    /// if `!UseIdTable && RouteAlgo != XYRouting`
    int unsigned IdAddrOffset;
    /// The number of endpoints in the System Address Map,
    /// Only used if `UseIdTable` is set
    int unsigned NumSamRules;
    /// The number of routes for every routing table,
    /// Only used if `RouteAlgo == SourceRouting`
    int unsigned NumRoutes;
  } route_cfg_t;

  /// Configuration for the network interface (chimney)
  typedef struct packed {
    /// Whether an AXI subordinate is attached to the network interfaces
    /// (e.g. a DRAM memory)
    bit EnSbrPort;
    /// Whether an AXI manager is attached to the network interfaces
    /// (e.g. a host core)
    bit EnMgrPort;
    /// The number of both incoming and outgoing transactions that can be
    /// handled by the network interface.
    int unsigned MaxTxns;
    /// The number of unique transaction IDs that can be issued by the network
    /// to AXI subordinates downstream. By default the network interface issues
    /// with a single txnID, effectively serializing incoming transactions from
    /// all managers in the entire system. If multiple txnIDs are used, incoming
    /// transactions with different TxnIDs _might_ not be serialized. This is results
    /// in more complex logic in the network interfaces, but might be useful for
    /// downstream AXI networks that can handle out-of-order transactions.
    int unsigned MaxUniqueIds;
    /// Number of outstanding transactions per txnID. Only used if
    /// `RoBType == NormalRoB`.
    int unsigned MaxTxnsPerId;
    /// The type of Reoder Buffer (RoB) that is used for B responses.
    rob_type_e BRoBType;
    /// The depth of the RoB for B responses. Only used if `BRoBType != NoRoB`.
    int unsigned BRoBSize;
    /// The type of Reoder Buffer (RoB) that is used for R responses.
    rob_type_e RRoBType;
    /// The depth of the RoB for R responses. Only used if `RRoBType != NoRoB`.
    int unsigned RRoBSize;
    /// Whether to buffer incoming AXI requests at the network interface,
    /// to ease timing closure.
    bit CutAx;
    /// Whether to buffer incoming links at the network interface,
    bit CutRsp;
  } chimney_cfg_t;

  /// The default configuration for the network interface
  localparam chimney_cfg_t ChimneyDefaultCfg = '{
    EnSbrPort: 1'b1,
    EnMgrPort: 1'b1,
    MaxTxns: 32,
    MaxUniqueIds: 1,
    MaxTxnsPerId: 32,
    BRoBType: NoRoB,
    BRoBSize: 0,
    RRoBType: NoRoB,
    RRoBSize: 0,
    CutAx: 1'b0,
    CutRsp: 1'b0
  };

  /// The default configuration for routing
  localparam route_cfg_t RouteDefaultCfg = '{
    RouteAlgo: XYRouting,
    UseIdTable: 1'b0,
    XYAddrOffsetX: 0,
    XYAddrOffsetY: 0,
    IdAddrOffset: 0,
    NumSamRules: 0,
    NumRoutes: 0
  };

  /// The AXI channel to link mapping in a single-AXI network interface
  function automatic floo_chan_e axi_chan_mapping(axi_ch_e ch);
    if (ch == AxiAw || ch == AxiW || ch == AxiAr) begin
      return FlooReq;
    end else begin
      return FlooRsp;
    end
  endfunction

  /// The AXI channel to link mapping in a narrow-wide AXI network interface
  function automatic floo_chan_e nw_chan_mapping(nw_ch_e ch);
    if (ch == NarrowAw || ch == NarrowW || ch == NarrowAr || ch == WideAr) begin
      return FlooReq;
    end else if (ch == WideAw || ch == WideW || ch == WideR) begin
      return FlooWide;
    end else begin
      return FlooRsp;
    end
  endfunction

  /// Swaps the direction of the AXI interface config
  function automatic axi_cfg_t axi_cfg_swap_iw(axi_cfg_t cfg);
    return '{
      AddrWidth: cfg.AddrWidth,
      DataWidth: cfg.DataWidth,
      UserWidth: cfg.UserWidth,
      InIdWidth: cfg.OutIdWidth,
      OutIdWidth: cfg.InIdWidth
    };
  endfunction

  /// Helper function to enable/disable the subordinate and manager ports
  /// for a chimney config.
  function automatic chimney_cfg_t set_ports(chimney_cfg_t cfg, bit en_sbr, bit en_mgr);
    cfg.EnSbrPort = en_sbr;
    cfg.EnMgrPort = en_mgr;
    return cfg;
  endfunction

  /// Helper function to calculate the maximum of two unsigned integers
  function automatic int unsigned max(int unsigned a, int unsigned b);
    return (a > b) ? a : b;
  endfunction

  /// Returns the AXI config the resulting AXI config when joining a narrow
  /// and wide AXI subordinate interfaces.
  function automatic axi_cfg_t axi_join_cfg(axi_cfg_t cfg_n, axi_cfg_t cfg_w);
    return '{
      AddrWidth: cfg_n.AddrWidth,
      DataWidth: max(cfg_n.DataWidth, cfg_w.DataWidth),
      UserWidth: max(cfg_n.UserWidth, cfg_w.UserWidth),
      InIdWidth: 0, // Not used in `nw_join`
      OutIdWidth: max(cfg_n.OutIdWidth, cfg_w.OutIdWidth) + 1 // for the AXI mux
    };
  endfunction

  /// Returns the number of bits of an AXI channel for a single-AXI config
  function automatic int unsigned get_axi_chan_width(axi_cfg_t cfg, axi_ch_e ch);
    case (ch)
      AxiAw: return axi_pkg::aw_width(cfg.AddrWidth, cfg.InIdWidth, cfg.UserWidth);
      AxiW: return axi_pkg::w_width(cfg.DataWidth, cfg.UserWidth);
      AxiB: return axi_pkg::b_width(cfg.InIdWidth, cfg.UserWidth);
      AxiAr: return axi_pkg::ar_width(cfg.AddrWidth, cfg.InIdWidth, cfg.UserWidth);
      AxiR: return axi_pkg::r_width(cfg.DataWidth, cfg.InIdWidth, cfg.UserWidth);
      default: $error("Invalid AXI channel");
    endcase
  endfunction

  /// Returns the number of bits of an AXI channel for a narrow-wide AXI config
  function automatic int unsigned get_nw_chan_width(axi_cfg_t cfg_n, axi_cfg_t cfg_w, nw_ch_e ch);
    case (ch)
      NarrowAw: return axi_pkg::aw_width(cfg_n.AddrWidth, cfg_n.InIdWidth, cfg_n.UserWidth);
      NarrowW: return axi_pkg::w_width(cfg_n.DataWidth, cfg_n.UserWidth);
      NarrowAr: return axi_pkg::ar_width(cfg_n.AddrWidth, cfg_n.InIdWidth, cfg_n.UserWidth);
      NarrowB: return axi_pkg::b_width(cfg_n.InIdWidth, cfg_n.UserWidth);
      NarrowR: return axi_pkg::r_width(cfg_n.DataWidth, cfg_n.InIdWidth, cfg_n.UserWidth);
      WideAw: return axi_pkg::aw_width(cfg_w.AddrWidth, cfg_w.InIdWidth, cfg_w.UserWidth);
      WideW: return axi_pkg::w_width(cfg_w.DataWidth, cfg_w.UserWidth);
      WideR: return axi_pkg::r_width(cfg_w.DataWidth, cfg_w.InIdWidth, cfg_w.UserWidth);
      WideAr: return axi_pkg::ar_width(cfg_w.AddrWidth, cfg_w.InIdWidth, cfg_w.UserWidth);
      WideB: return axi_pkg::b_width(cfg_w.InIdWidth, cfg_w.UserWidth);
      default: $error("Invalid AXI channel");
    endcase
  endfunction

  /// Calculates the maximum payload bits required for a link, based on the single-AXI
  /// channel mapping
  function automatic int unsigned get_max_axi_payload_bits(axi_cfg_t cfg, floo_chan_e ch);
    int unsigned max_payload_bits = 0;
    for (int unsigned i = 0; i < NumAxiChannels; i++) begin
      if (axi_chan_mapping(axi_ch_e'(i)) == ch) begin
        if (get_axi_chan_width(cfg, axi_ch_e'(i)) > max_payload_bits) begin
          max_payload_bits = get_axi_chan_width(cfg, axi_ch_e'(i));
        end
      end
    end
    return max_payload_bits + 1; // +1 because we need at least one `rsvd` bit
  endfunction

  /// Calculates the maximum payload bits required for a link, based on the narrow-wide AXI
  /// channel mapping
  function automatic int unsigned get_max_nw_payload_bits(
    axi_cfg_t cfg_n, axi_cfg_t cfg_w, floo_chan_e ch);
    int unsigned max_payload_bits = 0;
    for (int unsigned i = 0; i < NumNWAxiChannels; i++) begin
      if (nw_chan_mapping(nw_ch_e'(i)) == ch) begin
        if (get_nw_chan_width(cfg_n, cfg_w, nw_ch_e'(i)) > max_payload_bits) begin
          max_payload_bits = get_nw_chan_width(cfg_n, cfg_w, nw_ch_e'(i));
        end
      end
    end
    return max_payload_bits + 1; // +1 because we need at least one `rsvd` bit
  endfunction

  /// Calculates the number of unused (i.e. reserved) bits in a link for a specific
  /// AXI channel payload in a single-AXI config
  function automatic int unsigned get_axi_rsvd_bits(axi_cfg_t cfg, axi_ch_e ch);
    return get_max_axi_payload_bits(cfg, axi_chan_mapping(ch)) -
                                    get_axi_chan_width(cfg, ch);
  endfunction

  /// Calculates the number of unused (i.e. reserved) bits in a link for a specific
  /// AXI channel payload in a narrow-wide AXI config
  function automatic int unsigned get_nw_rsvd_bits(axi_cfg_t cfg_n, axi_cfg_t cfg_w, nw_ch_e ch);
    return get_max_nw_payload_bits(cfg_n, cfg_w, nw_chan_mapping(ch)) -
                                   get_nw_chan_width(cfg_n, cfg_w, ch);
  endfunction

endpackage
