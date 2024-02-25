// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "floo_noc/typedef.svh"
`include "common_cells/assertions.svh"

module tb_floo_dma_mesh;

  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumX = 4;
  localparam int unsigned NumY = 4;
  localparam int unsigned NumMax = (NumX > NumY) ? NumX : NumY;

  localparam int unsigned HBMLatency = 100;
  localparam axi_narrow_in_addr_t HBMSize = 48'h10000; // 64KB
  localparam axi_narrow_in_addr_t MemSize = HBMSize;

  if (RouteAlgo == XYRouting) begin : gen_asserts
  `ASSERT_INIT(NotEnoughXBits, $clog2(NumX + 2) <= $bits(x_bits_t))
  `ASSERT_INIT(NotEnoughYBits, $clog2(NumY + 2) <= $bits(y_bits_t))
  `ASSERT_INIT(NotEnoughAddrOffset, $clog2(HBMSize) <= XYAddrOffsetX)
  end else begin : gen_error
    $fatal(1, "This testbench only supports XYRouting");
  end

  // Narrow Wide Chimney parameters
  localparam bit CutAx = 1'b1;
  localparam bit CutRsp = 1'b0;
  localparam int unsigned NarrowMaxTxnsPerId = 4;
  localparam int unsigned NarrowReorderBufferSize = 32'd256;
  localparam int unsigned WideMaxTxnsPerId = 32;
  localparam int unsigned WideReorderBufferSize = 32'd64;
  localparam int unsigned NarrowMaxTxns = 32;
  localparam int unsigned WideMaxTxns = 32;
  localparam int unsigned ChannelFifoDepth = 2;
  localparam int unsigned OutputFifoDepth = 32;

  logic clk, rst_n;

  /////////////////////
  //   AXI Signals   //
  /////////////////////

  axi_narrow_in_req_t   [NumX-1:0][NumY-1:0] narrow_man_req;
  axi_narrow_in_rsp_t  [NumX-1:0][NumY-1:0] narrow_man_rsp;
  axi_wide_in_req_t     [NumX-1:0][NumY-1:0] wide_man_req;
  axi_wide_in_rsp_t    [NumX-1:0][NumY-1:0] wide_man_rsp;

  axi_narrow_out_req_t  [NumX-1:0][NumY-1:0] narrow_sub_req;
  axi_narrow_out_rsp_t [NumX-1:0][NumY-1:0] narrow_sub_rsp;
  axi_wide_out_req_t    [NumX-1:0][NumY-1:0] wide_sub_req;
  axi_wide_out_rsp_t   [NumX-1:0][NumY-1:0] wide_sub_rsp;

  axi_narrow_out_req_t  [West:North][NumMax-1:0] narrow_hbm_req;
  axi_narrow_out_rsp_t [West:North][NumMax-1:0] narrow_hbm_rsp;
  axi_wide_out_req_t    [West:North][NumMax-1:0] wide_hbm_req;
  axi_wide_out_rsp_t   [West:North][NumMax-1:0] wide_hbm_rsp;

  /////////////////////
  //   NoC Signals   //
  /////////////////////


  floo_req_t [NumX-1:0][NumY-1:0] narrow_chimney_man_req, narrow_chimney_sub_req;
  floo_rsp_t [NumX-1:0][NumY-1:0] narrow_chimney_man_rsp, narrow_chimney_sub_rsp;
  floo_wide_t       [NumX-1:0][NumY-1:0] wide_chimney_man, wide_chimney_sub;

  floo_req_t [NumX:0][NumY-1:0] req_hor_pos;
  floo_req_t [NumX:0][NumY-1:0] req_hor_neg;
  floo_req_t [NumY:0][NumX-1:0] req_ver_pos;
  floo_req_t [NumY:0][NumX-1:0] req_ver_neg;
  floo_rsp_t [NumX:0][NumY-1:0] rsp_hor_pos;
  floo_rsp_t [NumX:0][NumY-1:0] rsp_hor_neg;
  floo_rsp_t [NumY:0][NumX-1:0] rsp_ver_pos;
  floo_rsp_t [NumY:0][NumX-1:0] rsp_ver_neg;
  floo_wide_t       [NumX:0][NumY-1:0] wide_hor_pos;
  floo_wide_t       [NumX:0][NumY-1:0] wide_hor_neg;
  floo_wide_t       [NumY:0][NumX-1:0] wide_ver_pos;
  floo_wide_t       [NumY:0][NumX-1:0] wide_ver_neg;


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
    .TA           ( ApplTime                ),
    .TT           ( TestTime                ),
    .Latency      ( HBMLatency              ),
    .NumChannels  ( 1                       ),
    .AddrWidth    ( AxiWideOutAddrWidth     ),
    .DataWidth    ( AxiWideOutDataWidth     ),
    .UserWidth    ( AxiWideOutUserWidth     ),
    .IdWidth      ( AxiWideOutIdWidth       ),
    .axi_req_t    ( axi_wide_out_req_t      ),
    .axi_rsp_t    ( axi_wide_out_rsp_t      ),
    .aw_chan_t    ( axi_wide_out_aw_chan_t  ),
    .w_chan_t     ( axi_wide_out_w_chan_t   ),
    .b_chan_t     ( axi_wide_out_b_chan_t   ),
    .ar_chan_t    ( axi_wide_out_ar_chan_t  ),
    .r_chan_t     ( axi_wide_out_r_chan_t   )
  ) i_floo_wide_hbm_model [West:North][NumMax-1:0] (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .hbm_req_i  ( wide_hbm_req  ),
    .hbm_rsp_o  ( wide_hbm_rsp  )
  );

  floo_hbm_model #(
    .TA           ( ApplTime                  ),
    .TT           ( TestTime                  ),
    .Latency      ( HBMLatency                ),
    .NumChannels  ( 1                         ),
    .AddrWidth    ( AxiNarrowOutAddrWidth     ),
    .DataWidth    ( AxiNarrowOutDataWidth     ),
    .UserWidth    ( AxiNarrowOutUserWidth     ),
    .IdWidth      ( AxiNarrowOutIdWidth       ),
    .axi_req_t    ( axi_narrow_out_req_t      ),
    .axi_rsp_t    ( axi_narrow_out_rsp_t      ),
    .aw_chan_t    ( axi_narrow_out_aw_chan_t  ),
    .w_chan_t     ( axi_narrow_out_w_chan_t   ),
    .b_chan_t     ( axi_narrow_out_b_chan_t   ),
    .ar_chan_t    ( axi_narrow_out_ar_chan_t  ),
    .r_chan_t     ( axi_narrow_out_r_chan_t   )
  ) i_floo_narrow_hbm_model [West:North][NumMax-1:0] (
    .clk_i      ( clk             ),
    .rst_ni     ( rst_n           ),
    .hbm_req_i  ( narrow_hbm_req  ),
    .hbm_rsp_o  ( narrow_hbm_rsp  )
  );

  for (genvar i = North; i <= West; i++) begin : gen_hbm_chimneys

    localparam int unsigned NumChimneys = (i == North || i == South) ? NumX : NumY;

    floo_req_t [NumChimneys-1:0] req_hbm_in, req_hbm_out;
    floo_rsp_t [NumChimneys-1:0] rsp_hbm_in, rsp_hbm_out;
    floo_wide_t [NumChimneys-1:0]       wide_hbm_in, wide_hbm_out;
    id_t [NumChimneys-1:0]           xy_id_hbm;

    if (i == North) begin : gen_north_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: j+1, y: NumY+1};
      end
      assign req_hbm_in  = req_ver_pos[NumY];
      assign rsp_hbm_in  = rsp_ver_pos[NumY];
      assign wide_hbm_in        = wide_ver_pos[NumY];
      assign req_ver_neg[NumY] = req_hbm_out;
      assign rsp_ver_neg[NumY] = rsp_hbm_out;
      assign wide_ver_neg[NumY]       = wide_hbm_out;
    end
    else if (i == South) begin : gen_south_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: j+1, y: 0};
      end
      assign req_hbm_in  = req_ver_neg[0];
      assign rsp_hbm_in  = rsp_ver_neg[0];
      assign wide_hbm_in        = wide_ver_neg[0];
      assign req_ver_pos[0] = req_hbm_out;
      assign rsp_ver_pos[0] = rsp_hbm_out;
      assign wide_ver_pos[0]       = wide_hbm_out;
    end
    else if (i == East) begin : gen_east_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: NumX+1, y: j+1};
      end
      assign req_hbm_in  = req_hor_pos[NumX];
      assign rsp_hbm_in  = rsp_hor_pos[NumX];
      assign wide_hbm_in        = wide_hor_pos[NumX];
      assign req_hor_neg[NumX] = req_hbm_out;
      assign rsp_hor_neg[NumX] = rsp_hbm_out;
      assign wide_hor_neg[NumX]       = wide_hbm_out;
    end
    else if (i == West) begin : gen_west_hbm_chimneys
      for (genvar j = 0; j < NumChimneys; j++) begin : gen_hbm_chimney_xy_id
        assign xy_id_hbm[j] = '{x: 0, y: j+1};
      end
      assign req_hbm_in  = req_hor_neg[0];
      assign rsp_hbm_in  = rsp_hor_neg[0];
      assign wide_hbm_in        = wide_hor_neg[0];
      assign req_hor_pos[0] = req_hbm_out;
      assign rsp_hor_pos[0] = rsp_hbm_out;
      assign wide_hor_pos[0]       = wide_hbm_out;
    end

    floo_narrow_wide_chimney #(
      .NarrowMaxTxns            ( NarrowMaxTxns           ),
      .WideMaxTxns              ( WideMaxTxns             ),
      .NarrowReorderBufferSize  ( NarrowReorderBufferSize ),
      .WideReorderBufferSize    ( WideReorderBufferSize   ),
      .CutAx                    ( CutAx                   ),
      .CutRsp                   ( CutRsp                  )
    ) i_hbm_chimney [NumChimneys-1:0] (
      .clk_i                ( clk               ),
      .rst_ni               ( rst_n             ),
      .sram_cfg_i           ( '0                ),
      .test_enable_i        ( 1'b0              ),
      .id_i                 ( xy_id_hbm         ),
      .route_table_i        ( '0                ),
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
    for (genvar y = 0; y < NumX; y++) begin : gen_y
      id_t current_id;
      localparam string NarrowDmaName = $sformatf("narrow_dma_%0d_%0d", x, y);
      localparam string WideDmaName   = $sformatf("wide_dma_%0d_%0d", x, y);
      floo_req_t [NumDirections-1:0] req_out, req_in;
      floo_rsp_t [NumDirections-1:0] rsp_out, rsp_in;
      floo_wide_t       [NumDirections-1:0] wide_out, wide_in;

      localparam int unsigned Index = y * NumX + x+1;
      localparam logic [AxiNarrowInAddrWidth-1:0] MemBaseAddr =
          (x+1) << XYAddrOffsetX | (y+1) << XYAddrOffsetY;
      assign current_id = '{x: x+1, y: y+1};

      floo_dma_test_node #(
        .TA             ( ApplTime              ),
        .TT             ( TestTime              ),
        .DataWidth      ( AxiNarrowInDataWidth  ),
        .AddrWidth      ( AxiNarrowInAddrWidth  ),
        .UserWidth      ( AxiNarrowInUserWidth  ),
        .AxiIdInWidth   ( AxiNarrowOutIdWidth   ),
        .AxiIdOutWidth  ( AxiNarrowInIdWidth    ),
        .MemBaseAddr    ( MemBaseAddr           ),
        .MemSize        ( MemSize               ),
        .NumAxInFlight  ( 2*NarrowMaxTxnsPerId  ),
        .axi_in_req_t   ( axi_narrow_out_req_t  ),
        .axi_in_rsp_t   ( axi_narrow_out_rsp_t  ),
        .axi_out_req_t  ( axi_narrow_in_req_t   ),
        .axi_out_rsp_t  ( axi_narrow_in_rsp_t   ),
        .JobId          ( 100 + Index           )
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
        .TA             ( ApplTime            ),
        .TT             ( TestTime            ),
        .DataWidth      ( AxiWideInDataWidth  ),
        .AddrWidth      ( AxiWideInAddrWidth  ),
        .UserWidth      ( AxiWideInUserWidth  ),
        .AxiIdInWidth   ( AxiWideOutIdWidth   ),
        .AxiIdOutWidth  ( AxiWideInIdWidth    ),
        .MemBaseAddr    ( MemBaseAddr         ),
        .MemSize        ( MemSize             ),
        .NumAxInFlight  ( 2*WideMaxTxnsPerId  ),
        .axi_in_req_t   ( axi_wide_out_req_t  ),
        .axi_in_rsp_t   ( axi_wide_out_rsp_t  ),
        .axi_out_req_t  ( axi_wide_in_req_t   ),
        .axi_out_rsp_t  ( axi_wide_in_rsp_t   ),
        .JobId          ( Index               )
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
        .req_t      ( axi_narrow_in_req_t ),
        .rsp_t      ( axi_narrow_in_rsp_t ),
        .AxiIdWidth ( AxiNarrowInIdWidth  ),
        .Name       ( NarrowDmaName       )
      ) i_axi_narrow_bw_monitor (
        .clk_i        ( clk                   ),
        .en_i         ( rst_n                 ),
        .end_of_sim_i ( &end_of_sim           ),
        .req_i        ( narrow_man_req[x][y]  ),
        .rsp_i        ( narrow_man_rsp[x][y]  ),
        .ar_in_flight_o(                      ),
        .aw_in_flight_o(                      )
        );

      axi_bw_monitor #(
        .req_t      ( axi_wide_in_req_t ),
        .rsp_t      ( axi_wide_in_rsp_t ),
        .AxiIdWidth ( AxiWideInIdWidth  ),
        .Name       ( WideDmaName       )
      ) i_axi_wide_bw_monitor (
        .clk_i        ( clk                 ),
        .en_i         ( rst_n               ),
        .end_of_sim_i ( &end_of_sim         ),
        .req_i        ( wide_man_req[x][y]  ),
        .rsp_i        ( wide_man_rsp[x][y]  ),
        .ar_in_flight_o(                    ),
        .aw_in_flight_o(                    )
        );

      floo_narrow_wide_chimney #(
        .NarrowMaxTxns            ( NarrowMaxTxns           ),
        .WideMaxTxns              ( WideMaxTxns             ),
        .NarrowReorderBufferSize  ( NarrowReorderBufferSize ),
        .WideReorderBufferSize    ( WideReorderBufferSize   ),
        .CutAx                    ( CutAx                   ),
        .CutRsp                   ( CutRsp                  )
      ) i_dma_chimney (
        .clk_i                ( clk                           ),
        .rst_ni               ( rst_n                         ),
        .sram_cfg_i           ( '0                            ),
        .test_enable_i        ( 1'b0                          ),
        .id_i                 ( current_id                    ),
        .route_table_i        ( '0                            ),
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

      floo_narrow_wide_router #(
        .NumRoutes        ( NumDirections     ),
        .ChannelFifoDepth ( ChannelFifoDepth  ),
        .OutputFifoDepth  ( OutputFifoDepth   ),
        .RouteAlgo        ( RouteAlgo         ),
        .XYRouteOpt       ( 1'b0              ),
        .id_t             ( id_t              )
      ) i_router (
        .clk_i          ( clk         ),
        .rst_ni         ( rst_n       ),
        .test_enable_i  ( 1'b0        ),
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
    #100ns;
    // Stop the simulation
    $stop;
  end

endmodule
