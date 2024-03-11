// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>


// a router with virtual channels in the design of "Simple virtual channel allocation for high throughput and high frequency on-chip routers"
// using the FVADA VC selection algorithm also described in that paper
module floo_vc_router #(
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
  parameter int           NumVCWidthToOut [NumPorts]  = {2,2,2,2,1},
  parameter int           NumVCWidthToOutMax          = 2,

  parameter int           NumInputSaGlobal[NumPorts]  =
    {3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 4+NumLocalPorts-1},
    // to dir N,E,S,W,L0(,L1,L2,L3)

  parameter int           VCDepth                     = 2,
  parameter int           VCDepthWidth                = $clog2(VCDepth+1),
  parameter type          flit_t                      = logic,
  parameter int           HdrLength                   = $bits(hdr_t),
  parameter int           DataLength                  = $bits(flit_t) - HdrLength,
  parameter type          flit_payload_t              = logic[DataLength-1:0],

  // Route Algorithm stuff
  parameter route_algo_e  RouteAlgo                   = IdTable,
  /// Used for ID-based and XY routing
  parameter int unsigned  IdWidth                     = 0,
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

// These arrays are too large: in these dimensions where there are fewer vc, the highest indexes are never accessed, so the synthesizer should remove them
logic           [NumPorts-1:0][NumVCMax-1:0]      vc_ctrl_head_v;
hdr_t           [NumPorts-1:0][NumVCMax-1:0]      vc_ctrl_head;
flit_payload_t  [NumPorts-1:0][NumVCMax-1:0]      vc_data_head;

logic           [NumPorts-1:0]                    read_enable_sa_stage;
logic           [NumPorts-1:0][NumVCWidth-1:0]    read_vc_id_sa_stage;
logic           [NumPorts-1:0]                    read_enable_st_stage;
logic           [NumPorts-1:0][NumVCWidth-1:0]    read_vc_id_st_stage;


logic           [NumPorts-1:0]                    sa_local_v;
logic           [NumPorts-1:0][NumPorts-1:0]      sa_local_output_dir_oh;
logic           [NumPorts-1:0][NumVCWidth-1:0]    sa_local_vc_id;
logic           [NumPorts-1:0][NumVCMax-1:0]      sa_local_vc_id_oh;
hdr_t           [NumPorts-1:0]                    sa_local_sel_ctrl_head;

logic           [NumPorts-1:0][NumPorts-1:0]      sa_local_v_per_output;
logic           [NumPorts-1:0][NumPorts-1:0]      sa_local_vc_id_per_output;

logic           [NumPorts-1:0]                    sa_global_v;
logic           [NumPorts-1:0][NumPorts-1:0]      sa_global_input_dir_oh;
logic           [NumPorts-1:0][NumVCWidth-1:0]    sa_global_input_vc_id;

route_direction_e     [NumPorts-1:0]              look_ahead_routing;

logic           [NumPorts-1:0][NumVC-1:0][VCDepthWidth-1:0] credit_counter;
logic           [NumPorts-1:0]                    credit_consume_v;
logic           [NumPorts-1:0][NumVCWidth-1:0]    credit_consume_id;

logic           [NumPorts-1:0][NumVC-1:0]         vc_selection_v;
logic           [NumPorts-1:0][NumVC-1:0][NumVCWidth-1:0]   vc_selection_id;
logic           [NumPorts-1:0]                    vc_assignment_v;






// =============
// 1 input ports
// =============

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_input_ports
  floo_input_port #(
    .flit_t,
    .flit_payload_t,
    .NumVC                          (NumVC[in_port]),
    .NumVCMax                       (NumVCMax),
    .NumVCWidth,
    .VCDepth                        (VCDepth),
  ) i_input_port (
    // input from other router or local port
    .credit_v_o                     (credit_v_o           [in_port]),
    .credit_id_o                    (credit_id_o          [in_port]),
    .data_v_i                       (data_v_i             [in_port]),
    .data_i                         (data_i               [in_port]),

    // output head flit ctrl info to SA & RC unit
    .vc_ctrl_head_v_o               (vc_ctrl_head_v       [in_port]),
    .vc_ctrl_head_o                 (vc_ctrl_head         [in_port]),

    // output data to switch traversal
    .vc_data_head_o                 (vc_data_head         [in_port]),

    // pop flit ctrl fifo (comes from SA stage)
    .read_enable_sa_stage_i         (read_enable_sa_stage [in_port]),
    .read_vc_id_sa_stage_i          (sa_local_vc_id       [in_port]),

    // pop flit data fifo (comes from ST stage)
    .read_enable_st_stage_i         (read_enable_st_stage [in_port]),
    .read_vc_id_st_stage_i          (read_vc_id_st_stage  [in_port]),

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
    .NumVCWidth,
    .NumPorts
  ) i_sa_local (
    .vc_ctrl_head_v_i               (vc_ctrl_head_v         [in_port]),
    .vc_ctrl_head_i                 (vc_ctrl_head           [in_port]),

    .sa_local_v_o                   (sa_local_v             [in_port]), // 1 if any was chosen
    .sa_local_vc_id_o               (sa_local_vc_id         [in_port]), // chosen id
    .sa_local_vc_id_oh_o            (sa_local_vc_id_oh      [in_port]), // chosen id onehot encoded
    .sa_local_sel_ctrl_head_o       (sa_local_sel_ctrl_head [in_port]),

    // chosen output: all 0 if none
    .sa_local_output_dir_oh_o       (sa_local_output_dir_oh [in_port]),

    // when to update rr arbiter
    .update_rr_arb_i                (read_enable_sa_stage   [in_port]),
    .clk_i,
    .rst_ni
  );
end


// =============
// 3 global SA for each output port
// =============

/*

sa_local_vc_id is in the same space as vc_data/ctrl_head -> 0th is 0th vc, doesnt need to be dir N
sa_local_output_dir_oh is in route_direction_e space           -> 0th is towards (route_direction_e) 0
  -> cannot take each bit for each input in xyRouting

generally: we are not allowed to give the results from sa_local to the sa_global of the same port


Issue: sa global would benefit from only using as many inputs as needed

*/
always_comb begin
  for (int out_port = 0; out_port < NumPorts; out_port++) begin : gen_transform_sa_results
    if (RouteAlgo == XYRouting) begin : gen_reduce_sa_global_input_size_if_xyrouting
      int sa_global_input_index = in_port < out_port ? in_port : inport - 1;
      // to N/S has inputs S/N,E,W,L, to E/W has inputs W/E,L
      for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_red_sa_glb_xyrouting_in_port
        if(!(in_port == out_port ||
          (out_port == East && (in_port == South || in_port == North)) ||
          (out_port == West && (in_port == South || in_port == North))
            )) begin : gen_reduce_sa_global_xyrouting_include_input
            sa_local_vc_id_per_output[out_port][sa_global_input_index]
                  = sa_local_vc_id[in_port][out_port];
            sa_local_v_per_output[out_port][sa_global_input_index]
                  = sa_local_v[in_port][out_port];
            sa_global_input_index = sa_global_input_index ++;
        end
      end

    end
    // if not XY Routing: just transpose the matrix and leave out this dim
    else begin : gen_transpose_sa_results
      for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_transp_sa_results_in_port
        if(in_port != out_port) begin : gen_transp_sa_results_in_port_ne_out_port
          int sa_global_input_index = in_port < out_port ? in_port : inport - 1;
            sa_local_vc_id_per_output[out_port][sa_global_input_index]
                  = sa_local_vc_id[in_port][out_port];
            sa_local_v_per_output[out_port][sa_global_input_index]
                  = sa_local_v[in_port][out_port];
        end
      end
    end
  end
end

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_sa_global
  floo_sa_global #(
  .NumInputs                        (NumInputSaGlobal       [out_port]),
  .NumVCWidth,
  .NumPorts
  ) i_sa_global (
  // for each input: is their sa local in that dir valid
  .sa_local_v_i                     (sa_local_v_per_output  [out_port]),
  .sa_local_vc_id_i                 (sa_local_vc_id_per_output[out_port]),

  .sa_global_v_o                    (sa_global_v            [out_port]),
  .sa_global_input_dir_oh_o         (sa_global_input_dir_oh [out_port]),
  .sa_global_input_vc_id_o          (sa_global_input_vc_id  [out_port]),

  // update arbiter if the vc assignment was successful
  .update_rr_arb_i                  (vc_assignment_v        [out_port]),

  .clk_i,
  .rst_ni
);
end


// =============
// 4 look-ahead routing (runs parallel to global SA)
// =============

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_sa_local
  floo_look_ahead_routing #(
    .NumRoutes(NumPorts),
    .flit_t,
    .RouteAlgo,
    .IdWidth,
    .id_t,
    .NumAddrRules,
    .addr_rule_t
  ) i_floo_look_ahead_routing (
    .vc_ctrl_head_i                 (sa_local_sel_ctrl_head [in_port]),
    .look_ahead_routing_o           (look_ahead_routing     [in_port]),
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
  floo_credit_counter
  #(
    .NumVC                          (NumVCToOut             [out_port]),
    .VCDepth
  )
  i_floo_credit_counter (
    .credit_v_i                     (credit_v_i             [out_port]),
    .credit_id_i                    (credit_id_i            [out_port]),
    .consume_credit_v_i             (credit_consume_v       [out_port]),
    .consume_credit_id_i            (credit_consume_id      [out_port]),
    .credit_counter_o               (credit_counter         [out_port]),
    .clk_i,
    .rst_ni
  );
end


// =============
// 6 vc selection (runs parallel to sa local/global)
// =============

for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_vc_selection
  floo_vc_selection
  #(
    .NumVC                          (NumVCToOut             [out_port]),
    .VCDepth
  )
  i_floo_vc_selection (
    .credit_counter_i               (credit_counter         [out_port]),
    .vc_selection_v_o               (vc_selection_v_o       [out_port]),
    .vc_selection_id_o              (vc_selection_id        [out_port])
  );
end


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

