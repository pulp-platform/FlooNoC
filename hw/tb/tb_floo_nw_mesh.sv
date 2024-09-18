// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

module tb_floo_nw_mesh;

  import floo_pkg::*;
  import floo_nw_mesh_noc_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumX = 4;
  localparam int unsigned NumY = 4;
  localparam int unsigned NumHBMChannels = NumY;
  localparam int unsigned NumMax = (NumX > NumY) ? NumX : NumY;

  typedef axi_narrow_in_addr_t addr_t;
  localparam int unsigned HBMLatency = 100;
  localparam addr_t HBMSize = 48'h10000; // 64KB
  localparam addr_t MemSize = HBMSize;

  logic clk, rst_n;
  logic [NumX-1:0][NumY-1:0][1:0] end_of_sim;

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

  axi_narrow_in_req_t  [NumX-1:0][NumY-1:0] cluster_narrow_in_req;
  axi_narrow_in_rsp_t  [NumX-1:0][NumY-1:0] cluster_narrow_in_rsp;
  axi_narrow_out_req_t [NumX-1:0][NumY-1:0] cluster_narrow_out_req;
  axi_narrow_out_rsp_t [NumX-1:0][NumY-1:0] cluster_narrow_out_rsp;
  axi_wide_in_req_t  [NumX-1:0][NumY-1:0] cluster_wide_in_req;
  axi_wide_in_rsp_t  [NumX-1:0][NumY-1:0] cluster_wide_in_rsp;
  axi_wide_out_req_t [NumX-1:0][NumY-1:0] cluster_wide_out_req;
  axi_wide_out_rsp_t [NumX-1:0][NumY-1:0] cluster_wide_out_rsp;

  axi_narrow_out_req_t [NumHBMChannels-1:0] hbm_narrow_req;
  axi_narrow_out_rsp_t [NumHBMChannels-1:0] hbm_narrow_rsp;
  axi_wide_out_req_t [NumHBMChannels-1:0] hbm_wide_req;
  axi_wide_out_rsp_t [NumHBMChannels-1:0] hbm_wide_rsp;

  ///////////////////
  //   HBM Model   //
  ///////////////////

  localparam axi_cfg_t AxiCfgJoin = floo_pkg::axi_join_cfg(AxiCfgN, AxiCfgW);
  typedef logic [AxiCfgJoin.OutIdWidth-1:0] hbm_id_t;
  typedef logic [AxiCfgJoin.UserWidth-1:0] hbm_user_t;

  `AXI_TYPEDEF_ALL_CT(hbm_axi, hbm_axi_req_t, hbm_axi_rsp_t, axi_wide_out_addr_t, hbm_id_t, axi_wide_out_data_t, axi_wide_out_strb_t, hbm_user_t)

  hbm_axi_req_t [NumHBMChannels-1:0]  hbm_req;
  hbm_axi_rsp_t [NumHBMChannels-1:0]  hbm_rsp;

  floo_nw_join #(
    .AxiCfgN              ( axi_cfg_swap_iw(AxiCfgN)    ),
    .AxiCfgW              ( axi_cfg_swap_iw(AxiCfgW)    ),
    .AxiCfgJoin           ( axi_cfg_swap_iw(AxiCfgJoin) ),
    .axi_narrow_req_t     ( axi_narrow_out_req_t        ),
    .axi_narrow_rsp_t     ( axi_narrow_out_rsp_t        ),
    .axi_wide_req_t       ( axi_wide_out_req_t          ),
    .axi_wide_rsp_t       ( axi_wide_out_rsp_t          ),
    .axi_req_t            ( hbm_axi_req_t               ),
    .axi_rsp_t            ( hbm_axi_rsp_t               )
  ) i_floo_nw_join [NumHBMChannels-1:0] (
    .clk_i            ( clk             ),
    .rst_ni           ( rst_n           ),
    .test_enable_i    ( 1'b0            ),
    .axi_narrow_req_i ( hbm_narrow_req  ),
    .axi_narrow_rsp_o ( hbm_narrow_rsp  ),
    .axi_wide_req_i   ( hbm_wide_req    ),
    .axi_wide_rsp_o   ( hbm_wide_rsp    ),
    .axi_req_o        ( hbm_req         ),
    .axi_rsp_i        ( hbm_rsp         )
  );

  floo_hbm_model #(
    .TA           ( ApplTime              ),
    .TT           ( TestTime              ),
    .Latency      ( HBMLatency            ),
    .NumChannels  ( 1                     ),
    .AddrWidth    ( AxiCfgJoin.AddrWidth  ),
    .DataWidth    ( AxiCfgJoin.DataWidth  ),
    .UserWidth    ( AxiCfgJoin.UserWidth  ),
    .IdWidth      ( AxiCfgJoin.OutIdWidth ),
    .axi_req_t    ( hbm_axi_req_t         ),
    .axi_rsp_t    ( hbm_axi_rsp_t         ),
    .aw_chan_t    ( hbm_axi_aw_chan_t     ),
    .w_chan_t     ( hbm_axi_w_chan_t      ),
    .b_chan_t     ( hbm_axi_b_chan_t      ),
    .ar_chan_t    ( hbm_axi_ar_chan_t     ),
    .r_chan_t     ( hbm_axi_r_chan_t      )
  ) i_floo_hbm_model [NumHBMChannels-1:0] (
    .clk_i      ( clk     ),
    .rst_ni     ( rst_n   ),
    .hbm_req_i  ( hbm_req ),
    .hbm_rsp_o  ( hbm_rsp )
  );

  ////////////////////////
  //   DMA Model Mesh   //
  ////////////////////////

  function automatic addr_t get_base_addr(int unsigned x, int unsigned y);
    foreach (Sam[i]) begin
      if (Sam[i].idx.x == x && Sam[i].idx.y == y) begin
        return Sam[i].start_addr;
      end
      $error("No base address found for x=%0d, y=%0d", x, y);
    end

  endfunction

  for (genvar x = 0; x < NumX; x++) begin : gen_x
    for (genvar y = 0; y < NumX; y++) begin : gen_y
      localparam string NarrowDmaName = $sformatf("narrow_dma_%0d_%0d", x, y);
      localparam string WideDmaName   = $sformatf("wide_dma_%0d_%0d", x, y);

      localparam addr_t MemBaseAddr = get_base_addr(x+1, y);
      localparam int unsigned Index = x * NumX + y;

      floo_dma_test_node #(
        .TA             ( ApplTime                                  ),
        .TT             ( TestTime                                  ),
        .AxiCfg         ( axi_cfg_swap_iw(AxiCfgN)                  ),
        .MemBaseAddr    ( MemBaseAddr                               ),
        .MemSize        ( MemSize                                   ),
        .NumAxInFlight  ( 2*floo_test_pkg::ChimneyCfg.MaxTxnsPerId  ),
        .axi_in_req_t   ( axi_narrow_out_req_t                      ),
        .axi_in_rsp_t   ( axi_narrow_out_rsp_t                      ),
        .axi_out_req_t  ( axi_narrow_in_req_t                       ),
        .axi_out_rsp_t  ( axi_narrow_in_rsp_t                       ),
        .JobId          ( 100 + Index                               )
      ) i_narrow_dma_node (
        .clk_i          ( clk                           ),
        .rst_ni         ( rst_n                         ),
        .axi_in_req_i   ( cluster_narrow_out_req[x][y]  ),
        .axi_in_rsp_o   ( cluster_narrow_out_rsp[x][y]  ),
        .axi_out_req_o  ( cluster_narrow_in_req[x][y]   ),
        .axi_out_rsp_i  ( cluster_narrow_in_rsp[x][y]   ),
        .end_of_sim_o   ( end_of_sim[x][y][0]           )
      );

      floo_dma_test_node #(
        .TA             ( ApplTime                                  ),
        .TT             ( TestTime                                  ),
        .AxiCfg         ( axi_cfg_swap_iw(AxiCfgW)                  ),
        .MemBaseAddr    ( MemBaseAddr                               ),
        .MemSize        ( MemSize                                   ),
        .NumAxInFlight  ( 2*floo_test_pkg::ChimneyCfg.MaxTxnsPerId  ),
        .axi_in_req_t   ( axi_wide_out_req_t                        ),
        .axi_in_rsp_t   ( axi_wide_out_rsp_t                        ),
        .axi_out_req_t  ( axi_wide_in_req_t                         ),
        .axi_out_rsp_t  ( axi_wide_in_rsp_t                         ),
        .JobId          ( Index                                     )
      ) i_wide_dma_node (
        .clk_i          ( clk                         ),
        .rst_ni         ( rst_n                       ),
        .axi_in_req_i   ( cluster_wide_out_req[x][y]  ),
        .axi_in_rsp_o   ( cluster_wide_out_rsp[x][y]  ),
        .axi_out_req_o  ( cluster_wide_in_req[x][y]   ),
        .axi_out_rsp_i  ( cluster_wide_in_rsp[x][y]   ),
        .end_of_sim_o   ( end_of_sim[x][y][1]         )
      );

      axi_bw_monitor #(
        .req_t      ( axi_narrow_in_req_t ),
        .rsp_t      ( axi_narrow_in_rsp_t ),
        .AxiIdWidth ( AxiCfgN.InIdWidth   ),
        .Name       ( NarrowDmaName       )
      ) i_axi_narrow_bw_monitor (
        .clk_i          ( clk                         ),
        .en_i           ( rst_n                       ),
        .end_of_sim_i   ( end_of_sim[x][y][0]         ),
        .req_i          ( cluster_narrow_in_req[x][y] ),
        .rsp_i          ( cluster_narrow_in_rsp[x][y] ),
        .ar_in_flight_o (                             ),
        .aw_in_flight_o (                             )
        );

      axi_bw_monitor #(
        .req_t      ( axi_wide_in_req_t   ),
        .rsp_t      ( axi_wide_in_rsp_t   ),
        .AxiIdWidth ( AxiCfgW.InIdWidth   ),
        .Name       ( WideDmaName         )
      ) i_axi_wide_bw_monitor (
        .clk_i          ( clk                       ),
        .en_i           ( rst_n                     ),
        .end_of_sim_i   ( end_of_sim[x][y][1]       ),
        .req_i          ( cluster_wide_in_req[x][y] ),
        .rsp_i          ( cluster_wide_in_rsp[x][y] ),
        .ar_in_flight_o (                           ),
        .aw_in_flight_o (                           )
        );
    end
  end


  /////////////////////////
  //   Network-on-Chip   //
  /////////////////////////

  floo_nw_mesh_noc i_floo_nw_mesh_noc (
    .clk_i                    ( clk                     ),
    .rst_ni                   ( rst_n                   ),
    .test_enable_i            ( 1'b0                    ),
    .cluster_narrow_in_req_i  ( cluster_narrow_in_req   ),
    .cluster_narrow_in_rsp_o  ( cluster_narrow_in_rsp   ),
    .cluster_narrow_out_req_o ( cluster_narrow_out_req  ),
    .cluster_narrow_out_rsp_i ( cluster_narrow_out_rsp  ),
    .cluster_wide_in_req_i    ( cluster_wide_in_req     ),
    .cluster_wide_in_rsp_o    ( cluster_wide_in_rsp     ),
    .cluster_wide_out_req_o   ( cluster_wide_out_req    ),
    .cluster_wide_out_rsp_i   ( cluster_wide_out_rsp    ),
    .hbm_narrow_out_req_o     ( hbm_narrow_req          ),
    .hbm_narrow_out_rsp_i     ( hbm_narrow_rsp          ),
    .hbm_wide_out_req_o       ( hbm_wide_req            ),
    .hbm_wide_out_rsp_i       ( hbm_wide_rsp            )
  );


  initial begin
    wait(&end_of_sim);
    // Wait for some time
    repeat (2) @(posedge clk);
    // Stop the simulation
    $stop;
  end

endmodule
