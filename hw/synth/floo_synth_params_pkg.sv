// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_synth_params_pkg;

  // Router parameters
  localparam int unsigned InFifoDepth = 2;
  localparam int unsigned OutFifoDepth = 2;

  // Default route config for testing
  localparam floo_pkg::route_cfg_t RouteCfg = '{
    RouteAlgo: floo_pkg::SourceRouting,
    UseIdTable: 0,
    XYAddrOffsetX: 16,
    XYAddrOffsetY: 20,
    IdAddrOffset: 0,
    NumSamRules: 22,
    NumRoutes: 5,
    default: '0 // Potentially enable Multicast features
  };

  // Common chimney parameters
  localparam bit AtopSupport = 1'b1;
  localparam int unsigned MaxAtomicTxns = 4;

  // Default chimney config for testing
  localparam floo_pkg::chimney_cfg_t ChimneyCfg = '{
    EnSbrPort: 1'b1,
    EnMgrPort: 1'b1,
    MaxTxns: 32,
    MaxUniqueIds: 1,
    MaxTxnsPerId: 32,
    BRoBType: floo_pkg::NoRoB,
    BRoBSize: 0,
    RRoBType: floo_pkg::NoRoB,
    RRoBSize: 0,
    CutAx: 1'b0,
    CutRsp: 1'b0
  };

  typedef logic rob_idx_t;
  typedef logic port_id_t;
  typedef logic [4:0] id_t;
  typedef logic [20:0] route_t;

  localparam int unsigned SamNumRules = 22;

  typedef struct packed {
    id_t idx;
    logic [47:0] start_addr;
    logic [47:0] end_addr;
  } sam_rule_t;

  localparam sam_rule_t [SamNumRules-1:0] Sam = '{
    '{idx: 21, start_addr: 48'h000000000000, end_addr: 48'h00000000ffff},  // peripherals_ni
    '{idx: 22, start_addr: 48'h010000000000, end_addr: 48'h010100000000},  // serial_link_ni
    '{idx: 20, start_addr: 48'h000140000000, end_addr: 48'h000180000000},  // hbm_ni_3
    '{idx: 19, start_addr: 48'h000100000000, end_addr: 48'h000140000000},  // hbm_ni_2
    '{idx: 18, start_addr: 48'h0000c0000000, end_addr: 48'h000100000000},  // hbm_ni_1
    '{idx: 17, start_addr: 48'h000080000000, end_addr: 48'h0000c0000000},  // hbm_ni_0
    '{idx: 15, start_addr: 48'h0000103c0000, end_addr: 48'h000010400000},  // cluster_ni_3_3
    '{idx: 14, start_addr: 48'h000010380000, end_addr: 48'h0000103c0000},  // cluster_ni_3_2
    '{idx: 13, start_addr: 48'h000010340000, end_addr: 48'h000010380000},  // cluster_ni_3_1
    '{idx: 12, start_addr: 48'h000010300000, end_addr: 48'h000010340000},  // cluster_ni_3_0
    '{idx: 11, start_addr: 48'h0000102c0000, end_addr: 48'h000010300000},  // cluster_ni_2_3
    '{idx: 10, start_addr: 48'h000010280000, end_addr: 48'h0000102c0000},  // cluster_ni_2_2
    '{idx: 9, start_addr: 48'h000010240000, end_addr: 48'h000010280000},  // cluster_ni_2_1
    '{idx: 8, start_addr: 48'h000010200000, end_addr: 48'h000010240000},  // cluster_ni_2_0
    '{idx: 7, start_addr: 48'h0000101c0000, end_addr: 48'h000010200000},  // cluster_ni_1_3
    '{idx: 6, start_addr: 48'h000010180000, end_addr: 48'h0000101c0000},  // cluster_ni_1_2
    '{idx: 5, start_addr: 48'h000010140000, end_addr: 48'h000010180000},  // cluster_ni_1_1
    '{idx: 4, start_addr: 48'h000010100000, end_addr: 48'h000010140000},  // cluster_ni_1_0
    '{idx: 3, start_addr: 48'h0000100c0000, end_addr: 48'h000010100000},  // cluster_ni_0_3
    '{idx: 2, start_addr: 48'h000010080000, end_addr: 48'h0000100c0000},  // cluster_ni_0_2
    '{idx: 1, start_addr: 48'h000010040000, end_addr: 48'h000010080000},  // cluster_ni_0_1
    '{idx: 0, start_addr: 48'h000010000000, end_addr: 48'h000010040000}  // cluster_ni_0_0

};


endpackage

package floo_synth_axi_pkg;

  import floo_synth_params_pkg::*;

  // Axi chimney parameters
  localparam floo_pkg::axi_cfg_t AxiCfg = '{
    AddrWidth: 32,
    DataWidth: 64,
    UserWidth: 1,
    InIdWidth: 3,
    OutIdWidth: 3
  };

  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::axi_ch_e, logic)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi, AxiCfg)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, AxiCfg, hdr_t)
  `FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)

endpackage

package floo_synth_nw_pkg;

  import floo_synth_params_pkg::*;

  localparam floo_pkg::axi_cfg_t AxiCfgN = '{
    AddrWidth: 48,
    DataWidth: 64,
    UserWidth: 5,
    InIdWidth: 4,
    OutIdWidth: 2
  };

  // AXI nw_chimney parameters
  localparam floo_pkg::axi_cfg_t AxiCfgW = '{
    AddrWidth: 48,
    DataWidth: 512,
    UserWidth: 1,
    InIdWidth: 3,
    OutIdWidth: 1
  };

  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in, AxiCfgN, AxiCfgW, hdr_t)
  `FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, req, rsp, wide)

endpackage


package floo_synth_nw_vc_pkg;

  import floo_synth_params_pkg::*;

  localparam floo_pkg::axi_cfg_t AxiCfgN = '{
    AddrWidth: 48,
    DataWidth: 64,
    UserWidth: 5,
    InIdWidth: 4,
    OutIdWidth: 2
  };

  // AXI nw_chimney parameters
  localparam floo_pkg::axi_cfg_t AxiCfgW = '{
    AddrWidth: 48,
    DataWidth: 512,
    UserWidth: 1,
    InIdWidth: 3,
    OutIdWidth: 1
  };

  localparam int NumVCWidth = 2;
  localparam type vc_id_t = logic[NumVCWidth:0];

  `FLOO_TYPEDEF_VC_HDR_T(vc_hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic, vc_id_t)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(vc_axi, vc_req, vc_rsp, vc_wide, axi_narrow_in, axi_wide_in, AxiCfgN, AxiCfgW, vc_hdr_t)
  `FLOO_TYPEDEF_NW_LINK_ALL(vc_req, vc_rsp, vc_wide, vc_req, vc_rsp, vc_wide)

endpackage
