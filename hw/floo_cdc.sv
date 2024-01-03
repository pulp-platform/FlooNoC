// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

/// A Clock-Domain-Crossing (CDC) module implemented with a gray-counter based FIFO.
module floo_cdc #(
  /// Number of virtual channels
  /// Currently only supports 1 virtual channel
  parameter int unsigned  NumVirtChannels = 32'd1,
  /// Number of physical channels
  /// Currently only supports 1 physical channel
  parameter int unsigned  NumPhysChannels = 32'd1,
  /// Fifo log depth of the gray-counter based FIFO
  /// default is 3 (8 entries) which are needed to
  /// guarantee full throughput of the FIFO with 2 sync stages
  /// TODO: Check if this is true
  parameter int unsigned  FifoLogDepth    = 32'd3,
  /// Number of sync stages of read and write pointer
  /// in the gray-counter based FIFO
  parameter int unsigned  SyncStages      = 32'd2,
  /// Flit type of the FIFO
  parameter type          flit_t          = logic
) (
  input  logic src_clk_i,
  input  logic src_rst_ni,
  input  logic src_valid_i,
  output logic src_ready_o,
  input  flit_t src_data_i,

  input  logic dst_clk_i,
  input  logic dst_rst_ni,
  output logic dst_valid_o,
  input  logic dst_ready_i,
  output flit_t dst_data_o
);

  cdc_fifo_gray #(
    .LOG_DEPTH    ( FifoLogDepth  ),
    .SYNC_STAGES  ( SyncStages    ),
    .T            ( flit_t        )
  ) i_cdc_fifo_gray (
    .src_rst_ni   ( src_rst_ni  ),
    .src_clk_i    ( src_clk_i   ),
    .src_data_i   ( src_data_i  ),
    .src_valid_i  ( src_valid_i ),
    .src_ready_o  ( src_ready_o ),
    .dst_rst_ni   ( dst_rst_ni  ),
    .dst_clk_i    ( dst_clk_i   ),
    .dst_data_o   ( dst_data_o  ),
    .dst_valid_o  ( dst_valid_o ),
    .dst_ready_i  ( dst_ready_i )
  );

// Currently only supports 1 virtual/physical channel
`ASSERT_INIT(MultVirtChannels, NumVirtChannels == 1)
`ASSERT_INIT(MultPhysChannels, NumPhysChannels == 1)

endmodule
