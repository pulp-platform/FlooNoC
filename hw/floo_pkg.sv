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
    North = 3'd0, // y increasing
    East  = 3'd1, // x increasing
    South = 3'd2, // y decreasing
    West  = 3'd3, // x decreasing
    Eject = 3'd4, // target/destination
    NumDirections
  } route_direction_e;

  // typedef enum logic[2:0] {
  //   N = 3'd0,
  //   E = 3'd1,
  //   S = 3'd2,
  //   W = 3'd3,
  //   L0 = 3'd4,
  //   L1 = 3'd5,
  //   L2 = 3'd6,
  //   L3 = 3'd7
  // } route_dir_e;  // this is nasty, but there might be more than one local port

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
