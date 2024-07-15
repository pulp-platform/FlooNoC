`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module tb_r1e4;
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NarrowNumReads = 1000;
  localparam int unsigned NarrowNumWrites = 1000;
  localparam int unsigned WideNumReads = 1000;
  localparam int unsigned WideNumWrites = 1000;

  localparam bit AtopSupport = 1'b0;

  localparam int unsigned NumNI = 4;
  localparam int unsigned NumRouter = 1;

  localparam int unsigned ReorderBufferSize = 128;
  localparam int unsigned MaxTxns = 32;
  localparam int unsigned MaxTxnsPerId = 32;

  logic clk, rst_n;

  axi_narrow_in_req_t [NumNI-1:0] narrow_man_req;
  axi_narrow_in_rsp_t [NumNI-1:0] narrow_man_rsp;
  axi_wide_in_req_t [NumNI-1:0] wide_man_req;
  axi_wide_in_rsp_t [NumNI-1:0] wide_man_rsp;

  axi_narrow_out_req_t [NumNI-1:0] narrow_sub_req;
  axi_narrow_out_rsp_t [NumNI-1:0] narrow_sub_rsp;
  axi_wide_out_req_t [NumNI-1:0] wide_sub_req;
  axi_wide_out_rsp_t [NumNI-1:0] wide_sub_rsp;

  // axi_narrow_in_req_t [NumNI-1:0] narrow_sub_req_id_mapped;
  // axi_narrow_in_rsp_t [NumNI-1:0] narrow_sub_rsp_id_mapped;
  // axi_wide_in_req_t [NumNI-1:0] wide_sub_req_id_mapped;
  // axi_wide_in_rsp_t [NumNI-1:0] wide_sub_rsp_id_mapped;

  // for (genvar i = 0; i < NumDirections; i++) begin : gen_dir
  //   `AXI_ASSIGN_REQ_STRUCT(narrow_sub_req_id_mapped[i], narrow_sub_req[i])
  //   `AXI_ASSIGN_RESP_STRUCT(narrow_sub_rsp_id_mapped[i], narrow_sub_rsp[i])
  //   `AXI_ASSIGN_REQ_STRUCT(wide_sub_req_id_mapped[i], wide_sub_req[i])
  //   `AXI_ASSIGN_RESP_STRUCT(wide_sub_rsp_id_mapped[i], wide_sub_rsp[i])
  // end

  // floo_req_t [NumNI-1:0] chimney_req;
  // floo_rsp_t [NumNI-1:0] chimney_rsp;
  // floo_wide_t [NumNI-1:0] chimney_wide;

  logic [NumNI*2-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  typedef struct packed {
    logic [AxiNarrowInAddrWidth-1:0] start_addr;
    logic [AxiNarrowInAddrWidth-1:0] end_addr;
  } node_addr_region_t;


  typedef struct packed {
    id_t idx;
    logic [AxiNarrowInAddrWidth-1:0] start_addr;
    logic [AxiNarrowInAddrWidth-1:0] end_addr;
  } node_addr_region_id_t;

  node_addr_region_id_t [NumNI-1:0] node_addr_regions;
  // assign node_addr_regions = '{
	// '{idx: '{x: 1, y: 2}, start_addr: 48'h000010000000, end_addr: 48'h000010003fff},
	// '{idx: '{x: 2, y: 1}, start_addr: 48'h000010004000, end_addr: 48'h000010007fff},
	// '{idx: '{x: 1, y: 0}, start_addr: 48'h000010008000, end_addr: 48'h00001000bfff},
	// '{idx: '{x: 0, y: 1}, start_addr: 48'h00001000c000, end_addr: 48'h000010010000}
  // };
  assign node_addr_regions = '{
      '{
          idx: '{x: 1, y: 2},
          start_addr: 48'h0000_0000_0000,
          end_addr: 48'h0000_0fff_ffff
      },  // cluster1_ni
      '{
          idx: '{x: 2, y: 1},
          start_addr: 48'h0000_1000_0000,
          end_addr: 48'h0000_1fff_ffff
      },  // cluster2_ni
      '{
          idx: '{x: 1, y: 0},
          start_addr: 48'h0000_2000_0000,
          end_addr: 48'h0000_2fff_ffff
      },  // cluster3_ni
      '{
          idx: '{x: 0, y: 1},
          start_addr: 48'h0000_3000_0000,
          end_addr: 48'h0000_3fff_ffff
      }  // cluster4_ni

  };  

	localparam int unsigned NumAddrRegions = NumNI-1;
	localparam node_addr_region_t [NumNI-1:0][NumAddrRegions-1:0] AddrsExcludeSelf = '{
	  '{
       '{start_addr: 48'h0000_2000_0000, end_addr: 48'h0000_2fff_ffff},
       '{start_addr: 48'h0000_1000_0000, end_addr: 48'h0000_1fff_ffff},
       '{start_addr: 48'h0000_0000_0000, end_addr: 48'h0000_0fff_ffff}
	  },
	  '{
       '{start_addr: 48'h0000_3000_0000, end_addr: 48'h0000_3fff_ffff},
       '{start_addr: 48'h0000_1000_0000, end_addr: 48'h0000_1fff_ffff},
       '{start_addr: 48'h0000_0000_0000, end_addr: 48'h0000_0fff_ffff}
	  },
	  '{
       '{start_addr: 48'h0000_3000_0000, end_addr: 48'h0000_3fff_ffff},
       '{start_addr: 48'h0000_2000_0000, end_addr: 48'h0000_2fff_ffff},
       '{start_addr: 48'h0000_0000_0000, end_addr: 48'h0000_0fff_ffff}
	  },
	  '{
       '{start_addr: 48'h0000_3000_0000, end_addr: 48'h0000_3fff_ffff},
       '{start_addr: 48'h0000_2000_0000, end_addr: 48'h0000_2fff_ffff},
       '{start_addr: 48'h0000_1000_0000, end_addr: 48'h0000_1fff_ffff}
	  }
	};

  router1_endpoint4_floo_noc i_dut (
  	.clk_i                (clk),
  	.rst_ni               (rst_n),
  	.test_enable_i        (1'b0),
  	.cluster1_narrow_req_i(narrow_man_req[0]),
  	.cluster1_narrow_rsp_o(narrow_man_rsp[0]),
  	.cluster1_wide_req_i  (wide_man_req[0]),
  	.cluster1_wide_rsp_o  (wide_man_rsp[0]),
  	.cluster1_narrow_req_o(narrow_sub_req[0]),
  	.cluster1_narrow_rsp_i(narrow_sub_rsp[0]),
  	.cluster1_wide_req_o  (wide_sub_req[0]),
  	.cluster1_wide_rsp_i  (wide_sub_rsp[0]),
  	.cluster2_narrow_req_i(narrow_man_req[1]),
  	.cluster2_narrow_rsp_o(narrow_man_rsp[1]),
  	.cluster2_wide_req_i  (wide_man_req[1]),
  	.cluster2_wide_rsp_o  (wide_man_rsp[1]),
  	.cluster2_narrow_req_o(narrow_sub_req[1]),
  	.cluster2_narrow_rsp_i(narrow_sub_rsp[1]),
  	.cluster2_wide_req_o  (wide_sub_req[1]),
  	.cluster2_wide_rsp_i  (wide_sub_rsp[1]),
  	.cluster3_narrow_req_i(narrow_man_req[2]),
  	.cluster3_narrow_rsp_o(narrow_man_rsp[2]),
  	.cluster3_wide_req_i  (wide_man_req[2]),
  	.cluster3_wide_rsp_o  (wide_man_rsp[2]),
  	.cluster3_narrow_req_o(narrow_sub_req[2]),
  	.cluster3_narrow_rsp_i(narrow_sub_rsp[2]),
  	.cluster3_wide_req_o  (wide_sub_req[2]),
  	.cluster3_wide_rsp_i  (wide_sub_rsp[2]),
  	.cluster4_narrow_req_i(narrow_man_req[3]),
  	.cluster4_narrow_rsp_o(narrow_man_rsp[3]),
  	.cluster4_wide_req_i  (wide_man_req[3]),
  	.cluster4_wide_rsp_o  (wide_man_rsp[3]),
  	.cluster4_narrow_req_o(narrow_sub_req[3]),
  	.cluster4_narrow_rsp_i(narrow_sub_rsp[3]),
  	.cluster4_wide_req_o  (wide_sub_req[3]),
  	.cluster4_wide_rsp_i  (wide_sub_rsp[3])   
  );


  for (genvar i = 0; i < NumNI; i++) begin : testnode_generation

  	// localparam int unsigned NumAddrRegions = NumNI-1;
  	// localparam node_addr_region_t [NumAddrRegions-1:0] AddrsExcludeSelf = '0;

  	// for (genvar j = 0; j < NumAddrRegions; j++) begin
  	// 	localparam int unsigned cnt = (j < i) ? j : j+1;
  	// 	// always_comb begin
  	// 	assign	AddrsExcludeSelf[j].start_addr = node_addr_regions[cnt].start_addr;
  	// 	assign 	AddrsExcludeSelf[j].end_addr = node_addr_regions[cnt].end_addr;
  	// 	// end
  	// end

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
	    .Atops          ( AtopSupport           ),
	    .AxiMaxBurstLen ( ReorderBufferSize     ),
	    .NumAddrRegions ( NumAddrRegions        ),
	    .rule_t         ( node_addr_region_t    ),
	    .AddrRegions    ( AddrsExcludeSelf[i]      ),
	    .NumReads       ( NarrowNumReads        ),
	    .NumWrites      ( NarrowNumWrites       )
	  ) i_narrow_test_node (
	    .clk_i          ( clk               ),
	    .rst_ni         ( rst_n             ),
	    .mst_port_req_o ( narrow_man_req[i] ),
	    .mst_port_rsp_i ( narrow_man_rsp[i] ),
	    .slv_port_req_i ( narrow_sub_req[i] ),
	    .slv_port_rsp_o ( narrow_sub_rsp[i] ),
	    .end_of_sim     ( end_of_sim[2*i]     )
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
	    .Atops          ( 1'b0                ),
	    .ApplTime       ( ApplTime            ),
	    .TestTime       ( TestTime            ),
	    .AxiMaxBurstLen ( ReorderBufferSize   ),
	    .NumAddrRegions ( NumAddrRegions      ),
	    .rule_t         ( node_addr_region_t  ),
	    .AddrRegions    ( AddrsExcludeSelf[i]    ),
	    .NumReads       ( WideNumReads        ),
	    .NumWrites      ( WideNumWrites       )
	  ) i_wide_test_node (
	    .clk_i          ( clk             ),
	    .rst_ni         ( rst_n           ),
	    .mst_port_req_o ( wide_man_req[i] ),
	    .mst_port_rsp_i ( wide_man_rsp[i] ),
	    .slv_port_req_i ( wide_sub_req[i] ),
	    .slv_port_rsp_o ( wide_sub_rsp[i] ),
	    .end_of_sim     ( end_of_sim[2*i+1]   )
	  );  	
  end

  initial begin
    wait(&end_of_sim);
    $stop;
  end

endmodule