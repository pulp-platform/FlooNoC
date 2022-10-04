// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_param_pkg;

  import floo_pkg::*;

  localparam int unsigned NumX = 5; // Number of tiles in X direction
  localparam int unsigned NumY = 5; // Number of tiles in Y direction

  // Already defined in floo_pkg
  localparam int unsigned RucheFactor       = 0;
  localparam int unsigned NumRoutes         = 5 + (RucheFactor > 0) * 4;
  localparam int unsigned ChannelFifoDepth  = 2;
  localparam int unsigned OutputFifoDepth   = 2;
  localparam route_algo_e RouteAlgo         = XYRouting;


  // Chimney parameters
  localparam bit CutAx = 1'b1;
  localparam bit CutRsp = 1'b0;
  localparam int unsigned MaxTxnsPerId = 16;
  localparam bit RoBSimple = 1'b0;
  localparam int unsigned ReorderBufferSize = 32'd64;
  // Narrow Wide Chimney parameters
  localparam bit NarrowRoBSimple = 1'b1;
  localparam int unsigned NarrowMaxTxnsPerId = 4;
  localparam int unsigned NarrowReorderBufferSize = 32'd256;
  localparam bit WideRoBSimple = 1'b0;
  localparam int unsigned WideMaxTxnsPerId = 32;
  localparam int unsigned WideReorderBufferSize = 32'd128;

  `FLOO_NOC_TYPEDEF_XY_ID_T(xy_id_t, NumX, NumY)

endpackage
