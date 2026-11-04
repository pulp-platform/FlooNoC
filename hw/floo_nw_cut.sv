// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"
`include "common_cells/assertions.svh"

/// Spill register cuts on a narrow-wide link, in both directions.
/// Side A and side B are the two endpoints of the link: `floo_*_a_i` is what A drives and
/// `floo_*_a_o` is what A receives. Each virtual channel gets its own spill register; with
/// `WideRwDecouple == Phys` the two wide virtual channels are two parallel paths.
/// `WideRwDecouple == Vc` (shared physical channel) needs `VcImpl == VcNaive`, see `floo_cut`.
module floo_nw_cut
  import floo_pkg::*;
#(
  /// Config of the narrow AXI interfaces (see axi_cfg_t for details)
  parameter axi_cfg_t          AxiCfgN        = '0,
  /// Config of the wide AXI interfaces (see axi_cfg_t for details)
  parameter axi_cfg_t          AxiCfgW        = '0,
  /// Number of spill register stages, 0 is a plain connection
  parameter int unsigned       NumCuts        = 1,
  /// Read and write decoupling of the wide channels, as in `floo_nw_router`
  parameter wide_rw_decouple_e WideRwDecouple = None,
  /// Virtual channel implementation, as in `floo_nw_router`
  parameter vc_impl_e          VcImpl         = VcNaive,
  /// Header type
  parameter type               hdr_t          = logic,
  /// Floo `req` link type
  parameter type               floo_req_t     = logic,
  /// Floo `rsp` link type
  parameter type               floo_rsp_t     = logic,
  /// Floo `wide` link type
  parameter type               floo_wide_t    = logic
) (
  input  logic       clk_i,
  input  logic       rst_ni,
  /// Side A of the link
  input  floo_req_t  floo_req_a_i,
  output floo_req_t  floo_req_a_o,
  input  floo_rsp_t  floo_rsp_a_i,
  output floo_rsp_t  floo_rsp_a_o,
  input  floo_wide_t floo_wide_a_i,
  output floo_wide_t floo_wide_a_o,
  /// Side B of the link
  input  floo_req_t  floo_req_b_i,
  output floo_req_t  floo_req_b_o,
  input  floo_rsp_t  floo_rsp_b_i,
  output floo_rsp_t  floo_rsp_b_o,
  input  floo_wide_t floo_wide_b_i,
  output floo_wide_t floo_wide_b_o
);

  localparam int unsigned NumWidePhysChannels = (WideRwDecouple == Phys) ? 2 : 1;
  localparam int unsigned NumWideVirtChannels = (WideRwDecouple == None) ? 1 : 2;

  typedef logic [AxiCfgN.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfgN.InIdWidth-1:0] axi_narrow_in_id_t;
  typedef logic [AxiCfgN.UserWidth-1:0] axi_narrow_user_t;
  typedef logic [AxiCfgN.DataWidth-1:0] axi_narrow_data_t;
  typedef logic [AxiCfgN.DataWidth/8-1:0] axi_narrow_strb_t;
  typedef logic [AxiCfgW.InIdWidth-1:0] axi_wide_in_id_t;
  typedef logic [AxiCfgW.UserWidth-1:0] axi_wide_user_t;
  typedef logic [AxiCfgW.DataWidth-1:0] axi_wide_data_t;
  typedef logic [AxiCfgW.DataWidth/8-1:0] axi_wide_strb_t;

  `AXI_TYPEDEF_ALL_CT(axi_narrow, axi_narrow_req_t, axi_narrow_rsp_t, axi_addr_t,
      axi_narrow_in_id_t, axi_narrow_data_t, axi_narrow_strb_t, axi_narrow_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide, axi_wide_req_t, axi_wide_rsp_t, axi_addr_t,
      axi_wide_in_id_t, axi_wide_data_t, axi_wide_strb_t, axi_wide_user_t)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow, axi_wide, AxiCfgN, AxiCfgW, hdr_t)

  // Index 0 is side A, index 1 is side B. Cut channel `d` carries the flits driven by side `d`.
  floo_req_t  [1:0] req_in,  req_out;
  floo_rsp_t  [1:0] rsp_in,  rsp_out;
  floo_wide_t [1:0] wide_in, wide_out;

  logic           [1:0] req_valid_in,  req_ready_in,  req_valid_out,  req_ready_out;
  logic           [1:0] rsp_valid_in,  rsp_ready_in,  rsp_valid_out,  rsp_ready_out;
  floo_req_chan_t [1:0] req_data_in,   req_data_out;
  floo_rsp_chan_t [1:0] rsp_data_in,   rsp_data_out;

  logic            [1:0][NumWideVirtChannels-1:0] wide_valid_in, wide_ready_in;
  logic            [1:0][NumWideVirtChannels-1:0] wide_valid_out, wide_ready_out;
  floo_wide_chan_t [1:0][NumWidePhysChannels-1:0] wide_data_in, wide_data_out;

  assign req_in  = {floo_req_b_i, floo_req_a_i};
  assign rsp_in  = {floo_rsp_b_i, floo_rsp_a_i};
  assign wide_in = {floo_wide_b_i, floo_wide_a_i};

  assign {floo_req_b_o, floo_req_a_o}   = req_out;
  assign {floo_rsp_b_o, floo_rsp_a_o}   = rsp_out;
  assign {floo_wide_b_o, floo_wide_a_o} = wide_out;

  // The ready of a direction travels in the link of the opposite direction
  for (genvar d = 0; d < 2; d++) begin : gen_dir
    assign req_valid_in[d]  = req_in[d].valid;
    assign req_data_in[d]   = req_in[d].req;
    assign req_ready_in[d]  = req_in[1-d].ready;
    assign rsp_valid_in[d]  = rsp_in[d].valid;
    assign rsp_data_in[d]   = rsp_in[d].rsp;
    assign rsp_ready_in[d]  = rsp_in[1-d].ready;
    assign wide_valid_in[d] = wide_in[d].valid;
    assign wide_data_in[d]  = wide_in[d].wide;
    assign wide_ready_in[d] = wide_in[1-d].ready;

    assign req_out[1-d].valid  = req_valid_out[d];
    assign req_out[1-d].req    = req_data_out[d];
    assign req_out[d].ready    = req_ready_out[d];
    assign rsp_out[1-d].valid  = rsp_valid_out[d];
    assign rsp_out[1-d].rsp    = rsp_data_out[d];
    assign rsp_out[d].ready    = rsp_ready_out[d];
    assign wide_out[1-d].valid = wide_valid_out[d];
    assign wide_out[1-d].wide  = wide_data_out[d];
    assign wide_out[d].ready   = wide_ready_out[d];
  end

  floo_cut #(
    .NumChannels    (2),
    .NumVirtChannels(1),
    .NumPhysChannels(1),
    .NumCuts        (NumCuts),
    .flit_t         (floo_req_chan_t)
  ) i_req_cut (
    .clk_i,
    .rst_ni,
    .valid_i(req_valid_in),
    .ready_o(req_ready_out),
    .data_i (req_data_in),
    .valid_o(req_valid_out),
    .ready_i(req_ready_in),
    .data_o (req_data_out)
  );

  floo_cut #(
    .NumChannels    (2),
    .NumVirtChannels(1),
    .NumPhysChannels(1),
    .NumCuts        (NumCuts),
    .flit_t         (floo_rsp_chan_t)
  ) i_rsp_cut (
    .clk_i,
    .rst_ni,
    .valid_i(rsp_valid_in),
    .ready_o(rsp_ready_out),
    .data_i (rsp_data_in),
    .valid_o(rsp_valid_out),
    .ready_i(rsp_ready_in),
    .data_o (rsp_data_out)
  );

  floo_cut #(
    .NumChannels    (2),
    .NumVirtChannels(NumWideVirtChannels),
    .NumPhysChannels(NumWidePhysChannels),
    .NumCuts        (NumCuts),
    .VcImpl         (VcImpl),
    .flit_t         (floo_wide_chan_t)
  ) i_wide_cut (
    .clk_i,
    .rst_ni,
    .valid_i(wide_valid_in),
    .ready_o(wide_ready_out),
    .data_i (wide_data_in),
    .valid_o(wide_valid_out),
    .ready_i(wide_ready_in),
    .data_o (wide_data_out)
  );

  ////////////////
  // Assertions //
  ////////////////

  // The credit field of the links is not carried through the cut. Wide virtual channels on a
  // shared physical channel are checked in `floo_cut`.
  `ASSERT_INIT(NoCreditVc, VcImpl != VcCredit,
      "floo_nw_cut: credit-based virtual channels are not supported")

endmodule
