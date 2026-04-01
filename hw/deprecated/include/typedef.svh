// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>
// - Michael Rogenmoser <michaero@iis.ee.ethz.ch>

// Macros to define the FlooNoC data types

`ifndef FLOO_NOC_TYPEDEF_DEPRECATED_SVH_
`define FLOO_NOC_TYPEDEF_DEPRECATED_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// Header definition for virtual channel and lookahead routing
//
// Arguments:
// - hdr_t: Name of the header struct type
// - dst_t: Type of the destination ID
// - src_t: Type of the source ID (Usually `dst_t`)
// - ch_t: Identifier type for the payload
// - rob_idx_t: Type of the RoB index
// - vc_id_t: Type of the virtual channel ID
//
// Usage Example:
// `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, ...)
// `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::axi_ch_e, logic)
//
// For `SourceRouting`:
// `FLOO_TYPEDEF_HDR_T(hdr_t, route_t, id_t, floo_pkg::axi_ch_e, logic)
`define FLOO_TYPEDEF_VC_HDR_T(hdr_t, dst_t, src_t, ch_t, rob_idx_t, vc_id_t, mask_t = logic, collect_op_t = logic)  \
  typedef struct packed {                                                     \
    logic rob_req;                                                            \
    rob_idx_t rob_idx;                                                        \
    dst_t dst_id;                                                             \
    mask_t collective_mask;                                                   \
    src_t src_id;                                                             \
    logic last;                                                               \
    logic atop;                                                               \
    ch_t axi_ch;                                                              \
    collect_op_t collective_op;                                               \
    vc_id_t vc_id;                                                            \
    floo_pkg::route_direction_e lookahead;                                    \
  } hdr_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Defines the all the link types with credit-based flow control interface
// for use with virtual channels
//
// Arguments:
// - name: Name of the link type
// - chan_name: Name of the channel type to transport
// - vc_id_t: Type of the virtual channel ID
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi, AxiCfg)
// `FLOO_TYPEDEF_AXI_CHAN_ALL(my_axi, req, rsp, my_axi_in, AxiCfg, hdr_t)
// FLOO_TYPEDEF_LINK_T(vc_req, my_axi)
`define FLOO_TYPEDEF_VC_LINK_T(name, chan_name, vc_id_t)  \
  typedef struct packed {                                 \
    logic valid;                                          \
    logic credit_v;                                       \
    vc_id_t credit_id;                                    \
    floo_``chan_name``_chan_t ``chan_name``;              \
  } floo_``name``_t;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the link types with credit-based flow control interface
// for a single AXI interface configuration
//
// Arguments:
// - req: Name of the `req` link type
// - rsp: Name of the `rsp` link type
// - req_chan: Name of the `req` channel type to transport
// - rsp_chan: Name of the `rsp` channel type to transport
// - vc_id_t: Type of the virtual channel ID
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi, AxiCfg)
// `FLOO_TYPEDEF_AXI_CHAN_ALL(my_axi, my_req, my_rsp, my_axi_in, AxiCfg, hdr_t)
// `FLOO_TYPEDEF_VC_AXI_LINK_ALL(vc_req, vc_rsp, my_req, my_rsp)
`define FLOO_TYPEDEF_VC_AXI_LINK_ALL(req, rsp, req_chan, rsp_chan, vc_id_t) \
  `FLOO_TYPEDEF_VC_LINK_T(req, req_chan, vc_id_t)                           \
  `FLOO_TYPEDEF_VC_LINK_T(rsp, rsp_chan, vc_id_t)                           \


////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the link types with credit-based flow control interface
// for a narrow-wide AXI interface configuration
//
// Arguments:
// - req: Name of the `req` link type
// - rsp: Name of the `rsp` link type
// - wide: Name of the `wide` link type
// - req_chan: Name of the `req` channel type to transport
// - rsp_chan: Name of the `rsp` channel type to transport
// - wide_chan: Name of the `wide` channel type to transport
// - vc_id_t: Type of the virtual channel ID
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfgN = '{...};
// localparam floo_pkg::axi_cfg_t AxiCfgW = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_narrow_axi, AxiCfgN)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_wide_axi, AxiCfgW)
// `FLOO_TYPEDEF_NW_CHAN_ALL(axi, my_req, my_rsp, my_wide, my_axi_narrow_in, my_axi_wide_in, AxiCfgN, AxiCfgW, hdr_t)
// `FLOO_TYPEDEF_NW_LINK_ALL(vc_req, vc_rsp, vc_wide, my_req, my_rsp, my_wide)
`define FLOO_TYPEDEF_VC_NW_LINK_ALL(req, rsp, wide, req_chan, rsp_chan, wide_chan, vc_id_t) \
  `FLOO_TYPEDEF_VC_LINK_T(req, req_chan, vc_id_t)                                           \
  `FLOO_TYPEDEF_VC_LINK_T(rsp, rsp_chan, vc_id_t)                                           \
  `FLOO_TYPEDEF_VC_LINK_T(wide, wide_chan, vc_id_t)

`endif // FLOO_NOC_TYPEDEF_DEPRECATED_SVH_
