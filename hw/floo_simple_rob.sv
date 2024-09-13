// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

/// A simplistic low-complexity Reorder Buffer, similar to a FIFO
/// WARNING: The implementation has a known bug for burst support,
/// and is therefore only advised to be used for B responses.
module floo_simple_rob #(
  /// If the response only consists of small metadata i.e. B channel
  /// In this case no SRAM will be instantied and the response will be
  /// metadata will be stored in SCMs
  parameter bit          OnlyMetaData = 1'b0,
  /// Size of the reorder buffer
  parameter int unsigned RoBSize = 32'd64,
  /// Data type of response to be reordered
  parameter type         ax_len_t   = logic,
  parameter type         rsp_chan_t = logic,
  parameter type         rsp_data_t = logic,
  parameter type         rsp_meta_t = logic,
  parameter type         rob_idx_t  = logic[$clog2(RoBSize)-1:0],
  parameter type         dest_t     = logic,
  parameter type         sram_cfg_t = logic,
  // Dependent parameters, DO NOT OVERRIDE!
  localparam type rob_flag_t        = logic[RoBSize-1:0]
) (
  input  logic      clk_i,
  input  logic      rst_ni,
  input  sram_cfg_t sram_cfg_i,
  input  logic      ax_valid_i,
  output logic      ax_ready_o,
  input  ax_len_t   ax_len_i,
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

  rob_idx_t read_pointer_q, read_pointer_d;
  rob_idx_t write_pointer_q, write_pointer_d;
  logic [$clog2(RoBSize):0] status_cnt_q, status_cnt_d;
  logic [$clog2(RoBSize):0] free_entries;
  rsp_meta_t  [RoBSize-1:0] rob_meta_q, rob_meta_d;
  rsp_meta_t rob_meta;
  rob_idx_t rsp_burst_cnt_q, rsp_burst_cnt_d;
  rob_flag_t rob_valid_q, rob_valid_d;
  axi_pkg::len_t ax_len;

  typedef enum logic {RoBWrite, RoBRead} rob_state_e;
  rob_state_e rob_state_q, rob_state_d;

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
      .NumWords   ( RoBSize           ),
      .DataWidth  ( $bits(rsp_data_t) ),
      .NumPorts   ( 1                 ),
      .impl_in_t  ( sram_cfg_t        )
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


  assign free_entries = RoBSize - status_cnt_q;
  assign ax_len = (OnlyMetaData)? 1 : ax_len_i + 1'b1;

  always_comb begin
    read_pointer_d = read_pointer_q;
    write_pointer_d = write_pointer_q;
    status_cnt_d = status_cnt_q;

    ax_ready_o = 1'b0;
    ax_valid_o = 1'b0;
    ax_rob_req_o = 1'b1;
    ax_rob_idx_o = '0;
    rsp_ready_o = '0;
    rsp_valid_o = rsp_out_valid_q;

    rob_req = 1'b0;
    rob_wen = 1'b0;
    rob_addr = '0;
    rob_valid_d = rob_valid_q;
    rob_meta_d = rob_meta_q;

    rob_state_d = rob_state_q;
    rsp_burst_cnt_d = rsp_burst_cnt_q;
    rsp_out_valid_d = '0;

    if (ax_valid_i && free_entries >= ax_len) begin
      ax_valid_o = 1'b1;
      ax_rob_idx_o = write_pointer_q;
      if (ax_ready_i) begin
        ax_ready_o = 1'b1;
        // Increment write and status counter
        if (write_pointer_q + ax_len >= RoBSize) begin
          write_pointer_d = write_pointer_q + ax_len - RoBSize;
        end else begin
          write_pointer_d = write_pointer_q + ax_len;
        end
        status_cnt_d = status_cnt_q + ax_len;
      end
    end

    unique case (rob_state_q)

      RoBWrite: begin

        if (rsp_valid_i) begin
          rsp_ready_o = 1'b1;
          rob_req = 1'b1;
          rob_wen = 1'b1;
          rob_addr = rsp_rob_idx_i + rsp_burst_cnt_q;
          rob_meta_d[rob_addr] = rob_meta;
          rob_valid_d[rob_addr] = 1'b1;
          // WARNING: This implementation does not support interleaved
          // bursts with different IDs. Each burst would need its own
          // `rsp_burst_cnt` counter which is currently not implemented.
          // The way to implement this would be to increment `rsp_rob_idx_i`
          // at the endpoint which issues the responses.
          rsp_burst_cnt_d = (rsp_last_i)? '0 : rsp_burst_cnt_q + 1'b1;
        end

        if (rsp_last_i && rob_valid_d[read_pointer_q]) begin
          rob_state_d = RoBRead;
          rsp_burst_cnt_d = '0;
        end
      end

      RoBRead: begin
        if (rob_valid_q[read_pointer_q]) begin
          rob_req = 1'b1;
          rsp_out_valid_d = 1'b1;
          if (rsp_valid_o && rsp_ready_i) begin
            rob_valid_d[read_pointer_q] = 1'b0;
            if (read_pointer_q + 1'b1 >= RoBSize) begin
              read_pointer_d = read_pointer_q + 1'b1 - RoBSize;
            end else begin
              read_pointer_d = read_pointer_q + 1'b1;
            end
            status_cnt_d--;
          end
          rob_addr = read_pointer_d;
        end else begin
          rsp_valid_o = 1'b0;
          rob_state_d = RoBWrite;
        end
      end

      default:;
    endcase

  end

  if (OnlyMetaData) begin : gen_b_rsp
    assign rob_meta = rsp_i;
    assign rsp_o = rob_meta_q[rob_addr_q];
  end else begin : gen_r_rsp
    // For R responses, we have to split up the response into data and metadata
    assign rob_meta = '{id: rsp_i.id,user: rsp_i.user,last: rsp_i.last,resp: rsp_i.resp};
    assign rsp_o = '{
      data: rob_rdata,
      id: rob_meta_q[rob_addr_q].id,
      user: rob_meta_q[rob_addr_q].user,
      last: rob_meta_q[rob_addr_q].last,
      resp: rob_meta_q[rob_addr_q].resp};
    assign rob_wdata = rsp_i.data;
  end

  `FF(read_pointer_q, read_pointer_d, '0)
  `FF(write_pointer_q, write_pointer_d, '0)
  `FF(status_cnt_q, status_cnt_d, '0)
  `FF(rsp_burst_cnt_q, rsp_burst_cnt_d, '0)
  `FF(rob_valid_q, rob_valid_d, '0)
  `FF(rob_addr_q, rob_addr, '0)
  `FFL(rob_meta_q, rob_meta_d, rob_req && rob_wen, '0)
  `FF(rob_state_q, rob_state_d, RoBWrite)
  `FF(rsp_out_valid_q, rsp_out_valid_d, '0)

  // This module currently does not handle interleaved burst responses correctly
  `ASSERT(NoBurstSupport, rsp_last_i == 1'b1)

endmodule
