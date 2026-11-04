// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

/// Self-checking testbench of `floo_nw_cut`: random flits with random backpressure in both
/// directions on the req, rsp and wide channels. Every flit must arrive exactly once, in order,
/// on its own virtual channel. `WideMode` selects the wide link: 0 = `None` (1 virtual, 1 physical
/// channel), 1 = `Vc` (2 virtual channels on 1 shared physical channel, uses the arbiter of
/// `floo_cut`), 2 = `Phys` (2 virtual and 2 physical channels, two parallel paths).
module tb_floo_nw_cut;

  import floo_pkg::*;

  localparam time CyclTime = 10ns;
  localparam int unsigned NumFlits = 2000;
  localparam int unsigned NumCuts = 1;
  // Probability in percent that a source offers a flit / a sink accepts a flit
  localparam int unsigned ValidProb = 50;
  localparam int unsigned ReadyProb = 50;

  parameter int unsigned WideMode = 2;
  localparam wide_rw_decouple_e WideRwDecouple = wide_rw_decouple_e'(WideMode);
  localparam int unsigned NumWidePhys = (WideRwDecouple == Phys) ? 2 : 1;
  localparam int unsigned NumWideVirt = (WideRwDecouple == None) ? 1 : 2;
  // All virtual channels of the wide link share one data bus
  localparam bit SharedWideBus = (NumWideVirt != NumWidePhys);

  // Channels per direction: req, rsp, then one per wide virtual channel
  localparam int unsigned ChReq = 0;
  localparam int unsigned ChRsp = 1;
  localparam int unsigned ChWide = 2;
  localparam int unsigned NumChan = ChWide + NumWideVirt;

  logic clk, rst_n;

  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)
  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, floo_test_pkg::AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, floo_test_pkg::AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in,
      floo_test_pkg::AxiCfgN, floo_test_pkg::AxiCfgW, hdr_t)
  `FLOO_TYPEDEF_NW_VIRT_CHAN_LINK_ALL(req, rsp, wide, req, rsp, wide, NumWideVirt, NumWidePhys)

  // Index 0 is side A, index 1 is side B
  floo_req_t  [1:0] req_i,  req_o;
  floo_rsp_t  [1:0] rsp_i,  rsp_o;
  floo_wide_t [1:0] wide_i, wide_o;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  floo_nw_cut #(
    .AxiCfgN       ( floo_test_pkg::AxiCfgN ),
    .AxiCfgW       ( floo_test_pkg::AxiCfgW ),
    .NumCuts       ( NumCuts                ),
    .WideRwDecouple( WideRwDecouple         ),
    .VcImpl        ( VcNaive                ),
    .hdr_t         ( hdr_t                  ),
    .floo_req_t    ( floo_req_t             ),
    .floo_rsp_t    ( floo_rsp_t             ),
    .floo_wide_t   ( floo_wide_t            )
  ) i_dut (
    .clk_i        ( clk        ),
    .rst_ni       ( rst_n      ),
    .floo_req_a_i ( req_i[0]   ),
    .floo_req_a_o ( req_o[0]   ),
    .floo_rsp_a_i ( rsp_i[0]   ),
    .floo_rsp_a_o ( rsp_o[0]   ),
    .floo_wide_a_i( wide_i[0]  ),
    .floo_wide_a_o( wide_o[0]  ),
    .floo_req_b_i ( req_i[1]   ),
    .floo_req_b_o ( req_o[1]   ),
    .floo_rsp_b_i ( rsp_i[1]   ),
    .floo_rsp_b_o ( rsp_o[1]   ),
    .floo_wide_b_i( wide_i[1]  ),
    .floo_wide_b_o( wide_o[1]  )
  );

  // Expected flits per source side and channel, stored as the raw bits of the channel
  localparam int unsigned MaxBits = $bits(floo_wide_chan_t);
  typedef logic [MaxBits-1:0] bits_t;
  bits_t exp_q [2][NumChan][$];
  int unsigned num_sent [2][NumChan];
  int unsigned num_recv [2][NumChan];
  bit fired [2][NumChan];
  int unsigned num_err = 0;

  function automatic bit roll(int unsigned prob);
    return ($urandom_range(99) < prob);
  endfunction

  // Physical wide channel used by a channel index
  function automatic int unsigned wide_phys(int c);
    return (NumWidePhys == 1) ? 0 : c - ChWide;
  endfunction

  function automatic bit is_valid(int s, int c);
    case (c)
      ChReq:   return req_i[s].valid;
      ChRsp:   return rsp_i[s].valid;
      default: return wide_i[s].valid[c-ChWide];
    endcase
  endfunction

  function automatic void set_valid(int s, int c, bit val);
    case (c)
      ChReq:   req_i[s].valid = val;
      ChRsp:   rsp_i[s].valid = val;
      default: wide_i[s].valid[c-ChWide] = val;
    endcase
  endfunction

  // Ready seen by the source of side `s`
  function automatic bit src_ready(int s, int c);
    case (c)
      ChReq:   return req_o[s].ready;
      ChRsp:   return rsp_o[s].ready;
      default: return wide_o[s].ready[c-ChWide];
    endcase
  endfunction

  // Valid and ready of the sink of side `r`
  function automatic bit sink_valid(int r, int c);
    case (c)
      ChReq:   return req_o[r].valid;
      ChRsp:   return rsp_o[r].valid;
      default: return wide_o[r].valid[c-ChWide];
    endcase
  endfunction

  function automatic bit sink_ready(int r, int c);
    case (c)
      ChReq:   return req_i[r].ready;
      ChRsp:   return rsp_i[r].ready;
      default: return wide_i[r].ready[c-ChWide];
    endcase
  endfunction

  function automatic void set_ready(int r, int c, bit rdy);
    case (c)
      ChReq:   req_i[r].ready = rdy;
      ChRsp:   rsp_i[r].ready = rdy;
      default: wide_i[r].ready[c-ChWide] = rdy;
    endcase
  endfunction

  // Drive a random flit and remember it
  function automatic void offer(int s, int c);
    floo_req_chan_t  rq;
    floo_rsp_chan_t  rs;
    floo_wide_chan_t wd;
    void'(std::randomize(rq));
    void'(std::randomize(rs));
    void'(std::randomize(wd));
    case (c)
      ChReq: begin
        req_i[s].req = rq;
        exp_q[s][c].push_back(bits_t'(rq));
      end
      ChRsp: begin
        rsp_i[s].rsp = rs;
        exp_q[s][c].push_back(bits_t'(rs));
      end
      default: begin
        wide_i[s].wide[wide_phys(c)] = wd;
        exp_q[s][c].push_back(bits_t'(wd));
      end
    endcase
    set_valid(s, c, 1'b1);
  endfunction

  // Compare a flit received by side `1-s` with the oldest expected flit of source `s`
  function automatic void check(int s, int c);
    bits_t got, exp;
    case (c)
      ChReq:   got = bits_t'(req_o[1-s].req);
      ChRsp:   got = bits_t'(rsp_o[1-s].rsp);
      default: got = bits_t'(wide_o[1-s].wide[wide_phys(c)]);
    endcase
    if (exp_q[s][c].size() == 0) begin
      $error("Unexpected flit: side %0d -> %0d, channel %0d", s, 1-s, c);
      num_err++;
    end else begin
      exp = exp_q[s][c].pop_front();
      if (got !== exp) begin
        $error("Mismatch: side %0d -> %0d, channel %0d, flit %0d", s, 1-s, c, num_recv[s][c]);
        num_err++;
      end
    end
    num_recv[s][c]++;
  endfunction

  // Signals change 1 ns after the clock edge, a handshake is sampled at the falling edge.
  for (genvar s = 0; s < 2; s++) begin : gen_side
    // Source of side `s`. On a shared wide bus only one virtual channel may be valid at a time,
    // like the output of a router.
    initial begin
      bit bus_busy;
      for (int c = 0; c < NumChan; c++) begin
        fired[s][c] = 1'b0;
        num_sent[s][c] = 0;
        num_recv[s][c] = 0;
      end
      req_i[s].valid = 1'b0;
      rsp_i[s].valid = 1'b0;
      wide_i[s].valid = '0;
      wait (rst_n);
      forever begin
        @(posedge clk);
        #1ns;
        bus_busy = 1'b0;
        for (int c = 0; c < NumChan; c++) begin
          if (fired[s][c]) begin
            set_valid(s, c, 1'b0);
            fired[s][c] = 1'b0;
          end
          if (c >= ChWide && is_valid(s, c)) bus_busy = 1'b1;
        end
        for (int c = 0; c < NumChan; c++) begin
          if (!is_valid(s, c) && num_sent[s][c] < NumFlits && roll(ValidProb) &&
              !(SharedWideBus && c >= ChWide && bus_busy)) begin
            offer(s, c);
            num_sent[s][c]++;
            if (c >= ChWide) bus_busy = 1'b1;
          end
        end
      end
    end
    // Sink of side `s`, receives the flits of side `1-s`
    initial begin
      req_i[s].ready = 1'b0;
      rsp_i[s].ready = 1'b0;
      wide_i[s].ready = '0;
      forever begin
        @(posedge clk);
        #1ns;
        for (int c = 0; c < NumChan; c++) set_ready(s, c, roll(ReadyProb));
      end
    end
    always @(negedge clk) begin
      if (rst_n) begin
        for (int c = 0; c < NumChan; c++) begin
          if (is_valid(s, c) && src_ready(s, c)) fired[s][c] = 1'b1;
          if (sink_valid(s, c) && sink_ready(s, c)) check(1-s, c);
        end
        if (SharedWideBus && !$onehot0(wide_o[s].valid)) begin
          $error("More than one virtual channel valid on the shared wide bus of side %0d", s);
          num_err++;
        end
      end
    end
  end

  // End of test
  initial begin
    bit done;
    wait (rst_n);
    done = 1'b0;
    while (!done) begin
      @(posedge clk);
      done = 1'b1;
      for (int s = 0; s < 2; s++)
        for (int c = 0; c < NumChan; c++)
          if (num_recv[s][c] < NumFlits) done = 1'b0;
    end
    repeat (20) @(posedge clk);
    for (int s = 0; s < 2; s++)
      for (int c = 0; c < NumChan; c++)
        if (num_recv[s][c] != NumFlits || exp_q[s][c].size() != 0) begin
          $error("Channel %0d of side %0d: %0d of %0d flits received", c, s, num_recv[s][c],
                 NumFlits);
          num_err++;
        end
    if (num_err == 0) begin
      $display("tb_floo_nw_cut: PASSED (WideMode %0d, %0d flits per channel and direction)",
               WideMode, NumFlits);
    end else begin
      $fatal(1, "tb_floo_nw_cut: FAILED with %0d errors", num_err);
    end
    $finish;
  end

  // Timeout
  initial begin
    #(CyclTime * NumFlits * 200);
    $fatal(1, "tb_floo_nw_cut: timeout");
  end

endmodule
