// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

module tb_floo_vc_dma_mesh;

  import floo_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumX = 4;
  localparam int unsigned NumY = 4;
  localparam int unsigned NumMax = (NumX > NumY) ? NumX : NumY;

  typedef logic[$clog2(NumX+2)-1:0] x_bits_t;
  typedef logic[$clog2(NumY+2)-1:0] y_bits_t;
  typedef logic [2:0] vc_id_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)
  `FLOO_TYPEDEF_VC_HDR_T(hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic, vc_id_t)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, floo_test_pkg::AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, floo_test_pkg::AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in,
      floo_test_pkg::AxiCfgN, floo_test_pkg::AxiCfgW, hdr_t)
  `FLOO_TYPEDEF_VC_NW_LINK_ALL(vc_req, vc_rsp, vc_wide, req, rsp, wide, vc_id_t)

  function automatic chimney_cfg_t gen_cut_rsp_cfg();
    chimney_cfg_t cfg = floo_pkg::ChimneyDefaultCfg;
    cfg.CutRsp = 1'b1;
    return cfg;
  endfunction

  localparam chimney_cfg_t ChimneyCfg = gen_cut_rsp_cfg();

  localparam int unsigned HBMLatency = 100;
  localparam axi_narrow_addr_t HBMSize = 48'h10000; // 64KB
  localparam axi_narrow_addr_t MemSize = HBMSize;

  localparam int unsigned ChannelFifoDepth = 2;
  localparam int unsigned WormholeVCDepth = 3;  // >= ChannelFifoDepth
  localparam int unsigned FixedWormholeVC = 1;  // send all Wormhole flits to same VC
  localparam int unsigned AllowVCOverflow = 1;  // 1: FVADA, 0: fixed VC, direction based
  localparam int unsigned AllowOverflowFromDeeperVC = 1; // can be overwritten by AllowVCOverflow=0
  localparam int unsigned UpdateRRArbIfNotSent = 0; // does not work
  localparam int unsigned CreditShortcut = 1;   // 1: if receive free credit from correct vc, send
  localparam int unsigned NumVCLocal = 1;       // 4 would be 1 per direction
  localparam int unsigned Only1VC = 0;          // tiny standart router
  localparam int unsigned SingleStage = 0;      // 0: standard 2 stage router, 1: single stage

  logic clk, rst_n;

  /////////////////////
  //   AXI Signals   //
  /////////////////////

  axi_narrow_in_req_t   [NumX-1:0][NumY-1:0] narrow_man_req;
  axi_narrow_in_rsp_t   [NumX-1:0][NumY-1:0] narrow_man_rsp;
  axi_wide_in_req_t     [NumX-1:0][NumY-1:0] wide_man_req;
  axi_wide_in_rsp_t     [NumX-1:0][NumY-1:0] wide_man_rsp;

  axi_narrow_out_req_t  [NumX-1:0][NumY-1:0] narrow_sub_req;
  axi_narrow_out_rsp_t  [NumX-1:0][NumY-1:0] narrow_sub_rsp;
  axi_wide_out_req_t    [NumX-1:0][NumY-1:0] wide_sub_req;
  axi_wide_out_rsp_t    [NumX-1:0][NumY-1:0] wide_sub_rsp;

  axi_narrow_out_req_t  [West:North][NumMax-1:0] narrow_hbm_req;
  axi_narrow_out_rsp_t  [West:North][NumMax-1:0] narrow_hbm_rsp;
  axi_wide_out_req_t    [West:North][NumMax-1:0] wide_hbm_req;
  axi_wide_out_rsp_t    [West:North][NumMax-1:0] wide_hbm_rsp;

  /////////////////////
  //   NoC Signals   //
  /////////////////////


  floo_vc_req_t [NumX-1:0][NumY-1:0] narrow_chimney_man_req, narrow_chimney_sub_req;
  floo_vc_rsp_t [NumX-1:0][NumY-1:0] narrow_chimney_man_rsp, narrow_chimney_sub_rsp;
  floo_vc_wide_t       [NumX-1:0][NumY-1:0] wide_chimney_man, wide_chimney_sub;

  floo_vc_req_t [NumX:0][NumY-1:0] req_hor_pos;
  floo_vc_req_t [NumX:0][NumY-1:0] req_hor_neg;
  floo_vc_req_t [NumY:0][NumX-1:0] req_ver_pos;
  floo_vc_req_t [NumY:0][NumX-1:0] req_ver_neg;
  floo_vc_rsp_t [NumX:0][NumY-1:0] rsp_hor_pos;
  floo_vc_rsp_t [NumX:0][NumY-1:0] rsp_hor_neg;
  floo_vc_rsp_t [NumY:0][NumX-1:0] rsp_ver_pos;
  floo_vc_rsp_t [NumY:0][NumX-1:0] rsp_ver_neg;
  floo_vc_wide_t [NumX:0][NumY-1:0] wide_hor_pos;
  floo_vc_wide_t [NumX:0][NumY-1:0] wide_hor_neg;
  floo_vc_wide_t [NumY:0][NumX-1:0] wide_ver_pos;
  floo_vc_wide_t [NumY:0][NumX-1:0] wide_ver_neg;


  logic [NumX-1:0][NumY-1:0][1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  ////////////////////////////////
  //   HBM Model on left side   //
  ////////////////////////////////

  floo_hbm_model #(
    .TA           ( ApplTime                          ),
    .TT           ( TestTime                          ),
    .Latency      ( HBMLatency                        ),
    .NumChannels  ( 1                                 ),
    .AddrWidth    ( floo_test_pkg::AxiCfgW.AddrWidth  ),
    .DataWidth    ( floo_test_pkg::AxiCfgW.DataWidth  ),
    .UserWidth    ( floo_test_pkg::AxiCfgW.UserWidth  ),
    .IdWidth      ( floo_test_pkg::AxiCfgW.OutIdWidth ),
    .axi_req_t    ( axi_wide_out_req_t                ),
    .axi_rsp_t    ( axi_wide_out_rsp_t                ),
    .aw_chan_t    ( axi_wide_out_aw_chan_t            ),
    .w_chan_t     ( axi_wide_out_w_chan_t             ),
    .b_chan_t     ( axi_wide_out_b_chan_t             ),
    .ar_chan_t    ( axi_wide_out_ar_chan_t            ),
    .r_chan_t     ( axi_wide_out_r_chan_t             )
  ) i_floo_wide_hbm_model [West:North][NumMax-1:0] (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .hbm_req_i  ( wide_hbm_req  ),
    .hbm_rsp_o  ( wide_hbm_rsp  )
  );

  floo_hbm_model #(
    .TA           ( ApplTime                          ),
    .TT           ( TestTime                          ),
    .Latency      ( HBMLatency                        ),
    .NumChannels  ( 1                                 ),
    .AddrWidth    ( floo_test_pkg::AxiCfgN.AddrWidth  ),
    .DataWidth    ( floo_test_pkg::AxiCfgN.DataWidth  ),
    .UserWidth    ( floo_test_pkg::AxiCfgN.UserWidth  ),
    .IdWidth      ( floo_test_pkg::AxiCfgN.OutIdWidth ),
    .axi_req_t    ( axi_narrow_out_req_t              ),
    .axi_rsp_t    ( axi_narrow_out_rsp_t              ),
    .aw_chan_t    ( axi_narrow_out_aw_chan_t          ),
    .w_chan_t     ( axi_narrow_out_w_chan_t           ),
    .b_chan_t     ( axi_narrow_out_b_chan_t           ),
    .ar_chan_t    ( axi_narrow_out_ar_chan_t          ),
    .r_chan_t     ( axi_narrow_out_r_chan_t           )
  ) i_floo_narrow_hbm_model [West:North][NumMax-1:0] (
    .clk_i      ( clk             ),
    .rst_ni     ( rst_n           ),
    .hbm_req_i  ( narrow_hbm_req  ),
    .hbm_rsp_o  ( narrow_hbm_rsp  )
  );

  for (genvar i = North; i <= West; i++) begin : gen_hbm_chimneys

    localparam int unsigned NumChimneys = (i == North || i == South) ? NumX : NumY;

    floo_vc_req_t [NumChimneys-1:0] req_hbm_in, req_hbm_out;
    floo_vc_rsp_t [NumChimneys-1:0] rsp_hbm_in, rsp_hbm_out;
    floo_vc_wide_t [NumChimneys-1:0]       wide_hbm_in, wide_hbm_out;
    id_t [NumChimneys-1:0]           xy_id_hbm;

    if (i == North) begin : gen_north_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: j+1, y: NumY+1, port_id: 0};
      end
      assign req_hbm_in = req_ver_pos[NumY];
      assign rsp_hbm_in = rsp_ver_pos[NumY];
      assign wide_hbm_in = wide_ver_pos[NumY];
      assign req_ver_neg[NumY] = req_hbm_out;
      assign rsp_ver_neg[NumY] = rsp_hbm_out;
      assign wide_ver_neg[NumY] = wide_hbm_out;
    end
    else if (i == South) begin : gen_south_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: j+1, y: 0, port_id: 0};
      end
      assign req_hbm_in = req_ver_neg[0];
      assign rsp_hbm_in = rsp_ver_neg[0];
      assign wide_hbm_in = wide_ver_neg[0];
      assign req_ver_pos[0] = req_hbm_out;
      assign rsp_ver_pos[0] = rsp_hbm_out;
      assign wide_ver_pos[0] = wide_hbm_out;
    end
    else if (i == East) begin : gen_east_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: NumX+1, y: j+1, port_id: 0};
      end
      assign req_hbm_in = req_hor_pos[NumX];
      assign rsp_hbm_in = rsp_hor_pos[NumX];
      assign wide_hbm_in = wide_hor_pos[NumX];
      assign req_hor_neg[NumX] = req_hbm_out;
      assign rsp_hor_neg[NumX] = rsp_hbm_out;
      assign wide_hor_neg[NumX] = wide_hbm_out;
    end
    else if (i == West) begin : gen_west_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: 0, y: j+1, port_id: 0};
      end
      assign req_hbm_in = req_hor_neg[0];
      assign rsp_hbm_in = rsp_hor_neg[0];
      assign wide_hbm_in = wide_hor_neg[0];
      assign req_hor_pos[0] = req_hbm_out;
      assign rsp_hor_pos[0] = rsp_hbm_out;
      assign wide_hor_pos[0] = wide_hbm_out;
    end

    floo_vc_narrow_wide_chimney #(
      .AxiCfgN              ( floo_test_pkg::AxiCfgN                 ),
      .AxiCfgW              ( floo_test_pkg::AxiCfgW                 ),
      .ChimneyCfgN          ( ChimneyCfg                             ),
      .ChimneyCfgW          ( ChimneyCfg                             ),
      .RouteCfg             ( floo_test_pkg::RouteCfg                ),
      .OutputDir            ( route_direction_e'(i)                  ),
      .NumVC                ( Only1VC? 1 : (i==North||i==South)? 2:4 ),
      .InputFifoDepth       ( WormholeVCDepth                        ),
      .VCDepth              ( ChannelFifoDepth                       ),
      .CreditShortcut       ( CreditShortcut                         ),
      .AllowVCOverflow      ( AllowVCOverflow                        ),
      .FixedWormholeVC      ( FixedWormholeVC                        ),
      .WormholeVCId         ( i==East? 2: i==West? 1: 0              ),
      .WormholeVCDepth      ( WormholeVCDepth                        ),
      .hdr_t                ( hdr_t                                  ),
      .id_t                 ( id_t                                   ),
      .vc_id_t              ( vc_id_t                                ),
      .axi_narrow_in_req_t  ( axi_narrow_in_req_t                    ),
      .axi_narrow_in_rsp_t  ( axi_narrow_in_rsp_t                    ),
      .axi_narrow_out_req_t ( axi_narrow_out_req_t                   ),
      .axi_narrow_out_rsp_t ( axi_narrow_out_rsp_t                   ),
      .axi_wide_in_req_t    ( axi_wide_in_req_t                      ),
      .axi_wide_in_rsp_t    ( axi_wide_in_rsp_t                      ),
      .axi_wide_out_req_t   ( axi_wide_out_req_t                     ),
      .axi_wide_out_rsp_t   ( axi_wide_out_rsp_t                     ),
      .floo_vc_req_t        ( floo_vc_req_t                          ),
      .floo_vc_rsp_t        ( floo_vc_rsp_t                          ),
      .floo_vc_wide_t       ( floo_vc_wide_t                         )
    ) i_hbm_chimney [NumChimneys-1:0] (
      .clk_i                ( clk               ),
      .rst_ni               ( rst_n             ),
      .sram_cfg_i           ( '0                ),
      .test_enable_i        ( 1'b0              ),
      .id_i                 ( xy_id_hbm         ),
      .route_table_i        ( '0                ),
      .id_route_map_i       ( '0                ),
      .axi_narrow_in_req_i  ( '0                ),
      .axi_narrow_in_rsp_o  (                   ),
      .axi_narrow_out_req_o ( narrow_hbm_req[i] ),
      .axi_narrow_out_rsp_i ( narrow_hbm_rsp[i] ),
      .axi_wide_in_req_i    ( '0                ),
      .axi_wide_in_rsp_o    (                   ),
      .axi_wide_out_req_o   ( wide_hbm_req[i]   ),
      .axi_wide_out_rsp_i   ( wide_hbm_rsp[i]   ),
      .floo_req_i           ( req_hbm_in        ),
      .floo_req_o           ( req_hbm_out       ),
      .floo_rsp_i           ( rsp_hbm_in        ),
      .floo_rsp_o           ( rsp_hbm_out       ),
      .floo_wide_i          ( wide_hbm_in       ),
      .floo_wide_o          ( wide_hbm_out      )
    );
  end



  //////////////////
  //   NoC Mesh   //
  //////////////////

  for (genvar x = 0; x < NumX; x++) begin : gen_x
    for (genvar y = 0; y < NumY; y++) begin : gen_y
      id_t current_id;
      localparam string NarrowDmaName = $sformatf("narrow_dma_%0d_%0d", x, y);
      localparam string WideDmaName   = $sformatf("wide_dma_%0d_%0d", x, y);
      floo_vc_req_t [NumDirections-1:0] req_out, req_in;
      floo_vc_rsp_t [NumDirections-1:0] rsp_out, rsp_in;
      floo_vc_wide_t       [NumDirections-1:0] wide_out, wide_in;

      localparam int unsigned Index = y * NumX + x+1;
      localparam axi_narrow_addr_t MemBaseAddr =
          (x+1) << floo_test_pkg::RouteCfg.XYAddrOffsetX |
          (y+1) << floo_test_pkg::RouteCfg.XYAddrOffsetY;
      assign current_id = '{x: x+1, y: y+1, port_id: 0};

      floo_dma_test_node #(
        .TA             ( ApplTime                                  ),
        .TT             ( TestTime                                  ),
        .AxiCfg         ( axi_cfg_swap_iw(floo_test_pkg::AxiCfgN)   ),
        .MemBaseAddr    ( MemBaseAddr                               ),
        .MemSize        ( MemSize                                   ),
        .NumAxInFlight  ( 2*floo_test_pkg::ChimneyCfg.MaxTxnsPerId  ),
        .axi_in_req_t   ( axi_narrow_out_req_t                      ),
        .axi_in_rsp_t   ( axi_narrow_out_rsp_t                      ),
        .axi_out_req_t  ( axi_narrow_in_req_t                       ),
        .axi_out_rsp_t  ( axi_narrow_in_rsp_t                       ),
        .JobId          ( 100 + Index                               )
      ) i_narrow_dma_node (
        .clk_i          ( clk                   ),
        .rst_ni         ( rst_n                 ),
        .axi_in_req_i   ( narrow_sub_req[x][y]  ),
        .axi_in_rsp_o   ( narrow_sub_rsp[x][y]  ),
        .axi_out_req_o  ( narrow_man_req[x][y]  ),
        .axi_out_rsp_i  ( narrow_man_rsp[x][y]  ),
        .end_of_sim_o   ( end_of_sim[x][y][0]   )
      );

      floo_dma_test_node #(
        .TA             ( ApplTime                                  ),
        .TT             ( TestTime                                  ),
        .AxiCfg         ( axi_cfg_swap_iw(floo_test_pkg::AxiCfgW)   ),
        .MemBaseAddr    ( MemBaseAddr                               ),
        .MemSize        ( MemSize                                   ),
        .NumAxInFlight  ( 2*floo_test_pkg::ChimneyCfg.MaxTxnsPerId  ),
        .axi_in_req_t   ( axi_wide_out_req_t                        ),
        .axi_in_rsp_t   ( axi_wide_out_rsp_t                        ),
        .axi_out_req_t  ( axi_wide_in_req_t                         ),
        .axi_out_rsp_t  ( axi_wide_in_rsp_t                         ),
        .JobId          ( Index                                     )
      ) i_wide_dma_node (
        .clk_i          ( clk                 ),
        .rst_ni         ( rst_n               ),
        .axi_in_req_i   ( wide_sub_req[x][y]  ),
        .axi_in_rsp_o   ( wide_sub_rsp[x][y]  ),
        .axi_out_req_o  ( wide_man_req[x][y]  ),
        .axi_out_rsp_i  ( wide_man_rsp[x][y]  ),
        .end_of_sim_o   ( end_of_sim[x][y][1] )
      );

      axi_bw_monitor #(
        .req_t      ( axi_narrow_in_req_t               ),
        .rsp_t      ( axi_narrow_in_rsp_t               ),
        .AxiIdWidth ( floo_test_pkg::AxiCfgN.InIdWidth  ),
        .Name       ( NarrowDmaName                     )
      ) i_axi_narrow_bw_monitor (
        .clk_i        ( clk                   ),
        .en_i         ( rst_n                 ),
        .end_of_sim_i ( end_of_sim[x][y][0]   ),
        .req_i        ( narrow_man_req[x][y]  ),
        .rsp_i        ( narrow_man_rsp[x][y]  ),
        .ar_in_flight_o(                      ),
        .aw_in_flight_o(                      )
        );

      axi_bw_monitor #(
        .req_t      ( axi_wide_in_req_t                 ),
        .rsp_t      ( axi_wide_in_rsp_t                 ),
        .AxiIdWidth ( floo_test_pkg::AxiCfgW.InIdWidth  ),
        .Name       ( WideDmaName                       )
      ) i_axi_wide_bw_monitor (
        .clk_i        ( clk                 ),
        .en_i         ( rst_n               ),
        .end_of_sim_i ( end_of_sim[x][y][1] ),
        .req_i        ( wide_man_req[x][y]  ),
        .rsp_i        ( wide_man_rsp[x][y]  ),
        .ar_in_flight_o(                    ),
        .aw_in_flight_o(                    )
        );

      floo_vc_narrow_wide_chimney #(
        .AxiCfgN              ( floo_test_pkg::AxiCfgN    ),
        .AxiCfgW              ( floo_test_pkg::AxiCfgW    ),
        .ChimneyCfgN          ( ChimneyCfg                ),
        .ChimneyCfgW          ( ChimneyCfg                ),
        .RouteCfg             ( floo_test_pkg::RouteCfg   ),
        .OutputDir            ( Eject                     ),
        .InputFifoDepth       ( WormholeVCDepth           ),
        .NumVC                ( NumVCLocal                ),
        .VCDepth              ( ChannelFifoDepth          ),
        .CreditShortcut       ( CreditShortcut            ),
        .AllowVCOverflow      ( AllowVCOverflow           ),
        .FixedWormholeVC      ( FixedWormholeVC           ),
        .WormholeVCId         ( 0                         ),
        .WormholeVCDepth      ( WormholeVCDepth           ),
        .hdr_t                ( hdr_t                     ),
        .id_t                 ( id_t                      ),
        .vc_id_t              ( vc_id_t                   ),
        .axi_narrow_in_req_t  ( axi_narrow_in_req_t       ),
        .axi_narrow_in_rsp_t  ( axi_narrow_in_rsp_t       ),
        .axi_narrow_out_req_t ( axi_narrow_out_req_t      ),
        .axi_narrow_out_rsp_t ( axi_narrow_out_rsp_t      ),
        .axi_wide_in_req_t    ( axi_wide_in_req_t         ),
        .axi_wide_in_rsp_t    ( axi_wide_in_rsp_t         ),
        .axi_wide_out_req_t   ( axi_wide_out_req_t        ),
        .axi_wide_out_rsp_t   ( axi_wide_out_rsp_t        ),
        .floo_vc_req_t        ( floo_vc_req_t             ),
        .floo_vc_rsp_t        ( floo_vc_rsp_t             ),
        .floo_vc_wide_t       ( floo_vc_wide_t            )
      ) i_dma_chimney (
        .clk_i                ( clk                           ),
        .rst_ni               ( rst_n                         ),
        .sram_cfg_i           ( '0                            ),
        .test_enable_i        ( 1'b0                          ),
        .id_i                 ( current_id                    ),
        .route_table_i        ( '0                            ),
        .id_route_map_i       ( '0                            ),
        .axi_narrow_in_req_i  ( narrow_man_req[x][y]          ),
        .axi_narrow_in_rsp_o  ( narrow_man_rsp[x][y]          ),
        .axi_narrow_out_req_o ( narrow_sub_req[x][y]          ),
        .axi_narrow_out_rsp_i ( narrow_sub_rsp[x][y]          ),
        .axi_wide_in_req_i    ( wide_man_req[x][y]            ),
        .axi_wide_in_rsp_o    ( wide_man_rsp[x][y]            ),
        .axi_wide_out_req_o   ( wide_sub_req[x][y]            ),
        .axi_wide_out_rsp_i   ( wide_sub_rsp[x][y]            ),
        .floo_req_i           ( narrow_chimney_sub_req[x][y]  ),
        .floo_req_o           ( narrow_chimney_man_req[x][y]  ),
        .floo_rsp_i           ( narrow_chimney_man_rsp[x][y]  ),
        .floo_rsp_o           ( narrow_chimney_sub_rsp[x][y]  ),
        .floo_wide_i          ( wide_chimney_sub[x][y]        ),
        .floo_wide_o          ( wide_chimney_man[x][y]        )
      );

      floo_vc_narrow_wide_router #(
        .AxiCfgN                    ( floo_test_pkg::AxiCfgN   ),
        .AxiCfgW                    ( floo_test_pkg::AxiCfgW   ),
        .NumPorts                   ( int'(NumDirections)       ),
        .NumVC                      ( Only1VC ?
                                      {1, 1, 1, 1, NumVCLocal} :
                                      {2, 4, 2, 4, NumVCLocal}  ),
        .RouteAlgo                  ( floo_test_pkg::RouteCfg.RouteAlgo ),
        .id_t                       ( id_t                      ),
        .hdr_t                      ( hdr_t                     ),
        .vc_id_t                    ( vc_id_t                   ),
        .NumVCToOut                 ( Only1VC ? {1, 1, 1, 1, 1} :
                                      {y==NumY-1 ? 1 : 2,
                                      x==NumX-1 ? 1 : 4,
                                      y==0 ?      1 : 2,
                                      x==0 ?      1 : 4,
                                      1}),      // only 1 towards hbm
        .VCDepth                    ( ChannelFifoDepth        ),
        .CreditShortcut             ( CreditShortcut          ),
        .AllowVCOverflow            ( AllowVCOverflow         ),
        .FixedWormholeVC            ( FixedWormholeVC         ),
        .SingleStage                ( SingleStage             ),
        .WormholeVCDepth            ( WormholeVCDepth         ),
        .AllowOverflowFromDeeperVC  (AllowOverflowFromDeeperVC),
        .WormholeVCId               ( Only1VC?
                                      {0, 0, 0, 0, 0} :
                                      {0, 1, 0, 2, 0}         ),
        .floo_vc_req_t              ( floo_vc_req_t           ),
        .floo_vc_rsp_t              ( floo_vc_rsp_t           ),
        .floo_vc_wide_t             ( floo_vc_wide_t          )
      ) i_router (
        .clk_i          ( clk         ),
        .rst_ni         ( rst_n       ),
        .id_i           ( current_id  ),
        .id_route_map_i ( '0          ),
        .floo_req_i     ( req_in      ),
        .floo_req_o     ( req_out     ),
        .floo_rsp_i     ( rsp_in      ),
        .floo_rsp_o     ( rsp_out     ),
        .floo_wide_i    ( wide_in     ),
        .floo_wide_o    ( wide_out    )
      );

      // Eject
      assign req_in[Eject] = narrow_chimney_man_req[x][y];
      assign narrow_chimney_sub_req[x][y] = req_out[Eject];
      assign rsp_in[Eject] = narrow_chimney_sub_rsp[x][y];
      assign narrow_chimney_man_rsp[x][y] = rsp_out[Eject];
      assign wide_in[Eject] = wide_chimney_man[x][y];
      assign wide_chimney_sub[x][y] = wide_out[Eject];

      // East
      assign req_in[East] = req_hor_neg[x+1][y];
      assign req_hor_pos[x+1][y] = req_out[East];
      assign rsp_in[East] = rsp_hor_neg[x+1][y];
      assign rsp_hor_pos[x+1][y] = rsp_out[East];
      assign wide_in[East] = wide_hor_neg[x+1][y];
      assign wide_hor_pos[x+1][y] = wide_out[East];

      // West
      assign req_in[West] = req_hor_pos[x][y];
      assign req_hor_neg[x][y] = req_out[West];
      assign rsp_in[West] = rsp_hor_pos[x][y];
      assign rsp_hor_neg[x][y] = rsp_out[West];
      assign wide_in[West] = wide_hor_pos[x][y];
      assign wide_hor_neg[x][y] = wide_out[West];

      // North
      assign req_in[North] = req_ver_neg[y+1][x];
      assign req_ver_pos[y+1][x] = req_out[North];
      assign rsp_in[North] = rsp_ver_neg[y+1][x];
      assign rsp_ver_pos[y+1][x] = rsp_out[North];
      assign wide_in[North] = wide_ver_neg[y+1][x];
      assign wide_ver_pos[y+1][x] = wide_out[North];

      // South
      assign req_in[South] = req_ver_pos[y][x];
      assign req_ver_neg[y][x] = req_out[South];
      assign rsp_in[South] = rsp_ver_pos[y][x];
      assign rsp_ver_neg[y][x] = rsp_out[South];
      assign wide_in[South] = wide_ver_pos[y][x];
      assign wide_ver_neg[y][x] = wide_out[South];

    end
  end

  initial begin
    wait(&end_of_sim);
    // Wait for some time
    repeat (2) @(posedge clk);
    // Stop the simulation
    $stop;
  end

endmodule
