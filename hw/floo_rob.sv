// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

/// A table-based Reorder Buffer
module floo_rob #(
  /// Maximum number of transactions in flight per ID which *require* reordering
  parameter int unsigned MaxRoTxnsPerId = 32'd32,
  /// If the response only consists of small metadata i.e. B channel
  /// In this case no SRAM will be instantied and the response will be
  /// metadata will be stored in normal FFs
  parameter bit          OnlyMetaData = 1'b0,
  /// Size of the reorder buffer
  parameter int unsigned ReorderBufferSize = 32'd64,
  /// Data type of response to be reordered
  parameter type         ax_len_t   = logic,
  parameter type         ax_id_t    = logic,
  parameter type         rsp_chan_t = logic,
  parameter type         rsp_data_t = logic,
  parameter type         rsp_meta_t = logic,
  parameter type         rob_idx_t  = logic,
  parameter type         dest_t     = logic,
  // Type for implementation inputs and outputs
  parameter type         sram_cfg_t = logic
) (
  input  logic      clk_i,
  input  logic      rst_ni,
  input  sram_cfg_t sram_cfg_i,
  input  logic      ax_valid_i,
  output logic      ax_ready_o,
  input  ax_len_t   ax_len_i,
  input  ax_id_t    ax_id_i,
  input  dest_t     ax_dest_i,
  output logic      ax_valid_o,
  input  logic      ax_ready_i,
  output logic      ax_rob_req_o,
  output rob_idx_t  ax_rob_idx_o,
  input  logic      rsp_valid_i,
  output logic      rsp_ready_o,
  input  rsp_chan_t rsp_i,
  input  logic      rsp_rob_req_i,
  input  rob_idx_t  rsp_rob_idx_i,
  input  logic      rsp_last_i,
  output logic      rsp_valid_o,
  input  logic      rsp_ready_i,
  output rsp_chan_t rsp_o
);

  localparam int unsigned AxiIdWidth = $bits(ax_id_i);
  localparam int unsigned NumIds = 2**AxiIdWidth;
  typedef logic[AxiIdWidth-1:0] axi_id_t;
  typedef logic[$clog2(NumIds)-1:0] num_id_t;
  typedef logic[ReorderBufferSize-1:0] rob_flag_t;

  /////////////////////////
  //  Transaction Table  //
  /////////////////////////

  rob_idx_t rob_next_free_idx;

  // `st_peek` is the status of the least recently modified ID
  // This ID will be used to peek into the reorder buffer, if there is
  // data that can be released, in that case the state is switched from
  // `RoBWrite` to `RoBRead`
  logic    st_peek_valid;
  axi_id_t st_rob_peek_id_q;
  rob_idx_t   st_peek_rob_idx;
  // the peek ID changes at every response handshake
  `FFL(st_rob_peek_id_q, rsp_i.id, rsp_valid_i && rsp_ready_o, '0)

  // `st_rsp` is the status of the response ID that is currently being processed
  logic       st_rsp_pop;
  logic       st_rsp_rob_req;
  axi_id_t    st_rsp_out_id;
  rob_idx_t   st_rsp_rob_idx;

  // `st_ax` is the status of the request ID that is currently being processed
  logic st_ax_push;
  logic st_ax_gnt;

  floo_rob_status_table #(
    .NumIds       ( NumIds          ),
    .MaxTxnsPerId ( MaxRoTxnsPerId  ),
    .id_t         ( axi_id_t        ),
    .rob_idx_t    ( rob_idx_t       ),
    .dest_t       ( dest_t          )
  ) i_floo_rob_status_table (
    .clk_i          ( clk_i               ),
    .rst_ni         ( rst_ni              ),
    .rsp_pop_i      ( st_rsp_pop          ),
    .rsp_id_i       ( st_rsp_out_id       ),
    .rsp_rob_req_o  ( st_rsp_rob_req      ),
    .rsp_rob_idx_o  ( st_rsp_rob_idx      ),
    .peek_id_i      ( st_rob_peek_id_q    ),
    .peek_valid_o   ( st_peek_valid       ),
    .peek_rob_idx_o ( st_peek_rob_idx     ),
    .ax_push_i      ( st_ax_push          ),
    .ax_id_i        ( ax_id_i             ),
    .ax_rob_idx_i   ( rob_next_free_idx   ),
    .ax_dest_i      ( ax_dest_i           ),
    .ax_rob_req_o   ( ax_rob_req_o        ),
    .ax_rob_idx_o   ( ax_rob_idx_o        ),
    .ax_gnt_o       ( st_ax_gnt           )
   );

  //////////////////////
  //  Reorder Buffer  //
  //////////////////////

  logic       rob_req;
  logic       rob_wen;
  rob_idx_t   rob_addr;
  rob_idx_t   rob_addr_q;
  rsp_data_t  rob_wdata;
  rsp_data_t  rob_rdata;
  logic       rsp_out_valid_q, rsp_out_valid_d;

  if (!OnlyMetaData) begin : gen_rob_sram
    tc_sram_impl #(
      .NumWords   (ReorderBufferSize),
      .DataWidth  ($bits(rsp_data_t)),
      .NumPorts   ( 1               ),
      .impl_in_t  ( sram_cfg_t      )
    ) i_reorder_buffer (
      .clk_i    ( clk_i       ),
      .rst_ni   ( rst_ni      ),
      .impl_i   ( sram_cfg_i  ),
      .impl_o   (             ),
      .req_i    ( rob_req     ),
      .addr_i   ( rob_addr    ),
      .be_i     ( '1          ),
      .wdata_i  ( rob_wdata   ),
      .we_i     ( rob_wen     ),
      .rdata_o  ( rob_rdata   )
    );
  end else begin : gen_no_rob_sram
    assign rob_rdata = '0;
  end

  rsp_meta_t  [ReorderBufferSize-1:0] rob_meta_q, rob_meta_d;
  rob_flag_t rob_valid_q, rob_valid_d;
  rob_flag_t rob_alloc_q, rob_alloc_d;
  rob_idx_t rob_free_space;

  `FF(rob_valid_q, rob_valid_d, '0)
  `FF(rob_alloc_q, rob_alloc_d, '0)
  `FF(rob_addr_q, rob_addr, '0)
  `FF(rsp_out_valid_q, rsp_out_valid_d, '0)
  `FFL(rob_meta_q, rob_meta_d, rob_req && rob_wen, '0)

  assign rob_next_free_idx = ReorderBufferSize - rob_free_space;

  lzc #(
    .WIDTH  ( ReorderBufferSize ),
    .MODE   ( 1'b1              )
  ) i_lzc (
    .in_i     ( rob_alloc_q     ),
    .cnt_o    ( rob_free_space  ),
    .empty_o  (                 )
  );

  ///////////////////////////////
  //  Near Ax & Far Rsp Logic  //
  ///////////////////////////////

  typedef enum logic {RoBWrite, RoBRead} rob_state_e;
  rob_state_e rob_state_q, rob_state_d;
  `FF(rob_state_q, rob_state_d, RoBRead)

  // In the ID table, only the pointer to the first entry of a specific response
  // is stored. From there an offset is used to calculate the exact index in the
  // reorder buffer.
  rob_idx_t [NumIds-1:0] read_rob_idx_offset_q, read_rob_idx_offset_d;
  rob_idx_t [NumIds-1:0] write_rob_idx_offset_q, write_rob_idx_offset_d;
  `FF(read_rob_idx_offset_q, read_rob_idx_offset_d, '0)
  `FF(write_rob_idx_offset_q, write_rob_idx_offset_d, '0)

  // `is_last_rsp_in_rob` denotes if it is the last beat in a burst.
  // For B responses, this is always true
  logic is_last_rsp_in_rob;
  rsp_meta_t rob_meta;

  // TODO: make this prettier
  if (OnlyMetaData) begin : gen_b_rsp
    assign rob_meta = rsp_i;
    assign rsp_o = (rob_state_q == RoBRead)? rob_meta_q[rob_addr] : rsp_i;
    // B responses are not burst, so they are always the last beat
    assign is_last_rsp_in_rob = 1'b1;
  end else begin : gen_r_rsp
    // For R responses, we have to split up the response into data and metadata
    assign rob_meta = '{
      id: rsp_i.id,
      user: rsp_i.user,
      last: rsp_i.last,
      resp: rsp_i.resp
    };
    assign rsp_o = (rob_state_q == RoBRead)?
    '{data: rob_rdata,
      id: rob_meta_q[rob_addr_q].id,
      user: rob_meta_q[rob_addr_q].user,
      last: rob_meta_q[rob_addr_q].last,
      resp: rob_meta_q[rob_addr_q].resp}
    : rsp_i;
    assign rob_wdata = rsp_i.data;
    assign is_last_rsp_in_rob = rob_meta_q[rob_addr_q].last;
  end

  always_comb begin

    rob_state_d = rob_state_q;
    rob_valid_d = rob_valid_q;
    rob_alloc_d = rob_alloc_q;
    rob_meta_d = rob_meta_q;

    rob_req = 1'b0;
    rob_addr = '0;
    rob_wen = 1'b0;

    read_rob_idx_offset_d = read_rob_idx_offset_q;
    write_rob_idx_offset_d = write_rob_idx_offset_q;

    ax_valid_o = 1'b0;
    ax_ready_o = 1'b0;

    rsp_valid_o = 1'b0;
    rsp_ready_o = rsp_ready_i;
    rsp_out_valid_d = '0;

    st_ax_push = 1'b0;
    st_rsp_pop = 1'b0;
    st_rsp_out_id = (rob_state_q == RoBWrite)? rsp_i.id : st_rob_peek_id_q;

    unique case (rob_state_q)

      RoBRead: begin

        rsp_ready_o = 1'b0;
        rsp_out_valid_d = rsp_out_valid_q;
        rsp_valid_o = 1'b0;
        rob_req = 1'b1;
        rob_wen = 1'b0;
        rob_addr = st_peek_rob_idx + read_rob_idx_offset_q[st_rsp_out_id];

        // If the peek ID is valid and there is a valid item in the RoB
        // for the current response, then we can release the response
        if (st_peek_valid && rob_valid_q[rob_addr]) begin
          rsp_out_valid_d = 1'b1;
          rsp_valid_o = rsp_out_valid_q;
          if (rsp_ready_i && rsp_valid_o) begin
            // Clear the valid memory and the allocated flag
            rob_valid_d[rob_addr] = 1'b0;
            rob_alloc_d[rob_addr] = 1'b0;
            rob_addr++;
            // increment the offset counter
            read_rob_idx_offset_d[st_rsp_out_id]++;
            // If this was the last beat for this ID, increment the rsp_counter
            if (is_last_rsp_in_rob) begin
              st_rsp_pop = 1'b1;
              rsp_out_valid_d = 1'b0;
              read_rob_idx_offset_d[st_rsp_out_id] = '0;
            end
          end
        // If the peeked entry is invalid or the ROB is empty, we can't release
        // a response, so we have to wait for the next response
        end else begin
          rob_state_d = RoBWrite;
        end
      end

      RoBWrite: begin

        rob_addr = rsp_rob_idx_i + write_rob_idx_offset_q[st_rsp_out_id];

        // If the peeked ID has a valid entry and there is data in the RoB,
        // we can release the response from the RoB to make place for new requests
        if (st_peek_valid && rob_valid_q[st_peek_rob_idx + read_rob_idx_offset_q[st_rob_peek_id_q]]) begin
          rob_state_d = RoBRead;
          // Don't forward the current response, since we are releasing one from the RoB
          rsp_valid_o = 1'b0;
          rsp_ready_o = 1'b0;
        end else if (rsp_valid_i) begin
          // If the request counter is at zero, this means that there is only one
          // request in flight for this ID, hence no space was allocated in the
          // reorder buffer, the response can be forwarded directly, and the
          // valid flag can be cleared in the ID status table
          if (!rsp_rob_req_i) begin
            rsp_valid_o = 1'b1;
            if (rsp_last_i && rsp_ready_i) begin
              // Pop the transaction
              st_rsp_pop = 1'b1;
            end
          // If sequence ID of the response is equal to the currently expected
          // response ID, the response is in order and can be forwarded directly
          // The response ID counter is incremented by one, and in case it was the
          // last one, the entry in the ID status table can be cleared
          end else if (st_rsp_rob_req && (rsp_rob_idx_i == st_rsp_rob_idx)) begin
            rsp_valid_o = 1'b1;
            if (rsp_ready_i) begin
              // Unset the allocated bit
              rob_alloc_d[rob_addr] = 1'b0;
              write_rob_idx_offset_d[st_rsp_out_id]++;
              // If this was the last beat of a response for this ID, increment the
              // response counter and clear the entry in the ID status table if
              // this was the very last response
              if (rsp_last_i) begin
                // Pop the transaction
                st_rsp_pop = 1'b1;
                write_rob_idx_offset_d[st_rsp_out_id] = '0;
              end
            end
          // Otherwise, the response is out of order and has to be stored in the
          // reorder buffer. The response is stored in the next slot in the based
          // the rob_idx in the ID status table and the current offset. The offset
          // is incremented with every response
          end else begin
            rob_req = 1'b1;
            rob_wen = 1'b1;
            rsp_ready_o = 1'b1;
            rob_valid_d[rob_addr] = 1'b1;
            rob_meta_d[rob_addr] = rob_meta;
            write_rob_idx_offset_d[st_rsp_out_id] = (rsp_last_i)? '0 : write_rob_idx_offset_q[st_rsp_out_id] + 1;
          end
        end
      end

      default:;
    endcase

    if (ax_valid_i && st_ax_gnt) begin
      // Check if this is the second or more transaction for this ID
      // In that case, the entry in the ID status tabe is already valid
      if (!ax_rob_req_o) begin
        ax_valid_o = 1'b1;
        if (ax_ready_i) begin
          ax_ready_o = 1'b1;
          st_ax_push = 1'b1;
        end
      end else if (rob_free_space > ax_len_i) begin
        ax_valid_o = 1'b1;
        if (ax_ready_i) begin
          ax_ready_o = 1'b1;
          st_ax_push = 1'b1;
          // Mark the entries in the reorder buffer as occupied
          // Only the last entry is set to 1 which is enough, since
          // the free buffer size is just calcluated with a leading-zero-counter
          rob_alloc_d[rob_next_free_idx + ax_len_i] = 1'b1;
        end
      end
    end
  end

endmodule

module floo_rob_status_table #(
  parameter int unsigned NumIds = 32'd32,
  parameter int unsigned MaxTxnsPerId = 32'd32,
  parameter type id_t        = logic,
  parameter type dest_t      = logic,
  parameter type rob_idx_t   = logic
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  // Response access
  input  logic        rsp_pop_i,
  input  id_t         rsp_id_i,
  output logic        rsp_rob_req_o,
  output rob_idx_t    rsp_rob_idx_o,
  // Peek access
  input  id_t         peek_id_i,
  output logic        peek_valid_o,
  output rob_idx_t    peek_rob_idx_o,
  // Request access
  input  logic        ax_push_i,
  input  id_t         ax_id_i,
  input  rob_idx_t    ax_rob_idx_i,
  input  dest_t       ax_dest_i,
  output logic        ax_rob_req_o,
  output rob_idx_t    ax_rob_idx_o,
  output logic        ax_gnt_o
);

  typedef logic [$clog2(MaxTxnsPerId)-1:0] fifo_usage_t;
  typedef struct packed {
    logic rob_req;
    rob_idx_t rob_idx;
  } fifo_data_t;

  logic [NumIds-1:0] fifo_push, fifo_pop;
  logic [NumIds-1:0] ax_rob_req_q, ax_rob_req_d;
  logic [NumIds-1:0] fifo_full, fifo_empty;
  fifo_data_t [NumIds-1:0] fifo_data_in, fifo_data_out;
  dest_t [NumIds-1:0] prev_dest_q, prev_dest_d;
  fifo_usage_t [NumIds-1:0] fifo_usage;

  always_comb begin
    fifo_push = '0;
    fifo_pop  = '0;
    fifo_data_in = '0;
    ax_rob_req_d = ax_rob_req_q;
    prev_dest_d = prev_dest_q;

    peek_valid_o = !fifo_empty[peek_id_i] && fifo_data_out[peek_id_i].rob_req;
    peek_rob_idx_o = fifo_data_out[peek_id_i].rob_idx;
    rsp_rob_req_o = fifo_data_out[rsp_id_i].rob_req;
    rsp_rob_idx_o = fifo_data_out[rsp_id_i].rob_idx;
    ax_rob_idx_o = ax_rob_idx_i;
    ax_gnt_o = !fifo_full[ax_id_i];
    ax_rob_req_o = 1'b0;

    // The last destination is always stored on every push
    if (ax_push_i && ax_gnt_o) begin
      prev_dest_d[ax_id_i] = ax_dest_i;
    end

    // The first never needs to be reordered
    if (!ax_rob_req_q[ax_id_i] && (fifo_usage[ax_id_i] == 0)) begin
      ax_rob_req_o = 1'b0;
      // The second and more pushes check if the destination is the same as the previous one
      // If so, the request can be forwarded directly without reordering
    end else if (!ax_rob_req_q[ax_id_i] && (prev_dest_q[ax_id_i] == ax_dest_i)) begin
      ax_rob_req_o = 1'b0;
      // Otherwise we need to start reordering
    end else begin
      ax_rob_req_d[ax_id_i] = 1'b1;
      ax_rob_req_o = 1'b1;
    end

    // Clear the valid flag if the last transaction is popped,
    // but not if the AX side is pushing a new transaction
    if (rsp_pop_i && !((rsp_id_i == ax_id_i) && ax_push_i)) begin
      if (fifo_usage[rsp_id_i] == 1) begin
        ax_rob_req_d[rsp_id_i] = 1'b0;
      end
    end

    fifo_push[ax_id_i] = ax_push_i && ax_gnt_o;
    fifo_pop[rsp_id_i] = rsp_pop_i;
    fifo_data_in[ax_id_i].rob_req = ax_rob_req_o;
    fifo_data_in[ax_id_i].rob_idx = ax_rob_idx_o;

  end

  fifo_v3 #(
    .DEPTH  ( MaxTxnsPerId  ),
    .dtype  ( fifo_data_t   )
  ) i_status_table_fifo [NumIds-1:0] (
    .clk_i,
    .rst_ni,
    .push_i     ( fifo_push     ),
    .testmode_i ( 1'b0          ),
    .flush_i    ( 1'b0          ),
    .data_i     ( fifo_data_in  ),
    .pop_i      ( fifo_pop      ),
    .data_o     ( fifo_data_out),
    .empty_o    ( fifo_empty    ),
    .full_o     ( fifo_full     ),
    .usage_o    ( fifo_usage    )
  );

  `FF(ax_rob_req_q, ax_rob_req_d, '0)
  `FF(prev_dest_q, prev_dest_d, '0)

endmodule
