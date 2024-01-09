// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead

`include "axi/typedef.svh"

package floo_axi_pkg;

  import floo_pkg::*;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

  typedef enum {
    AxiAw = 0,
    AxiW = 1,
    AxiAr = 2,
    AxiB = 3,
    AxiR = 4,
    NumAxiChannels = 5
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


  typedef logic [3:0] rob_idx_t;
  typedef logic [2:0] x_bits_t;
  typedef logic [2:0] y_bits_t;
  typedef struct packed {
    x_bits_t x;
    y_bits_t y;
  } id_t;



  typedef struct packed {
    logic rob_req;
    rob_idx_t rob_idx;
    id_t dst_id;
    id_t src_id;
    logic last;
    logic atop;
    axi_ch_e axi_ch;
  } hdr_t;



  /////////////////////
  //   Address Map   //
  /////////////////////

  typedef logic addr_map_rule_t;
  localparam int unsigned AddrMapNumIDs = 0;
  localparam int unsigned AddrMapNumRules = 0;
  localparam addr_map_rule_t AddrMap = '0;

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

  typedef struct packed {
    hdr_t hdr;
    logic [73:0] rsvd;
  } floo_req_generic_flit_t;

  typedef struct packed {
    hdr_t hdr;
    logic [70:0] rsvd;
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
    logic ready;
    floo_req_chan_t req;
  } floo_req_t;

  typedef struct packed {
    logic valid;
    logic ready;
    floo_rsp_chan_t rsp;
  } floo_rsp_t;


endpackage
