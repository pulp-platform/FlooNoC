// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

module floo_route_comp
  import floo_pkg::*;
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
  parameter int unsigned NumRules = 0,
  /// The type of the coordinates or IDs
  parameter type id_t = logic,
  /// The type of the rules
  parameter type rule_t = logic,
  /// The address type
  parameter type addr_t = logic
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  addr_t addr_i,
  input  rule_t [NumRules-1:0] map_i,
  output id_t   id_o
);

  if (UseIdTable &&
     ((RouteAlgo == IdTable) ||
      (RouteAlgo == XYRouting) ||
      (RouteAlgo == SourceRouting))) begin : gen_table_routing
    logic dec_error;

    // This is simply to pass the assertions in addr_decode
    // It is not used otherwise, since we specify `idx_t`
    localparam int unsigned MaxPossibleId = 1 << $bits(id_o);

    addr_decode #(
      .NoIndices  ( MaxPossibleId ),
      .NoRules    ( NumRules      ),
      .addr_t     ( addr_t        ),
      .rule_t     ( rule_t        ),
      .idx_t      ( id_t          )
    ) i_addr_dst_decode (
      .addr_i           ( addr_i    ),
      .addr_map_i       ( map_i     ),
      .idx_o            ( id_o      ),
      .dec_valid_o      (           ),
      .dec_error_o      ( dec_error ),
      .en_default_idx_i ( 1'b0      ),
      .default_idx_i    ( '0        )
    );

    `ASSERT(DecodeError, !dec_error)
  end else if (RouteAlgo == XYRouting) begin : gen_xy_bits_routing
    assign id_o.x = addr_i[XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = addr_i[XYAddrOffsetY +: $bits(id_o.y)];
  end else if (RouteAlgo == IdTable) begin : gen_id_bits_routing
    assign id_o = addr_i[IdAddrOffset +: $bits(id_o)];
  end else begin : gen_error
    $fatal(1, "Routing algorithm not implemented");
  end

endmodule
