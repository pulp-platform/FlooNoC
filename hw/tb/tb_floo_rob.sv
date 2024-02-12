// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_floo_rob;

  import floo_pkg::*;
  import floo_test_pkg::*;
  import floo_axi_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumReads = 1000;
  localparam int unsigned NumWrites = 1000;

  localparam int unsigned ReorderBufferSize = 64;
  localparam int unsigned MaxTxns = 32;
  localparam int unsigned MaxTxnsPerId = 32;

  localparam int unsigned NumSlaves = 4;

  logic clk, rst_n;

  axi_in_req_t  node_mst_req;
  axi_in_rsp_t node_mst_rsp;

  axi_out_req_t  [NumDirections-1:0] node_slv_req;
  axi_out_rsp_t [NumDirections-1:0] node_slv_rsp;
  axi_in_req_t  [NumDirections-1:0] node_slv_req_id_mapped;
  axi_in_rsp_t [NumDirections-1:0] node_slv_rsp_id_mapped;

  for (genvar i = 0; i < NumDirections; i++) begin : gen_dir
    `AXI_ASSIGN_REQ_STRUCT(node_slv_req_id_mapped[i], node_slv_req[i])
    `AXI_ASSIGN_RESP_STRUCT(node_slv_rsp_id_mapped[i], node_slv_rsp[i])
  end

  floo_req_t [NumDirections-1:0] chimney_req_out, chimney_req_in;
  floo_rsp_t [NumDirections-1:0] chimney_rsp_out, chimney_rsp_in;
  floo_req_chan_t [NumDirections-1:0] chimney_req_out_chan, chimney_req_in_chan;
  floo_rsp_chan_t [NumDirections-1:0] chimney_rsp_out_chan, chimney_rsp_in_chan;

  logic [NumDirections-1:0]      chimney_req_out_valid, chimney_req_out_ready;
  logic [NumDirections-1:0]      chimney_rsp_out_valid, chimney_rsp_out_ready;
  logic [NumDirections-1:0]      chimney_req_in_valid, chimney_req_in_ready;
  logic [NumDirections-1:0]      chimney_rsp_in_valid, chimney_rsp_in_ready;

  for (genvar i = 0; i < NumDirections; i++) begin : gen_directions
    assign chimney_req_out_chan[i] = chimney_req_out[i].req;
    assign chimney_rsp_out_chan[i] = chimney_rsp_out[i].rsp;
    assign chimney_req_in[i].req = chimney_req_in_chan[i];
    assign chimney_rsp_in[i].rsp = chimney_rsp_in_chan[i];
    assign chimney_req_out_valid[i] = chimney_req_out[i].valid;
    assign chimney_req_out_ready[i] = chimney_req_out[i].ready;
    assign chimney_rsp_out_valid[i] = chimney_rsp_out[i].valid;
    assign chimney_rsp_out_ready[i] = chimney_rsp_out[i].ready;
    assign chimney_req_in[i].valid = chimney_req_in_valid[i];
    assign chimney_req_in[i].ready = chimney_req_in_ready[i];
    assign chimney_rsp_in[i].valid = chimney_rsp_in_valid[i];
    assign chimney_rsp_in[i].ready = chimney_rsp_in_ready[i];
  end

  logic [1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  ////////////////////
  //  Local Master  //
  ////////////////////

  id_t [NumDirections-1:0] xy_id;
  assign xy_id[Eject] = '{x: 3'd1, y: 3'd1};

  typedef struct packed {
    int unsigned             idx;
    axi_in_addr_t start_addr;
    axi_in_addr_t end_addr;
  } node_addr_region_t;

  localparam int unsigned NumAddrRegions = 4;
  localparam node_addr_region_t [NumAddrRegions-1:0] AddrRegions = '{
    '{idx: 0, start_addr: 32'h00210000, end_addr: 32'h0021FFFF},  // North
    '{idx: 1, start_addr: 32'h00120000, end_addr: 32'h0012FFFF},   // East
    '{idx: 2, start_addr: 32'h00010000, end_addr: 32'h0001FFFF},  // South
    '{idx: 3, start_addr: 32'h00100000, end_addr: 32'h0010FFFF}    // West
  };

  floo_axi_test_node #(
    .AxiAddrWidth   ( AxiInAddrWidth      ),
    .AxiDataWidth   ( AxiInDataWidth      ),
    .AxiIdInWidth   ( AxiInIdWidth        ),
    .AxiIdOutWidth  ( AxiInIdWidth        ),
    .AxiUserWidth   ( AxiInUserWidth      ),
    .mst_req_t      ( axi_in_req_t        ),
    .mst_rsp_t      ( axi_in_rsp_t        ),
    .slv_req_t      ( axi_out_req_t       ),
    .slv_rsp_t      ( axi_out_rsp_t       ),
    .ApplTime       ( ApplTime            ),
    .TestTime       ( TestTime            ),
    .AxiMaxBurstLen ( 4                   ),
    .NumAddrRegions ( NumAddrRegions      ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .NumReads       ( NumReads            ),
    .NumWrites      ( NumWrites           )
  ) i_test_node_0 (
    .clk_i          ( clk                 ),
    .rst_ni         ( rst_n               ),
    .mst_port_req_o ( node_mst_req        ),
    .mst_port_rsp_i ( node_mst_rsp        ),
    .slv_port_req_i ( node_slv_req[Eject] ),
    .slv_port_rsp_o ( node_slv_rsp[Eject] ),
    .end_of_sim     ( end_of_sim[0]       )
  );

  floo_axi_chimney #(
    .MaxTxns            ( MaxTxns             ),
    .MaxTxnsPerId       ( MaxTxnsPerId        ),
    .ReorderBufferSize  ( ReorderBufferSize   )
  ) i_floo_axi_chimney (
    .clk_i          ( clk                       ),
    .rst_ni         ( rst_n                     ),
    .sram_cfg_i     ( '0                        ),
    .test_enable_i  ( 1'b0                      ),
    .axi_in_req_i   ( node_mst_req              ),
    .axi_in_rsp_o   ( node_mst_rsp              ),
    .axi_out_req_o  ( node_slv_req[Eject]       ),
    .axi_out_rsp_i  ( node_slv_rsp[Eject]       ),
    .id_i           ( xy_id[Eject]              ),
    .map_i          ( '0                        ),
    .floo_req_o     ( chimney_req_out[Eject]    ),
    .floo_rsp_o     ( chimney_rsp_out[Eject]    ),
    .floo_req_i     ( chimney_req_in[Eject]     ),
    .floo_rsp_i     ( chimney_rsp_in[Eject]     )
  );

  floo_router #(
    .NumRoutes        ( NumDirections           ),
    .NumVirtChannels  ( 1                       ),
    .NumPhysChannels  ( 1                       ),
    .flit_t           ( floo_req_generic_flit_t ),
    .ChannelFifoDepth ( 4                       ),
    .RouteAlgo        ( XYRouting               ),
    .id_t             ( id_t                    )
  ) i_floo_req_router (
    .clk_i          ( clk                   ),
    .rst_ni         ( rst_n                 ),
    .test_enable_i  ( 1'b0                  ),
    .xy_id_i        ( xy_id[Eject]          ),
    .id_route_map_i ( '0                    ),
    .valid_i        ( chimney_req_out_valid ),
    .ready_o        ( chimney_req_in_ready  ),
    .data_i         ( chimney_req_out_chan  ),
    .valid_o        ( chimney_req_in_valid  ),
    .ready_i        ( chimney_req_out_ready ),
    .data_o         ( chimney_req_in_chan   )
  );

  floo_router #(
    .NumRoutes        ( NumDirections           ),
    .NumVirtChannels  ( 1                       ),
    .NumPhysChannels  ( 1                       ),
    .flit_t           ( floo_rsp_generic_flit_t ),
    .ChannelFifoDepth ( 4                       ),
    .RouteAlgo        ( XYRouting               ),
    .id_t             ( id_t                    )
  ) i_floo_rsp_router (
    .clk_i          ( clk                   ),
    .rst_ni         ( rst_n                 ),
    .test_enable_i  ( 1'b0                  ),
    .xy_id_i        ( xy_id[Eject]          ),
    .id_route_map_i ( '0                    ),
    .valid_i        ( chimney_rsp_out_valid ),
    .ready_o        ( chimney_rsp_in_ready  ),
    .data_i         ( chimney_rsp_out_chan  ),
    .valid_o        ( chimney_rsp_in_valid  ),
    .ready_i        ( chimney_rsp_out_ready ),
    .data_o         ( chimney_rsp_in_chan   )
  );

  localparam slave_type_e SlaveType[NumDirections-1] = '{
    FastSlave, FastSlave, SlowSlave, MixedSlave};

  for (genvar i = North; i <= West; i++) begin : gen_slaves

    if (i == North) begin : gen_north
      assign xy_id[i] = '{x: 3'd1, y: 3'd2};
    end else if (i == South) begin : gen_south
      assign xy_id[i] = '{x: 3'd1, y: 3'd0};
    end else if (i == East) begin : gen_east
      assign xy_id[i] = '{x: 3'd2, y: 3'd1};
    end else if (i == West) begin : gen_west
      assign xy_id[i] = '{x: 3'd0, y: 3'd1};
    end

    floo_axi_chimney #(
      .MaxTxns            ( MaxTxns             ),
      .MaxTxnsPerId       ( MaxTxnsPerId        ),
      .ReorderBufferSize  ( ReorderBufferSize   )
    ) i_floo_axi_chimney (
      .clk_i          ( clk                   ),
      .rst_ni         ( rst_n                 ),
      .sram_cfg_i     ( '0                    ),
      .test_enable_i  ( 1'b0                  ),
      .axi_in_req_i   ( '0                    ),
      .axi_in_rsp_o   (                       ),
      .axi_out_req_o  ( node_slv_req[i]       ),
      .axi_out_rsp_i  ( node_slv_rsp[i]       ),
      .id_i           ( xy_id[i]              ),
      .map_i          ( '0                    ),
      .floo_req_o     ( chimney_req_out[i]    ),
      .floo_rsp_o     ( chimney_rsp_out[i]    ),
      .floo_req_i     ( chimney_req_in[i]     ),
      .floo_rsp_i     ( chimney_rsp_in[i]     )
    );

    floo_axi_rand_slave #(
      .AxiAddrWidth ( AxiOutAddrWidth ),
      .AxiDataWidth ( AxiOutDataWidth ),
      .AxiIdWidth   ( AxiOutIdWidth   ),
      .AxiUserWidth ( AxiOutUserWidth ),
      .axi_req_t    ( axi_out_req_t   ),
      .axi_rsp_t    ( axi_out_rsp_t  ),
      .ApplTime     ( ApplTime        ),
      .TestTime     ( TestTime        ),
      .SlaveType    ( SlaveType[i]    ),
      .DstStartAddr ( 32'h0000_0000   ), // TODO: make this configurable
      .DstEndAddr   ( 32'h0000_8000   )
    ) i_test_node_1 (
      .clk_i              ( clk             ),
      .rst_ni             ( rst_n           ),
      .slv_port_req_i     ( node_slv_req[i] ),
      .slv_port_rsp_o     ( node_slv_rsp[i] ),
      .mon_mst_port_req_o (                 ),
      .mon_mst_port_rsp_o (                 )
    );

  end

  axi_reorder_compare #(
    .NumSlaves      ( NumSlaves           ),
    .AxiIdWidth     ( AxiInIdWidth        ),
    .NumAddrRegions ( NumAddrRegions      ),
    .addr_t         ( axi_in_addr_t       ),
    .rule_t         ( node_addr_region_t  ),
    .AddrRegions    ( AddrRegions         ),
    .aw_chan_t      ( axi_in_aw_chan_t    ),
    .w_chan_t       ( axi_in_w_chan_t     ),
    .b_chan_t       ( axi_in_b_chan_t     ),
    .ar_chan_t      ( axi_in_ar_chan_t    ),
    .r_chan_t       ( axi_in_r_chan_t     ),
    .req_t          ( axi_in_req_t        ),
    .rsp_t          ( axi_in_rsp_t       ),
    .Verbose        ( 1'b0                )
  ) i_axi_reorder_compare (
    .clk_i          ( clk                                       ),
    .rst_ni         ( rst_n                                     ),
    .mon_mst_req_i  ( node_mst_req                              ),
    .mon_mst_rsp_i  ( node_mst_rsp                              ),
    .mon_slv_req_i  ( node_slv_req_id_mapped[NumDirections-1:1] ),
    .mon_slv_rsp_i  ( node_slv_rsp_id_mapped[NumDirections-1:1] ),
    .end_of_sim_o   ( end_of_sim[1]                             )
  );

  initial begin
    wait(&end_of_sim);
    $stop;
  end


endmodule
