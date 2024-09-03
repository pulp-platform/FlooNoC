// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "floo_noc/typedef.svh"

/// A mesh topology with ruche channels and a configurable number of rows and columns
module floo_mesh_ruche
  import floo_pkg::*;
#(
  parameter int unsigned NumX             = 4,
  parameter int unsigned NumY             = 4,
  parameter int unsigned NumVirtChannels  = 1,
  parameter int unsigned NumPhysChannels  = 1,
  parameter int unsigned RucheFactor      = 2,
  parameter int unsigned NumRoutes        = 5,
  parameter route_algo_e RouteAlgo        = IdTable,
  parameter type flit_t                   = logic,
  parameter type xy_id_t                  = logic
) (
  input logic clk_i,
  input logic rst_ni,
  input  logic  [NumX-1:0][NumY-1:0][NumVirtChannels-1:0]  valid_i,
  output logic  [NumX-1:0][NumY-1:0][NumVirtChannels-1:0]  ready_o,
  input  flit_t [NumX-1:0][NumY-1:0][NumPhysChannels-1:0]  data_i,

  output logic  [NumX-1:0][NumY-1:0][NumVirtChannels-1:0] valid_o,
  input  logic  [NumX-1:0][NumY-1:0][NumVirtChannels-1:0] ready_i,
  output flit_t [NumX-1:0][NumY-1:0][NumPhysChannels-1:0] data_o
);

  flit_t  [NumX-2:0][NumY-1:0][NumPhysChannels-1:0] pos_x_flit;
  logic   [NumX-2:0][NumY-1:0][NumVirtChannels-1:0] pos_x_ready, pos_x_valid;
  flit_t  [NumX-2:0][NumY-1:0][NumPhysChannels-1:0] neg_x_flit;
  logic   [NumX-2:0][NumY-1:0][NumVirtChannels-1:0] neg_x_ready, neg_x_valid;
  flit_t  [NumX-1:0][NumY-2:0][NumPhysChannels-1:0] pos_y_flit;
  logic   [NumX-1:0][NumY-2:0][NumVirtChannels-1:0] pos_y_ready, pos_y_valid;
  flit_t  [NumX-1:0][NumY-2:0][NumPhysChannels-1:0] neg_y_flit;
  logic   [NumX-1:0][NumY-2:0][NumVirtChannels-1:0] neg_y_ready, neg_y_valid;

  flit_t  [NumX-2:0][NumY-1:0][NumPhysChannels-1:0] ruche_pos_x_flit;
  logic   [NumX-2:0][NumY-1:0][NumVirtChannels-1:0] ruche_pos_x_ready, ruche_pos_x_valid;
  flit_t  [NumX-2:0][NumY-1:0][NumPhysChannels-1:0] ruche_neg_x_flit;
  logic   [NumX-2:0][NumY-1:0][NumVirtChannels-1:0] ruche_neg_x_ready, ruche_neg_x_valid;
  flit_t  [NumX-1:0][NumY-2:0][NumPhysChannels-1:0] ruche_pos_y_flit;
  logic   [NumX-1:0][NumY-2:0][NumVirtChannels-1:0] ruche_pos_y_ready, ruche_pos_y_valid;
  flit_t  [NumX-1:0][NumY-2:0][NumPhysChannels-1:0] ruche_neg_y_flit;
  logic   [NumX-1:0][NumY-2:0][NumVirtChannels-1:0] ruche_neg_y_ready, ruche_neg_y_valid;

  for (genvar x = 0; x < NumX; x++) begin : gen_x
    for (genvar y = 0; y < NumY; y++) begin : gen_y
      xy_id_t current_id;
      assign current_id = '{x: x, y: y};

      flit_t  [4:0][NumPhysChannels-1:0] in_flit;
      logic   [4:0][NumVirtChannels-1:0] in_ready, in_valid;
      flit_t  [4:0][NumPhysChannels-1:0] out_flit;
      logic   [4:0][NumVirtChannels-1:0] out_ready, out_valid;

      flit_t  [RucheWest:RucheNorth][NumPhysChannels-1:0] ruche_in_flit;
      logic   [RucheWest:RucheNorth][NumVirtChannels-1:0] ruche_in_ready, ruche_in_valid;
      flit_t  [RucheWest:RucheNorth][NumPhysChannels-1:0] ruche_out_flit;
      logic   [RucheWest:RucheNorth][NumVirtChannels-1:0] ruche_out_ready, ruche_out_valid;

      always_comb begin
        in_flit[West:North]   = '0;
        in_valid[West:North]  = '0;
        out_ready[West:North] = '0;

        in_valid[Eject]       = valid_i[x][y];
        in_flit[Eject]        = data_i[x][y];
        ready_o[x][y]         = in_ready[Eject];
        valid_o[x][y]         = out_valid[Eject];
        data_o[x][y]          = out_flit[Eject];
        out_ready[Eject]      = ready_i[x][y];

        // Y
        if (y < NumY-1) begin
          in_flit[North]      = neg_y_flit[x][y];
          in_valid[North]     = neg_y_valid[x][y];
          neg_y_ready[x][y]   = in_ready[North];
          pos_y_flit[x][y]    = out_flit[North];
          pos_y_valid[x][y]   = out_valid[North];
          out_ready[North]    = pos_y_ready[x][y];
        end
        if (y > 0) begin
          in_flit[South]      = pos_y_flit[x][y-1];
          in_valid[South]     = pos_y_valid[x][y-1];
          pos_y_ready[x][y-1] = in_ready[South];
          neg_y_flit[x][y-1]  = out_flit[South];
          neg_y_valid[x][y-1] = out_valid[South];
          out_ready[South]    = neg_y_ready[x][y-1];
        end

        // Y Rouche
        if (y > RucheFactor) begin
          ruche_in_flit[RucheSouth] = ruche_pos_y_flit[x][y-RucheFactor];
          ruche_in_valid[RucheSouth] = ruche_pos_y_valid[x][y-RucheFactor];
          ruche_pos_y_ready[x][y-RucheFactor] = ruche_in_ready[RucheSouth];
          ruche_neg_y_flit[x][y-RucheFactor] = ruche_out_flit[RucheSouth];
          ruche_neg_y_valid[x][y-RucheFactor] = ruche_out_valid[RucheSouth];
          ruche_out_ready[RucheSouth] = ruche_neg_y_ready[x][y-RucheFactor];
        end
        if (y < NumY-RucheFactor) begin
          ruche_in_flit[RucheNorth] = ruche_neg_y_flit[x][y];
          ruche_in_valid[RucheNorth] = ruche_neg_y_valid[x][y];
          ruche_neg_y_ready[x][y] = ruche_in_ready[RucheNorth];
          ruche_pos_y_flit[x][y] = ruche_out_flit[RucheNorth];
          ruche_pos_y_valid[x][y] = ruche_out_valid[RucheNorth];
          ruche_out_ready[RucheNorth] = ruche_pos_y_ready[x][y];
        end

        // X
        if (x < NumX-1) begin
          in_flit[East]       = neg_x_flit[x][y];
          in_valid[East]      = neg_x_valid[x][y];
          neg_x_ready[x][y]   = in_ready[East];
          pos_x_flit[x][y]    = out_flit[East];
          pos_x_valid[x][y]   = out_valid[East];
          out_ready[East]     = pos_x_ready[x][y];
        end
        if (x > 0) begin
          in_flit[West]       = pos_x_flit[x-1][y];
          in_valid[West]      = pos_x_valid[x-1][y];
          pos_x_ready[x-1][y] = in_ready[West];
          neg_x_flit[x-1][y]  = out_flit[West];
          neg_x_valid[x-1][y] = out_valid[West];
          out_ready[West]     = neg_x_ready[x-1][y];
        end

        // X Rouche
        if (x > RucheFactor) begin
          ruche_in_flit[RucheWest] = ruche_pos_x_flit[x-RucheFactor][y];
          ruche_in_valid[RucheWest] = ruche_pos_x_valid[x-RucheFactor][y];
          ruche_pos_x_ready[x-RucheFactor][y] = ruche_in_ready[RucheWest];
          ruche_neg_x_flit[x-RucheFactor][y] = ruche_out_flit[RucheWest];
          ruche_neg_x_valid[x-RucheFactor][y] = ruche_out_valid[RucheWest];
          ruche_out_ready[RucheWest] = ruche_neg_x_ready[x-RucheFactor][y];
        end
        if (x < NumX-RucheFactor) begin
          ruche_in_flit[RucheEast] = ruche_neg_x_flit[x][y];
          ruche_in_valid[RucheEast] = ruche_neg_x_valid[x][y];
          ruche_neg_x_ready[x][y] = ruche_in_ready[RucheEast];
          ruche_pos_x_flit[x][y] = ruche_out_flit[RucheEast];
          ruche_pos_x_valid[x][y] = ruche_out_valid[RucheEast];
          ruche_out_ready[RucheEast] = ruche_pos_x_ready[x][y];
        end
      end

      floo_router #(
        .NumPhysChannels ( NumPhysChannels ),
        .NumVirtChannels ( NumVirtChannels ),
        .NumRoutes       ( NumRoutes       ),
        .flit_t          ( flit_t          ),
        .RouteAlgo       ( RouteAlgo       ),
        .InFifoDepth( 2               ),
        .IdWidth         ( $bits(xy_id_t)  ),
        .id_t            ( xy_id_t         ),
        .addr_rule_t     ( logic           ),
        .NumAddrRules    ( 1               )
      ) i_floo_router (
        .clk_i,
        .rst_ni,
        .test_enable_i  ( 1'b0       ),

        .xy_id_i        ( current_id ),
        .id_route_map_i ( '0         ),

        .valid_i        ( in_valid  ),
        .ready_o        ( in_ready  ),
        .data_i         ( in_flit   ),

        .valid_o        ( out_valid ),
        .ready_i        ( out_ready ),
        .data_o         ( out_flit  )
      );
    end
  end

endmodule
