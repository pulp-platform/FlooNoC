// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

`include "common_cells/registers.svh"

/// A router with virtual channels, using the FVADA VC selection algorithm
module floo_vc_router import floo_pkg::*; #(
  /// Number of ports
  parameter int unsigned NumPorts                   =  5,
  /// Number of local prots
  parameter int unsigned NumLocalPorts              =  NumPorts - 4,
  // Number of VCs from each direction, 1313 for XY routing
  parameter int unsigned NumVC[NumPorts]            = {
    1+NumLocalPorts, // North
    3+NumLocalPorts, // East
    1+NumLocalPorts, // South
    3+NumLocalPorts, // West
    4+NumLocalPorts-1 // Local0
  },
  /// Number of maximum VCs
  parameter int unsigned NumVCMax                   =  NumPorts - 1,
  // NumVCWidth: needs to be 3 in routers with more than 1 local ports
  parameter int unsigned NumVCWidth                 =  2,
  // Set this to 3 towards routers with more than 1 local ports
  parameter int unsigned NumVCToOut[NumPorts]       =  {2, 4, 2, 4, 1},
  parameter int unsigned NumVCToOutMax              =  4,
  parameter int unsigned NumVCWidthToOutMax         =  2,
  parameter int unsigned NumInputSaGlobal[NumPorts] = {
    3+NumLocalPorts, // North
    1+NumLocalPorts, // East
    3+NumLocalPorts, // South
    1+NumLocalPorts, // West
    4+NumLocalPorts-1 // Local0
  },
  parameter int unsigned VCDepth                    =  2,
  parameter bit CreditShortcut                      =  1'b1, // not used if SingleStage is set
  parameter bit AllowVCOverflow                     =  1'b1,
  /// Make certain VCs deeper than others
  /// Rationale: in XY-routing, flits usually traverse straight through
  parameter bit FixedWormholeVC                     =  1'b0, // send all Wormhole flits to same VC
  parameter int unsigned WormholeVCId[NumPorts]     = {0, 1, 0, 2, 0},
  parameter int unsigned WormholeVCDepth            =  3,
  parameter bit AllowOverflowFromDeeperVC           =  1'b1,
  /// Use single stage
  parameter bit SingleStage                         =  1'b0,
  parameter type flit_t                             =  logic,
  parameter type hdr_t                              =  logic,
  parameter type payload_t                          =  logic,
  // Route Algorithm stuff
  parameter route_algo_e RouteAlgo                  =  XYRouting,
  /// Used for ID-based and XY routing
  parameter int unsigned IdWidth                    =  1,
  parameter type id_t                               =  logic[IdWidth-1:0],
  /// Used for ID-based routing
  parameter int unsigned NumAddrRules               =  0,
  parameter type addr_rule_t                        =  logic
) (
  input  logic                                        clk_i,
  input  logic                                        rst_ni,
  input  id_t                                         xy_id_i,
  input  addr_rule_t [NumAddrRules-1:0]               id_route_map_i,
  /// Input Ports
  output logic    [NumPorts-1:0]                      credit_valid_o,
  output logic    [NumPorts-1:0][NumVCWidth-1:0]      credit_id_o,
  input  logic    [NumPorts-1:0]                      data_valid_i,
  input  flit_t   [NumPorts-1:0]                      data_i,
  /// Output Ports
  input logic     [NumPorts-1:0]                      credit_valid_i,
  input logic     [NumPorts-1:0][NumVCWidth-1:0]      credit_id_i,
  output  logic   [NumPorts-1:0]                      data_valid_o,
  output  flit_t  [NumPorts-1:0]                      data_o
);

  ////////////////////
  //  Declarations  //
  ////////////////////

  // Some arrays might be larger than necessary, but should be optimized during synthesis
  logic [NumPorts-1:0][NumVCMax-1:0]      vc_hdr_valid;
  hdr_t [NumPorts-1:0][NumVCMax-1:0]      vc_hdr;
  payload_t [NumPorts-1:0][NumVCMax-1:0]  vc_payload;

  logic [NumPorts-1:0]                read_en_sa_stage;
  logic [NumPorts-1:0][NumVCMax-1:0]  read_vc_id_oh_sa_stage;
  logic [NumPorts-1:0]                read_en_st_stage;
  logic [NumPorts-1:0][NumVCMax-1:0]  read_vc_id_oh_st_stage;

  logic [NumPorts-1:0][NumPorts-1:0]  sa_local_outdir_oh;
  logic [NumPorts-1:0][NumVCMax-1:0]  sa_local_vc_id_oh;
  hdr_t [NumPorts-1:0]                sa_local_sel_hdr;

  logic [NumPorts-1:0][NumPorts-1:0]  sa_local_out_valid;

  logic [NumPorts-1:0]                sa_global_valid;
  logic [NumPorts-1:0][NumPorts-1:0]  sa_global_dir_oh;

  route_direction_e [NumPorts-1:0]                la_route_per_input;
  route_direction_e [NumPorts-1:0][NumPorts-1:0]  la_route_per_output;
  route_direction_e [NumPorts-1:0]                la_route_sel;
  route_direction_e [NumPorts-1:0]                la_route_sel_st_stage;

  logic [NumPorts-1:0][NumVCToOutMax-1:0]                         vc_not_full;
  logic [NumPorts-1:0][NumVCToOutMax-1:0]                         vc_sel_valid;
  logic [NumPorts-1:0][NumVCToOutMax-1:0][NumVCWidthToOutMax-1:0] vc_sel_id;
  logic [NumPorts-1:0]                                            vc_valid;
  logic [NumPorts-1:0][NumVCWidthToOutMax-1:0]                    vc_id;
  logic [NumPorts-1:0][NumVCWidthToOutMax-1:0]                    vc_assgn_id_st_stage;


  logic [NumPorts-1:0]                outport_valid;
  logic [NumPorts-1:0][NumPorts-1:0]  output_id_oh_sa_stage;
  logic [NumPorts-1:0][NumPorts-1:0]  output_id_oh_sa_stage_t;
  logic [NumPorts-1:0][NumPorts-1:0]  output_id_oh_st_stage;
  hdr_t [NumPorts-1:0]                sel_hdr_sa_stage;
  hdr_t [NumPorts-1:0]                sel_input_hdr_st_stage;

  logic [NumPorts-1:0][NumPorts-1:0]  last_bits;
  logic [NumPorts-1:0]                last_bits_sel;  // 1 bit/output
  logic [NumPorts-1:0]                last_bits_sel_st_stage;
  logic [NumPorts-1:0]                wh_detect; // per output
  logic [NumPorts-1:0]                wh_valid; // per outport
  logic [NumPorts-1:0]                wh_valid_d;
  logic [NumPorts-1:0][NumPorts-1:0]  wh_required_sel;
  logic [NumPorts-1:0]                wh_correct_sel;
  logic [NumPorts-1:0][NumPorts-1:0]  wh_sa_global_dir_oh;

  ///////////////////
  //  Input Ports  //
  ///////////////////

  for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_input_ports

    localparam int unsigned DeeperVCId = WormholeVCId[in_port >= Eject ? in_port : (in_port+2) % 4];

    floo_input_port #(
      .flit_t         ( flit_t          ),
      .payload_t      ( payload_t       ),
      .hdr_t          ( hdr_t           ),
      .NumVC          ( NumVC[in_port]  ),
      .VCIdxWidth     ( NumVCWidth      ),
      .VCDepth        ( VCDepth         ),
      .DeeperVCId     ( DeeperVCId      ),
      .DeeperVCDepth  ( WormholeVCDepth )
    ) i_input_port (
      .clk_i,
      .rst_ni,
      .credit_valid_o           ( credit_valid_o[in_port]                             ),
      .credit_id_o              ( credit_id_o[in_port]                                ),
      .data_valid_i             ( data_valid_i[in_port]                               ),
      .data_i                   ( data_i[in_port]                                     ),
      .vc_hdr_valid_o           ( vc_hdr_valid[in_port][NumVC[in_port]-1:0]           ),
      .vc_hdr_o                 ( vc_hdr[in_port][NumVC[in_port]-1:0]                 ),
      .vc_data_o                ( vc_payload[in_port][NumVC[in_port]-1:0]             ),
      .read_enable_sa_stage_i   ( read_en_sa_stage[in_port]                           ),
      .read_vc_id_oh_sa_stage_i ( sa_local_vc_id_oh[in_port][NumVC[in_port]-1:0]      ),
      .read_enable_st_stage_i   ( read_en_st_stage[in_port]                           ),
      .read_vc_id_oh_st_stage_i ( read_vc_id_oh_st_stage[in_port][NumVC[in_port]-1:0] )
    );
  end

  ////////////////////////////////////
  //  Local SA for each input port  //
  ////////////////////////////////////

  for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_sa_local
    floo_sa_local #(
      .NumVC    ( NumVC[in_port]  ),
      .NumPorts ( NumPorts        ),
      .hdr_t    ( hdr_t           )
    ) i_sa_local (
      .clk_i,
      .rst_ni,
      .vc_hdr_valid_i           (vc_hdr_valid[in_port][NumVC[in_port]-1:0]      ),
      .vc_hdr_i                 (vc_hdr[in_port][NumVC[in_port]-1:0]            ),
      .sa_local_vc_id_oh_o      (sa_local_vc_id_oh[in_port][NumVC[in_port]-1:0] ),
      .sa_local_sel_hdr_o       (sa_local_sel_hdr[in_port]                      ),
      .sa_local_output_dir_oh_o (sa_local_outdir_oh[in_port]                    ),
      .sent_i                   (read_en_sa_stage[in_port]                      ),
      .update_rr_arb_i          ((read_en_sa_stage  [in_port] &
                                  sel_hdr_sa_stage[in_port].last)               )
    );
  end

  //////////////////////////////////////
  //  Global SA for each output port  //
  //////////////////////////////////////

  for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_sa_global
    floo_sa_global #(
    .NumInputs  ( NumInputSaGlobal[out_port]  )
    ) i_sa_global (
      .clk_i,
      .rst_ni,
      // for each input: is their sa local in that dir valid
      .sa_local_valid_i       ( sa_local_out_valid[out_port][NumInputSaGlobal[out_port]-1:0]  ),
      .wh_sa_global_dir_oh_i  ( wh_sa_global_dir_oh[out_port][NumInputSaGlobal[out_port]-1:0] ),
      .wh_valid_i             ( wh_valid[out_port]                                            ),
      .sa_global_valid_o      ( sa_global_valid[out_port]                                     ),
      .sa_global_dir_oh_o     ( sa_global_dir_oh [out_port][NumInputSaGlobal[out_port]-1:0]   ),
      // update arbiter if allowed to update
      .sent_i                 ( outport_valid[out_port]                                       ),
      .update_rr_arb_i        ( (outport_valid[out_port] & last_bits_sel[out_port])           )
  );
  end

  ///////////////////////////////////////////////////////
  //  Look-ahead routing (runs parallel to global SA)  //
  ///////////////////////////////////////////////////////

  for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_lookahead_routing
    floo_look_ahead_routing #(
      .NumRoutes    ( NumPorts      ),
      .hdr_t        ( hdr_t         ),
      .RouteAlgo    ( RouteAlgo     ),
      .id_t         ( id_t          ),
      .NumAddrRules ( NumAddrRules  ),
      .addr_rule_t  ( addr_rule_t)
    ) i_floo_look_ahead_routing (
      .clk_i,
      .rst_ni,
      .id_route_map_i,
      .xy_id_i,
      .hdr_i      ( sa_local_sel_hdr[in_port]   ),
      .hdr_o      ( sel_hdr_sa_stage[in_port]   ),
      .la_route_o ( la_route_per_input[in_port] )
    );
  end

  //////////////////////////////////////
  //  Output port vc credit counters  //
  //////////////////////////////////////

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
      .credit_valid_i         ( credit_valid_i[out_port]                        ),
      .credit_id_i            ( credit_id_i[out_port][NumVCWidthToOutMax-1:0]   ),
      .consume_credit_valid_i ( outport_valid[out_port]                         ),
      .consume_credit_id_i    ( vc_id[out_port]                                 ),
      .vc_not_full_o          ( vc_not_full[out_port][NumVCToOut[out_port]-1:0] )
    );
  end


  ///////////////////////////////////////////////////////
  //  VC Selection (runs parallel to sa local/global)  //
  ///////////////////////////////////////////////////////

  for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_vc_selection
    floo_vc_selection #(
      .NumVC                      ( NumVCToOut[out_port]      ),
      .NumVCWidthMax              ( NumVCWidthToOutMax        ),
      .AllowVCOverflow            ( AllowVCOverflow           ),
      .AllowOverflowFromDeeperVC  ( AllowOverflowFromDeeperVC ),
      .DeeperVCId                 ( WormholeVCId[out_port]    )
    ) i_floo_vc_selection (
      .vc_not_full_i  ( vc_not_full[out_port][NumVCToOut[out_port]-1:0]   ),
      .vc_sel_valid_o ( vc_sel_valid[out_port][NumVCToOut[out_port]-1:0]  ),
      .vc_sel_id_o    ( vc_sel_id[out_port][NumVCToOut[out_port]-1:0]     )
    );
  end

  ////////////////////////////////////////////
  //  VC assignment (runs after sa global)  //
  ////////////////////////////////////////////

  for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_vc_assignment
    floo_vc_assignment #(
      .NumVC            ( NumVCToOut[out_port]            ),
      .NumVCWidthMax    ( NumVCWidthToOutMax              ),
      .NumInputs        ( NumInputSaGlobal[out_port]      ),
      .RouteAlgo        ( RouteAlgo                       ),
      .OutputId         ( out_port                        ),
      .CreditShortcut   ( CreditShortcut && !SingleStage  ),
      .FixedWormholeVC  ( FixedWormholeVC                 ),
      .WormholeVCId     ( WormholeVCId[out_port]          )
    ) i_floo_vc_assignment (
      .sa_global_valid_i  ( sa_global_valid[out_port]                                     ),
      .sa_global_dir_oh_i ( sa_global_dir_oh[out_port][NumInputSaGlobal[out_port]-1:0]    ),
      .la_route_i         ( la_route_per_output[out_port][NumInputSaGlobal[out_port]-1:0] ),
      .vc_sel_valid_i     ( vc_sel_valid[out_port][NumVCToOut[out_port]-1:0]              ),
      .vc_sel_id_i        ( vc_sel_id[out_port][NumVCToOut[out_port]-1:0]                 ),
      .vc_not_full_i      ( vc_not_full[out_port][NumVCToOut[out_port]-1:0]               ),
      // make sure correct vc is selected if not last or doing wormhole routing
      .wh_vc_en_i         ( ~last_bits_sel[out_port] | wh_valid[out_port]                 ),
      .credit_valid_i     ( credit_valid_i[out_port]                                      ),
      .credit_id_i        ( credit_id_i[out_port][NumVCWidthToOutMax-1:0]                 ),
      .vc_valid_o         ( vc_valid[out_port]                                            ),
      .vc_id_o            ( vc_id[out_port]                                               ),
      .la_route_sel_o     ( la_route_sel[out_port]                                        )
    );
  end

  ////////////////////////
  //  Wormhole routing  //
  ////////////////////////

  // If a flit with hdr.last == 0 is sent, start wormhole routing
  // The entire stream should be sent as fast as possible
  //   -> lock sa local and global of that port
  // The stream is not allowed to be interleaved
  //   -> check that output selects same output as first time
  // to make sure no locks exist, the stream is sent to the same (preferred) vc each time

  // Theoretically, interleaving is allowed by flits that have a different destination,
  // however, this is currently not implemented

  for(genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_select_last_bit
    floo_mux #(
      .NumInputs  ( NumInputSaGlobal[out_port]  ),
      .DataWidth  ( 1                           )
    ) i_floo_mux_select_vc_id (
      .sel_i  ( sa_global_dir_oh[out_port][NumInputSaGlobal[out_port]-1:0]  ),
      .data_i ( last_bits[out_port][NumInputSaGlobal[out_port]-1:0]         ),
      .data_o ( last_bits_sel[out_port]                                     )
    );
  end

  for(genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_check_result
    assign wh_correct_sel[out_port] = output_id_oh_sa_stage[out_port] == wh_required_sel[out_port];
  end

  for (genvar out_port = 0; out_port < NumPorts; out_port++) begin : gen_wormhole_ff
    `FFL(wh_required_sel[out_port], output_id_oh_sa_stage[out_port], wh_detect[out_port], '0)
    `FFL(wh_sa_global_dir_oh[out_port], sa_global_dir_oh[out_port], wh_detect[out_port], '0)
  end

  assign outport_valid = vc_valid & (~wh_valid | wh_correct_sel);

  assign wh_detect = ~last_bits_sel & outport_valid;
  assign wh_valid_d = wh_detect | (wh_valid & ~(last_bits_sel & outport_valid));
  `FF(wh_valid, wh_valid_d, '0)

  for(genvar i = 0 ; i < NumPorts; i++) begin : gen_transpose_DataWidth
    for(genvar j = 0 ; j < NumPorts; j++) begin : gen_transpose_NumInputs
      assign output_id_oh_sa_stage_t[i][j] = output_id_oh_sa_stage[j][i];
    end
  end

  // extract information
  for(genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_inport_read_enable
    assign read_en_sa_stage[in_port] = |(output_id_oh_sa_stage_t[in_port] & outport_valid);
    assign read_vc_id_oh_sa_stage[in_port] = sa_local_vc_id_oh[in_port];
  end


  //////////////////////////////////////////////////
  //  Map between per input and per output space  //
  //////////////////////////////////////////////////

  always_comb begin
    sa_local_out_valid = '0;
    la_route_per_output = '0;
    output_id_oh_sa_stage = '0;
    for (int out_port = 0; out_port < NumPorts; out_port++) begin : gen_transform_sa_results
      if (RouteAlgo == XYRouting) begin : gen_reduce_sa_global_input_size_if_xyrouting
        // to N/S has inputs S/N,E,W,L, to E/W has inputs W/E,L
        for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_in_port
          if(!(in_port == out_port ||
            (out_port == East && (in_port == South || in_port == North)) ||
            (out_port == West && (in_port == South || in_port == North))
              )) begin : gen_reduce_sa_global_xyrouting_include_input
              automatic int per_output_index =
                (out_port >= Eject || out_port == North || out_port == South) ? // from everything
                          (in_port < out_port ? in_port : in_port - 1) :
                (out_port == East || in_port >= Eject ? in_port - 3 : 0);
              sa_local_out_valid[out_port][per_output_index]
                    = sa_local_outdir_oh[in_port][out_port];
              la_route_per_output[out_port][per_output_index]
                    = la_route_per_input[in_port];
              last_bits[out_port][per_output_index]
                    = sa_local_sel_hdr[in_port].last;

              output_id_oh_sa_stage[out_port][in_port]
                    = sa_global_dir_oh[out_port][per_output_index];
          end
        end
      end
      // if not XY Routing: just transpose the matrix and leave out this dim
      else begin : gen_transpose_sa_results
        for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_in_port
          if(in_port != out_port) begin : gen_transp_sa_results_in_port_ne_out_port
            automatic int per_output_index = in_port < out_port ? in_port : in_port - 1;
            sa_local_out_valid[out_port][per_output_index]
                  = sa_local_outdir_oh[in_port][out_port];
            la_route_per_output[out_port][per_output_index]
                  = la_route_per_input[in_port];
            output_id_oh_sa_stage[out_port][in_port]
                  = sa_global_dir_oh[out_port][per_output_index];
            last_bits[out_port][per_output_index]
                  = sa_local_sel_hdr[in_port].last;
          end
        end
      end
    end
  end


  //////////////////////////
  //  SA to ST stage reg  //
  //////////////////////////

  if(SingleStage) begin : gen_no_stage_reg
    assign read_en_st_stage = read_en_sa_stage;
    assign read_vc_id_oh_st_stage = read_vc_id_oh_sa_stage;
    assign output_id_oh_st_stage = output_id_oh_sa_stage;
    assign data_valid_o = outport_valid;
    assign sel_input_hdr_st_stage = sel_hdr_sa_stage;
    assign vc_assgn_id_st_stage = vc_id;
    assign la_route_sel_st_stage = la_route_sel;
    assign last_bits_sel_st_stage = last_bits_sel;
  end else begin : gen_sa_to_st_stage

    `FF(read_en_st_stage, read_en_sa_stage, '0)
    `FF(read_vc_id_oh_st_stage, read_vc_id_oh_sa_stage, '0)
    `FF(output_id_oh_st_stage, output_id_oh_sa_stage, '0)
    `FF(data_valid_o, outport_valid, '0)

    for (genvar port = 0; port < NumPorts; port++) begin : gen_hdr_ff
      // per in_port: will be assigned in switch
      `FF(sel_input_hdr_st_stage[port].rob_req,
          sel_hdr_sa_stage[port].rob_req,    '0);
      `FF(sel_input_hdr_st_stage[port].rob_idx,
          sel_hdr_sa_stage[port].rob_idx,    '0);
      `FF(sel_input_hdr_st_stage[port].dst_id,
          sel_hdr_sa_stage[port].dst_id,     '0);
      `FF(sel_input_hdr_st_stage[port].src_id,
          sel_hdr_sa_stage[port].src_id,     '0);
      `FF(sel_input_hdr_st_stage[port].atop,
          sel_hdr_sa_stage[port].atop,       '0);
      `FFNR(sel_input_hdr_st_stage[port].axi_ch,
          sel_hdr_sa_stage[port].axi_ch, clk_i);
      // already per out_port: assign directly
      `FF(vc_assgn_id_st_stage[port], vc_id[port], '0)
      `FF(la_route_sel_st_stage[port], la_route_sel[port], North)
      `FF(last_bits_sel_st_stage[port], last_bits_sel[port], '0)
    end
end

  //////////
  //  ST  //
  //////////

  floo_vc_router_switch #(
    .NumPorts       ( NumPorts  ),
    .NumVC          ( NumVC     ),
    .NumVCMax       ( NumVCMax  ),
    .flit_t         ( flit_t    ),
    .flit_payload_t ( payload_t ),
    .hdr_t          ( hdr_t     ),
    .RouteAlgo      ( RouteAlgo )
  ) i_floo_vc_router_switch (
    .vc_data_head_i             ( vc_payload              ),
    .ctrl_head_per_inport_i     ( sel_input_hdr_st_stage  ),
    .vc_assignment_id_i         ( vc_assgn_id_st_stage    ),
    .look_ahead_routing_sel_i   ( la_route_sel_st_stage   ),
    .last_bits_sel_i            ( last_bits_sel_st_stage  ),
    .read_vc_id_oh_i            ( read_vc_id_oh_st_stage  ),
    .inport_id_oh_per_output_i  ( output_id_oh_st_stage   ),
    .data_o
  );

endmodule
