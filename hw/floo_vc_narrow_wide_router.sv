// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>
// Lukas Berner <bernerl@student.ethz.ch>

/// Wrapper of a multi-link router for narrow and wide links
module floo_vc_narrow_wide_router
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
  #(
    parameter int           NumPorts                    = 5,
    parameter int           NumLocalPorts               = NumPorts - 4,
    parameter int           NumVC           [NumPorts]  =
            {1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 4+NumLocalPorts-1},
            // Num VC from dir N,E,S,W,L0(,L1,L2,L3): 1313 for XY routing
    parameter int           NumVCMax                    = NumPorts - 1,
    // NumVCWidth: needs to be 3 in routers with more than 1 local ports
    parameter int           NumVCWidth                  = 3,
    // set this to 3 towards routers with more than 1 local ports: towards N,E,S,W,L0(,L1,L2,L3)
    parameter int           NumVCToOut      [NumPorts]  = {2,4,2,4,1},
    parameter int           NumVCToOutMax               = 4,
    parameter int           NumVCWidthToOutMax          = 2,

    parameter int           NumInputSaGlobal[NumPorts]  =
      {3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 4+NumLocalPorts-1},
      // to dir N,E,S,W,L0(,L1,L2,L3)
    parameter int           VCDepth                     = 2,
    parameter int           VCDepthWidth                = $clog2(VCDepth+1),
    parameter int           CreditShortcut              = 1, // not used if SingleStage
    parameter int           AllowVCOverflow             = 1, // 1: FVADA, 0: fixed VC per direction
    parameter int           FixedWormholeVC             = 1,
    parameter int           WormholeVCId    [NumPorts]  = {0,1,0,2,0}, // as seen from output port
    parameter int           WormholeVCDepth             = 3,
    parameter int           AllowOverflowFromDeeperVC   = 1, //overriden if AllowVCOverflow is 0
    parameter int           UpdateRRArbIfNotSent        = 0,
    parameter int           SingleStage                 = 0, // 0: standard 2 stage, 1: single stage

    // Route Algorithm stuff
    parameter route_algo_e  RouteAlgo                   = XYRouting,
    /// Used for ID-based and XY routing
    parameter int unsigned  IdWidth                     = 1,
    parameter type          id_t                        = logic[IdWidth-1:0],
    /// Used for ID-based routing
    parameter int unsigned  NumAddrRules                = 0,
    parameter type          addr_rule_t                 = logic
) (
  input  logic   clk_i,
  input  logic   rst_ni,

  input  id_t id_i,
  input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,

  input   floo_vc_req_t   [NumPorts-1:0] floo_req_i,
  output  floo_vc_req_t   [NumPorts-1:0] floo_req_o,
  input   floo_vc_rsp_t   [NumPorts-1:0] floo_rsp_i,
  output  floo_vc_rsp_t   [NumPorts-1:0] floo_rsp_o,
  input   floo_vc_wide_t  [NumPorts-1:0] floo_wide_i,
  output  floo_vc_wide_t  [NumPorts-1:0] floo_wide_o
);

  floo_req_chan_t [NumPorts-1:0] req_in, req_out;
  floo_rsp_chan_t [NumPorts-1:0] rsp_in, rsp_out;
  floo_wide_chan_t [NumPorts-1:0] wide_in, wide_out;
  logic [NumPorts-1:0]  req_v_in,   req_v_out,  req_credit_valid_in,  req_credit_valid_out,
                        rsp_v_in,   rsp_v_out,  rsp_credit_valid_in,  rsp_credit_valid_out,
                        wide_v_in,  wide_v_out, wide_credit_valid_in, wide_credit_valid_out;
  vc_id_t [NumPorts-1:0]  req_credit_id_in, req_credit_id_out,
                          rsp_credit_id_in, rsp_credit_id_out,
                          wide_credit_id_in, wide_credit_id_out;

  for (genvar i = 0; i < NumPorts; i++) begin : gen_connect_variables
    assign req_in[i] = floo_req_i[i].req;
    assign req_v_in[i] = floo_req_i[i].valid;
    assign req_credit_valid_in[i] = floo_req_i[i].credit_v;
    assign req_credit_id_in[i] = floo_req_i[i].credit_id;
    assign floo_req_o[i].req = req_out[i];
    assign floo_req_o[i].valid = req_v_out[i];
    assign floo_req_o[i].credit_v = req_credit_valid_out[i];
    assign floo_req_o[i].credit_id = req_credit_id_out[i];

    assign rsp_in[i] = floo_rsp_i[i].rsp;
    assign rsp_v_in[i] = floo_rsp_i[i].valid;
    assign rsp_credit_valid_in[i] = floo_rsp_i[i].credit_v;
    assign rsp_credit_id_in[i] = floo_rsp_i[i].credit_id;
    assign floo_rsp_o[i].rsp = rsp_out[i];
    assign floo_rsp_o[i].valid = rsp_v_out[i];
    assign floo_rsp_o[i].credit_v = rsp_credit_valid_out[i];
    assign floo_rsp_o[i].credit_id = rsp_credit_id_out[i];

    assign wide_in[i] = floo_wide_i[i].wide;
    assign wide_v_in[i] = floo_wide_i[i].valid;
    assign wide_credit_valid_in[i] = floo_wide_i[i].credit_v;
    assign wide_credit_id_in[i] = floo_wide_i[i].credit_id;
    assign floo_wide_o[i].wide = wide_out[i];
    assign floo_wide_o[i].valid = wide_v_out[i];
    assign floo_wide_o[i].credit_v = wide_credit_valid_out[i];
    assign floo_wide_o[i].credit_id = wide_credit_id_out[i];
  end

  floo_vc_router #(
    .NumPorts           (NumPorts),
    .NumLocalPorts      (NumLocalPorts),
    .NumVC              (NumVC),
    .NumVCMax           (NumVCMax),
    .NumVCWidth         (NumVCWidth),
    .NumVCToOut         (NumVCToOut),
    .NumVCToOutMax      (NumVCToOutMax),
    .NumVCWidthToOutMax (NumVCWidthToOutMax),
    .NumInputSaGlobal   (NumInputSaGlobal),
    .UpdateRRArbIfNotSent(UpdateRRArbIfNotSent),
    .SingleStage        (SingleStage),
    .VCDepth            (VCDepth),
    .VCDepthWidth       (VCDepthWidth),
    .CreditShortcut     (CreditShortcut),
    .AllowVCOverflow    (AllowVCOverflow),
    .FixedWormholeVC    (FixedWormholeVC),
    .WormholeVCDepth    (WormholeVCDepth),
    .WormholeVCId       (WormholeVCId),
    .AllowOverflowFromDeeperVC(AllowOverflowFromDeeperVC),
    .RouteAlgo          (RouteAlgo),
    .flit_t             (floo_req_generic_flit_t),
    .hdr_t              (hdr_t),
    .payload_t          (floo_req_payload_t),
    .IdWidth            (IdWidth),
    .id_t               (id_t),
    .NumAddrRules       (NumAddrRules),
    .addr_rule_t        (addr_rule_t)
  ) i_req_floo_vc_router (
    .clk_i,
    .rst_ni,
    .xy_id_i            (id_i),
    .id_route_map_i,
    .credit_valid_o         (req_credit_valid_out),
    .credit_id_o        (req_credit_id_out),
    .data_valid_i           (req_v_in),
    .data_i             (req_in),
    .credit_valid_i         (req_credit_valid_in),
    .credit_id_i        (req_credit_id_in),
    .data_valid_o           (req_v_out),
    .data_o             (req_out)
  );


  floo_vc_router #(
    .NumPorts           (NumPorts),
    .NumLocalPorts      (NumLocalPorts),
    .NumVC              (NumVC),
    .NumVCMax           (NumVCMax),
    .NumVCWidth         (NumVCWidth),
    .NumVCToOut         (NumVCToOut),
    .NumVCToOutMax      (NumVCToOutMax),
    .NumVCWidthToOutMax (NumVCWidthToOutMax),
    .NumInputSaGlobal   (NumInputSaGlobal),
    .UpdateRRArbIfNotSent(UpdateRRArbIfNotSent),
    .SingleStage        (SingleStage),
    .VCDepth            (VCDepth),
    .VCDepthWidth       (VCDepthWidth),
    .CreditShortcut     (CreditShortcut),
    .AllowVCOverflow    (AllowVCOverflow),
    .FixedWormholeVC    (FixedWormholeVC),
    .WormholeVCDepth    (WormholeVCDepth),
    .WormholeVCId       (WormholeVCId),
    .AllowOverflowFromDeeperVC(AllowOverflowFromDeeperVC),
    .RouteAlgo          (RouteAlgo),
    .flit_t             (floo_rsp_generic_flit_t),
    .hdr_t              (hdr_t),
    .payload_t          (floo_rsp_payload_t),
    .IdWidth            (IdWidth),
    .id_t               (id_t),
    .NumAddrRules       (NumAddrRules),
    .addr_rule_t        (addr_rule_t)
  ) i_rsp_floo_vc_router (
    .clk_i,
    .rst_ni,
    .xy_id_i            (id_i),
    .id_route_map_i,
    .credit_valid_o         (rsp_credit_valid_out),
    .credit_id_o        (rsp_credit_id_out),
    .data_valid_i           (rsp_v_in),
    .data_i             (rsp_in),
    .credit_valid_i         (rsp_credit_valid_in),
    .credit_id_i        (rsp_credit_id_in),
    .data_valid_o           (rsp_v_out),
    .data_o             (rsp_out)
  );


  floo_vc_router #(
    .NumPorts           (NumPorts),
    .NumLocalPorts      (NumLocalPorts),
    .NumVC              (NumVC),
    .NumVCMax           (NumVCMax),
    .NumVCWidth         (NumVCWidth),
    .NumVCToOut         (NumVCToOut),
    .NumVCToOutMax      (NumVCToOutMax),
    .NumVCWidthToOutMax (NumVCWidthToOutMax),
    .NumInputSaGlobal   (NumInputSaGlobal),
    .UpdateRRArbIfNotSent(UpdateRRArbIfNotSent),
    .SingleStage        (SingleStage),
    .VCDepth            (VCDepth),
    .VCDepthWidth       (VCDepthWidth),
    .CreditShortcut     (CreditShortcut),
    .AllowVCOverflow    (AllowVCOverflow),
    .FixedWormholeVC    (FixedWormholeVC),
    .WormholeVCDepth    (WormholeVCDepth),
    .WormholeVCId       (WormholeVCId),
    .AllowOverflowFromDeeperVC(AllowOverflowFromDeeperVC),
    .RouteAlgo          (RouteAlgo),
    .flit_t             (floo_wide_generic_flit_t),
    .hdr_t              (hdr_t),
    .payload_t          (floo_wide_payload_t),
    .IdWidth            (IdWidth),
    .id_t               (id_t),
    .NumAddrRules       (NumAddrRules),
    .addr_rule_t        (addr_rule_t)
  ) i_wide_floo_vc_router (
    .clk_i,
    .rst_ni,
    .xy_id_i            (id_i),
    .id_route_map_i,
    .credit_valid_o         (wide_credit_valid_out),
    .credit_id_o        (wide_credit_id_out),
    .data_valid_i           (wide_v_in),
    .data_i             (wide_in),
    .credit_valid_i         (wide_credit_valid_in),
    .credit_id_i        (wide_credit_id_in),
    .data_valid_o           (wide_v_out),
    .data_o             (wide_out)
  );

endmodule
