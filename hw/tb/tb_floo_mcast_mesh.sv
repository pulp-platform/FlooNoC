// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "floo_noc/typedef.svh"
`include "common_cells/assertions.svh"

module tb_floo_mcast_mesh;

  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NarrowNumReads = 100;
  localparam int unsigned NarrowNumWrites = 100;
  localparam int unsigned WideNumReads = 100;
  localparam int unsigned WideNumWrites = 100;

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

  typedef struct packed {
    logic [AxiNarrowInAddrWidth-1:0] start_addr;
    logic [AxiNarrowInAddrWidth-1:0] end_addr;
  } node_addr_region_t;

  localparam int unsigned NumAddrRegions = NumX*NumY-1;
  localparam node_addr_region_t [0:0][NumAddrRegions-1:0] AddrsExcludeSelf = '{
   '{
     '{
          //idx: '{x: 0, y: 1},
          start_addr: 48'h000020000000,
          end_addr: 48'h000030000000
      },  // cluster_ni_0_1
      '{
          //idx: '{x: 0, y: 2},
          start_addr: 48'h000030000000,
          end_addr: 48'h000040000000
      },  // cluster_ni_0_2
      '{
          //idx: '{x: 0, y: 3},
          start_addr: 48'h000040000000,
          end_addr: 48'h000050000000
      },  // cluster_ni_0_3
      '{
          //idx: '{x: 1, y: 0},
          start_addr: 48'h000050000000,
          end_addr: 48'h000060000000
      },  // cluster_ni_1_0
      '{
          //idx: '{x: 1, y: 1},
          start_addr: 48'h000060000000,
          end_addr: 48'h000070000000
      },  // cluster_ni_1_1
      '{
          //idx: '{x: 1, y: 2},
          start_addr: 48'h000070000000,
          end_addr: 48'h000080000000
      },  // cluster_ni_1_2
      '{
          //idx: '{x: 1, y: 3},
          start_addr: 48'h000080000000,
          end_addr: 48'h000090000000
      },  // cluster_ni_1_3
      '{
          //idx: '{x: 2, y: 0},
          start_addr: 48'h000090000000,
          end_addr: 48'h0000a0000000
      },  // cluster_ni_2_0
      '{
          //idx: '{x: 2, y: 1},
          start_addr: 48'h0000a0000000,
          end_addr: 48'h0000b0000000
      },  // cluster_ni_2_1
      '{
          //idx: '{x: 2, y: 2},
          start_addr: 48'h0000b0000000,
          end_addr: 48'h0000c0000000
      },  // cluster_ni_2_2
      '{
          //idx: '{x: 2, y: 3},
          start_addr: 48'h0000c0000000,
          end_addr: 48'h0000d0000000
      },  // cluster_ni_2_3
      '{
          //idx: '{x: 3, y: 0},
          start_addr: 48'h0000d0000000,
          end_addr: 48'h0000e0000000
      },  // cluster_ni_3_0
      '{
          //idx: '{x: 3, y: 1},
          start_addr: 48'h0000e0000000,
          end_addr: 48'h0000f0000000
      },  // cluster_ni_3_1
      '{
          //idx: '{x: 3, y: 2},
          start_addr: 48'h0000f0000000,
          end_addr: 48'h000100000000
      },  // cluster_ni_3_2
      '{
          //idx: '{x: 3, y: 3},
          start_addr: 48'h000100000000,
          end_addr: 48'h000110000000
      }  // cluster_ni_3_3
    }
  };

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

  logic [NumX-1:0][NumY-1:0] NarrowEOS, WideEOS;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  floo_axi_test_node #(
    .AxiAddrWidth   ( AxiNarrowInAddrWidth  ),
    .AxiDataWidth   ( AxiNarrowInDataWidth  ),
    .AxiIdInWidth   ( AxiNarrowOutIdWidth   ),
    .AxiIdOutWidth  ( AxiNarrowInIdWidth    ),
    .AxiUserWidth   ( AxiNarrowInUserWidth  ),
    .mst_req_t      ( axi_narrow_in_req_t   ),
    .mst_rsp_t      ( axi_narrow_in_rsp_t   ),
    .slv_req_t      ( axi_narrow_out_req_t  ),
    .slv_rsp_t      ( axi_narrow_out_rsp_t  ),
    .ApplTime       ( ApplTime              ),
    .TestTime       ( TestTime              ),
    .Atops          ( 1'b0           ),
    .AxiMaxBurstLen ( NarrowReorderBufferSize     ),
    .NumAddrRegions ( NumAddrRegions        ),
    .rule_t         ( node_addr_region_t    ),
    .AddrRegions    ( AddrsExcludeSelf[0]      ),
    .NumReads       ( NarrowNumReads        ),
    .NumWrites      ( NarrowNumWrites       )
  ) i_narrow_test_node [NumX-1:0][NumY-1:0] (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .mst_port_req_o ( narrow_man_req ),
    .mst_port_rsp_i ( narrow_man_rsp ),
    .slv_port_req_i ( narrow_sub_req ),
    .slv_port_rsp_o ( narrow_sub_rsp ),
    .end_of_sim     ( NarrowEOS     )
  );

  floo_axi_test_node #(
    .AxiAddrWidth   ( AxiWideInAddrWidth  ),
    .AxiDataWidth   ( AxiWideInDataWidth  ),
    .AxiIdInWidth   ( AxiWideOutIdWidth   ),
    .AxiIdOutWidth  ( AxiWideInIdWidth    ),
    .AxiUserWidth   ( AxiWideInUserWidth  ),
    .mst_req_t      ( axi_wide_in_req_t   ),
    .mst_rsp_t      ( axi_wide_in_rsp_t   ),
    .slv_req_t      ( axi_wide_out_req_t  ),
    .slv_rsp_t      ( axi_wide_out_rsp_t  ),
    .ApplTime       ( ApplTime              ),
    .TestTime       ( TestTime              ),
    .Atops          ( 1'b0           ),
    .AxiMaxBurstLen ( WideReorderBufferSize     ),
    .NumAddrRegions ( NumAddrRegions        ),
    .rule_t         ( node_addr_region_t    ),
    .AddrRegions    ( AddrsExcludeSelf[0]      ),
    .NumReads       ( WideNumReads        ),
    .NumWrites      ( WideNumWrites       )
  ) i_wide_test_node [NumX-1:0][NumY-1:0] (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .mst_port_req_o ( wide_man_req ),
    .mst_port_rsp_i ( wide_man_rsp ),
    .slv_port_req_i ( wide_sub_req ),
    .slv_port_rsp_o ( wide_sub_rsp ),
    .end_of_sim     ( WideEOS     )
  );

  mcast_mesh_floo_noc i_dut (
    .clk_i               (clk),
    .rst_ni              (rst_n),
    .test_enable_i       (1'b0),
    .cluster_narrow_req_i(narrow_man_req),
    .cluster_narrow_rsp_o(narrow_man_rsp),
    .cluster_wide_req_i  (wide_man_req),
    .cluster_wide_rsp_o  (wide_man_rsp),
    .cluster_narrow_req_o(narrow_sub_req),
    .cluster_narrow_rsp_i(narrow_sub_rsp),
    .cluster_wide_req_o  (wide_sub_req),
    .cluster_wide_rsp_i  (wide_sub_rsp)
  );


  initial begin
    wait(&NarrowEOS && &WideEOS);
    // Wait for some time
    #100ns;
    // Stop the simulation
    $stop;
  end

endmodule
