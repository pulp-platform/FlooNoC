// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lorenzo Leone <lleone@iis.ee.ethz.ch>
// Chen Wu <chenwu@student.ethz.ch>
//
// This module computes the mask to be injected into the NoC
// for multicast transactions. It receives the ID of the
// destination rule and uses a dedicated decoder to access the
// common SAM. It then reads the address mask offsets to identify
// which bits of the address rule can be masked and finally
// evaluates the ID mask.

`include "common_cells/assertions.svh"

module floo_mask_translation
    import floo_pkg::*;
#(
  /// The route config
  parameter      floo_pkg::route_cfg_t RouteCfg = '0,
  parameter bit  UseIdTable = RouteCfg.UseIdTable,
  parameter type id_t = logic,
  /// The type of the address
  parameter type addr_t = logic,
  /// The type of the address rules
  parameter type addr_rule_t = logic,
  /// The System Address Map
  parameter addr_rule_t [RouteCfg.NumSamRules-1:0] Sam,
  /// The type of the offset + len to identify which bits in the address can be masked
  parameter type mask_sel_t = logic
) (
  input  id_t   id_i,
  input  addr_t mask_i,
  output id_t   mask_o
);

  localparam int unsigned AddrWidth = $bits(addr_t);

  if (RouteCfg.UseIdTable &&
     (RouteCfg.RouteAlgo == floo_pkg::XYRouting)) begin: gen_mcast_addr_mask

    logic mask_dec_error;
    mask_sel_t x_mask_sel, y_mask_sel;
    addr_t x_addr_mask, y_addr_mask;

    floo_mask_decode #(
      .NumMaskRules   ( RouteCfg.NumSamRules ),
      .id_t           ( id_t                 ),
      .addr_rule_t    ( addr_rule_t          ),
      .mask_sel_t     ( mask_sel_t           )
    ) i_mask_decode   (
      .id_i           ( id_i            ),
      .addr_map_i     ( Sam             ),
      .mask_x_mask_o  ( x_mask_sel      ),
      .mask_y_mask_o  ( y_mask_sel      ),
      .dec_error_o    ( mask_dec_error  )
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


endmodule
