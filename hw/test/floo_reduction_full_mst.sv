// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Raphael Roth <raroth@student.ethz.ch>

// This module simulate the enviroment around a router.

// Open Points:

`include "common_cells/assertions.svh"
`include "axi/assign.svh"
`include "floo_noc/typedef.svh"

module floo_reduction_full_mst #(
    /// Apply Time
    parameter time                          ApplTime        = 1ns,
    /// Test Time
    parameter time                          TestTime        = 1ns,
    /// Configuration for the underlying AXI
    parameter floo_pkg::axi_cfg_t           AxiCfg          = '{default:0},
    /// AXI request / response type
    parameter type                          mst_req_t       = logic,
    parameter type                          mst_rsp_t       = logic,
    parameter type                          slv_req_t       = logic,
    parameter type                          slv_rsp_t       = logic,
    /// Address rule
    parameter type                          rule_t          = logic,
    /// div Param
    parameter int unsigned                  AxiMaxBurstLen  = 128,
    parameter int unsigned                  NumAddrRegions  = 0,
    parameter rule_t [NumAddrRegions-1:0]   AddrRegions     = '0,
    parameter int unsigned                  NumInvalidPath  = 0,
    parameter rule_t [NumInvalidPath-1:0]   InvalidPath     = '0,
    parameter int unsigned                  NumPossibleMask = 0,
    parameter rule_t [NumPossibleMask-1:0]  PossibleMask    = '0,
    parameter int unsigned                  NumReductions   = 10,
    parameter int unsigned                  NumTestPorts    = 5,
    parameter int unsigned                  NumInfligthElem = 20
) (
    input  logic                            clk_i,
    input  logic                            rst_ni,
    // Master Port
    output mst_req_t [NumTestPorts-1:0]     mst_port_req_o,
    input  mst_rsp_t [NumTestPorts-1:0]     mst_port_rsp_i,
    // Slave Port
    input  slv_req_t [NumTestPorts-1:0]     slv_port_req_i,
    output slv_rsp_t [NumTestPorts-1:0]     slv_port_rsp_o,
    // Flag for each Test Port to indicate if finsihed
    output logic     [NumTestPorts-1:0]     end_of_sim_o
);



    /* All local parameter */


    /* All Typedef Vars */


    // Generate the typedef for the reduction master
    typedef axi_reduction_test::axi_reduction_rand_master #(
        // AXI interface parameters
        .AW                             (AxiCfg.AddrWidth),
        .DW                             (AxiCfg.DataWidth),
        .IW                             (AxiCfg.InIdWidth), 
        .UW                             (AxiCfg.UserWidth),
        // Stimuli application and test time
        .TA                             (ApplTime),
        .TT                             (TestTime),
        // Maximum number of read and write transactions in flight
        .MAX_READ_TXNS                  (NumInfligthElem),
        .MAX_WRITE_TXNS                 (NumInfligthElem),
        .AXI_EXCLS                      (1'b0),
        .AXI_ATOPS                      (1'b0),
        .UNIQUE_IDS                     (1'b0),
        // Extra parameters to handle reduction requests
        .rule_t                         (rule_t), 
        .NoAddrRules                    (NumAddrRegions ),
        .NoInvalidPath                  (NumInvalidPath),
        .NoPossibleMask                 (NumPossibleMask),
        .NoMsts                         (NumTestPorts),
        .NoSlvs                         (NumTestPorts),
        .NoRedPorts                     (NumTestPorts),
        .NoWrites                       (NumReductions),
        .ENABLE_REDUCTION               (1'b1),
        .ENABLE_EXCLUSIVE_REDUCTION     (1'b1),
        .ReductionId                    (2),
        .AddrMap                        (AddrRegions),
        .InvalidPath                    (InvalidPath),
        .PossibleMask                   (PossibleMask)
    ) axi_reduction_rand_master_t;

    // Generate the typedef for the slave
    typedef axi_reduction_test::axi_reduction_rand_slave #(
        //typedef axi_reduction_test::axi_reduction_rand_slave #(
        // AXI interface parameters
        .AW (AxiCfg.AddrWidth),
        .DW (AxiCfg.DataWidth),
        .IW (AxiCfg.InIdWidth), 
        .UW (AxiCfg.UserWidth),
        // Stimuli application and test time
        .TA (ApplTime),
        .TT (TestTime),
        .ENABLE_EXCLUSIVE_REDUCTION     (1'b1)
    ) axi_rand_slave_t;

    /* Variable declaration */

    // AXI Interfaces Master
    AXI_BUS #(
        .AXI_ADDR_WIDTH (AxiCfg.AddrWidth),
        .AXI_DATA_WIDTH (AxiCfg.DataWidth),
        .AXI_ID_WIDTH   (AxiCfg.InIdWidth),
        .AXI_USER_WIDTH (AxiCfg.UserWidth)
    ) master [NumTestPorts-1:0] ();
    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH (AxiCfg.AddrWidth),
        .AXI_DATA_WIDTH (AxiCfg.DataWidth),
        .AXI_ID_WIDTH   (AxiCfg.InIdWidth),
        .AXI_USER_WIDTH (AxiCfg.UserWidth)
    ) master_dv [NumTestPorts-1:0] (clk_i);
    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH (AxiCfg.AddrWidth),
        .AXI_DATA_WIDTH (AxiCfg.DataWidth),
        .AXI_ID_WIDTH   (AxiCfg.InIdWidth),
        .AXI_USER_WIDTH (AxiCfg.UserWidth)
    ) master_monitor_dv [NumTestPorts-1:0] (clk_i);

    // AXI Interfaces Slaves
    AXI_BUS #(
        .AXI_ADDR_WIDTH (AxiCfg.AddrWidth),
        .AXI_DATA_WIDTH (AxiCfg.DataWidth),
        .AXI_ID_WIDTH   (AxiCfg.InIdWidth),
        .AXI_USER_WIDTH (AxiCfg.UserWidth)
    ) slave [NumTestPorts-1:0] ();
    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH (AxiCfg.AddrWidth),
        .AXI_DATA_WIDTH (AxiCfg.DataWidth),
        .AXI_ID_WIDTH   (AxiCfg.InIdWidth),
        .AXI_USER_WIDTH (AxiCfg.UserWidth)
    ) slave_dv [NumTestPorts-1:0](clk_i);
    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH (AxiCfg.AddrWidth),
        .AXI_DATA_WIDTH (AxiCfg.DataWidth),
        .AXI_ID_WIDTH   (AxiCfg.InIdWidth),
        .AXI_USER_WIDTH (AxiCfg.UserWidth)
    ) slave_monitor_dv [NumTestPorts-1:0](clk_i);

    // Master & Slave class to generate / accept data
    axi_reduction_rand_master_t axi_rand_master [NumTestPorts];
    axi_rand_slave_t axi_rand_slave [NumTestPorts];

    /* Module Declaration */

    // Connect the DV Master
    for (genvar i = 0; i < NumTestPorts; i++) begin : gen_conn_dv_masters
        `AXI_ASSIGN (master[i], master_dv[i])
        `AXI_ASSIGN_TO_REQ(mst_port_req_o[i], master[i])
        `AXI_ASSIGN_FROM_RESP(master[i], mst_port_rsp_i[i])
    end

    // Connect the DV Slaves
    for (genvar i = 0; i < NumTestPorts; i++) begin : gen_conn_dv_slaves
        `AXI_ASSIGN(slave_dv[i], slave[i])
        `AXI_ASSIGN_FROM_REQ(slave[i], slv_port_req_i[i])
        `AXI_ASSIGN_TO_RESP(slv_port_rsp_o[i], slave[i])
    end

    // Run all testbench masters
    for (genvar i = 0; i < NumTestPorts; i++) begin : gen_rand_master
        initial begin
            axi_rand_master[i] = new(master_dv[i]);
            end_of_sim_o[i] <= 1'b0;

            // Add all other memory region to the master's (TODO: Correct? Take a look with Lorenzo)
            //axi_rand_master[i].add_memory_region(AddrRegions[i].start_addr, AddrRegions[i].end_addr, axi_pkg::DEVICE_NONBUFFERABLE);
            for(int j = 0; j < NumTestPorts; j++) begin
                if(i != j) begin
                    axi_rand_master[i].add_memory_region(AddrRegions[j].start_addr, AddrRegions[j].end_addr, axi_pkg::DEVICE_NONBUFFERABLE);
                end
            end
            
            axi_rand_master[i].set_mst_idx(i);
            axi_rand_master[i].set_reduction_probability(100);
            axi_rand_master[i].reset();
            @(posedge rst_ni);
            axi_rand_master[i].run(0, NumReductions);
            end_of_sim_o[i] <= 1'b1;
        end
    end

    // Run all testbench slaves
    for (genvar i = 0; i < NumTestPorts; i++) begin : gen_rand_slave
        initial begin
            axi_rand_slave[i] = new(slave_dv[i]);
            axi_rand_slave[i].set_slv_idx(i);
            axi_rand_slave[i].reset();
            @(posedge rst_ni);
            axi_rand_slave[i].run();
        end
    end

endmodule