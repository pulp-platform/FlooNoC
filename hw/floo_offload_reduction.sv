// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This module describes the datapath of the offload reduction. The controller is part of the
// "floo_offload_reduction_buffer.sv" module and describes there.
// The selected operation we want to support for now are defined under floo_pkg::reduction_op_t!
//
// The main design goal was to allow a fully pipelined operation e.g. if out inputs provide each
// cycle a new elements to reduce then the underlying reduction utilization should be 100% during
// the reduction. However as this required more tracking effort we support other modes too.
// When we reduce elements from at tleast three different inputs we are required to have a
// partial result buffer for intermidiate results.
//
// Overall three modes are supported: Generic, Stalling, Simple, see the controller for more
// documentation.
//
// For the generic system we require a tag based system to allow tracking of each elements as we
// elementsfrom different reduction iteration in-fligth. All elements which hold the same tag
// need to be reduced together. This allows to separate the tag generation and the reduction logic.
//
// Additionally ever element gets an mask which indicates which elements are already reduced in
// the reduction_data as reduction with more than two inputs require two (or more) iterations.
// The mask allows for an easy comparison for the final result e.g. if it is equal to the input
// mask then all required inputs are reduced together.
//
// For the full documentation see the Masterthesis of Raphael Roth

// Restriction:
// - Currently we only support reduction of elements belonging to the same reduction stream.
//   In AXI term: different beats beloning to the same burst are okay but not two different
//   burts.
// - The max number of input is currently fixed to 6. This can be extended but th size of
//   the tag_t depends on it.
// - We only support symmetric configurations e.g. NumInput and NumOutput needs to be equal

// Open Points:
// - The status of the reduction logic (e.g. FPU) is currently not evaluated by the contoller!

`include "common_cells/assertions.svh"

module floo_offload_reduction import floo_pkg::*; #(
  /// Number of Routes (Currently support only symmetric configurations)
  parameter int unsigned NumRoutes              = 1,
  /// Various types used by floonoc / routing
  parameter type         flit_t                 = logic,
  parameter type         hdr_t                  = logic,
  parameter type         id_t                   = logic,
  /// Data payload size to extract from the floo flit
  parameter type         RdData_t               = logic,
  /// Possible reduction operation(s)
  parameter type         RdOperation_t          = logic,
  /// Parameter for the reduction configuration
  parameter reduction_cfg_t RdCfg               = '0,
  /// Axi Configuration
  parameter axi_cfg_t    AxiCfg                 = '0
) (
  /// Control Inputs
  input  logic                                  clk_i,
  input  logic                                  rst_ni,
  input  logic                                  flush_i,
  input  id_t                                   node_id_i,
  /// Ports towards the input routes
  input  logic  [NumRoutes-1:0]                 valid_i,
  output logic  [NumRoutes-1:0]                 ready_o,
  input  flit_t [NumRoutes-1:0]                 data_i,
  input  logic  [NumRoutes-1:0][NumRoutes-1:0]  output_route_i,
  input  logic  [NumRoutes-1:0][NumRoutes-1:0]  expected_input_i,
  /// Ports towards the output routes
  output logic  [NumRoutes-1:0]                 valid_o,
  input  logic  [NumRoutes-1:0]                 ready_i,
  output flit_t [NumRoutes-1:0]                 data_o,
  /// IF towards external reduction
  output RdOperation_t                          reduction_req_type_o,
  output RdData_t                               reduction_req_op1_o,
  output RdData_t                               reduction_req_op2_o,
  output logic                                  reduction_req_valid_o,
  input  logic                                  reduction_req_ready_i,
  /// IF from external reduction
  input  RdData_t                               reduction_resp_data_i,
  input  logic                                  reduction_resp_valid_i,
  output logic                                  reduction_resp_ready_o
);

/* All local parameter */

// Set the complexity of the Controller
localparam bit GENERIC  = (RdCfg.RdControllConf == ControllerGeneric) ? 1'b1 : 1'b0;
localparam bit SIMPLE   = (RdCfg.RdControllConf == ControllerSimple) ? 1'b1 : 1'b0;
localparam bit STALLING = (RdCfg.RdControllConf == ControllerStalling) ? 1'b1 : 1'b0;

/* All Typedef Vars */
// Index Variable to control the crossbar and the partial buffer
typedef logic [cf_math_pkg::idx_width(RdCfg.RdPartialBufferSize)-1:0] part_res_idx_t;

// Generate the types for the mask, the tag and the red_data
typedef logic [RdCfg.RdTagBits-1:0] tag_t;
typedef logic [NumRoutes-1:0] mask_t;

// dfferent combination between flit / data / tag / mask for the main data path
typedef struct packed {
  flit_t flit;
  mask_t input_exp;
  mask_t output_dir;
  tag_t tag;
} flit_in_out_dir_tag_t;

typedef struct packed {
  flit_t flit;
  mask_t mask;
  tag_t tag;
} flit_mask_tag_t;

typedef struct packed {
  RdData_t data;
  mask_t mask;
  tag_t tag;
} red_data_mask_tag_t;

typedef struct packed {
  RdData_t data;
  mask_t mask;
} red_data_mask_t;

typedef struct packed {
  RdData_t data;
  tag_t tag;
} red_data_tag_t;

/* Variable declaration */

// Variable for the tag generation
tag_t  [NumRoutes-1:0] fifo_tag;

// Output signals from the input FIFO's
flit_in_out_dir_tag_t [NumRoutes-1:0] fifo_out_data;
logic                 [NumRoutes-1:0] fifo_out_valid;
logic                 [NumRoutes-1:0] fifo_out_ready;

// Input signals which are already mapped to the corresponding operand
red_data_mask_tag_t [1:0] input_mapped_operands_data;
logic               [1:0] input_mapped_operands_valid;
logic               [1:0] input_mapped_operands_ready;

// Signal from the partial result buffer
red_data_mask_tag_t [1:0] partial_result_buffer_data;
logic               [1:0] partial_result_buffer_valid;
logic               [1:0] partial_result_buffer_ready;

// Signal after the merge between the partial result buffer and the inputs
red_data_mask_tag_t [1:0] merged_data;
logic               [1:0] merged_valid;
logic               [1:0] merged_ready;

// Signal after joining the handsake
logic join_operands_valid;
logic join_operands_ready;

// Var to determint the executed operation
RdOperation_t reduction_scheduled_operation;

// Signal for the FPU response
red_data_mask_tag_t reduction_resp_data;

// Singal to the partial result buffer
red_data_mask_tag_t input_partial_result_buf_data;
logic               input_partial_result_buf_valid;
logic               input_partial_result_buf_ready;

// Signal for the fully reduced result
red_data_tag_t  fully_reduced_data;
logic           fully_reduced_valid;
logic           fully_reduced_ready;

// Signal toward the output of the reduction logic
flit_mask_tag_t final_flit;
logic           final_valid;
logic           final_ready;

// Control Signal to either merge the partial buffer or the inputs
logic [1:0] ctrl_sel_part_res;

// Control Signal for the output demultiplexer
logic ctrl_demux;

// Selector for the partial result buffer
part_res_idx_t [1:0] ctrl_sel_buffer_idx;

// Spyglass signals from the partial result buffer
tag_t [RdCfg.RdPartialBufferSize-1:0] spyglass_tag;
logic [RdCfg.RdPartialBufferSize-1:0] spyglass_valid;

/* Module Declaration */

// The tag is only required for the Generic configuration
// For each incoming element generate the corresponding tag.
if(GENERIC == 1'b1) begin : gen_tag_generation
  floo_offload_reduction_taggen #(
      .NumRoutes        (NumRoutes),
      .TAG_T            (tag_t),
      .RdTagBits        (RdCfg.RdTagBits)
  ) i_gen_tag (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .flush_i          (flush_i),
      .mask_i           (expected_input_i),
      .valid_i          (valid_i),
      .ready_i          (ready_o),
      .tag_o            (fifo_tag)
  );
end else begin : gen_bypass_tag_generation
  assign fifo_tag = '0;
end

// Fifo's for all inputs to ack the incoming data
// and to reduce unnecessary backpressure into the system.
if(RdCfg.RdFifoDepth > 0) begin : gen_input_fifo
  for (genvar i = 0; i < NumRoutes; i++) begin : gen_routes
      stream_fifo #(
        .FALL_THROUGH           (RdCfg.RdFifoFallThrough),
        .DEPTH                  (RdCfg.RdFifoDepth),
        .T                      (flit_in_out_dir_tag_t)
      ) i_in_fifo_generic (
        .clk_i                  (clk_i),
        .rst_ni                 (rst_ni),
        .flush_i                (flush_i),
        .testmode_i             (1'b0),
        .usage_o                (),
        .data_i                 ({data_i[i], expected_input_i[i], output_route_i[i], fifo_tag[i]}),
        .valid_i                (valid_i[i]),
        .ready_o                (ready_o[i]),
        .data_o                 (fifo_out_data[i]),
        .valid_o                (fifo_out_valid[i]),
        .ready_i                (fifo_out_ready[i])
      );
  end
end else begin : gen_no_input_fifo
  for (genvar i = 0; i < NumRoutes; i++) begin : gen_routes
    assign fifo_out_data[i] = {data_i[i], expected_input_i[i], output_route_i[i], fifo_tag[i]};
    assign fifo_out_valid[i] = valid_i[i];
    assign ready_o[i] = fifo_out_ready[i];
  end
end

// Controller which runs the hole reduction
floo_offload_reduction_controller #(
  .NumRoutes                    (NumRoutes),
  .RdPartialBufferSize          (RdCfg.RdPartialBufferSize),
  .RdPipelineDepth              (RdCfg.RdPipelineDepth),
  .RdData_t                     (RdData_t),
  .RdOperation_t                (RdOperation_t),
  .tag_t                        (tag_t),
  .mask_t                       (mask_t),
  .flit_t                       (flit_t),
  .hdr_t                        (hdr_t),
  .data_tag_t                   (red_data_tag_t),
  .data_mask_tag_t              (red_data_mask_tag_t),
  .flit_mask_tag_t              (flit_mask_tag_t),
  .flit_in_out_dir_tag_t        (flit_in_out_dir_tag_t),
  .idx_part_res_t               (part_res_idx_t),
  .GENERIC                      (GENERIC),
  .SIMPLE                       (SIMPLE),
  .STALLING                     (STALLING),
  .RdSupportAxi                 (RdCfg.RdSupportAxi),
  .AxiCfg                       (AxiCfg),
  .RdEnableBypass               (RdCfg.RdEnableBypass)
) i_reduction_controller (
  .clk_i                        (clk_i),
  .rst_ni                       (rst_ni),
  .flush_i                      (flush_i),
  .head_fifo_flit_i             (fifo_out_data),
  .head_fifo_valid_i            (fifo_out_valid),
  .head_fifo_ready_o            (fifo_out_ready),
  .operand_data_o               (input_mapped_operands_data),
  .operand_valid_o              (input_mapped_operands_valid),
  .operand_ready_i              (input_mapped_operands_ready),
  .reduction_req_operation_o    (reduction_scheduled_operation),
  .reduction_req_mask_i         (merged_data[0].mask | merged_data[1].mask),
  .reduction_req_valid_i        (reduction_req_valid_o),
  .reduction_req_ready_i        (reduction_req_ready_i),
  .fully_red_data_i             (fully_reduced_data),
  .fully_red_valid_i            (fully_reduced_valid),
  .fully_red_ready_o            (fully_reduced_ready),
  .reduction_resp_mask_i        (reduction_resp_data.mask),
  .reduction_resp_tag_i         (reduction_resp_data.tag),
  .reduction_resp_valid_i       (reduction_resp_valid_i),
  .reduction_resp_ready_i       (reduction_resp_ready_o),
  .final_flit_o                 (final_flit),
  .final_valid_o                (final_valid),
  .final_ready_i                (final_ready),
  .buf_spyglass_tag_i           (spyglass_tag),
  .buf_spyglass_valid_i         (spyglass_valid),
  .select_partial_result_idx_o  (ctrl_sel_buffer_idx),
  .ctrl_part_res_mux_o          (ctrl_sel_part_res),
  .ctrl_output_demux_o          (ctrl_demux)
);

// Generate the MUX to include the partial buffer
if((GENERIC == 1'b1) || (STALLING == 1'b1)) begin : gen_mux_partial_result
  for (genvar i = 0; i < 2; i++) begin : gen_mux_partial_result_loop
      stream_mux #(
          .DATA_T             (red_data_mask_tag_t),
          .N_INP              (2)
      ) i_merge_part_res_and_input (
          .inp_data_i         ({partial_result_buffer_data[i], input_mapped_operands_data[i]}),
          .inp_valid_i        ({partial_result_buffer_valid[i], input_mapped_operands_valid[i]}),
          .inp_ready_o        ({partial_result_buffer_ready[i], input_mapped_operands_ready[i]}),
          .inp_sel_i          (ctrl_sel_part_res[i]),
          .oup_data_o         (merged_data[i]),
          .oup_valid_o        (merged_valid[i]),
          .oup_ready_i        (merged_ready[i])
      );
  end
end else begin : gen_bypass_mux_partial_result
  assign merged_data = input_mapped_operands_data;
  assign merged_valid = input_mapped_operands_valid;
  assign input_mapped_operands_ready = merged_ready;
  assign partial_result_buffer_ready = '0;
end

// Join the Handshake for the operands controll path's
stream_join #(
    .N_INP                  (2)
) i_join_controlpath_operands (
    .inp_valid_i            (merged_valid),
    .inp_ready_o            (merged_ready),
    .oup_valid_o            (join_operands_valid),
    .oup_ready_i            (join_operands_ready)
);

// Connect the HS for the output request to the FPU
assign reduction_req_valid_o = join_operands_valid;
assign join_operands_ready = reduction_req_ready_i;

// Output the operands here
// TODO(raroth): Introduce Cut here to allow cutting the Offload unit.
//       Extend the Configuration to allow fo this cut!
//       Cut the response from the offload unit too!
assign reduction_req_op1_o = merged_data[0].data;
assign reduction_req_op2_o = merged_data[1].data;
assign reduction_req_type_o = reduction_scheduled_operation;

// Note: At this position in the dataflow of this file lies the external reduction hardware
// After some (5) cycles the request turns comes back as response.
// The external Reduction requires at least 1 cycle to avoid hw-loops!

// We buffer the tag internally rather than pass it to the outside
// TODO: Add assertion that if "reduction_req_valid_o" is set that both tag are equal!
if(GENERIC == 1'b1) begin : gen_fifo_for_tag
  fifo_v3 #(
      .FALL_THROUGH     (1'b0),
      .dtype            (tag_t),
      .DEPTH            (RdCfg.RdPipelineDepth+2)
  ) i_fifo_mask_parallel_fpu (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .flush_i          (flush_i),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (),
      .usage_o          (),
      .data_i           (merged_data[0].tag),
      .push_i           (reduction_req_ready_i & reduction_req_valid_o),  // active fpu req hs
      .data_o           (reduction_resp_data.tag),
      .pop_i            (reduction_resp_valid_i & reduction_resp_ready_o) // active fpu resp hs
  );
end else begin
  assign reduction_resp_data.tag = '0;
end

// We buffer the mask internally rather than pass it to the outside
// The mask is or-connected because the results are "added"
// The mask field determins which input element is already
// reduced in the given element.
// from partial buffer: more than 1 bit set
// from input: only 1 bit set
// TODO: Add assertion that if "reduction_req_valid_o" is set that no bit position is set
//       in both mask as this would mean we have already added the element once!
if((GENERIC == 1'b1) || (STALLING == 1'b1)) begin : gen_fifo_for_mask
  fifo_v3 #(
      .FALL_THROUGH     (1'b0),
      .dtype            (mask_t),
      .DEPTH            (RdCfg.RdPipelineDepth+2)
  ) i_fifo_mask_parallel_fpu (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .flush_i          (flush_i),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (),
      .usage_o          (),
      .data_i           (merged_data[0].mask | merged_data[1].mask),
      .push_i           (reduction_req_ready_i & reduction_req_valid_o),  // active fpu req hs
      .data_o           (reduction_resp_data.mask),
      .pop_i            (reduction_resp_valid_i & reduction_resp_ready_o) // active fpu resp hs
  );
end else begin
  assign reduction_resp_data.mask = '0;
end

// Merge the response from the reduction with the interal tag / mask storage
assign reduction_resp_data.data = reduction_resp_data_i;

// Demux the output of the fpu
if((GENERIC == 1'b1) || (STALLING == 1'b1)) begin : gen_demux_partial_result
  stream_demux #(
    .N_OUP              (2)
  ) i_stream_demux_output_fpu (
    .inp_valid_i        (reduction_resp_valid_i),
    .inp_ready_o        (reduction_resp_ready_o),
    .oup_sel_i          (ctrl_demux),
    .oup_valid_o        ({fully_reduced_valid, input_partial_result_buf_valid}),
    .oup_ready_i        ({fully_reduced_ready, input_partial_result_buf_ready})
  );
end else begin
  assign fully_reduced_valid = reduction_resp_valid_i;
  assign reduction_resp_ready_o = fully_reduced_ready;
  assign input_partial_result_buf_valid = 1'b0;
end

// Assign the data beloning to the mux
assign input_partial_result_buf_data = reduction_resp_data;
assign fully_reduced_data.data = reduction_resp_data.data;
assign fully_reduced_data.tag = reduction_resp_data.tag;

// Dynammically fork the data into the correct output direction
// (Currently only 1 output direction is set by the dyn fork.
// Potentially we could support here a reduce and multicast operation
// if more than one output is set.

// TODO: By introducing a cut on these signal used by the multiplexer we could separate
//       the reduction logic from the rest of the router (timing wise at least).
//       Additionally the input fifo's would need to be configured as not fall through!
stream_fork_dynamic #(
  .N_OUP          (NumRoutes)
) i_dynamic_fork (
  .clk_i          (clk_i),
  .rst_ni         (rst_ni),
  .valid_i        (final_valid),
  .ready_o        (final_ready),
  .sel_i          (final_flit.mask),
  .sel_valid_i    (final_valid),
  .sel_ready_o    (),
  .valid_o        (valid_o),
  .ready_i        (ready_i)
);

// Dublicate the output data for all output IF
always_comb begin : gen_dublicate_output_data
  data_o = '0;
  for(int i = 0; i < NumRoutes;i++) begin
    data_o[i] = final_flit.flit;
  end
end

// Generate the partial result buffer only if we are in the GENERIC or the STALLING case
if((GENERIC == 1'b1) || (STALLING == 1'b1)) begin : gen_partial_result_buffer
  floo_offload_reduction_buffer #(
      .data_mask_tag_t    (red_data_mask_tag_t),
      .tag_t              (tag_t),
      .NElements          (RdCfg.RdPartialBufferSize),
      .NOutPorts          (2)
  ) i_buf_part_result (
      .clk_i              (clk_i),
      .rst_ni             (rst_ni),
      .flush_i            (flush_i),
      .inp_data_i         (input_partial_result_buf_data),
      .inp_valid_i        (input_partial_result_buf_valid),
      .inp_ready_o        (input_partial_result_buf_ready),
      .oup_data_o         (partial_result_buffer_data),
      .oup_valid_o        (partial_result_buffer_valid),
      .oup_ready_i        (partial_result_buffer_ready),
      .inp_sel_valid_i    (ctrl_sel_part_res),
      .inp_sel_i          (ctrl_sel_buffer_idx),
      .spyglass_valid_o   (spyglass_valid),
      .spyglass_tag_o     (spyglass_tag)
  );
end else begin
  assign input_partial_result_buf_ready = 1'b0;
  assign partial_result_buffer_data = '0;
  assign partial_result_buffer_valid = '0;
  assign spyglass_valid = '0;
  assign spyglass_tag = '0;
end

/* ASSERTION Checks */
// The fp reduction supports up to 6 operands
`ASSERT_INIT(Number_Input_Route_Invalid, !(NumRoutes > 6))
// Currently we only support reduction extension with an pipeline depth of at least 1 cycle as otherwise loops could be generated!
`ASSERT_INIT(ReductionPipelineDepth, !(RdCfg.RdPipelineDepth == 0))
// The size needs to be at least 2 for the partial buffer for the generic / stalling proceessor
`ASSERT_INIT(PartialBufferSize, !((GENERIC | STALLING) && (RdCfg.RdPartialBufferSize < 2)))
// We can only run GENERIC or SIMPLE or STALLING
`ASSERT_INIT(Invalid_Configuration_1, !(GENERIC & SIMPLE))
`ASSERT_INIT(Invalid_Configuration_2, !(STALLING & SIMPLE))
`ASSERT_INIT(Invalid_Configuration_3, !(GENERIC & STALLING))
`ASSERT_INIT(Invalid_Configuration_4, (GENERIC | STALLING | SIMPLE))

endmodule
