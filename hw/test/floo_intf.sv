// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A Floo AXI interface used for testing.
interface FLOO_LINK_DV
(
  input logic clk_i
);

  import floo_axi_pkg::*;

  floo_req_t floo_req_mgr;
  floo_rsp_t floo_rsp_mgr;
  floo_req_t floo_req_sbr;
  floo_rsp_t floo_rsp_sbr;

endinterface

/// A Floo narrow-wide interface used for testing.
interface FLOO_NW_LINK_DV
(
  input logic clk_i
);

  import floo_narrow_wide_pkg::*;

  floo_req_t floo_req_mgr;
  floo_rsp_t floo_rsp_mgr;
  floo_wide_t floo_wide_mgr;
  floo_req_t floo_req_sbr;
  floo_rsp_t floo_rsp_sbr;
  floo_wide_t floo_wide_sbr;

endinterface
