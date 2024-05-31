// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/// Accepts flits from the input port and stores them in a FIFO.
module floo_input_port #(
  /// Types of the flit, header and payload
  parameter type flit_t     = logic,
  parameter type hdr_t      = logic,
  parameter type payload_t  = logic,
  /// Number of virtual channels
  parameter int unsigned NumVC          = 32'd0,
  /// Width of the VC index
  parameter int unsigned VCIdxWidth     = 32'd0,
  /// Depth of the VC FIFOs
  parameter int unsigned VCDepth        = 32'd0,
  /// Deeper FIFO for a specific VC
  parameter int unsigned DeeperVCId     = 32'd0,
  /// Depth of the deeper FIFO
  parameter int unsigned DeeperVCDepth  = 32'd0
) (
  input  logic clk_i,
  input  logic rst_ni,
  /// input from other router or local port
  output logic                  credit_valid_o,
  output logic [VCIdxWidth-1:0] credit_id_o,
  input  logic                  data_valid_i,
  input  flit_t                 data_i,
  /// output to router
  output logic [NumVC-1:0]      vc_hdr_valid_o,
  output hdr_t [NumVC-1:0]      vc_hdr_o,
  output payload_t [NumVC-1:0]  vc_data_o,
  // input pop flit ctrl fifo (comes from SA stage)
  input  logic                  read_enable_sa_stage_i,
  input  logic [NumVC-1:0]      read_vc_id_oh_sa_stage_i,
  // input pop flit ctrl fifo (comes from ST stage)
  input  logic                  read_enable_st_stage_i,
  input  logic [NumVC-1:0]      read_vc_id_oh_st_stage_i
);

logic [NumVC-1:0] data_valid_i_oh;
logic [NumVC-1:0] remove_hdr;
logic [NumVC-1:0] remove_data;

// One-hot encoding of valid data
always_comb begin
  data_valid_i_oh = '0;
  if(data_valid_i) begin
    data_valid_i_oh[data_i.hdr.vc_id[VCIdxWidth-1:0]] = 1'b1;
  end
end

// When to remove from fifo
always_comb begin
  // Remove ctrl at SA stage
  remove_hdr = '0;
  if(read_enable_sa_stage_i) begin
    remove_hdr = read_vc_id_oh_sa_stage_i;
  end
  // Remove data at ST stage
  remove_data = '0;
  if(read_enable_st_stage_i) begin
    remove_data = read_vc_id_oh_st_stage_i;
  end
end

// Data Fifo
for(genvar vc = 0; vc < NumVC; vc++) begin: gen_data_fifos
  localparam int unsigned Depth = (vc == DeeperVCId) ? DeeperVCDepth : VCDepth;
  floo_input_fifo #(
    .Depth  ( Depth     ),
    .type_t ( payload_t )
  ) i_data_fifo (
    .clk_i,
    .rst_ni,
    .data_i   ( data_i.payload      ),
    .valid_i  ( data_valid_i_oh[vc] ),
    .data_o   ( vc_data_o [vc]      ),
    .valid_o  (                     ),
    .ready_i  ( remove_data[vc]     )
  );

  floo_input_fifo #(
    .Depth  ( Depth ),
    .type_t ( hdr_t )
  ) i_hdr_fifo (
    .clk_i,
    .rst_ni,
    .data_i   ( data_i.hdr          ),
    .valid_i  ( data_valid_i_oh[vc] ),
    .data_o   ( vc_hdr_o[vc]        ),
    .valid_o  ( vc_hdr_valid_o[vc]  ),
    .ready_i  ( remove_hdr [vc]     )
  );
end

logic [VCIdxWidth-1:0][NumVC-1:0] id_mask;

// Could also be from sa stage
assign credit_valid_o = read_enable_st_stage_i;

// Extract `credit_id` from onehot: create id mask
for(genvar i = 0; i < VCIdxWidth; i++) begin : gen_id_mask_NumVCWidth
  for(genvar j = 0; j < NumVC; j++) begin : gen_id_mask_NumVC
    assign id_mask[i][j] = (j/(2**i)) % 2;
  end
end

// Mask looks like this: N_Input = 3: (0,0) is first bit
// 0 0 0  // 1 0 0  // 0 1 0  // 1 1 0  // 0 0 1  // 1 0 1  // 0 1 1  // 1 1 1
// Use mask to get credit_id
for(genvar i = 0; i < VCIdxWidth; i++) begin : gen_get_credit_id
  assign credit_id_o[i] = |(read_vc_id_oh_st_stage_i & id_mask[i]);
end


endmodule
