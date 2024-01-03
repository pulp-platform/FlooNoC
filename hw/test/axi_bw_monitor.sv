// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
//  - Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A AXI4 Bus Monitor for measuring the throughput and latency of the AXI4 Bus
module axi_bw_monitor #(
  parameter type req_t     = logic,
  parameter type rsp_t    = logic,
  parameter int unsigned AxiIdWidth = 4,
  parameter int unsigned NumAxiIds = 2**AxiIdWidth,
  parameter string name = ""
) (
  input logic clk_i,
  input logic en_i,
  input logic end_of_sim_i,
  input req_t req_i,
  input rsp_t rsp_i,
  output logic [31:0] ar_in_flight_o,
  output logic [31:0] aw_in_flight_o
);

  int unsigned cycle_cnt;

  int unsigned ar_outstanding [NumAxiIds][$];
  int unsigned aw_outstanding [NumAxiIds][$];
  int unsigned read_latency [$];
  int unsigned write_latency [$];
  real read_latency_mean;
  real write_latency_mean;
  real read_latency_stddev;
  real write_latency_stddev;
  real read_bw;
  real write_bw;
  real read_util;
  real write_util;
  int unsigned ar_cnt;
  int unsigned aw_cnt;
  int unsigned w_cnt;
  int unsigned r_cnt;

  int unsigned prev_r_last;


  initial begin
    cycle_cnt = 0;
    @(posedge en_i);
    while(!end_of_sim_i) begin
      @(posedge clk_i);
      cycle_cnt++;
    end
  end

  always @(posedge clk_i) begin
    ar_in_flight_o = 0;
    aw_in_flight_o = 0;
    for (int i = 0; i < NumAxiIds; i++) begin
      ar_in_flight_o += ar_outstanding[i].size();
      aw_in_flight_o += aw_outstanding[i].size();
    end
  end

  initial begin
    ar_cnt = 0;
    aw_cnt = 0;
    w_cnt = 0;
    r_cnt = 0;
    read_latency_mean = 0;
    write_latency_mean = 0;
    read_latency_stddev = 0;
    write_latency_stddev = 0;
    read_bw = 0;
    write_bw = 0;
    read_util = 0;
    write_util = 0;
    prev_r_last = 1;
    @(posedge en_i);
    while(!end_of_sim_i) begin
      @(posedge clk_i);
      if (req_i.ar_valid && rsp_i.ar_ready) begin
        ar_outstanding[req_i.ar.id].push_back(cycle_cnt);
        ar_cnt++;
      end
      if (req_i.aw_valid && rsp_i.aw_ready) begin
        aw_outstanding[req_i.aw.id].push_back(cycle_cnt);
        aw_cnt++;
      end
      if (req_i.w_valid && rsp_i.w_ready) begin
        w_cnt++;
      end
      if (rsp_i.r_valid && req_i.r_ready) begin
        r_cnt++;
        if (prev_r_last) begin
          read_latency.push_back(cycle_cnt - ar_outstanding[rsp_i.r.id].pop_front());
        end
        prev_r_last = rsp_i.r.last;
      end
      if (rsp_i.b_valid && req_i.b_ready) begin
        write_latency.push_back(cycle_cnt - aw_outstanding[rsp_i.b.id].pop_front());
      end
    end

    // Calculate the average of all latencies
    foreach (read_latency[i]) begin
      read_latency_mean += read_latency[i];
    end
    foreach (write_latency[i]) begin
      write_latency_mean += write_latency[i];
    end
    if (read_latency.size() == 0) begin
      read_latency_mean = 0;
    end else begin
      read_latency_mean = read_latency_mean / read_latency.size();
    end
    if (write_latency.size() == 0) begin
      write_latency_mean = 0;
    end else begin
      write_latency_mean = write_latency_mean / write_latency.size();
    end
    // Calculate the standard deviation of all latencies
    foreach (read_latency[i]) begin
      read_latency_stddev += (read_latency[i] - read_latency_mean) ** 2;
    end
    foreach (write_latency[i]) begin
      write_latency_stddev += (write_latency[i] - write_latency_mean) ** 2;
    end
    if (read_latency.size() == 0) begin
      read_latency_stddev = 0;
    end else begin
      read_latency_stddev = $sqrt(read_latency_stddev / read_latency.size());
    end
    if (write_latency.size() == 0) begin
      write_latency_stddev = 0;
    end else begin
      write_latency_stddev = $sqrt(write_latency_stddev / write_latency.size());
    end

    // Calculate the BW and utilization
    read_bw = real'(r_cnt) * $bits(rsp_i.r.data) / real'(cycle_cnt);
    write_bw = real'(w_cnt) * $bits(req_i.w.data) / real'(cycle_cnt);
    read_util = real'(r_cnt) * 100 / real'(cycle_cnt);
    write_util = real'(w_cnt) * 100 / real'(cycle_cnt);

    $display("[Monitor %s][Read] Latency: %0.2f +- %0.2f, BW: %0.2f Bits/cycle, Util: %0.2f%%", name, read_latency_mean, read_latency_stddev, read_bw, read_util);
    $display("[Monitor %s][Write] Latency: %0.2f +- %0.2f, BW: %0.2f Bits/cycle, Util: %0.2f%%", name, write_latency_mean, write_latency_stddev, write_bw, write_util);
  end

endmodule
