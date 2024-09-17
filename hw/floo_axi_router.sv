// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

/// Wrapper of a multi-link router for single-AXI links
module floo_axi_router #(
  /// Config of the AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfg        = '0,
  /// Routing algorithm
  parameter floo_pkg::route_algo_e RouteAlgo  = floo_pkg::XYRouting,
  /// Number of input/output ports
  parameter int unsigned NumRoutes            = 0,
  /// Number of input ports
  parameter int unsigned NumInputs            = NumRoutes,
  /// Number of output ports
  parameter int unsigned NumOutputs           = NumRoutes,
  /// Input buffer depth
  parameter int unsigned InFifoDepth          = 0,
  /// Output buffer depth
  parameter int unsigned OutFifoDepth         = 0,
  /// Disable illegal connections in router
  /// (only applies for `RouteAlgo == XYRouting`)
  parameter bit          XYRouteOpt           = 1'b1,
  /// Node ID type
  parameter type id_t                         = logic,
  /// Header type
  parameter type hdr_t                        = logic,
  /// Number of rules in the route table
  /// (only used for `RouteAlgo == IdTable`)
  parameter int unsigned NumAddrRules         = 0,
  /// Address rule type
  /// (only used for `RouteAlgo == IdTable`)
  parameter type addr_rule_t                  = logic,
  /// Floo `req` link type
  parameter type floo_req_t                   = logic,
  /// Floo `rsp` link type
  parameter type floo_rsp_t                   = logic
) (
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   test_enable_i,
  /// Coordinate of the current node
  /// (only used for `RouteAlgo == XYRouting`)
  input  id_t id_i,
  /// Routing table
  /// (only used for `RouteAlgo == IdTable`)
  input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,
  /// Input and output links
  input   floo_req_t [NumInputs-1:0] floo_req_i,
  input   floo_rsp_t [NumOutputs-1:0] floo_rsp_i,
  output  floo_req_t [NumOutputs-1:0] floo_req_o,
  output  floo_rsp_t [NumInputs-1:0] floo_rsp_o
);

  typedef logic [AxiCfg.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfg.InIdWidth-1:0] axi_in_id_t;
  typedef logic [AxiCfg.UserWidth-1:0] axi_user_t;
  typedef logic [AxiCfg.DataWidth-1:0] axi_data_t;
  typedef logic [AxiCfg.DataWidth/8-1:0] axi_strb_t;

  // (Re-) definitons of `axi_in` and `floo` types, for transport
  `AXI_TYPEDEF_ALL_CT(axi, axi_req_t, axi_rsp_t, axi_addr_t, axi_in_id_t,
                      axi_data_t, axi_strb_t, axi_user_t)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi, AxiCfg, hdr_t)

  floo_req_chan_t [NumInputs-1:0] req_in;
  floo_rsp_chan_t [NumInputs-1:0] rsp_out;
  floo_req_chan_t [NumOutputs-1:0] req_out;
  floo_rsp_chan_t [NumOutputs-1:0] rsp_in;
  logic [NumInputs-1:0] req_valid_in, req_ready_out;
  logic [NumInputs-1:0] rsp_valid_out, rsp_ready_in;
  logic [NumOutputs-1:0] req_valid_out, req_ready_in;
  logic [NumOutputs-1:0] rsp_valid_in, rsp_ready_out;

  for (genvar i = 0; i < NumInputs; i++) begin : gen_chimney_req
    assign req_valid_in[i] = floo_req_i[i].valid;
    assign floo_req_o[i].ready = req_ready_out[i];
    assign req_in[i] = floo_req_i[i].req;
    assign floo_rsp_o[i].valid = rsp_valid_out[i];
    assign rsp_ready_in[i] = floo_rsp_i[i].ready;
    assign floo_rsp_o[i].rsp = rsp_out[i];
  end

  for (genvar i = 0; i < NumOutputs; i++) begin : gen_chimney_rsp
    assign floo_req_o[i].valid = req_valid_out[i];
    assign req_ready_in[i] = floo_req_i[i].ready;
    assign floo_req_o[i].req = req_out[i];
    assign rsp_valid_in[i] = floo_rsp_i[i].valid;
    assign floo_rsp_o[i].ready = rsp_ready_out[i];
    assign rsp_in[i] = floo_rsp_i[i].rsp;
  end

  floo_router #(
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .flit_t           ( floo_req_generic_flit_t ),
    .InFifoDepth      ( InFifoDepth             ),
    .OutFifoDepth     ( OutFifoDepth            ),
    .RouteAlgo        ( RouteAlgo               ),
    .XYRouteOpt       ( XYRouteOpt              ),
    .id_t             ( id_t                    ),
    .NumAddrRules     ( NumAddrRules            ),
    .addr_rule_t      ( addr_rule_t             )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i(id_i),
    .id_route_map_i,
    .valid_i        ( req_valid_in  ),
    .ready_o        ( req_ready_out ),
    .data_i         ( req_in        ),
    .valid_o        ( req_valid_out ),
    .ready_i        ( req_ready_in  ),
    .data_o         ( req_out       )
  );


  floo_router #(
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .InFifoDepth      ( InFifoDepth             ),
    .OutFifoDepth     ( OutFifoDepth            ),
    .RouteAlgo        ( RouteAlgo               ),
    .XYRouteOpt       ( XYRouteOpt              ),
    .flit_t           ( floo_rsp_generic_flit_t ),
    .id_t             ( id_t                    ),
    .NumAddrRules     ( NumAddrRules            ),
    .addr_rule_t      ( addr_rule_t             )
  ) i_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i(id_i),
    .id_route_map_i,
    .valid_i        ( rsp_valid_in  ),
    .ready_o        ( rsp_ready_out ),
    .data_i         ( rsp_in        ),
    .valid_o        ( rsp_valid_out ),
    .ready_i        ( rsp_ready_in  ),
    .data_o         ( rsp_out       )
  );

endmodule
