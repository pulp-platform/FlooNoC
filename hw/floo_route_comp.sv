// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

module floo_route_comp
  import floo_pkg::*;
#(
  /// The route config
  parameter floo_pkg::route_cfg_t RouteCfg = '0,
  parameter bit UseIdTable = RouteCfg.UseIdTable,
  parameter type id_t = logic,
  /// The type of the address
  parameter type addr_t = logic,
  /// The type of the route
  parameter type route_t = logic,
  /// The type of the address rules
  parameter type addr_rule_t = logic
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  id_t   id_i,
  input  addr_t addr_i,
  input  addr_t mask_i,
  input  addr_rule_t [RouteCfg.NumSamRules-1:0] addr_map_i,
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,
  output route_t route_o,
  output id_t id_o,
  output id_t mask_o
);

  // Use an address decoder to map the address to a destination ID.
  // The `rule_t` struct has to have the fields `idx`, `start_addr` and `end_addr`.
  // `SourceRouting` is a special case, where the the `idx` is the actual (pre-computed) route.
  // Further, the `rule_t` requires an additional field `id`, which can be used for the return route.
  // The reason for that is that a request destination is given by a physical address, while the
  // response destination is given by the ID of the source.
  if (UseIdTable &&
    ((RouteCfg.RouteAlgo == IdTable) ||
     (RouteCfg.RouteAlgo == XYRouting) ||
     (RouteCfg.RouteAlgo == SourceRouting)))
  begin : gen_table_routing
    logic dec_error;

    // This is simply to pass the assertions in addr_decode
    // It is not used otherwise, since we specify `idx_t`
    localparam int unsigned MaxPossibleId = 1 << $bits(id_o);

    addr_decode #(
      .NoIndices  ( MaxPossibleId        ),
      .NoRules    ( RouteCfg.NumSamRules ),
      .addr_t     ( addr_t               ),
      .rule_t     ( addr_rule_t          ),
      .idx_t      ( id_t                 )
    ) i_addr_dst_decode (
      .addr_i           ( addr_i      ),
      .addr_map_i       ( addr_map_i  ),
      .idx_o            ( id_o        ),
      .dec_valid_o      (             ),
      .dec_error_o      ( dec_error   ),
      .en_default_idx_i ( 1'b0        ),
      .default_idx_i    ( '0          )
    );

    `ASSERT(DecodeError, !dec_error)
  end else if (RouteCfg.RouteAlgo == XYRouting) begin : gen_xy_bits_routing
    assign id_o.port_id = '0;
    assign id_o.x = addr_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = addr_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
    assign mask_o.port_id = '0;
    assign mask_o.x = mask_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
    assign mask_o.y = mask_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
  end else if (RouteCfg.RouteAlgo == IdTable) begin : gen_id_bits_routing
    assign id_o = addr_i[RouteCfg.IdAddrOffset +: $bits(id_o)];
  end else if (RouteCfg.RouteAlgo == SourceRouting) begin : gen_source_routing
    // Nothing to do here
  end else begin : gen_error
    $fatal(1, "Routing algorithm not implemented");
  end
  if (RouteCfg.RouteAlgo == SourceRouting) begin : gen_route
    assign route_o = (UseIdTable)? route_table_i[id_o] : route_table_i[id_i];
  end else begin : gen_no_route
    assign route_o = '0;
  end

endmodule
