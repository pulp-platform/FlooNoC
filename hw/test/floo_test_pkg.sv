// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "floo_noc/typedef.svh"

package floo_test_pkg;

  typedef enum {
    FastSlave,
    SlowSlave,
    MixedSlave
  } slave_type_e;

  // System parameters
  localparam int unsigned NumX = 4;
  localparam int unsigned NumY = 4;

  // Router parameters
  localparam int unsigned NumRoutes = 5;
  localparam int unsigned ChannelFifoDepth  = 2;
  localparam int unsigned OutputFifoDepth   = 2;

  // Default route config for testing
  localparam floo_pkg::route_cfg_t RouteCfg = '{
    RouteAlgo: floo_pkg::XYRouting,
    UseIdTable: 0,
    XYAddrOffsetX: 16,
    XYAddrOffsetY: 20,
    IdAddrOffset: 0,
    NumSamRules: 0,
    NumRoutes: 0
  };

  // Common chimney parameters
  localparam bit AtopSupport = 1'b1;
  localparam int unsigned MaxAtomicTxns = 4;

  // Axi chimney parameters
  localparam floo_pkg::axi_cfg_t AxiCfg = '{
    AddrWidth: 32,
    DataWidth: 64,
    UserWidth: 1,
    InIdWidth: 3,
    OutIdWidth: 3
  };

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

  // Default chimney config for testing
  localparam floo_pkg::chimney_cfg_t ChimneyCfg = floo_pkg::ChimneyDefaultCfg;

endpackage
