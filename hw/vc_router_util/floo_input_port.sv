// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>


module floo_input_port #(
  parameter type flit_t = logic,
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
  input logic [NumVCWidth-1:0]          read_vc_id_sa_stage_i,

  // input pop flit ctrl fifo (comes from ST stage)
  input logic                           read_enable_st_stage_i,
  input logic [NumVCWidth-1:0]          read_vc_id_st_stage_i
);

logic [NumVC-1:0] data_v_i_oh;

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
  remove_ctrl_head[inport_read_vc_id_sa_stage_i] = inport_read_enable_sa_stage_i;
end

// data fifo -> hdr is always before payload in flits
for(genvar v_chan = 0; v_chan < NumVC; v_chan++) begin: gen_data_fifos
  stream_fifo_optimal_wrap #(
    .Depth  (VCDepth),
    .type_t (flit_payload_t)
  ) i_data_fifo (
    .clk_i,
    .rst_ni,
    .testmode_i ('0),
    .flush_i    ('0),
    .usage_o    (),
    .data_i     (data_i           [DataLength-1:0]),
    .valid_i    (data_v_i_oh      [v_chan]),
    .ready_o    (),
    .data_o     (vc_data_head_o   [v_chan]),
    .valid_o    (),
    .ready_i    (remove_data_head [v_chan])
  );
end

// ctrl fifo -> hdr is always before payload in flits
for(genvar v_chan = 0; v_chan < NumVC; v_chan++) begin: gen_ctrl_fifos
  stream_fifo_optimal_wrap #(
      .Depth  (VCDepth),
      .type_t (hdr_t)
    ) i_data_fifo (
      .clk_i,
      .rst_ni,
      .testmode_i ('0),
      .flush_i    ('0),
      .usage_o    (),
      .data_i     (data_i           [DataLength+HdrLength-1:DataLength]),
      .valid_i    (data_v_i_oh      [v_chan]),
      .ready_o    (),
      .data_o     (vc_ctrl_head_o   [v_chan]),
      .valid_o    (vc_ctrl_head_v_o [v_chan]),
      .ready_i    (remove_ctrl_head [v_chan])
    );
end

assign credit_v_o   = read_enable_st_stage_i; //could also be from sa stage
assign credit_id_o  = read_vc_id_st_stage_i;


endmodule
