// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "axi/assign.svh"
`include "axi/typedef.svh"

/// A AXI4 Bus Multi-Slave generating random AXI respones with configurable response time
module floo_axi_rand_slave
  import floo_test_pkg::*;
#(
  parameter int unsigned AxiAddrWidth = 0,
  parameter int unsigned AxiDataWidth = 0,
  parameter int unsigned AxiIdWidth   = 0,
  parameter int unsigned AxiUserWidth = 0,
  parameter type axi_req_t = logic,
  parameter type axi_rsp_t = logic,
  // Dependent parameter, DO NOT OVERWRITE!
  parameter int unsigned AxiStrbWidth = AxiDataWidth/8,
  // TB Parameters
  parameter time ApplTime = 2ns,
  parameter time TestTime = 8ns,
  parameter logic[AxiAddrWidth-1:0] DstStartAddr = '0,
  parameter logic[AxiAddrWidth-1:0] DstEndAddr = '1,
  parameter slave_type_e SlaveType = MixedSlave,
  parameter int unsigned NumSlaves = 4,
  localparam logic[AxiAddrWidth-1:0] SlvAddrSpace = (DstEndAddr - DstStartAddr) / NumSlaves
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  axi_req_t slv_port_req_i,
  output axi_rsp_t slv_port_rsp_o,

  output axi_req_t [NumSlaves-1:0] mon_mst_port_req_o,
  output axi_rsp_t [NumSlaves-1:0] mon_mst_port_rsp_o
);

  typedef logic [AxiAddrWidth-1:0] addr_t;
  typedef logic [AxiDataWidth-1:0] data_t;
  typedef logic [AxiStrbWidth-1:0] strb_t;
  typedef logic [AxiIdWidth-1:0]   id_t;
  typedef logic [AxiUserWidth-1:0] user_t;

  `AXI_TYPEDEF_ALL(axi_xbar, addr_t, id_t, data_t, strb_t, user_t)

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth      ),
    .AXI_DATA_WIDTH ( AxiDataWidth      ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth      )
  ) slave_dv [NumSlaves] (clk_i);

  typedef struct packed {
    logic [31:0] idx;
    logic [AxiAddrWidth-1:0] start_addr;
    logic [AxiAddrWidth-1:0] end_addr;
  } xbar_rule_t;

  xbar_rule_t [NumSlaves-1:0] XbarAddrMap;
  for (genvar i = 0; i < NumSlaves; i++) begin : gen_addr_rules
    assign XbarAddrMap[i] = '{
      idx: i,
      start_addr: DstStartAddr + i * SlvAddrSpace,
      end_addr: DstStartAddr + (i+1) * SlvAddrSpace
    };
  end

  localparam axi_pkg::xbar_cfg_t XbarCfg = '{
    NoSlvPorts:         1,
    NoMstPorts:         NumSlaves,
    MaxSlvTrans:        128,
    MaxMstTrans:        128,
    FallThrough:        1,
    LatencyMode:        axi_pkg::CUT_ALL_PORTS,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: AxiIdWidth,
    AxiIdUsedSlvPorts:  AxiIdWidth,
    UniqueIds:          0,
    AxiAddrWidth:       AxiAddrWidth,
    AxiDataWidth:       AxiDataWidth,
    NoAddrRules:        NumSlaves
  };

  axi_xbar_req_t xbar_in_req;
  axi_xbar_resp_t xbar_in_rsp;
  axi_xbar_req_t [NumSlaves-1:0] xbar_out_req;
  axi_xbar_resp_t [NumSlaves-1:0] xbar_out_rsp;

  axi_xbar #(
    .Cfg          (XbarCfg),
    .Connectivity ('1),
    .ATOPs        (0),
    .slv_aw_chan_t(axi_xbar_aw_chan_t),
    .mst_aw_chan_t(axi_xbar_aw_chan_t),
    .w_chan_t     (axi_xbar_w_chan_t ),
    .slv_b_chan_t (axi_xbar_b_chan_t ),
    .mst_b_chan_t (axi_xbar_b_chan_t ),
    .slv_ar_chan_t(axi_xbar_ar_chan_t),
    .mst_ar_chan_t(axi_xbar_ar_chan_t),
    .slv_r_chan_t (axi_xbar_r_chan_t ),
    .mst_r_chan_t (axi_xbar_r_chan_t ),
    .slv_req_t    (axi_xbar_req_t   ),
    .slv_resp_t   (axi_xbar_resp_t   ),
    .mst_req_t    (axi_xbar_req_t   ),
    .mst_resp_t   (axi_xbar_resp_t   ),
    .rule_t       (xbar_rule_t)
  ) i_xbar (
    .clk_i                (clk_i),
    .rst_ni               (rst_ni),
    .test_i               (1'b0),
    .slv_ports_req_i      (xbar_in_req),
    .slv_ports_resp_o     (xbar_in_rsp),
    .mst_ports_req_o      (xbar_out_req),
    .mst_ports_resp_i     (xbar_out_rsp),
    .addr_map_i           (XbarAddrMap),
    .en_default_mst_port_i('1),
    .default_mst_port_i   ('0)
  );

  assign xbar_in_req = slv_port_req_i;
  assign slv_port_rsp_o = xbar_in_rsp;

  for (genvar i = 0; i < NumSlaves; i++) begin : gen_assign_slvs
    `AXI_ASSIGN_FROM_REQ(slave_dv[i], xbar_out_req[i])
    `AXI_ASSIGN_TO_RESP(xbar_out_rsp[i], slave_dv[i])
    `AXI_ASSIGN_TO_REQ(mon_mst_port_req_o[i], slave_dv[i])
    `AXI_ASSIGN_TO_RESP(mon_mst_port_rsp_o[i], slave_dv[i])
  end

  typedef axi_test::axi_rand_slave #(
    // AXI interface parameters
    .AW ( AxiAddrWidth     ),
    .DW ( AxiDataWidth     ),
    .IW ( AxiIdWidth       ),
    .UW ( AxiUserWidth     ),
    // Stimuli application and test time
    .TA ( ApplTime         ),
    .TT ( TestTime         )
  ) axi_rand_slave_t;

  typedef axi_test::axi_rand_slave #(
    // AXI interface parameters
    .AW ( AxiAddrWidth     ),
    .DW ( AxiDataWidth     ),
    .IW ( AxiIdWidth       ),
    .UW ( AxiUserWidth     ),
    // Stimuli application and test time
    .TA ( ApplTime         ),
    .TT ( TestTime         ),
    // Responsiveness
    .AX_MIN_WAIT_CYCLES   (0),
    .AX_MAX_WAIT_CYCLES   (5),
    .R_MIN_WAIT_CYCLES    (0),
    .R_MAX_WAIT_CYCLES    (5),
    .RESP_MIN_WAIT_CYCLES (0),
    .RESP_MAX_WAIT_CYCLES (5)
  ) axi_rand_fast_slave_t;

  typedef axi_test::axi_rand_slave #(
    // AXI interface parameters
    .AW ( AxiAddrWidth     ),
    .DW ( AxiDataWidth     ),
    .IW ( AxiIdWidth       ),
    .UW ( AxiUserWidth     ),
    // Stimuli application and test time
    .TA ( ApplTime         ),
    .TT ( TestTime         ),
    // Responsiveness
    .AX_MIN_WAIT_CYCLES   (50),
    .AX_MAX_WAIT_CYCLES   (100),
    .R_MIN_WAIT_CYCLES    (50),
    .R_MAX_WAIT_CYCLES    (100),
    .RESP_MIN_WAIT_CYCLES (50),
    .RESP_MAX_WAIT_CYCLES (100)
  ) axi_rand_slow_slave_t;

  // axi slave
  axi_rand_slow_slave_t axi_rand_slow_slave[NumSlaves];
  axi_rand_fast_slave_t axi_rand_fast_slave[NumSlaves];

  if (SlaveType == SlowSlave) begin : gen_slow_slaves
    for (genvar i = 0; i < NumSlaves; i++) begin
      initial begin
        axi_rand_slow_slave[i] = new( slave_dv[i] );
        axi_rand_slow_slave[i].reset();
        @(posedge rst_ni)
        axi_rand_slow_slave[i].run();
      end
    end
  end else if (SlaveType == FastSlave) begin : gen_fast_slaves
    for (genvar i = 0; i < NumSlaves; i++) begin
      initial begin
        axi_rand_fast_slave[i] = new( slave_dv[i] );
        axi_rand_fast_slave[i].reset();
        @(posedge rst_ni)
        axi_rand_fast_slave[i].run();
      end
    end
  end else if (SlaveType == MixedSlave) begin : gen_mixed_slaves
    for (genvar i = 0; i < NumSlaves; i++) begin
      if (i % 2 == 0) begin
        initial begin
          axi_rand_slow_slave[i] = new( slave_dv[i] );
          axi_rand_slow_slave[i].reset();
          @(posedge rst_ni)
          axi_rand_slow_slave[i].run();
        end
      end else begin
        initial begin
          axi_rand_fast_slave[i] = new( slave_dv[i] );
          axi_rand_fast_slave[i].reset();
          @(posedge rst_ni)
          axi_rand_fast_slave[i].run();
        end
      end
    end
  end

endmodule
