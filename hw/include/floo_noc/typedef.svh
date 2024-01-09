// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`ifndef FLOO_NOC_TYPEDEF_SVH_
`define FLOO_NOC_TYPEDEF_SVH_

`define FLOO_NOC_TYPEDEF_FLIT_T(flit_t, FlitWidth) \
  typedef struct packed {           \
    logic [FlitWidth-1:0] data;     \
    logic                 last;     \
  } flit_t;

`define FLOO_NOC_TYPEDEF_ID_FLIT_T(flit_t, IdWidth, FlitWidth) \
  typedef struct packed {           \
    logic [FlitWidth-1:0] data;     \
    logic [IdWidth-1:0]   dst_id;   \
    logic                 last;     \
  } flit_t;

`define FLOO_NOC_TYPEDEF_XY_ID_T(xy_id_t, NumX, NumY) \
  typedef struct packed {                             \
    logic [$clog2(NumX)-1:0] x;                       \
    logic [$clog2(NumY)-1:0] y;                       \
  } xy_id_t;

`define FLOO_NOC_TYPEDEF_XY_FLIT_T(flit_t, xy_id_t, FlitWidth) \
  typedef struct packed {           \
    logic [FlitWidth-1:0] data;     \
    xy_id_t               dst_id;   \
    logic                 last;     \
  } flit_t;

`endif // FLOO_NOC_TYPEDEF_SVH_
