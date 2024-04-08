// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
//  - Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "idma/typedef.svh"

/// An endpoint node with a DMA master port and a Simulation Memory Slave port
module floo_dma_test_node  #(
  parameter time         TA                   = 1ns,
  parameter time         TT                   = 9ns,
  parameter int unsigned BufferDepth          = 16,
  parameter int unsigned NumAxInFlight        = 16,
  parameter int unsigned DataWidth            = 32,
  parameter int unsigned AddrWidth            = 32,
  parameter int unsigned UserWidth            = 1,
  parameter int unsigned AxiIdWidth           = 2,
  parameter int unsigned AxiIdInWidth         = AxiIdWidth,
  parameter int unsigned AxiIdOutWidth        = AxiIdWidth,
  parameter type axi_req_t                    = logic,
  parameter type axi_rsp_t                    = logic,
  parameter type axi_in_req_t                 = axi_req_t,
  parameter type axi_in_rsp_t                 = axi_rsp_t,
  parameter type axi_out_req_t                = axi_req_t,
  parameter type axi_out_rsp_t                = axi_rsp_t,
  parameter int unsigned TFLenWidth           = 32,
  parameter int unsigned MemSysDepth          = 0,
  parameter logic [AddrWidth-1:0] MemBaseAddr = 32'h0,
  parameter logic [AddrWidth-1:0] MemSize     = 32'h10000,
  parameter bit          MaskInvalidData      = 1,
  parameter bit          RAWCouplingAvail     = 1,
  parameter bit          HardwareLegalizer    = 1,
  parameter bit          RejectZeroTransfers  = 1,
  parameter bit          ErrorHandling        = 0,
  parameter int          JobId                = -1,
  parameter bit          EnableDebug          = 0
) (
  input logic  clk_i,
  input logic  rst_ni,
  input axi_in_req_t  axi_in_req_i,
  output axi_in_rsp_t axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input axi_out_rsp_t axi_out_rsp_i,
  output logic end_of_sim_o
);

  import idma_pkg::*;

  // debug
  localparam bit Debug         = 1'b0;
  localparam bit ModelOutput   = 1'b0;
  localparam bit PrintFifoInfo = 1'b0;

  // dependent parameters
  localparam int unsigned StrbWidth       = DataWidth / 8;
  localparam int unsigned OffsetWidth     = $clog2(StrbWidth);

  // parse error handling caps
  localparam idma_pkg::error_cap_e ErrorCap = ErrorHandling ? idma_pkg::ERROR_HANDLING :
                                                            idma_pkg::NO_ERROR_HANDLING;

  // static types
  typedef logic [7:0] byte_t;

  // dependent typed
  typedef logic [AddrWidth-1:0]     addr_t;
  typedef logic [DataWidth-1:0]     data_t;
  typedef logic [StrbWidth-1:0]     strb_t;
  typedef logic [UserWidth-1:0]     user_t;
  typedef logic [AxiIdInWidth-1:0]  id_in_t;
  typedef logic [AxiIdOutWidth-1:0] id_out_t;
  typedef logic [OffsetWidth-1:0]   offset_t;
  typedef logic [TFLenWidth-1:0]    tf_len_t;

  // AXI typedef
  `AXI_TYPEDEF_ALL(axi_xbar, addr_t, id_out_t, data_t, strb_t, user_t)

  typedef struct packed {
    axi_xbar_ar_chan_t ar_chan;
  } axi_xbar_read_meta_channel_t;
  typedef union packed {
    axi_xbar_read_meta_channel_t axi;
  } read_meta_channel_t;
  typedef struct packed {
    axi_xbar_aw_chan_t aw_chan;
  } axi_xbar_write_meta_channel_t;
  typedef union packed {
    axi_xbar_write_meta_channel_t axi;
  } write_meta_channel_t;

  // iDMA request / response types
  `IDMA_TYPEDEF_FULL_REQ_T(idma_req_t, id_out_t, addr_t, tf_len_t)
  `IDMA_TYPEDEF_FULL_RSP_T(idma_rsp_t, addr_t)

  //--------------------------------------
  // DMA Signals
  //--------------------------------------

  // dma request
  idma_req_t idma_req;
  logic req_valid;
  logic req_ready;

  // dma response
  idma_rsp_t idma_rsp;
  logic rsp_valid;
  logic rsp_ready;

  // error handler
  idma_eh_req_t idma_eh_req;
  logic eh_req_valid;
  logic eh_req_ready;

  // AXI Xbar signals
  axi_xbar_req_t [0:0] xbar_in_req;
  axi_xbar_resp_t [0:0] xbar_in_rsp;
  axi_xbar_req_t [1:0] xbar_out_req;
  axi_xbar_resp_t [1:0]  xbar_out_rsp;

  // AXI4 master
  axi_xbar_req_t axi_dma_req, axi_dma_read_req, axi_dma_write_req;
  axi_xbar_resp_t axi_dma_rsp, axi_dma_read_rsp, axi_dma_write_rsp;

  // AXI4 slave
  axi_xbar_req_t axi_mem_req;
  axi_xbar_resp_t axi_mem_rsp;

  // busy signal
  idma_busy_t busy;

  typedef struct packed {
    logic [31:0] idx;
    logic [AddrWidth-1:0] start_addr;
    logic [AddrWidth-1:0] end_addr;
  } xbar_rule_t;

  xbar_rule_t [0:0] XbarAddrMap;
  assign XbarAddrMap = '{
    '{ idx: 0, start_addr: MemBaseAddr, end_addr: MemBaseAddr + MemSize }
  };

  localparam axi_pkg::xbar_cfg_t XbarCfg = '{
    NoSlvPorts:         1,
    NoMstPorts:         2,
    MaxSlvTrans:        128,
    MaxMstTrans:        128,
    FallThrough:        1,
    LatencyMode:        axi_pkg::CUT_ALL_PORTS,
    AxiIdWidthSlvPorts: AxiIdOutWidth,
    AxiIdUsedSlvPorts:  AxiIdOutWidth,
    UniqueIds:          0,
    AxiAddrWidth:       AddrWidth,
    AxiDataWidth:       DataWidth,
    NoAddrRules:        1,
    PipelineStages:     0
  };

  //--------------------------------------
  // DMA
  //--------------------------------------
  idma_backend_rw_axi #(
    .DataWidth           ( DataWidth              ),
    .AddrWidth           ( AddrWidth              ),
    .AxiIdWidth          ( AxiIdOutWidth          ),
    .UserWidth           ( UserWidth              ),
    .TFLenWidth          ( TFLenWidth             ),
    .MaskInvalidData     ( MaskInvalidData        ),
    .BufferDepth         ( BufferDepth            ),
    .RAWCouplingAvail    ( RAWCouplingAvail       ),
    .HardwareLegalizer   ( HardwareLegalizer      ),
    .RejectZeroTransfers ( RejectZeroTransfers    ),
    .ErrorCap            ( ErrorCap               ),
    .PrintFifoInfo       ( PrintFifoInfo          ),
    .NumAxInFlight       ( NumAxInFlight          ),
    .MemSysDepth         ( MemSysDepth            ),
    .idma_req_t          ( idma_req_t             ),
    .idma_rsp_t          ( idma_rsp_t             ),
    .idma_eh_req_t       ( idma_eh_req_t          ),
    .idma_busy_t         ( idma_busy_t            ),
    .axi_req_t           ( axi_xbar_req_t         ),
    .axi_rsp_t           ( axi_xbar_resp_t        ),
    .write_meta_channel_t( write_meta_channel_t   ),
    .read_meta_channel_t ( read_meta_channel_t    )
  ) i_idma_backend (
    .clk_i          ( clk_i           ),
    .rst_ni         ( rst_ni          ),
    .testmode_i     ( 1'b0            ),
    .idma_req_i     ( idma_req        ),
    .req_valid_i    ( req_valid       ),
    .req_ready_o    ( req_ready       ),
    .idma_rsp_o     ( idma_rsp        ),
    .rsp_valid_o    ( rsp_valid       ),
    .rsp_ready_i    ( rsp_ready       ),
    .idma_eh_req_i  ( idma_eh_req     ),
    .eh_req_valid_i ( eh_req_valid    ),
    .eh_req_ready_o ( eh_req_ready    ),
    .axi_read_req_o (axi_dma_read_req ),
    .axi_read_rsp_i (axi_dma_read_rsp ),
    .axi_write_req_o(axi_dma_write_req),
    .axi_write_rsp_i(axi_dma_write_rsp),
    .busy_o         ( busy            )
  );

  // Read Write Join
  axi_rw_join #(
    .axi_req_t        ( axi_xbar_req_t ),
    .axi_resp_t       ( axi_xbar_resp_t )
) i_axi_rw_join (
    .clk_i,
    .rst_ni,
    .slv_read_req_i   ( axi_dma_read_req  ),
    .slv_read_resp_o  ( axi_dma_read_rsp  ),
    .slv_write_req_i  ( axi_dma_write_req ),
    .slv_write_resp_o ( axi_dma_write_rsp ),
    .mst_req_o        ( axi_dma_req       ),
    .mst_resp_i       ( axi_dma_rsp       )
);

  axi_xbar #(
    .Cfg          ( XbarCfg             ),
    .Connectivity ( '1                  ),
    .ATOPs        ( 0                   ),
    .slv_aw_chan_t( axi_xbar_aw_chan_t  ),
    .mst_aw_chan_t( axi_xbar_aw_chan_t  ),
    .w_chan_t     ( axi_xbar_w_chan_t   ),
    .slv_b_chan_t ( axi_xbar_b_chan_t   ),
    .mst_b_chan_t ( axi_xbar_b_chan_t   ),
    .slv_ar_chan_t( axi_xbar_ar_chan_t  ),
    .mst_ar_chan_t( axi_xbar_ar_chan_t  ),
    .slv_r_chan_t ( axi_xbar_r_chan_t   ),
    .mst_r_chan_t ( axi_xbar_r_chan_t   ),
    .slv_req_t    ( axi_xbar_req_t      ),
    .slv_resp_t   ( axi_xbar_resp_t     ),
    .mst_req_t    ( axi_xbar_req_t      ),
    .mst_resp_t   ( axi_xbar_resp_t     ),
    .rule_t       ( xbar_rule_t         )
  ) i_xbar (
    .clk_i                  ( clk_i         ),
    .rst_ni                 ( rst_ni        ),
    .test_i                 ( 1'b0          ),
    .slv_ports_req_i        ( xbar_in_req   ),
    .slv_ports_resp_o       ( xbar_in_rsp   ),
    .mst_ports_req_o        ( xbar_out_req  ),
    .mst_ports_resp_i       ( xbar_out_rsp  ),
    .addr_map_i             ( XbarAddrMap   ),
    .en_default_mst_port_i  ( '1            ),
    .default_mst_port_i     ( 1'b1          )
  );

  floo_axi_rand_slave #(
    .AxiAddrWidth ( AddrWidth                 ),
    .AxiDataWidth ( DataWidth                 ),
    .AxiIdWidth   ( AxiIdOutWidth             ),
    .AxiUserWidth ( UserWidth                 ),
    .AxiStrbWidth ( StrbWidth                 ),
    .ApplTime     ( TA                        ),
    .TestTime     ( TT                        ),
    .SlaveType    ( floo_test_pkg::FastSlave  ),
    .NumSlaves    ( 1                         ),
    .axi_req_t    ( axi_xbar_req_t            ),
    .axi_rsp_t    ( axi_xbar_resp_t           )
  ) i_dma_sim_mem (
    .clk_i              ( clk_i       ),
    .rst_ni             ( rst_ni      ),
    .slv_port_req_i     ( axi_mem_req ),
    .slv_port_rsp_o     ( axi_mem_rsp ),
    .mon_mst_port_req_o (             ),
    .mon_mst_port_rsp_o (             )
  );

  floo_axi_rand_slave #(
    .AxiAddrWidth ( AddrWidth                 ),
    .AxiDataWidth ( DataWidth                 ),
    .AxiIdWidth   ( AxiIdInWidth              ),
    .AxiUserWidth ( UserWidth                 ),
    .AxiStrbWidth ( StrbWidth                 ),
    .ApplTime     ( TA                        ),
    .TestTime     ( TT                        ),
    .SlaveType    ( floo_test_pkg::FastSlave  ),
    .NumSlaves    ( 1                         ),
    .axi_req_t    ( axi_in_req_t              ),
    .axi_rsp_t    ( axi_in_rsp_t              )
  ) i_sink_in_mem (
    .clk_i              ( clk_i         ),
    .rst_ni             ( rst_ni        ),
    .slv_port_req_i     ( axi_in_req_i  ),
    .slv_port_rsp_o     ( axi_in_rsp_o  ),
    .mon_mst_port_req_o (               ),
    .mon_mst_port_rsp_o (               )
  );

  assign xbar_in_req = axi_dma_req;
  assign axi_dma_rsp = xbar_in_rsp;
  assign axi_mem_req = xbar_out_req[0];
  assign xbar_out_rsp[0] = axi_mem_rsp;
  assign axi_out_req_o = xbar_out_req[1];
  assign xbar_out_rsp[1] = axi_out_rsp_i;

  //--------------------------------------
  // DMA Driver
  //--------------------------------------
  // virtual interface definition
  IDMA_DV #(
    .DataWidth  ( DataWidth     ),
    .AddrWidth  ( AddrWidth     ),
    .UserWidth  ( UserWidth     ),
    .AxiIdWidth ( AxiIdOutWidth ),
    .TFLenWidth ( TFLenWidth    )
  ) idma_dv (clk_i);

  // DMA driver type
  typedef idma_test::idma_driver #(
      .DataWidth  ( DataWidth     ),
      .AddrWidth  ( AddrWidth     ),
      .UserWidth  ( UserWidth     ),
      .AxiIdWidth ( AxiIdOutWidth ),
      .TFLenWidth ( TFLenWidth    ),
      .TA         ( TA            ),
      .TT         ( TT            )
  ) drv_t;

  // instantiation of the driver
  drv_t drv = new(idma_dv);

  // connect virtual driver interface to structs
  assign idma_req              = idma_dv.req;
  assign req_valid             = idma_dv.req_valid;
  assign rsp_ready             = idma_dv.rsp_ready;
  assign idma_eh_req           = idma_dv.eh_req;
  assign eh_req_valid          = idma_dv.eh_req_valid;
  // connect struct to virtual driver interface
  assign idma_dv.req_ready     = req_ready;
  assign idma_dv.rsp           = idma_rsp;
  assign idma_dv.rsp_valid     = rsp_valid;
  assign idma_dv.eh_req_ready  = eh_req_ready;

  //--------------------------------------
  // DMA Job Queue
  //--------------------------------------
  // job type definition
  typedef idma_test::idma_job #(
      .AddrWidth   ( AddrWidth )
  ) tb_dma_job_t;

  // request and response queues
  tb_dma_job_t req_jobs [$];
  tb_dma_job_t rsp_jobs [$];

  // `include "include/tb_tasks.svh" //: instead: content of that file pasted here
  // this fixes issue that it reads idma/test/include/tb_tasks.svh instead of the one in the same directory
  // -> in that other file, almost exactly the same functions exist, plus some that need a model to be defined

////////////////////////////////////////
// START OF TB_TASKS.SVH /////////////////
////////////////////////////////////////

  task automatic read_jobs (
    input string       filename,
    ref   tb_dma_job_t jobs [$]
  );

    // job file
    integer job_file;

    // parsed fields
    int unsigned            num_errors;
    string                  is_read, error_handling;
    addr_t                  err_addr;
    tb_dma_job_t            now;
    idma_pkg::idma_eh_req_t eh;

    // open file
    job_file = $fopen(filename, "r");

    // check if file exist
    if (job_file == 0)
        $fatal(1, "File not found!");

    // until not end of file
    while (! $feof(job_file)) begin
        now = new();
        void'($fscanf(job_file, "%d\n", now.length));
        void'($fscanf(job_file, "0x%x\n", now.src_addr));
        void'($fscanf(job_file, "0x%x\n", now.dst_addr));
        void'($fscanf(job_file, "%d\n", now.src_protocol));
        void'($fscanf(job_file, "%d\n", now.dst_protocol));
        void'($fscanf(job_file, "%d\n", now.max_src_len));
        void'($fscanf(job_file, "%d\n", now.max_dst_len));
        void'($fscanf(job_file, "%b\n", now.aw_decoupled));
        void'($fscanf(job_file, "%b\n", now.rw_decoupled));
        if (now.IsND) begin
            for (int d = 0; d < now.NumDim-1; d++) begin
                void'($fscanf(job_file, "%d\n", now.n_dims[d].reps));
                void'($fscanf(job_file, "0x%x\n", now.n_dims[d].src_strides));
                void'($fscanf(job_file, "0x%x\n", now.n_dims[d].dst_strides));
            end
        end
        void'($fscanf(job_file, "%d\n", num_errors));
        for (int i = 0; i < num_errors; i++) begin
            void'($fscanf(job_file, "%c%c0x%h\n", is_read, error_handling, err_addr));
            // parse error handling option
            eh = '0;
            case (error_handling)
                "c" : eh = idma_pkg::CONTINUE;
                "a" : eh = idma_pkg::ABORT;
                default:;
            endcase
            now.err_action.push_back(eh);

            // parse read flag
            if (is_read == "r") begin
                now.err_is_read.push_back(1);
            end else begin
                now.err_is_read.push_back(0);
            end

            // error address
            now.err_addr.push_back(err_addr);
        end
        if (now.length == 0) continue;
        jobs.push_back(now);
    end

    // close job file
    $fclose(job_file);

  endtask

  // print a job summary (# jobs and total length)
  task automatic print_summary (
    ref   tb_dma_job_t jobs [$]
  );
    int unsigned data_size;
    int unsigned num_transfers;
    data_size     = '0;
    num_transfers = jobs.size();
    // go through queue
    for (int i = 0; i < num_transfers; i++) begin
        data_size = data_size + jobs[i].length;
    end
    $display("[DMA%0d] Launching %d jobs copying a total of %d B (%d kiB - %d MiB)",
                JobId + 1,
                num_transfers,
                data_size,
                data_size / 1024,
                data_size / 1024 / 1024
            );
  endtask

  ////////////////////////////////////////
  // END OF TB_TASKS.SVH /////////////////
  ////////////////////////////////////////


  //--------------------------------------
    // Read Job queue from File
    //--------------------------------------
  initial begin
    string job_file, job_name, job_dir;
    if ($value$plusargs ("JOB_NAME=%s", job_name)) begin
      job_name = $sformatf("%s", job_name);
    end else begin
      job_name = "single_tf";
    end
    if ($value$plusargs("JOB_DIR=%s", job_dir)) begin
      job_dir = $sformatf("%s", job_dir);
    end else begin
      job_dir = "hw/test/jobs";
    end
    if (JobId != -1) begin
      job_file = $sformatf("%s/%s_%0d.txt", job_dir, job_name, JobId);
    end else begin
      job_file = $sformatf("%s/%s.txt", job_dir, job_name);
    end
    $display("[DMA%0d] Reading from %s", JobId + 1, job_file);
    read_jobs(job_file, req_jobs);
    read_jobs(job_file, rsp_jobs);
  end

  //--------------------------------------
  // Launch Transfers
  //--------------------------------------

  logic                error;
  logic                last;
  idma_pkg::err_type_t err_type;
  axi_pkg::resp_t      cause;
  addr_t               burst_addr;
  int                  err_idx [$];

  initial begin
    // reset driver
    drv.reset_driver();
    // wait until reset has completed
    wait (rst_ni);
    // print a job summary
    print_summary(req_jobs);
    // wait some additional time
    #100ns;

    // run all requests in queue
    while (req_jobs.size() != 0) begin
        // pop front to get a job
        automatic tb_dma_job_t now = req_jobs.pop_front();
        // print job to terminal
        if (EnableDebug) $display("[DMA%0d]%s", JobId + 1, now.pprint());
        // launch DUT
        drv.launch_tf(
                      now.length,
                      now.src_addr,
                      now.dst_addr,
                      now.src_protocol,
                      now.dst_protocol,
                      now.aw_decoupled,
                      now.rw_decoupled,
                      $clog2(now.max_src_len),
                      $clog2(now.max_dst_len),
                      now.max_src_len != 'd256,
                      now.max_dst_len != 'd256,
                      now.id
                    );
    end
    // once done: launched all transfers
    $display("[DMA%0d] Launched all Transfers.", JobId + 1);

end

initial begin
  end_of_sim_o = 1'b0;
  // wait until reset has completed
  wait (rst_ni);
  // run all requests in queue
  while (rsp_jobs.size() != 0) begin
      // pop front to get a job
      automatic tb_dma_job_t now = rsp_jobs.pop_front();
      // launch DUT
      drv.wait_tf(cause, err_type, burst_addr, error, last);
      if (error) begin
        $display("[DMA%0d] Error: %s", JobId + 1, idma_pkg::err_type_t'(err_type));
        $display("[DMA%0d] Cause: %s", JobId + 1, axi_pkg::resp_t'(cause));
        $display("[DMA%0d] Burst Address: 0x%0h", JobId + 1, burst_addr);
      end
  end
  // wait for some time
  #100ns;
  // stop simulation
  end_of_sim_o = 1'b1;
end


endmodule
