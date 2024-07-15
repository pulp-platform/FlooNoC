// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "axi/assign.svh"

/// A AXI4 Bus Master-Slave Node for generating random AXI transactions
module floo_axi_test_node #(
  parameter int unsigned AxiAddrWidth = 0,
  parameter int unsigned AxiDataWidth = 0,
  parameter int unsigned AxiIdInWidth = 0,
  parameter int unsigned AxiIdOutWidth   = 0,
  parameter int unsigned AxiUserWidth = 0,
  parameter type mst_req_t = logic,
  parameter type mst_rsp_t = logic,
  parameter type slv_req_t = logic,
  parameter type slv_rsp_t = logic,
  // Dependent parameter, DO NOT OVERWRITE!
  parameter int unsigned AxiStrbWidth = AxiDataWidth/8,
  // TB Parameters
  parameter time ApplTime = 2ns,
  parameter time TestTime = 8ns,
  parameter bit          Atops = 1'b0,
  parameter int unsigned AxiMaxBurstLen = 128,
  parameter int unsigned NumAddrRegions  = 1,
  parameter type rule_t = logic,
  parameter rule_t [NumAddrRegions-1:0] AddrRegions = '0,
  parameter int unsigned NumReads = 0,
  parameter int unsigned NumWrites = 0
) (
  input  logic clk_i,
  input  logic rst_ni,

  output mst_req_t mst_port_req_o,
  input  mst_rsp_t mst_port_rsp_i,

  input  slv_req_t slv_port_req_i,
  output slv_rsp_t slv_port_rsp_o,

  output logic end_of_sim
);
  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth  ),
    .AXI_DATA_WIDTH ( AxiDataWidth  ),
    .AXI_ID_WIDTH   ( AxiIdOutWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth  )
  ) master_dv (clk_i);

  `AXI_ASSIGN_TO_REQ(mst_port_req_o, master_dv)
  `AXI_ASSIGN_FROM_RESP(master_dv, mst_port_rsp_i)

  typedef axi_test::axi_rand_master #(
    // AXI interface parameters
    .AW ( AxiAddrWidth  ),
    .DW ( AxiDataWidth  ),
    .IW ( AxiIdOutWidth ),
    .UW ( AxiUserWidth  ),
    // Stimuli application and test time
    .TA ( ApplTime      ),
    .TT ( TestTime      ),
    // Maximum number of read and write transactions in flight
    .MAX_READ_TXNS  ( 20    ),
    .MAX_WRITE_TXNS ( 20    ),
    .AXI_EXCLS      ( 1'b0  ),
    .AXI_ATOPS      ( Atops ),
    .UNIQUE_IDS     ( 1'b0  ),
    // Delay of master port
    .AXI_MAX_BURST_LEN    ( AxiMaxBurstLen ),
    .AX_MIN_WAIT_CYCLES   ( 0              ),
    .AX_MAX_WAIT_CYCLES   ( 2              ),
    .W_MIN_WAIT_CYCLES    ( 0              ),
    .W_MAX_WAIT_CYCLES    ( 2              ),
    .RESP_MIN_WAIT_CYCLES ( 0              ),
    .RESP_MAX_WAIT_CYCLES ( 2              ),
    .ENABLE_MULTICAST ( 1'b1 )
  ) axi_rand_master_t;

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth  ),
    .AXI_DATA_WIDTH ( AxiDataWidth  ),
    .AXI_ID_WIDTH   ( AxiIdOutWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth  )
  ) slave_dv (clk_i);

  `AXI_ASSIGN_FROM_REQ(slave_dv, slv_port_req_i)
  `AXI_ASSIGN_TO_RESP(slv_port_rsp_o, slave_dv)

  typedef axi_test::axi_rand_slave #(
    // AXI interface parameters
    .AW ( AxiAddrWidth  ),
    .DW ( AxiDataWidth  ),
    .IW ( AxiIdOutWidth ),
    .UW ( AxiUserWidth  ),
    // Stimuli application and test time
    .TA ( ApplTime      ),
    .TT ( TestTime      )
  ) axi_rand_slave_t;

  // traffic generator master
  axi_rand_master_t axi_rand_master;
  initial begin
    axi_rand_master = new( master_dv);
    end_of_sim = 1'b0;

    for (int i = 0; i < NumAddrRegions; i++) begin
      axi_rand_master.add_memory_region(AddrRegions[i].start_addr,
                                        AddrRegions[i].end_addr,
                                        axi_pkg::DEVICE_NONBUFFERABLE);
    end

    axi_rand_master.set_multicast_probability(50);
    axi_rand_master.reset();
    @(posedge rst_ni)
    axi_rand_master.run(NumReads, NumWrites);
    end_of_sim = 1'b1;
  end

  // axi slave
  axi_rand_slave_t axi_rand_slave;
  initial begin
    axi_rand_slave = new( slave_dv );
    axi_rand_slave.reset();
    @(posedge rst_ni)
    axi_rand_slave.run();
  end

endmodule
