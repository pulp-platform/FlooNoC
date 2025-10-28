// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Chen Wu <chenwu@student.ethz.ch>
//         Raphael Roth <raroth@student.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

module floo_reduction_arbiter import floo_pkg::*;
#(
  /// Number of input ports
  parameter int unsigned NumRoutes            = 1,
  /// Collective ops configuration
  parameter collect_op_be_cfg_t  CollectOpCfg    = CollectiveSupportDefaultCfg,
  /// Type definitions
  parameter type         flit_t               = logic,
  parameter type         hdr_t                = logic,
  parameter type         id_t                 = logic,
  /// Do we support local loopback e.g. should the logic expect the local flit or not
  parameter bit          RdSupportLoopback    = 1'b0,
  /// AXI dependent parameter for collective support
  /// When performing collective, data bits need to be extracted from the payoload
  parameter bit          RdSupportAxi         = 1'b1,
  parameter axi_cfg_t    AxiCfg               = '0
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

  `FLOO_TYPEDEF_AXI_FROM_CFG(axi, AxiCfg)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, AxiCfg, hdr_t)

  // We calculte the different reduction in parallel and select the result at the output
  flit_t data_forward_flit;
  flit_t data_collectB;
  flit_t data_LSBAnd;

  collect_op_e incoming_red_op;

  // Logic bit to connect all LSB together
  logic lsb;
  logic [1:0] resp;

  // calculated expected input source lists for each input flit
  logic [NumRoutes-1:0][NumRoutes-1:0]  in_route_mask;
  logic [NumRoutes-1:0]                 red_valid_in;
  logic [NumRoutes-1:0][NumRoutes-1:0]  ready_out;

  typedef logic [cf_math_pkg::idx_width(NumRoutes)-1:0] arb_idx_t;
  arb_idx_t input_sel;

  // TODO (lleone): The handshake betwene the input and output shoudl be implemented with
  // a stream fork. The one in common cell is not suitable for this condition because
  // it connectes the input stream to ALL of output ports. We would need a stream fork
  // that connects the input stream to ANY of the output ports.
  assign ready_o = ready_out[input_sel];
  for (genvar i = 0; i < NumRoutes; i++) begin : gen_invalid_data
    // Compute list of possible input sources for each input port
    // This module determines which inputs are expected to participate in the reduction
    floo_route_xymask #(
      .NumRoutes ( NumRoutes ),
      .flit_t    ( flit_t    ),
      .id_t      ( id_t      ),
      .FwdMode   ( 0         ) // We enable the backward mode for reduction
    ) i_route_xymask (
      .channel_i    ( data_i[i]   ),
      .xy_id_i      ( xy_id_i         ),
      .route_sel_o  ( in_route_mask[i] )
    );

    floo_reduction_sync #(
      .NumRoutes          ( NumRoutes ),
      .RdSupportLoopback  ( RdSupportLoopback ),
      .arb_idx_t          ( arb_idx_t ),
      .flit_t             ( flit_t    ),
      .id_t               ( id_t      )
    ) i_reduction_sync (
      .sel_i            ( arb_idx_t'(i)    ),
      .data_i           ( data_i           ),
      .valid_i          ( valid_i          ),
      .ready_o          ( ready_out[i]     ),
      .xy_id_i          ( xy_id_i          ),
      .valid_o          ( red_valid_in[i]  ),
      .ready_i          ( ready_i          ),
      .in_route_mask_i  ( in_route_mask[i] )
    );
  end

  // Use a leading zero counter to find the first valid reduction input
  lzc #(
    .WIDTH(NumRoutes)
  ) i_lzc (
    .in_i  ( red_valid_in ),
    .cnt_o ( input_sel    ),
    .empty_o ()
  );

  // Select the incoming reduction operation
  assign incoming_red_op = data_i[input_sel].hdr.collective_op;

  // ----------------------------
  // Reduction op implementations
  // ----------------------------

  // TODO(lleone): Guard with a Cfg parameter that tells you which are the supported operations
  // Collect B response operation
  always_comb begin : gen_reduced_B
    data_collectB = data_i[input_sel];
    resp = '0;
    // We check every input port from which we expect a response
    for (int i = 0; i < NumRoutes; i++) begin
      if(in_route_mask[input_sel][i]) begin
        // Select only the bits of the payload that are part of the response
        // and check if at least one of the participants sent an error.
        resp = extractAxiBResp(data_i[i]);
        if(resp == axi_pkg::RESP_SLVERR) begin
          data_collectB = data_i[i];
          break;
        end
      end
    end
  end

  // Forward flits directly - Just choose to forward the selected one
  always_comb begin : gen_forward
    data_forward_flit = '0;
    if (CollectOpCfg.EnLSBAnd) data_forward_flit = data_i[input_sel];
  end

  // And all the LSB
  always_comb begin : gen_and_lsb
    data_LSBAnd = '0;
    if (CollectOpCfg.EnLSBAnd) begin
      data_LSBAnd = data_i[input_sel];
      lsb = 1'b1;

      // We check every input port from which we expect a response
      for (int i = 0; i < NumRoutes; i++) begin
        if(in_route_mask[input_sel][i]) begin
          // Extract the last bit from the data
          if(RdSupportAxi) begin
            axi_data_t axi_w_data;
            axi_w_data = extractAxiWData(data_i[i]);
            lsb &= axi_w_data[0];
          end
        end
      end

      // Assign the bit again
      if(RdSupportAxi) begin
        data_LSBAnd = insertAxiWlsb(data_LSBAnd, lsb);
      end
    end
  end

  // Select which parallel operation to output
  always_comb begin
    // Assign inital value
    data_o = '0;
    case ({incoming_red_op, 1'b1})
      {SelectAW, CollectOpCfg.EnLSBAnd}:  data_o = data_forward_flit;
      {LSBAnd,   CollectOpCfg.EnLSBAnd}:  data_o = data_LSBAnd;
      {CollectB, 1'b1}:                   data_o = data_collectB;
      default:;
    endcase
  end

  // Connect the valid and ready signals
  assign valid_o = red_valid_in[input_sel];
  // TODO (lleone): Delete this line
  // assign ready_o = (ready_i & valid_o) ? valid_i & in_route_mask[input_sel] : '0;

  // -----------------------------
  // AXI Specific Helper functions
  // -----------------------------

  //TODO(lleone): Move those functions into floo_pkg
  // Insert data into AXI specific W frame!
  function automatic flit_t insertAxiWlsb(flit_t metadata, logic data);
      floo_axi_w_flit_t w_flit;
      // Parse the entire flit
      w_flit = floo_axi_w_flit_t'(metadata);
      // Copy the new data
      w_flit.payload.data[0] = data;
      return flit_t'(w_flit);
  endfunction

  // Extract data from AXI specific W frame!
  function automatic axi_data_t extractAxiWData(flit_t metadata);
      floo_axi_w_flit_t w_flit;
      // Parse the entire flit
      w_flit = floo_axi_w_flit_t'(metadata);
      // Return the W data
      return w_flit.payload.data;
  endfunction

  // Extract B response from AXI specific B frame!
  function automatic axi_pkg::resp_t extractAxiBResp(flit_t metadata);
      floo_axi_b_flit_t b_flit;
      // Parse the entire flit
      b_flit = floo_axi_b_flit_t'(metadata);
      // Return the B response
      return b_flit.payload.resp;
  endfunction

endmodule
