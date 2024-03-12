// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

module floo_vc_router_switch #(
  parameter int           NumPorts                    = 5,
  parameter int           NumVC           [NumPorts]  =
            {1+NumLocalPorts, 3+NumLocalPorts, 1+NumLocalPorts, 3+NumLocalPorts, 4+NumLocalPorts-1},
            // Num VC from dir N,E,S,W,L0(,L1,L2,L3): 1313 for XY routing
  parameter int           NumVCMax                    = NumPorts - 1,
  parameter type          flit_t                      = logic,
  parameter type          flit_payload_t              = logic,
  parameter int           DataLength                  = $bits(flit_payload_t),
  parameter route_algo_e  RouteAlgo                   = XYRouting
) (
  input flit_payload_t  [NumPorts-1:0][NumVCMax-1:0]    vc_data_head_i,
  input hdr_t           [NumPorts-1:0]                  ctrl_head_per_inport_i,
  input logic           [NumPorts-1:0][NumVCMax-1:0]    read_vc_id_oh_i,
  input logic           [NumPorts-1:0][NumPorts-1:0]    inport_id_oh_per_output_i,
  output flit_t         [NumPorts-1:0]                  data_o
);

flit_payload_t [NumPorts-1:0] sel_data_head_per_inport;

// select data head per inport

for (genvar in_port = 0; in_port < NumPorts; in_port++) begin : gen_select_data_head
  floo_mux #(
    .NumInputs        (NumVC),
    .DataWidth        (DataLength)
  ) i_floo_mux_select_data_head (
    .sel_i            (read_vc_id_oh_i          [in_port]),
    .data_i           (vc_data_head_i           [in_port]),
    .data_o           (sel_data_head_per_inport [in_port])
  );
end





endmodule
