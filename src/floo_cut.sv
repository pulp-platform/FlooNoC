// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

/// Spill registers to cut timing paths
module floo_cut #(
  parameter int unsigned  NumChannels     = 32'd2, // 2 for bi-directional channels
  parameter int unsigned  NumVirtChannels = 32'd1,
  parameter int unsigned  NumPhysChannels = 32'd1,
  parameter int unsigned  NumCuts         = 32'd1,
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

    flit_t  [NumChannels-1:0][NumCuts:0] data;
    flit_t  [NumChannels-1:0][NumCuts-1:0][NumVirtChannels-1:0] data_virt;
    logic   [NumChannels-1:0][NumCuts:0][NumVirtChannels-1:0] valid, ready;
    logic   [NumChannels-1:0][NumCuts-1:0][NumVirtChannels-1:0] valid_virt, ready_virt;

    for (genvar n = 0; n < NumChannels; n++) begin : gen_channel

      // Assign input to first element
      assign data[n][0] = data_i[n];
      assign valid[n][0] = valid_i[n];
      assign ready[n][0] = ready_i[n];
      // Assign output to last element
      assign data_o[n] = data[n][NumCuts];
      assign valid_o[n] = valid[n][NumCuts];
      assign ready_o[n] = ready[n][NumCuts];

      for (genvar c = 0; c < NumCuts; c++) begin : gen_cut

        for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt
          spill_register #(
            .T       ( flit_t ),
            .Bypass  ( 1'b0   )
          ) i_floo_spill_reg (
            .clk_i   ( clk_i                ),
            .rst_ni  ( rst_ni               ),
            .valid_i ( valid[n][c][v]       ),
            .ready_o ( ready[n][c+1][v]     ),
            .data_i  ( data[n][c]           ),
            .valid_o ( valid_virt[n][c][v]  ),
            .ready_i ( ready_virt[n][c][v]  ),
            .data_o  ( data_virt[n][c][v]   )
          );
        end

        // TODO(fischeti): Is an arbiter necessary here?
        floo_vc_arbiter #(
          .NumVirtChannels(NumVirtChannels),
          .NumPhysChannels(NumPhysChannels),
          .flit_t(flit_t)
        ) i_floo_vc_arbiter (
          .clk_i      ( clk_i             ),
          .rst_ni     ( rst_ni            ),
          .valid_i    ( valid_virt[n][c]  ),
          .ready_o    ( ready_virt[n][c]  ),
          .data_i     ( data_virt[n][c]   ),
          .data_o     ( data[n][c+1]      ),
          .valid_o    ( valid[n][c+1]     ),
          .ready_i    ( ready[n][c]       )
        );
      end

    end
  end

endmodule
