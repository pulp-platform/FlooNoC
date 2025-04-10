// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>

module floo_reduction_arbiter import floo_pkg::*;
#(
  /// Number of input ports
  parameter int unsigned NumRoutes  = 1,
  /// Type definitions
  parameter type         flit_t     = logic,
  parameter type         payload_t  = logic,
  parameter payload_t    NarrowRspMask = '0,
  parameter payload_t    WideRspMask = '0,
  parameter type         id_t       = logic
) (
  /// Current XY-coordinate of the router
  input  id_t                    xy_id_i,
  /// Input ports
  input  logic  [NumRoutes-1:0]  valid_i,
  output logic  [NumRoutes-1:0]  ready_o,
  input  flit_t [NumRoutes-1:0]  data_i,
  /// Output port
  output logic                   valid_o,
  input  logic                   ready_i,
  output flit_t                  data_o
);

  // calculated expected input source lists for each input flit
  logic [NumRoutes-1:0]  in_route_mask;

  typedef logic [cf_math_pkg::idx_width(NumRoutes)-1:0] arb_idx_t;
  arb_idx_t input_sel;

  // Use a leading zero counter to find the first valid input to reduce
  lzc #(
    .WIDTH(NumRoutes)
  ) i_lzc (
    .in_i  ( valid_i   ),
    .cnt_o ( input_sel ),
    .empty_o ()
  );

  floo_reduction_sync #(
    .NumRoutes ( NumRoutes ),
    .arb_idx_t ( arb_idx_t ),
    .flit_t    ( flit_t    ),
    .id_t      ( id_t      )
  ) i_reduction_sync (
    .sel_i            ( input_sel     ),
    .data_i           ( data_i        ),
    .valid_i          ( valid_i       ),
    .xy_id_i          ( xy_id_i       ),
    .valid_o          ( valid_o       ),
    .in_route_mask_o  ( in_route_mask )
  );

  payload_t ReduceMask;
  assign ReduceMask = data_i[input_sel].hdr.axi_ch==NarrowB? NarrowRspMask : WideRspMask;

  logic [1:0] resp;

  // Reduction operation
  always_comb begin : gen_reduced_B
    data_o = data_i[input_sel];
    // We check every input port from which we expect a response
    for (int i = 0; i < NumRoutes; i++) begin
      if(in_route_mask[i]) begin
        // For every bit that is set in the mask, we assemble the response
        automatic int j = 0;
        for (int k = 0; k < $bits(ReduceMask); k++) begin
          if (ReduceMask[k]) begin
            resp[j] = data_i[i].payload[k];
            j++;
          end
        end
        // If one of the responses is an error, we return an error
        if(resp == axi_pkg::RESP_SLVERR) begin
          data_o = data_i[i];
          break;
        end
      end
    end
  end

  // TODO(fischeti): Check with Chen
  assign ready_o = (ready_i & valid_o)? valid_i & in_route_mask : '0;

endmodule
