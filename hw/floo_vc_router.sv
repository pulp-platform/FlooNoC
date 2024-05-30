// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"

// a router with virtual channels in the design of "Simple virtual channel allocation for high throughput and high frequency on-chip routers"
// using the FVADA VC selection algorithm also described in that paper
module floo_vc_router import floo_pkg::*; #(
  parameter int           NumPorts                    = 5, // phys channels are always in and output
  parameter int           NumLocalPorts               = NumPorts - 4,
  parameter int           NumVC           [NumPorts]  =
            {1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 4+NumLocalPorts-1},
            // Num VC from dir N,E,S,W,L0(,L1,L2,L3): 1313 for XY routing
  parameter int           NumVCMax                    = NumPorts - 1,
  // NumVCWidth: needs to be 3 in routers with more than 1 local ports
  parameter int           NumVCWidth                  = 2,
  // set this to 3 towards routers with more than 1 local ports: towards N,E,S,W,L0(,L1,L2,L3)
  parameter int           NumVCToOut      [NumPorts]  = {2,4,2,4,1},
  parameter int           NumVCToOutMax               = 4,
  parameter int           NumVCWidthToOutMax          = 2,

  parameter int           NumInputSaGlobal[NumPorts]  =
    {3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 4+NumLocalPorts-1},
    // to dir N,E,S,W,L0(,L1,L2,L3)
  parameter int           VCDepth                     = 2,
  parameter int           VCDepthWidth                = $clog2(VCDepth+1),
  parameter int           CreditShortcut              = 1, // not used if SingleStage=1
  parameter int           AllowVCOverflow             = 1, // 1: FVADA, 0: fixed VC, direction based
  // Idea behind this: need depth 3 for continuous flow, since xy-routing: usually flits traverse straight through -> make that vc deeper
  parameter int           FixedWormholeVC             = 0, // send all Wormhole flits to same VC
  parameter int           WormholeVCId    [NumPorts]  = {0,1,0,2,0}, // as seen from output port
  parameter int           WormholeVCDepth             = 3,
  parameter int           AllowOverflowFromDeeperVC   = 1, //if 1 but AllowVCOverflow=0, overwritten
  parameter int           UpdateRRArbIfNotSent        = 0, //doesnt seem to work
  parameter int           SingleStage                 = 0, // 0: standard 2 stage, 1: single stage
  parameter type          flit_t                      = logic,
  parameter type          hdr_t                       = logic,
  parameter int           HdrLength                   = $bits(hdr_t),
  parameter int           DataLength                  = $bits(flit_t) - HdrLength,
  parameter type          flit_payload_t              = logic[DataLength-1:0],

  // Route Algorithm stuff
  parameter route_algo_e  RouteAlgo                   = XYRouting,
  /// Used for ID-based and XY routing
  parameter int unsigned  IdWidth                     = 1,
  parameter type          id_t                        = logic[IdWidth-1:0],
  /// Used for ID-based routing
  parameter int unsigned  NumAddrRules                = 0,
  parameter type          addr_rule_t                 = logic
) (
  input  logic                                        clk_i,
  input  logic                                        rst_ni,

  input  id_t                                         xy_id_i,        // if unused assign to '0
  input  addr_rule_t [NumAddrRules-1:0]               id_route_map_i, // if unused assign to '0

  // contents from input port
  output logic    [NumPorts-1:0]                      credit_v_o,
  output logic    [NumPorts-1:0][NumVCWidth-1:0]      credit_id_o,
  input  logic    [NumPorts-1:0]                      data_v_i,
  input  flit_t   [NumPorts-1:0]                      data_i,

  // contents from output port
  input logic     [NumPorts-1:0]                      credit_v_i,
  input logic     [NumPorts-1:0][NumVCWidth-1:0]      credit_id_i,
  output  logic   [NumPorts-1:0]                      data_v_o,
  output  flit_t  [NumPorts-1:0]                      data_o
);

/*
Structure:
0 defines
1 input ports
2 local SA for each input port
3 global SA for each output port
4 look-ahead routing (runs parallel to global SA)
5 output port vc credit counters
6 vc selection (runs parallel to sa local/global)
7 vc assignment (runs after sa global)
8 wormhole routing
9 map between per input and per output space
10 SA to ST stage reg
11 ST
*/

// =============
// 0 defines
// =============

// These arrays are too large: in these dimensions where there are fewer vc, the highest indexes are never accessed, so the synthesizer should remove them
logic           [NumPorts-1:0][NumVCMax-1:0]                        vc_ctrl_head_v;
hdr_t           [NumPorts-1:0][NumVCMax-1:0]                        vc_ctrl_head;
flit_payload_t  [NumPorts-1:0][NumVCMax-1:0]                        vc_data_head;

logic           [NumPorts-1:0]                                      read_enable_sa_stage;
logic           [NumPorts-1:0][NumVCMax-1:0]                        read_vc_id_oh_sa_stage;
logic           [NumPorts-1:0]                                      read_enable_st_stage;
logic           [NumPorts-1:0][NumVCMax-1:0]                        read_vc_id_oh_st_stage;

logic           [NumPorts-1:0][NumPorts-1:0]                        sa_local_output_dir_oh;
logic           [NumPorts-1:0][NumVCMax-1:0]                        sa_local_vc_id_oh;
hdr_t           [NumPorts-1:0]                                      sa_local_sel_ctrl_head;

logic           [NumPorts-1:0][NumPorts-1:0]                        sa_local_v_per_output;

logic           [NumPorts-1:0]                                      sa_global_v;
logic           [NumPorts-1:0][NumPorts-1:0]                        sa_global_input_dir_oh;

route_direction_e [NumPorts-1:0]                                    look_ahead_routing_per_input;
route_direction_e [NumPorts-1:0][NumPorts-1:0]                      look_ahead_routing_per_output;
route_direction_e [NumPorts-1:0]                                    look_ahead_routing_sel;
route_direction_e [NumPorts-1:0]                                    look_ahead_routing_sel_st_stage;

logic           [NumPorts-1:0][NumVCToOutMax-1:0]                   vc_not_full;

logic           [NumPorts-1:0][NumVCToOutMax-1:0]                        vc_selection_v;
logic           [NumPorts-1:0][NumVCToOutMax-1:0][NumVCWidthToOutMax-1:0]vc_selection_id;
logic           [NumPorts-1:0]                                      vc_assignment_v;
logic           [NumPorts-1:0][NumVCWidthToOutMax-1:0]              vc_assignment_id;
logic           [NumPorts-1:0][NumVCWidthToOutMax-1:0]              vc_assignment_id_st_stage;

logic           [NumPorts-1:0]                                      outport_v;

logic           [NumPorts-1:0][NumPorts-1:0]        inport_id_oh_per_output_sa_stage;
logic           [NumPorts-1:0][NumPorts-1:0]        inport_id_oh_per_output_sa_stage_transposed;
logic           [NumPorts-1:0][NumPorts-1:0]        inport_id_oh_per_output_st_stage;
hdr_t           [NumPorts-1:0]                      sel_ctrl_head_per_input_sa_stage;
hdr_t           [NumPorts-1:0]                      sel_ctrl_head_per_input_st_stage;

logic           [NumPorts-1:0][NumPorts-1:0]        last_bits_per_output;
logic           [NumPorts-1:0]                      last_bits_sel;  // 1 bit/output
logic           [NumPorts-1:0]                      last_bits_sel_st_stage;
logic           [NumPorts-1:0]                      wormhole_detected; // per output
logic           [NumPorts-1:0]                      wormhole_v; // per outport
logic           [NumPorts-1:0]                      wormhole_v_d;
logic           [NumPorts-1:0]                      wormhole_v_per_input; // per input
logic           [NumPorts-1:0][NumPorts-1:0]        wormhole_required_sel_input;
logic           [NumPorts-1:0][NumPorts-1:0]        wormhole_required_sel_input_transposed;
logic           [NumPorts-1:0]                      wormhole_correct_input_sel;
logic           [NumPorts-1:0][NumPorts-1:0]        wormhole_sa_global_input_dir_oh;




// =============
// 1 input ports
// =============

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_input_ports
  floo_input_port #(
    .flit_t                         (flit_t),
    .flit_payload_t                 (flit_payload_t),
    .hdr_t                          (hdr_t),
    .NumVC                          (NumVC[in_port]),
    .NumVCWidth                     (NumVCWidth),
    .VCDepth                        (VCDepth),
    .DeeperVCId                     (WormholeVCId[in_port >= Eject ? in_port : (in_port+2) % 4]),
    .DeeperVCDepth                  (WormholeVCDepth)
  ) i_input_port (
    // input from other router or local port
    .credit_v_o                     (credit_v_o           [in_port]),
    .credit_id_o                    (credit_id_o          [in_port]),
    .data_v_i                       (data_v_i             [in_port]),
    .data_i                         (data_i               [in_port]),

    // output head flit ctrl info to SA & RC unit
    .vc_ctrl_head_v_o               (vc_ctrl_head_v       [in_port][NumVC[in_port]-1:0]),
    .vc_ctrl_head_o                 (vc_ctrl_head         [in_port][NumVC[in_port]-1:0]),

    // output data to switch traversal
    .vc_data_head_o                 (vc_data_head         [in_port][NumVC[in_port]-1:0]),

    // pop flit ctrl fifo (comes from SA stage)
    .read_enable_sa_stage_i         (read_enable_sa_stage [in_port]),
    .read_vc_id_oh_sa_stage_i       (sa_local_vc_id_oh    [in_port][NumVC[in_port]-1:0]),

    // pop flit data fifo (comes from ST stage)
    .read_enable_st_stage_i         (read_enable_st_stage [in_port]),
    .read_vc_id_oh_st_stage_i       (read_vc_id_oh_st_stage[in_port][NumVC[in_port]-1:0]),

    .clk_i,
    .rst_ni
  );
end


// =============
// 2 local SA for each input port
// =============

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_sa_local
  floo_sa_local #(
    .NumVC                          (NumVC                  [in_port]),
    .NumPorts                       (NumPorts),
    .hdr_t                          (hdr_t)
  ) i_sa_local (
    .vc_ctrl_head_v_i               (vc_ctrl_head_v         [in_port][NumVC[in_port]-1:0]),
    .vc_ctrl_head_i                 (vc_ctrl_head           [in_port][NumVC[in_port]-1:0]),

    .sa_local_vc_id_oh_o            (sa_local_vc_id_oh      [in_port][NumVC[in_port]-1:0]),
    .sa_local_sel_ctrl_head_o       (sa_local_sel_ctrl_head [in_port]),

    // chosen output: all 0 if none
    .sa_local_output_dir_oh_o       (sa_local_output_dir_oh [in_port]),
    // when to update rr arbiter
    .sent_i                         (read_enable_sa_stage   [in_port]),
    .update_rr_arb_i                ((read_enable_sa_stage  [in_port] &
                                      sel_ctrl_head_per_input_sa_stage[in_port].last) |
                                     (UpdateRRArbIfNotSent==1 & ~read_enable_sa_stage [in_port] &
                                      ~wormhole_v_per_input [in_port])),
    .clk_i,
    .rst_ni
  );
end


// =============
// 3 global SA for each output port
// =============

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_sa_global
  floo_sa_global #(
  .NumInputs                        (NumInputSaGlobal       [out_port])
  ) i_sa_global (
  // for each input: is their sa local in that dir valid
  .sa_local_v_i                     (sa_local_v_per_output  [out_port]
                                                            [NumInputSaGlobal[out_port]-1:0]),
  .wormhole_sa_global_input_dir_oh_i(wormhole_sa_global_input_dir_oh[out_port]
                                                            [NumInputSaGlobal[out_port]-1:0]),
  .wormhole_v_i                     (wormhole_v             [out_port]),
  .sa_global_v_o                    (sa_global_v            [out_port]),
  .sa_global_input_dir_oh_o         (sa_global_input_dir_oh [out_port]
                                                            [NumInputSaGlobal[out_port]-1:0]),
  // update arbiter if allowed to update
  .sent_i                           (outport_v              [out_port]),
  .update_rr_arb_i                  ((outport_v[out_port] & last_bits_sel[out_port]) |
                      (UpdateRRArbIfNotSent==1 & ~outport_v[out_port] & ~wormhole_v[out_port])),
  .clk_i,
  .rst_ni
);
end


// =============
// 4 look-ahead routing (runs parallel to global SA)
// =============

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_lookahead_routing
  floo_look_ahead_routing #(
    .NumRoutes                      (NumPorts),
    .hdr_t                          (hdr_t),
    .RouteAlgo                      (RouteAlgo),
    .IdWidth                        (IdWidth),
    .id_t                           (id_t),
    .NumAddrRules                   (NumAddrRules),
    .addr_rule_t                    (addr_rule_t)
  ) i_floo_look_ahead_routing (
    .ctrl_head_i                    (sa_local_sel_ctrl_head           [in_port]),
    .ctrl_head_o                    (sel_ctrl_head_per_input_sa_stage [in_port]),
    .look_ahead_routing_o           (look_ahead_routing_per_input     [in_port]),
    .id_route_map_i,
    .xy_id_i,
    .clk_i,
    .rst_ni
  );
end


// =============
// 5 output port vc credit counters
// =============

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_credit_counters
  floo_credit_counter #(
    .NumVC          ( NumVCToOut [out_port]   ),
    .VCIdxWidthMax  ( NumVCWidthToOutMax      ),
    .VCDepth        ( VCDepth                 ),
    .DeeperVCId     ( WormholeVCId [out_port] ),
    .DeeperVCDepth  ( WormholeVCDepth         )
  ) i_floo_credit_counter (
    .clk_i,
    .rst_ni,
    .credit_valid_i         ( credit_v_i[out_port]                            ),
    .credit_id_i            ( credit_id_i[out_port][NumVCWidthToOutMax-1:0]   ),
    .consume_credit_valid_i ( outport_v[out_port]                             ),
    .consume_credit_id_i    ( vc_assignment_id[out_port]                      ),
    .vc_not_full_o          ( vc_not_full[out_port][NumVCToOut[out_port]-1:0] )
  );
end


// =============
// 6 vc selection (runs parallel to sa local/global)
// =============

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_vc_selection
  floo_vc_selection
  #(
    .NumVC                          (NumVCToOut             [out_port]),
    .NumVCWidthMax                  (NumVCWidthToOutMax),
    .VCDepth                        (VCDepth),
    .AllowVCOverflow                (AllowVCOverflow),
    .AllowOverflowFromDeeperVC      (AllowOverflowFromDeeperVC),
    .DeeperVCId                     (WormholeVCId          [out_port])
  )
  i_floo_vc_selection (
    .vc_not_full_i                  (vc_not_full            [out_port][NumVCToOut[out_port]-1:0]),
    .vc_selection_v_o               (vc_selection_v         [out_port][NumVCToOut[out_port]-1:0]),
    .vc_selection_id_o              (vc_selection_id        [out_port][NumVCToOut[out_port]-1:0])
  );
end


// =============
// 7 vc assignment (runs after sa global)
// =============

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_vc_assignment
  floo_vc_assignment
  #(
    .NumVC                          (NumVCToOut             [out_port]),
    .NumVCWidthMax                  (NumVCWidthToOutMax),
    .NumInputs                      (NumInputSaGlobal       [out_port]),
    .RouteAlgo                      (RouteAlgo),
    .OutputId                       (out_port),
    .CreditShortcut                 (CreditShortcut && SingleStage == 0),
    .FixedWormholeVC                (FixedWormholeVC),
    .WormholeVCId                   (WormholeVCId          [out_port])
  )
  i_floo_vc_assignment (
    .sa_global_v_i                  (sa_global_v            [out_port]),
    .sa_global_input_dir_oh_i       (sa_global_input_dir_oh [out_port]
                                                                [NumInputSaGlobal[out_port]-1:0]),
    .look_ahead_routing_i           (look_ahead_routing_per_output[out_port]
                                                                [NumInputSaGlobal[out_port]-1:0]),
    .vc_selection_v_i               (vc_selection_v         [out_port][NumVCToOut[out_port]-1:0]),
    .vc_selection_id_i              (vc_selection_id        [out_port][NumVCToOut[out_port]-1:0]),
    .vc_not_full_i                  (vc_not_full            [out_port][NumVCToOut[out_port]-1:0]),
    // make sure correct vc is selected if not last or doing wormhole routing
    .require_wormhole_vc_i          (~last_bits_sel          [out_port]
                                    | wormhole_v            [out_port]),
    .credit_v_i                     (credit_v_i             [out_port]),
    .credit_id_i                    (credit_id_i            [out_port][NumVCWidthToOutMax-1:0]),
    .vc_assignment_v_o              (vc_assignment_v        [out_port]),
    .vc_assignment_id_o             (vc_assignment_id       [out_port]),
    .look_ahead_routing_sel_o       (look_ahead_routing_sel [out_port])
  );
end

// =============
// 8 wormhole routing:
/* =============
  if a flit with hdr.last == 0 is sent, start wormhole routing
  the entire stream should be sent as fast as possible
    -> lock sa local and global of that port
  the stream is not allowed to be interleaved
    -> check that output selects same output as first time
  to make sure no locks exist, the stream is sent to the same (preferred) vc each time

  theoretically, interleaving is allowed by flits that have a different destination, this is currently not implemented
*/

for(genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_select_last_bit
  floo_mux #(
    .NumInputs(NumInputSaGlobal       [out_port]),
    .DataWidth(1)
  ) i_floo_mux_select_vc_id (
    .sel_i    (sa_global_input_dir_oh [out_port][NumInputSaGlobal[out_port]-1:0]),
    .data_i   (last_bits_per_output   [out_port][NumInputSaGlobal[out_port]-1:0]),
    .data_o   (last_bits_sel          [out_port])
  );
end

for(genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_check_result
  assign wormhole_correct_input_sel[out_port] =
          inport_id_oh_per_output_sa_stage[out_port] == wormhole_required_sel_input[out_port];
end

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_wormhole_ff
  `FFL( wormhole_required_sel_input[out_port],
        inport_id_oh_per_output_sa_stage[out_port], wormhole_detected[out_port], '0)
  `FFL( wormhole_sa_global_input_dir_oh[out_port],
        sa_global_input_dir_oh[out_port], wormhole_detected[out_port], '0)
end

assign outport_v = vc_assignment_v & (~wormhole_v | wormhole_correct_input_sel);

assign wormhole_detected = ~last_bits_sel & outport_v;
assign wormhole_v_d = wormhole_detected | (wormhole_v & ~(last_bits_sel & outport_v));
`FF(wormhole_v, wormhole_v_d, '0)

for(genvar i = 0 ; i < NumPorts; i++) begin : gen_transpose_DataWidth
  for(genvar j = 0 ; j < NumPorts; j++) begin : gen_transpose_NumInputs
    assign inport_id_oh_per_output_sa_stage_transposed[i][j] =
                      inport_id_oh_per_output_sa_stage[j][i];
    assign wormhole_required_sel_input_transposed[i][j] =
                      wormhole_required_sel_input[j][i];
  end
end

// extract information
for(genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_inport_read_enable
  assign read_enable_sa_stage[in_port] =
      |(inport_id_oh_per_output_sa_stage_transposed[in_port] & outport_v);
  assign wormhole_v_per_input[in_port] =
      |(wormhole_required_sel_input_transposed[in_port] & wormhole_v);
  assign read_vc_id_oh_sa_stage[in_port] = sa_local_vc_id_oh[in_port];
end


// =============
// 9 map between per input and per output space
// =============

/*
Map between per input and per output space:

sa_local_vc_id is in the same space as vc_data/ctrl_head -> 0th is 0th vc, doesnt need to be dir N
sa_local_output_dir_oh is in out_port space              -> 0th is towards (route_direction_e) 0th output

input space:
sa_local_vc_id
sa_local_output_dir_oh
look_ahead_routing_per_input
last_bits_per_input

inport_id_oh_per_output_sa_stage

output space:
sa_local_v_per_output
look_ahead_routing_per_output
last_bits_per_output

sa_global_input_dir_oh
*/

// initial begin
//   forever begin
//     @(posedge clk_i);
//     #4ns;
//     $display("sa_local_v_per_output: %b", sa_local_v_per_output);
//     $display("sa_local_output_dir_oh: %b", sa_local_output_dir_oh);
//     $display("sa_global_v: %b", sa_global_v);
//     $display("sa_global_input_dir: %b", sa_global_input_dir_oh);
//     // $display("look_ahead_routing_per_input: %p", look_ahead_routing_per_input);
//     // $display("look_ahead_routing_per_output: %p", look_ahead_routing_per_output);
//     $display("vc_not_full: %b", vc_not_full);
//     $display("vc_assignment_v: %b", vc_assignment_v);
//     $display("last_bits_sel: %b, outport_v:%b, wormhole_detected: %b, wormhole_v_d_ %b",
//         last_bits_sel, outport_v, wormhole_detected, wormhole_v_d);
//     $display("wormhole_v_per_input: %b", wormhole_v_per_input);
//     $display("sa_global_input_dir_oh: %b", sa_global_input_dir_oh);
//     $display("inport_id_oh_per_output_sa_stage: %p", inport_id_oh_per_output_sa_stage);
//   end
// end

always_comb begin
  sa_local_v_per_output            = '0;
  look_ahead_routing_per_output    = '0;
  inport_id_oh_per_output_sa_stage = '0;
  for (int out_port = 0; out_port < NumPorts; out_port++) begin : gen_transform_sa_results
    if (RouteAlgo == XYRouting) begin : gen_reduce_sa_global_input_size_if_xyrouting
      // to N/S has inputs S/N,E,W,L, to E/W has inputs W/E,L
      for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_red_sa_glb_xyrouting_in_port
        if(!(in_port == out_port ||
          (out_port == East && (in_port == South || in_port == North)) ||
          (out_port == West && (in_port == South || in_port == North))
            )) begin : gen_reduce_sa_global_xyrouting_include_input
            automatic int per_output_index =
              (out_port >= Eject || out_port == North || out_port == South) ? // from everything
                        (in_port < out_port ? in_port : in_port - 1) :
              (out_port == East || in_port >= Eject ? in_port - 3 : 0);
            // $display("(%0d,%0d, %0d) ",out_port,in_port, per_output_index);
            sa_local_v_per_output[out_port][per_output_index]
                  = sa_local_output_dir_oh[in_port][out_port];
            look_ahead_routing_per_output[out_port][per_output_index]
                  = look_ahead_routing_per_input[in_port];
            last_bits_per_output[out_port][per_output_index]
                  = sa_local_sel_ctrl_head[in_port].last;

            inport_id_oh_per_output_sa_stage[out_port][in_port]
                  = sa_global_input_dir_oh[out_port][per_output_index];
        end
      end
    end
    // if not XY Routing: just transpose the matrix and leave out this dim
    else begin : gen_transpose_sa_results
      for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_transp_sa_results_in_port
        if(in_port != out_port) begin : gen_transp_sa_results_in_port_ne_out_port
          automatic int per_output_index = in_port < out_port ? in_port : in_port - 1;
          sa_local_v_per_output[out_port][per_output_index]
                = sa_local_output_dir_oh[in_port][out_port];
          look_ahead_routing_per_output[out_port][per_output_index]
                = look_ahead_routing_per_input[in_port];
          inport_id_oh_per_output_sa_stage[out_port][in_port]
                = sa_global_input_dir_oh[out_port][per_output_index];
          last_bits_per_output[out_port][per_output_index]
                = sa_local_sel_ctrl_head[in_port].last;
        end
      end
    end
  end
end



// =============
// 10 SA to ST stage reg
// =============

if(SingleStage) begin : gen_no_stage_reg
  assign read_enable_st_stage             = read_enable_sa_stage;
  assign read_vc_id_oh_st_stage           = read_vc_id_oh_sa_stage;
  assign inport_id_oh_per_output_st_stage = inport_id_oh_per_output_sa_stage;
  assign data_v_o                         = outport_v;
  assign sel_ctrl_head_per_input_st_stage = sel_ctrl_head_per_input_sa_stage;
  assign vc_assignment_id_st_stage        = vc_assignment_id;
  assign look_ahead_routing_sel_st_stage  = look_ahead_routing_sel;
  assign last_bits_sel_st_stage           = last_bits_sel;
end else begin : gen_sa_to_st_stage

`FF(read_enable_st_stage, read_enable_sa_stage, '0)
`FF(read_vc_id_oh_st_stage, read_vc_id_oh_sa_stage, '0)
`FF(inport_id_oh_per_output_st_stage, inport_id_oh_per_output_sa_stage, '0)
`FF(data_v_o, outport_v, '0)

for (genvar port = 0; port < NumPorts; port++) begin : gen_hdr_ff
  // per in_port: will be assigned in switch
  `FF(sel_ctrl_head_per_input_st_stage[port].rob_req,
      sel_ctrl_head_per_input_sa_stage[port].rob_req,    '0);
  `FF(sel_ctrl_head_per_input_st_stage[port].rob_idx,
      sel_ctrl_head_per_input_sa_stage[port].rob_idx,    '0);
  `FF(sel_ctrl_head_per_input_st_stage[port].dst_id,
      sel_ctrl_head_per_input_sa_stage[port].dst_id,     '0);
  `FF(sel_ctrl_head_per_input_st_stage[port].src_id,
      sel_ctrl_head_per_input_sa_stage[port].src_id,     '0);
  `FF(sel_ctrl_head_per_input_st_stage[port].atop,
      sel_ctrl_head_per_input_sa_stage[port].atop,       '0);
  `FFNR(sel_ctrl_head_per_input_st_stage[port].axi_ch,
      sel_ctrl_head_per_input_sa_stage[port].axi_ch, clk_i);
  // already per out_port: assign directly
  `FF(vc_assignment_id_st_stage[port], vc_assignment_id[port], '0)
  `FF(look_ahead_routing_sel_st_stage[port], look_ahead_routing_sel[port], North)
  `FF(last_bits_sel_st_stage[port], last_bits_sel[port], '0)
end

end

// =============
// 11 ST
// =============

floo_vc_router_switch #(
  .NumPorts                         (NumPorts),
  .NumVC                            (NumVC),
  .NumVCMax                         (NumVCMax),
  .flit_t                           (flit_t),
  .flit_payload_t                   (flit_payload_t),
  .hdr_t                            (hdr_t),
  .RouteAlgo                        (RouteAlgo)
) i_floo_vc_router_switch (
  .vc_data_head_i                   (vc_data_head),
  .ctrl_head_per_inport_i           (sel_ctrl_head_per_input_st_stage),
  .vc_assignment_id_i               (vc_assignment_id_st_stage),
  .look_ahead_routing_sel_i         (look_ahead_routing_sel_st_stage),
  .last_bits_sel_i                  (last_bits_sel_st_stage),
  .read_vc_id_oh_i                  (read_vc_id_oh_st_stage),
  .inport_id_oh_per_output_i        (inport_id_oh_per_output_st_stage),
  .data_o
);


endmodule
