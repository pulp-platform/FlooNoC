// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

/// This module simply translates the address to an endpoint ID.
/// It uses either an address decoder for the system address map,
/// or a simple offset based translation.
module floo_id_translation #(
  /// The route config
  parameter floo_pkg::route_cfg_t RouteCfg = '0,
  /// The type of the ID
  parameter type id_t = logic,
  /// The type of the IDX field in the address rule
  parameter type sam_idx_t = id_t,
  /// The address type
  parameter type addr_t = logic,
  /// The type of the address rules
  parameter type addr_rule_t = logic,
  /// The System Address Map
  parameter addr_rule_t [RouteCfg.NumSamRules-1:0] Sam,
  /// The type of the offset + len to identify which bits in the address can be masked
  parameter type mask_sel_t = logic,
  /// Mask type coming from the user field
  parameter type mask_t = addr_t,
  parameter bit  EnMultiCast = 1'b0
) (
  input  logic  clk_i,   // Only used for assertions
  input  logic  rst_ni,  // Only used for assertions
  input  logic  valid_i, // Only used for assertions
  input  addr_t addr_i,
  input  mask_t mask_i,
  output id_t   id_o,
  output id_t   mask_o
);

  localparam int unsigned AddrWidth = $bits(addr_t);

  if (RouteCfg.UseIdTable) begin : gen_addr_decoder
    logic dec_error;
    sam_idx_t idx_out;
    mask_sel_t x_mask_sel, y_mask_sel;
    addr_t x_addr_mask, y_addr_mask;

    // This is simply to pass the assertions in addr_decode
    // It is not used otherwise, since we specify `idx_t`
    localparam int unsigned MaxPossibleId = 1 << $bits(id_o);

    addr_decode #(
      .NoIndices  ( MaxPossibleId        ),
      .NoRules    ( RouteCfg.NumSamRules ),
      .addr_t     ( addr_t               ),
      .rule_t     ( addr_rule_t          ),
      .idx_t      ( sam_idx_t            )
    ) i_addr_dst_decode (
      .addr_i,
      .addr_map_i       ( Sam         ),
      .idx_o            ( idx_out     ),
      .dec_valid_o      (             ),
      .dec_error_o      ( dec_error   ),
      .en_default_idx_i ( 1'b0        ),
      .default_idx_i    ( '0          )
    );

    `ASSERT(DecodeError, !(dec_error && valid_i))

    if (EnMultiCast) begin: gen_mcast_id_mask
      assign x_mask_sel = idx_out.mask_x;
      assign y_mask_sel = idx_out.mask_y;
      always_comb begin
        x_addr_mask = (({AddrWidth{1'b1}} >> (AddrWidth - x_mask_sel.len)) << x_mask_sel.offset);
        y_addr_mask = (({AddrWidth{1'b1}} >> (AddrWidth - y_mask_sel.len)) << y_mask_sel.offset);
      end
    assign mask_o.x = (mask_i & x_addr_mask) >> x_mask_sel.offset;
    assign mask_o.y = (mask_i & y_addr_mask) >> y_mask_sel.offset;
    assign mask_o.port_id = '0;
    assign id_o = idx_out.id;
    end else begin: gen_no_mcast
      // If no multicast, simply forward the decoder id to the output
      assign id_o = idx_out;
    end
  end else if (RouteCfg.RouteAlgo == floo_pkg::XYRouting) begin : gen_xy_offset
    assign id_o.port_id = '0; // Not supported at the moment
    assign id_o.x = addr_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = addr_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
    if(EnMultiCast) begin : gen_mcast_mask
      assign mask_o.x = mask_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
      assign mask_o.y = mask_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
      assign mask_o.port_id = '0;
    end else begin : gen_no_mcast_mask
      assign mask_o = '0;
    end
  end else if (RouteCfg.RouteAlgo == floo_pkg::IdTable) begin : gen_id_offset
    assign id_o = addr_i[RouteCfg.IdAddrOffset +: $bits(id_o)];
  end else begin: gen_unsupported_routing
    $fatal(1, "Routing algorithm %0s only supports table-based address translation",
        RouteCfg.RouteAlgo);
  end

endmodule
