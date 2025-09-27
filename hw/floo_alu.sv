// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This 32 bit alu is designed to be used as an easy offload unit for the offload reduction.
// It should resemble the FPU from openhw group and could potentially be extended.

`include "common_cells/assertions.svh"

package alu_pkg;
  // STRONGLY Inspired by the fpnew from openhw group!

  // ---------
  // INT TYPES
  // ---------
  // | Enumerator | Width  |
  // |:----------:|-------:|
  // | INT8       |  8 bit |
  // | UINT8      |  8 bit |
  // | INT16      | 16 bit |
  // | UINT16     | 16 bit |
  // | INT32      | 32 bit |
  // | UINT32     | 32 bit |
  // | INT64      | 64 bit |
  // | UINT64     | 64 bit |
  // *NOTE:* Add new formats only at the end of the enumeration for backwards compatibilty!
  localparam int unsigned NUM_INT_FORMATS = 8;
  localparam int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Int formats (Uint required for differentation between signed / unsigned min max)
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,
    UINT8,
    INT16,
    UINT16,
    INT32,
    UINT32,
    INT64,
    UINT64
    // add new formats here
  } alu_int_format_e;

    // Returns the width of an INT format by index
  function automatic int unsigned int_width(alu_int_format_e ifmt);
    unique case (ifmt)
      INT8:  return 8;
      UINT8:  return 8;
      INT16: return 16;
      UINT16: return 16;
      INT32: return 32;
      UINT32: return 32;
      INT64: return 64;
      UINT64: return 64;
      default: begin
        // pragma translate_off
        $fatal(1, "Invalid INT format supplied");
        // pragma translate_on
        // just return any integer to avoid any latches
        // hopefully this error is caught by simulation
        return INT8;
      end
    endcase
  endfunction

  // --------------
  // ALU OPERATIONS
  // --------------
  localparam int unsigned NUM_INT_OPERATION = 4;
  localparam int unsigned INT_OPERATION_BITS = $clog2(NUM_INT_OPERATION);

  // Int Operation
  typedef enum logic [INT_OPERATION_BITS-1:0] {
    ADD,
    MUL,
    MIN,
    MAX
  } alu_operation_e;

  // --------------
  // STATUS
  // --------------
  typedef struct packed {
    logic is_zero;
  } alu_status_t;

endpackage

// Wrapper incl. decoder for the ALU
module floo_reduction_alu import floo_pkg::*; #() (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic              flush_i,
  /// IF towards external FPU
  input  logic[63:0]        alu_req_op1_i,
  input  logic[63:0]        alu_req_op2_i,
  input  collect_op_e       alu_req_type_i,
  input  logic              alu_req_valid_i,
  output logic              alu_req_ready_o,
  /// IF from external ALU
  output logic[63:0]        alu_resp_data_o,
  output logic              alu_resp_valid_o,
  input  logic              alu_resp_ready_i
);

  /* All local parameter */

  /* All Typedef Vars */

  // Typedef for the input of the ALU
  typedef struct packed {
    logic [1:0][63:0]         operands;
    alu_pkg::alu_operation_e  op;
    alu_pkg::alu_int_format_e fmt;
    logic                     vectorial_op;
  } alu_in_t;

  // Typedef for the output of the ALU
  typedef struct packed {
    logic [63:0] result;
  } alu_out_t;

  /* Variable declaration */
  alu_in_t alu_in;
  alu_out_t alu_out;

  /* Module Declaration */

  // Parse the ALU request
  always_comb begin
    // Init default values
    alu_in = '0;

    // Set default Values
    alu_in.vectorial_op = 1'b0;
    alu_in.operands[0] = alu_req_op1_i;
    alu_in.operands[1] = alu_req_op2_i;

    // Define the operation we want to execute on the FPU
    unique casez (alu_req_type_i)
      (floo_pkg::A_Add) : begin
        alu_in.op = alu_pkg::ADD;
        alu_in.fmt = alu_pkg::INT32;
      end
      (floo_pkg::A_Mul) : begin
        alu_in.op = alu_pkg::MUL;
        alu_in.fmt = alu_pkg::INT32;
      end
      (floo_pkg::A_Min_S) : begin
        alu_in.op = alu_pkg::MIN;
        alu_in.fmt = alu_pkg::INT32;
      end
      (floo_pkg::A_Min_U) : begin
        alu_in.op = alu_pkg::MIN;
        alu_in.fmt = alu_pkg::UINT32;
      end
      (floo_pkg::A_Max_S) : begin
        alu_in.op = alu_pkg::MAX;
        alu_in.fmt = alu_pkg::INT32;
      end
      (floo_pkg::A_Max_U) : begin
        alu_in.op = alu_pkg::MAX;
        alu_in.fmt = alu_pkg::UINT32;
      end
      default : begin
        alu_in.op = alu_pkg::ADD;
        alu_in.fmt = alu_pkg::INT32;
      end
    endcase
  end

  // Instanciate the ALU
  floo_alu_top #(
    .tag_t                (logic),
    .CutOutput            (1'b1),
    .CutInput             (1'b0)
  ) i_alu (
    .clk_i                (clk_i),
    .rst_ni               (rst_ni),
    .flush_i              (flush_i),
    .operands_i           (alu_in.operands),
    .op_i                 (alu_in.op),
    .fmt_i                (alu_in.fmt),
    .vector_mode_i        (alu_in.vectorial_op),
    .tag_i                (1'b0),
    .in_valid_i           (alu_req_valid_i),
    .in_ready_o           (alu_req_ready_o),
    .result_o             (alu_out.result),
    .status_o             (),
    .tag_o                (),
    .out_valid_o          (alu_resp_valid_o),
    .out_ready_i          (alu_resp_ready_i)
  );

  // Assign the output signal of the ALU
  assign alu_resp_data_o = alu_out.result;

endmodule

// ALU Module which should similar to the fpnew module from the openhw group
module floo_alu_top #(
  parameter type          tag_t = logic,
  parameter bit           CutOutput = 1'b1,
  parameter bit           CutInput = 1'b1,
  // Do not change
  localparam int unsigned WIDTH = 64,
  localparam int unsigned NUM_OPERANDS = 2
) (
  input logic                                 clk_i,
  input logic                                 rst_ni,
  input logic                                 flush_i,
  /// Input Signal
  input logic [NUM_OPERANDS-1:0][WIDTH-1:0]   operands_i,
  input alu_pkg::alu_operation_e              op_i,
  input alu_pkg::alu_int_format_e             fmt_i,
  input logic                                 vector_mode_i,
  input tag_t                                 tag_i,
  input logic                                 in_valid_i,
  output logic                                in_ready_o,
  /// Output Signal
  output logic [WIDTH-1:0]                    result_o,
  output alu_pkg::alu_status_t                status_o,
  output tag_t                                tag_o,
  output logic                                out_valid_o,
  input  logic                                out_ready_i
);

/* All local parameter */

/* All Typedef Vars */

// Typedefs for the cut to avoid a cut for everything
typedef struct packed {
  logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands;
  alu_pkg::alu_operation_e op;
  alu_pkg::alu_int_format_e fmt;
  logic vector_mode;
  tag_t tag;
} cut_input_t;

typedef struct packed {
  logic [WIDTH-1:0] result;
  alu_pkg::alu_status_t status;
  tag_t tag;
} cut_output_t;

/* Variable declaration */

// Vars after the input cut
logic [NUM_OPERANDS-1:0][WIDTH-1:0]   operands_q;
alu_pkg::alu_operation_e op_q;
alu_pkg::alu_int_format_e fmt_q;
logic vector_mode_q;
tag_t tag_q;
logic in_valid_q;
logic in_ready_q;

// Vars with the result infront of the output cut
logic [WIDTH-1:0] result_d;
alu_pkg::alu_status_t status_d;
tag_t tag_d;
logic out_valid_d;
logic out_ready_d;

// trunc'ed signal to support only 32 Bit signal
logic [NUM_OPERANDS-1:0][31:0]        operands_32;
logic [31:0] res_32;
logic [31:0] adder_res_32;
logic [31:0] mul_res_32;
logic [31:0] min_res_32;
logic [31:0] max_res_32;

/* Module Declaration */

// Input Cut to split the ALU from the rest of the system
if (CutInput == 1'b1) begin
  spill_register_flushable #(
    .T                  (cut_input_t),
    .Bypass             (1'b0)
  ) i_output_cut (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .valid_i            (in_valid_i),
    .flush_i            (flush_i),
    .ready_o            (in_ready_o),
    .data_i             ({operands_i, op_i, fmt_i, vector_mode_i, tag_i}),
    .valid_o            (in_valid_q),
    .ready_i            (in_ready_q),
    .data_o             ({operands_q, op_q, fmt_q, vector_mode_q, tag_q})
  );
end else begin
  assign operands_q = operands_i;
  assign op_q = op_i;
  assign fmt_q = fmt_i;
  assign vector_mode_q = vector_mode_i;
  assign tag_q = tag_i;
  assign in_valid_q = in_valid_i;
  assign in_ready_o = in_ready_q;
end

// Implement ALU here
// Parse both operands to 32 Bit
for (genvar i = 0; i < NUM_OPERANDS;i++) begin
  assign operands_32[i] = operands_q[i][31:0];
end

// Adder Path
assign adder_res_32 = operands_32[1] + operands_32[0];

// Multiplier Path
always_comb begin
  mul_res_32 = '0;
  for (int i = 0; i < 32; i++) begin
    mul_res_32 = (|((operands_32[0] >> i) & 1)) ? mul_res_32 + (operands_32[1] << i) : mul_res_32;
  end
end

// Min / Max Path
always_comb begin : gen_minmax
  logic sign;

  max_res_32 = '0;
  min_res_32 = '0;
  sign = 1'b0;

  // Determint if we require sign > When we extend the signal by 1 bit then we can use the signed hw
  // for both the signed and unsigned case.
  if(fmt_q == alu_pkg::INT32) begin
    sign = 1'b1;
  end

  // Calc the min / max signal in the same case
  if($signed({sign & operands_32[0][31], operands_32[0]}) > $signed({sign & operands_32[1][31], operands_32[1]})) begin
    max_res_32 = operands_32[0];
    min_res_32 = operands_32[1];
  end else begin
    max_res_32 = operands_32[1];
    min_res_32 = operands_32[0];
  end
end

// Mux the result together
always_comb begin : result_mux
  res_32 = '0;
  unique case (op_i)
    alu_pkg::ADD:   res_32 = adder_res_32;
    alu_pkg::MUL:   res_32 = mul_res_32;
    alu_pkg::MIN:   res_32 = min_res_32;
    alu_pkg::MAX:   res_32 = max_res_32;
    default:        res_32 = '0;
  endcase
end

// Sign extend the 32 Bit result
assign result_d = {{32{res_32[31]}},res_32};

// Bypass tag & handshake
assign tag_d = tag_q;
assign out_valid_d = in_valid_q;
assign in_ready_q = out_ready_d;
assign status_d.is_zero = ~ (|res_32); // Or Connect all signal and invert to determin if we have a 0 signal

// introduce cut at output of ALU
if (CutOutput == 1'b1) begin
  spill_register_flushable #(
    .T                  (cut_output_t),
    .Bypass             (1'b0)
  ) i_output_cut (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .valid_i            (out_valid_d),
    .flush_i            (flush_i),
    .ready_o            (out_ready_d),
    .data_i             ({result_d, status_d, tag_d}),
    .valid_o            (out_valid_o),
    .ready_i            (out_ready_i),
    .data_o             ({result_o, status_o, tag_o})
  );
end else begin
  assign result_o = result_d;
  assign status_o = status_d;
  assign tag_o = tag_d;
  assign out_valid_o = out_valid_d;
  assign out_ready_d = out_ready_i;
end

/* Assertions for the module */

// Currently we only support 32Bit operations! Could be extended in the future
`ASSERT(Invalid_Input, !((fmt_i != alu_pkg::INT32) && (fmt_i != alu_pkg::UINT32)))
`ASSERT(Invalid_Vector_Ops, !(vector_mode_i != 1'b0))

endmodule
