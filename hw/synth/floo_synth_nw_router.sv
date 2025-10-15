// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

module floo_synth_nw_router
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
  import floo_synth_collective_pkg::*;
#(
  parameter int unsigned NumPorts = int'(floo_pkg::NumDirections),
  parameter int unsigned  EnCollective  = 0,
  parameter int unsigned  EnNarrOffload    = 0,
  parameter int unsigned  EnWideOffload    = 0
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  input  id_t id_i,
  input logic id_route_map_i,

  input  floo_req_t [NumPorts-1:0] floo_req_i,
  input  floo_rsp_t [NumPorts-1:0] floo_rsp_i,
  output floo_req_t [NumPorts-1:0] floo_req_o,
  output floo_rsp_t [NumPorts-1:0] floo_rsp_o,
  input  floo_wide_t [NumPorts-1:0] floo_wide_i,
  output floo_wide_t [NumPorts-1:0] floo_wide_o,
  /// Wide IF towards the offload logic
  output floo_pkg::collect_op_e              offload_wide_req_op_o,
  output RdDataWide_t                   offload_wide_req_operand1_o,
  output RdDataWide_t                   offload_wide_req_operand2_o,
  output logic                          offload_wide_req_valid_o,
  input logic                           offload_wide_req_ready_i,
  /// Wide IF from external FPU
  input RdDataWide_t                    offload_wide_resp_result_i,
  input logic                           offload_wide_resp_valid_i,
  output logic                          offload_wide_resp_ready_o,
  /// Narrow IF towards the offload logic
  output floo_pkg::collect_op_e            offload_narrow_req_op_o,
  output RdDataNarrow_t                 offload_narrow_req_operand1_o,
  output RdDataNarrow_t                 offload_narrow_req_operand2_o,
  output logic                          offload_narrow_req_valid_o,
  input logic                           offload_narrow_req_ready_i,
  /// Narrow IF from external FPU
  input RdDataNarrow_t                  offload_narrow_resp_result_i,
  input logic                           offload_narrow_resp_valid_i,
  output logic                          offload_narrow_resp_ready_o
);


localparam floo_pkg::collect_op_fe_cfg_t OpCfg = CollectOpCfgList[EnCollective];
localparam reduction_cfg_t NarrRedCfg = NarrRedCfgList[EnNarrOffload];
localparam reduction_cfg_t WideRedCfg = WideRedCfgList[EnWideOffload];

if (!EnCollective) begin
  floo_nw_router #(
    .AxiCfgN       ( AxiCfgN             ),
    .AxiCfgW       ( AxiCfgW             ),
    .RouteAlgo     ( RouteCfg.RouteAlgo  ),
    .NumRoutes     ( NumPorts            ),
    .NumAddrRules  ( 1                   ),
    .InFifoDepth   ( InFifoDepth         ),
    .OutFifoDepth  ( OutFifoDepth        ),
    .XYRouteOpt    ( 1'b0                ),
    .EnDecoupledRW ( 1'b0                ),
    .id_t          ( id_t                ),
    .hdr_t         ( hdr_t               ),
    .floo_req_t    ( floo_req_t          ),
    .floo_rsp_t    ( floo_rsp_t          ),
    .floo_wide_t   ( floo_wide_t         )
  ) i_floo_nw_router (
    .clk_i          ( clk_i           ),
    .rst_ni         ( rst_ni          ),
    .test_enable_i  ( test_enable_i   ),
    .id_i           ( id_i            ),
    .id_route_map_i ( id_route_map_i  ),
    .floo_req_i     ( floo_req_i      ),
    .floo_rsp_i     ( floo_rsp_i      ),
    .floo_req_o     ( floo_req_o      ),
    .floo_rsp_o     ( floo_rsp_o      ),
    .floo_wide_i    ( floo_wide_i     ),
    .floo_wide_o    ( floo_wide_o     ),
    .offload_wide_req_op_o          (),
    .offload_wide_req_operand1_o    (),
    .offload_wide_req_operand2_o    (),
    .offload_wide_req_valid_o       (),
    .offload_wide_req_ready_i       ('0),
    .offload_wide_resp_result_i     ('0),
    .offload_wide_resp_valid_i      ('0),
    .offload_wide_resp_ready_o      (),
    // Narrow Reduction offload port
    .offload_narrow_req_op_o        (),
    .offload_narrow_req_operand1_o  (),
    .offload_narrow_req_operand2_o  (),
    .offload_narrow_req_valid_o     (),
    .offload_narrow_req_ready_i     ('0),
    .offload_narrow_resp_result_i   ('0),
    .offload_narrow_resp_valid_i    ('0),
    .offload_narrow_resp_ready_o    ()
  );
end else begin
  floo_nw_router #(
    .AxiCfgN      ( AxiCfgN             ),
    .AxiCfgW      ( AxiCfgW             ),
    .RouteAlgo    ( RouteCfg.RouteAlgo  ),
    .NumRoutes    ( NumPorts            ),
    .NumAddrRules ( 1                   ),
    .InFifoDepth  ( InFifoDepth         ),
    .OutFifoDepth ( OutFifoDepth        ),
    .XYRouteOpt   ( 1'b0                ),
    .NoLoopback   (1'b0),
    .EnDecoupledRW (1'b0),
    .id_t         ( id_t                ),
    .hdr_t        ( hdr_coll_t          ),
    .floo_req_t   ( floo_req_t          ),
    .floo_rsp_t   ( floo_rsp_t          ),
    .floo_wide_t  ( floo_wide_t         ),
    .RdWideOperation_t        (floo_pkg::collect_op_e),
    .RdNarrowOperation_t      (floo_pkg::collect_op_e),
    .RdWideData_t             (RdDataWide_t),
    .RdNarrowData_t           (RdDataNarrow_t),
    .CollectiveOpCfg          (OpCfg),          // To be modified for different synth cfg results
    .RdWideCfg                (WideRedCfg),     // To be modified for different synth cfg results
    .RdNarrowCfg              (NarrRedCfg),   // To be modified for different synth cfg results
    .RdRespCfg                (ResponseReductionCfg)
  ) i_floo_nw_router (
    .clk_i          ( clk_i           ),
    .rst_ni         ( rst_ni          ),
    .test_enable_i  ( test_enable_i   ),
    .id_i           ( id_i            ),
    .id_route_map_i ( id_route_map_i  ),
    .floo_req_i     ( floo_req_i      ),
    .floo_rsp_i     ( floo_rsp_i      ),
    .floo_req_o     ( floo_req_o      ),
    .floo_rsp_o     ( floo_rsp_o      ),
    .floo_wide_i    ( floo_wide_i     ),
    .floo_wide_o    ( floo_wide_o     ),
    .offload_wide_req_op_o          (offload_wide_req_op_o),
    .offload_wide_req_operand1_o    (offload_wide_req_operand1_o),
    .offload_wide_req_operand2_o    (offload_wide_req_operand2_o),
    .offload_wide_req_valid_o       (offload_wide_req_valid_o),
    .offload_wide_req_ready_i       (offload_wide_req_ready_i),
    .offload_wide_resp_result_i     (offload_wide_resp_result_i),
    .offload_wide_resp_valid_i      (offload_wide_resp_valid_i),
    .offload_wide_resp_ready_o      (offload_wide_resp_ready_o),
    // Narrow Reduction offload port
    .offload_narrow_req_op_o        (offload_narrow_req_op_o),
    .offload_narrow_req_operand1_o  (offload_narrow_req_operand1_o),
    .offload_narrow_req_operand2_o  (offload_narrow_req_operand2_o),
    .offload_narrow_req_valid_o     (offload_narrow_req_valid_o),
    .offload_narrow_req_ready_i     (offload_narrow_req_ready_i),
    .offload_narrow_resp_result_i   (offload_narrow_resp_result_i),
    .offload_narrow_resp_valid_i    (offload_narrow_resp_valid_i),
    .offload_narrow_resp_ready_o    (offload_narrow_resp_ready_o)
  );
end


endmodule
