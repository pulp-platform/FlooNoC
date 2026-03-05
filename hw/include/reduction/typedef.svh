// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Lorenzo Leone <lleone@iis.ee.ethz.ch>
//
// Macros to define the reduction offload interface data types.
//
`ifndef RED_INTERFACE_TYPEDEF_SVH_
`define RED_INTERFACE_TYPEDEF_SVH_

////////////////////////////////////////////////////////////////////////////////////////////////////
// Reduction offload request channel payload
//
// Arguments:
// - name:       Suffix/prefix used to build the type name
// - data_t:     Operand data type
`define RED_TYPEDEF_REQ_CHAN_T(name, data_t) \
  typedef struct packed {                          \
    floo_pkg::collect_op_e  op;                                     \
    data_t   operand1;                               \
    data_t   operand2;                               \
  } red_``name``_req_chan_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Reduction offload response channel payload
//
// Arguments:
// - name:   Suffix/prefix used to build the type name
// - data_t: Result data type
`define RED_TYPEDEF_RSP_CHAN_T(name, data_t) \
  typedef struct packed {                   \
    data_t result;                          \
  } red_``name``_rsp_chan_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ready/valid link for a request channel
//
// Arguments:
// - name:      Link type base name (e.g. wide_req)
// - chan_name: Channel base name used
`define RED_TYPEDEF_REQ_LINK_T(name, chan_name) \
  typedef struct packed {                       \
    logic                    valid;             \
    logic                    ready;             \
    red_``chan_name``_req_chan_t req;           \
  } red_``name``_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Ready/valid link for a response channel
//
// Arguments:
// - name:      Link type base name (e.g. wide_rsp)
// - chan_name: Channel base name
`define RED_TYPEDEF_RSP_LINK_T(name, chan_name) \
  typedef struct packed {                       \
    logic                    valid;             \
    logic                    ready;             \
    red_``chan_name``_rsp_chan_t rsp;           \
  } red_``name``_t;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Convenience macro: define both request and response channel payload types
//
// Arguments:
// - name:   Base name
// - data_t: Data type (operands + result)
`define RED_TYPEDEF_REQ_RSP_CHAN_ALL(name, data_t) \
  `RED_TYPEDEF_REQ_CHAN_T(name, data_t)            \
  `RED_TYPEDEF_RSP_CHAN_T(name, data_t)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Convenience macro: define payload types AND ready/valid links
//
// Arguments:
// - name:     Base name for the payload types
// - data_t:   Data type (operands + result)
// - req_link: Base name for the request link type
// - rsp_link: Base name for the response link type
//
// Example:
// `RED_TYPEDEF_REQ_RSP_LINK_ALL(wide, data_t, wide_req, wide_rsp)
`define RED_TYPEDEF_REQ_RSP_LINK(name, data_t, req_link, rsp_link) \
  `RED_TYPEDEF_REQ_RSP_CHAN_ALL(name, data_t)                          \
  `RED_TYPEDEF_REQ_LINK_T(req_link, name)                                    \
  `RED_TYPEDEF_RSP_LINK_T(rsp_link, name)

`endif // RED_INTERFACE_TYPEDEF_SVH_
