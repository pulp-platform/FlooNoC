// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

module floo_vc_router_switch import floo_pkg::*; #(
  parameter int           NumPorts                    = 5,
  parameter int           NumLocalPorts               = 1,
  parameter int           NumVC           [NumPorts]  =
            {1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 4+NumLocalPorts-1},
            // Num VC from dir N,E,S,W,L0(,L1,L2,L3): 1313 for XY routing
  parameter int           NumVCMax                    = NumPorts - 1,
  parameter int           NumVCWidth                  = 2,
  parameter type          flit_t                      = logic,
  parameter type          hdr_t                       = logic,
  parameter int           DataLength                  = $bits(flit_t) - $bits(hdr_t),
  parameter type          flit_payload_t              = logic[DataLength-1:0],
  parameter route_algo_e  RouteAlgo                   = XYRouting
) (
  input flit_payload_t  [NumPorts-1:0][NumVCMax-1:0]    vc_data_head_i,
  input hdr_t           [NumPorts-1:0]                  ctrl_head_per_inport_i,
  input route_direction_e[NumPorts-1:0]                look_ahead_routing_sel_i,
  input logic           [NumPorts-1:0][NumVCWidth-1:0]  vc_assignment_id_i,
  input logic           [NumPorts-1:0]                  last_bits_sel_i,
  input logic           [NumPorts-1:0][NumVCMax-1:0]    read_vc_id_oh_i,
  input logic           [NumPorts-1:0][NumPorts-1:0]    inport_id_oh_per_output_i,
  output flit_t         [NumPorts-1:0]                  data_o
);

flit_payload_t [NumPorts-1:0] data_head_per_inport;

// select data head per inport

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_select_data_head
  floo_mux #(
    .NumInputs        (NumVC[in_port]),
    .DataWidth        (DataLength)
  ) i_floo_mux_select_data_head (
    .sel_i            (read_vc_id_oh_i          [in_port][NumVC[in_port]-1:0]),
    .data_i           (vc_data_head_i           [in_port][NumVC[in_port]-1:0]),
    .data_o           (data_head_per_inport [in_port])
  );
end

if(RouteAlgo != XYRouting) begin : gen_switch_not_XY_routing_optimized
  always_comb begin
    data_o = '0;
    for (int out_port = 0; out_port < NumPorts; out_port++) begin : gen_nXYopt_out
      for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_nXYopt_in
        // dont need to check bits on diagonal
        if(out_port != in_port) begin : gen_nXYopt_out_neq_in
          if(inport_id_oh_per_output_i[out_port][in_port]) begin : gen_nXYopt_found_match
            data_o[out_port].payload          = data_head_per_inport[in_port];
            data_o[out_port].hdr.rob_req      = ctrl_head_per_inport_i[in_port].rob_req;
            data_o[out_port].hdr.rob_idx      = ctrl_head_per_inport_i[in_port].rob_idx;
            data_o[out_port].hdr.dst_id       = ctrl_head_per_inport_i[in_port].dst_id;
            data_o[out_port].hdr.src_id       = ctrl_head_per_inport_i[in_port].src_id;
            data_o[out_port].hdr.atop         = ctrl_head_per_inport_i[in_port].atop;
            data_o[out_port].hdr.axi_ch       = ctrl_head_per_inport_i[in_port].axi_ch;
            data_o[out_port].hdr.vc_id        = vc_assignment_id_i[out_port];
            data_o[out_port].hdr.lookahead    = look_ahead_routing_sel_i[out_port];
            data_o[out_port].hdr.last         = last_bits_sel_i[out_port];
          end
        end
      end
    end
  end
end else begin : gen_switch_XY_routing_optimized
  always_comb begin
    data_o = '0;
    // if XY routing is used, not each bit of inport_id_oh_per_output_i needs to be checked
    for (int out_port = 0; out_port < NumPorts; out_port++) begin : gen_XYopt_out
      for (int in_port = 0; in_port < NumPorts; in_port++) begin : gen_XYopt_in
        // N -> S,L, E->N,S,W,L, S->N,L, W->N,E,S,L
        if(!(in_port == out_port ||
            (out_port == East && (in_port == South || in_port == North)) ||
            (out_port == West && (in_port == South || in_port == North))
              )) begin : gen_XYopt_possible_connection
          if(inport_id_oh_per_output_i[out_port][in_port]) begin : gen_nXYopt_found_match
            data_o[out_port].payload          = data_head_per_inport[in_port];
            data_o[out_port].hdr.rob_req      = ctrl_head_per_inport_i[in_port].rob_req;
            data_o[out_port].hdr.rob_idx      = ctrl_head_per_inport_i[in_port].rob_idx;
            data_o[out_port].hdr.dst_id       = ctrl_head_per_inport_i[in_port].dst_id;
            data_o[out_port].hdr.src_id       = ctrl_head_per_inport_i[in_port].src_id;
            data_o[out_port].hdr.atop         = ctrl_head_per_inport_i[in_port].atop;
            data_o[out_port].hdr.axi_ch       = ctrl_head_per_inport_i[in_port].axi_ch;
            data_o[out_port].hdr.vc_id        = vc_assignment_id_i[out_port];
            data_o[out_port].hdr.lookahead    = look_ahead_routing_sel_i[out_port];
            data_o[out_port].hdr.last         = last_bits_sel_i[out_port];
          end
        end
      end
    end
  end
end

endmodule
