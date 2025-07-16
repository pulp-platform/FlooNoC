// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This module allows to implement a reduction HW to simulate a reduction operation.
// Simple Testbench implementation!

// Open Points:

`include "common_cells/assertions.svh"

// This Wrapper allows to wrap 8x 64 Bit (512 Bits) in parallel
module floo_reduction_wrapper import floo_pkg::*; #(
  parameter type         RdData_t               = logic,
  parameter int unsigned RdElements             = 8,
  parameter bit          FPU_ACTIVE             = 1'b0,
  parameter bit          ALU_ACTIVE             = 1'b0,
  parameter bit          DEBUG_PRINT_TRACE      = 1'b0
) (
  input  logic                          clk_i,
  input  logic                          rst_ni,
  input  logic                          flush_i,
  /// IF towards external FPU
  input  RdData_t                       reduction_req_op1_i,
  input  RdData_t                       reduction_req_op2_i,
  input  collect_op_t                   reduction_req_type_i,
  input  logic                          reduction_req_valid_i,
  output logic                          reduction_req_ready_o,
  /// IF from external FPU
  output RdData_t                       reduction_resp_data_o,
  output logic                          reduction_resp_valid_o,
  input  logic                          reduction_resp_ready_i
);

  // Parameter
  localparam int unsigned FLEN = 64;

  // Variable
  logic [RdElements] comp_req_valid;
  logic [RdElements] comp_req_ready;
  logic [RdElements] comp_resp_valid;
  logic [RdElements] comp_resp_ready;

  // Fork the hadshaking
  stream_fork #(
    .N_OUP         (RdElements)
  ) i_dca_fork_fpu (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .valid_i       (reduction_req_valid_i),
    .ready_o       (reduction_req_ready_o),
    .valid_o       (comp_req_valid),
    .ready_i       (comp_req_ready)
  );

  // Implement FPU(s)
  for (genvar i = 0; i < RdElements; i++) begin : gen_fpu_metadata

    // Generate the FPU
    if(FPU_ACTIVE == 1'b1) begin
      floo_reduction_fpu #(
        .ID                   (i),
        .DEBUG_PRINT_TRACE    (DEBUG_PRINT_TRACE)
      ) i_fpu (
        .clk_i                (clk_i),
        .rst_ni               (rst_ni),
        .flush_i              (flush_i),
        .fpu_req_op1_i        (reduction_req_op1_i[(FLEN*(i+1))-1:FLEN*i]),
        .fpu_req_op2_i        (reduction_req_op2_i[(FLEN*(i+1))-1:FLEN*i]),
        .fpu_req_type_i       (reduction_req_type_i),
        .fpu_req_valid_i      (comp_req_valid[i]),
        .fpu_req_ready_o      (comp_req_ready[i]),
        .fpu_resp_data_o      (reduction_resp_data_o[(FLEN*(i+1)-1):FLEN*i]),
        .fpu_resp_valid_o     (comp_resp_valid[i]),
        .fpu_resp_ready_i     (comp_resp_ready[i])
      );
    end

    // Generate the ALU
    if(ALU_ACTIVE == 1'b1) begin
      floo_reduction_alu #(
        .ID                   (i),
        .DEBUG_PRINT_TRACE    (DEBUG_PRINT_TRACE)
      ) i_alu (
        .clk_i                (clk_i),
        .rst_ni               (rst_ni),
        .flush_i              (flush_i),
        .alu_req_op1_i        (reduction_req_op1_i[(FLEN*(i+1))-1:FLEN*i]),
        .alu_req_op2_i        (reduction_req_op2_i[(FLEN*(i+1))-1:FLEN*i]),
        .alu_req_type_i       (reduction_req_type_i),
        .alu_req_valid_i      (comp_req_valid[i]),
        .alu_req_ready_o      (comp_req_ready[i]),
        .alu_resp_data_o      (reduction_resp_data_o[(FLEN*(i+1)-1):FLEN*i]),
        .alu_resp_valid_o     (comp_resp_valid[i]),
        .alu_resp_ready_i     (comp_resp_ready[i])
      );
    end

  end

  // Join all the signal together
  stream_join #(
    .N_INP           (RdElements)
  ) i_dca_join_fpu (
    .inp_valid_i     (comp_resp_valid),
    .inp_ready_o     (comp_resp_ready),
    .oup_valid_o     (reduction_resp_valid_o),
    .oup_ready_i     (reduction_resp_ready_i)
  );

  // Sanity Check
  `ASSERT_INIT(Invalid_ALU_or_FPU, !((FPU_ACTIVE ^ ALU_ACTIVE) == 1'b0))
  `ASSERT_INIT(Invalid_Config, !($bits(RdData_t) != (RdElements*FLEN)))

endmodule

// Floating Point Reduction
module floo_reduction_fpu import floo_pkg::*; #(
  parameter int unsigned ID = 0,
  parameter bit          DEBUG_PRINT_TRACE      = 1'b0
) (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic              flush_i,
  /// IF towards external FPU
  input  logic[63:0]        fpu_req_op1_i,
  input  logic[63:0]        fpu_req_op2_i,
  input  collect_op_t       fpu_req_type_i,
  input  logic              fpu_req_valid_i,
  output logic              fpu_req_ready_o,
  /// IF from external FPU
  output logic[63:0]        fpu_resp_data_o,
  output logic              fpu_resp_valid_o,
  input  logic              fpu_resp_ready_i
);

  /* All local parameter */

  // FPU Configuration
  localparam fpnew_pkg::fpu_features_t FPUFeatures = '{
    Width:             64,
    EnableVectors:     1'b1,
    EnableNanBox:      1'b1,
    FpFmtMask:         {1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1}, //{RVF, RVD, XF16, XF8, XF16ALT, XF8ALT},
    IntFmtMask:        {1'b1, 1'b1, 1'b1, 1'b1} //{XFVEC && (XF8 || XF8ALT), XFVEC && (XF16 || XF16ALT), 1'b1, 1'b0}
  };

  // FPU Implementation copied from the generated code (messy as fuck)
  localparam fpnew_pkg::fpu_implementation_t FPUImplementation [1] = '{
      '{
          PipeRegs:
                    '{'{2, 3, 1, 1, 1, 1},   // FMA Block
                      '{1, 1, 1, 1, 1, 1},   // DIVSQRT
                      '{1, 1, 1, 1, 1, 1},   // NONCOMP
                      '{2, 2, 2, 2, 2, 2},   // CONV
                      '{3, 3, 3, 3, 3, 3}    // DOTP
                      },
          UnitTypes: '{'{fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED},  // FMA
                      '{fpnew_pkg::DISABLED, fpnew_pkg::DISABLED, fpnew_pkg::DISABLED, fpnew_pkg::DISABLED, fpnew_pkg::DISABLED, fpnew_pkg::DISABLED}, // DIVSQRT
                      '{fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL, fpnew_pkg::PARALLEL}, // NONCOMP
                      '{fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED},   // CONV
                      '{fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED, fpnew_pkg::MERGED}},  // DOTP
          PipeConfig: fpnew_pkg::BEFORE
      }
    };

  /* All Typedef Vars */
  typedef struct packed {
    logic [2:0][63:0]        operands;
    fpnew_pkg::roundmode_e   rnd_mode;
    fpnew_pkg::operation_e   op;
    logic                    op_mod;
    fpnew_pkg::fp_format_e   src_fmt;
    fpnew_pkg::fp_format_e   dst_fmt;
    fpnew_pkg::int_format_e  int_fmt;
    logic                    vectorial_op;
  } fpu_in_t;

  typedef struct packed {
    logic [63:0] result;
    logic [4:0]      status;
  } fpu_out_t;

  /* Variable declaration */
  fpu_in_t fpu_in;
  fpu_out_t fpu_out;

  /* Module Declaration */

  // Parse the FPU Request
  always_comb begin
    // Init default values
    fpu_in = '0;

    // Set default Values
    fpu_in.src_fmt = fpnew_pkg::FP64;
    fpu_in.dst_fmt = fpnew_pkg::FP64;
    fpu_in.int_fmt = fpnew_pkg::INT64;
    fpu_in.vectorial_op = 1'b0;
    fpu_in.op_mod = 1'b0;
    fpu_in.rnd_mode = fpnew_pkg::RNE;
    fpu_in.op = fpnew_pkg::ADD;

    // Define the operation we want to execute on the FPU
    unique casez (fpu_req_type_i)
      (floo_pkg::F_Add) : begin
        fpu_in.op = fpnew_pkg::ADD;
        fpu_in.operands[0] = '0;
        fpu_in.operands[1] = fpu_req_op1_i;
        fpu_in.operands[2] = fpu_req_op2_i;
      end
      (floo_pkg::F_Mul) : begin
        fpu_in.op = fpnew_pkg::MUL;
        fpu_in.operands[0] = fpu_req_op1_i;
        fpu_in.operands[1] = fpu_req_op2_i;
        fpu_in.operands[2] = '0;
      end
      (floo_pkg::F_Max) : begin
        fpu_in.op = fpnew_pkg::MINMAX;
        fpu_in.rnd_mode = fpnew_pkg::RNE;
        fpu_in.operands[0] = fpu_req_op1_i;
        fpu_in.operands[1] = fpu_req_op2_i;
        fpu_in.operands[2] = '0;
      end
      (floo_pkg::F_Min) : begin
        fpu_in.op = fpnew_pkg::MINMAX;
        fpu_in.rnd_mode = fpnew_pkg::RTZ;
        fpu_in.operands[0] = fpu_req_op1_i;
        fpu_in.operands[1] = fpu_req_op2_i;
        fpu_in.operands[2] = '0;
      end
      default : begin
        fpu_in.op = fpnew_pkg::ADD;
        fpu_in.operands[0] = '0;
        fpu_in.operands[1] = '0;
        fpu_in.operands[2] = '0;
      end
    endcase
  end

  // Instanciate the FPU as single element
  fpnew_top #(
    // FPU configuration
    .Features                    (FPUFeatures),
    .Implementation              (FPUImplementation[0]),
    .TagType                     (logic),
    .CompressedVecCmpResult      (1),
    .StochasticRndImplementation (fpnew_pkg::DEFAULT_RSR)
  ) i_fpu (
    .clk_i            (clk_i),
    .rst_ni           (rst_ni),
    .hart_id_i        ('0),
    .operands_i       (fpu_in.operands),
    .rnd_mode_i       (fpu_in.rnd_mode),
    .op_i             (fpu_in.op),
    .op_mod_i         (fpu_in.op_mod),
    .src_fmt_i        (fpu_in.src_fmt),
    .dst_fmt_i        (fpu_in.dst_fmt),
    .int_fmt_i        (fpu_in.int_fmt),
    .vectorial_op_i   (fpu_in.vectorial_op),
    .tag_i            ('0),
    .simd_mask_i      ('1),
    .in_valid_i       (fpu_req_valid_i),
    .in_ready_o       (fpu_req_ready_o),
    .flush_i          (flush_i),
    .result_o         (fpu_out.result),
    .status_o         (fpu_out.status),
    .tag_o            (),
    .out_valid_o      (fpu_resp_valid_o),
    .out_ready_i      (fpu_resp_ready_i),
    .busy_o           ()
  );

  // Provide the data to the output
  assign fpu_resp_data_o = fpu_out.result;

  // Print the Status info
  if(DEBUG_PRINT_TRACE) begin
    int cnt_in;
    int cnt_out;
    initial begin
      cnt_in = 0;
      cnt_out = 0;
      while(1) begin
        @(posedge clk_i);
        // Print the incoming operation
        if((fpu_req_valid_i == 1'b1) && (fpu_req_ready_o == 1'b1)) begin
          $display($time, " [FPU %1d - Itr %1d] > FPU Ops: [%f, %f] FPU Op: %s", ID, cnt_in, fpu_req_op1_i, fpu_req_op2_i, genOp(fpu_req_type_i));
          cnt_in = cnt_in + 1;
        end

        // Print Result / Status of FPU
        if((fpu_resp_valid_o == 1'b1) && (fpu_resp_ready_i == 1'b1)) begin
          $display($time, " [FPU %1d - Itr %1d] > FPU Result: %f FPU Status: %s", ID, cnt_out, fpu_out.result, genBitRep(fpu_out.status));
          cnt_out = cnt_out + 1;
        end
      end
    end

    // Helper Function to generate Bitstring
    function string genBitRep (logic [4:0] in);
      string retVal;
      retVal = "B";
      for(int i = 0; i < 5; i++) begin
          if(in[4-i] == 1'b1) begin
              retVal = {retVal, "1"};
          end else begin
              retVal = {retVal, "0"};
          end
      end
      return retVal;
    endfunction

    function string genOp (reduction_op_t type_reduction);
      string retVal;
      retVal = "";
      unique casez (type_reduction)
        (floo_pkg::F_Add) : begin
          retVal = "FAdd";
        end
        (floo_pkg::F_Mul) : begin
          retVal = "FMul";
        end
        (floo_pkg::F_Max) : begin
          retVal = "FMax";
        end
        (floo_pkg::F_Min) : begin
          retVal = "FMin";
        end
      endcase
      return retVal;
    endfunction
  end

endmodule

