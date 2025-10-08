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
  /// Enable decoupling between Read and Write wide channels using virtual channels
  parameter bit          EnDecoupledRW              = 1'b0,
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
  /// Parameter to define which type of collective operation support
  parameter floo_pkg::collect_op_cfg_t CollectiveOpCfg = floo_pkg::CollectiveOpDefaultCfg,
  /// Parameter for the wide reduction configuration
  parameter floo_pkg::reduction_cfg_t RdWideCfg     = floo_pkg::ReductionDefaultCfg,
  /// Parameter for the narrow reduction configuration
  parameter floo_pkg::reduction_cfg_t RdNarrowCfg   = floo_pkg::ReductionDefaultCfg,
  /// Paramter for the response router
  parameter floo_pkg::reduction_cfg_t RdRespCfg     = floo_pkg::ReductionDefaultCfg
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

  // Local parameters to properly configure collective operation support
  // hiding the complexity to the user
  localparam int unsigned WideVirtChannel = (EnDecoupledRW) ? 2 : 1;

  localparam floo_pkg::collective_cfg_t CollectiveReqCfg = '{
    OpCfg: '{
      EnNarrowMulticast : floo_pkg::is_en_collective(CollectiveOpCfg),
      EnWideMulticast   : 1'b0,
      EnLSBAnd          : CollectiveOpCfg.EnLSBAnd,
      EnF_Add           : 1'b0,
      EnF_Mul           : 1'b0,
      EnF_Min           : 1'b0,
      EnF_Max           : 1'b0,
      EnA_Add           : CollectiveOpCfg.EnA_Add,
      EnA_Mul           : CollectiveOpCfg.EnA_Mul,
      EnA_Min_S         : CollectiveOpCfg.EnA_Min_S,
      EnA_Min_U         : CollectiveOpCfg.EnA_Min_U,
      EnA_Max_S         : CollectiveOpCfg.EnA_Max_S,
      EnA_Max_U         : CollectiveOpCfg.EnA_Max_U
    },
    RedCfg: RdNarrowCfg
  };

  localparam floo_pkg::collective_cfg_t CollectiveRspCfg = '{
    OpCfg: '{
      EnNarrowMulticast : floo_pkg::is_en_narrow_reduction(CollectiveOpCfg) |
                          floo_pkg::is_en_wide_reduction(CollectiveOpCfg),
      EnWideMulticast   : 1'b0,
      EnLSBAnd          : CollectiveOpCfg.EnNarrowMulticast |
                          CollectiveOpCfg.EnWideMulticast,
      EnF_Add           : 1'b0,
      EnF_Mul           : 1'b0,
      EnF_Min           : 1'b0,
      EnF_Max           : 1'b0,
      EnA_Add           : 1'b0,
      EnA_Mul           : 1'b0,
      EnA_Min_S         : 1'b0,
      EnA_Min_U         : 1'b0,
      EnA_Max_S         : 1'b0,
      EnA_Max_U         : 1'b0
    },
    RedCfg: RdRespCfg
  };

  localparam floo_pkg::collective_cfg_t CollectiveWideCfg = '{
    OpCfg: '{
      EnNarrowMulticast : 1'b0,
      EnWideMulticast   : CollectiveOpCfg.EnWideMulticast,
      EnLSBAnd          : 1'b0,
      EnF_Add           : CollectiveOpCfg.EnF_Add,
      EnF_Mul           : CollectiveOpCfg.EnF_Mul,
      EnF_Min           : CollectiveOpCfg.EnF_Min,
      EnF_Max           : CollectiveOpCfg.EnF_Max,
      EnA_Add           : 1'b0,
      EnA_Mul           : 1'b0,
      EnA_Min_S         : 1'b0,
      EnA_Min_U         : 1'b0,
      EnA_Max_S         : 1'b0,
      EnA_Max_U         : 1'b0
    },
    RedCfg: RdWideCfg
  };

  floo_req_chan_t [NumInputs-1:0] req_in;
  floo_rsp_chan_t [NumInputs-1:0] rsp_out;
  floo_req_chan_t [NumOutputs-1:0] req_out;
  floo_rsp_chan_t [NumOutputs-1:0] rsp_in;
  floo_wide_chan_t [NumRoutes-1:0] wide_in, wide_out;
  logic [NumInputs-1:0] req_valid_in, req_ready_out;
  logic [NumInputs-1:0] rsp_valid_out, rsp_ready_in;
  logic [NumOutputs-1:0] req_valid_out, req_ready_in;
  logic [NumOutputs-1:0] rsp_valid_in, rsp_ready_out;
  logic [NumRoutes-1:0][WideVirtChannel-1:0] wide_valid_in, wide_valid_out;
  logic [NumRoutes-1:0][WideVirtChannel-1:0] wide_ready_in, wide_ready_out;

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
    .id_t                 ( id_t                      ),
    .addr_rule_t          ( addr_rule_t               ),
    .flit_t               ( floo_req_generic_flit_t   ),
    .hdr_t                ( hdr_t                     ),
    .RdOperation_t        ( RdNarrowOperation_t       ),
    .RdData_t             ( RdNarrowData_t            ),
    .CollectiveCfg        ( CollectiveReqCfg          ),
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
    .id_t                 ( id_t                    ),
    .addr_rule_t          ( addr_rule_t             ),
    .flit_t               ( floo_rsp_generic_flit_t ),
    .hdr_t                ( hdr_t                   ),
    .CollectiveCfg        ( CollectiveRspCfg        ),
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
    .NumVirtChannels      ( WideVirtChannel           ),
    .InFifoDepth          ( InFifoDepth               ),
    .OutFifoDepth         ( OutFifoDepth              ),
    .RouteAlgo            ( RouteAlgo                 ),
    .XYRouteOpt           ( XYRouteOpt                ),
    .NumAddrRules         ( NumAddrRules              ),
    .NoLoopback           ( NoLoopback                ),
    .EnCollVirtChannel    ( EnDecoupledRW             ),
    .id_t                 ( id_t                      ),
    .addr_rule_t          ( addr_rule_t               ),
    .flit_t               ( floo_wide_generic_flit_t  ),
    .hdr_t                ( hdr_t                     ),
    .RdOperation_t        ( RdWideOperation_t         ),
    .RdData_t             ( RdWideData_t              ),
    .CollectiveCfg        ( CollectiveWideCfg         ),
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
