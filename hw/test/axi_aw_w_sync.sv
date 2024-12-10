// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
//  - Michael Rogenmoser <michaero@iis.ee.ethz.ch>


/// Only allows passing of AW if corresponding W is valid.
/// Only allows passing of W if corresponding AW is valid or sent.

 `include "axi/assign.svh"
 `include "common_cells/registers.svh"

 module axi_aw_w_sync #(
   parameter type axi_req_t  = logic,
   parameter type axi_resp_t = logic
 ) (
   input  logic      clk_i,
   input  logic      rst_ni,

   input  axi_req_t  slv_req_i,
   output axi_resp_t slv_resp_o,

   output axi_req_t  mst_req_o,
   input  axi_resp_t mst_resp_i
 );

   `AXI_ASSIGN_AR_STRUCT(mst_req_o.ar, slv_req_i.ar)
   assign mst_req_o.ar_valid = slv_req_i.ar_valid;
   assign slv_resp_o.ar_ready = mst_resp_i.ar_ready;
   `AXI_ASSIGN_R_STRUCT(slv_resp_o.r, mst_resp_i.r)
   assign slv_resp_o.r_valid = mst_resp_i.r_valid;
   assign mst_req_o.r_ready = slv_req_i.r_ready;
   `AXI_ASSIGN_B_STRUCT(slv_resp_o.b, mst_resp_i.b)
   assign slv_resp_o.b_valid = mst_resp_i.b_valid;
   assign mst_req_o.b_ready = slv_req_i.b_ready;

   `AXI_ASSIGN_AW_STRUCT(mst_req_o.aw, slv_req_i.aw)
   `AXI_ASSIGN_W_STRUCT(mst_req_o.w, slv_req_i.w)

   logic aw_valid, w_valid;
   logic w_completed_d, w_completed_q;
   `FF(w_completed_q, w_completed_d, 1'b1)


   // AW is valid when previous write completed and current AW and W are valid
   assign aw_valid = w_completed_q && slv_req_i.aw_valid && slv_req_i.w_valid;

   // W is valid when corresponding AW is valid or sent
   assign w_valid = slv_req_i.w_valid && (!w_completed_q || (aw_valid && mst_resp_i.aw_ready)); // This is probably pretty bad for timing

   always_comb begin
     w_completed_d = w_completed_q;
     // reset w_completed to 0 when a new AW request happens
     if (aw_valid && mst_resp_i.aw_ready) begin
       w_completed_d = 1'b0;
     end
     // assign w_completed to w_last when W handshake is done and W is ongoing
     if (slv_req_i.w_valid && slv_resp_o.w_ready) begin
       w_completed_d = slv_req_i.w.last;
     end
   end

   assign mst_req_o.w_valid = w_valid;
   assign slv_resp_o.w_ready = w_valid && mst_resp_i.w_ready;
   assign mst_req_o.aw_valid = aw_valid;
   assign slv_resp_o.aw_ready = aw_valid && mst_resp_i.aw_ready;

 endmodule
