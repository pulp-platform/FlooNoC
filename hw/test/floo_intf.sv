// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A Floo AXI interface used for testing.

interface FLOO_LINK #(
  parameter int unsigned PayloadWidth = 64
);
  floo_axi_pkg::hdr_t hdr;
  logic [PayloadWidth-1:0] payload;
  logic valid;
  logic ready;

  modport manager (output hdr, output payload, output valid, input ready);
  modport subordinate (input hdr, input payload, input valid, output ready);
  modport monitor (input hdr, input payload, input valid, input ready);
endinterface

interface FLOO_LINK_DV #(
  parameter int unsigned PayloadWidth = 64
) (
  input logic clk_i
);
  floo_axi_pkg::hdr_t hdr;
  logic [PayloadWidth-1:0] payload;
  logic valid;
  logic ready;

  modport manager (output hdr, output payload, output valid, input ready);
  modport subordinate (input hdr, input payload, input valid, output ready);
  modport monitor (input hdr, input payload, input valid, input ready);
endinterface

interface FLOO_NW_LINK #(
  parameter int unsigned PayloadWidth = 64
);
  floo_narrow_wide_pkg::hdr_t hdr;
  logic [PayloadWidth-1:0] payload;
  logic valid;
  logic ready;

  modport manager (output hdr, output payload, output valid, input ready);
  modport subordinate (input hdr, input payload, input valid, output ready);
  modport monitor (input hdr, input payload, input valid, input ready);
endinterface

interface FLOO_NW_LINK_DV #(
  parameter int unsigned PayloadWidth = 64
) (
  input logic clk_i
);
  floo_narrow_wide_pkg::hdr_t hdr;
  logic [PayloadWidth-1:0] payload;
  logic valid;
  logic ready;

  modport manager (output hdr, output payload, output valid, input ready);
  modport subordinate (input hdr, input payload, input valid, output ready);
  modport monitor (input hdr, input payload, input valid, input ready);
endinterface
