// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_axi_chimney
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_axi_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  axi_in_req_t  axi_in_req_i,
  output axi_in_rsp_t  axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input  axi_out_rsp_t axi_out_rsp_i,
  input  id_t id_i,
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,
  output floo_req_t floo_req_o,
  output floo_rsp_t floo_rsp_o,
  input  floo_req_t floo_req_i,
  input  floo_rsp_t floo_rsp_i
);

    floo_axi_chimney #(
      .AxiCfg         ( AxiCfg          ),
      .ChimneyCfg     ( ChimneyCfg      ),
      .RouteCfg       ( RouteCfg        ),
      .AtopSupport    ( AtopSupport     ),
      .MaxAtomicTxns  ( MaxAtomicTxns   ),
      .Sam            ( Sam             ),
      .id_t           ( id_t            ),
      .route_t        ( route_t         ),
      .dst_t          ( route_t         ),
      .hdr_t          ( hdr_t           ),
      .sam_rule_t     ( sam_rule_t      ),
      .axi_in_req_t   ( axi_in_req_t    ),
      .axi_in_rsp_t   ( axi_in_rsp_t    ),
      .axi_out_req_t  ( axi_out_req_t   ),
      .axi_out_rsp_t  ( axi_out_rsp_t   ),
      .floo_req_t     ( floo_req_t      ),
      .floo_rsp_t     ( floo_rsp_t      )
    ) i_floo_axi_chimney (
      .clk_i          ( clk_i         ),
      .rst_ni         ( rst_ni        ),
      .test_enable_i  ( test_enable_i ),
      .sram_cfg_i     ( '0            ),
      .axi_in_req_i   ( axi_in_req_i  ),
      .axi_in_rsp_o   ( axi_in_rsp_o  ),
      .axi_out_req_o  ( axi_out_req_o ),
      .axi_out_rsp_i  ( axi_out_rsp_i ),
      .id_i           ( id_i          ),
      .route_table_i  ( route_table_i ),
      .floo_req_o     ( floo_req_o    ),
      .floo_rsp_o     ( floo_rsp_o    ),
      .floo_req_i     ( floo_req_i    ),
      .floo_rsp_i     ( floo_rsp_i    )
    );

endmodule
