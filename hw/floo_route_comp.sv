// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

module floo_route_comp
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
#(
  /// The type of routing algorithms to use
  parameter route_algo_e RouteAlgo = IdTable,
  /// Whether to use a routing table with address decoder
  /// In case of XY Routing or the coordinates should be
  /// directly read from the request address
  parameter bit UseIdTable = 1'b1,
  /// The offset bit to read the X coordinate from
  parameter int unsigned XYAddrOffsetX = 0,
  /// The offset bit to read the Y coordinate from
  parameter int unsigned XYAddrOffsetY = 0,
  /// The offset bit to read the ID from
  parameter int unsigned IdAddrOffset = 0,
  /// The number of possible rules
  parameter int unsigned NumAddrRules = 0,
  /// The number of possible routes
  parameter int unsigned NumRoutes = 0,
  /// The type of the coordinates or IDs
  parameter type id_t = logic,
  /// The type of the address
  parameter type addr_t = logic,
  /// The type of the mask
  parameter type mask_t = logic,
  /// The type of the select dst
  parameter type select_t = logic,
  /// The type of the route
  parameter type route_t = logic,
  /// The type of the address rules
  parameter type addr_rule_t = logic,
  /// The type of the mask rules
  parameter type mask_rule_t = logic
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  id_t   id_i,
  input  addr_t addr_i,
  input  mask_t mask_i,
  input  addr_rule_t [NumAddrRules-1:0] addr_map_i,
  input  mask_rule_t [NumAddrRules-1:0] mask_map_i,
  input  route_t [NumRoutes-1:0] route_table_i,
  output route_t route_o,
  output id_t id_o,
  output select_t select_o, 
  output logic [$clog2(NumAddrRules):0] rep_coeff_o,
  output mask_t [NumAddrRules-1:0] addr_o,
  output mask_t [NumAddrRules-1:0] mask_o
);

  // Use an address decoder to map the address to a destination ID.
  // The `rule_t` struct has to have the fields `idx`, `start_addr` and `end_addr`.
  // `SourceRouting` is a special case, where the the `idx` is the actual (pre-computed) route.
  // Further, the `rule_t` requires an additional field `id`, which can be used for the return route.
  // The reason for that is that a request destination is given by a physical address, while the
  // response destination is given by the ID of the source.

  if (UseIdTable &&
    ((RouteAlgo == IdTable) ||
     (RouteAlgo == XYRouting) ||
     (RouteAlgo == SourceRouting)))
  begin : gen_table_routing
    logic dec_error, dec_error_mcast;

    // This is simply to pass the assertions in addr_decode
    // It is not used otherwise, since we specify `idx_t`
    localparam int unsigned MaxPossibleId = 1 << $bits(id_o);
    
    multiaddr_decode #(
      .NoIndices (NumAddrRules), // MaxPossibleId != NumAddrRules, but here it is not important as mask_o/addr_o is unused.
      .NoRules (NumAddrRules),
      .addr_t (mask_t),
      .rule_t (mask_rule_t),
      .src_t (id_t)
    ) i_multiaddr_decode (
      .addr_i (addr_i),
      .mask_i (mask_i),
      .addr_map_i (mask_map_i),
      .src_id_i (id_i),
      .select_o (select_o),
      .rep_coeff_o (rep_coeff_o),
      .addr_o (addr_o),
      .mask_o (mask_o),
      .dec_valid_o      (             ),
      .dec_error_o      ( dec_error_mcast ),
      .en_default_idx_i ( 1'b0        ),
      .default_idx_i    ( '0          )
    );      
    addr_decode #(
      .NoIndices  ( MaxPossibleId ),
      .NoRules    ( NumAddrRules  ),
      .addr_t     ( addr_t        ),
      .rule_t     ( addr_rule_t   ),
      .idx_t      ( id_t          )
    ) i_addr_dst_decode (
      .addr_i           ( addr_i      ),
      .addr_map_i       ( addr_map_i  ),
      .idx_o            ( id_o        ),
      .dec_valid_o      (             ),
      .dec_error_o      ( dec_error   ),
      .en_default_idx_i ( 1'b0        ),
      .default_idx_i    ( '0          )
    );

      `ASSERT(DecodeError, !dec_error || id_i!='{x:0, y:0})
  end else if (RouteAlgo == XYRouting) begin : gen_xy_bits_routing
    assign id_o.x = addr_i[XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = addr_i[XYAddrOffsetY +: $bits(id_o.y)];
  end else if (RouteAlgo == IdTable) begin : gen_id_bits_routing
    assign id_o = addr_i[IdAddrOffset +: $bits(id_o)];
  end else if (RouteAlgo == SourceRouting) begin : gen_source_routing
    // Nothing to do here
  end else begin : gen_error
    $fatal(1, "Routing algorithm not implemented");
  end
  if (RouteAlgo == SourceRouting) begin : gen_route
    assign route_o = (UseIdTable)? route_table_i[id_o] : route_table_i[id_i];
  end else begin : gen_no_route
    assign route_o = '0;
  end

endmodule
