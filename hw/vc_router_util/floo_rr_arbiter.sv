// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"

// one hot & id encoded round robin arbiter
module floo_rr_arbiter #(
  parameter   int NumInputs = 2,
  localparam  int NumInputsWidth = NumInputs > 1 ? $clog2(NumInputs) : 1
) (
  input   logic [NumInputs-1:0]       req_i,
  input   logic                       update_i, // only update arbiter when told to
  input   logic                       grant_i,  // output was actually selected
  output  logic [NumInputs-1:0]       grant_o,
  output  logic [NumInputsWidth-1:0]  grant_id_o,
  input   logic                       clk_i, rst_ni
);
  genvar i, j;
  if(NumInputs == 1) begin: gen_1_input
    assign grant_o     = req_i;
    assign grant_id_o = 0;
  end else begin: gen_gt1_inputs

    logic [NumInputs-1:0] reodered_req, reordered_selected_req;
    logic [NumInputs*2-1:0] left_rotate_helper, right_rotate_helper;
    logic [NumInputs-1:0] dereordered_selected_req;
    logic [NumInputsWidth-1:0] round_ptr_q, round_ptr_d;
    logic [NumInputsWidth-1:0] round_ptr_q_comp;
    logic [NumInputsWidth-1:0] selected_req_id;

    logic [NumInputsWidth-1:0][NumInputs-1:0] id_mask;

    // rotade left
    assign left_rotate_helper = {req_i, req_i} << round_ptr_q;
    assign reodered_req = left_rotate_helper[NumInputs*2-1-:NumInputs];

    //isolate rightmost 1 bit: reodered_req & (-reodered_req)
    assign reordered_selected_req = reodered_req & (~reodered_req + 1'b1);

    //rotate back: circular rotate by NumInputs - round_ptr_q
    assign round_ptr_q_comp = NumInputs - round_ptr_q;
    assign right_rotate_helper =
          {reordered_selected_req, reordered_selected_req} << round_ptr_q_comp;
    assign dereordered_selected_req = right_rotate_helper[NumInputs*2-1-:NumInputs];

    //extract id from onehot: create id mask
    for(i = 0; i < NumInputsWidth; i++) begin : gen_id_mask_NumInputsWidth
      for(j = 0; j < NumInputs; j++) begin : gen_id_mask_NumInputs
        assign id_mask[i][j] = (j/(2**i)) % 2;
      end
    end
    //mask looks like this: N_Input = 3: (0,0) is first bit
    // 0 0 0  // 1 0 0  // 0 1 0  // 1 1 0  // 0 0 1  // 1 0 1  // 0 1 1  // 1 1 1
    // use mask to get req_id
    for(i = 0; i < NumInputsWidth; i++) begin : gen_get_selected_req_id
      assign selected_req_id[i] = |(dereordered_selected_req & id_mask[i]);
    end

    // ff for round ptr.
    // logic: decrease rount_ptr if update_i, else set to selected_req_id
    always_comb begin
      round_ptr_d = round_ptr_q;
      if(grant_i) begin
        if (update_i)
          round_ptr_d = NumInputs - selected_req_id - 1;
        else
          round_ptr_d = NumInputs - selected_req_id;
      end
    end
    `FF(round_ptr_q, round_ptr_d, '0)

    assign grant_o     = dereordered_selected_req;
    assign grant_id_o  = selected_req_id;

  end
endmodule
