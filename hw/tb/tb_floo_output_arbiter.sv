// Copyright 2026 Fondazione Chips-IT.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

/// Checks that `floo_output_arbiter` keeps a packet together when parallel reductions are
/// enabled. A parallel reduction sends its AW from the local port, and its W follows some cycles
/// later. Meanwhile, a unicast read from the North port waits for the same output. The read must
/// not leave between the AW and the W: the next router locks its route on the AW, and would send
/// the read to the AW's port.
module tb_floo_output_arbiter;

  import floo_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam int unsigned NumRoutes = 5;
  // Cycles between the AW of the reduction and its W
  localparam int unsigned WDelay = 2;

  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  typedef logic [$bits(collect_reserved_op_e)-1:0] collect_op_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)
  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, axi_ch_e, logic, id_t, collect_op_t)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi, floo_test_pkg::AxiCfg)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, floo_test_pkg::AxiCfg, hdr_t)

  typedef floo_req_generic_flit_t flit_t;

  localparam collect_op_be_cfg_t CollectOpCfg = '{
    EnLsbAnd:   1'b1,
    EnSelectAW: 1'b1,
    default:    1'b0
  };

  // The router of this output is at (1,1). The reduction starts here, with no other member
  // (empty mask), and goes South to (1,0); the read comes from (1,2) and also goes to (1,0).
  localparam id_t XyId  = '{x: 1, y: 1, port_id: 0};
  localparam id_t DstId = '{x: 1, y: 0, port_id: 0};
  localparam id_t RdSrc = '{x: 1, y: 2, port_id: 0};

  logic clk, rst_n;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  logic  [NumRoutes-1:0] valid_in, ready_in;
  flit_t [NumRoutes-1:0] data_in;
  logic                  valid_out;
  flit_t                 data_out;

  floo_output_arbiter #(
    .NumRoutes            ( NumRoutes    ),
    .NumParallelRedRoutes ( NumRoutes    ),
    .CollectOpCfg         ( CollectOpCfg ),
    .RouteAlgo            ( XYRouting    ),
    .flit_t               ( flit_t       ),
    .hdr_t                ( hdr_t        ),
    .id_t                 ( id_t         ),
    .collect_op_t         ( collect_op_t ),
    .AxiCfg               ( floo_test_pkg::AxiCfg )
  ) i_dut (
    .clk_i   ( clk       ),
    .rst_ni  ( rst_n     ),
    .xy_id_i ( XyId      ),
    .valid_i ( valid_in  ),
    .ready_o ( ready_in  ),
    .data_i  ( data_in   ),
    .valid_o ( valid_out ),
    .ready_i ( 1'b1      ),
    .data_o  ( data_out  )
  );

  function automatic flit_t make_flit(id_t src, axi_ch_e ch, collect_op_t op, logic last);
    flit_t f = '0;
    f.hdr.src_id        = src;
    f.hdr.dst_id        = DstId;
    f.hdr.collective_op = op;
    f.hdr.axi_ch        = ch;
    f.hdr.last          = last;
    // The W of a LsbAnd reduction carries its bit in the data's LSB
    if (ch == AxiW) f.payload[0] = 1'b1;
    return f;
  endfunction

  // Sends one flit on an input, and waits for its handshake
  task automatic send(int unsigned port, flit_t f);
    #ApplTime;
    data_in[port]  = f;
    valid_in[port] = 1'b1;
    do @(posedge clk); while (!ready_in[port]);
    #ApplTime;
    valid_in[port] = 1'b0;
    data_in[port]  = '0;
  endtask

  initial begin
    valid_in = '0;
    data_in  = '0;
    wait (rst_n);
    @(posedge clk);
    fork
      begin
        send(Eject, make_flit(XyId, AxiAw, collect_op_t'(SelectAW), 1'b0));
        repeat (WDelay - 1) @(posedge clk);
        send(Eject, make_flit(XyId, AxiW, collect_op_t'(LsbAnd), 1'b1));
      end
      send(North, make_flit(RdSrc, AxiAr, collect_op_t'(Unicast), 1'b1));
    join
  end

  // Every flit after one with `last = 0` must belong to the same packet
  flit_t first;
  logic  open;
  int unsigned num_out, num_split;

  initial begin
    open      = 1'b0;
    num_out   = 0;
    num_split = 0;
    wait (rst_n);
    while (num_out < 3) begin
      @(posedge clk);
      if (valid_out) begin
        $display("[%0t] out: src=(%0d,%0d) dst=(%0d,%0d) ch=%s last=%0b", $time,
                 data_out.hdr.src_id.x, data_out.hdr.src_id.y, data_out.hdr.dst_id.x,
                 data_out.hdr.dst_id.y, data_out.hdr.axi_ch.name(), data_out.hdr.last);
        if (open && data_out.hdr.src_id != first.hdr.src_id) begin
          $error("A flit from (%0d,%0d) left inside the packet from (%0d,%0d)",
                 data_out.hdr.src_id.x, data_out.hdr.src_id.y,
                 first.hdr.src_id.x, first.hdr.src_id.y);
          num_split++;
        end
        if (!open) first = data_out;
        open = !data_out.hdr.last;
        num_out++;
      end
    end
    if (num_split == 0) $display("[PASS] the packet of the reduction left whole");
    else $fatal(1, "[FAIL] %0d flit(s) left inside an open packet", num_split);
    $finish;
  end

  initial begin
    #(100 * CyclTime);
    $fatal(1, "[FAIL] timeout: %0d of 3 flits left the output", num_out);
  end

endmodule
