// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A FIFO buffer with configurable depth
module floo_fifo #(
  parameter int unsigned  NumChannels     = 32'd2, // 2 for bi-directional channels
  parameter int unsigned  NumVirtChannels = 32'd1,
  parameter int unsigned  NumPhysChannels = 32'd1,
  parameter int unsigned  FifoDepth       = 32'd1,
  parameter type          flit_t          = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,

  input  logic [NumChannels-1:0][NumVirtChannels-1:0] valid_i,
  output logic [NumChannels-1:0][NumVirtChannels-1:0] ready_o,
  input  flit_t[NumChannels-1:0][NumPhysChannels-1:0] data_i,

  output logic [NumChannels-1:0][NumVirtChannels-1:0] valid_o,
  input  logic [NumChannels-1:0][NumVirtChannels-1:0] ready_i,
  output flit_t[NumChannels-1:0][NumPhysChannels-1:0] data_o
);

  if (FifoDepth == 0) begin : gen_no_fifo
    // Degenerate case
    assign valid_o = valid_i;
    assign ready_o = ready_i;
    assign data_o  = data_i;
  end else begin : gen_floo_fifo

    // Generate the buffers
    if (NumPhysChannels == 1) begin : gen_virt_channels

      logic [NumChannels-1:0][NumVirtChannels-1:0]  ready_in, valid_out;
      flit_t [NumChannels-1:0][NumVirtChannels-1:0] data_out;

      for (genvar n = 0; n < NumChannels; n++) begin : gen_channel
        for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_channel
          stream_fifo #(
            .DEPTH        ( FifoDepth ),
            .T            ( flit_t    ),
            .FALL_THROUGH ( 1'b0      )
          ) i_stream_fifo (
            .clk_i      ( clk_i           ),
            .rst_ni     ( rst_ni          ),
            .testmode_i ( test_enable_i   ),
            .flush_i    ( 1'b0            ),
            .usage_o    (                 ),
            .data_i     ( data_i[n]       ),
            .valid_i    ( valid_i[n][v]   ),
            .ready_o    ( ready_o[n][v]   ),
            .data_o     ( data_out[n][v]  ),
            .valid_o    ( valid_out[n][v] ),
            .ready_i    ( ready_in[n][v]  )
          );
        end

        // TODO(fischeti): Is an arbiter necessary here?
        floo_vc_arbiter #(
          .NumVirtChannels(NumVirtChannels),
          .flit_t(flit_t)
        ) i_floo_vc_arbiter (
          .clk_i      ( clk_i         ),
          .rst_ni     ( rst_ni        ),
          .valid_i    ( valid_out[n]  ),
          .ready_o    ( ready_in[n]   ),
          .data_i     ( data_out[n]   ),
          .data_o     ( data_o[n]     ),
          .valid_o    ( valid_o[n]    ),
          .ready_i    ( ready_i[n]    )
        );
      end
    end else if (NumVirtChannels == NumPhysChannels) begin : gen_phys_channels
      for (genvar n = 0; n < NumChannels; n++) begin : gen_channel
        for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_channel
          stream_fifo #(
            .DEPTH        ( FifoDepth ),
            .T            ( flit_t    ),
            .FALL_THROUGH ( 1'b0      )
          ) i_stream_fifo (
            .clk_i      ( clk_i         ),
            .rst_ni     ( rst_ni        ),
            .testmode_i ( test_enable_i ),
            .flush_i    ( 1'b0          ),
            .usage_o    (               ),
            .data_i     ( data_i[n][v]  ),
            .valid_i    ( valid_i[n][v] ),
            .ready_o    ( ready_o[n][v] ),
            .data_o     ( data_o[n][v]  ),
            .valid_o    ( valid_o[n][v] ),
            .ready_i    ( ready_i[n][v] )
          );
        end
      end
    end else begin : gen_not_supported
      $fatal(1, "unimplemented");
    end
  end

endmodule
