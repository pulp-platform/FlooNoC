// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

/// Self-checking testbench of `floo_nw_cut`: random flits with random backpressure in both
/// directions on the req, rsp and both wide virtual channels (2 virtual and 2 physical channels).
/// Every flit must arrive exactly once, in order, on its own channel.
module tb_floo_nw_cut;

  import floo_pkg::*;

  localparam time CyclTime = 10ns;
  localparam int unsigned NumFlits = 2000;
  localparam int unsigned NumCuts = 1;
  // Probability in percent that a source offers a flit / a sink accepts a flit
  localparam int unsigned ValidProb = 50;
  localparam int unsigned ReadyProb = 50;

  // Four channels per direction: req, rsp, wide VC0, wide VC1
  localparam int unsigned NumChan = 4;
  localparam int unsigned ChReq = 0;
  localparam int unsigned ChRsp = 1;
  localparam int unsigned ChWide0 = 2;
  localparam int unsigned ChWide1 = 3;

  logic clk, rst_n;

  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)
  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, floo_test_pkg::AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, floo_test_pkg::AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in,
      floo_test_pkg::AxiCfgN, floo_test_pkg::AxiCfgW, hdr_t)
  `FLOO_TYPEDEF_NW_VIRT_CHAN_LINK_ALL(req, rsp, wide, req, rsp, wide, 2, 2)

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
    .WideRwDecouple( Phys                   ),
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
  int unsigned num_err = 0;

  function automatic bit roll(int unsigned prob);
    return ($urandom_range(99) < prob);
  endfunction

  // Source `s` offers flits that are received by side `1-s`. Signals change 1 ns after the clock
  // edge, a handshake is sampled at the falling edge.
  for (genvar s = 0; s < 2; s++) begin : gen_side
    for (genvar c = 0; c < NumChan; c++) begin : gen_chan
      bit fired;
      // Source
      initial begin
        fired = 1'b0;
        num_sent[s][c] = 0;
        num_recv[s][c] = 0;
        case (c)
          ChReq:   req_i[s].valid = 1'b0;
          ChRsp:   rsp_i[s].valid = 1'b0;
          ChWide0: wide_i[s].valid[0] = 1'b0;
          ChWide1: wide_i[s].valid[1] = 1'b0;
        endcase
        wait (rst_n);
        forever begin
          @(posedge clk);
          #1ns;
          if (fired) begin
            case (c)
              ChReq:   req_i[s].valid = 1'b0;
              ChRsp:   rsp_i[s].valid = 1'b0;
              ChWide0: wide_i[s].valid[0] = 1'b0;
              ChWide1: wide_i[s].valid[1] = 1'b0;
            endcase
            fired = 1'b0;
          end
          if (!is_valid(s, c) && num_sent[s][c] < NumFlits && roll(ValidProb)) begin
            offer(s, c);
            num_sent[s][c]++;
          end
        end
      end
      // Handshake sampling of the source
      always @(negedge clk) begin
        if (rst_n && is_valid(s, c) && src_ready(s, c)) fired = 1'b1;
      end
      // Sink: side `1-s` accepts, driven through the ready of its own link
      initial begin
        req_i[1-s].ready = 1'b0;
        rsp_i[1-s].ready = 1'b0;
        wide_i[1-s].ready = '0;
        forever begin
          @(posedge clk);
          #1ns;
          set_ready(1-s, c, roll(ReadyProb));
        end
      end
      always @(negedge clk) begin
        if (rst_n && sink_valid(1-s, c) && sink_ready(1-s, c)) check(s, c);
      end
    end
  end

  function automatic bit is_valid(int s, int c);
    case (c)
      ChReq:   return req_i[s].valid;
      ChRsp:   return rsp_i[s].valid;
      ChWide0: return wide_i[s].valid[0];
      default: return wide_i[s].valid[1];
    endcase
  endfunction

  function automatic bit src_ready(int s, int c);
    case (c)
      ChReq:   return req_o[s].ready;
      ChRsp:   return rsp_o[s].ready;
      ChWide0: return wide_o[s].ready[0];
      default: return wide_o[s].ready[1];
    endcase
  endfunction

  function automatic bit sink_valid(int r, int c);
    case (c)
      ChReq:   return req_o[r].valid;
      ChRsp:   return rsp_o[r].valid;
      ChWide0: return wide_o[r].valid[0];
      default: return wide_o[r].valid[1];
    endcase
  endfunction

  function automatic bit sink_ready(int r, int c);
    case (c)
      ChReq:   return req_i[r].ready;
      ChRsp:   return rsp_i[r].ready;
      ChWide0: return wide_i[r].ready[0];
      default: return wide_i[r].ready[1];
    endcase
  endfunction

  function automatic void set_ready(int r, int c, bit rdy);
    case (c)
      ChReq:   req_i[r].ready = rdy;
      ChRsp:   rsp_i[r].ready = rdy;
      ChWide0: wide_i[r].ready[0] = rdy;
      default: wide_i[r].ready[1] = rdy;
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
        req_i[s].valid = 1'b1;
        exp_q[s][c].push_back(bits_t'(rq));
      end
      ChRsp: begin
        rsp_i[s].rsp = rs;
        rsp_i[s].valid = 1'b1;
        exp_q[s][c].push_back(bits_t'(rs));
      end
      ChWide0: begin
        wide_i[s].wide[0] = wd;
        wide_i[s].valid[0] = 1'b1;
        exp_q[s][c].push_back(bits_t'(wd));
      end
      default: begin
        wide_i[s].wide[1] = wd;
        wide_i[s].valid[1] = 1'b1;
        exp_q[s][c].push_back(bits_t'(wd));
      end
    endcase
  endfunction

  // Compare a received flit with the oldest expected flit of the same source and channel
  function automatic void check(int s, int c);
    bits_t got, exp;
    case (c)
      ChReq:   got = bits_t'(req_o[1-s].req);
      ChRsp:   got = bits_t'(rsp_o[1-s].rsp);
      ChWide0: got = bits_t'(wide_o[1-s].wide[0]);
      default: got = bits_t'(wide_o[1-s].wide[1]);
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
    if (num_err == 0) $display("tb_floo_nw_cut: PASSED (%0d flits per channel and direction)", NumFlits);
    else $fatal(1, "tb_floo_nw_cut: FAILED with %0d errors", num_err);
    $finish;
  end

  // Timeout
  initial begin
    #(CyclTime * NumFlits * 200);
    $fatal(1, "tb_floo_nw_cut: timeout");
  end

endmodule
