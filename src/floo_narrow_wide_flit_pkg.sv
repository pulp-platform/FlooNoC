// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead

     
`include "axi/typedef.svh"

package floo_narrow_wide_flit_pkg;

  localparam int unsigned NumPhysChannels = 3;
  localparam int unsigned NumAxiChannels = 10;

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


  typedef logic [47:0] narrow_in_addr_t;
  typedef logic [63:0] narrow_in_data_t;
  typedef logic [7:0] narrow_in_strb_t;
  typedef logic [3:0] narrow_in_id_t;
  typedef logic [4:0] narrow_in_user_t;

  typedef logic [47:0] narrow_out_addr_t;
  typedef logic [63:0] narrow_out_data_t;
  typedef logic [7:0] narrow_out_strb_t;
  typedef logic [1:0] narrow_out_id_t;
  typedef logic [4:0] narrow_out_user_t;

  typedef logic [47:0] wide_in_addr_t;
  typedef logic [511:0] wide_in_data_t;
  typedef logic [63:0] wide_in_strb_t;
  typedef logic [2:0] wide_in_id_t;
  typedef logic [0:0] wide_in_user_t;

  typedef logic [47:0] wide_out_addr_t;
  typedef logic [511:0] wide_out_data_t;
  typedef logic [63:0] wide_out_strb_t;
  typedef logic [0:0] wide_out_id_t;
  typedef logic [0:0] wide_out_user_t;


  `AXI_TYPEDEF_ALL(narrow_in, narrow_in_addr_t, narrow_in_id_t, narrow_in_data_t, narrow_in_strb_t, narrow_in_user_t)
  `AXI_TYPEDEF_ALL(narrow_out, narrow_out_addr_t, narrow_out_id_t, narrow_out_data_t, narrow_out_strb_t, narrow_out_user_t)
  `AXI_TYPEDEF_ALL(wide_in, wide_in_addr_t, wide_in_id_t, wide_in_data_t, wide_in_strb_t, wide_in_user_t)
  `AXI_TYPEDEF_ALL(wide_out, wide_out_addr_t, wide_out_id_t, wide_out_data_t, wide_out_strb_t, wide_out_user_t)

  //////////////////////
  //   AXI Channels   //
  //////////////////////

  typedef enum logic[3:0] {
    NarrowInAw,
    NarrowInW,
    NarrowInAr,
    WideInAr,
    WideInAw,
    NarrowInB,
    NarrowInR,
    WideInB,
    WideInW,
    WideInR
  } axi_ch_e;

  ///////////////////////////
  //   Physical Channels   //
  ///////////////////////////

  typedef enum int {
    PhysNarrowReq,
    PhysNarrowRsp,
    PhysWide
  } phys_chan_e;

  /////////////////////////
  //   Channel Mapping   //
  /////////////////////////

  localparam int NumVirtPerPhys[NumPhysChannels] = '{5, 3, 2};

  localparam int PhysChanMapping[NumAxiChannels] = '{
    PhysNarrowReq,
    PhysNarrowReq,
    PhysNarrowReq,
    PhysNarrowReq,
    PhysNarrowReq,
    PhysNarrowRsp,
    PhysNarrowRsp,
    PhysNarrowRsp,
    PhysWide,
    PhysWide
  };

  localparam int VirtChanMapping[NumPhysChannels][5] = '{
    '{NarrowInAw, NarrowInW, NarrowInAr, WideInAr, WideInAw},
    '{NarrowInB, NarrowInR, WideInB, 0, 0},
    '{WideInW, WideInR, 0, 0, 0}
  };

  ///////////////////////
  //   Meta Typedefs   //
  ///////////////////////

  typedef logic [0:0] rob_req_t;
  typedef logic [7:0] rob_idx_t;
  typedef logic [5:0] dst_id_t;
  typedef logic [5:0] src_id_t;
  typedef logic [0:0] last_t;
  typedef logic [0:0] atop_t;
  typedef logic [3:0] axi_ch_t;

  ////////////////////////////
  //   AXI Packet Structs   //
  ////////////////////////////

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    narrow_in_aw_chan_t aw;
  } narrow_in_aw_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    narrow_in_w_chan_t w;
    logic [13:0] rsvd;
  } narrow_in_w_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    narrow_in_ar_chan_t ar;
    logic [5:0] rsvd;
  } narrow_in_ar_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    wide_in_ar_chan_t ar;
    logic [10:0] rsvd;
  } wide_in_ar_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    wide_in_aw_chan_t aw;
    logic [4:0] rsvd;
  } wide_in_aw_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    logic [91:0] rsvd;
  } narrow_req_generic_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    narrow_in_b_chan_t b;
    logic [64:0] rsvd;
  } narrow_in_b_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    narrow_in_r_chan_t r;
  } narrow_in_r_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    wide_in_b_chan_t b;
    logic [69:0] rsvd;
  } wide_in_b_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    logic [75:0] rsvd;
  } narrow_rsp_generic_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    wide_in_w_chan_t w;
  } wide_in_w_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    wide_in_r_chan_t r;
    logic [58:0] rsvd;
  } wide_in_r_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    logic [577:0] rsvd;
  } wide_generic_t;



  ///////////////////////////
  //   AXI Packet Unions   //
  ///////////////////////////

  typedef union packed {
    narrow_in_aw_data_t narrow_in_aw;
    narrow_in_w_data_t narrow_in_w;
    narrow_in_ar_data_t narrow_in_ar;
    wide_in_ar_data_t wide_in_ar;
    wide_in_aw_data_t wide_in_aw;
  narrow_req_generic_t gen;
  } narrow_req_data_t;

  typedef union packed {
    narrow_in_b_data_t narrow_in_b;
    narrow_in_r_data_t narrow_in_r;
    wide_in_b_data_t wide_in_b;
  narrow_rsp_generic_t gen;
  } narrow_rsp_data_t;

  typedef union packed {
    wide_in_w_data_t wide_in_w;
    wide_in_r_data_t wide_in_r;
  wide_generic_t gen;
  } wide_data_t;


  ///////////////////////////////
  //   Physical Flit Structs   //
  ///////////////////////////////

    typedef struct packed {
      logic valid;
      logic ready;
      narrow_req_data_t data;
    } narrow_req_flit_t;

    typedef struct packed {
      logic valid;
      logic ready;
      narrow_rsp_data_t data;
    } narrow_rsp_flit_t;

    typedef struct packed {
      logic valid;
      logic ready;
      wide_data_t data;
    } wide_flit_t;


  //////////////////////////////
  //   Phys Packeed Structs   //
  //////////////////////////////

  typedef struct packed {
    narrow_req_flit_t narrow_req;
    narrow_rsp_flit_t narrow_rsp;
    wide_flit_t wide;
  } flit_t;

endpackage
