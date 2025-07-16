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
  parameter floo_pkg::axi_cfg_t AxiCfgN             = '0,
  /// Config of the wide AXI interfaces (see floo_pkg::axi_cfg_t for details)
  parameter floo_pkg::axi_cfg_t AxiCfgW             = '0,
  /// Routing algorithm
  parameter floo_pkg::route_algo_e RouteAlgo        = floo_pkg::XYRouting,
  /// Number of input/output ports
  parameter int unsigned NumRoutes                  = 0,
  /// Number of input ports
  parameter int unsigned NumInputs                  = NumRoutes,
  /// Number of output ports
  parameter int unsigned NumOutputs                 = NumRoutes,
  /// Input buffer depth
  parameter int unsigned InFifoDepth                = 0,
  /// Output buffer depth
  parameter int unsigned OutFifoDepth               = 0,
  /// Disable illegal connections in router
  /// (only applies for `RouteAlgo == XYRouting`)
  parameter bit          XYRouteOpt                 = 1'b1,
  /// Disables loopback connections
  parameter bit          NoLoopback                 = 1'b1,
  /// Enable multicast feature
  parameter bit          EnMultiCast                = 1'b0,
  /// Enable parallel reduction feature
  parameter bit          EnParallelReduction        = 1'b0,
  /// Enable offload reduction feature
  parameter bit          EnOffloadWideReduction     = 1'b0,
  /// Enable offload reduction on the narrow port
  parameter bit          EnOffloadNarrowReduction   = 1'b0,
  /// Node ID type
  parameter type id_t                               = logic,
  /// Header type
  parameter type hdr_t                              = logic,
  /// Number of rules in the route table
  /// (only used for `RouteAlgo == IdTable`)
  parameter int unsigned NumAddrRules               = 0,
  /// Address rule type
  /// (only used for `RouteAlgo == IdTable`)
  parameter type addr_rule_t                        = logic,
  /// Floo `req` link type
  parameter type floo_req_t                         = logic,
  /// Floo `rsp` link type
  parameter type floo_rsp_t                         = logic,
  /// Floo `wide` link type
  parameter type floo_wide_t                        = logic,
  /// Possible operation for offloading (must match type in header)
  parameter type RdWideOperation_t                  = logic,
  parameter type RdNarrowOperation_t                = logic,
  /// Data type of the offload reduction
  parameter type RdWideData_t                       = logic,
  parameter type RdNarrowData_t                     = logic,
  /// Parameter for the wide reduction configuration
  parameter floo_pkg::reduction_cfg_t RdWideCfg     = '0,
  /// Parameter for the narrow reduction configuration
  parameter floo_pkg::reduction_cfg_t RdNarrowCfg   = '0,
  /// Paramter for the response router
  parameter floo_pkg::reduction_cfg_t RdRespCfg     = '0
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
  input   floo_req_t [NumInputs-1:0]    floo_req_i,
  input   floo_rsp_t [NumOutputs-1:0]   floo_rsp_i,
  output  floo_req_t [NumOutputs-1:0]   floo_req_o,
  output  floo_rsp_t [NumInputs-1:0]    floo_rsp_o,
  input   floo_wide_t [NumRoutes-1:0]   floo_wide_i,
  output  floo_wide_t [NumRoutes-1:0]   floo_wide_o,
  /// Wide IF towards the offload logic
  output RdWideOperation_t              offload_wide_req_op_o,
  output RdWideData_t                   offload_wide_req_operand1_o,
  output RdWideData_t                   offload_wide_req_operand2_o,
  output logic                          offload_wide_req_valid_o,
  input logic                           offload_wide_req_ready_i,
  /// Wide IF from external FPU
  input RdWideData_t                    offload_wide_resp_result_i,
  input logic                           offload_wide_resp_valid_i,
  output logic                          offload_wide_resp_ready_o,
  /// Narrow IF towards the offload logic
  output RdNarrowOperation_t            offload_narrow_req_op_o,
  output RdNarrowData_t                 offload_narrow_req_operand1_o,
  output RdNarrowData_t                 offload_narrow_req_operand2_o,
  output logic                          offload_narrow_req_valid_o,
  input logic                           offload_narrow_req_ready_i,
  /// Narrow IF from external FPU
  input RdNarrowData_t                  offload_narrow_resp_result_i,
  input logic                           offload_narrow_resp_valid_i,
  output logic                          offload_narrow_resp_ready_o
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
  floo_wide_chan_t [NumRoutes-1:0] wide_in, wide_out;
  logic [NumInputs-1:0] req_valid_in, req_ready_out;
  logic [NumInputs-1:0] rsp_valid_out, rsp_ready_in;
  logic [NumOutputs-1:0] req_valid_out, req_ready_in;
  logic [NumOutputs-1:0] rsp_valid_in, rsp_ready_out;
  logic [NumRoutes-1:0] wide_valid_in, wide_valid_out;
  logic [NumRoutes-1:0] wide_ready_in, wide_ready_out;

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

  floo_router #(
    .NumInput             ( NumInputs                 ),
    .NumOutput            ( NumOutputs                ),
    .NumPhysChannels      ( 1                         ),
    .NumVirtChannels      ( 1                         ),
    .InFifoDepth          ( InFifoDepth               ),
    .OutFifoDepth         ( OutFifoDepth              ),
    .RouteAlgo            ( RouteAlgo                 ),
    .XYRouteOpt           ( XYRouteOpt                ),
    .NumAddrRules         ( NumAddrRules              ),
    .NoLoopback           ( NoLoopback                ),
    .EnMultiCast          ( EnMultiCast               ),
    .EnOffloadReduction   ( EnOffloadNarrowReduction | EnOffloadWideReduction ),
    .EnParallelReduction  ( EnParallelReduction       ),
    .id_t                 ( id_t                      ),
    .addr_rule_t          ( addr_rule_t               ),
    .flit_t               ( floo_req_generic_flit_t   ),
    .hdr_t                ( hdr_t                     ),
    .payload_t            ( floo_req_payload_t        ),
    .NarrowRspMask        ( NarrowBFlitMask.payload   ),
    .WideRspMask          ( WideBFlitMask.payload     ),
    .RdOperation_t        ( RdNarrowOperation_t       ),
    .RdData_t             ( RdNarrowData_t            ),
    .RdCfg                ( RdNarrowCfg               ),
    .AxiCfgOffload        ( AxiCfgN                   ),
    .AxiCfgParallel       ( AxiCfgN                   )
  ) i_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i                  ( id_i                            ),
    .id_route_map_i,
    .valid_i                  ( req_valid_in                    ),
    .ready_o                  ( req_ready_out                   ),
    .data_i                   ( req_in                          ),
    .valid_o                  ( req_valid_out                   ),
    .ready_i                  ( req_ready_in                    ),
    .data_o                   ( req_out                         ),
    .offload_req_op_o         ( offload_narrow_req_op_o         ),
    .offload_req_operand1_o   ( offload_narrow_req_operand1_o   ),
    .offload_req_operand2_o   ( offload_narrow_req_operand2_o   ),
    .offload_req_valid_o      ( offload_narrow_req_valid_o      ),
    .offload_req_ready_i      ( offload_narrow_req_ready_i      ),
    .offload_resp_result_i    ( offload_narrow_resp_result_i    ),
    .offload_resp_valid_i     ( offload_narrow_resp_valid_i     ),
    .offload_resp_ready_o     ( offload_narrow_resp_ready_o     )
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

  floo_router #(
    .NumInput             ( NumInputs               ),
    .NumOutput            ( NumOutputs              ),
    .NumPhysChannels      ( 1                       ),
    .NumVirtChannels      ( 1                       ),
    .InFifoDepth          ( InFifoDepth             ),
    .OutFifoDepth         ( OutFifoDepth            ),
    .RouteAlgo            ( RouteAlgo               ),
    .XYRouteOpt           ( XYRouteOpt              ),
    .NumAddrRules         ( NumAddrRules            ),
    .NoLoopback           ( NoLoopback              ),
    .EnMultiCast          ( EnOffloadNarrowReduction | EnOffloadWideReduction | EnParallelReduction ),
    .EnOffloadReduction   ( 1'b0                    ),
    .EnParallelReduction  ( EnMultiCast             ),
    .id_t                 ( id_t                    ),
    .addr_rule_t          ( addr_rule_t             ),
    .flit_t               ( floo_rsp_generic_flit_t ),
    .hdr_t                ( hdr_t                   ),
    .payload_t            ( floo_rsp_payload_t      ),
    .NarrowRspMask        ( floo_rsp_generic_flit_t'(NarrowBFlitMask.payload) ),
    .WideRspMask          ( floo_rsp_generic_flit_t'(WideBFlitMask.payload)   ),
    .RdCfg                ( RdRespCfg               ),
    .AxiCfgOffload        ( '0                      ),
    .AxiCfgParallel       ( AxiCfgN                 )
  ) i_rsp_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i                  ( id_i          ),
    .id_route_map_i,
    .valid_i                  ( rsp_valid_in  ),
    .ready_o                  ( rsp_ready_out ),
    .data_i                   ( rsp_in        ),
    .valid_o                  ( rsp_valid_out ),
    .ready_i                  ( rsp_ready_in  ),
    .data_o                   ( rsp_out       ),
    .offload_req_op_o         (               ),
    .offload_req_operand1_o   (               ),
    .offload_req_operand2_o   (               ),
    .offload_req_valid_o      (               ),
    .offload_req_ready_i      ( '0            ),
    .offload_resp_result_i    ( '0            ),
    .offload_resp_valid_i     ( '0            ),
    .offload_resp_ready_o     (               )
  );


  floo_router #(
    .NumRoutes            ( NumRoutes                 ),
    .NumPhysChannels      ( 1                         ),
    .NumVirtChannels      ( 1                         ),
    .InFifoDepth          ( InFifoDepth               ),
    .OutFifoDepth         ( OutFifoDepth              ),
    .RouteAlgo            ( RouteAlgo                 ),
    .XYRouteOpt           ( XYRouteOpt                ),
    .NumAddrRules         ( NumAddrRules              ),
    .NoLoopback           ( NoLoopback                ),
    .EnMultiCast          ( EnMultiCast               ),
    .EnOffloadReduction   ( EnOffloadWideReduction    ),
    .EnParallelReduction  ( 1'b0                      ),
    .id_t                 ( id_t                      ),
    .addr_rule_t          ( addr_rule_t               ),
    .flit_t               ( floo_wide_generic_flit_t  ),
    .hdr_t                ( hdr_t                     ),
    .RdOperation_t        ( RdWideOperation_t         ),
    .RdData_t             ( RdWideData_t              ),
    .RdCfg                ( RdWideCfg                 ),
    .AxiCfgOffload        ( AxiCfgW                   ),
    .AxiCfgParallel       ( '0                        )
  ) i_wide_req_floo_router (
    .clk_i,
    .rst_ni,
    .test_enable_i,
    .xy_id_i                  ( id_i                          ),
    .id_route_map_i,
    .valid_i                  ( wide_valid_in                 ),
    .ready_o                  ( wide_ready_out                ),
    .data_i                   ( wide_in                       ),
    .valid_o                  ( wide_valid_out                ),
    .ready_i                  ( wide_ready_in                 ),
    .data_o                   ( wide_out                      ),
    .offload_req_op_o         ( offload_wide_req_op_o         ),
    .offload_req_operand1_o   ( offload_wide_req_operand1_o   ),
    .offload_req_operand2_o   ( offload_wide_req_operand2_o   ),
    .offload_req_valid_o      ( offload_wide_req_valid_o      ),
    .offload_req_ready_i      ( offload_wide_req_ready_i      ),
    .offload_resp_result_i    ( offload_wide_resp_result_i    ),
    .offload_resp_valid_i     ( offload_wide_resp_valid_i     ),
    .offload_resp_ready_o     ( offload_wide_resp_ready_o     )
  );

endmodule
