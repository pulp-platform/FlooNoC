// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Lukas Berner <bernerl@student.ethz.ch>

/*test ideas:
1) connectivity from each input vs to each output vc, lookahead is set correctly on output
2) FVADA working correctly: forward to different vc if prioritized one is not free -> lookahead still set correctly
3) dont send if all buffers full


*/

`include "floo_noc/typedef.svh"



module tb_floo_vc_router;

import floo_pkg::*;
import floo_axi_pkg::*;

localparam time CyclTime = 10ns;
localparam time ApplTime = 2ns;
localparam time TestTime = 8ns;

localparam type          flit_t                       = floo_req_generic_flit_t;
localparam int           HdrLength                    = $bits(hdr_t);
localparam int           DataLength                   = $bits(flit_t) - HdrLength;
localparam type          flit_payload_t               = logic[DataLength-1:0];
localparam int           NumVCWidth                   = 2;
localparam int           NumPorts                     = 5;

logic clk, rst_n;

clk_rst_gen #(
  .ClkPeriod    ( CyclTime ),
  .RstClkCycles ( 5        )
) i_clk_gen (
  .clk_o  ( clk   ),
  .rst_no ( rst_n )
);

flit_t input_queue  [NumPorts][$];
flit_t result_queue [NumPorts][$];
flit_t expected_result_queue [NumPorts][$];



id_t xy_id = '{x: 3'd1, y: 3'd1, port_id: 2'd0};
logic [NumPorts-1:0] credit_v_o;
logic [NumPorts-1:0][NumVCWidth-1:0] credit_id_o;
logic [NumPorts-1:0] data_v_i;
flit_t [NumPorts-1:0] data_i;
logic [NumPorts-1:0] credit_v_i;
logic [NumPorts-1:0][NumVCWidth-1:0] credit_id_i;
logic [NumPorts-1:0] data_v_o;
flit_t [NumPorts-1:0] data_o;

// DUT
floo_vc_router #(
  .NumPorts           (NumPorts),
  .NumVCWidth         (NumVCWidth),
  .RouteAlgo          (XYRouting),
  .flit_t             (flit_t),
  .hdr_t              (hdr_t),
  .flit_payload_t     (flit_payload_t),
  .id_t               (id_t)
) i_floo_vc_router (
  .clk_i              (clk),
  .rst_ni             (rst_n),
  .xy_id_i            (xy_id),
  .id_route_map_i     ('0),
  // contents from input port
  .credit_v_o         (credit_v_o),
  .credit_id_o        (credit_id_o),
  .data_v_i           (data_v_i),
  .data_i             (data_i),
  // contents from output port
  .credit_v_i         (credit_v_i),
  .credit_id_i        (credit_id_i),
  .data_v_o           (data_v_o),
  .data_o             (data_o)
);


// collects outputs of router on all ports
task static collect_all_results();
  @(posedge clk);
  #TestTime;
  for (int port=0; port<NumPorts; port++) begin
    if (data_v_o[port]) begin
      result_queue[port].push_back(data_o[port]);
    end
end
endtask

// apply inputs of all ports during next cycle
task static apply_all_inputs();
  @(negedge clk);
  #ApplTime;
  for (int port=0; port<NumPorts; port++) begin
    if (input_queue[port].size() != '0) begin
      data_i[port] = input_queue[port].pop_front();
      data_v_i[port] = 1'b1;
    end
  end

  @(posedge clk)
  #ApplTime;
  for (int port=0; port<NumPorts; port++) begin
    data_v_i[port] = 1'b0;
  end
endtask


/****************
 *  Test Bench  *
 ****************/

flit_payload_t  payload;
hdr_t           hdr;
flit_t          flit;

flit_t result;
flit_t exp_result;



initial begin : main_test_bench
@(posedge rst_n)
hdr = '0;
hdr.src_id = '1;
hdr.lookahead = South;
hdr.dst_id = '{x: 3'd1, y: 3'd0, port_id: 2'd0}; //should arrive with lookahead = Eject
hdr.vc_id = '0;
hdr.last = 1'b1;
payload.randomize();


flit = '{hdr, payload};
input_queue[0].push_back(flit);
flit.hdr.lookahead = Eject;
flit.hdr.vc_id = 2'd3;
expected_result_queue[2].push_back(flit); //expect output towards south


for(int t = 1; t < 6; t++) begin
  collect_all_results();
  $display("t = %d: ", t);
  for(int port = 0; port < NumPorts; port++) begin
      $display("Port: %d:", port);
      if(result_queue[port].size() == 0) begin
        $display("Still empty");
      end else begin
        $display("Got Something!!");
        if(expected_result_queue[port].size() == 0)
          $error("Didnt expect anything here");
        else begin
          exp_result = expected_result_queue[port].pop_front();
          result = result_queue[port].pop_front();
          if(exp_result != result)
            $error("Results dont match");

        end
      end
  end
  $display(" ");
end


$stop;

end : main_test_bench






endmodule
