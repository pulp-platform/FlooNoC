// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>
// - Michael Rogenmoser <michaero@iis.ee.ethz.ch>

/// Currently only contains useful functions and some constants and typedefs
package floo_pkg;

  // Support Routing Algorithms
  typedef enum logic[1:0] {
    IdTable,
    SourceRouting,
    XYRouting
  } route_algo_e;

  typedef enum logic[2:0] {
    North = 3'd0, // y increasing
    East  = 3'd1, // x increasing
    South = 3'd2, // y decreasing
    West  = 3'd3, // x decreasing
    Eject = 3'd4, // target/destination
    NumDirections
  } route_direction_e;

  typedef enum  {
    RucheNorth = 'd5,
    RucheEast  = 'd6,
    RucheSouth = 'd7,
    RucheWest  = 'd8
  } ruche_direction_e;

  typedef enum logic [1:0] {
    NormalRoB,
    SimpleRoB,
    NoRoB
  } rob_type_e;

  typedef enum logic [2:0] {
    AxiAw = 3'd0,
    AxiW = 3'd1,
    AxiAr = 3'd2,
    AxiB = 3'd3,
    AxiR = 3'd4,
    NumAxiChannels = 3'd5
  } axi_ch_e;

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

  typedef enum logic [1:0] {
    FlooReq = 2'd0,
    FlooRsp = 2'd1,
    FlooWide = 2'd2
  } floo_chan_e;

  typedef struct packed {
    int unsigned AddrWidth;
    int unsigned DataWidth;
    int unsigned UserWidth;
    int unsigned InIdWidth;
    int unsigned OutIdWidth;
  } axi_cfg_t;

  typedef struct packed {
    route_algo_e RouteAlgo;
    bit UseIdTable;
    int unsigned XYAddrOffsetX;
    int unsigned XYAddrOffsetY;
    int unsigned IdAddrOffset;
    int unsigned NumSamRules;
    int unsigned NumRoutes;
  } route_cfg_t;

  typedef struct packed {
    bit EnSbrPort;
    bit EnMgrPort;
    int unsigned MaxTxns;
    int unsigned MaxUniqueIds;
    int unsigned MaxTxnsPerId;
    rob_type_e BRoBType;
    int unsigned BRoBDepth;
    rob_type_e RRoBType;
    int unsigned RRoBDepth;
    bit CutAx;
    bit CutRsp;
  } chimney_cfg_t;

  localparam chimney_cfg_t ChimneyDefaultCfg = '{
    EnSbrPort: 1'b1,
    EnMgrPort: 1'b1,
    MaxTxns: 32,
    MaxUniqueIds: 1,
    MaxTxnsPerId: 32,
    BRoBType: NoRoB,
    BRoBDepth: 0,
    RRoBType: NoRoB,
    RRoBDepth: 0,
    CutAx: 1'b0,
    CutRsp: 1'b0
  };

  localparam route_cfg_t RouteDefaultCfg = '{
    RouteAlgo: XYRouting,
    UseIdTable: 1'b0,
    XYAddrOffsetX: 0,
    XYAddrOffsetY: 0,
    IdAddrOffset: 0,
    NumSamRules: 0,
    NumRoutes: 0
  };

  function automatic floo_chan_e axi_chan_mapping(axi_ch_e ch);
    if (ch == AxiAw || ch == AxiW || ch == AxiAr) begin
      return FlooReq;
    end else begin
      return FlooRsp;
    end
  endfunction

  function automatic floo_chan_e nw_chan_mapping(nw_ch_e ch);
    if (ch == NarrowAw || ch == NarrowW || ch == NarrowAr || ch == WideAr) begin
      return FlooReq;
    end else if (ch == WideAw || ch == WideW || ch == WideR) begin
      return FlooWide;
    end else begin
      return FlooRsp;
    end
  endfunction

  function automatic axi_cfg_t axi_cfg_swap_iw(axi_cfg_t cfg);
    return '{
      AddrWidth: cfg.AddrWidth,
      DataWidth: cfg.DataWidth,
      UserWidth: cfg.UserWidth,
      InIdWidth: cfg.OutIdWidth,
      OutIdWidth: cfg.InIdWidth
    };
  endfunction

  function automatic chimney_cfg_t set_ports(chimney_cfg_t cfg, bit en_sbr, bit en_mgr);
    cfg.EnSbrPort = en_sbr;
    cfg.EnMgrPort = en_mgr;
    return cfg;
  endfunction

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

  function automatic int unsigned get_axi_rsvd_bits(axi_cfg_t cfg, axi_ch_e ch);
    return get_max_axi_payload_bits(cfg, axi_chan_mapping(ch)) -
                                    get_axi_chan_width(cfg, ch);
  endfunction

  function automatic int unsigned get_nw_rsvd_bits(axi_cfg_t cfg_n, axi_cfg_t cfg_w, nw_ch_e ch);
    return get_max_nw_payload_bits(cfg_n, cfg_w, nw_chan_mapping(ch)) -
                                   get_nw_chan_width(cfg_n, cfg_w, ch);
  endfunction

endpackage
