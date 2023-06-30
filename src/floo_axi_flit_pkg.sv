// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead


`include "axi/typedef.svh"

package floo_axi_flit_pkg;

  localparam int unsigned NumPhysChannels = 2;
  localparam int unsigned NumAxiChannels = 5;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

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

  typedef logic [31:0] axi_out_addr_t;
  typedef logic [63:0] axi_out_data_t;
  typedef logic [7:0] axi_out_strb_t;
  typedef logic [2:0] axi_out_id_t;
  typedef logic [0:0] axi_out_user_t;


  `AXI_TYPEDEF_ALL(axi_in, axi_in_addr_t, axi_in_id_t, axi_in_data_t, axi_in_strb_t, axi_in_user_t)
  `AXI_TYPEDEF_ALL(axi_out, axi_out_addr_t, axi_out_id_t, axi_out_data_t, axi_out_strb_t,
                   axi_out_user_t)

  //////////////////////
  //   AXI Channels   //
  //////////////////////

  typedef enum logic [2:0] {
    AxiInAw,
    AxiInW,
    AxiInAr,
    AxiInB,
    AxiInR
  } axi_ch_e;

  ///////////////////////////
  //   Physical Channels   //
  ///////////////////////////

  typedef enum int {
    PhysReq,
    PhysRsp
  } phys_chan_e;

  /////////////////////////
  //   Channel Mapping   //
  /////////////////////////

  localparam int NumVirtPerPhys[NumPhysChannels] = '{3, 2};

  localparam int PhysChanMapping[NumAxiChannels] = '{PhysReq, PhysReq, PhysReq, PhysRsp, PhysRsp};

  localparam int VirtChanMapping[NumPhysChannels][3] = '{
      '{AxiInAw, AxiInW, AxiInAr},
      '{AxiInB, AxiInR, 0}
  };

  ///////////////////////
  //   Meta Typedefs   //
  ///////////////////////

  typedef logic [0:0] rob_req_t;
  typedef logic [5:0] rob_idx_t;
  typedef logic [5:0] dst_id_t;
  typedef logic [5:0] src_id_t;
  typedef logic [0:0] last_t;
  typedef logic [0:0] atop_t;
  typedef logic [2:0] axi_ch_t;

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
    axi_in_aw_chan_t aw;
    logic [2:0] rsvd;
  } axi_in_aw_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    axi_in_w_chan_t w;
  } axi_in_w_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    axi_in_ar_chan_t ar;
    logic [8:0] rsvd;
  } axi_in_ar_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    logic [73:0] rsvd;
  } req_generic_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    axi_in_b_chan_t b;
    logic [64:0] rsvd;
  } axi_in_b_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    axi_in_r_chan_t r;
  } axi_in_r_data_t;

  typedef struct packed {
    rob_req_t rob_req;
    rob_idx_t rob_idx;
    dst_id_t dst_id;
    src_id_t src_id;
    last_t last;
    atop_t atop;
    axi_ch_t axi_ch;
    logic [70:0] rsvd;
  } rsp_generic_t;



  ///////////////////////////
  //   AXI Packet Unions   //
  ///////////////////////////

  typedef union packed {
    axi_in_aw_data_t axi_in_aw;
    axi_in_w_data_t axi_in_w;
    axi_in_ar_data_t axi_in_ar;
    req_generic_t gen;
  } req_data_t;

  typedef union packed {
    axi_in_b_data_t axi_in_b;
    axi_in_r_data_t axi_in_r;
    rsp_generic_t   gen;
  } rsp_data_t;


  ///////////////////////////////
  //   Physical Flit Structs   //
  ///////////////////////////////

  typedef struct packed {
    logic valid;
    logic ready;
    req_data_t data;
  } req_flit_t;

  typedef struct packed {
    logic valid;
    logic ready;
    rsp_data_t data;
  } rsp_flit_t;


  //////////////////////////////
  //   Phys Packeed Structs   //
  //////////////////////////////

  typedef struct packed {
    req_flit_t req;
    rsp_flit_t rsp;
  } flit_t;

endpackage

