// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_axi_chimney
  import floo_pkg::*;
  import floo_axi_flit_pkg::*;
  import floo_param_pkg::*;
(
  input  logic      clk_i,
  input  logic      rst_ni,
  input  axi_in_req_t  axi_in_req_i,
  output axi_in_resp_t axi_in_rsp_o,
  output axi_out_req_t  axi_out_req_o,
  input  axi_out_resp_t axi_out_rsp_i,
  input  xy_id_t    xy_id_i,
  output req_flit_t req_o,
  output rsp_flit_t rsp_o,
  input  req_flit_t req_i,
  input  rsp_flit_t rsp_i
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
    .req_o,
    .rsp_o,
    .req_i,
    .rsp_i
  );

endmodule
