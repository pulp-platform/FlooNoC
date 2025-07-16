// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>
//
// This module is used to handle arithmetic reduction streams that need to be offloaded
// to a functional unit. It selects the first two valid inputs and issues them to the FU.
// It then takes care of forwarding the incoming result back to the correct output.
//
// Limitations:
// This module is not AXI agnostic, it works only with AXI compliant data streams.
// The protocol information is necessary to extract the data bits from the payload.

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"
`include "floo_noc/typedef.svh"
`include "axi/typedef.svh"


module floo_reduction_unit
  import floo_pkg::*;
  #(
    parameter int unsigned NumInputs  = 0,
    parameter int unsigned NumOutputs = 0,
    parameter type flit_t             = logic,
    parameter type hdr_t              = logic,
    parameter type id_t               = logic,
    parameter type reduction_data_t   = logic,
    /// Parameters for the reduction configuration
    parameter reduction_cfg_t RedCfg               = '0,
    /// Axi Configuration
    parameter floo_pkg::axi_cfg_t AxiCfg            = '0
  )(
    input   logic                                     clk_i,
    input   logic                                     rst_ni,
    input   id_t                                      xy_id_i,
    input   logic   [NumInputs-1:0]                   valid_i,
    output  logic   [NumInputs-1:0]                   ready_o,
    input   flit_t  [NumInputs-1:0]                   data_i,
    output  logic   [NumOutputs-1:0]                  valid_o,
    input   logic   [NumOutputs-1:0]                  ready_i,
    output  flit_t  [NumOutputs-1:0]                  data_o,
    /// One-hot mask to route result to the output
    input   logic   [NumInputs-1:0][NumOutputs-1:0]   routed_out_mask_i,
    /// One-hot mask to indicate expected inputs
    input   logic   [NumInputs-1:0][NumInputs-1:0]    in_mask_i,
    output  logic                                     operands_valid_o,
    input   logic                                     operands_ready_i,
    output  reduction_data_t                          operand1_o,
    output  reduction_data_t                          operand2_o,
    output  collect_op_e                              operation_o,
    input   logic                                     result_valid_i,
    output  logic                                     result_ready_o,
    input   reduction_data_t                          result_i
  );

  `FLOO_TYPEDEF_AXI_FROM_CFG(axi, AxiCfg)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, AxiCfg, hdr_t)

  typedef logic [cf_math_pkg::idx_width(NumInputs)-1:0] input_sel_t;
  typedef logic [cf_math_pkg::idx_width(NumOutputs)-1:0] out_select_t;

  typedef struct packed {
    collect_op_e     op;
    reduction_data_t operand1;
    reduction_data_t operand2;
  } red_intsr_t;

  // Select signals for the input data
  input_sel_t operand1_sel;
  input_sel_t operand2_sel;
  collect_op_e incoming_op;

  logic [NumInputs-1:0] mask_operand1;
  logic [NumInputs-1:0] mask_operand2;

  // Selected flit. Still generic floo flit type
  flit_t operand1_flit, operand2_flit;

  // Signals towards multiple functional units
  logic       operands_valid_out;
  logic       operands_ready_in;

  // Signals towards the offload interface
  logic       offload_operands_valid_out;
  logic       offload_operands_ready_in;
  red_intsr_t       instr_out, instr_out_cut;
  floo_axi_w_flit_t w_flit_operand1, w_flit_operand2;
  floo_axi_w_flit_t w_flit_result;

  // Signals towards selectAW unit
  logic       aw_valid_out;
  logic       aw_ready_in;
  flit_t      aw_out;

  // Signals from the response offload interface
  reduction_data_t      result_data_in;
  logic                 result_valid_in;
  logic                 result_ready_out;
  flit_t                result_flit_in;

  // Output flit after the mux
  flit_t                result_flit_out;
  logic                 result_flit_valid_out;
  logic                 result_flit_ready_in;
  logic                 result_mux_sel;

  // Metadata for latency tolerant controller
  flit_t                  metadata_flit_out;
  logic [NumOutputs-1:0]  metadata_route_out_dir;
  out_select_t            out_select;

  ///------------------------///
  /// Outgoing operands flow ///
  ///------------------------///

  // Leading zero counter to chose the first valid operand
  lzc #(
    .WIDTH(NumInputs)
  ) i_lzc_opn1 (
    .in_i     ( valid_i       ),
    .cnt_o    ( operand1_sel  ),
    .empty_o  (               )
  );

  floo_reduction_sync #(
    .NumRoutes          ( NumInputs ),
    .RdSupportLoopback  ( RedCfg.RdSupportLoopback ),
    .arb_idx_t          ( input_sel_t ),
    .flit_t             ( flit_t    ),
    .id_t               ( id_t      )
  ) i_reduction_sync (
    .sel_i            ( operand1_sel            ),
    .data_i           ( data_i                  ),
    .valid_i          ( valid_i                 ),
    .ready_o          ( ready_o                 ),
    .xy_id_i          ( xy_id_i                 ),
    .in_route_mask_i  ( in_mask_i[operand1_sel] ),
    .valid_o          ( operands_valid_out      ),
    .ready_i          ( operands_ready_in       )
  );

  // The first operand is always the one selected from the lzc module
  assign operand1_flit = data_i[operand1_sel];
  assign incoming_op = data_i[operand1_sel].hdr.collective_op;


  assign mask_operand1 = {NumInputs'(1)} << operand1_sel;
  assign mask_operand2 = in_mask_i[operand1_sel] & ~mask_operand1;
  // This zero counter is used to select the second operand looking at the input mask
  lzc #(
    .WIDTH(NumInputs)
  ) i_lzc_opn2 (
    .in_i     ( mask_operand2 ),
    .cnt_o    ( operand2_sel  ),
    .empty_o  (               )
  );

  assign operand2_flit = data_i[operand2_sel];

  // Stream demux to arbitrate between different functional units:
  // - Output 1: Offload unit
  // - Output 2: SelectAW unit
  stream_demux #(
    .N_OUP ( 2 )
  ) i_operands_demux (
    .inp_valid_i   ( operands_valid_out     ),
    .inp_ready_o   ( operands_ready_in      ),
    .oup_sel_i     ( incoming_op == SeqAW   ),
    .oup_valid_o   ( {aw_valid_out, offload_operands_valid_out} ),
    .oup_ready_i   ( {aw_ready_in, offload_operands_ready_in}   )
  );


  assign w_flit_operand1 = floo_axi_w_flit_t'(operand1_flit);
  assign w_flit_operand2 = floo_axi_w_flit_t'(operand2_flit);

  assign instr_out.operand1 = w_flit_operand1.payload.data;
  assign instr_out.operand2 = w_flit_operand2.payload.data;
  assign instr_out.op = operand2_flit.hdr.collective_op;

  // For the select AW we don't need any operations except for assigning one of
  assign aw_out = operand1_flit;

  // Store incoming hdr + payload info for the response path
  // The data bits are useless since the result coming from the
  // functional unit will be the actual data. For this reason we hardcode the data to 0
  // at the fifo input to make sure that those FFs are then optimized away.

  // To avoid combinational loop, the push of the fifo must not depend on the ready
  // because the latter depends from the output of the fifo itself that is combinatorial
  // in case of FALL_THROUGH.

  logic already_pushed_q;
  logic valid_operand_handshake;

  assign valid_operand_handshake = operands_valid_out & operands_ready_in;

  `FFLARNC(already_pushed_q, 1'b1, operands_valid_out && (~already_pushed_q),
           valid_operand_handshake, 1'b0, clk_i, rst_ni)
  fifo_v3 #(
      .FALL_THROUGH     (1'b1),
      .dtype            (flit_t),
      .DEPTH            (RedCfg.RdPipelineDepth+2)
  ) i_fifo_flit (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .flush_i          (1'b0),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (),
      .usage_o          (),
      .data_i           (operand1_flit),                     // store the flit of the first operand
      .push_i           (operands_valid_out & (~already_pushed_q)),  // push when handshake on the input operands
      .data_o           (metadata_flit_out),
      .pop_i            (result_flit_valid_out & result_flit_ready_in) // pop mask when handshake on the result
  );
  // Fifo to store the output direction of the element during the FPU reduction
  fifo_v3 #(
      .FALL_THROUGH     (1'b1),
      .DATA_WIDTH       (NumInputs),
      .DEPTH            (RedCfg.RdPipelineDepth+2)
  ) i_fifo_route_dir (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .flush_i          (1'b0),
      .testmode_i       (1'b0),
      .full_o           (),
      .empty_o          (), // Not needed, this fifo is always sinc with the flit one
      .usage_o          (),
      .data_i           (routed_out_mask_i[operand1_sel]),         // store the route out of the first operand
      .push_i           (operands_valid_out & (~already_pushed_q)),  // push when handshake on the input operands
      .data_o           (metadata_route_out_dir),
      .pop_i            (result_flit_valid_out & result_flit_ready_in) // pop mask when handshake on the result
  );

  // TODO (lleone): Create a REQ/RSP struct for the following interface
  // and replace all the spill registers with just one for REQ and one for RSP
  spill_register #(
        .T (red_intsr_t),
        .Bypass (!RedCfg.CutOffloadIntf)
  ) i_offload_cut_req (
        .clk_i,
        .rst_ni,
        .data_i   (instr_out),
        .valid_i  (offload_operands_valid_out),
        .ready_o  (offload_operands_ready_in),
        .data_o   (instr_out_cut),
        .valid_o  (operands_valid_o),
        .ready_i  (operands_ready_i)
  );

  // TODO(lleone): When uniforming the offload interface, get rid of this part, isnce the cur will be of the type of the interface
  assign operation_o = instr_out_cut.op;
  assign operand1_o = instr_out_cut.operand1;
  assign operand2_o = instr_out_cut.operand2;


  ///-------------------------///
  /// Incoming responses flow ///
  ///-------------------------///

  spill_register #(
        .T (reduction_data_t),
        .Bypass (!RedCfg.CutOffloadIntf)
  ) i_offload_cut_rsp (
        .clk_i,
        .rst_ni,
        .data_i   (result_i),
        .valid_i  (result_valid_i),
        .ready_o  (result_ready_o),
        .data_o   (result_data_in),
        .valid_o  (result_valid_in),
        .ready_i  (result_ready_out)
  );

  // TODO(lleone): Make sure this logic is actually optimized away in PnR
  // Apply the result from the offload unit to the stored flit
  always_comb begin: gen_result_flit
    w_flit_result = floo_axi_w_flit_t'(metadata_flit_out);
    w_flit_result.payload.data = result_data_in;
  end

  assign result_flit_in = flit_t'(w_flit_result);


  ///-------------------------///
  ///  Output responses flow  ///
  ///-------------------------///

  assign result_mux_sel = metadata_flit_out.hdr.collective_op == SeqAW;
  stream_mux #(
    .DATA_T   ( flit_t ),
    .N_INP    ( 2 )
  ) i_result_mux (
    .inp_data_i   ( {aw_out, result_flit_in}        ),
    .inp_valid_i  ( {aw_valid_out, result_valid_in} ),
    .inp_ready_o  ( {aw_ready_in, result_ready_out} ),
    .inp_sel_i    ( result_mux_sel                  ),
    .oup_data_o   ( result_flit_out                 ),
    .oup_valid_o  ( result_flit_valid_out           ),
    .oup_ready_i  ( result_flit_ready_in            )
  );

  // Output destination lzc
  lzc #(
    .WIDTH(NumOutputs)
  ) i_lzc_result_out (
    .in_i     ( metadata_route_out_dir  ),
    .cnt_o    ( out_select       ),
    .empty_o  (                  )
  );

  stream_demux #(
    .N_OUP ( NumOutputs )
  ) i_result_demux (
    .inp_valid_i   ( result_flit_valid_out  ),
    .inp_ready_o   ( result_flit_ready_in   ),
    .oup_sel_i     ( out_select             ),
    .oup_valid_o   ( valid_o                ),
    .oup_ready_i   ( ready_i                )
  );
  assign data_o = {NumOutputs{result_flit_out}};

  `ASSERT(ReductionFrom2MoreInputs,
          !(|valid_i) || ($countones(in_mask_i[operand1_sel]) == 0) ||
          ($countones(in_mask_i[operand1_sel]) == 2),
         clk_i, !rst_ni,
         "Incoming sequential reduction from more than 2 inputs is not supported")
endmodule
