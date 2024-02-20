// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A set of testbench utilities for the FlooNoC interface.
package floo_test;

  import floo_pkg::*;

  class floo_driver #(
    parameter time TA = 0ns,
    parameter time TT = 0ns,
    parameter type hdr_t = logic,
    localparam type payload_t = logic
  );
    virtual FLOO_LINK_DV intf;

    function new(virtual FLOO_LINK_DV intf);
      this.intf = intf;
    endfunction

    function void reset_mgr();
      intf.valid <= 1'b0;
      intf.hdr <= '0;
      intf.payload <= '0;
    endfunction

    function void reset_sbr();
      intf.ready <= 1'b0;
    endfunction

    task cycle_start();
      #TT;
    endtask

    task cycle_end();
      @(posedge intf.clk_i);
    endtask

    task send_payload (
      input hdr_t hdr,
      input payload_t req
    );
      intf.payload <= #TA req;
      intf.valid <= #TA 1'b1;
      cycle_start();
      while (intf.ready != 1'b1) begin cycle_end(); cycle_start(); end
      cycle_end();
      intf.payload <= #TA '0;
      intf.valid <= #TA 1'b0;
    endtask

    task recv_payload (
      output hdr_t hdr,
      output payload_t rsp
    );
      intf.ready <= 1'b1;
      cycle_start();
      while (intf.valid != 1'b1) begin cycle_end(); cycle_start(); end
      hdr = intf.hdr;
      rsp = intf.payload;
      cycle_end();
      intf.ready <= 1'b0;
    endtask

  endclass

  class floo_node #(
    parameter time TA = 0ns,
    parameter time TT = 0ns,
    parameter type hdr_t = logic,
    localparam type payload_t = logic
  );

    floo_driver #(
      .TA(TA),
      .TT(TT)
    ) drv;

    function new(virtual FLOO_LINK_DV intf);
      drv = new(intf);
      drv.reset_mgr();
      drv.reset_sbr();
    endfunction

  endclass

endpackage
