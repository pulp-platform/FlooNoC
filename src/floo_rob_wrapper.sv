// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A wrapper of all available reorder buffers
module floo_rob_wrapper
  import floo_pkg::*;
#(
  /// Type of reorder buffer to use
  parameter rob_type_e   RoBType = NormalRoB,
  /// Maximum number of transactions in flight per ID which *require* reordering
  parameter int unsigned MaxRoTxnsPerId = 32'd32,
  /// If the response only consists of small metadata i.e. B channel
  /// In this case no SRAM will be instantied and the response will be
  /// metadata will be stored in normal FFs
  parameter bit          OnlyMetaData = 1'b0,
  /// Size of the reorder buffer
  parameter int unsigned ReorderBufferSize = 32'd64,
  /// Data type of response to be reordered
  parameter type         ax_len_t   = logic,
  parameter type         ax_id_t    = logic,
  parameter type         rsp_chan_t = logic,
  parameter type         rsp_data_t = logic,
  parameter type         rsp_meta_t = logic,
  parameter type         rob_idx_t  = logic,
  parameter type         dest_t     = logic,
  // Type for implementation inputs and outputs
  parameter type         sram_cfg_t = logic
) (
  input  logic      clk_i,
  input  logic      rst_ni,
  input  sram_cfg_t sram_cfg_i,
  input  logic      ax_valid_i,
  output logic      ax_ready_o,
  input  ax_len_t   ax_len_i,
  input  ax_id_t    ax_id_i,
  input  dest_t     ax_dest_i,
  output logic      ax_valid_o,
  input  logic      ax_ready_i,
  output logic      ax_rob_req_o,
  output rob_idx_t  ax_rob_idx_o,
  input  logic      rsp_valid_i,
  output logic      rsp_ready_o,
  input  rsp_chan_t rsp_i,
  input  logic      rsp_rob_req_i,
  input  rob_idx_t  rsp_rob_idx_i,
  input  logic      rsp_last_i,
  output logic      rsp_valid_o,
  input  logic      rsp_ready_i,
  output rsp_chan_t rsp_o
);

  if (RoBType == NormalRoB) begin : gen_normal_rob
    floo_rob #(
      .ReorderBufferSize  ( ReorderBufferSize ),
      .MaxRoTxnsPerId     ( MaxRoTxnsPerId    ),
      .OnlyMetaData       ( OnlyMetaData      ),
      .ax_len_t           ( ax_len_t          ),
      .ax_id_t            ( ax_id_t           ),
      .rsp_chan_t         ( rsp_chan_t        ),
      .rsp_data_t         ( rsp_data_t        ),
      .rsp_meta_t         ( rsp_meta_t        ),
      .rob_idx_t          ( rob_idx_t         ),
      .dest_t             ( dest_t            ),
      .sram_cfg_t         ( sram_cfg_t        )
    ) i_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i,
      .ax_ready_o,
      .ax_len_i,
      .ax_id_i,
      .ax_dest_i,
      .ax_valid_o,
      .ax_ready_i,
      .ax_rob_req_o,
      .ax_rob_idx_o,
      .rsp_valid_i,
      .rsp_ready_o,
      .rsp_i,
      .rsp_rob_req_i,
      .rsp_rob_idx_i,
      .rsp_last_i,
      .rsp_valid_o,
      .rsp_ready_i,
      .rsp_o
    );

  end else if (RoBType == SimpleRoB) begin : gen_simpl_rob
    floo_simple_rob #(
      .ReorderBufferSize  ( ReorderBufferSize ),
      .MaxRoTxnsPerId     ( MaxRoTxnsPerId    ),
      .OnlyMetaData       ( OnlyMetaData      ),
      .ax_len_t           ( ax_len_t          ),
      .rsp_chan_t         ( rsp_chan_t        ),
      .rsp_data_t         ( rsp_data_t        ),
      .rsp_meta_t         ( rsp_meta_t        ),
      .rob_idx_t          ( rob_idx_t         ),
      .dest_t             ( dest_t            ),
      .sram_cfg_t         ( sram_cfg_t        )
    ) i_rob (
      .clk_i,
      .rst_ni,
      .sram_cfg_i,
      .ax_valid_i,
      .ax_ready_o,
      .ax_len_i,
      .ax_dest_i,
      .ax_valid_o,
      .ax_ready_i,
      .ax_rob_req_o,
      .ax_rob_idx_o,
      .rsp_valid_i,
      .rsp_ready_o,
      .rsp_i,
      .rsp_rob_req_i,
      .rsp_rob_idx_i,
      .rsp_last_i,
      .rsp_valid_o,
      .rsp_ready_i,
      .rsp_o
    );

  end else if (RoBType == NoRoB) begin : gen_no_rob

    localparam int unsigned AxiIdBits = $bits(ax_id_i);
    localparam int unsigned CounterWidth = $clog2(MaxRoTxnsPerId);

    logic push, pop;
    logic in_flight;
    dest_t prev_dest;

    // A new transaction can be pushed if it is the first one
    // i.e. `in_flight` is not set or if the previous transaction
    // has the same destination
    assign push = ax_valid_i && (!in_flight || ax_dest_i == prev_dest);
    // Whenever a response arrives we can pop the transaction
    assign pop = rsp_valid_i && rsp_last_i;

    assign ax_valid_o = push;
    assign ax_ready_o = push && ax_ready_i;

    assign ax_rob_req_o = 1'b1;
    assign ax_rob_idx_o = '0;

    assign rsp_ready_o = rsp_ready_i;
    assign rsp_valid_o = rsp_valid_i;
    assign rsp_o = rsp_i;


    axi_demux_id_counters #(
      .AxiIdBits          ( AxiIdBits     ),
      .CounterWidth       ( CounterWidth  ),
      .mst_port_select_t  ( dest_t        )
    ) i_axi_demux_id_counters (
      .clk_i,
      .rst_ni,
      .lookup_axi_id_i              ( ax_id_i             ),
      .lookup_mst_select_o          ( prev_dest           ),
      .lookup_mst_select_occupied_o ( in_flight           ),
      .full_o                       ( /* TODO */          ),
      .push_axi_id_i                ( ax_id_i             ),
      .push_mst_select_i            ( ax_dest_i           ),
      .push_i                       ( push && ax_ready_i  ),  // Only push on handshake
      .inject_axi_id_i              ( '0                  ),
      .inject_i                     ( 1'b0                ),
      .pop_axi_id_i                 ( rsp_i.id            ),
      .pop_i                        ( pop && rsp_ready_i  )  // Only pop on handshake
    );

  end else begin
    $error("Unknown RoB type %0d", RoBType);
  end

endmodule
