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
  typedef enum logic[1:0] {
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
    XYRouting
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

  /// TODO(lleone): delet this portion of code
  // /// The types of collective communication
  // typedef enum logic [1:0] {
  //   /// Normal communication
  //   Unicast = 2'd0,
  //   /// Multicast communication
  //   Multicast = 2'd1,
  //   /// Parallel reduction operations
  //   ParallelReduction = 2'd2,
  //   /// Offload Reduction
  //   OffloadReduction = 2'd3
  // } collect_comm_e;

  // /// Different offloadable reduction
  // typedef enum logic [3:0] {
  //   R_Select  = 4'b0000, // Select the first incoming flit
  //   F_Add     = 4'b0100, // FP Addition
  //   F_Mul     = 4'b0101, // FP Multiplication
  //   F_Min     = 4'b0110, // FP Min
  //   F_Max     = 4'b0111, // FP Max
  //   A_Add     = 4'b1000, // Atomic Add (signed)
  //   A_Mul     = 4'b1001, // (Non-) Atomic (signed)
  //   A_Min_S   = 4'b1010, // Atomic Min (signed)
  //   A_Min_U   = 4'b1110, // Atomic Min (unsigned)
  //   A_Max_S   = 4'b1011, // Atomic Max (signed)
  //   A_Max_U   = 4'b1111  // Atomic Max (unsigned)
  // } reduction_offload_op_e;

  // /// Different instantanous reduction
  // typedef enum logic [3:0] {
  //   SelectAW  = 4'b0000,  // Select the first incoming flit
  //   CollectB  = 4'b0001,  // Collect the B responses from an AXI transmission
  //   LSBAnd    = 4'b0010   // AND Connect the LSB of the payload (useful for barrier ops)
  // } reduction_parallel_op_e;


  /// Union for both Datatype(s) - because they need to have the same size for the chimney
  /// The chimney needs this information as it does not know if we support an offload reduction
  /// or an parallel reduction.
  // typedef union packed {
  //   reduction_offload_op_e op_offload;
  //   reduction_parallel_op_e op_parallel;
  // } reduction_op_t;

  /// List of supported collective operations in the NoC
  /// These are "micro" collective operations. For example an AXI
  /// multicast is split into a generic multicast + reduction
  /// of teh B responses (CollectB).
  /// The internal micro operations must be in teh MSB to make sure
  /// the user will never issue those
  typedef enum logic [3:0] {
    Unicast   = 4'b0000,  // Unicast operation
    Multicast = 4'b0001,  // Multicast communication
    LSBAnd    = 4'b0010,  // AND Connect the LSB of the payload
    F_Add     = 4'b0011,  // FP Addition
    F_Mul     = 4'b0100,  // FP Multiplication
    F_Min     = 4'b0101,  // FP Min
    F_Max     = 4'b0110,  // FP Max
    A_Add     = 4'b0111,  // Atomic Add (signed)
    A_Mul     = 4'b1000,  // (Non-) Atomic (signed)
    A_Min_S   = 4'b1001,  // Atomic Min (signed)
    A_Min_U   = 4'b1010,  // Atomic Min (unsigned)
    A_Max_S   = 4'b1011,  // Atomic Max (signed)
    A_Max_U   = 4'b1100,  // Atomic Max (unsigned)
    SelectAW  = 4'b1101,  // Select first incoming AW flit
    CollectB  = 4'b1110,  // Collect B responses for AXI transmisison
    //  TODO(lleone): Remove this operation and chenag the offload logic to make
    // handle the selectAW from the parallel reduction harware
    SeqAW     = 4'b1111   // Select the first incoming flit from a sequential reduction
  } collect_op_e;

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

  /// Collective operations to support in teh NoC
  /// In this context collective operations are macro
  /// operations, i.e. multicast, reduction etc...
  /// The user does not have to care about the hidden
  /// transfers required to implement these macro colelctive.
  typedef struct packed {
    /// Enable multicast transcation support on the narrow router
    bit EnNarrowMulticast;
    /// Enable multicast transcation support on the wide router
    bit EnWideMulticast;
    /// Enable LSB and operation support
    bit EnLSBAnd;
    /// Enable FP addition support
    bit EnF_Add;
    /// Enable FP multiplier support
    bit EnF_Mul;
    /// Enable FP minimum calculation support
    bit EnF_Min;
    /// Enable FP maximum calculationn support
    bit EnF_Max;
    /// Enable INT addition support
    bit EnA_Add;
    /// Enable INT multiplier support
    bit EnA_Mul;
    /// Enable INT signed minimum calculation support
    bit EnA_Min_S;
    /// Enable INT unsigned minimum calculation support
    bit EnA_Min_U;
    /// Enable INT signed maximum calculation support
    bit EnA_Max_S;
    /// Enable INT unsigned maximum calculation support
    bit EnA_Max_U;
  } collect_op_cfg_t;

  typedef logic [3:0] collect_op_t;

  /// Controller configuration
  typedef enum logic [1:0] {
    /// Simple configuration
    ControllerSimple = 2'd0,
    /// Stalling configuration
    ControllerStalling = 2'd1,
    /// Generic configuration
    ControllerGeneric = 2'd2
  } floo_red_controller_e;

  /// Configuration for the offload reduction logic
  typedef struct packed {
    /// configuration for the controller
    floo_red_controller_e RdControllConf;
    /// input fifo configuration
    bit RdFifoFallThrough;
    int unsigned RdFifoDepth;
    /// pipeline depth of the offload unit
    int unsigned RdPipelineDepth;
    /// partial buffer size
    int unsigned RdPartialBufferSize;
    /// required tag bit if generic controller is used
    int unsigned RdTagBits;
    /// is the underlying protocl AXI
    bit RdSupportAxi;
    /// enable the bypass (required for AXI-AW)
    bit RdEnableBypass;
    /// support loopback for the local link - collective will
    /// be forwarded to the local port too.
    bit RdSupportLoopback;
    /// Cut offload interface
    bit CutOffloadIntf;
  } reduction_cfg_t;

  /// Configuration to specify how extensive collective support is enabled
  typedef struct packed {
    collect_op_cfg_t OpCfg;
    reduction_cfg_t  RedCfg;
  } collective_cfg_t;

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
    /// Configuration to support collective operations
    collective_cfg_t CollectiveCfg;
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

  /// Default collective operations supported in the NoC - all disabled
  localparam collect_op_cfg_t CollectiveOpDefaultCfg = '{
    EnNarrowMulticast : 1'b0,
    EnWideMulticast   : 1'b0,
    EnLSBAnd          : 1'b0,
    EnF_Add           : 1'b0,
    EnF_Mul           : 1'b0,
    EnF_Min           : 1'b0,
    EnF_Max           : 1'b0,
    EnA_Add           : 1'b0,
    EnA_Mul           : 1'b0,
    EnA_Min_S         : 1'b0,
    EnA_Min_U         : 1'b0,
    EnA_Max_S         : 1'b0,
    EnA_Max_U         : 1'b0
  };

  /// The default configuration for the offload reduction unit
  localparam reduction_cfg_t ReductionDefaultCfg = '{
    RdControllConf: ControllerGeneric,
    RdFifoFallThrough: 1'b1,
    RdFifoDepth: 2,
    RdPipelineDepth: 5,
    RdPartialBufferSize: 3,
    RdTagBits: 5,
    RdSupportAxi: 1'b1,
    RdEnableBypass: 1'b1,
    RdSupportLoopback: 1'b1,
    CutOffloadIntf: 1'b1
  };

  /// The default configuration for collective operations
  localparam collective_cfg_t CollectiveDefaultCfg = '{
    OpCfg: CollectiveOpDefaultCfg,
    RedCfg: ReductionDefaultCfg
  };

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
    NumRoutes: 0,
    CollectiveCfg: CollectiveDefaultCfg
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

  /// Helper function to calculate the minimum of two unsigned integers
  function automatic int unsigned min(int unsigned a, int unsigned b);
    return (a < b) ? a : b;
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


  /**********************************************************
   *         Collective Communication Support               *
   **********************************************************/
  /* These functions help to abstract the complexity of the NoC and the
  /  implementation schemes for collective communication.
  /  The user is responsible to declare only which macro level collective
  /  operations are supported in the NoC (collect_op_cfg_t).
  /  The NoC implementation will then derive which type of hardware support
  /  is required (e.g. multicast, collectB, selectAW, etc...). This info
  /  is implementation specific and must be transparent to the user.
  */
  ///---------------------------------------------------------
  /// Helper functions to calculate which macro transaction are supported
  /// and which type of hardware support is required

  /// Calculates if the NoC needs support for Narrow parallel reduction
  function automatic bit is_en_parallel_reduction(collect_op_cfg_t cfg);
    return (cfg.EnLSBAnd);
  endfunction

  /// Calculates if the NoC needs support for Narrow sequential reduction
  function automatic bit is_en_narrow_seq_reduction(collect_op_cfg_t cfg);
    return (cfg.EnA_Add | cfg.EnA_Mul | cfg.EnA_Min_S |
            cfg.EnA_Min_U | cfg.EnA_Max_S | cfg.EnA_Max_U
            );
  endfunction

  /// Calculates if the NoC needs support for Narrow Sequential reduction
  function automatic bit is_en_narrow_reduction(collect_op_cfg_t cfg);
    return (is_en_narrow_seq_reduction(cfg) | is_en_parallel_reduction(cfg)
            );
  endfunction

  /// Calculates if the NoC needs support for Wide Sequential reduction
  /// there is no need to separate between parallel and sequential for the
  /// wide because only wide sequential is supported
  function automatic bit is_en_wide_reduction(collect_op_cfg_t cfg);
    return (cfg.EnF_Add | cfg.EnF_Mul |
            cfg.EnF_Min | cfg.EnF_Max
            );
  endfunction

  /// Calculate if narrow collective support is enabled
  function automatic bit is_en_narrow_collective(collect_op_cfg_t cfg);
    return (cfg.EnNarrowMulticast | is_en_narrow_reduction(cfg));
  endfunction

  /// Calculate if wide collective support is enabled
  function automatic bit is_en_wide_collective(collect_op_cfg_t cfg);
    return (cfg.EnWideMulticast | is_en_wide_reduction(cfg));
  endfunction

  /// Calculate if there is need for collective support
  function automatic bit is_en_collective(collect_op_cfg_t cfg);
    return (is_en_wide_collective(cfg) | is_en_narrow_collective(cfg));
  endfunction

  ///---------------------------------------------------------
  /// Helper functions to translate internal opcodes in macro transactions
  /// Evaluate if the incoming operation is a multicast operation
  function automatic bit is_multicast_op(collect_op_e op);
    return (op == Multicast);
  endfunction

  /// Evaluate if the incoming operation is a reduction operation
  function automatic bit is_reduction_op(collect_op_e op);
    case (op)
      F_Add, F_Mul, F_Min, F_Max, LSBAnd, SelectAW, SeqAW,
      A_Add, A_Mul, A_Min_S, A_Min_U, A_Max_S,
      A_Max_U: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  /// Evaluate if the incoming operation is a parallel reduction
  function automatic bit is_parallel_reduction_op(collect_op_e op);
    return (op == LSBAnd | op == CollectB | op == SelectAW);
  endfunction

  /// Evaluate if the incoming operation is a sequential reduction
  function automatic bit is_sequential_reduction_op(collect_op_e op);
    case (op)
      F_Add, F_Mul, F_Min, F_Max, SeqAW,
      A_Add, A_Mul, A_Min_S, A_Min_U, A_Max_S,
      A_Max_U: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

endpackage
