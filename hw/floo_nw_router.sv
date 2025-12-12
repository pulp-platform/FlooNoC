// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"
`include "common_cells/registers.svh"

/// Wrapper of a multi-link router for narrow and wide links
module floo_nw_router #(
  /// Config of the narrow AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfgN       = '0,
  /// Config of the wide AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfgW       = '0,
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
  /// Enable decoupling between Read and Write WIDE channels using virtual channels
  /// assumed that write transactions are alwasy on VC0.
  parameter int unsigned  NumWideVirtChannels       = 32'd1,
  parameter int unsigned  NumWidePhysChannels       = 32'd1,
  parameter floo_pkg::vc_impl_e VcImpl              = floo_pkg::VcNaive,
  /// Enable multicast feature
  parameter bit          EnMultiCast          = 1'b0,
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
  parameter type floo_rsp_t                   = logic,
  /// Floo `wide` link type
  parameter type floo_wide_t                  = logic
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
  output  floo_rsp_t [NumInputs-1:0] floo_rsp_o,
  input   floo_wide_t [NumRoutes-1:0] floo_wide_i,
  output  floo_wide_t [NumRoutes-1:0] floo_wide_o
);

  typedef logic [AxiCfgN.AddrWidth-1:0] axi_addr_t;
  typedef logic [AxiCfgN.InIdWidth-1:0] axi_narrow_in_id_t;
  typedef logic [AxiCfgN.UserWidth-1:0] axi_narrow_user_t;
  typedef logic [AxiCfgN.DataWidth-1:0] axi_narrow_data_t;
  typedef logic [AxiCfgN.DataWidth/8-1:0] axi_narrow_strb_t;
  typedef logic [AxiCfgW.InIdWidth-1:0] axi_wide_in_id_t;
  typedef logic [AxiCfgW.UserWidth-1:0] axi_wide_user_t;
  typedef logic [AxiCfgW.DataWidth-1:0] axi_wide_data_t;
  typedef logic [AxiCfgW.DataWidth/8-1:0] axi_wide_strb_t;

  // (Re-) definitons of `axi_in` and `floo` types, for transport
  `AXI_TYPEDEF_ALL_CT(axi_narrow, axi_narrow_req_t, axi_narrow_rsp_t, axi_addr_t,
      axi_narrow_in_id_t, axi_narrow_data_t, axi_narrow_strb_t, axi_narrow_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide, axi_wide_req_t, axi_wide_rsp_t, axi_addr_t,
      axi_wide_in_id_t, axi_wide_data_t, axi_wide_strb_t, axi_wide_user_t)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow, axi_wide, AxiCfgN, AxiCfgW, hdr_t)

  floo_req_chan_t [NumInputs-1:0] req_in;
  floo_rsp_chan_t [NumInputs-1:0] rsp_out;
  floo_req_chan_t [NumOutputs-1:0] req_out;
  floo_rsp_chan_t [NumOutputs-1:0] rsp_in;
  floo_wide_chan_t [NumRoutes-1:0][NumWidePhysChannels-1:0] wide_in;
  floo_wide_chan_t [NumRoutes-1:0][NumWidePhysChannels-1:0] wide_out;
  logic [NumInputs-1:0] req_valid_in, req_ready_out;
  logic [NumInputs-1:0] rsp_valid_out, rsp_ready_in;
  logic [NumOutputs-1:0] req_valid_out, req_ready_in;
  logic [NumOutputs-1:0] rsp_valid_in, rsp_ready_out;
  logic [NumRoutes-1:0][NumWideVirtChannels-1:0] wide_valid_in, wide_valid_out;
  logic [NumRoutes-1:0][NumWideVirtChannels-1:0] wide_ready_in, wide_ready_out;
  logic [NumRoutes-1:0][NumWideVirtChannels-1:0] wide_credit_in, wide_credit_out;

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

  for (genvar i = 0; i < NumRoutes; i++) begin : gen_chimney_wide
    assign wide_valid_in[i] = floo_wide_i[i].valid;
    assign floo_wide_o[i].ready = wide_ready_out[i];
    assign wide_in[i] = floo_wide_i[i].wide;
    assign floo_wide_o[i].valid = wide_valid_out[i];
    assign wide_ready_in[i] = floo_wide_i[i].ready;
    assign floo_wide_o[i].wide = wide_out[i];
  end

  // Generation of credit based conenctions only when necessary
  if (VcImpl == floo_pkg::VcCreditBased) begin: gen_credit_connections
    // Narrow lreq inks never rely on credit based flow
    for (genvar i = 0; i < NumInputs; i++) begin: gen_credit_tied_zero_req
      assign floo_req_o[i].credit = '0;
    end
    // Narrow rsp links never rely on credit based flow
    for (genvar i = 0; i < NumOutputs; i++) begin: gen_credit_tied_zero_rsp
      assign floo_rsp_o[i].credit = '0;
    end
    // Wide links credit connections
    for (genvar i = 0; i < NumRoutes; i++) begin: gen_credit_wide
      assign floo_wide_o[i].credit = wide_credit_out[i];
      assign wide_credit_in[i] = floo_wide_i[i].credit;
    end
  end else begin: gen_no_credit_connections
    assign wide_credit_in = '0;
  end

  floo_router #(
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .InFifoDepth      ( InFifoDepth             ),
    .OutFifoDepth     ( OutFifoDepth            ),
    .RouteAlgo        ( RouteAlgo               ),
    .XYRouteOpt       ( XYRouteOpt              ),
    .NumAddrRules     ( NumAddrRules            ),
    .NoLoopback       ( 1'b1                    ),
    .EnMultiCast      ( EnMultiCast             ),
    .EnReduction      ( 1'b0                    ),
    .id_t             ( id_t                    ),
    .addr_rule_t      ( addr_rule_t             ),
    .flit_t           ( floo_req_generic_flit_t )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i        ( id_i ),
    .id_route_map_i,
    .valid_i        ( req_valid_in  ),
    .ready_o        ( req_ready_out ),
    .data_i         ( req_in        ),
    .credit_i       ( '0            ),
    .valid_o        ( req_valid_out ),
    .ready_i        ( req_ready_in  ),
    .data_o         ( req_out       ),
    .credit_o       ( /*unused */   )
  );

  // We construct the masks for the narrow and wide B responses here.
  // Every bit of the payload is set to 0, except for the bits that
  // correspond to the resp field.
  localparam axi_narrow_b_chan_t NarrowBMask = '{resp: 2'b11, default: '0};
  localparam floo_axi_narrow_b_flit_t NarrowBFlitMask = '{
    payload: NarrowBMask,
    hdr: '0,
    rsvd: '0
  };
  localparam axi_narrow_b_chan_t WideBMask = '{resp: 2'b11, default: '0};
  localparam floo_axi_wide_b_flit_t WideBFlitMask = '{
    payload: WideBMask,
    hdr: '0,
    rsvd: '0
  };

  // Enable reduction for the B response.
  // Disable multicast for the B response.
  floo_router #(
    .NumInput         ( NumInputs               ),
    .NumOutput        ( NumOutputs              ),
    .NumPhysChannels  ( 1                       ),
    .NumVirtChannels  ( 1                       ),
    .InFifoDepth      ( InFifoDepth             ),
    .OutFifoDepth     ( OutFifoDepth            ),
    .RouteAlgo        ( RouteAlgo               ),
    .XYRouteOpt       ( XYRouteOpt              ),
    .NumAddrRules     ( NumAddrRules            ),
    .NoLoopback       ( 1'b1                    ),
    .EnMultiCast      ( 1'b0                    ),
    .EnReduction      ( EnMultiCast             ),
    .id_t             ( id_t                    ),
    .addr_rule_t      ( addr_rule_t             ),
    .flit_t           ( floo_rsp_generic_flit_t ),
    .payload_t        ( floo_rsp_payload_t      ),
    .NarrowRspMask    ( floo_rsp_generic_flit_t'(NarrowBFlitMask.payload) ),
    .WideRspMask      ( floo_rsp_generic_flit_t'(WideBFlitMask.payload)   )
  ) i_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i        ( id_i ),
    .id_route_map_i,
    .valid_i        ( rsp_valid_in  ),
    .ready_o        ( rsp_ready_out ),
    .data_i         ( rsp_in        ),
    .credit_i       ( '0            ),
    .valid_o        ( rsp_valid_out ),
    .ready_i        ( rsp_ready_in  ),
    .data_o         ( rsp_out       ),
    .credit_o       ( /*unused */   )
  );


  floo_router #(
    .NumRoutes        ( NumRoutes                 ),
    .NumPhysChannels  ( NumWidePhysChannels       ),
    .NumVirtChannels  ( NumWideVirtChannels       ),
    .InFifoDepth      ( InFifoDepth               ),
    .OutFifoDepth     ( OutFifoDepth              ),
    .RouteAlgo        ( RouteAlgo                 ),
    .XYRouteOpt       ( XYRouteOpt                ),
    .NumAddrRules     ( NumAddrRules              ),
    .NoLoopback       ( 1'b1                      ),
    .VcImpl           ( VcImpl                    ),
    .EnMultiCast      ( EnMultiCast               ),
    .EnReduction      ( 1'b0                      ),
    .id_t             ( id_t                      ),
    .addr_rule_t      ( addr_rule_t               ),
    .flit_t           ( floo_wide_generic_flit_t  )
  ) i_wide_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i        ( id_i ),
    .id_route_map_i,
    .valid_i        ( wide_valid_in   ),
    .ready_o        ( wide_ready_out  ),
    .data_i         ( wide_in         ),
    .credit_i       ( wide_credit_in  ),
    .valid_o        ( wide_valid_out  ),
    .ready_i        ( wide_ready_in   ),
    .data_o         ( wide_out        ),
    .credit_o       ( wide_credit_out )
  );

endmodule
