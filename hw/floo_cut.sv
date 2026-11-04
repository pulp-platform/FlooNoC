// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

/// Spill registers to cut timing paths. Every virtual channel gets its own spill register.
/// Supported configurations:
/// - `NumPhysChannels == NumVirtChannels`: each virtual channel has its own valid, ready and data
///   bus, so the paths are fully parallel.
/// - `NumPhysChannels == 1` with `VcImpl == VcNaive`: the virtual channels share one data bus and
///   a `floo_vc_arbiter` after each cut picks the stored flit that drives it.
module floo_cut
  import floo_pkg::*;
#(
  parameter int unsigned  NumChannels     = 32'd2, // 2 for bi-directional channels
  parameter int unsigned  NumVirtChannels = 32'd1,
  parameter int unsigned  NumPhysChannels = 32'd1,
  parameter int unsigned  NumCuts         = 32'd1,
  parameter vc_impl_e     VcImpl          = VcNaive,
  parameter type          flit_t          = logic
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic [NumChannels-1:0][NumVirtChannels-1:0] valid_i,
  output logic [NumChannels-1:0][NumVirtChannels-1:0] ready_o,
  input  flit_t[NumChannels-1:0][NumPhysChannels-1:0] data_i,

  output logic [NumChannels-1:0][NumVirtChannels-1:0] valid_o,
  input  logic [NumChannels-1:0][NumVirtChannels-1:0] ready_i,
  output flit_t[NumChannels-1:0][NumPhysChannels-1:0] data_o
);

  if (NumCuts == 0) begin : gen_no_cuts
    // Degenerate case
    assign valid_o = valid_i;
    assign ready_o = ready_i;
    assign data_o  = data_i;
  end else begin : gen_floo_cuts

    flit_t [NumChannels-1:0][NumCuts:0][NumPhysChannels-1:0] data;
    logic  [NumChannels-1:0][NumCuts:0][NumVirtChannels-1:0] valid, ready;

    for (genvar n = 0; n < NumChannels; n++) begin : gen_channel

      // Assign input to first element
      assign data[n][0] = data_i[n];
      assign valid[n][0] = valid_i[n];
      assign ready[n][NumCuts] = ready_i[n];
      // Assign output to last element
      assign data_o[n] = data[n][NumCuts];
      assign valid_o[n] = valid[n][NumCuts];
      assign ready_o[n] = ready[n][0];

      for (genvar c = 0; c < NumCuts; c++) begin : gen_cut

        if (NumPhysChannels == NumVirtChannels) begin : gen_parallel
          for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt
            cc_spill_register #(
              .data_t  ( flit_t ),
              .Bypass  ( 1'b0   )
            ) i_floo_spill_reg (
              .clk_i   ( clk_i                ),
              .rst_ni  ( rst_ni               ),
              .clr_i   ( 1'b0                 ),
              .valid_i ( valid[n][c][v]       ),
              .ready_o ( ready[n][c][v]       ),
              .data_i  ( data[n][c][v]        ),
              .valid_o ( valid[n][c+1][v]     ),
              .ready_i ( ready[n][c+1][v]     ),
              .data_o  ( data[n][c+1][v]      )
            );
          end
        end else begin : gen_arbitrated
          flit_t [NumVirtChannels-1:0] data_virt;
          logic  [NumVirtChannels-1:0] valid_virt, ready_virt;

          for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt
            cc_spill_register #(
              .data_t  ( flit_t ),
              .Bypass  ( 1'b0   )
            ) i_floo_spill_reg (
              .clk_i   ( clk_i                ),
              .rst_ni  ( rst_ni               ),
              .clr_i   ( 1'b0                 ),
              .valid_i ( valid[n][c][v]       ),
              .ready_o ( ready[n][c][v]       ),
              .data_i  ( data[n][c][0]        ),
              .valid_o ( valid_virt[v]        ),
              .ready_i ( ready_virt[v]        ),
              .data_o  ( data_virt[v]         )
            );
          end

          floo_vc_arbiter #(
            .NumVirtChannels ( NumVirtChannels ),
            .NumPhysChannels ( NumPhysChannels ),
            .VcImpl          ( VcImpl          ),
            .flit_t          ( flit_t          )
          ) i_floo_vc_arbiter (
            .clk_i      ( clk_i             ),
            .rst_ni     ( rst_ni            ),
            .valid_i    ( valid_virt        ),
            .ready_o    ( ready_virt        ),
            .data_i     ( data_virt         ),
            .data_o     ( data[n][c+1]      ),
            .valid_o    ( valid[n][c+1]     ),
            .ready_i    ( ready[n][c+1]     ),
            .credit_i   ( '0                )
          );
        end

      end

    end
  end

  ////////////////
  // Assertions //
  ////////////////

  // Other configurations are not supported. Supporting one shared physical channel with another
  // `VcImpl` needs:
  // - `VcPreemptValid`: nothing in the cut itself (its valid has no combinational dependency on
  //   the downstream ready, unlike `VcNaive`), but a test for the withdrawn valid.
  // - `VcCredit`: the credits must also pass through the cut and the receiver FIFO must be
  //   deeper to cover the added round trip.
  `ASSERT_INIT(SupportedVcConfig,
      (NumPhysChannels == NumVirtChannels) || (NumPhysChannels == 1 && VcImpl == VcNaive),
      "floo_cut: only NumPhysChannels == NumVirtChannels or one physical channel with VcNaive")

endmodule
