// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This module controls the hole reduction by setting all Mux / DeMus / Buff Select into its
// appropriate position. To control the reduction(s) we have one buffer which stores all the
// required metadata.
//
// We have three different configurations: Generic, Stalling & Simple
//
// Generic:     Most sufficicated option!
//              Allows to have multiple reduction ongoing with the downside of requiring a TAG
//              for each element. This mode can achieve a 100% FPU utilization (5 Stages) given
//              enough data to reduce. To achieve 100% FPU utilization in all cases the partial
//              buffer size should be as deep as the FPU pipeline.
//
// Stalling:    Good balance between area overhead & performence
//              Allows one ongoing reduction if more than two flits are involved.
//              It stalls all incoming element until the one
//              it is currently working on is finished therefor no tag requirements.
//              Can not achieve a 100% FPU utilization if more than two inputs are involved in
//              the reduction. The partial buffer can be reduced to its minimum size of 2.
//
// Simple:      least hw overhead
//              All incoming reduction can consits of only two elements therefor no partial buffer
//              is required. However the user writing the software has to garantee that the only
//              two elements are used in eac reduction. This requires that the sw guy is aware of
//              the physical implementation of the NoC. No tag or mask is required as we can start
//              the reduction as soon as we have two elements on the input.
//
// To garantee the ordering in the generic implementation this modul implements priority scheme
// e.g. the first buffer entry has the most priority, then the second, then the third etc.
// It works only on elements from lower priority if the higher ones can not schedule
// any operation.
//
// This module must be aware of the underlying communication protocol embedded in the FlooNoc.
// Any header like information (e.g. AXI AW transmission) needs to be forwarded just once
// without reducing anything. This is implmented by a bypass option.

// Limits:
// - We can not handle out-of-order
// - We can not handle multiple reduction when they do not belong to the same subset of addresses
//   (Due to the tag generation)

// Open Points:
// - AW flits stalls the hole process > We could potentially send the AW as soon as we receive
//   the first  AW packet and then delet the others rather than waiting until all AW flits are
//   available.

// Disclaimer:
// Sorry for the mess in the code ;) I had to add too much configuration option(s)!

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"
`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

module floo_offload_reduction_controller #(
    /// Number of Routes
    parameter int unsigned  NumRoutes               = 1,
    /// Partial buffer size for partial results
    /// used in Generic / Stalling configuration
    parameter int unsigned  RdPartialBufferSize     = 3,
    /// Pipeline depth of the external reduction logic
    parameter int unsigned  RdPipelineDepth         = 3,
    /// Data payload size to extract from the floo flit
    parameter type          RdData_t                = logic,
    /// Possible reduction operation(s)
    parameter type          RdOperation_t           = logic,
    /// Various types used by floonoc / routing
    parameter type          tag_t                   = logic,
    parameter type          mask_t                  = logic,
    parameter type          flit_t                  = logic,
    parameter type          hdr_t                   = logic,
    parameter type          data_tag_t              = logic,
    parameter type          data_mask_tag_t         = logic,
    parameter type          flit_mask_tag_t         = logic,
    parameter type          flit_in_out_dir_tag_t   = logic,
    /// Type to address the entries of the partial result buffer
    parameter type          idx_part_res_t          = logic,
    /// Controller configuration
    parameter bit           GENERIC                 = 1'b1,
    parameter bit           SIMPLE                  = 1'b0,
    parameter bit           STALLING                = 1'b0,
    /// Defines if the underlying protocol is AXI
    parameter bit           RdSupportAxi            = 1'b1,
    /// Axi Configuration
    parameter floo_pkg::axi_cfg_t AxiCfg            = '0,
    /// Define if we support a bypass or not (for AXI AW header)
    parameter bit           RdEnableBypass          = 1'b1
) (
    /// Control Signals
    input   logic                                   clk_i,
    input   logic                                   rst_ni,
    input   logic                                   flush_i,
    /// Input from the fifos
    input   flit_in_out_dir_tag_t [NumRoutes-1:0]   head_fifo_flit_i,
    input   logic [NumRoutes-1:0]                   head_fifo_valid_i,
    output  logic [NumRoutes-1:0]                   head_fifo_ready_o,
    /// Output Operands (Support only 2 operands)
    output  data_mask_tag_t [1:0]                   operand_data_o,
    output  logic [1:0]                             operand_valid_o,
    input   logic [1:0]                             operand_ready_i,
    /// Metadata reduction req
    output  RdOperation_t                           reduction_req_operation_o,
    input   mask_t                                  reduction_req_mask_i,
    input   logic                                   reduction_req_valid_i,
    input   logic                                   reduction_req_ready_i,
    /// Final Input from the reduction offload (fully reduced)
    input   data_tag_t                              fully_red_data_i,
    input   logic                                   fully_red_valid_i,
    output  logic                                   fully_red_ready_o,
    /// Metadata reduction resp
    input   mask_t                                  reduction_resp_mask_i,
    input   tag_t                                   reduction_resp_tag_i,
    input   logic                                   reduction_resp_valid_i,
    input   logic                                   reduction_resp_ready_i,
    /// Flit provided to the output of the reduction logic
    output  flit_mask_tag_t                         final_flit_o,
    output  logic                                   final_valid_o,
    input   logic                                   final_ready_i,
    /// Spyglass from the partial result buffer
    input   tag_t [RdPartialBufferSize-1:0]         buf_spyglass_tag_i,
    input   logic [RdPartialBufferSize-1:0]         buf_spyglass_valid_i,
    /// Contol Output for the index of the partial result buffer
    output idx_part_res_t [1:0]                     select_partial_result_idx_o,
    /// Control Signal for the Muxes / DeMuxes
    output logic [1:0]                              ctrl_part_res_mux_o,
    output logic                                    ctrl_output_demux_o
);

/* All local parameter */
// Buffer Size to control all ongoing reduction
// @ GENERIC: Needs to be at least to be RdPartialBufferSize which is RdPipelineDepth+1
// @ STALLING: We only have one reduction ongoing so 1 is enough
// @ SIMPLE: We do not need any buffer so 1 to avoid questa panic (will be optimized away as never used)
localparam int unsigned RdBufferSize = (GENERIC) ? (RdPartialBufferSize) : 1;

localparam bit [NumRoutes-1:0] ONES = 1;

/* All Typedef Vars */

// Generate the axi / floo types to extract all relevant information
// If we want to support another protocol rather AXI then add it here
typedef logic [AxiCfg.AddrWidth-1:0] axi_addr_t;
typedef logic [AxiCfg.InIdWidth-1:0] axi_in_id_t;
typedef logic [AxiCfg.OutIdWidth-1:0] axi_out_id_t;
typedef logic [AxiCfg.UserWidth-1:0] axi_user_t;
typedef logic [AxiCfg.DataWidth-1:0] axi_data_t;
typedef logic [AxiCfg.DataWidth/8-1:0] axi_strb_t;

`AXI_TYPEDEF_ALL_CT(axi, axi_req_t, axi_rsp_t, axi_addr_t, axi_in_id_t, axi_data_t, axi_strb_t, axi_user_t)
`AXI_TYPEDEF_AW_CHAN_T(axi_out_aw_chan_t, axi_addr_t, axi_out_id_t, axi_user_t)
`FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi, AxiCfg, hdr_t)

// Typedef to encompass an ongoing reduction in the buffer
// TODO(raroth):    Try to store only the header inside the buffer_t and not the hole flit!
//          It looks like the Synth can not optimize away the unused FlipFlop.
//          I assumed this but I think it won't do it.
//          It will get an uglier code but It can save some Area!
typedef struct packed {
    // Copy (one) flit for all metadata in the package
    flit_t                      header;
    // Final reduction mask e.g. from which input i need to reduce input flits
    mask_t                      final_mask;
    // Assigned tag by the generator
    tag_t                       tag;
    // Output direction (N - E - S - W - L) of the flit
    mask_t                      output_dir;
    // Is the entry valid
    logic                       f_valid;
    // forward directly with the bypass
    logic                       f_forwarding;
} buffer_t;

// Index for the input
typedef logic [cf_math_pkg::idx_width(NumRoutes)-1:0] idx_input_t;

/* Variable declaration */

// Buffer to hold all reduction info's
buffer_t [RdBufferSize-1:0]             buffer_q, buffer_d;

// Stalled input signals
flit_in_out_dir_tag_t [NumRoutes-1:0]   stalling_flit;
logic [NumRoutes-1:0]                   stalling_valid;
logic [NumRoutes-1:0]                   stalling_ready;

// Signal to insert a new reduction in the buffer (serialzied approach to reduce required logic)
// Iterates over all input and set to 1 if we found a tag that is not yet inside the buffer
flit_in_out_dir_tag_t [NumRoutes-1:0]   unkown_incoming_flit;
flit_in_out_dir_tag_t                   new_incoming_flit;
logic [NumRoutes-1:0]                   unkown_incoming_valid;
logic                                   new_incoming_valid;

// Indicates if we have inserted the new data into the buffer or not
logic f_insert_data_in_buffer;

// Flags to find two valid operands for an reduction
logic f_op1_found;
logic f_op2_found;

// Temporary signals for all selection(s)
idx_input_t [1:0]       tmp_sel_input;
idx_part_res_t [1:0]    tmp_sel_part_res_buf;
logic [1:0]             tmp_part_res_mux;

// Locked in signals to prevent changed during backpressure
logic                   locked_d, locked_q;
idx_input_t [1:0]       selected_input_d, selected_input_q;
idx_part_res_t [1:0]    selected_partial_result_buffer_d, selected_partial_result_buffer_q;
logic [1:0]             selected_partial_result_mux_d, selected_partial_result_mux_q;
RdOperation_t           selected_op_d, selected_op_q;
tag_t                   selected_tag_d, selected_tag_q;

// Bypass Signal
flit_mask_tag_t bypass_flit;
logic           bypass_valid;
logic           bypass_ready;

// internal generated signals which holds the output mask for the current reduction response
flit_t  fully_red_flit;
mask_t  fully_red_mask;
flit_t  metadata_out_flit;
mask_t  metadata_out_mask;

// Var used for the simple controller
flit_t req_header;
mask_t req_output_mask;
logic simple_reduction_ongoing_n;

// Signal to retire the elements from the buffer
logic retire_element;
logic stalling_reduction_ongoing_n;
logic backpressure_fpu_resp;

/* Module Declaration */

// If the stalling mode is enabled then we have to stall the inputs
// e.g. we deassert the valid without ackknowledge to the outside world
// and only resets of the final flit leaves the reduction logic
if(STALLING) begin : gen_stalling
    for(genvar i = 0; i < NumRoutes;i++) begin
        floo_offload_reduction_stalling #() i_stalling_module (
            .clk_i          (clk_i),
            .rst_ni         (rst_ni),
            .flush_i        (flush_i),
            .src_valid_i    (head_fifo_valid_i[i]),
            .src_ready_o    (head_fifo_ready_o[i]),
            .stalling_i     (retire_element | (bypass_valid & bypass_ready)),
            .dst_valid_o    (stalling_valid[i]),
            .dst_ready_i    (stalling_ready[i])
        );
    end
    assign stalling_flit = head_fifo_flit_i;
end else begin : gen_no_stalling
    assign stalling_flit = head_fifo_flit_i;
    assign stalling_valid = head_fifo_valid_i;
    assign head_fifo_ready_o = stalling_ready;
end

// Check if on any input we have new data are available. Each input is checked against
// each buffer entry if the tag is available. However only one input will be forwarded
// into the buffer.
if(GENERIC || STALLING) begin : gen_filter_unkown_flit_tags
    // Search if any element on the input can be inserted into the buffer
    always_comb begin
        // Init all Vars
        unkown_incoming_flit = '0;
        unkown_incoming_valid = 1'b0;

        // Loop over all inputs
        for(int k = 0; k < NumRoutes; k++) begin
            // Is the incoming flit valid?
            if(stalling_valid[k] == 1'b1) begin
                // This input can be inserted if it is not already in the buffer
                unkown_incoming_valid[k] = 1'b1;
                // Assign the acutal data here
                unkown_incoming_flit[k] = stalling_flit[k];
                // Go through the hole buffer and check if the element is already inside or not
                for(int j = 0; j < RdBufferSize; j++) begin
                    if((stalling_flit[k].tag == buffer_q[j].tag) && (buffer_q[j].f_valid == 1'b1)) begin
                        unkown_incoming_valid[k] = 1'b0;
                    end
                end
            end
        end
    end
end else begin
    assign unkown_incoming_flit = '0;
    assign unkown_incoming_valid = 1'b0;
end

// Select one of the unkown flits to be inserted in the buffer next. (Prio. lower indexes)
// Both loop's could be combined but maybe there could be a better way to find the lsb
// indexes here
if(GENERIC || STALLING) begin : gen_incoming_data
    // Search if any element on the input can be inserted into the buffer
    always_comb begin
        // Init all Vars
        new_incoming_flit = '0;
        new_incoming_valid = 1'b0;

        // Loop over unkown inputs
        for(int k = 0; k < NumRoutes; k++) begin
            // Is the incoming flit valid and is not already one selected?
            if((unkown_incoming_valid[k] == 1'b1) && (new_incoming_valid == 1'b0)) begin
                // If we find a valid one - selct our selection
                new_incoming_valid = 1'b1;
                new_incoming_flit = unkown_incoming_flit[k];
            end
        end
    end
end else begin
    assign new_incoming_flit = '0;
    assign new_incoming_valid = 1'b0;
end

// Dedect if the system does apply backpressure
// The problem is that we want to fill the FPU pipeline. However if backpressure is applied we can
// only insert an element if at least one element originates in the partial result buffer.
// Otherwise we could deadlock thehole system.
assign backpressure_fpu_resp = reduction_resp_valid_i & (~reduction_resp_ready_i);

// The control part can be split into 4 distinctive stages (with additional substages)
// 1. Stage: Populate the buffer with new data
// 2. Stage: Schedule an reduction when possible
// 3. Stage: Schedule an direct passthrough if possible (AXI AW)
// 4. Stage: Retire an buffer entry if the corresponding tag leaves the reduction logic
// 5. Stage: If one higher prio buffer entry is free then push the buffer by one position

// The entries of the buffer are prioritized by the index. Operation from the first index
// are priorited over the ones from the second, then from the third etc.
// This only happens if we use the generic configuration as the stalling one has only
// a single buffer entry (b.c. it works only on one reduction at the time).

// TODO(raroth): optimize the timing for the generic controller here. The "locked_d" variable serializes
//       the evaluation of the meta data buffer. If we remove this and introduce an priority
//       arbiter at the output to select the most "pressing" reduction we could restore the timing
if(GENERIC || STALLING) begin : gen_controller_stalling_generic
    always_comb begin
        // Init all Vars
        buffer_d = buffer_q;
        locked_d = locked_q;
        selected_input_d = selected_input_q;
        selected_partial_result_buffer_d = selected_partial_result_buffer_q;
        selected_partial_result_mux_d = selected_partial_result_mux_q;
        selected_op_d = selected_op_q;
        selected_tag_d = selected_tag_q;

        // All ready signals for the input(s)
        stalling_ready = '0;

        // Output signal to the reduction
        operand_data_o = '0;
        operand_valid_o = '0;

        // Init control signal for partial result / mux
        select_partial_result_idx_o = '0;
        ctrl_part_res_mux_o = '0;
        reduction_req_operation_o = floo_pkg::F_Add;

        // Flags
        f_op1_found = 1'b0;
        f_op2_found = 1'b0;
        f_insert_data_in_buffer = 1'b0;

        // Temporary selector signals
        tmp_sel_input = '0;
        tmp_sel_part_res_buf = '0;
        tmp_part_res_mux = '0;

        // Signal to directly bypass the reduction
        bypass_flit = '0;
        bypass_valid = 1'b0;

        // Iterate over all buffer entries - handle by prio
        for(int i = 0; i < RdBufferSize; i++) begin
            // Reset Var for the loop
            f_op1_found = 1'b0;
            f_op2_found = 1'b0;
            tmp_sel_input = '0;
            tmp_sel_part_res_buf = '0;
            tmp_part_res_mux = '0;

            // 1. Stage: Accept new Data into the Buffer if we have free space and a valid entry
            if(buffer_d[i].f_valid == 1'b0) begin

                // Check if we can insert a new element
                if((new_incoming_valid == 1'b1) && (f_insert_data_in_buffer == 1'b0)) begin
                    // Lock in such a way that only one buffer entry can accept the data
                    f_insert_data_in_buffer = 1'b1;
                    // Insert the data into the selected entry
                    buffer_d[i].header = new_incoming_flit.flit;
                    buffer_d[i].final_mask = new_incoming_flit.input_exp;
                    buffer_d[i].output_dir = new_incoming_flit.output_dir;
                    buffer_d[i].tag = new_incoming_flit.tag;
                    buffer_d[i].f_valid = 1'b1;
                    // Check if we have to directly forward the flit
                    buffer_d[i].f_forwarding = (new_incoming_flit.flit.hdr.collective_op == floo_pkg::R_Select) ? 1'b1 : 1'b0;
                    if((buffer_d[i].f_forwarding == 1'b1) && (RdEnableBypass == 1'b0)) begin
                        $error($time, "Somehow an AW flit got to an reduction which does not support bypass - Why?");
                    end
                end
            end

            // 2.1 Stage: Try to schedula an operation from the partial result buffer when:
            //      - Entry in Buffer is valid
            //      - No higher prioritized buffer already has scheduled an operation
            //      - The reduction is not an AW transaction
            if( (buffer_d[i].f_valid == 1'b1) &&
                (locked_d == 1'b0) &&
                (buffer_d[i].f_forwarding == 0)) begin

                // First iterate over the partial result buffer
                for(int j = 0; j < RdPartialBufferSize;j++) begin
                    if((buf_spyglass_tag_i[j] == buffer_d[i].tag) && (buf_spyglass_valid_i[j] == 1'b1)) begin
                        if(f_op1_found == 1'b0) begin
                            // Select the appropriate entry in the partial result buffer
                            tmp_sel_part_res_buf[0] = j;
                            // Switch the Mux0 from the input to the partial result buffer
                            tmp_part_res_mux[0] = 1'b1;
                            // lock the first op
                            f_op1_found = 1'b1;
                        end else if(f_op2_found == 1'b0) begin
                            // Select the appropriate entry in the partial result buffer
                            tmp_sel_part_res_buf[1] = j;
                            // Switch the Mux1 from the input to the partial result buffer
                            tmp_part_res_mux[1] = 1'b1;
                            // lock the second op
                            f_op2_found = 1'b1;
                        end
                    end
                end
            end

            // 2.2 Stage: Try to schedula an operation from the inputs when:
            //      - Entry in Buffer is valid
            //      - No higher prioritized buffer already has scheduled an operation
            //      - The reduction is not an AW transaction
            //      - No backpressure is applied to the FPU response or f_op1_found is 1
            //        and f_op2_found is 0 (otherwise deadlock potential!)
            if( (buffer_d[i].f_valid == 1'b1) &&
                (locked_d == 1'b0) &&
                (buffer_d[i].f_forwarding == 0) &&
                ((backpressure_fpu_resp == 1'b0) || ((f_op1_found == 1'b1) && (f_op2_found == 1'b0)))) begin

                // Iterate over all inputs
                for(int j = 0; j < NumRoutes;j++) begin
                    if((stalling_flit[j].tag == buffer_d[i].tag) && (stalling_valid[j] == 1'b1)) begin
                        if(f_op1_found == 1'b0) begin
                            // Select the appropriate input (Mux0 is per default input selection)
                            tmp_sel_input[0] = j;
                            // lock the first op
                            f_op1_found = 1'b1;
                        end else if(f_op2_found == 1'b0) begin
                            // Select the appropriate input (Mux1 is per default input selection)
                            tmp_sel_input[1] = j;
                            // lock the second op
                            f_op2_found = 1'b1;
                        end
                    end
                end
            end

            // 2.3 Stage: Schedule an operation if:
            //  - Both operands are found
            //  - No locked in operation
            if( (f_op1_found == 1'b1) &&
                (f_op2_found == 1'b1) &&
                (locked_d == 1'b0)) begin

                // lock the output signals
                locked_d = 1'b1;
                // Copy the required signal
                selected_input_d = tmp_sel_input;
                selected_partial_result_buffer_d = tmp_sel_part_res_buf;
                selected_partial_result_mux_d = tmp_part_res_mux;
                selected_op_d = buffer_d[i].header.hdr.collective_op;
                selected_tag_d = buffer_d[i].tag;
            end

            // 3 Stage: Send an AW flit to the output if:
            // - buffer entry 0 to ensure ordering
            // - The reduction is an AW transaction
            // - All required AW flits are aligned at the input
            // - If stalling: Only when the fpu hasn't a element in, otherwise reordering will occure!
            if( (buffer_d[i].f_valid == 1'b1) &&
                (buffer_d[i].f_forwarding == 1) &&
                ((stalling_valid & buffer_d[i].final_mask) == buffer_d[i].final_mask) &&
                ((stalling_reduction_ongoing_n == 1'b1) || (!STALLING)) &&
                (i == 0) &&
                (RdEnableBypass == 1'b1)) begin

                // Assign valid & data signal to the output
                bypass_valid = 1'b1;
                bypass_flit.flit = buffer_d[i].header;
                bypass_flit.mask = buffer_d[i].output_dir;
                bypass_flit.tag = buffer_d[i].tag;
                // Forward the bypass ready signal to the input's which requires the signal
                stalling_ready = (buffer_d[i].final_mask & {(NumRoutes){bypass_ready}});
            end

            // 4 Stage: Retire an element if:
            // - Valid Buffer Element
            // - Tag matches the one that leaves the reduction logic
            // - Handshake on the output
            //
            // Note:
            // To garantee ordering we only should retire from the 0'th entry!
            // However to avoid deadlocks with not retired instruction I allow
            // to retire from any position. TODO: Solve by introducing assertion
            if( (buffer_d[i].f_valid == 1'b1) &&
                (buffer_d[i].tag == final_flit_o.tag) &&
                ((retire_element == 1'b1) || ((bypass_valid == 1'b1) && (bypass_ready == 1'b1) && STALLING))) begin

                // Reset the valid flag of the buffer
                buffer_d[i].f_valid = 1'b0;
                // ATTENTION! DO NOT OVERWRITE THE buffer_d[i].mask & .header fields!
                // Otherwise the stalling implementation won't work
                if(i > 0) begin
                    $error($time, "We retired an element other from buffer entry 0. This should not happen. Why?");
                end
            end
        end

        // 5 Stage: Copy the data to a higher prio slot if it is free and we are valid
        // (Stalling case already handled by having i only 0!)
        for(int i = 0; i < RdBufferSize; i++) begin
            if(i != 0) begin
                if((buffer_d[i-1].f_valid == 1'b0) && (buffer_d[i].f_valid == 1'b1)) begin
                    buffer_d[i-1] = buffer_d[i];    // copy the data (incl. valid bit)
                    buffer_d[i] = '0;               // delet all old data
                end
            end
        end

        // Handle all locked in signals!
        if(locked_d == 1'b1) begin
            // Handle both operands
            for(int i = 0; i < 2; i++) begin
                // Use data provided by the partial result buffer
                if(selected_partial_result_mux_d[i] == 1'b1) begin : fetch_result_from_partial_buffer
                    select_partial_result_idx_o[i] = selected_partial_result_buffer_d[i];
                // Use data provided by the input(s)
                end else begin : fetch_result_from_input
                    // data: extract the data from the AXI W channel in the selected input
                    // mask: shift the 00001 according to the selected input
                    // tag: just get it from the locked in version
                    if(RdSupportAxi) begin
                        operand_data_o[i] = {extractAXIWdata(stalling_flit[selected_input_d[i]].flit), ONES << selected_input_d[i], selected_tag_d};
                    end
                    // Set the valid bit
                    operand_valid_o[i] = 1'b1;
                    // Forward the ready bit without influencing already existing ready bits
                    // on other inputs. We can schedule an bypass and a operation in the same
                    // cycle.
                    // We either shift 00001 or 00000 to the left according to the selected input
                    stalling_ready = stalling_ready | ((ONES & {(NumRoutes){operand_ready_i[i]}}) << selected_input_d[i]);
                end
            end
            // Set the selected OP
            reduction_req_operation_o = selected_op_d;
            // Set the mux
            ctrl_part_res_mux_o = selected_partial_result_mux_d;
        end

        // Release the lock if we recognize a valid handshake
        if((reduction_req_valid_i == 1'b1) && (reduction_req_ready_i == 1'b1)) begin
            locked_d = 1'b0;
        end
    end
end else begin
    // Set all not required vars to 0
    assign select_partial_result_idx_o = '0;
    assign ctrl_part_res_mux_o = '0;
    assign selected_partial_result_buffer_d = '0;
    assign selected_partial_result_mux_d = '0;
    assign selected_tag_d = '0;
    assign selected_op_d = '0;
end

// Determint when a element from the buffer should be retired. In the stalling case we track
// if the element is to be forwarded to the output after this iteration.
if(GENERIC) begin : gen_generic_retirement
    assign retire_element = final_valid_o & final_ready_i;
end else if(STALLING) begin : gen_stalling_retirement
    assign retire_element = ((buffer_d[0].final_mask == reduction_req_mask_i) && (reduction_req_valid_i == 1'b1) && (reduction_req_ready_i == 1'b1)) ? 1'b1 : 1'b0;
end else begin
    assign retire_element = 1'b0;
end

// Simple controller which is only able to combine two flits
// TODO: Add assertion to the decoded mask so that at most only two bits can be set!
if(SIMPLE) begin : gen_simple_controller
    always_comb begin

        // Init all Vars
        buffer_d = buffer_q;
        locked_d = locked_q;
        selected_input_d = selected_input_q;

        // All ready signals for the input(s)
        stalling_ready = '0;

        // Output signal to the reduction
        operand_data_o = '0;
        operand_valid_o = '0;

        // Init control signal for partial result / mux
        reduction_req_operation_o = '0;

        // Signal to directly bypass the reduction
        bypass_flit = '0;
        bypass_valid = 1'b0;

        // Simple controller specific vars
        req_header = '0;
        req_output_mask = '0;

        // Set intial value for the op found signal
        tmp_sel_input = '0;
        f_op1_found = 1'b0;
        f_op2_found = 1'b0;

        // 1.1 Stage: Search for schedulable operands when:
        // - Input is valid
        // - Currently no operation locked in
        for(int i = 0; i < NumRoutes; i++) begin
            // Find the first operand
            if((stalling_valid[i] == 1'b1) && (f_op1_found == 1'b0) && (locked_d == 1'b0)) begin
                // Select the appropriate input (No Mux in simple case)
                tmp_sel_input[0] = i;
                // lock the first op
                f_op1_found = 1'b1;
            // Find the second operand
            end else if((stalling_valid[i] == 1'b1) && (f_op1_found == 1'b1) && (f_op2_found == 1'b0) && (locked_d == 1'b0)) begin
                // Select the appropriate input (No Mux in simple case)
                tmp_sel_input[1] = i;
                // lock the second op
                f_op2_found = 1'b1;
            end
        end

        // 1.2 Stage: Schedule an operation if:
        //  - Both operands are found
        //  - No locked in operation
        if( (f_op1_found == 1'b1) &&
            (f_op2_found == 1'b1) &&
            (locked_d == 1'b0)) begin

            // lock the output matrix
            locked_d = 1'b1;
            // Copy the required signal
            selected_input_d = tmp_sel_input;
        end

        // 1.3 Stage: Forward the data to the FPU or the bypass
        if(locked_d == 1'b1) begin
            // Handle the case for a bypassable flit
            if(stalling_flit[selected_input_d[0]].flit.hdr.collective_op == floo_pkg::R_Select) begin
                // Stall sending the bypass until the pipeline is empty to avoid reordering
                if(simple_reduction_ongoing_n) begin
                    // AW flit found - direct forward to the output
                    bypass_valid = 1'b1;
                    // Forward the entire AW flit
                    bypass_flit.flit = stalling_flit[selected_input_d[0]].flit;
                    bypass_flit.mask = stalling_flit[selected_input_d[0]].output_dir;
                    // Forward the ready signal to all involved inputs
                    stalling_ready = (stalling_flit[selected_input_d[0]].input_exp & {(NumRoutes){bypass_ready}});
                end
            end else begin
                // Iterate over all operands and prepare the data
                stalling_ready = '0;
                for(int i = 0; i < 2; i++) begin
                    if(RdSupportAxi) begin
                        operand_data_o[i].data = extractAXIWdata(stalling_flit[selected_input_d[i]].flit);
                    end

                    // Forward the handshaking
                    stalling_ready = stalling_ready | ((ONES & {(NumRoutes){operand_ready_i[i]}}) << selected_input_d[i]);
                    // Schedule the operation
                    operand_valid_o[i] = 1'b1;
                end
                // Select the ongoing operand
                reduction_req_operation_o = stalling_flit[selected_input_d[0]].flit.hdr.collective_op;
                // Forward the header of the flit
                req_header = stalling_flit[selected_input_d[0]].flit;
                // Forward the output selection mask
                req_output_mask = stalling_flit[selected_input_d[0]].output_dir;
            end
        end

        // 1.4 Stage: Release lock if operation was accepted
        if((reduction_req_valid_i == 1'b1) && (reduction_req_ready_i == 1'b1)) begin
            locked_d = 1'b0;
        end

        // 1.5 Stage: Release lock if bypass was accepted
        if((bypass_valid == 1'b1) && (bypass_ready == 1'b1)) begin
            locked_d = 1'b0;
        end
    end
end else begin
    assign req_header = '0;
    assign req_output_mask = '0;
end

// If we want to support a bypass then use an arb-tree to include the bypass!
if(RdEnableBypass == 1'b1) begin : gen_bypass_arb_tree
    stream_arbiter_flushable  #(
        .DATA_T                 (flit_mask_tag_t),
        .N_INP                  (2)
    ) i_output_arbiter (
        .clk_i                  (clk_i),
        .rst_ni                 (rst_ni),
        .flush_i                (flush_i),
        .inp_data_i             ({{fully_red_flit, fully_red_mask, fully_red_data_i.tag}, bypass_flit}),
        .inp_valid_i            ({fully_red_valid_i, bypass_valid}),
        .inp_ready_o            ({fully_red_ready_o, bypass_ready}),
        .oup_data_o             (final_flit_o),
        .oup_valid_o            (final_valid_o),
        .oup_ready_i            (final_ready_i)
    );
end else begin
    assign final_flit_o = {fully_red_flit, fully_red_mask, fully_red_data_i.tag};
    assign final_valid_o = fully_red_valid_i;
    assign fully_red_ready_o = final_ready_i;
end

// Generate the header and the output mask for the fully reduced data
// @ Generic:            Iterate through the buffer and try to find a matching tag
//                       then extract the header and the output mask
// @ Stalling:           When we know that the element leave the reduction logic after the next
//                       reduction then we fetch the header / output mask and store them inside
//                       a designated fifo.
// @ Simple:             Store the header / output dir directly inside a fifo when
//                       the request is placed!
if(GENERIC) begin
    assign stalling_reduction_ongoing_n = 1'b0; //Sig. not used in stalling case
    always_comb begin
        metadata_out_flit = '0;
        metadata_out_mask = '0;

        for(int i = 0; i < RdBufferSize; i++) begin
            if(buffer_q[i].f_valid && (buffer_q[i].tag == fully_red_data_i.tag) && fully_red_valid_i) begin
                metadata_out_flit = buffer_q[i].header;
                metadata_out_mask = buffer_q[i].output_dir;
            end
        end
    end
end else if(STALLING) begin
    // Fifo to store the header of the element during the FPU reduction
    fifo_v3 #(
        .FALL_THROUGH     (1'b0),
        .dtype            (flit_t),
        .DEPTH            (RdPipelineDepth+2)
    ) i_fifo_header (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .flush_i          (flush_i),
        .testmode_i       (1'b0),
        .full_o           (),
        .empty_o          (stalling_reduction_ongoing_n),
        .usage_o          (),
        .data_i           (buffer_d[0].header),
        // push header only if we know that this is the last iteration of the flit e.g. it
        // leaves the reduction logic afterwards
        .push_i           (retire_element),
        .data_o           (metadata_out_flit),
        // pop header on active fpu resp hs and active output hs
        // We need to include the resp hs as otherwise a bypass flit could remove an element
        .pop_i            (final_valid_o & final_ready_i & reduction_resp_valid_i & reduction_resp_ready_i)
    );

    // Fifo to store the output direction of the element during the FPU reduction
    fifo_v3 #(
        .FALL_THROUGH     (1'b0),
        .DATA_WIDTH       (NumRoutes),
        .DEPTH            (RdPipelineDepth+2)
    ) i_fifo_outdir (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .flush_i          (flush_i),
        .testmode_i       (1'b0),
        .full_o           (),
        .empty_o          (),
        .usage_o          (),
        .data_i           (buffer_d[0].output_dir),
        // push header only if we know that this is the last iteration of the flit e.g. it
        // leaves the reduction logic afterwards
        .push_i           (retire_element),
        .data_o           (metadata_out_mask),
        // pop mask on active fpu resp hs and active output hs
        // We need to include the resp hs as otherwise a bypass flit could remove an element
        .pop_i            (final_valid_o & final_ready_i & reduction_resp_valid_i & reduction_resp_ready_i)
    );
end else begin
    // Fifo to store the header of the element during the FPU reduction
    fifo_v3 #(
        .FALL_THROUGH     (1'b0),
        .dtype            (flit_t),
        .DEPTH            (RdPipelineDepth+2)
    ) i_fifo_header (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .flush_i          (flush_i),
        .testmode_i       (1'b0),
        .full_o           (),
        .empty_o          (simple_reduction_ongoing_n),
        .usage_o          (),
        .data_i           (req_header),
        .push_i           (reduction_req_valid_i & reduction_req_ready_i),  // push mask on active fpu req hs
        .data_o           (metadata_out_flit),
        .pop_i            (reduction_resp_valid_i & reduction_resp_ready_i) // pop mask on active fpu resp hs
    );

    // Fifo to store the output direction of the element during the FPU reduction
    fifo_v3 #(
        .FALL_THROUGH     (1'b0),
        .DATA_WIDTH       (NumRoutes),
        .DEPTH            (RdPipelineDepth+2)
    ) i_fifo_outdir (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .flush_i          (flush_i),
        .testmode_i       (1'b0),
        .full_o           (),
        .empty_o          (),
        .usage_o          (),
        .data_i           (req_output_mask),
        .push_i           (reduction_req_valid_i & reduction_req_ready_i),  // push mask on active fpu req hs
        .data_o           (metadata_out_mask),
        .pop_i            (reduction_resp_valid_i & reduction_resp_ready_i) // pop mask on active fpu resp hs
    );
end

// Parse the mask
//Combine the metadata flit together with the result from the reduction.
always_comb begin
    fully_red_flit = '0;
    if(RdSupportAxi == 1'b1) begin
        fully_red_flit = insertAXIWdata(metadata_out_flit, fully_red_data_i.data);
    end
    fully_red_mask = metadata_out_mask;
end

// Generate the signal for the demux which either forwards the reduction response
// to the partial buffer or towards the output (if fully reduced)
if(GENERIC) begin : gen_response_demux_generic
    logic [RdBufferSize-1:0] temp_match;
    for(genvar i = 0; i < RdBufferSize; i++) begin
        // Only allow if we found a matching final mask and tag with a valid entry
        assign temp_match[i] = (buffer_q[i].f_valid && (buffer_q[i].final_mask == reduction_resp_mask_i) && (buffer_q[i].tag == reduction_resp_tag_i)) ? 1'b1 : 1'b0;
    end
    assign ctrl_output_demux_o = (|temp_match) & reduction_resp_valid_i;
end else if(STALLING) begin : gen_response_demux_stalling
    // Fifo to store if the element should be forwarded to the output
    fifo_v3 #(
        .FALL_THROUGH     (1'b0),
        .DATA_WIDTH       (1),
        .DEPTH            (RdPipelineDepth+2)
    ) i_fifo_outdir (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .flush_i          (flush_i),
        .testmode_i       (1'b0),
        .full_o           (),
        .empty_o          (),
        .usage_o          (),
        .data_i           (retire_element),
        .push_i           (reduction_req_valid_i & reduction_req_ready_i),  // push mask on active fpu req hs
        .data_o           (ctrl_output_demux_o),
        .pop_i            (reduction_resp_valid_i & reduction_resp_ready_i) // pop mask on active fpu resp hs
    );
end else begin
    // No buffering - always forward it
    assign ctrl_output_demux_o = 1'b1;
end

// AXI Specific function!
// Insert data into AXI specific W frame!
function automatic flit_t insertAXIWdata(flit_t metadata, RdData_t data);
    floo_axi_w_flit_t w_flit;
    // Parse the entire flit
    w_flit = floo_axi_w_flit_t'(metadata);
    // Copy the new data
    w_flit.payload.data = data;
    return flit_t'(w_flit);
endfunction

// Extract data from AXI specific W frame!
function automatic RdData_t extractAXIWdata(flit_t metadata);
    floo_axi_w_flit_t w_flit;
    // Parse the entire flit
    w_flit = floo_axi_w_flit_t'(metadata);
    // Return the W data
    return w_flit.payload.data;
endfunction

// Store the data in the buffer
`FF(buffer_q, buffer_d, '0, clk_i, rst_ni)

// Store all locked in signals
`FF(locked_q, locked_d, '0, clk_i, rst_ni)
`FF(selected_input_q, selected_input_d, '0, clk_i, rst_ni)
`FF(selected_partial_result_buffer_q, selected_partial_result_buffer_d, '0, clk_i, rst_ni)
`FF(selected_partial_result_mux_q, selected_partial_result_mux_d, '0, clk_i, rst_ni)
`FF(selected_op_q, selected_op_d, floo_pkg::F_Add, clk_i, rst_ni)
`FF(selected_tag_q, selected_tag_d, '0, clk_i, rst_ni)

/* ASSERTION Checks */
// We can only run GENERIC or SIMPLE or STALLING
`ASSERT_INIT(Invalid_Configuration_1, !(GENERIC & SIMPLE))
`ASSERT_INIT(Invalid_Configuration_2, !(STALLING & SIMPLE))
`ASSERT_INIT(Invalid_Configuration_3, !(GENERIC & STALLING))
`ASSERT_INIT(Invalid_Configuration_4, (GENERIC | STALLING | SIMPLE))

// Currently the AXI support must be enabled
`ASSERT_INIT(Support_AXI, RdSupportAxi)

endmodule
