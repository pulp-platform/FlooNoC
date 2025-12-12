// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_synth_params_pkg;
  import floo_pkg::*;

  // Router parameters
  localparam int unsigned InFifoDepth = 2;
  localparam int unsigned OutFifoDepth = 2;

  // Default route config for testing
  localparam floo_pkg::route_cfg_t RouteCfg = '{
    RouteAlgo: floo_pkg::XYRouting,
    UseIdTable: 0,
    XYAddrOffsetX: 16,
    XYAddrOffsetY: 20,
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

  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)

  // Unused types
  typedef logic route_t;

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
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in,
      AxiCfgN, AxiCfgW, hdr_t)
  `FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, req, rsp, wide)
  // Enable the following VC LINK when you want to experiment the use of virtual channels in collective
  // `FLOO_TYPEDEF_NW_VIRT_CHAN_LINK_ALL(req, rsp, wide, req, rsp, wide, 1, 2, 1)

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
  `FLOO_TYPEDEF_NW_CHAN_ALL(vc_axi, vc_req, vc_rsp, vc_wide, axi_narrow_in, axi_wide_in,
      AxiCfgN, AxiCfgW, vc_hdr_t)
  `FLOO_TYPEDEF_NW_LINK_ALL(vc_req, vc_rsp, vc_wide, vc_req, vc_rsp, vc_wide)

endpackage
