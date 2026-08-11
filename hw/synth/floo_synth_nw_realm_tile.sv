// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Gianluca Bellocchi <gianluca.bellocchi@unimore.it>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "register_interface/typedef.svh"

module floo_synth_nw_realm_tile
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
  import floo_synth_collective_pkg::*;
  import endpoint_axi_pkg::*;
  import floo_synth_qos_pkg::*;
  #(
    parameter collective_cfg_idx_e CollectCfgIdx = CollectNone
  ) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  endpoint_axi_pkg::narrow_out_req_t   axi_narrow_in_req_i,
  output endpoint_axi_pkg::narrow_out_resp_t  axi_narrow_in_rsp_o,
  input  endpoint_axi_pkg::wide_out_req_t     axi_wide_in_req_i,
  output endpoint_axi_pkg::wide_out_resp_t    axi_wide_in_rsp_o,
  output endpoint_axi_pkg::wide_in_req_t      axi_wide_out_req_o,
  input  endpoint_axi_pkg::wide_in_resp_t     axi_wide_out_rsp_i,
  input  id_t id_i,
  input  route_t [floo_iomsb(RouteCfg.NumRoutes):0] route_table_i,
  output floo_req_t  [West:North] floo_req_o,
  input  floo_rsp_t  [West:North] floo_rsp_i,
  output floo_wide_t [West:North] floo_wide_o,
  input  floo_req_t  [West:North] floo_req_i,
  output floo_rsp_t  [West:North] floo_rsp_o,
  input  floo_wide_t [West:North] floo_wide_i
);

  localparam floo_pkg::route_cfg_t ActiveRouteCfg = '{
    RouteAlgo:     CollectRouteCfg.RouteAlgo,
    UseIdTable:    CollectRouteCfg.UseIdTable,
    XYAddrOffsetX: CollectRouteCfg.XYAddrOffsetX,
    XYAddrOffsetY: CollectRouteCfg.XYAddrOffsetY,
    CollectiveCfg: '{
      OpCfg:      CollectOpCfgList[CollectCfgIdx],
      NarrRedCfg: CollectRouteCfg.CollectiveCfg.NarrRedCfg,
      WideRedCfg: CollectRouteCfg.CollectiveCfg.WideRedCfg
    },
    default: '0
  };

  localparam floo_pkg::collective_cfg_t ActiveCollectiveCfg = '{
    OpCfg:      CollectOpCfgList[CollectCfgIdx],
    NarrRedCfg: CollectRouteCfg.CollectiveCfg.NarrRedCfg,
    WideRedCfg: CollectRouteCfg.CollectiveCfg.WideRedCfg
  };

  ////////////
  // Router //
  ////////////

  floo_req_t  [int'(NumDirections)-1:0] router_floo_req_in,  router_floo_req_out;
  floo_rsp_t  [int'(NumDirections)-1:0] router_floo_rsp_in,  router_floo_rsp_out;
  floo_wide_t [int'(NumDirections)-1:0] router_floo_wide_in, router_floo_wide_out;

  // Reduction offload ports are unused in this endpoint tile: tie off.
  red_wide_req_t   router_offload_wide_req;
  red_narrow_req_t router_offload_narrow_req;

  floo_nw_router #(
    .AxiCfgN          ( AxiCfgN             ),
    .AxiCfgW          ( AxiCfgW             ),
    .RouteAlgo        ( RouteCfg.RouteAlgo  ),
    .NumRoutes        ( int'(NumDirections) ),
    .NumAddrRules     ( 1                   ),
    .InFifoDepth      ( InFifoDepth         ),
    .OutFifoDepth     ( OutFifoDepth        ),
    .XYRouteOpt       ( 1'b0                ),
    .WideRwDecouple   ( WideRwDecouple      ),
    .VcImpl           ( VcImpl              ),
    .NoLoopback       ( 1'b0                ),
    .CollectiveCfg    ( ActiveCollectiveCfg ),
    .id_t             ( id_t                ),
    .hdr_t            ( hdr_t               ),
    .floo_req_t       ( floo_req_t          ),
    .floo_rsp_t       ( floo_rsp_t          ),
    .floo_wide_t      ( floo_wide_t         ),
    .red_wide_req_t   ( red_wide_req_t      ),
    .red_wide_rsp_t   ( red_wide_rsp_t      ),
    .red_narrow_req_t ( red_narrow_req_t    ),
    .red_narrow_rsp_t ( red_narrow_rsp_t    )
  ) i_floo_nw_router (
    .clk_i                ( clk_i                     ),
    .rst_ni               ( rst_ni                    ),
    .test_enable_i        ( test_enable_i             ),
    .id_i                 ( id_i                      ),
    .id_route_map_i       ( '0                        ),
    .floo_req_i           ( router_floo_req_in        ),
    .floo_rsp_i           ( router_floo_rsp_in        ),
    .floo_req_o           ( router_floo_req_out       ),
    .floo_rsp_o           ( router_floo_rsp_out       ),
    .floo_wide_i          ( router_floo_wide_in       ),
    .floo_wide_o          ( router_floo_wide_out      ),
    .offload_wide_req_o   ( router_offload_wide_req   ),
    .offload_wide_rsp_i   ( '0                        ),
    .offload_narrow_req_o ( router_offload_narrow_req ),
    .offload_narrow_rsp_i ( '0                        )
  );

  // Connect to the wrapper ports.
  assign floo_req_o                          = router_floo_req_out[West:North];
  assign router_floo_req_in[West:North]      = floo_req_i;
  assign floo_rsp_o                          = router_floo_rsp_out[West:North];
  assign router_floo_rsp_in[West:North]      = floo_rsp_i;
  assign floo_wide_o                         = router_floo_wide_out[West:North];
  assign router_floo_wide_in[West:North]     = floo_wide_i;

  /////////////
  // Chimney //
  /////////////

  // Chimney subordinate (inject side) is driven by the AXI-Realm outputs.
  endpoint_axi_pkg::narrow_out_req_t  chimney_narrow_in_req;
  endpoint_axi_pkg::narrow_out_resp_t chimney_narrow_in_rsp;
  endpoint_axi_pkg::wide_out_req_t    chimney_wide_in_req;
  endpoint_axi_pkg::wide_out_resp_t   chimney_wide_in_rsp;

  // Chimney manager (eject side): narrow NoC => configuration, wide NoC => local memory.
  endpoint_axi_pkg::narrow_in_req_t   chimney_narrow_out_req;
  endpoint_axi_pkg::narrow_in_resp_t  chimney_narrow_out_rsp;
  endpoint_axi_pkg::wide_in_req_t     chimney_wide_out_req;
  endpoint_axi_pkg::wide_in_resp_t    chimney_wide_out_rsp;

  floo_nw_chimney #(
    .AxiCfgN              ( AxiCfgN                             ),
    .AxiCfgW              ( AxiCfgW                             ),
    .ChimneyCfgN          ( ChimneyCfg                          ),
    .ChimneyCfgW          ( ChimneyCfg                          ),
    .RouteCfg             ( ActiveRouteCfg                      ),
    .AtopSupport          ( AtopSupport                         ),
    .WideRwDecouple       ( WideRwDecouple                      ),
    .VcImpl               ( VcImpl                              ),
    .MaxAtomicTxns        ( MaxAtomicTxns                       ),
    .id_t                 ( id_t                                ),
    .rob_idx_t            ( rob_idx_t                           ),
    .route_t              ( route_t                             ),
    .dst_t                ( route_t                             ),
    .hdr_t                ( hdr_t                               ),
    .sam_rule_t           ( collective_sam_rule_t               ),
    .sam_idx_t            ( collective_idx_t                    ),
    .mask_sel_t           ( collective_mask_sel_t               ),
    .axi_narrow_in_req_t  ( endpoint_axi_pkg::narrow_out_req_t  ),
    .axi_narrow_in_rsp_t  ( endpoint_axi_pkg::narrow_out_resp_t ),
    .axi_narrow_out_req_t ( endpoint_axi_pkg::narrow_in_req_t   ),
    .axi_narrow_out_rsp_t ( endpoint_axi_pkg::narrow_in_resp_t  ),
    .axi_wide_in_req_t    ( endpoint_axi_pkg::wide_out_req_t    ),
    .axi_wide_in_rsp_t    ( endpoint_axi_pkg::wide_out_resp_t   ),
    .axi_wide_out_req_t   ( endpoint_axi_pkg::wide_in_req_t     ),
    .axi_wide_out_rsp_t   ( endpoint_axi_pkg::wide_in_resp_t    ),
    .floo_req_t           ( floo_req_t                          ),
    .floo_rsp_t           ( floo_rsp_t                          ),
    .floo_wide_t          ( floo_wide_t                         ),
    .user_narrow_struct_t ( collective_narrow_user_t            ),
    .user_wide_struct_t   ( collective_wide_user_t              )
  ) i_floo_nw_chimney (
    .clk_i                ( clk_i                       ),
    .rst_ni               ( rst_ni                      ),
    .test_enable_i        ( test_enable_i               ),
    .sram_cfg_i           ( '0                          ),
    .axi_narrow_in_req_i  ( chimney_narrow_in_req       ),
    .axi_narrow_in_rsp_o  ( chimney_narrow_in_rsp       ),
    .axi_narrow_out_req_o ( chimney_narrow_out_req      ),
    .axi_narrow_out_rsp_i ( chimney_narrow_out_rsp      ),
    .axi_wide_in_req_i    ( chimney_wide_in_req         ),
    .axi_wide_in_rsp_o    ( chimney_wide_in_rsp         ),
    .axi_wide_out_req_o   ( chimney_wide_out_req        ),
    .axi_wide_out_rsp_i   ( chimney_wide_out_rsp        ),
    .id_i                 ( id_i                        ),
    .route_table_i        ( route_table_i               ),
    .floo_req_o           ( router_floo_req_in[Eject]   ),
    .floo_rsp_o           ( router_floo_rsp_in[Eject]   ),
    .floo_wide_o          ( router_floo_wide_in[Eject]  ),
    .floo_req_i           ( router_floo_req_out[Eject]  ),
    .floo_rsp_i           ( router_floo_rsp_out[Eject]  ),
    .floo_wide_i          ( router_floo_wide_out[Eject] )
  );

  // Wide traffic ejected from the NoC is exposed as the local tile memory port.
  assign axi_wide_out_req_o   = chimney_wide_out_req;
  assign chimney_wide_out_rsp = axi_wide_out_rsp_i;

  //////////////////////////////////////////////////////////////////////////////
  // Narrow NoC (cfg): NI narrow eject => AXI4 targets => AXI4-Lite => reg-bus //
  //////////////////////////////////////////////////////////////////////////////

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( endpoint_axi_pkg::AddrWidth          ),
    .AXI_DATA_WIDTH ( endpoint_axi_pkg::NarrowDataWidth    ),
    .AXI_ID_WIDTH   ( endpoint_axi_pkg::NarrowIdWidthIn    ),
    .AXI_USER_WIDTH ( endpoint_axi_pkg::NarrowUserWidth    )
  ) cfg_xbar_slv [0:0] ();

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( endpoint_axi_pkg::AddrWidth          ),
    .AXI_DATA_WIDTH ( endpoint_axi_pkg::NarrowDataWidth    ),
    .AXI_ID_WIDTH   ( endpoint_axi_pkg::NarrowIdWidthIn    ),
    .AXI_USER_WIDTH ( endpoint_axi_pkg::NarrowUserWidth    )
  ) cfg_xbar_mst [floo_synth_qos_pkg::NumNoCPlanes-1:0] ();

  `AXI_ASSIGN_FROM_REQ(cfg_xbar_slv[0], chimney_narrow_out_req)
  `AXI_ASSIGN_TO_RESP(chimney_narrow_out_rsp, cfg_xbar_slv[0])

  axi_pkg::xbar_rule_64_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] cfg_addr_map;
  for (genvar p = 0; p < floo_synth_qos_pkg::NumNoCPlanes; p++) begin : gen_cfg_addr_map
    assign cfg_addr_map[p] = '{
      idx:        p,
      start_addr: p * floo_synth_qos_pkg::CfgAddrSpaceDim,
      end_addr:   (p + 1) * floo_synth_qos_pkg::CfgAddrSpaceDim
    };
  end

  localparam axi_pkg::xbar_cfg_t CfgXbarCfg = '{
    NoSlvPorts:         1,
    NoMstPorts:         floo_synth_qos_pkg::NumNoCPlanes,
    MaxMstTrans:        1,
    MaxSlvTrans:        1,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_ALL_PORTS,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: endpoint_axi_pkg::NarrowIdWidthIn,
    AxiIdUsedSlvPorts:  1,
    UniqueIds:          0,
    AxiAddrWidth:       endpoint_axi_pkg::AddrWidth,
    AxiDataWidth:       endpoint_axi_pkg::NarrowDataWidth,
    NoAddrRules:        floo_synth_qos_pkg::NumNoCPlanes
  };

  axi_xbar_intf #(
    .AXI_USER_WIDTH ( endpoint_axi_pkg::NarrowUserWidth ),
    .Cfg            ( CfgXbarCfg                        ),
    .ATOPS          ( 1'b0                              ),
    .rule_t         ( axi_pkg::xbar_rule_64_t           )
  ) i_cfg_xbar (
    .clk_i,
    .rst_ni,
    .test_i                ( 1'b0         ),
    .slv_ports             ( cfg_xbar_slv ),
    .mst_ports             ( cfg_xbar_mst ),
    .addr_map_i            ( cfg_addr_map ),
    .en_default_mst_port_i ( '0           ),
    .default_mst_port_i    ( '0           )
  );

  // AXI-Realm register files.
  floo_synth_qos_pkg::cfg_req_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] regbus_realm_req;
  floo_synth_qos_pkg::cfg_rsp_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] regbus_realm_rsp;

  // AXI data-downsized (64b -> 32b).
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( endpoint_axi_pkg::AddrWidth       ),
    .AXI_DATA_WIDTH ( floo_synth_qos_pkg::CfgDataWidth  ),
    .AXI_ID_WIDTH   ( endpoint_axi_pkg::NarrowIdWidthIn ),
    .AXI_USER_WIDTH ( endpoint_axi_pkg::NarrowUserWidth )
  ) cfg_data_downsized [floo_synth_qos_pkg::NumNoCPlanes-1:0] ();

  // AXI data-downsized (48b -> 32b).
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( floo_synth_qos_pkg::CfgAddrWidth  ),
    .AXI_DATA_WIDTH ( floo_synth_qos_pkg::CfgDataWidth  ),
    .AXI_ID_WIDTH   ( endpoint_axi_pkg::NarrowIdWidthIn ),
    .AXI_USER_WIDTH ( endpoint_axi_pkg::NarrowUserWidth )
  ) cfg_addr_downsized [floo_synth_qos_pkg::NumNoCPlanes-1:0] ();

  // AXI4-Lite.
  AXI_LITE #(
    .AXI_ADDR_WIDTH ( floo_synth_qos_pkg::CfgAddrWidth ),
    .AXI_DATA_WIDTH ( floo_synth_qos_pkg::CfgDataWidth )
  ) cfg_axi_lite [floo_synth_qos_pkg::NumNoCPlanes-1:0] ();

  floo_synth_qos_pkg::cfg_lite_req_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] cfg_lite_req;
  floo_synth_qos_pkg::cfg_lite_resp_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] cfg_lite_rsp;

  floo_synth_qos_pkg::cfg_addr32_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] cfg_aw_addr32;
  floo_synth_qos_pkg::cfg_addr32_t [floo_synth_qos_pkg::NumNoCPlanes-1:0] cfg_ar_addr32;

  for (genvar p = 0; p < floo_synth_qos_pkg::NumNoCPlanes; p++) begin : gen_cfg_chain

    // Downsize data width from 64b to 32b.
    axi_dw_converter_intf #(
      .AXI_ID_WIDTH            ( endpoint_axi_pkg::NarrowIdWidthIn ),
      .AXI_ADDR_WIDTH          ( endpoint_axi_pkg::AddrWidth       ),
      .AXI_SLV_PORT_DATA_WIDTH ( endpoint_axi_pkg::NarrowDataWidth ),
      .AXI_MST_PORT_DATA_WIDTH ( floo_synth_qos_pkg::CfgDataWidth  ),
      .AXI_USER_WIDTH          ( endpoint_axi_pkg::NarrowUserWidth ),
      .AXI_MAX_READS           ( floo_synth_qos_pkg::CfgDwMaxReads )
    ) i_cfg_dw_converter (
      .clk_i,
      .rst_ni,
      .slv ( cfg_xbar_mst[p]        ),
      .mst ( cfg_data_downsized[p]  )
    );

    assign cfg_aw_addr32[p] = cfg_data_downsized[p].aw_addr[floo_synth_qos_pkg::CfgAddrWidth-1:0];
    assign cfg_ar_addr32[p] = cfg_data_downsized[p].ar_addr[floo_synth_qos_pkg::CfgAddrWidth-1:0];

    // Downsize address width from 48b to 32b.
    axi_modify_address_intf #(
      .AXI_SLV_PORT_ADDR_WIDTH ( endpoint_axi_pkg::AddrWidth       ),
      .AXI_MST_PORT_ADDR_WIDTH ( floo_synth_qos_pkg::CfgAddrWidth  ),
      .AXI_DATA_WIDTH          ( floo_synth_qos_pkg::CfgDataWidth  ),
      .AXI_ID_WIDTH            ( endpoint_axi_pkg::NarrowIdWidthIn ),
      .AXI_USER_WIDTH          ( endpoint_axi_pkg::NarrowUserWidth )
    ) i_cfg_modify_address (
      .slv           ( cfg_data_downsized[p] ),
      .mst_aw_addr_i ( cfg_aw_addr32[p]      ),
      .mst_ar_addr_i ( cfg_ar_addr32[p]      ),
      .mst           ( cfg_addr_downsized[p] )
    );

    // Convert AXI4 to AXI4-Lite.
    axi_to_axi_lite_intf #(
      .AXI_ADDR_WIDTH     ( floo_synth_qos_pkg::CfgAddrWidth   ),
      .AXI_DATA_WIDTH     ( floo_synth_qos_pkg::CfgDataWidth   ),
      .AXI_ID_WIDTH       ( endpoint_axi_pkg::NarrowIdWidthIn  ),
      .AXI_USER_WIDTH     ( endpoint_axi_pkg::NarrowUserWidth  ),
      .AXI_MAX_WRITE_TXNS ( floo_synth_qos_pkg::CfgLiteMaxTxns ),
      .AXI_MAX_READ_TXNS  ( floo_synth_qos_pkg::CfgLiteMaxTxns ),
      .FALL_THROUGH       ( 1'b0                               ),
      .FULL_BW            ( 0                                  )
    ) i_cfg_to_axi_lite (
      .clk_i,
      .rst_ni,
      .testmode_i ( test_enable_i         ),
      .slv        ( cfg_addr_downsized[p] ),
      .mst        ( cfg_axi_lite[p]       )
    );

    `AXI_LITE_ASSIGN_TO_REQ(cfg_lite_req[p], cfg_axi_lite[p])
    `AXI_LITE_ASSIGN_FROM_RESP(cfg_axi_lite[p], cfg_lite_rsp[p])

    // Convert AXI4-Lite to register bus.
    axi_lite_to_reg #(
      .ADDR_WIDTH     ( floo_synth_qos_pkg::CfgAddrWidth      ),
      .DATA_WIDTH     ( floo_synth_qos_pkg::CfgDataWidth      ),
      .BUFFER_DEPTH   ( floo_synth_qos_pkg::CfgRegBufferDepth ),
      .DECOUPLE_W     ( 1                                     ),
      .axi_lite_req_t ( floo_synth_qos_pkg::cfg_lite_req_t    ),
      .axi_lite_rsp_t ( floo_synth_qos_pkg::cfg_lite_resp_t   ),
      .reg_req_t      ( floo_synth_qos_pkg::cfg_req_t         ),
      .reg_rsp_t      ( floo_synth_qos_pkg::cfg_rsp_t         )
    ) i_cfg_axi_lite_to_reg (
      .clk_i,
      .rst_ni,
      .axi_lite_req_i ( cfg_lite_req[p]     ),
      .axi_lite_rsp_o ( cfg_lite_rsp[p]     ),
      .reg_req_o      ( regbus_realm_req[p] ),
      .reg_rsp_i      ( regbus_realm_rsp[p] )
    );
  end

  // Register-file guard ID (derived from the tile position on the mesh).
  floo_synth_qos_pkg::reg_id_t realm_regfile_id;
  assign realm_regfile_id = floo_synth_qos_pkg::reg_id_t'(id_i.y + floo_synth_qos_pkg::MeshDimY * id_i.x);

  //////////////////////////
  // AXI-Realm (wide NoC) //
  //////////////////////////

  endpoint_axi_pkg::wide_out_req_t  realm_wide_in_req,  realm_wide_out_req;
  endpoint_axi_pkg::wide_out_resp_t realm_wide_in_rsp,  realm_wide_out_rsp;

  // Accelerator wide manager => AXI-Realm subordinate.
  assign realm_wide_in_req = axi_wide_in_req_i;
  assign axi_wide_in_rsp_o = realm_wide_in_rsp;

  axi_rt_unit_top #(
    .NumManagers        ( floo_synth_qos_pkg::NumManagers        ),
    .AddrWidth          ( floo_synth_qos_pkg::RtAddrWidth        ),
    .DataWidth          ( floo_synth_qos_pkg::RtWideDataWidth    ),
    .IdWidth            ( floo_synth_qos_pkg::RtWideIdWidth      ),
    .UserWidth          ( floo_synth_qos_pkg::RtWideUserWidth    ),
    .NumPending         ( floo_synth_qos_pkg::NumPending         ),
    .WBufferDepth       ( floo_synth_qos_pkg::WBufferDepth       ),
    .NumAddrRegions     ( floo_synth_qos_pkg::NumRegions         ),
    .BudgetWidth        ( floo_synth_qos_pkg::BudgetWidth        ),
    .PeriodWidth        ( floo_synth_qos_pkg::PeriodWidth        ),
    .RegIdWidth         ( floo_synth_qos_pkg::RegIdWidth         ),
    .CutSplitterPaths   ( floo_synth_qos_pkg::CutSplitterPaths   ),
    .DisableSplitChecks ( floo_synth_qos_pkg::DisableSplitChecks ),
    .CutDecErrors       ( floo_synth_qos_pkg::CutDecErrors       ),
    .AxiSizeWidth       ( floo_synth_qos_pkg::WideAxiSizeWidth   ),
    .UseWriteBuffer     ( floo_synth_qos_pkg::UseWriteBuffer     ),
    .UseSplitterReconf  ( floo_synth_qos_pkg::UseSplitterReconf  ),
    .aw_chan_t          ( endpoint_axi_pkg::wide_out_aw_chan_t   ),
    .ar_chan_t          ( endpoint_axi_pkg::wide_out_ar_chan_t   ),
    .w_chan_t           ( endpoint_axi_pkg::wide_out_w_chan_t    ),
    .r_chan_t           ( endpoint_axi_pkg::wide_out_r_chan_t    ),
    .b_chan_t           ( endpoint_axi_pkg::wide_out_b_chan_t    ),
    .axi_req_t          ( endpoint_axi_pkg::wide_out_req_t       ),
    .axi_resp_t         ( endpoint_axi_pkg::wide_out_resp_t      ),
    .req_req_t          ( floo_synth_qos_pkg::cfg_req_t          ),
    .req_rsp_t          ( floo_synth_qos_pkg::cfg_rsp_t          )
  ) i_axi_rt_unit_wide (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( realm_wide_in_req                                     ),
    .slv_resp_o ( realm_wide_in_rsp                                     ),
    .mst_req_o  ( realm_wide_out_req                                    ),
    .mst_resp_i ( realm_wide_out_rsp                                    ),
    .reg_req_i  ( regbus_realm_req[floo_synth_qos_pkg::IdxNoCPlaneWide] ),
    .reg_rsp_o  ( regbus_realm_rsp[floo_synth_qos_pkg::IdxNoCPlaneWide] ),
    .reg_id_i   ( realm_regfile_id                                      )
  );

  // AXI-Realm wide output => chimney wide inject.
  assign chimney_wide_in_req = realm_wide_out_req;
  assign realm_wide_out_rsp  = chimney_wide_in_rsp;

  ////////////////////////////
  // AXI-Realm (narrow NoC) //
  ////////////////////////////

  endpoint_axi_pkg::narrow_out_req_t  realm_narrow_in_req,  realm_narrow_out_req;
  endpoint_axi_pkg::narrow_out_resp_t realm_narrow_in_rsp,  realm_narrow_out_rsp;

  // Accelerator narrow manager => AXI-Realm subordinate.
  assign realm_narrow_in_req = axi_narrow_in_req_i;
  assign axi_narrow_in_rsp_o    = realm_narrow_in_rsp;

  axi_rt_unit_top #(
    .NumManagers        ( floo_synth_qos_pkg::NumManagers        ),
    .AddrWidth          ( floo_synth_qos_pkg::RtAddrWidth        ),
    .DataWidth          ( floo_synth_qos_pkg::RtNarrowDataWidth  ),
    .IdWidth            ( floo_synth_qos_pkg::RtNarrowIdWidth    ),
    .UserWidth          ( floo_synth_qos_pkg::RtNarrowUserWidth  ),
    .NumPending         ( floo_synth_qos_pkg::NumPending         ),
    .WBufferDepth       ( floo_synth_qos_pkg::WBufferDepth       ),
    .NumAddrRegions     ( floo_synth_qos_pkg::NumRegions         ),
    .BudgetWidth        ( floo_synth_qos_pkg::BudgetWidth        ),
    .PeriodWidth        ( floo_synth_qos_pkg::PeriodWidth        ),
    .RegIdWidth         ( floo_synth_qos_pkg::RegIdWidth         ),
    .CutSplitterPaths   ( floo_synth_qos_pkg::CutSplitterPaths   ),
    .DisableSplitChecks ( floo_synth_qos_pkg::DisableSplitChecks ),
    .CutDecErrors       ( floo_synth_qos_pkg::CutDecErrors       ),
    .AxiSizeWidth       ( floo_synth_qos_pkg::NarrowAxiSizeWidth ),
    .UseWriteBuffer     ( floo_synth_qos_pkg::UseWriteBuffer     ),
    .UseSplitterReconf  ( floo_synth_qos_pkg::UseSplitterReconf  ),
    .aw_chan_t          ( endpoint_axi_pkg::narrow_out_aw_chan_t ),
    .ar_chan_t          ( endpoint_axi_pkg::narrow_out_ar_chan_t ),
    .w_chan_t           ( endpoint_axi_pkg::narrow_out_w_chan_t  ),
    .r_chan_t           ( endpoint_axi_pkg::narrow_out_r_chan_t  ),
    .b_chan_t           ( endpoint_axi_pkg::narrow_out_b_chan_t  ),
    .axi_req_t          ( endpoint_axi_pkg::narrow_out_req_t     ),
    .axi_resp_t         ( endpoint_axi_pkg::narrow_out_resp_t    ),
    .req_req_t          ( floo_synth_qos_pkg::cfg_req_t          ),
    .req_rsp_t          ( floo_synth_qos_pkg::cfg_rsp_t          )
  ) i_axi_rt_unit_narrow (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( realm_narrow_in_req                                     ),
    .slv_resp_o ( realm_narrow_in_rsp                                     ),
    .mst_req_o  ( realm_narrow_out_req                                    ),
    .mst_resp_i ( realm_narrow_out_rsp                                    ),
    .reg_req_i  ( regbus_realm_req[floo_synth_qos_pkg::IdxNoCPlaneNarrow] ),
    .reg_rsp_o  ( regbus_realm_rsp[floo_synth_qos_pkg::IdxNoCPlaneNarrow] ),
    .reg_id_i   ( realm_regfile_id                                        )
  );

  // AXI-Realm narrow output => chimney narrow inject.
  assign chimney_narrow_in_req = realm_narrow_out_req;
  assign realm_narrow_out_rsp  = chimney_narrow_in_rsp;

endmodule
