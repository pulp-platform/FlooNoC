// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_narrow_wide_chimney
  import floo_pkg::*;
  import floo_narrow_wide_flit_pkg::*;
  import floo_param_pkg::*;
(
  input  logic          clk_i,
  input  logic          rst_ni,
  input  narrow_in_req_t   narrow_in_req_i,
  output narrow_in_resp_t  narrow_in_rsp_o,
  output narrow_out_req_t   narrow_out_req_o,
  input  narrow_out_resp_t  narrow_out_rsp_i,
  input  wide_in_req_t     wide_in_req_i,
  output wide_in_resp_t    wide_in_rsp_o,
  output wide_out_req_t     wide_out_req_o,
  input  wide_out_resp_t    wide_out_rsp_i,
  input  xy_id_t        xy_id_i,
  output narrow_req_flit_t narrow_req_o,
  output narrow_rsp_flit_t narrow_rsp_o,
  input  narrow_req_flit_t narrow_req_i,
  input  narrow_rsp_flit_t narrow_rsp_i,
  output wide_flit_t wide_o,
  input  wide_flit_t wide_i
);


floo_narrow_wide_chimney #(
  .RouteAlgo                ( floo_pkg::XYRouting     ),
  .XYAddrOffsetX            ( 32'd16                  ),
  .XYAddrOffsetY            ( 32'd20                  ),
  .NarrowMaxTxns            ( NarrowMaxTxnsPerId      ),
  .WideMaxTxns              ( WideMaxTxnsPerId        ),
  .NarrowMaxTxnsPerId       ( NarrowMaxTxnsPerId      ),
  .WideMaxTxnsPerId         ( WideMaxTxnsPerId        ),
  .NarrowReorderBufferSize  ( NarrowReorderBufferSize ),
  .WideReorderBufferSize    ( WideReorderBufferSize   ),
  .NarrowRoBSimple          ( NarrowRoBSimple         ),
  .WideRoBSimple            ( WideRoBSimple           ),
  .CutAx                    ( CutAx                   ),
  .CutRsp                   ( CutRsp                  ),
  .xy_id_t                  ( xy_id_t                 )
) i_floo_narrow_wide_chimney (
  .clk_i,
  .rst_ni,
  .test_enable_i(1'b0),
  .sram_cfg_i('0),
  .id_i('0),
  .xy_id_i,
  .narrow_in_req_i,
  .narrow_in_rsp_o,
  .narrow_out_req_o,
  .narrow_out_rsp_i,
  .wide_in_req_i,
  .wide_in_rsp_o,
  .wide_out_req_o,
  .wide_out_rsp_i,
  .narrow_req_i,
  .narrow_rsp_o,
  .narrow_req_o,
  .narrow_rsp_i,
  .wide_o,
  .wide_i
);

endmodule
