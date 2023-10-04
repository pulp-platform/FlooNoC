// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_axi_chimney
  import floo_pkg::*;
  import floo_axi_pkg::*;
  import floo_test_pkg::*;
(
  input  logic      clk_i,
  input  logic      rst_ni,
  input  axi_in_req_t  axi_in_req_i,
  output axi_in_rsp_t  axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input  axi_out_rsp_t axi_out_rsp_i,
  input  xy_id_t    xy_id_i,
  output floo_req_t floo_req_o,
  output floo_rsp_t floo_rsp_o,
  input  floo_req_t floo_req_i,
  input  floo_rsp_t floo_rsp_i
);


  floo_axi_chimney #(
    .RouteAlgo          ( floo_pkg::XYRouting ),
    .XYAddrOffsetX      ( 32'd16              ),
    .XYAddrOffsetY      ( 32'd20              ),
    .MaxTxnsPerId       ( MaxTxnsPerId        ),
    .ReorderBufferSize  ( ReorderBufferSize   ),
    .xy_id_t            ( xy_id_t             )
  ) i_floo_axi_chimney (
    .clk_i,
    .rst_ni,
    .test_enable_i(1'b0),
    .sram_cfg_i('0),
    .axi_in_req_i,
    .axi_in_rsp_o,
    .axi_out_req_o,
    .axi_out_rsp_i,
    .id_i('0),
    .xy_id_i,
    .floo_req_o,
    .floo_rsp_o,
    .floo_req_i,
    .floo_rsp_i
  );

endmodule
