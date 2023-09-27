// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "floo_noc/typedef.svh"

package floo_test_pkg;

  import floo_pkg::*;

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

  // Chimney parameters
  localparam bit CutAx = 1'b1;
  localparam bit CutRsp = 1'b0;
  localparam int unsigned MaxTxnsPerId = 16;
  localparam rob_type_e RoBType = NormalRoB;
  localparam int unsigned ReorderBufferSize = 32'd64;

  // Narrow Wide Chimney parameters
  localparam bit NarrowRoBSimple = 1'b1;
  localparam int unsigned NarrowMaxTxnsPerId = 4;
  localparam rob_type_e NarrowRoBType = NoRoB;
  localparam int unsigned NarrowReorderBufferSize = 32'd256;
  localparam int unsigned WideMaxTxnsPerId = 32;
  localparam rob_type_e WideRoBType = NoRoB;
  localparam int unsigned WideReorderBufferSize = 32'd128;

  `FLOO_NOC_TYPEDEF_XY_ID_T(xy_id_t, NumX, NumY)

endpackage
