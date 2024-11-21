// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

module tb_floo_axi_mesh;

  import floo_pkg::*;
  import floo_axi_mesh_noc_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumX = 4;
  localparam int unsigned NumY = 4;
  localparam int unsigned NumHBMChannels = NumY;
  localparam int unsigned NumMax = (NumX > NumY) ? NumX : NumY;

  typedef axi_in_addr_t addr_t;
  localparam int unsigned HBMLatency = 100;
  localparam addr_t HBMSize = 48'h10000; // 64KB
  localparam addr_t MemSize = HBMSize;

  logic clk, rst_n;
  logic [NumX-1:0][NumY-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  /////////////////////
  //   Axi Signals   //
  /////////////////////

  axi_in_req_t  [NumX-1:0][NumY-1:0] cluster_in_req;
  axi_in_rsp_t  [NumX-1:0][NumY-1:0] cluster_in_rsp;
  axi_out_req_t [NumX-1:0][NumY-1:0] cluster_out_req;
  axi_out_rsp_t [NumX-1:0][NumY-1:0] cluster_out_rsp;

  axi_out_req_t [NumHBMChannels-1:0] hbm_req;
  axi_out_rsp_t [NumHBMChannels-1:0] hbm_rsp;

  ///////////////////
  //   HBM Model   //
  ///////////////////

  floo_hbm_model #(
    .TA           ( ApplTime          ),
    .TT           ( TestTime          ),
    .Latency      ( HBMLatency        ),
    .NumChannels  ( 1                 ),
    .AddrWidth    ( AxiCfg.AddrWidth  ),
    .DataWidth    ( AxiCfg.DataWidth  ),
    .UserWidth    ( AxiCfg.UserWidth  ),
    .IdWidth      ( AxiCfg.OutIdWidth ),
    .axi_req_t    ( axi_out_req_t     ),
    .axi_rsp_t    ( axi_out_rsp_t     ),
    .aw_chan_t    ( axi_out_aw_chan_t ),
    .w_chan_t     ( axi_out_w_chan_t  ),
    .b_chan_t     ( axi_out_b_chan_t  ),
    .ar_chan_t    ( axi_out_ar_chan_t ),
    .r_chan_t     ( axi_out_r_chan_t  )
  ) i_floo_hbm_model [NumHBMChannels-1:0] (
    .clk_i      ( clk     ),
    .rst_ni     ( rst_n   ),
    .hbm_req_i  ( hbm_req ),
    .hbm_rsp_o  ( hbm_rsp )
  );

  ////////////////////////
  //   DMA Model Mesh   //
  ////////////////////////

  for (genvar x = 0; x < NumX; x++) begin : gen_x
    for (genvar y = 0; y < NumY; y++) begin : gen_y
      localparam string DmaName = $sformatf("dma_%0d_%0d", x, y);

      localparam int unsigned Index = x * NumY + y;
      localparam addr_t MemBaseAddr = Sam[ClusterNi00+Index].start_addr;

      floo_dma_test_node #(
        .TA             ( ApplTime                                  ),
        .TT             ( TestTime                                  ),
        .AxiCfg         ( axi_cfg_swap_iw(AxiCfg)                   ),
        .MemBaseAddr    ( MemBaseAddr                               ),
        .MemSize        ( MemSize                                   ),
        .NumAxInFlight  ( 2*floo_test_pkg::ChimneyCfg.MaxTxnsPerId  ),
        .axi_in_req_t   ( axi_out_req_t                             ),
        .axi_in_rsp_t   ( axi_out_rsp_t                             ),
        .axi_out_req_t  ( axi_in_req_t                              ),
        .axi_out_rsp_t  ( axi_in_rsp_t                              ),
        .JobId          ( Index                                     )
      ) i_dma_node (
        .clk_i          ( clk                   ),
        .rst_ni         ( rst_n                 ),
        .axi_in_req_i   ( cluster_out_req[x][y] ),
        .axi_in_rsp_o   ( cluster_out_rsp[x][y] ),
        .axi_out_req_o  ( cluster_in_req[x][y]  ),
        .axi_out_rsp_i  ( cluster_in_rsp[x][y]  ),
        .end_of_sim_o   ( end_of_sim[x][y]      )
      );

      axi_bw_monitor #(
        .req_t      ( axi_in_req_t      ),
        .rsp_t      ( axi_in_rsp_t      ),
        .AxiIdWidth ( AxiCfg.InIdWidth  ),
        .Name       ( DmaName           )
      ) i_axi_bw_monitor (
        .clk_i          ( clk                   ),
        .en_i           ( rst_n                 ),
        .end_of_sim_i   ( end_of_sim[x][y]      ),
        .req_i          ( cluster_in_req[x][y]  ),
        .rsp_i          ( cluster_in_rsp[x][y]  ),
        .ar_in_flight_o (                       ),
        .aw_in_flight_o (                       )
        );
    end
  end


  /////////////////////////
  //   Network-on-Chip   //
  /////////////////////////

  floo_axi_mesh_noc i_floo_axi_mesh_noc (
    .clk_i                  ( clk             ),
    .rst_ni                 ( rst_n           ),
    .test_enable_i          ( 1'b0            ),
    .cluster_axi_in_req_i   ( cluster_in_req  ),
    .cluster_axi_in_rsp_o   ( cluster_in_rsp  ),
    .cluster_axi_out_req_o  ( cluster_out_req ),
    .cluster_axi_out_rsp_i  ( cluster_out_rsp ),
    .hbm_axi_out_req_o      ( hbm_req         ),
    .hbm_axi_out_rsp_i      ( hbm_rsp         )
  );


  initial begin
    wait(&end_of_sim);
    // Wait for some time
    repeat (2) @(posedge clk);
    // Stop the simulation
    $stop;
  end

endmodule
