// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_nw_chimney
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
  import floo_synth_collective_pkg::*;
  import endpoint_axi_pkg::*;
  #(
    parameter bit EnCollective = 1'b0
  ) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  endpoint_axi_pkg::narrow_out_req_t  axi_narrow_in_req_i,
  output endpoint_axi_pkg::narrow_out_resp_t  axi_narrow_in_rsp_o,
  output endpoint_axi_pkg::narrow_in_req_t axi_narrow_out_req_o,
  input  endpoint_axi_pkg::narrow_in_resp_t axi_narrow_out_rsp_i,
  input  endpoint_axi_pkg::wide_out_req_t    axi_wide_in_req_i,
  output endpoint_axi_pkg::wide_out_resp_t    axi_wide_in_rsp_o,
  output endpoint_axi_pkg::wide_in_req_t   axi_wide_out_req_o,
  input  endpoint_axi_pkg::wide_in_resp_t   axi_wide_out_rsp_i,
  input  id_t id_i,
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,
  output floo_req_t  floo_req_o,
  output floo_rsp_t  floo_rsp_o,
  input  floo_req_t  floo_req_i,
  input  floo_rsp_t  floo_rsp_i,
  output floo_wide_t floo_wide_o,
  input  floo_wide_t floo_wide_i
);

localparam floo_pkg::route_cfg_t RouteCfgColl = (EnCollective) ? CollectRouteCfg : RouteCfg;

  floo_nw_chimney #(
    .AxiCfgN              ( AxiCfgN               ),
    .AxiCfgW              ( AxiCfgW               ),
    .ChimneyCfgN          ( ChimneyCfg            ),
    .ChimneyCfgW          ( ChimneyCfg            ),
    .RouteCfg             ( RouteCfgColl          ), //TODO (lleone): change to enable multicast/collective
    .AtopSupport          ( AtopSupport           ),
    .EnDecoupledRW        ( 1'b0                  ),
    .MaxAtomicTxns        ( MaxAtomicTxns         ),
    // SAM?
    .id_t                 ( id_t                  ),
    .route_t              ( route_t               ),
    .dst_t                ( route_t               ),
    .hdr_t                ( hdr_t                 ),
    .sam_rule_t           ( sam_multicast_rule_t  ), //TODO (lleone) handled unicast case
    .sam_idx_t            ( sam_idx_t             ), //TODO (lleone) handled unicast case
    .mask_sel_t           ( mask_sel_t            ), //TODO (lleone) handled unicast case
    .axi_narrow_in_req_t  ( endpoint_axi_pkg::narrow_out_req_t),
    .axi_narrow_in_rsp_t  ( endpoint_axi_pkg::narrow_out_resp_t),
    .axi_narrow_out_req_t ( endpoint_axi_pkg::narrow_in_req_t),
    .axi_narrow_out_rsp_t ( endpoint_axi_pkg::narrow_in_resp_t),
    .axi_wide_in_req_t    ( endpoint_axi_pkg::wide_out_req_t),
    .axi_wide_in_rsp_t    ( endpoint_axi_pkg::wide_out_resp_t),
    .axi_wide_out_req_t   ( endpoint_axi_pkg::wide_in_req_t),
    .axi_wide_out_rsp_t   ( endpoint_axi_pkg::wide_in_resp_t),

    .floo_req_t           ( floo_req_t            ),
    .floo_rsp_t           ( floo_rsp_t            ),
    .floo_wide_t          ( floo_wide_t           ),
    .floo_wide_in_t       ( floo_wide_double_t    ),
    .user_narrow_struct_t ( collective_narrow_user_t),
    .user_wide_struct_t   ( collective_wide_user_t)
  ) i_floo_nw_chimney (
    .clk_i                ( clk_i                 ),
    .rst_ni               ( rst_ni                ),
    .test_enable_i        ( test_enable_i         ),
    .sram_cfg_i           ( '0                    ),
    .axi_narrow_in_req_i  ( axi_narrow_in_req_i   ),
    .axi_narrow_in_rsp_o  ( axi_narrow_in_rsp_o   ),
    .axi_narrow_out_req_o ( axi_narrow_out_req_o  ),
    .axi_narrow_out_rsp_i ( axi_narrow_out_rsp_i  ),
    .axi_wide_in_req_i    ( axi_wide_in_req_i     ),
    .axi_wide_in_rsp_o    ( axi_wide_in_rsp_o     ),
    .axi_wide_out_req_o   ( axi_wide_out_req_o    ),
    .axi_wide_out_rsp_i   ( axi_wide_out_rsp_i    ),
    .id_i                 ( id_i                  ),
    .route_table_i        ( route_table_i         ),
    .floo_req_o           ( floo_req_o            ),
    .floo_rsp_o           ( floo_rsp_o            ),
    .floo_wide_o          ( floo_wide_o           ),
    .floo_req_i           ( floo_req_i            ),
    .floo_rsp_i           ( floo_rsp_i            ),
    .floo_wide_i          ( floo_wide_i           )
  );

endmodule
