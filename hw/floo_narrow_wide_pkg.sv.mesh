// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead

`include "axi/typedef.svh"

package floo_narrow_wide_pkg;

  import floo_pkg::*;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

  typedef enum logic [3:0] {
    NarrowAw = 4'd0,
    NarrowW = 4'd1,
    NarrowAr = 4'd2,
    WideAr = 4'd3,
    NarrowB = 4'd4,
    NarrowR = 4'd5,
    WideB = 4'd6,
    WideAw = 4'd7,
    WideW = 4'd8,
    WideR = 4'd9,
    NumAxiChannels = 4'd10
  } axi_ch_e;


  localparam int unsigned AxiNarrowInAddrWidth = 48;
  localparam int unsigned AxiNarrowInDataWidth = 64;
  localparam int unsigned AxiNarrowInIdWidth = 4;
  localparam int unsigned AxiNarrowInUserWidth = 48;


  localparam int unsigned AxiNarrowOutAddrWidth = 48;
  localparam int unsigned AxiNarrowOutDataWidth = 64;
  localparam int unsigned AxiNarrowOutIdWidth = 2;
  localparam int unsigned AxiNarrowOutUserWidth = 48;


  localparam int unsigned AxiWideInAddrWidth = 48;
  localparam int unsigned AxiWideInDataWidth = 512;
  localparam int unsigned AxiWideInIdWidth = 3;
  localparam int unsigned AxiWideInUserWidth = 48;


  localparam int unsigned AxiWideOutAddrWidth = 48;
  localparam int unsigned AxiWideOutDataWidth = 512;
  localparam int unsigned AxiWideOutIdWidth = 1;
  localparam int unsigned AxiWideOutUserWidth = 48;


  typedef logic [47:0] axi_narrow_in_addr_t;
  typedef logic [63:0] axi_narrow_in_data_t;
  typedef logic [7:0] axi_narrow_in_strb_t;
  typedef logic [3:0] axi_narrow_in_id_t;
  typedef logic [47:0] axi_narrow_in_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_narrow_in, axi_narrow_in_req_t, axi_narrow_in_rsp_t, axi_narrow_in_addr_t,
                      axi_narrow_in_id_t, axi_narrow_in_data_t, axi_narrow_in_strb_t,
                      axi_narrow_in_user_t)


  typedef logic [47:0] axi_narrow_out_addr_t;
  typedef logic [63:0] axi_narrow_out_data_t;
  typedef logic [7:0] axi_narrow_out_strb_t;
  typedef logic [1:0] axi_narrow_out_id_t;
  typedef logic [47:0] axi_narrow_out_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_narrow_out, axi_narrow_out_req_t, axi_narrow_out_rsp_t,
                      axi_narrow_out_addr_t, axi_narrow_out_id_t, axi_narrow_out_data_t,
                      axi_narrow_out_strb_t, axi_narrow_out_user_t)


  typedef logic [47:0] axi_wide_in_addr_t;
  typedef logic [511:0] axi_wide_in_data_t;
  typedef logic [63:0] axi_wide_in_strb_t;
  typedef logic [2:0] axi_wide_in_id_t;
  typedef logic [47:0] axi_wide_in_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_wide_in, axi_wide_in_req_t, axi_wide_in_rsp_t, axi_wide_in_addr_t,
                      axi_wide_in_id_t, axi_wide_in_data_t, axi_wide_in_strb_t, axi_wide_in_user_t)


  typedef logic [47:0] axi_wide_out_addr_t;
  typedef logic [511:0] axi_wide_out_data_t;
  typedef logic [63:0] axi_wide_out_strb_t;
  typedef logic [0:0] axi_wide_out_id_t;
  typedef logic [47:0] axi_wide_out_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_wide_out, axi_wide_out_req_t, axi_wide_out_rsp_t, axi_wide_out_addr_t,
                      axi_wide_out_id_t, axi_wide_out_data_t, axi_wide_out_strb_t,
                      axi_wide_out_user_t)



  /////////////////////////
  //   Header Typedefs   //
  /////////////////////////

  localparam route_algo_e RouteAlgo = XYRouting;
  localparam bit UseIdTable = 1'b1;
  localparam int unsigned NumXBits = 2;
  localparam int unsigned NumXEP = 4; //
  localparam int unsigned NumYBits = 2;
  localparam int unsigned NumYEP = 4; //
  localparam int unsigned XYAddrOffsetX = 33;
  localparam int unsigned XYAddrOffsetY = 35;
  localparam int unsigned IdAddrOffset = 0;


  typedef logic [3:0] rob_idx_t;
  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  typedef struct packed {
    x_bits_t x;
    y_bits_t y;
  } id_t;

  typedef logic route_t;
  typedef id_t dst_t;

  /////////////////////
  //   Address Map   //
  /////////////////////

  localparam int unsigned SamNumRules = 16;

  typedef struct packed {
    id_t idx;
    logic [47:0] start_addr;
    logic [47:0] end_addr;
  } sam_rule_t;

  typedef struct packed {
    int idx;
    id_t coord;
    logic [47:0] addr;
    logic [47:0] mask;
  } mask_rule_t;

  typedef logic [SamNumRules-1:0] select_t;
  typedef logic [47:0] mask_t;

  typedef struct packed {
    logic mcast_flag;
    logic rob_req;
    rob_idx_t rob_idx;
    dst_t dst_id;
    select_t dst_mask_id;
    id_t src_id;
    logic last;
    logic atop;
    axi_ch_e axi_ch;
  } hdr_t;

  localparam sam_rule_t [SamNumRules-1:0] Sam = '{
      '{
          idx: '{x: 0, y: 0},
          start_addr: 48'h000010000000,
          end_addr: 48'h000020000000
      },  // cluster_ni_0_0
      '{
          idx: '{x: 0, y: 1},
          start_addr: 48'h000020000000,
          end_addr: 48'h000030000000
      },  // cluster_ni_0_1
      '{
          idx: '{x: 0, y: 2},
          start_addr: 48'h000030000000,
          end_addr: 48'h000040000000
      },  // cluster_ni_0_2
      '{
          idx: '{x: 0, y: 3},
          start_addr: 48'h000040000000,
          end_addr: 48'h000050000000
      },  // cluster_ni_0_3
      '{
          idx: '{x: 1, y: 0},
          start_addr: 48'h000050000000,
          end_addr: 48'h000060000000
      },  // cluster_ni_1_0
      '{
          idx: '{x: 1, y: 1},
          start_addr: 48'h000060000000,
          end_addr: 48'h000070000000
      },  // cluster_ni_1_1
      '{
          idx: '{x: 1, y: 2},
          start_addr: 48'h000070000000,
          end_addr: 48'h000080000000
      },  // cluster_ni_1_2
      '{
          idx: '{x: 1, y: 3},
          start_addr: 48'h000080000000,
          end_addr: 48'h000090000000
      },  // cluster_ni_1_3
      '{
          idx: '{x: 2, y: 0},
          start_addr: 48'h000090000000,
          end_addr: 48'h0000a0000000
      },  // cluster_ni_2_0
      '{
          idx: '{x: 2, y: 1},
          start_addr: 48'h0000a0000000,
          end_addr: 48'h0000b0000000
      },  // cluster_ni_2_1
      '{
          idx: '{x: 2, y: 2},
          start_addr: 48'h0000b0000000,
          end_addr: 48'h0000c0000000
      },  // cluster_ni_2_2
      '{
          idx: '{x: 2, y: 3},
          start_addr: 48'h0000c0000000,
          end_addr: 48'h0000d0000000
      },  // cluster_ni_2_3
      '{
          idx: '{x: 3, y: 0},
          start_addr: 48'h0000d0000000,
          end_addr: 48'h0000e0000000
      },  // cluster_ni_3_0
      '{
          idx: '{x: 3, y: 1},
          start_addr: 48'h0000e0000000,
          end_addr: 48'h0000f0000000
      },  // cluster_ni_3_1
      '{
          idx: '{x: 3, y: 2},
          start_addr: 48'h0000f0000000,
          end_addr: 48'h000100000000
      },  // cluster_ni_3_2
      '{
          idx: '{x: 3, y: 3},
          start_addr: 48'h000100000000,
          end_addr: 48'h000110000000
      }  // cluster_ni_3_3

  };

  // id_t [SamNumRules:0] id_lut = '{
  //   '{x: 0, y: 0}, // idle position
  //   '{x: 0, y: 1},
  //   '{x: 1, y: 0},
  //   '{x: 2, y: 1}, 
  //   '{x: 1, y: 2}
  // };

  localparam mask_rule_t [SamNumRules-1:0] SamMask = '{
      '{
          idx: 0,
          coord: '{x: 0, y: 0},
          addr: 48'h0000_1000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster0_ni_0_0
      '{
          idx: 1,
          coord: '{x: 0, y: 1},
          addr: 48'h0000_2000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_0_1
      '{
          idx: 2,
          coord: '{x: 0, y: 2},
          addr: 48'h0000_3000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_0_2
      '{
          idx: 3,
          coord: '{x: 0, y: 3},
          addr: 48'h0000_4000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_0_3
      '{
          idx: 4,
          coord: '{x: 1, y: 0},
          addr: 48'h0000_5000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_1_0
      '{
          idx: 5,
          coord: '{x: 1, y: 1},
          addr: 48'h0000_6000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_1_1
      '{
          idx: 6,
          coord: '{x: 1, y: 2},
          addr: 48'h0000_7000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_1_2
      '{
          idx: 7,
          coord: '{x: 1, y: 3},
          addr: 48'h0000_8000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_1_3
      '{
          idx: 8,
          coord: '{x: 2, y: 0},
          addr: 48'h0000_9000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_2_0
      '{
          idx: 9,
          coord: '{x: 2, y: 1},
          addr: 48'h0000_a000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_2_1
      '{
          idx: 10,
          coord: '{x: 2, y: 2},
          addr: 48'h0000_b000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_2_2
      '{
          idx: 11,
          coord: '{x: 2, y: 3},
          addr: 48'h0000_c000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_2_3
      '{
          idx: 12,
          coord: '{x: 3, y: 0},
          addr: 48'h0000_d000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_3_0
      '{
          idx: 13,
          coord: '{x: 3, y: 1},
          addr: 48'h0000_e000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_3_1
      '{
          idx: 14,
          coord: '{x: 3, y: 2},
          addr: 48'h0000_f000_0000,
          mask: 48'h0000_0fff_ffff
      },  // cluster_ni_3_2
      '{
          idx: 15,
          coord: '{x: 3, y: 3},
          addr: 48'h0001_0000_0000,
          mask: 48'h0000_0fff_ffff
      }  // cluster_ni_3_3

  };



  ////////////////////////
  //   Flits Typedefs   //
  ////////////////////////

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
    logic [490:0] rsvd;
  } floo_wide_aw_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_w_chan_t w;
  } floo_wide_w_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_b_chan_t b;
    logic [65:0] rsvd;
  } floo_wide_b_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_ar_chan_t ar;
    logic [6:0] rsvd;
  } floo_wide_ar_flit_t;

  typedef struct packed {
    hdr_t hdr;
    axi_wide_in_r_chan_t r;
    logic [58:0] rsvd;
  } floo_wide_r_flit_t;

  typedef struct packed {
    hdr_t hdr;
    logic [134:0] rsvd;
  } floo_req_generic_flit_t;

  typedef struct packed {
    hdr_t hdr;
    logic [118:0] rsvd;
  } floo_rsp_generic_flit_t;

  typedef struct packed {
    hdr_t hdr;
    logic [624:0] rsvd;
  } floo_wide_generic_flit_t;



  //////////////////////////
  //   Channel Typedefs   //
  //////////////////////////

  typedef union packed {
    floo_narrow_aw_flit_t narrow_aw;
    floo_narrow_w_flit_t narrow_w;
    floo_narrow_ar_flit_t narrow_ar;
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
    floo_wide_aw_flit_t wide_aw;
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
