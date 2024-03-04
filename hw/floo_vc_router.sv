// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

// a router with virtual channels in the design of "Simple virtual channel allocation for high throughput and high frequency on-chip routers" 
// using the FVADA VC selection algorithm also described in that paper
module floo_vc_router (
  parameter int           NumPorts                    = 5, // phys channels are always input and output
  parameter int           NumLocalPorts               = NumPorts - 4;
  parameter int           NumVC [NumPorts-1:0]        = {4+NumLocalPorts-1, 3+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 1+NumLocalPorts}, // Num VC from dir L0, W, S, E, N: 3131 for XY routing
  parameter int           NumVCMax                    = NumPorts - 1;
  parameter int           NumVCWidth                  = 2,

  parameter int           NumInputSaGlobal [NumPorts-1:0] = {4+NumLocalPorts-1, 1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts}, // to dir L0, W, S, E, N

  parameter int           VCDepth                     = 2,
  parameter type          flit_t                      = logic,
  parameter int           HdrLength                   = $bits(hdr_t),
  parameter int           DataLength                  = $bits(flit_t) - HdrLength,
  parameter type          flit_payload_t              = logic[DataLength-1:0],
  // added fields to hdr: route_dir_e lookahead; logic [2:0] vc_id;

  // Route Algorithm stuff
  parameter route_algo_e  RouteAlgo                   = IdTable,
  /// Used for ID-based and XY routing
  parameter int unsigned  IdWidth                     = 0,
  parameter type          id_t                        = logic[IdWidth-1:0],
  /// Used for ID-based routing
  parameter int unsigned  NumAddrRules                = 0,
  parameter type          addr_rule_t                 = logic,
) (
  input  logic                                        clk_i,
  input  logic                                        rst_ni,

  input  id_t                                         xy_id_i,        // if unused assign to '0
  input  addr_rule_t [NumAddrRules-1:0]               id_route_map_i, // if unused assign to '0

  // contents from input port
  output logic  [NumPorts-1:0]                        credit_v_o,
  output logic  [NumPorts-1:0][NumVCWidth-1:0]        credit_id_o, 
  input  logic  [NumPorts-1:0][NumVCMax-1:0]          data_v_i, 
  input  flit_t [NumPorts-1:0]                        data_i,

  // contents from output port
  output logic  [NumPorts-1:0]                        credit_v_i,
  output logic  [NumPorts-1:0][NumVCWidth-1:0]        credit_id_i, 
  input  logic  [NumPorts-1:0][NumVCMax-1:0]          data_v_o, 
  input  flit_t [NumPorts-1:0]                        data_o
);
  
/*
Structure:
1 input ports
2 local SA for each input port
3 global SA for each output port
4 look-ahead routing (runs parallel to global SA)
5 output port vc credit counters
6 vc selection (runs parallel to sa local/global)
7 vc assignment (runs after sa global)
8 map input VCs to output VCs
9 SA to ST stage reg
10 ST
*/

// =============
// 0 defines
// =============


logic           [NumPorts-1:0][NumVCMax-1:0]    vc_ctrl_head_v;
hdr_t           [NumPorts-1:0][NumVCMax-1:0]    vc_ctrl_head;
flit_payload_t  [NumPorts-1:0][NumVCMax-1:0]    vc_data_head;

logic           [NumPorts-1:0]                  read_enable_sa_stage; 
logic           [NumPorts-1:0][NumVCWidth-1:0]  read_vc_id_sa_stage;
logic           [NumPorts-1:0]                  read_enable_st_stage; 
logic           [NumPorts-1:0][NumVCWidth-1:0]  read_vc_id_st_stage;


logic           [NumPorts-1:0]                  sa_local_vld;
logic           [NumPorts-1:0][NumPorts-1:0]    sa_local_vld_to_sa_global;
logic           [NumPorts-1:0][NumVCWidth-1:0]  sa_local_vc_id;
logic           [NumPorts-1:0][NumVCMax-1:0]    sa_local_vc_id_oh;


logic           [NumPorts-1:0][NumVCWidth-1:0]  sa_local_vc_id;



 

// =============
// 1 input ports
// =============

for (genvar i = 0; i < NumPorts; i++) begin
  floo_input_port #(
    .flit_t,
    .flit_payload_t,
    .NumVC         (NumVC[i]),
    .NumVCWidth
    .VCDepth       (VCDepth),
  )
  i_input_port
  (
    // input from other router or local port
    .credit_v_o                     (credit_v_o[i]),
    .credit_id_o                    (credit_id_o[i]), 
    .data_v_i                       (data_v_i[i]), 
    .data_i                         (data_i[i]),

    // output head flit ctrl info to SA & RC unit
    .vc_ctrl_head_v_o               (vc_ctrl_head_v[i]),
    .vc_ctrl_head_o                 (vc_ctrl_head[i]),

    // output data to switch traversal
    .vc_data_head_o                 (vc_data_head[i]),

    // pop flit ctrl fifo (comes from SA stage)
    .inport_read_enable_sa_stage_i  (read_enable_sa_stage[i]),
    .inport_read_vc_id_sa_stage_i   (sa_local_vc_id[i]),

    // pop flit data fifo (comes from ST stage)
    .inport_read_enable_st_stage_i  (read_enable_st_stage [i]),
    .inport_read_vc_id_st_stage_i   (read_vc_id_st_stage  [i]),

    .clk_i,
    .rst_ni
  );
end



// =============
// 2 local SA for each input port
// =============



// =============
// 3 global SA for each output port
// =============



// =============
// 4 look-ahead routing (runs parallel to global SA)
// =============



// =============
// 5 output port vc credit counters
// =============



// =============
// 6 vc selection (runs parallel to sa local/global)
// =============



// =============
// 7 vc assignment (runs after sa global)
// =============



// =============
// 8 map input VCs to output VCs
// =============



// =============
// 9 SA to ST stage reg
// =============



// =============
// 10 ST
// =============









endmodule
