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
  parameter bit EnMultiCast = 1'b0,
  parameter type id_t = logic,
  /// The type of the address
  parameter type addr_t = logic,
  parameter type mask_t = addr_t,
  /// The type of the route
  parameter type route_t = logic,
  /// The type of the address rules
  parameter type addr_rule_t = logic,
  parameter type mask_rule_t = logic,
  parameter type mask_sel_t = logic
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  id_t   id_i,
  input  addr_t addr_i,
  input  mask_t mask_i,
  input  addr_rule_t [RouteCfg.NumSamRules-1:0] addr_map_i,
  input  mask_rule_t [RouteCfg.NumSamRules-1:0] mask_map_i,
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
  localparam int unsigned AddrWidth = $bits(addr_t);
  if (UseIdTable &&
    ((RouteCfg.RouteAlgo == IdTable) ||
     (RouteCfg.RouteAlgo == XYRouting) ||
     (RouteCfg.RouteAlgo == SourceRouting)))
  begin : gen_table_routing
    logic dec_error;
    logic mask_dec_error;
    mask_sel_t x_mask_sel, y_mask_sel;
    addr_t x_addr_mask, y_addr_mask;
    // idx_t idx;

    // This is simply to pass the assertions in addr_decode
    // It is not used otherwise, since we specify `idx_t`
    localparam int unsigned MaxPossibleId = 1 << $bits(id_o);

    addr_decode #(
      .NoIndices  ( MaxPossibleId        ),
      .NoRules    ( RouteCfg.NumSamRules ),
      .addr_t     ( addr_t               ),
      .rule_t     ( addr_rule_t          ),
      .idx_t      ( id_t                )
    ) i_addr_dst_decode (
      .addr_i           ( addr_i      ),
      .addr_map_i       ( addr_map_i  ),
      .idx_o            ( id_o         ),
      .dec_valid_o      (             ),
      .dec_error_o      ( dec_error   ),
      .en_default_idx_i ( 1'b0        ),
      .default_idx_i    ( '0          )
    );
    if (EnMultiCast && RouteCfg.UseIdTable &&
        (RouteCfg.RouteAlgo == floo_pkg::XYRouting))
    begin : gen_mcast_mask
      floo_mask_decode #(
        .NumMaskRules ( RouteCfg.NumSamRules ),
        .mask_rule_t  ( mask_rule_t          ),
        .id_t         ( id_t                 ),
        .mask_sel_t   ( mask_sel_t           )
      ) i_mask_decode (
        .id_i         ( id_o            ),
        .mask_x_mask  ( x_mask_sel      ),
        .mask_y_mask  ( y_mask_sel      ),
        .mask_map_i   ( mask_map_i      ),
        .dec_error_o  ( mask_dec_error  )
      );
      always_comb begin
        x_addr_mask = (({AddrWidth{1'b1}} >> (AddrWidth - x_mask_sel.len)) << x_mask_sel.offset);
        y_addr_mask = (({AddrWidth{1'b1}} >> (AddrWidth - y_mask_sel.len)) << y_mask_sel.offset);
      end
      assign mask_o.x = (mask_i & x_addr_mask) >> x_mask_sel.offset;
      assign mask_o.y = (mask_i & y_addr_mask) >> y_mask_sel.offset;
      assign mask_o.port_id = '0;
      `ASSERT(MaskDecodeError, !mask_dec_error)
    end
    else begin : gen_no_mcast_mask
      assign mask_o = '0;
    end

    `ASSERT(DecodeError, !dec_error)
  end else if (RouteCfg.RouteAlgo == XYRouting) begin : gen_xy_bits_routing
    assign id_o.port_id = '0;
    assign id_o.x = addr_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = addr_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
    if(EnMultiCast) begin : gen_mcast_mask
      assign mask_o.x = mask_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
      assign mask_o.y = mask_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
      assign mask_o.port_id = '0;
    end else begin : gen_no_mcast_mask
      assign mask_o = '0;
    end
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
