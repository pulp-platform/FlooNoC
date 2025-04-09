// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>

`include "floo_noc/typedef.svh"

  // TODO MICHAERO: gen stimuli
  //   - for each input VC generate packets of flits in a queue with random destination Ports (IDs), excluding the source port
  //   - collect these packets for each destination port (ID) and VC
  //   - for each output VC collect all incoming packets of flits
  //   - match the collected flits to ensure all packets are routed to their intended destination without errors or injected/missing flits


module tb_floo_router;

  import floo_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  task automatic cycle_start();
    #ApplTime;
  endtask : cycle_start

  task automatic cycle_end();
    #TestTime;
  endtask : cycle_end

  task automatic started_cycle_end();
    #(TestTime-ApplTime);
  endtask : started_cycle_end

  localparam int unsigned NumTestPacketsPerChannel = 100;

  localparam int unsigned NumPorts = 5;
  localparam int unsigned NumVirtChannels = 6;
  localparam int unsigned IdWidth = $clog2(NumPorts);
  localparam int unsigned FlitWidth = 123;
  localparam int unsigned MaxPacketLength = 32;

  typedef logic [FlitWidth-1:0] payload_t;
  typedef logic [IdWidth-1:0] id_t;

  `FLOO_TYPEDEF_MASK_HDR_T(hdr_t, id_t, id_t, id_t, logic, logic, floo_pkg::collect_comm_e)
  `FLOO_TYPEDEF_GENERIC_FLIT_T(req, hdr_t, payload_t)

  logic clk, rst_n;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );


  /************************
   *  Stimuli generation  *
   ************************/

  class rand_data_t;
    bit [IdWidth-1:0] id;
    rand logic [FlitWidth-1:0] data;

    function new (bit [IdWidth-1:0] in_id);
      this.id = in_id;
    endfunction

    constraint data_mod_id_c {
      data % NumPorts == id;
    }
  endclass

  class stimuli_t;
    bit [IdWidth-1:0]        source;
    rand int                 len;
    rand bit [IdWidth-1:0]   id;

    function new (bit [IdWidth-1:0] in_source);
      this.source = in_source;
    endfunction

    constraint id_in_range_c {
      id < NumPorts;
      id != source;
    }

    constraint len_is_reasonable_c {
      len <= 32;
      len > 0;
    }

  endclass

  //                         Source Port   Virtual Channel
  floo_req_generic_flit_t  stimuli_queue[NumPorts][NumVirtChannels][$];

  //                         Destination   Virtual Channel      Source Port
  floo_req_generic_flit_t  golden_queue [NumPorts][NumVirtChannels][NumPorts][$];

  function automatic void generate_stimuli();
    for (int port = 0; port < NumPorts; port++) begin
      for (int virt_channel = 0; virt_channel < NumVirtChannels; virt_channel++) begin
        // TODO MICHAERO: ensure each output gets at least one packet from input for testbench termination

        for (int i = 0; i < NumTestPacketsPerChannel; i++) begin
          automatic stimuli_t stimuli = new(port);

          // Active Constraints
          stimuli.id_in_range_c.constraint_mode(1);
          stimuli.len_is_reasonable_c.constraint_mode(1);

          // Randomize
          if (stimuli.randomize()) begin
            for (int j = 0; j < stimuli.len; j++) begin
              automatic rand_data_t rand_data = new(port);
              rand_data.data_mod_id_c.constraint_mode(1);
              if (rand_data.randomize()) begin
                automatic floo_req_generic_flit_t next_flit = '0;
                next_flit.payload = rand_data.data;
                next_flit.hdr.src_id = port;
                next_flit.hdr.dst_id = stimuli.id;
                next_flit.hdr.last = j == stimuli.len-1;

                stimuli_queue[port][virt_channel].push_back(next_flit);
                golden_queue[port][virt_channel][stimuli.id].push_back(next_flit);

                // $display("%x from: %d to: %d vc: %d, last: %d",next_flit.data, port, next_flit.id, virt_channel, next_flit.last);
              end else begin
                $error("Could not randomize.");
              end
            end
          end else begin
            $error("Could not randomize.");
          end
        end
      end
    end
  endfunction

  // Apply Stimuli

  logic       [NumPorts-1:0][NumVirtChannels-1:0] pre_valid_in, pre_ready_in;
  floo_req_generic_flit_t [NumPorts-1:0][NumVirtChannels-1:0] pre_data_in;

  task automatic apply_stimuli(int unsigned port, int unsigned virt_channel);
    automatic floo_req_generic_flit_t stimuli;

    // pre_valid_in[port][virt_channel] = 1'b0;

    wait (stimuli_queue[port][virt_channel].size() != '0);
    fork
      begin : apply_valid_data
        stimuli = stimuli_queue[port][virt_channel].pop_front();
        pre_data_in[port][virt_channel] = stimuli;
        pre_valid_in[port][virt_channel] = 1'b1;
      end
      begin
        started_cycle_end();
        while (!pre_ready_in[port][virt_channel]) begin
          @(posedge clk)
          cycle_end();
        end
      end
    join
    @(posedge clk)
    cycle_start();
    pre_valid_in[port][virt_channel] = 1'b0;

  endtask

  /***********************
   *  Device Under Test  *
   ***********************/

  logic       [NumPorts-1:0][NumVirtChannels-1:0] delayed_valid_in;
  logic       [NumPorts-1:0][NumVirtChannels-1:0] delayed_ready_in;
  floo_req_generic_flit_t [NumPorts-1:0][NumVirtChannels-1:0] delayed_data_in;

  for (genvar port = 0; port < NumPorts; port++) begin : gen_in_delay
    for (genvar vc = 0; vc < NumVirtChannels; vc++) begin : gen_in_vc_delay
      stream_delay #(
        .StallRandom ( 1'b1        ),
        .FixedDelay  ( 1           ),
        .payload_t   ( floo_req_generic_flit_t ),
        .Seed        ( '0          )
      ) i_in_delay (
        .clk_i    (clk),
        .rst_ni   (rst_n),

        .payload_i( pre_data_in [port][vc] ),
        .ready_o  ( pre_ready_in[port][vc] ),
        .valid_i  ( pre_valid_in[port][vc] ),

        .payload_o( delayed_data_in [port][vc] ),
        .ready_i  ( delayed_ready_in[port][vc] ),
        .valid_o  ( delayed_valid_in[port][vc] )
      );
    end
  end

  logic       [NumPorts-1:0][NumVirtChannels-1:0] valid_in, valid_out;
  logic       [NumPorts-1:0][NumVirtChannels-1:0] ready_in, ready_out;
  floo_req_generic_flit_t [NumPorts-1:0]                      data_in,  data_out;

  for (genvar port = 0; port < NumPorts; port++) begin : gen_in_vc_arb
    floo_vc_arbiter #(
      .NumVirtChannels ( NumVirtChannels ),
      .flit_t          ( floo_req_generic_flit_t )
    ) i_vc_arbiter (
      .clk_i   ( clk   ),
      .rst_ni  ( rst_n ),

      .valid_i ( delayed_valid_in[port] ),
      .ready_o ( delayed_ready_in[port] ),
      .data_i  ( delayed_data_in [port] ),

      .valid_o ( valid_in[port] ),
      .ready_i ( ready_in[port] ),
      .data_o  ( data_in [port] )
    );
  end


  floo_router #(
    .NumRoutes        ( NumPorts                ),
    .NumVirtChannels  ( NumVirtChannels         ),
    .flit_t           ( floo_req_generic_flit_t ),
    .InFifoDepth      ( 4                       ),
    .RouteAlgo        ( SourceRouting           ),
    .IdWidth          ( IdWidth                 )
  ) i_dut (
    .clk_i         ( clk   ),
    .rst_ni        ( rst_n ),
    .test_enable_i ( '0 ),

    .xy_id_i       ( '0 ), // Unused for `SourceRouting`
    .id_route_map_i( '0 ), // Unused for `SourceRouting`

    .valid_i       ( valid_in  ),
    .ready_o       ( ready_in  ),
    .data_i        ( data_in   ),

    .valid_o       ( valid_out ),
    .ready_i       ( ready_out ),
    .data_o        ( data_out  )
  );

  logic       [NumPorts-1:0][NumVirtChannels-1:0] fall_valid_out;
  logic       [NumPorts-1:0][NumVirtChannels-1:0] fall_ready_out;
  floo_req_generic_flit_t [NumPorts-1:0][NumVirtChannels-1:0] fall_data_out;
  logic       [NumPorts-1:0][NumVirtChannels-1:0] delayed_valid_out;
  logic       [NumPorts-1:0][NumVirtChannels-1:0] delayed_ready_out;
  floo_req_generic_flit_t [NumPorts-1:0][NumVirtChannels-1:0] delayed_data_out;

  for (genvar port = 0; port < NumPorts; port++) begin : gen_out_delay
    for (genvar vc = 0; vc < NumVirtChannels; vc++) begin : gen_out_vc_delay

      fall_through_register #(
        .T ( floo_req_generic_flit_t )
      ) i_fall (
        .clk_i     (clk),
        .rst_ni    (rst_n),
        .clr_i     (1'b0),
        .testmode_i(1'b0),

        .valid_i   ( valid_out     [port][vc] ),
        .ready_o   ( ready_out     [port][vc] ),
        .data_i    ( data_out      [port] ),

        .valid_o   ( fall_valid_out[port][vc] ),
        .ready_i   ( fall_ready_out[port][vc] ),
        .data_o    ( fall_data_out [port][vc] )
      );

      stream_delay #(
        .StallRandom ( 1'b1        ),
        .FixedDelay  ( 1           ),
        .payload_t   ( floo_req_generic_flit_t ),
        .Seed        ( '0          )
      ) i_in_delay (
        .clk_i    (clk),
        .rst_ni   (rst_n),

        .payload_i( fall_data_out [port][vc] ),
        .ready_o  ( fall_ready_out[port][vc] ),
        .valid_i  ( fall_valid_out[port][vc] ),

        .payload_o( delayed_data_out [port][vc] ),
        .ready_i  ( delayed_ready_out[port][vc] ),
        .valid_o  ( delayed_valid_out[port][vc] )
      );
    end
  end

  /***********************
   *  Output collection  *
   ***********************/

  //                       Destination   Virtual Channel
  floo_req_generic_flit_t result_queue[NumPorts][NumVirtChannels][$];

  task automatic collect_result(int unsigned port, int unsigned virt_channel);

    fork
      begin
        delayed_ready_out[port][virt_channel] = 1'b1;
      end
      begin
        started_cycle_end();
        if (delayed_valid_out[port][virt_channel]) begin
          result_queue[port][virt_channel].push_back(delayed_data_out[port][virt_channel]);
        end
      end
    join
    @(posedge clk);
    cycle_start();
    delayed_ready_out[port][virt_channel] = 1'b0;

  endtask

  logic [NumPorts-1:0][NumVirtChannels-1:0] check_complete;

  task automatic check_result(int unsigned port, int unsigned virt_channel);
    logic last_active = 1'b0;
    int unsigned last_physical_bin = 0;
    int unsigned all_golden_size = 0;

    automatic floo_req_generic_flit_t result;
    automatic floo_req_generic_flit_t golden;

    do begin
      wait(result_queue[port][virt_channel].size() != 0);

      // Capture the result
      if (result_queue[port][virt_channel].size() == 0) begin
        $error("ERROR! Result queue is empty.");
      end else begin
        result = result_queue[port][virt_channel].pop_front();
      end
      if (golden_queue[result.hdr.src_id][virt_channel][port].size() == 0) begin
        $error("ERROR! Golden queue %d is empty.", result.hdr.src_id);
      end else begin
        golden = golden_queue[result.hdr.src_id][virt_channel][port].pop_front();
      end

      if (result.payload != golden.payload) begin
        $error("ERROR! Mismatch for port %d channel %d (from %d, target port %d)",
               port, virt_channel, result.hdr.src_id, result.hdr.dst_id);
      end

      all_golden_size = 0;
      for (int i = 0; i < NumPorts; i++) begin
        all_golden_size = all_golden_size + golden_queue[i][virt_channel][port].size();
      end
    end while (all_golden_size != 0);

    check_complete[port][virt_channel] = 1'b1;
  endtask

  /****************
   *  Test Bench  *
   ****************/

  task automatic run_apply(int unsigned port, int unsigned virt_channel);
    @(posedge clk);
    cycle_start();
    forever begin
      apply_stimuli(port, virt_channel);
    end
  endtask : run_apply

  task automatic run_collect(int unsigned port, int unsigned virt_channel);
    @(posedge clk);
    cycle_start();
    forever begin
      collect_result(port, virt_channel);
    end
  endtask : run_collect

  initial begin
    // Initialize variables
    pre_valid_in = '0;
    pre_data_in = '0;
    delayed_ready_out = '0;

    check_complete = '0;

    @(posedge rst_n)

    for (int port = 0; port < NumPorts; port++) begin
      automatic int internal_port = port;
      fork
        for (int virt_channel = 0; virt_channel < NumVirtChannels; virt_channel++) begin
          automatic int internal_virt_channel = virt_channel;
          fork
            run_apply(internal_port, internal_virt_channel);
            run_collect(internal_port, internal_virt_channel);
            check_result(internal_port, internal_virt_channel);
          join_none
        end
      join_none
    end
    generate_stimuli();
    while(check_complete != {NumPorts{{NumVirtChannels{1'b1}}}} ) begin
      @(posedge clk);
    end
    $finish(0);

  end

endmodule
