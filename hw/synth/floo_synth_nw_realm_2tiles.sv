// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Gianluca Bellocchi <gianluca.bellocchi@unimore.it>
//
// Inspired by `floo_synth_nw_2tiles`.
//
module floo_synth_nw_realm_2tiles
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
  import floo_synth_collective_pkg::*;
  import endpoint_axi_pkg::*;
#(
  parameter collective_cfg_idx_e CollectCfgIdx = floo_synth_collective_pkg::CollectNone,
  localparam int unsigned NumExtPorts = int'(NumDirections) - 2 // Cardinal links exposed per tile: all directions but `Eject` (chimney) and the inter-tile one.
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  // ---------------------------------------------------------------------------
  // Tile 0 (west).
  // ---------------------------------------------------------------------------
  input  id_t                                       id_0_i,
  input  route_t [floo_iomsb(RouteCfg.NumRoutes):0] route_table_0_i,
  // NoC interfaces
  input  floo_req_t  [NumExtPorts-1:0]        floo_req_0_i,
  input  floo_rsp_t  [NumExtPorts-1:0]        floo_rsp_0_i,
  output floo_req_t  [NumExtPorts-1:0]        floo_req_0_o,
  output floo_rsp_t  [NumExtPorts-1:0]        floo_rsp_0_o,
  input  floo_wide_t [NumExtPorts-1:0]        floo_wide_0_i,
  output floo_wide_t [NumExtPorts-1:0]        floo_wide_0_o,
  // Accelerator interfaces
  input  endpoint_axi_pkg::narrow_out_req_t   axi_narrow_in_0_req_i,
  output endpoint_axi_pkg::narrow_out_resp_t  axi_narrow_in_0_rsp_o,
  output endpoint_axi_pkg::narrow_in_req_t    axi_narrow_out_0_req_o,
  input  endpoint_axi_pkg::narrow_in_resp_t   axi_narrow_out_0_rsp_i,
  input  endpoint_axi_pkg::wide_out_req_t     axi_wide_in_0_req_i,
  output endpoint_axi_pkg::wide_out_resp_t    axi_wide_in_0_rsp_o,
  output endpoint_axi_pkg::wide_in_req_t      axi_wide_out_0_req_o,
  input  endpoint_axi_pkg::wide_in_resp_t     axi_wide_out_0_rsp_i,

  // ---------------------------------------------------------------------------
  // Tile 1 (east).
  // ---------------------------------------------------------------------------
  input  id_t                                       id_1_i,
  input  route_t [floo_iomsb(RouteCfg.NumRoutes):0] route_table_1_i,
  // NoC interfaces
  input  floo_req_t  [NumExtPorts-1:0]        floo_req_1_i,
  input  floo_rsp_t  [NumExtPorts-1:0]        floo_rsp_1_i,
  output floo_req_t  [NumExtPorts-1:0]        floo_req_1_o,
  output floo_rsp_t  [NumExtPorts-1:0]        floo_rsp_1_o,
  input  floo_wide_t [NumExtPorts-1:0]        floo_wide_1_i,
  output floo_wide_t [NumExtPorts-1:0]        floo_wide_1_o,
  // Accelerator interfaces
  input  endpoint_axi_pkg::narrow_out_req_t   axi_narrow_in_1_req_i,
  output endpoint_axi_pkg::narrow_out_resp_t  axi_narrow_in_1_rsp_o,
  output endpoint_axi_pkg::narrow_in_req_t    axi_narrow_out_1_req_o,
  input  endpoint_axi_pkg::narrow_in_resp_t   axi_narrow_out_1_rsp_i,
  input  endpoint_axi_pkg::wide_out_req_t     axi_wide_in_1_req_i,
  output endpoint_axi_pkg::wide_out_resp_t    axi_wide_in_1_rsp_o,
  output endpoint_axi_pkg::wide_in_req_t      axi_wide_out_1_req_o,
  input  endpoint_axi_pkg::wide_in_resp_t     axi_wide_out_1_rsp_i
);

  //////////////////////
  // Inter-tile links //
  //////////////////////

  // Tile 0 NoC links.
  floo_req_t  [West:North] t0_req_out,  t0_req_in;
  floo_rsp_t  [West:North] t0_rsp_out,  t0_rsp_in;
  floo_wide_t [West:North] t0_wide_out, t0_wide_in;

  // Tile 1 NoC links.
  floo_req_t  [West:North] t1_req_out,  t1_req_in;
  floo_rsp_t  [West:North] t1_rsp_out,  t1_rsp_in;
  floo_wide_t [West:North] t1_wide_out, t1_wide_in;

  // Inter-tile links.
  assign t0_req_in[East]  = t1_req_out[West];
  assign t1_req_in[West]  = t0_req_out[East];
  assign t0_rsp_in[East]  = t1_rsp_out[West];
  assign t1_rsp_in[West]  = t0_rsp_out[East];
  assign t0_wide_in[East] = t1_wide_out[West];
  assign t1_wide_in[West] = t0_wide_out[East];

  ////////////////////////
  // External NoC links //
  ////////////////////////

  // External-link index maps. It returns -1 for the internal and inter-tile links.
  function automatic int t0_ext_idx(route_direction_e dir);
    case (dir)
      North:   return 0;
      South:   return 1;
      West:    return 2;
      default: return -1;
    endcase
  endfunction

  function automatic int t1_ext_idx(route_direction_e dir);
    case (dir)
      North:   return 0;
      East:    return 1;
      South:   return 2;
      default: return -1; // West is the inter-tile link
    endcase
  endfunction

  // Tile 0 external cardinal links (skip East)
  for (genvar d = North; d <= West; d++) begin : gen_t0_ext
    if (d != East) begin : gen_conn
      assign floo_req_0_o[t0_ext_idx(route_direction_e'(d))]  = t0_req_out[d];
      assign floo_rsp_0_o[t0_ext_idx(route_direction_e'(d))]  = t0_rsp_out[d];
      assign floo_wide_0_o[t0_ext_idx(route_direction_e'(d))] = t0_wide_out[d];
      assign t0_req_in[d]  = floo_req_0_i[t0_ext_idx(route_direction_e'(d))];
      assign t0_rsp_in[d]  = floo_rsp_0_i[t0_ext_idx(route_direction_e'(d))];
      assign t0_wide_in[d] = floo_wide_0_i[t0_ext_idx(route_direction_e'(d))];
    end
  end

  // Tile 1 external cardinal links (skip West)
  for (genvar d = North; d <= West; d++) begin : gen_t1_ext
    if (d != West) begin : gen_conn
      assign floo_req_1_o[t1_ext_idx(route_direction_e'(d))]  = t1_req_out[d];
      assign floo_rsp_1_o[t1_ext_idx(route_direction_e'(d))]  = t1_rsp_out[d];
      assign floo_wide_1_o[t1_ext_idx(route_direction_e'(d))] = t1_wide_out[d];
      assign t1_req_in[d]  = floo_req_1_i[t1_ext_idx(route_direction_e'(d))];
      assign t1_rsp_in[d]  = floo_rsp_1_i[t1_ext_idx(route_direction_e'(d))];
      assign t1_wide_in[d] = floo_wide_1_i[t1_ext_idx(route_direction_e'(d))];
    end
  end

  ////////////
  // Tile 0 //
  ////////////

  floo_synth_nw_realm_tile #(
    .CollectCfgIdx ( CollectCfgIdx )
  ) i_realm_tile_0 (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .id_i                  ( id_0_i                 ),
    .route_table_i         ( route_table_0_i        ),
    .floo_req_o            ( t0_req_out             ),
    .floo_rsp_i            ( t0_rsp_in              ),
    .floo_wide_o           ( t0_wide_out            ),
    .floo_req_i            ( t0_req_in              ),
    .floo_rsp_o            ( t0_rsp_out             ),
    .floo_wide_i           ( t0_wide_in             ),
    .axi_narrow_in_req_i   ( axi_narrow_in_0_req_i  ),
    .axi_narrow_in_rsp_o   ( axi_narrow_in_0_rsp_o  ),
    .axi_narrow_out_req_o  ( axi_narrow_out_0_req_o ),
    .axi_narrow_out_rsp_i  ( axi_narrow_out_0_rsp_i ),
    .axi_wide_in_req_i     ( axi_wide_in_0_req_i    ),
    .axi_wide_in_rsp_o     ( axi_wide_in_0_rsp_o    ),
    .axi_wide_out_req_o    ( axi_wide_out_0_req_o   ),
    .axi_wide_out_rsp_i    ( axi_wide_out_0_rsp_i   )
  );

  ////////////
  // Tile 1 //
  ////////////

  floo_synth_nw_realm_tile #(
    .CollectCfgIdx ( CollectCfgIdx )
  ) i_realm_tile_1 (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .id_i                  ( id_1_i                 ),
    .route_table_i         ( route_table_1_i        ),
    .floo_req_o            ( t1_req_out             ),
    .floo_rsp_i            ( t1_rsp_in              ),
    .floo_wide_o           ( t1_wide_out            ),
    .floo_req_i            ( t1_req_in              ),
    .floo_rsp_o            ( t1_rsp_out             ),
    .floo_wide_i           ( t1_wide_in             ),
    .axi_narrow_in_req_i   ( axi_narrow_in_1_req_i  ),
    .axi_narrow_in_rsp_o   ( axi_narrow_in_1_rsp_o  ),
    .axi_narrow_out_req_o  ( axi_narrow_out_1_req_o ),
    .axi_narrow_out_rsp_i  ( axi_narrow_out_1_rsp_i ),
    .axi_wide_in_req_i     ( axi_wide_in_1_req_i    ),
    .axi_wide_in_rsp_o     ( axi_wide_in_1_rsp_o    ),
    .axi_wide_out_req_o    ( axi_wide_out_1_req_o   ),
    .axi_wide_out_rsp_i    ( axi_wide_out_1_rsp_i   )
  );

endmodule
