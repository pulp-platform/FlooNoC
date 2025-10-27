// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>
//
// This module is used to handle arithmetic reduction streams that need to be offloaded
// to a functional unit. It selects the first two valid inputs and issues them to the FU.
// It then takes care of forwarding the incoming result back to the correct output.

`include "common_cells/assertions.svh"

module floo_reduction_unit
  import floo_pkg::*;
  #(
    parameter int unsigned NumInputs = 0,
    parameter int unsigned NumOutputs = 0,
    parameter type flit_t = logic,
    parameter type reduction_data_t = logic
  )(
    input   logic                                     clk_i,
    input   logic                                     rst_ni,
    input   logic   [NumInputs-1:0]                   valid_i,
    output  logic   [NumInputs-1:0]                   ready_o,
    input   flit_t  [NumInputs-1:0]                   data_i,
    /// One-hot mask to route result to the output
    input   logic   [NumInputs-1:0][NumOutputs-1:0]   routed_out_mask_i,
    /// One-hot mask to indicate expected inputs for reduction
    input   logic   [NumInputs-1:0]                   reduction_in_mask_i,
    output  logic                                     reduction_op_valid_o,
    input   logic                                     reduction_op_ready_i,
    output  reduction_data_t                          reduction_op1,
    output  reduction_data_t                          reduction_op2,
    input   logic                                     reduction_result_valid_i,
    output  logic                                     reduction_result_ready_o,
    input   reduction_data_t                          reduction_result_i
  );

  logic [cf_math_pkg::idx_width(NumInputs)-1:0] input_select;

  // Leading zero counter to chose the first valid input
  lzc #(
    .WIDTH(NumInputs),
    .MODE(1'b1)
  ) i_lzc (
    .in_i     ( valid_i       ),
    .cnt_o    ( input_select  ),
    .empty_o  (               )
  );


  // Synchronize

endmodule
