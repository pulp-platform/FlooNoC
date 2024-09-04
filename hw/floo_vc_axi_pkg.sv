// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead

`include "axi/typedef.svh"

package floo_vc_axi_pkg;

  import floo_pkg::*;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

  typedef enum logic [2:0] {
    AxiAw = 3'd0,
    AxiW = 3'd1,
    AxiAr = 3'd2,
    AxiB = 3'd3,
    AxiR = 3'd4,
    NumAxiChannels = 3'd5
  } axi_ch_e;


  localparam int unsigned AxiInAddrWidth = 32;
  localparam int unsigned AxiInDataWidth = 64;
  localparam int unsigned AxiInIdWidth = 3;
  localparam int unsigned AxiInUserWidth = 1;


  localparam int unsigned AxiOutAddrWidth = 32;
  localparam int unsigned AxiOutDataWidth = 64;
  localparam int unsigned AxiOutIdWidth = 3;
  localparam int unsigned AxiOutUserWidth = 1;


  typedef logic [31:0] axi_in_addr_t;
  typedef logic [63:0] axi_in_data_t;
  typedef logic [7:0] axi_in_strb_t;
  typedef logic [2:0] axi_in_id_t;
  typedef logic [0:0] axi_in_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_in, axi_in_req_t, axi_in_rsp_t, axi_in_addr_t, axi_in_id_t, axi_in_data_t,
                      axi_in_strb_t, axi_in_user_t)


  typedef logic [31:0] axi_out_addr_t;
  typedef logic [63:0] axi_out_data_t;
  typedef logic [7:0] axi_out_strb_t;
  typedef logic [2:0] axi_out_id_t;
  typedef logic [0:0] axi_out_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_out, axi_out_req_t, axi_out_rsp_t, axi_out_addr_t, axi_out_id_t,
                      axi_out_data_t, axi_out_strb_t, axi_out_user_t)



  /////////////////////////
  //   Header Typedefs   //
  /////////////////////////

  localparam route_algo_e RouteAlgo = XYRouting;
  localparam bit UseIdTable = 1'b0;
  localparam int unsigned NumXBits = 3;
  localparam int unsigned NumYBits = 3;
  localparam int unsigned XYAddrOffsetX = 16;
  localparam int unsigned XYAddrOffsetY = 19;
  localparam int unsigned IdAddrOffset = 0;


  typedef logic [0:0] rob_idx_t;
  typedef logic [1:0] port_id_t;
  typedef logic [2:0] x_bits_t;
  typedef logic [2:0] y_bits_t;
  typedef struct packed {
    x_bits_t  x;
    y_bits_t  y;
    port_id_t port_id;
  } id_t;

  typedef logic route_t;
  typedef id_t dst_t;
  typedef logic [2:0] vc_id_t;


  typedef struct packed {
    logic rob_req;
    rob_idx_t rob_idx;
    dst_t dst_id;
    id_t src_id;
    logic last;
    logic atop;
    axi_ch_e axi_ch;
    vc_id_t vc_id;
    route_direction_e lookahead;
  } hdr_t;



  ////////////////////////
  //   Flits Typedefs   //
  ////////////////////////

  typedef struct packed {
    hdr_t hdr;
    axi_in_aw_chan_t aw;
    logic [2:0] rsvd;
  } floo_axi_aw_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_in_w_chan_t w;
  } floo_axi_w_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_in_b_chan_t b;
    logic [64:0] rsvd;
  } floo_axi_b_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_in_ar_chan_t ar;
    logic [8:0] rsvd;
  } floo_axi_ar_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_in_r_chan_t r;
  } floo_axi_r_flit_t;

  typedef logic [73:0] floo_req_payload_t;
  typedef struct packed {
    hdr_t hdr;
    floo_req_payload_t payload;
  } floo_req_generic_flit_t;

  typedef logic [70:0] floo_rsp_payload_t;
  typedef struct packed {
    hdr_t hdr;
    floo_rsp_payload_t payload;
  } floo_rsp_generic_flit_t;



  //////////////////////////
  //   Channel Typedefs   //
  //////////////////////////

  typedef union packed {
    floo_axi_aw_flit_t axi_aw;
    floo_axi_w_flit_t axi_w;
    floo_axi_ar_flit_t axi_ar;
    floo_req_generic_flit_t generic;
  } floo_req_chan_t;

  typedef union packed {
    floo_axi_b_flit_t axi_b;
    floo_axi_r_flit_t axi_r;
    floo_rsp_generic_flit_t generic;
  } floo_rsp_chan_t;



  ///////////////////////
  //   Link Typedefs   //
  ///////////////////////

  typedef struct packed {
    logic valid;
    logic credit_v;
    vc_id_t credit_id;
    floo_req_chan_t req;
  } floo_vc_req_t;

  typedef struct packed {
    logic valid;
    logic credit_v;
    vc_id_t credit_id;
    floo_rsp_chan_t rsp;
  } floo_vc_rsp_t;


endpackage
