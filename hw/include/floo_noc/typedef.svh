// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
// Authors:
// - Tim Fischer <fischeti@iis.ee.ethz.ch>
// - Michael Rogenmoser <michaero@iis.ee.ethz.ch>

// Macros to define the FlooNoC data types

`ifndef FLOO_NOC_TYPEDEF_SVH_
`define FLOO_NOC_TYPEDEF_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// Node ID for XY coordinates
//
// Arguments:
// - name: Name of the ID struct type
// - x_bits_t: Type of the X coordinate
// - y_bits_t: Type of the Y coordinate
// - port_id_t: Type of the port ID
//
// Usage Example:
// typedef logic [$clog2(NumX)-1:0] x_bits_t;
// typedef logic [$clog2(NumY)-1:0] y_bits_t;
// typedef logic port_id_t;
// `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, port_id_t)
`define FLOO_TYPEDEF_XY_NODE_ID_T(name, x_bits_t, y_bits_t, p_bits_t) \
  typedef struct packed {                                             \
    x_bits_t x;                                                       \
    y_bits_t y;                                                       \
    p_bits_t port_id;                                                 \
  } name;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Header definition
//
// Arguments:
// - hdr_t: Name of the header struct type
// - dst_t: Type of the destination ID
// - src_t: Type of the source ID (Usually `dst_t`)
// - ch_t: Identifier type for the payload
// - rob_idx_t: Type of the RoB index
//
// Usage Example:
// `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, ...)
// `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::axi_ch_e, logic)
//
// For `SourceRouting`:
// `FLOO_TYPEDEF_HDR_T(hdr_t, route_t, id_t, floo_pkg::axi_ch_e, logic)
`define FLOO_TYPEDEF_HDR_T(hdr_t, dst_t, src_t, ch_t, rob_idx_t, mask_t = logic, collect_comm_t = logic, reduction_t = logic)  \
  typedef struct packed {                                         \
    logic rob_req;                                                \
    rob_idx_t rob_idx;                                            \
    dst_t dst_id;                                                 \
    mask_t mask;                                                  \
    src_t src_id;                                                 \
    logic last;                                                   \
    logic atop;                                                   \
    ch_t axi_ch;                                                  \
    collect_comm_t commtype;                                      \
    reduction_t reduction_op;                                     \
  } hdr_t;

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
`define FLOO_TYPEDEF_VC_HDR_T(hdr_t, dst_t, src_t, ch_t, rob_idx_t, vc_id_t)  \
  typedef struct packed {                                                     \
    logic rob_req;                                                            \
    rob_idx_t rob_idx;                                                        \
    dst_t dst_id;                                                             \
    src_t src_id;                                                             \
    logic last;                                                               \
    logic atop;                                                               \
    ch_t axi_ch;                                                              \
    vc_id_t vc_id;                                                            \
    floo_pkg::route_direction_e lookahead;                                    \
  } hdr_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Flit definition of a specific AXI Channel.
//
// Arguments:
// - name: Name of the flit type
// - hdr_t: Type of the header
// - payload_t: Type of the payload
// - rsvd_bits: Number of reserved bits that are not used by the payload
//
// Usage Example:
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_FLIT_T(my_payload, hdr_t, my_payload_t, 13)
`define FLOO_TYPEDEF_FLIT_T(name, hdr_t, payload_t, rsvd_bits)  \
  typedef struct packed {                                       \
    hdr_t hdr;                                                  \
    payload_t payload;                                          \
    logic [rsvd_bits-1:0] rsvd;                                 \
  } floo_``name``_flit_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Flit definition of a generic flit.
//
// Arguments:
// - name: Name of the flit type
// - hdr_t: Type of the header
// - payload_t: Type of the payload
//
// Usage Example:
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_GENERIC_FLIT_T(req, hdr_t, logic [63:0])
`define FLOO_TYPEDEF_GENERIC_FLIT_T(name, hdr_t, payload_t) \
  typedef payload_t floo_``name``_payload_t ;               \
  typedef struct packed {                                   \
    hdr_t hdr;                                              \
    floo_``name``_payload_t payload;                        \
  } floo_``name``_generic_flit_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines AXI channel types based on a `floo_pkg::AxiCfg`.
// Both incoming and outgoing channel are defined with the `name_in` and `name_out` suffix
//
// Arguments:
// - name: Prefix for the AXI channel types
// - cfg: AxiCfg struct type defining AddrWidth, DataWidth, User Width and
//        IdWidth for in and out direction (see `floo_pkg::AxiCfg`)
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{
//  AddrWidth: 32,
//  DataWidth: 64,
//  UserWidth: 1,
//  InIdWidth: 4,
//  OutIdWidth: 2
// };
// `FLOO_TYPEDEF_AXI_FROM_CFG(axi, AxiCfg)
`define FLOO_TYPEDEF_AXI_FROM_CFG(name, cfg)                                                                                                                        \
  typedef logic [cfg.AddrWidth-1:0] ``name``_addr_t;                                                                                                                \
  typedef logic [cfg.InIdWidth-1:0] ``name``_in_id_t;                                                                                                               \
  typedef logic [cfg.OutIdWidth-1:0] ``name``_out_id_t;                                                                                                             \
  typedef logic [cfg.UserWidth-1:0] ``name``_user_t;                                                                                                                \
  typedef logic [cfg.DataWidth-1:0] ``name``_data_t;                                                                                                                \
  typedef logic [cfg.DataWidth/8-1:0] ``name``_strb_t;                                                                                                              \
  `AXI_TYPEDEF_ALL_CT(``name``_in, ``name``_in_req_t, ``name``_in_rsp_t, ``name``_addr_t, ``name``_in_id_t, ``name``_data_t, ``name``_strb_t, ``name``_user_t)      \
  `AXI_TYPEDEF_ALL_CT(``name``_out, ``name``_out_req_t, ``name``_out_rsp_t, ``name``_addr_t, ``name``_out_id_t, ``name``_data_t, ``name``_strb_t, ``name``_user_t)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the flit types and physical channel for configuration
// with a single AXI interface and two physical channels `req` and `rsp`.
// It also defines `unions` named as `chan_t`, which can be used
// to represent multiple different flit types in a single variable.
//
// Arguments:
// - name: Name of flit types
// - req: Name of the `req` flit type
// - rsp: Name of the `rsp` flit type
// - axi_name: Prefix for the AXI channel types
// - cfg: AxiCfg struct type defining AddrWidth, DataWidth, User Width and
//        IdWidth for in and out direction (see `floo_pkg::AxiCfg`)
// - hdr_t: Type of the header
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi, AxiCfg)
// `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, my_axi, AxiCfg, hdr_t)
`define FLOO_TYPEDEF_AXI_CHAN_ALL(name, req, rsp, axi_name, cfg, hdr_t)                                               \
  `FLOO_TYPEDEF_FLIT_T(``name``_aw, hdr_t, ``axi_name``_aw_chan_t, floo_pkg::get_axi_rsvd_bits(cfg, floo_pkg::AxiAw)) \
  `FLOO_TYPEDEF_FLIT_T(``name``_w, hdr_t, ``axi_name``_w_chan_t, floo_pkg::get_axi_rsvd_bits(cfg, floo_pkg::AxiW))    \
  `FLOO_TYPEDEF_FLIT_T(``name``_ar, hdr_t, ``axi_name``_ar_chan_t, floo_pkg::get_axi_rsvd_bits(cfg, floo_pkg::AxiAr)) \
  `FLOO_TYPEDEF_GENERIC_FLIT_T(req, hdr_t, logic [floo_pkg::get_max_axi_payload_bits(cfg, floo_pkg::FlooReq)-1:0])    \
                                                                                                                      \
  `FLOO_TYPEDEF_FLIT_T(``name``_b, hdr_t, ``axi_name``_b_chan_t, floo_pkg::get_axi_rsvd_bits(cfg, floo_pkg::AxiB))    \
  `FLOO_TYPEDEF_FLIT_T(``name``_r, hdr_t, ``axi_name``_r_chan_t, floo_pkg::get_axi_rsvd_bits(cfg, floo_pkg::AxiR))    \
  `FLOO_TYPEDEF_GENERIC_FLIT_T(rsp, hdr_t, logic [floo_pkg::get_max_axi_payload_bits(cfg, floo_pkg::FlooRsp)-1:0])    \
                                                                                                                      \
  typedef union packed {                                                                                              \
    floo_``name``_aw_flit_t axi_aw;                                                                                   \
    floo_``name``_w_flit_t axi_w;                                                                                     \
    floo_``name``_ar_flit_t axi_ar;                                                                                   \
    floo_``req``_generic_flit_t generic;                                                                              \
  } floo_``req``_chan_t;                                                                                              \
                                                                                                                      \
  typedef union packed {                                                                                              \
    floo_``name``_b_flit_t axi_b;                                                                                     \
    floo_``name``_r_flit_t axi_r;                                                                                     \
    floo_``rsp``_generic_flit_t generic;                                                                              \
  } floo_``rsp``_chan_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the flit types and physical channel for configuration
// with a narrow and a wide AXI interface and three physical channels `req`, `rsp` and `wide`.
// It also defines `unions` named as `chan_t`, which can be used
// to represent multiple different flit types in a single variable.
//
// Arguments:
// - name: Name of flit types
// - req: Name of the `req` flit type
// - rsp: Name of the `rsp` flit type
// - wide: Name of the `wide` flit type
// - axi_narrow_name: Prefix for the AXI narrow channel types
// - axi_wide_name: Prefix for the AXI wide channel types
// - cfg_n: AxiCfg struct type for the narrow AXI interface,
//          defining AddrWidth, DataWidth, User Width and
//          IdWidth for in and out direction (see `floo_pkg::AxiCfg`)
// - cfg_w: AxiCfg struct type for the wide AXI interface,
//          defining AddrWidth, DataWidth, User Width and
//          IdWidth for in and out direction (see `floo_pkg::AxiCfg`)
// - hdr_t: Type of the header
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfgN = '{...};
// localparam floo_pkg::axi_cfg_t AxiCfgW = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi_narrow, AxiCfgN)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi_wide, AxiCfgW)
// `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, my_axi_narrow_in, my_axi_wide_in, AxiCfgN, AxiCfgW, hdr_t)
`define FLOO_TYPEDEF_NW_CHAN_ALL(name, req, rsp, wide, axi_narrow_name, axi_wide_name, cfg_n, cfg_w, hdr_t)  \
  `AXI_TYPEDEF_ALL(__``name``_narrow, logic [cfg_n.AddrWidth-1:0], logic [cfg_n.InIdWidth-1:0], logic [cfg_n.DataWidth-1:0], logic [cfg_n.DataWidth/8-1:0], logic [cfg_n.UserWidth-1:0])  \
  `AXI_TYPEDEF_ALL(__``name``_wide, logic [cfg_w.AddrWidth-1:0], logic [cfg_w.InIdWidth-1:0], logic [cfg_w.DataWidth-1:0], logic [cfg_w.DataWidth/8-1:0], logic [cfg_w.UserWidth-1:0])    \
  `FLOO_TYPEDEF_FLIT_T(``name``_narrow_aw, hdr_t, ``axi_narrow_name``_aw_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::NarrowAw))                                            \
  `FLOO_TYPEDEF_FLIT_T(``name``_narrow_w, hdr_t, ``axi_narrow_name``_w_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::NarrowW))                                               \
  `FLOO_TYPEDEF_FLIT_T(``name``_narrow_ar, hdr_t, ``axi_narrow_name``_ar_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::NarrowAr))                                            \
  `FLOO_TYPEDEF_FLIT_T(``name``_wide_ar, hdr_t, ``axi_wide_name``_ar_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::WideAr))                                                  \
  `FLOO_TYPEDEF_GENERIC_FLIT_T(req, hdr_t, logic [floo_pkg::get_max_nw_payload_bits(cfg_n, cfg_w, floo_pkg::FlooReq)-1:0])                                                                \
                                                                                                                                                                                          \
  `FLOO_TYPEDEF_FLIT_T(``name``_narrow_b, hdr_t, ``axi_narrow_name``_b_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::NarrowB))                                               \
  `FLOO_TYPEDEF_FLIT_T(``name``_narrow_r, hdr_t, ``axi_narrow_name``_r_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::NarrowR))                                               \
  `FLOO_TYPEDEF_FLIT_T(``name``_wide_b, hdr_t, ``axi_wide_name``_b_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::WideB))                                                     \
  `FLOO_TYPEDEF_GENERIC_FLIT_T(rsp, hdr_t, logic [floo_pkg::get_max_nw_payload_bits(cfg_n, cfg_w, floo_pkg::FlooRsp)-1:0])                                                                \
                                                                                                                                                                                          \
  `FLOO_TYPEDEF_FLIT_T(``name``_wide_aw, hdr_t, ``axi_wide_name``_aw_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::WideAw))                                                  \
  `FLOO_TYPEDEF_FLIT_T(``name``_wide_w, hdr_t, ``axi_wide_name``_w_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::WideW))                                                     \
  `FLOO_TYPEDEF_FLIT_T(``name``_wide_r, hdr_t, ``axi_wide_name``_r_chan_t, floo_pkg::get_nw_rsvd_bits(cfg_n, cfg_w, floo_pkg::WideR))                                                     \
  `FLOO_TYPEDEF_GENERIC_FLIT_T(wide, hdr_t, logic [floo_pkg::get_max_nw_payload_bits(cfg_n, cfg_w, floo_pkg::FlooWide)-1:0])                                                              \
                                                                                                                                                                                          \
  typedef union packed {                                                                                                                                                                  \
    floo_``name``_narrow_aw_flit_t narrow_aw;                                                                                                                                             \
    floo_``name``_narrow_w_flit_t narrow_w;                                                                                                                                               \
    floo_``name``_narrow_ar_flit_t narrow_ar;                                                                                                                                             \
    floo_``name``_wide_ar_flit_t wide_ar;                                                                                                                                                 \
    floo_``req``_generic_flit_t generic;                                                                                                                                                  \
  } floo_``req``_chan_t;                                                                                                                                                                  \
                                                                                                                                                                                          \
  typedef union packed {                                                                                                                                                                  \
    floo_``name``_narrow_b_flit_t narrow_b;                                                                                                                                               \
    floo_``name``_narrow_r_flit_t narrow_r;                                                                                                                                               \
    floo_``name``_wide_b_flit_t wide_b;                                                                                                                                                   \
    floo_``rsp``_generic_flit_t generic;                                                                                                                                                  \
  } floo_``rsp``_chan_t;                                                                                                                                                                  \
                                                                                                                                                                                          \
  typedef union packed {                                                                                                                                                                  \
    floo_``name``_wide_aw_flit_t wide_aw;                                                                                                                                                 \
    floo_``name``_wide_w_flit_t wide_w;                                                                                                                                                   \
    floo_``name``_wide_r_flit_t wide_r;                                                                                                                                                   \
    floo_``wide``_generic_flit_t generic;                                                                                                                                                 \
  } floo_``wide``_chan_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the link types with a ready-valid handshaking interface
//
// Arguments:
// - name: Name of the link type
// - chan_name: Name of the channel type to transport
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi, AxiCfg)
// `FLOO_TYPEDEF_AXI_CHAN_ALL(my_axi, req, rsp, my_axi_in, AxiCfg, hdr_t)
// FLOO_TYPEDEF_LINK_T(req, my_axi)
`define FLOO_TYPEDEF_LINK_T(name, chan_name, vc_num = 1, phy_num = 1)   \
  typedef struct packed {                                        \
    logic [vc_num-1:0] valid;                                    \
    logic [vc_num-1:0] ready;                                    \
    logic [vc_num-1:0] credit;                                 \
    floo_``chan_name``_chan_t [phy_num-1:0] ``chan_name``;       \
  } floo_``name``_t;

  ////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the link types with a ready-valid handshaking interface
// It support virtual channeling by extending the handshakes
//
// Arguments:
// - name: Name of the link type
// - chan_name: Name of the channel type to transport
// - vc_num: Number of virtual channels
// - phy_num: Number of physical channels
//
// Assumption: vc_num >= phy_num
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi, AxiCfg)
// `FLOO_TYPEDEF_AXI_CHAN_ALL(my_axi, req, rsp, my_axi_in, AxiCfg, hdr_t)
// FLOO_TYPEDEF_VIRT_CHAN_LINK_T(req, my_axi, 1, 1)
//
`define FLOO_TYPEDEF_VIRT_CHAN_LINK_T(name, chan_name, vc_num, phy_num)   \
  typedef struct packed {                                        \
    logic [vc_num-1:0] valid;                                    \
    logic [vc_num-1:0] ready;                                    \
    logic [vc_num-1:0] credit;                                 \
    floo_``chan_name``_chan_t [phy_num-1:0] ``chan_name``;       \
  } floo_``name``_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
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
// Defines the all the link types with ready-valid handshaking interface
// for a single AXI interface configuration
//
// Arguments:
// - req: Name of the `req` link type
// - rsp: Name of the `rsp` link type
// - req_chan: Name of the `req` channel type to transport
// - rsp_chan: Name of the `rsp` channel type to transport
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfg = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_axi, AxiCfg)
// `FLOO_TYPEDEF_AXI_CHAN_ALL(my_axi, my_req, my_rsp, my_axi_in, AxiCfg, hdr_t)
// `FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, my_req, my_rsp)
`define FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req_chan, rsp_chan) \
  `FLOO_TYPEDEF_LINK_T(req, req_chan)                           \
  `FLOO_TYPEDEF_LINK_T(rsp, rsp_chan)                           \

////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the link types with ready-valid handshaking interface
// for a narrow-wide AXI interface configuration
//
// Arguments:
// - req: Name of the `req` link type
// - rsp: Name of the `rsp` link type
// - wide: Name of the `wide` link type
// - req_chan: Name of the `req` channel type to transport
// - rsp_chan: Name of the `rsp` channel type to transport
// - wide_chan: Name of the `wide` channel type to transport
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfgN = '{...};
// localparam floo_pkg::axi_cfg_t AxiCfgW = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_narrow_axi, AxiCfgN)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_wide_axi, AxiCfgW)
// `FLOO_TYPEDEF_NW_CHAN_ALL(axi, my_req, my_rsp, my_wide, my_axi_narrow_in, my_axi_wide_in, AxiCfgN, AxiCfgW, hdr_t)
// `FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, my_req, my_rsp, my_wide)
`define FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, req_chan, rsp_chan, wide_chan, req_vc_num = 1, rsp_vc_num = 1, wide_vc_num = 1, wide_phy_num = 1) \
  `FLOO_TYPEDEF_LINK_T(req, req_chan, req_vc_num, 1)                                           \
  `FLOO_TYPEDEF_LINK_T(rsp, rsp_chan, rsp_vc_num, 1)                                           \
  `FLOO_TYPEDEF_LINK_T(wide, wide_chan, wide_vc_num, wide_phy_num)

    ////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines the all the link types with ready-valid handshaking interface
// for a narrow-wide AXI interface configuration which implements a simple
// virtual channeling.
//
// Arguments:
// - req: Name of the `req` link type
// - rsp: Name of the `rsp` link type
// - wide: Name of the `wide` link type
// - req_chan: Name of the `req` channel type to transport
// - rsp_chan: Name of the `rsp` channel type to transport
// - wide_chan: Name of the `wide` channel type to transport
// - req_virt_chan: Number of virtual channel for the narrow link
// - wide_virt_chan: Number of virtual channel for the wide link
//
// Usage Example:
// localparam floo_pkg::axi_cfg_t AxiCfgN = '{...};
// localparam floo_pkg::axi_cfg_t AxiCfgW = '{...};
// `FLOO_TYPEDEF_HDR_T(hdr_t, ...)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_narrow_axi, AxiCfgN)
// `FLOO_TYPEDEF_AXI_FROM_CFG(my_wide_axi, AxiCfgW)
// `FLOO_TYPEDEF_NW_CHAN_ALL(axi, my_req, my_rsp, my_wide, my_axi_narrow_in, my_axi_wide_in, AxiCfgN, AxiCfgW, hdr_t)
// `FLOO_TYPEDEF_NW_LINK_ALL(req, rsp, wide, my_req, my_rsp, my_wide, 1, 2)
`define FLOO_TYPEDEF_NW_VIRT_CHAN_LINK_ALL(req, rsp, wide, req_chan, rsp_chan, wide_chan, req_virt_chan, wide_virt_chan, wide_phys_chan)  \
  `FLOO_TYPEDEF_VIRT_CHAN_LINK_T(req, req_chan, req_virt_chan, req_virt_chan)                                                            \
  `FLOO_TYPEDEF_VIRT_CHAN_LINK_T(rsp, rsp_chan, 1, 1)                                                                        \
  `FLOO_TYPEDEF_VIRT_CHAN_LINK_T(wide, wide_chan, wide_virt_chan, wide_phys_chan)

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

`endif // FLOO_NOC_TYPEDEF_SVH_
