// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/assertions.svh"

module floo_input_port #(
  parameter type flit_t = logic,
  parameter type hdr_t  = logic,
  parameter int HdrLength = $bits(hdr_t),
  parameter int DataLength = $bits(flit_t) - HdrLength,
  parameter type flit_payload_t = logic[DataLength-1:0],
  parameter int NumVC = 4,
  parameter int NumVCWidth = 2,
  parameter int VCDepth  = 3
) (
  input  logic clk_i,
  input  logic rst_ni,
  // input from other router or local port
  output logic                          credit_v_o,
  output logic  [NumVCWidth-1:0]        credit_id_o,
  input  logic                          data_v_i,
  input  flit_t                         data_i,

  output logic  [NumVC-1:0]             vc_ctrl_head_v_o,
  output hdr_t  [NumVC-1:0]             vc_ctrl_head_o,
  output flit_payload_t [NumVC-1:0]     vc_data_head_o,

  // input pop flit ctrl fifo (comes from SA stage)
  input logic                           read_enable_sa_stage_i,
  input logic [NumVC-1:0]               read_vc_id_oh_sa_stage_i,

  // input pop flit ctrl fifo (comes from ST stage)
  input logic                           read_enable_st_stage_i,
  input logic [NumVC-1:0]               read_vc_id_oh_st_stage_i
);

logic [NumVC-1:0] data_v_i_oh;
logic [NumVC-1:0] remove_ctrl_head;
logic [NumVC-1:0] remove_data_head;

// where to add data
always_comb begin
  data_v_i_oh = '0;
  if(data_v_i) begin
    data_v_i_oh[data_i.hdr.vc_id[NumVCWidth-1:0]] = 1'b1;
  end
end

// when to remove from fifo
always_comb begin
  // remove ctrl at SA stage
  remove_ctrl_head = '0;
  if(read_enable_sa_stage_i)
    remove_ctrl_head = read_vc_id_oh_sa_stage_i;
  // remove data at ST stage
  remove_data_head = '0;
  if(read_enable_st_stage_i)
    remove_data_head = read_vc_id_oh_st_stage_i;
end

// data fifo -> hdr is always before payload in flits
for(genvar v_chan = 0; v_chan < NumVC; v_chan++) begin: gen_data_fifos
  floo_input_fifo #(
    .Depth  (VCDepth),
    .type_t (flit_payload_t)
  ) i_data_fifo (
    .clk_i,
    .rst_ni,
    .data_i     (data_i           [DataLength-1:0]),
    .valid_i    (data_v_i_oh      [v_chan]),
    .data_o     (vc_data_head_o   [v_chan]),
    .valid_o    (),
    .ready_i    (remove_data_head [v_chan])
  );
end

// ctrl fifo -> hdr is always before payload in flits
for(genvar v_chan = 0; v_chan < NumVC; v_chan++) begin: gen_ctrl_fifos
  floo_input_fifo #(
      .Depth  (VCDepth),
      .type_t (hdr_t)
    ) i_data_fifo (
      .clk_i,
      .rst_ni,
      .data_i     (data_i           [DataLength+HdrLength-1:DataLength]),
      .valid_i    (data_v_i_oh      [v_chan]),
      .data_o     (vc_ctrl_head_o   [v_chan]),
      .valid_o    (vc_ctrl_head_v_o [v_chan]),
      .ready_i    (remove_ctrl_head [v_chan])
    );
end

assign credit_v_o   = read_enable_st_stage_i; //could also be from sa stage
logic [NumVCWidth-1:0][NumVC-1:0] id_mask;

//extract credit_id from onehot: create id mask
for(genvar i = 0; i < NumVCWidth; i++) begin : gen_id_mask_NumVCWidth
  for(genvar j = 0; j < NumVC; j++) begin : gen_id_mask_NumVC
    assign id_mask[i][j] = (j/(2**i)) % 2;
  end
end
//mask looks like this: N_Input = 3: (0,0) is first bit
// 0 0 0  // 1 0 0  // 0 1 0  // 1 1 0  // 0 0 1  // 1 0 1  // 0 1 1  // 1 1 1
// use mask to get credit_id
for(genvar i = 0; i < NumVCWidth; i++) begin : gen_get_credit_id
  assign credit_id_o[i] = |(read_vc_id_oh_st_stage_i & id_mask[i]);
end


endmodule
