// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

module axi_reorder_remap_compare #(
  parameter int unsigned AxiInIdWidth = 4,
  parameter int unsigned AxiOutIdWidth = 4,
  parameter type aw_chan_t = logic,
  parameter type w_chan_t = logic,
  parameter type b_chan_t = logic,
  parameter type ar_chan_t = logic,
  parameter type r_chan_t = logic,
  parameter type req_t = logic,
  parameter type rsp_t = logic,
  // Derived parameters
  localparam int unsigned NumAxiInIds = 2**AxiInIdWidth,
  localparam int unsigned NumAxiOutIds = 2**AxiOutIdWidth
) (
  input  logic clk_i,
  /// AXI master request channel
  input  req_t mon_mst_req_i,
  /// AXI master response channel
  input  rsp_t mon_mst_rsp_i,
  /// AXI slave request channels
  input  req_t mon_slv_req_i,
  /// AXI slave response channels
  input  rsp_t mon_slv_rsp_i,
  /// End of simulation
  output logic end_of_sim_o
);

`include "include/axi_print_txns.svh"

aw_chan_t aw_queue_sent [NumAxiInIds][$];
aw_chan_t aw_queue_recv [NumAxiOutIds][$];
aw_chan_t aw_w_queue_sent [$];
aw_chan_t aw_w_queue_recv [$];
w_chan_t  w_queue  [NumAxiInIds][$];
ar_chan_t ar_queue_sent [NumAxiInIds][$];
ar_chan_t ar_queue_recv [NumAxiOutIds][$];
b_chan_t  b_queue  [NumAxiInIds][$];
r_chan_t  r_queue  [NumAxiInIds][$];

always_ff @(posedge clk_i) begin : send_ax
  if (mon_mst_req_i.aw_valid && mon_mst_rsp_i.aw_ready) begin
    aw_queue_sent[mon_mst_req_i.aw.id].push_back(mon_mst_req_i.aw);
    aw_w_queue_sent.push_back(mon_mst_req_i.aw);
  end
  if (mon_mst_req_i.w_valid && mon_mst_rsp_i.w_ready) begin
    if (aw_w_queue_sent.size() == 0) $error("No AW for W");
    w_queue[aw_w_queue_sent[0].id].push_back(mon_mst_req_i.w);
    if (mon_mst_req_i.w.last) aw_w_queue_sent.pop_front();
  end
  if (mon_mst_req_i.ar_valid && mon_mst_rsp_i.ar_ready) begin
    ar_queue_sent[mon_mst_req_i.ar.id].push_back(mon_mst_req_i.ar);
  end
end

// verilog_lint: waive-start always-ff-non-blocking
always_ff @(posedge clk_i) begin : recv_ax
  if (mon_slv_req_i.aw_valid && mon_slv_rsp_i.aw_ready) begin
    automatic aw_chan_t mst_aw, slv_aw;
    automatic ar_chan_t atop_ar;
    automatic int match = 0;
    slv_aw = mon_slv_req_i.aw;
    slv_aw.id = 'X;
    foreach(aw_queue_sent[i]) begin
      // Continue if no AW in queue
      if (aw_queue_sent[i].size() == 0) continue;
      // Else check if AW (except ID) matches
      mst_aw = aw_queue_sent[i][0];
      mst_aw.id = 'X;
      if (mst_aw === slv_aw) begin
        // If so, remap ID and push to recv queue
        aw_queue_recv[mon_slv_req_i.aw.id].push_back(aw_queue_sent[i][0]);
        // If it is an atomic operation, push AR to recv queue
        if (mon_slv_req_i.aw.atop[axi_pkg::ATOP_R_RESP]) begin
          atop_ar = '0;
          atop_ar.id = aw_queue_sent[i][0].id;
          ar_queue_recv[mon_slv_req_i.aw.id].push_back(atop_ar);
        end
        aw_w_queue_recv.push_back(aw_queue_sent[i][0]);
        // Remove from sent queue
        aw_queue_sent[i].pop_front();
        match = 1;
        break;
      end
    end
    if (!match) $error("AW does not match");
  end
  if (mon_slv_req_i.w_valid && mon_slv_rsp_i.w_ready) begin
    automatic w_chan_t mst_w, slv_w;
    // Check if AW in queue
    if (aw_w_queue_recv.size() == 0) $error("No AW for W");
    // Check if W in queue
    if (w_queue[aw_w_queue_recv[0].id].size() == 0) $error("No W for W");
    // Check if W matches
    mst_w = w_queue[aw_w_queue_recv[0].id].pop_front();
    slv_w = mon_slv_req_i.w;
    if (mst_w !== slv_w) $error("W does not match");
    // Check if last
    if (mon_slv_req_i.w.last) aw_w_queue_recv.pop_front();
  end
  if (mon_slv_req_i.ar_valid && mon_slv_rsp_i.ar_ready) begin
    automatic ar_chan_t mst_ar, slv_ar;
    automatic int match = 0;
    slv_ar = mon_slv_req_i.ar;
    slv_ar.id = 'X;
    foreach(ar_queue_sent[i]) begin
      // Continue if no AR in queue
      if (ar_queue_sent[i].size() == 0) continue;
      // Else check if AR (except ID) matches
      mst_ar = ar_queue_sent[i][0];
      mst_ar.id = 'X;
      if (mst_ar === slv_ar) begin
        // If so, remap ID and push to recv queue
        ar_queue_recv[mon_slv_req_i.ar.id].push_back(ar_queue_sent[i][0]);
        // Remove from sent queue
        ar_queue_sent[i].pop_front();
        match = 1;
        break;
      end
    end
    if (!match) $error("No AR for AR");
  end
end
// verilog_lint: waive-stop always-ff-non-blocking

// verilog_lint: waive-start always-ff-non-blocking
always_ff @(posedge clk_i) begin : send_rsp
  if (mon_slv_rsp_i.b_valid && mon_slv_req_i.b_ready) begin
    // Check if AW in queue
    if (aw_queue_recv[mon_slv_rsp_i.b.id].size() == 0) $error("No AW for B");
    // Enqueue B in queue of original ID
    b_queue[aw_queue_recv[mon_slv_rsp_i.b.id][0].id].push_back(mon_slv_rsp_i.b);
    // Finish AW if last (always the case for B)
    aw_queue_recv[mon_slv_rsp_i.b.id].pop_front();
  end
  if (mon_slv_rsp_i.r_valid && mon_slv_req_i.r_ready) begin
    // Check if AR
    if (ar_queue_recv[mon_slv_rsp_i.r.id].size() == 0) $error("No AR for R");
    // Enqueue R in queue of original ID
    r_queue[ar_queue_recv[mon_slv_rsp_i.r.id][0].id].push_back(mon_slv_rsp_i.r);
    // Finish AR
    if (mon_slv_rsp_i.r.last) ar_queue_recv[mon_slv_rsp_i.r.id].pop_front();
  end
end
// verilog_lint: waive-stop always-ff-non-blocking

// verilog_lint: waive-start always-ff-non-blocking
always_ff @(posedge clk_i) begin : recv_rsp
  if (mon_mst_rsp_i.b_valid && mon_mst_req_i.b_ready) begin
    automatic b_chan_t mst_b, slv_b;
    // Check if B in queue
    if (b_queue[mon_mst_rsp_i.b.id].size() == 0) $error("No B for B");
    // Check if B matches
    slv_b = b_queue[mon_mst_rsp_i.b.id].pop_front();
    mst_b = mon_mst_rsp_i.b;
    slv_b.id = 'X;
    mst_b.id = 'X;
    if (mst_b !== slv_b) $error("B does not match");
  end
  if (mon_mst_rsp_i.r_valid && mon_mst_req_i.r_ready) begin
    automatic r_chan_t mst_r, slv_r;
    // Check if R in queue
    if (r_queue[mon_mst_rsp_i.r.id].size() == 0) $error("No R for R id:%0d", mon_mst_rsp_i.r.id);
    // Check if R matches
    slv_r = r_queue[mon_mst_rsp_i.r.id].pop_front();
    mst_r = mon_mst_rsp_i.r;
    slv_r.id = 'X;
    mst_r.id = 'X;
    if (mst_r !== slv_r) $error("R does not match");
  end
end
// verilog_lint: waive-stop always-ff-non-blocking

logic [NumAxiInIds-1:0] aw_queue_sent_empty;
logic [NumAxiOutIds-1:0] aw_queue_recv_empty;
logic aw_w_queue_sent_empty;
logic aw_w_queue_recv_empty;
logic [NumAxiInIds-1:0] w_queue_empty;
logic [NumAxiInIds-1:0] ar_queue_sent_empty;
logic [NumAxiOutIds-1:0] ar_queue_recv_empty;
logic [NumAxiInIds-1:0] b_queue_empty;
logic [NumAxiInIds-1:0] r_queue_empty;

assign aw_w_queue_sent_empty = (aw_w_queue_sent.size() == 0);
assign aw_w_queue_recv_empty = (aw_w_queue_recv.size() == 0);

for (genvar i = 0; i < NumAxiInIds; i++) begin : gen_aw_queue_sent_empty
  assign aw_queue_sent_empty[i] = (aw_queue_sent[i].size() == 0);
  assign w_queue_empty[i] = (w_queue[i].size() == 0);
  assign ar_queue_sent_empty[i] = (ar_queue_sent[i].size() == 0);
  assign b_queue_empty[i] = (b_queue[i].size() == 0);
  assign r_queue_empty[i] = (r_queue[i].size() == 0);
end

for (genvar i = 0; i < NumAxiOutIds; i++) begin : gen_aw_queue_recv_empty
  assign aw_queue_recv_empty[i] = (aw_queue_recv[i].size() == 0);
  assign ar_queue_recv_empty[i] = (ar_queue_recv[i].size() == 0);
end

assign end_of_sim_o = aw_w_queue_sent_empty &&
                      aw_w_queue_recv_empty &&
                      &aw_queue_sent_empty &&
                      &aw_queue_recv_empty &&
                      &w_queue_empty &&
                      &ar_queue_sent_empty &&
                      &ar_queue_recv_empty &&
                      &b_queue_empty &&
                      &r_queue_empty;
endmodule
