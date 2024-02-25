// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>
// - Michael Rogenmoser <michaero@iis.ee.ethz.ch>

/// Currently only contains useful functions and some constants and typedefs
package floo_pkg;

  typedef enum logic[1:0] {
    IdIsPort,
    IdTable,
    SourceRouting,
    XYRouting
  } route_algo_e;

  typedef enum logic[2:0] {
    Eject = 3'd0, // target/destination
    North = 3'd1, // y increasing
    East  = 3'd2, // x increasing
    South = 3'd3, // y decreasing
    West  = 3'd4, // x decreasing
    NumDirections
  } route_direction_e;

  typedef enum  {
    RucheNorth = 'd5,
    RucheEast  = 'd6,
    RucheSouth = 'd7,
    RucheWest  = 'd8
  } ruche_direction_e;

  typedef enum logic [1:0] {
    NormalRoB,
    SimpleRoB,
    NoRoB
  } rob_type_e;

endpackage
