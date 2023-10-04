// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_narrow_wide_chimney
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
  import floo_test_pkg::*;
(
  input  logic          clk_i,
  input  logic          rst_ni,
  input  axi_narrow_in_req_t   axi_narrow_in_req_i,
  output axi_narrow_in_rsp_t  axi_narrow_in_rsp_o,
  output axi_narrow_out_req_t   axi_narrow_out_req_o,
  input  axi_narrow_out_rsp_t  axi_narrow_out_rsp_i,
  input  axi_wide_in_req_t     axi_wide_in_req_i,
  output axi_wide_in_rsp_t    axi_wide_in_rsp_o,
  output axi_wide_out_req_t     axi_wide_out_req_o,
  input  axi_wide_out_rsp_t    axi_wide_out_rsp_i,
  input  xy_id_t        xy_id_i,
  output floo_req_t  floo_req_o,
  output floo_rsp_t  floo_rsp_o,
  input  floo_req_t  floo_req_i,
  input  floo_rsp_t  floo_rsp_i,
  output floo_wide_t floo_wide_o,
  input  floo_wide_t floo_wide_i
);

`ifdef TARGET_GF12
  typedef struct packed {
    logic [2:0] ema;
    logic [1:0] emaw;
    logic [0:0] emas;
  } sram_cfg_t;
`else
  typedef logic sram_cfg_t;
`endif

floo_narrow_wide_chimney #(
  .RouteAlgo                ( floo_pkg::XYRouting     ),
  .XYAddrOffsetX            ( 32'd16                  ),
  .XYAddrOffsetY            ( 32'd20                  ),
  .NarrowMaxTxns            ( NarrowMaxTxnsPerId      ),
  .WideMaxTxns              ( WideMaxTxnsPerId        ),
  .NarrowMaxTxnsPerId       ( NarrowMaxTxnsPerId      ),
  .WideMaxTxnsPerId         ( WideMaxTxnsPerId        ),
  .NarrowRoBType            ( NarrowRoBType           ),
  .WideRoBType              ( WideRoBType             ),
  .NarrowReorderBufferSize  ( NarrowReorderBufferSize ),
  .WideReorderBufferSize    ( WideReorderBufferSize   ),
  .CutAx                    ( CutAx                   ),
  .CutRsp                   ( CutRsp                  ),
  .xy_id_t                  ( xy_id_t                 ),
  .sram_cfg_t               ( sram_cfg_t              )
) i_floo_narrow_wide_chimney (
  .clk_i,
  .rst_ni,
  .test_enable_i(1'b0),
  .sram_cfg_i('0),
  .id_i('0),
  .id_map_i ('0),
  .xy_id_i,
  .axi_narrow_in_req_i,
  .axi_narrow_in_rsp_o,
  .axi_narrow_out_req_o,
  .axi_narrow_out_rsp_i,
  .axi_wide_in_req_i,
  .axi_wide_in_rsp_o,
  .axi_wide_out_req_o,
  .axi_wide_out_rsp_i,
  .floo_req_i,
  .floo_rsp_o,
  .floo_req_o,
  .floo_rsp_i,
  .floo_wide_o,
  .floo_wide_i
);

endmodule
