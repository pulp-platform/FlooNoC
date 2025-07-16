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
  /// Enable Parallel Reduction
  parameter bit          EnParallelReduction  = 1'b0,
  /// Type definitions
  parameter type         flit_t               = logic,
  parameter type         hdr_t                = logic,
  parameter type         payload_t            = logic,
  // Masks used to select which bits of the payload are part of the response,
  // allowing extraction of relevant bits and detection of any participant errors.
  parameter payload_t    NarrowRspMask        = '0,
  parameter payload_t    WideRspMask          = '0,
  parameter type         id_t                 = logic,
  /// Do we support local loopback e.g. should the logic expect the local flit or not
  parameter bit          RdSupportLoopback    = 1'b0,
  /// AXI dependent parameter
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

  // Generate the AXI specific types
  typedef logic [AxiCfg.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfg.InIdWidth-1:0] axi_in_id_t;
  typedef logic [AxiCfg.OutIdWidth-1:0] axi_out_id_t;
  typedef logic [AxiCfg.UserWidth-1:0] axi_user_t;
  typedef logic [AxiCfg.DataWidth-1:0] axi_data_t;
  typedef logic [AxiCfg.DataWidth/8-1:0] axi_strb_t;

  `AXI_TYPEDEF_ALL_CT(axi, axi_req_t, axi_rsp_t, axi_addr_t, axi_in_id_t, axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_AW_CHAN_T(axi_out_aw_chan_t, axi_addr_t, axi_out_id_t, axi_user_t)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi, AxiCfg, hdr_t)

  // We calculte the different reduction in parallel and select the result at the output
  flit_t data_forward_flit;
  flit_t data_collectB;
  flit_t data_LSBAnd;

  // Logic bit to connect all LSB together
  logic lsb;
  logic [1:0] resp;

  // Reduction mask for either the narrow or wide link
  payload_t ReduceMask;

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
    .NumRoutes          ( NumRoutes ),
    .RdSupportLoopback  ( RdSupportLoopback ),
    .arb_idx_t          ( arb_idx_t ),
    .flit_t             ( flit_t    ),
    .id_t               ( id_t      )
  ) i_reduction_sync (
    .sel_i            ( input_sel     ),
    .data_i           ( data_i        ),
    .valid_i          ( valid_i       ),
    .xy_id_i          ( xy_id_i       ),
    .valid_o          ( valid_o       ),
    .in_route_mask_o  ( in_route_mask )
  );

  // Set the reduction mask for either the narrow or the wide link
  assign ReduceMask = data_i[input_sel].hdr.axi_ch==NarrowB? NarrowRspMask : WideRspMask;

  // ----------------------------
  // Reduction op implementations
  // ----------------------------

  // Collect B response operation
  always_comb begin : gen_reduced_B
    data_collectB = data_i[input_sel];
    resp = '0;
    // We check every input port from which we expect a response
    for (int i = 0; i < NumRoutes; i++) begin
      if(in_route_mask[i]) begin
        // Select only the bits of the payload that are part of the response
        // and check if at least one of the participants sent an error.
        automatic int j = 0;
        for (int k = 0; k < $bits(ReduceMask); k++) begin
          if (ReduceMask[k]) begin
            resp[j] = data_i[i].payload[k];
            j++;
          end
        end
        // If one of the responses is an error, we return an error
        // otherwise we return the first response
        if(resp == axi_pkg::RESP_SLVERR) begin
          data_collectB = data_i[i];
          break;
        end
      end
    end
  end

  // Forward flits directly - Just choose to forward the selected one
  always_comb begin : gen_forward
    data_forward_flit = data_i[input_sel];
  end

  // And all the LSB
  always_comb begin : gen_and_lsb
    data_LSBAnd = data_i[input_sel];
    lsb = 1'b1;

    // We check every input port from which we expect a response
    for (int i = 0; i < NumRoutes; i++) begin
      if(in_route_mask[i]) begin
        // Extract the last bit from the data
        if(RdSupportAxi) begin
          lsb = lsb & extractAXIWlsb(data_i[i]);
        end
      end
    end

    // Assign the bit again
    if(RdSupportAxi) begin
      data_LSBAnd = insertAXIWlsb(data_LSBAnd, lsb);
    end
  end

  // If we support more than the inital parallel reduction
  if(EnParallelReduction) begin
    always_comb begin
      // Assign inital value
      data_o = '0;
      if(data_i[input_sel].hdr.reduction_op == SelectAW) begin
        // AW flit dedected
        data_o = data_forward_flit;
      end else if(data_i[input_sel].hdr.reduction_op == CollectB) begin
        // Collect B flit dedected
        data_o = data_collectB;
      end else if(data_i[input_sel].hdr.reduction_op == LSBAnd) begin
        // LSB And flit dedected
        data_o = data_LSBAnd;
      end
    end
  end else begin
    assign data_o = data_collectB;
  end

  // Connect the ready signal
  assign ready_o = (ready_i & valid_o)? valid_i & in_route_mask : '0;

  // AXI Specific function!
  // Insert data into AXI specific W frame!
  function automatic flit_t insertAXIWlsb(flit_t metadata, logic data);
      floo_axi_w_flit_t w_flit;
      // Parse the entire flit
      w_flit = floo_axi_w_flit_t'(metadata);
      // Copy the new data
      w_flit.payload.data[0] = data;
      return flit_t'(w_flit);
  endfunction

  // Extract data from AXI specific W frame!
  function automatic logic extractAXIWlsb(flit_t metadata);
      floo_axi_w_flit_t w_flit;
      // Parse the entire flit
      w_flit = floo_axi_w_flit_t'(metadata);
      // Return the W data
      return w_flit.payload.data[0];
  endfunction

endmodule
