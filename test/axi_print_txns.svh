// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

function automatic void print_aw (
  input aw_chan_t aw_expected,
  input aw_chan_t aw_received
);
  // verilog_lint: waive-start line-length
  $display("AW      | expected                                                         | received                                                         ");
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  $display("id:     | %64d | %64d", aw_expected.id, aw_received.id);
  $display("addr:   | %64x | %64x", aw_expected.addr, aw_received.addr);
  $display("len:    | %64d | %64d", aw_expected.len, aw_received.len);
  $display("size:   | %64d | %64d", aw_expected.size, aw_received.size);
  $display("burst:  | %64d | %64d", aw_expected.burst, aw_received.burst);
  $display("lock:   | %64d | %64d", aw_expected.lock, aw_received.lock);
  $display("cache:  | %64d | %64d", aw_expected.cache, aw_received.cache);
  $display("prot:   | %64d | %64d", aw_expected.prot, aw_received.prot);
  $display("qos:    | %64d | %64d", aw_expected.qos, aw_received.qos);
  $display("region: | %64d | %64d", aw_expected.region, aw_received.region);
  $display("user:   | %64d | %64d", aw_expected.user, aw_received.user);
  $display("atop:   | %64d | %64d", aw_expected.atop, aw_received.atop);
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  // verilog_lint: waive-stop line-length
endfunction

function automatic void print_ar (
  input ar_chan_t ar_expected,
  input ar_chan_t ar_received
);
  // verilog_lint: waive-start line-length
  $display("AR      | expected                                                         | received                                                         ");
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  $display("id:     | %64d | %64d", ar_expected.id, ar_received.id);
  $display("addr:   | %64x | %64x", ar_expected.addr, ar_received.addr);
  $display("len:    | %64d | %64d", ar_expected.len, ar_received.len);
  $display("size:   | %64d | %64d", ar_expected.size, ar_received.size);
  $display("burst:  | %64d | %64d", ar_expected.burst, ar_received.burst);
  $display("lock:   | %64d | %64d", ar_expected.lock, ar_received.lock);
  $display("cache:  | %64d | %64d", ar_expected.cache, ar_received.cache);
  $display("prot:   | %64d | %64d", ar_expected.prot, ar_received.prot);
  $display("qos:    | %64d | %64d", ar_expected.qos, ar_received.qos);
  $display("region: | %64d | %64d", ar_expected.region, ar_received.region);
  $display("user:   | %64d | %64d", ar_expected.user, ar_received.user);
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  // verilog_lint: waive-stop line-length
endfunction

function automatic void print_w (
  input w_chan_t w_expected,
  input w_chan_t w_received
);
  // verilog_lint: waive-start line-length
  $display("W       | expected                                                         | received                                                         ");
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  $display("data:   | %64x | %64x", w_expected.data, w_received.data);
  $display("strb:   | %64d | %64d", w_expected.strb, w_received.strb);
  $display("last:   | %64d | %64d", w_expected.last, w_received.last);
  $display("user:   | %64d | %64d", w_expected.user, w_received.user);
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  // verilog_lint: waive-stop line-length
endfunction

function automatic void print_b (
  input b_chan_t b_expected,
  input b_chan_t b_received
);
  // verilog_lint: waive-start line-length
  $display("B       | expected                                                         | received                                                         ");
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  $display("id:     | %64d | %64d", b_expected.id, b_received.id);
  $display("resp:   | %64d | %64d", b_expected.resp, b_received.resp);
  $display("user:   | %64d | %64d", b_expected.user, b_received.user);
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  // verilog_lint: waive-stop line-length
endfunction

function automatic void print_r (
  input r_chan_t r_expected,
  input r_chan_t r_received
);
  // verilog_lint: waive-start line-length
  $display("R       | expected                                                         | received                                                         ");
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  $display("id:     | %64d | %64d", r_expected.id, r_received.id);
  $display("data:   | %64x | %64x", r_expected.data, r_received.data);
  $display("resp:   | %64d | %64d", r_expected.resp, r_received.resp);
  $display("last:   | %64d | %64d", r_expected.last, r_received.last);
  $display("user:   | %64d | %64d", r_expected.user, r_received.user);
  $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
  // verilog_lint: waive-stop line-length
endfunction
