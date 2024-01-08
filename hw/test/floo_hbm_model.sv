// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/assign.svh"

/// A very simple model of the HBM memory controller with configurable delay
module floo_hbm_model #(
  parameter time         TA           = 1ns,
  parameter time         TT           = 9ns,
  parameter int unsigned Latency      = 100,
  parameter int unsigned NumChannels  = 1,
  parameter int unsigned AddrWidth    = 32,
  parameter int unsigned DataWidth    = 32,
  parameter int unsigned UserWidth    = 1,
  parameter int unsigned IdWidth      = 2,
  parameter type axi_req_t            = logic,
  parameter type axi_rsp_t            = logic,
  parameter type aw_chan_t            = logic,
  parameter type w_chan_t             = logic,
  parameter type b_chan_t             = logic,
  parameter type ar_chan_t            = logic,
  parameter type r_chan_t             = logic
) (
  input logic clk_i,
  input logic rst_ni,
  input axi_req_t [NumChannels-1:0] hbm_req_i,
  output axi_rsp_t [NumChannels-1:0] hbm_rsp_o
);

  // AXI multicut
  axi_req_t [NumChannels-1:0] hbm_req;
  axi_rsp_t [NumChannels-1:0] hbm_rsp;

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AddrWidth   ),
    .AXI_DATA_WIDTH ( DataWidth   ),
    .AXI_ID_WIDTH   ( IdWidth     ),
    .AXI_USER_WIDTH ( UserWidth   )
  ) slave_dv [NumChannels] (clk_i);

  typedef axi_test::axi_rand_slave #(
    // AXI interface parameters
    .AW ( AddrWidth ),
    .DW ( DataWidth ),
    .IW ( IdWidth   ),
    .UW ( UserWidth ),
    // Stimuli application and test time
    .TA ( TA  ),
    .TT ( TT  ),
    // Responsiv,eness
    .AX_MIN_WAIT_CYCLES   (0),
    .AX_MAX_WAIT_CYCLES   (0),
    .R_MIN_WAIT_CYCLES    (0),
    .R_MAX_WAIT_CYCLES    (0),
    .RESP_MIN_WAIT_CYCLES (0),
    .RESP_MAX_WAIT_CYCLES (0)
  ) axi_rand_slave_t;

  axi_rand_slave_t axi_rand_slave [NumChannels];

  for (genvar i = 0; i < NumChannels; i++) begin : gen_assign_slvs
    `AXI_ASSIGN_FROM_REQ(slave_dv[i], hbm_req[i])
    `AXI_ASSIGN_TO_RESP(hbm_rsp[i], slave_dv[i])
  end


  for (genvar i = 0; i < NumChannels; i++) begin : gen_channels
    axi_multicut #(
      .NoCuts     ( Latency/2 ),
      .aw_chan_t  ( aw_chan_t ),
      .w_chan_t   ( w_chan_t  ),
      .b_chan_t   ( b_chan_t  ),
      .ar_chan_t  ( ar_chan_t ),
      .r_chan_t   ( r_chan_t  ),
      .axi_req_t  ( axi_req_t ),
      .axi_resp_t ( axi_rsp_t )
    ) i_axi_multicut (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .mst_req_o (hbm_req[i]),
      .mst_resp_i(hbm_rsp[i]),
      .slv_req_i (hbm_req_i[i]),
      .slv_resp_o(hbm_rsp_o[i])
    );
  end

  for (genvar i = 0; i < NumChannels; i++) begin : gen_rand_slaves
    initial begin
      axi_rand_slave[i] = new( slave_dv[i] );
      axi_rand_slave[i].reset();
      @(posedge rst_ni)
      axi_rand_slave[i].run();
    end
  end

endmodule
