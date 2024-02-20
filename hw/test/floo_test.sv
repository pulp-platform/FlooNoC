// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A set of testbench utilities for the FlooNoC interface.
package floo_test;

  import floo_pkg::*;
  import floo_axi_pkg::*;

  class floo_driver #(
    parameter time TA = 0ns,
    parameter time TT = 0ns
  );
    virtual FLOO_LINK_DV intf;

    function new(virtual FLOO_LINK_DV intf);
      this.intf = intf;
    endfunction

    function void reset_mgr();
      intf.floo_req_mgr <= '0;
      intf.floo_rsp_mgr <= '0;
    endfunction

    function void reset_sbr();
      intf.floo_req_sbr <= '0;
      intf.floo_rsp_sbr <= '0;
    endfunction

    task cycle_start();
      #TT;
    endtask

    task cycle_end();
      @(posedge intf.clk_i);
    endtask

    task send_req (
      input floo_req_generic_flit_t req
    );
      intf.floo_req_mgr.req <= #TA req;
      intf.floo_req_mgr.valid <= #TA 1'b1;
      cycle_start();
      while (intf.floo_req_sbr.ready != 1'b1) begin cycle_end(); cycle_start(); end
      cycle_end();
      intf.floo_req_mgr.req <= #TA '0;
      intf.floo_req_mgr.valid <= #TA 1'b0;
    endtask

    task send_rsp (
      input floo_rsp_generic_flit_t rsp
    );
      intf.floo_rsp_sbr.rsp <= #TA rsp;
      intf.floo_rsp_sbr.valid <= #TA 1'b1;
      cycle_start();
      while (intf.floo_rsp_mgr.ready != 1'b1) begin cycle_end(); cycle_start(); end
      cycle_end();
      intf.floo_rsp_sbr.rsp <= #TA '0;
      intf.floo_rsp_sbr.valid <= #TA 1'b0;
    endtask

    task recv_req (
      output floo_req_generic_flit_t req
    );
      intf.floo_req_sbr.ready <= #TA 1'b1;
      cycle_start();
      while (intf.floo_req_mgr.valid != 1'b1) begin cycle_end(); cycle_start(); end
      // TODO: create new req? i.e. do we need to define it as a class?
      req = intf.floo_req_mgr.req;
      cycle_end();
      intf.floo_req_mgr.ready <= #TA 1'b0;
    endtask

    task recv_rsp (
      output floo_rsp_generic_flit_t rsp
    );
      intf.floo_rsp_mgr.ready <= #TA 1'b1;
      cycle_start();
      while (intf.floo_rsp_sbr.valid != 1'b1) begin cycle_end(); cycle_start(); end
      rsp = intf.floo_rsp_sbr.rsp;
      cycle_end();
      intf.floo_rsp_sbr.ready <= #TA 1'b0;
    endtask

  endclass

  class floo_node #(
    parameter time TA = 0ns,
    parameter time TT = 0ns,
    parameter id_t SrcId = '0,
    parameter route_algo_e RouteAlgo = XYRouting,
    parameter int MaxId = 0
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

    function floo_req_generic_flit_t new_rand_req();
      automatic logic rand_success;
      automatic hdr_t hdr;
      automatic floo_req_generic_flit_t req;
      automatic id_t dst_id;

      dst_id = id_t'($urandom_range(0, MaxId));
    endfunction

  endclass


endpackage
