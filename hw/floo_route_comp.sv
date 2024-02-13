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
  /// The type of the coordinates or IDs used to index the routing table, addr_map
  parameter type id_in_t = logic,
  /// The type of the coordinates, IDs or routes returned by the routing table
  parameter type id_out_t = logic,
  /// The type of the rules
  parameter type rule_t = logic
) (
  input  logic  clk_i,
  input  logic  rst_ni,
  input  id_in_t id_i,
  input  rule_t [NumRules-1:0] map_i,
  output id_out_t   id_o
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
    logic dec_error;

    // This is simply to pass the assertions in addr_decode
    // It is not used otherwise, since we specify `idx_t`
    localparam int unsigned MaxPossibleId = 1 << $bits(id_o);

    addr_decode #(
      .NoIndices  ( MaxPossibleId ),
      .NoRules    ( NumRules      ),
      .addr_t     ( id_in_t       ),
      .rule_t     ( rule_t        ),
      .idx_t      ( id_out_t      )
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
  end else if (RouteAlgo == SourceRouting) begin : gen_source_routing
    logic dec_error;
    always_comb begin
      dec_error = 1'b1;
      for (int unsigned i = 0; i < NumRules; i++) begin
        if (id_i == map_i[i].id) begin
          dec_error = 1'b0;
          id_o = map_i[i].idx;
          break;
        end
      end
    end
    `ASSERT(DecodeError, !dec_error)
  end else if (RouteAlgo == XYRouting) begin : gen_xy_bits_routing
    assign id_o.x = id_i[XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = id_i[XYAddrOffsetY +: $bits(id_o.y)];
  end else if (RouteAlgo == IdTable) begin : gen_id_bits_routing
    assign id_o = id_i[IdAddrOffset +: $bits(id_o)];
  end else begin : gen_error
    $fatal(1, "Routing algorithm not implemented");
  end

endmodule
