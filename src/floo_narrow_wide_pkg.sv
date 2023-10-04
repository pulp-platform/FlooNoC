// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead


`include "axi/typedef.svh"

package floo_narrow_wide_pkg;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

  localparam int unsigned NarrowInAddrWidth = 48;
  localparam int unsigned NarrowInDataWidth = 64;
  localparam int unsigned NarrowInIdWidth = 4;
  localparam int unsigned NarrowInUserWidth = 5;

  localparam int unsigned NarrowOutAddrWidth = 48;
  localparam int unsigned NarrowOutDataWidth = 64;
  localparam int unsigned NarrowOutIdWidth = 2;
  localparam int unsigned NarrowOutUserWidth = 5;

  localparam int unsigned WideInAddrWidth = 48;
  localparam int unsigned WideInDataWidth = 512;
  localparam int unsigned WideInIdWidth = 3;
  localparam int unsigned WideInUserWidth = 1;

  localparam int unsigned WideOutAddrWidth = 48;
  localparam int unsigned WideOutDataWidth = 512;
  localparam int unsigned WideOutIdWidth = 1;
  localparam int unsigned WideOutUserWidth = 1;

  typedef logic [NarrowInAddrWidth-1:0] axi_narrow_in_addr_t;
  typedef logic [NarrowInDataWidth-1:0] axi_narrow_in_data_t;
  typedef logic [NarrowInDataWidth/8-1:0] axi_narrow_in_strb_t;
  typedef logic [NarrowInIdWidth-1:0] axi_narrow_in_id_t;
  typedef logic [NarrowInUserWidth-1:0] axi_narrow_in_user_t;

  typedef logic [NarrowOutAddrWidth-1:0] axi_narrow_out_addr_t;
  typedef logic [NarrowOutDataWidth-1:0] axi_narrow_out_data_t;
  typedef logic [NarrowOutDataWidth/8-1:0] axi_narrow_out_strb_t;
  typedef logic [NarrowOutIdWidth-1:0] axi_narrow_out_id_t;
  typedef logic [NarrowOutUserWidth-1:0] axi_narrow_out_user_t;

  typedef logic [WideInAddrWidth-1:0] axi_wide_in_addr_t;
  typedef logic [WideInDataWidth-1:0] axi_wide_in_data_t;
  typedef logic [WideInDataWidth/8-1:0] axi_wide_in_strb_t;
  typedef logic [WideInIdWidth-1:0] axi_wide_in_id_t;
  typedef logic [WideInUserWidth-1:0] axi_wide_in_user_t;

  typedef logic [WideOutAddrWidth-1:0] axi_wide_out_addr_t;
  typedef logic [WideOutDataWidth-1:0] axi_wide_out_data_t;
  typedef logic [WideOutDataWidth/8-1:0] axi_wide_out_strb_t;
  typedef logic [WideOutIdWidth-1:0] axi_wide_out_id_t;
  typedef logic [WideOutUserWidth-1:0] axi_wide_out_user_t;

  `AXI_TYPEDEF_ALL_CT(axi_narrow_in, axi_narrow_in_req_t, axi_narrow_in_rsp_t, axi_narrow_in_addr_t,
                      axi_narrow_in_id_t, axi_narrow_in_data_t, axi_narrow_in_strb_t,
                      axi_narrow_in_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_narrow_out, axi_narrow_out_req_t, axi_narrow_out_rsp_t,
                      axi_narrow_out_addr_t, axi_narrow_out_id_t, axi_narrow_out_data_t,
                      axi_narrow_out_strb_t, axi_narrow_out_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide_in, axi_wide_in_req_t, axi_wide_in_rsp_t, axi_wide_in_addr_t,
                      axi_wide_in_id_t, axi_wide_in_data_t, axi_wide_in_strb_t, axi_wide_in_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide_out, axi_wide_out_req_t, axi_wide_out_rsp_t, axi_wide_out_addr_t,
                      axi_wide_out_id_t, axi_wide_out_data_t, axi_wide_out_strb_t,
                      axi_wide_out_user_t)

  /////////////////////////
  //   Header Typedefs   //
  /////////////////////////

  typedef logic [7:0] rob_idx_t;
  typedef logic [5:0] dst_id_t;
  typedef logic [5:0] src_id_t;
  typedef logic [3:0] axi_ch_t;

  typedef struct packed {
    logic rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    logic last;
    logic atop;
    axi_ch_t axi_ch;
  } hdr_t;


  ////////////////////////////
  //   AXI Flits Typedefs   //
  ////////////////////////////

  typedef struct packed {
    hdr_t hdr;
    axi_narrow_in_aw_chan_t aw;
  } floo_narrow_aw_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_narrow_in_w_chan_t w;
    logic [13:0] rsvd;
  } floo_narrow_w_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_narrow_in_b_chan_t b;
    logic [64:0] rsvd;
  } floo_narrow_b_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_narrow_in_ar_chan_t ar;
    logic [5:0] rsvd;
  } floo_narrow_ar_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_narrow_in_r_chan_t r;
  } floo_narrow_r_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_aw_chan_t aw;
    logic [4:0] rsvd;
  } floo_wide_aw_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_w_chan_t w;
  } floo_wide_w_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_b_chan_t b;
    logic [69:0] rsvd;
  } floo_wide_b_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_ar_chan_t ar;
    logic [10:0] rsvd;
  } floo_wide_ar_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_r_chan_t r;
    logic [58:0] rsvd;
  } floo_wide_r_flit_t;


  ////////////////////////////////
  //   Generic Flits Typedefs   //
  ////////////////////////////////

  typedef struct packed {
    hdr_t hdr;
    logic [91:0] rsvd;
  } floo_req_generic_flit_t;

  typedef struct packed {
    hdr_t hdr;
    logic [75:0] rsvd;
  } floo_rsp_generic_flit_t;

  typedef struct packed {
    hdr_t hdr;
    logic [577:0] rsvd;
  } floo_wide_generic_flit_t;


  //////////////////////////
  //   Channel Typedefs   //
  //////////////////////////

  typedef union packed {
    floo_narrow_aw_flit_t narrow_aw;
    floo_narrow_w_flit_t narrow_w;
    floo_narrow_ar_flit_t narrow_ar;
    floo_wide_aw_flit_t wide_aw;
    floo_wide_ar_flit_t wide_ar;
    floo_req_generic_flit_t generic;
  } floo_req_chan_t;

  typedef union packed {
    floo_narrow_b_flit_t narrow_b;
    floo_narrow_r_flit_t narrow_r;
    floo_wide_b_flit_t wide_b;
    floo_rsp_generic_flit_t generic;
  } floo_rsp_chan_t;

  typedef union packed {
    floo_wide_w_flit_t wide_w;
    floo_wide_r_flit_t wide_r;
    floo_wide_generic_flit_t generic;
  } floo_wide_chan_t;

  ///////////////////////
  //   Link Typedefs   //
  ///////////////////////

  typedef struct packed {
    logic valid;
    logic ready;
    floo_req_chan_t req;
  } floo_req_t;

  typedef struct packed {
    logic valid;
    logic ready;
    floo_rsp_chan_t rsp;
  } floo_rsp_t;

  typedef struct packed {
    logic valid;
    logic ready;
    floo_wide_chan_t wide;
  } floo_wide_t;

endpackage

