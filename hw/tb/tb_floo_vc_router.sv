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

int automatically_free_credits;

flit_t flit;
flit_t random_flit;
int next_in_port;

flit_t result;
flit_t exp_result;


id_t xy_id = '{x: 3'd2, y: 3'd2, port_id: 2'd0};
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
task automatic collect_all_results();
  @(posedge clk);
  #TestTime;
  for (int port=0; port<NumPorts; port++) begin
    if (data_v_o[port]) begin
      result_queue[port].push_back(data_o[port]);
      if(automatically_free_credits) begin
        free_credit_async(port, data_o[port].hdr.vc_id);
      end
    end
  end
endtask

// apply inputs of all ports during next cycle
task automatic apply_all_inputs();
  @(posedge clk);
  #ApplTime;
  for (int port=0; port<NumPorts; port++) begin
    if (input_queue[port].size() != 0) begin
      $display("Applying input on port %0d", port);
      data_i[port] = input_queue[port].pop_front();
      data_v_i[port] = 1'b1;
    end
  end
  fork begin
    @(posedge clk)
    #ApplTime;
    for (int port=0; port<NumPorts; port++) begin
      if (input_queue[port].size() == 0)
        data_v_i[port] = 1'b0;
    end
  end join_none
endtask

// send free credit msg (async)
task automatic free_credit_async(int unsigned port, int unsigned vc_id);
  fork
    begin
      @(posedge clk);
      #ApplTime;
      credit_v_i[port] = 1'b1;
      credit_id_i[port] = vc_id[NumVCWidth-1:0];
      @(posedge clk);
      #ApplTime;
      credit_v_i[port] = '0;
      credit_id_i[port] = '0;
    end
  join_none
endtask

// set vc_id to the preferred vc: in, out port are of receiving (next) router
task automatic get_preferred_vc(int unsigned in_port,
    int unsigned out_port, output logic[NumVCWidth-1:0] vc_id);
  if(in_port==out_port||((out_port==East||out_port==West)&&(in_port==North||in_port==South)))
    $fatal(1, "in_port = %0d to %0d = out_port is impossible in xy routing", in_port, out_port);
  vc_id = (NumVCWidth)'((in_port >= Eject || in_port == East || in_port == West) ?
                        (out_port < in_port ? out_port : out_port - 1) :
              (out_port >= Eject ? out_port - 3 : 0));
endtask

//randomize payload and src_id and axi, rob fields
task automatic randomize_flit();
  if(!std::randomize(random_flit))
    $fatal(1,"Was not able to randomize flit");
  flit.rsvd = random_flit.rsvd;
  flit.hdr.src_id =random_flit.hdr.src_id;
  flit.hdr.atop = random_flit.hdr.atop;
  flit.hdr.axi_ch = random_flit.hdr.axi_ch;
  flit.hdr.rob_idx = random_flit.hdr.rob_idx;
  flit.hdr.rob_req = random_flit.hdr.rob_req;
endtask

task automatic test_connection(int unsigned in_port, int unsigned out_port);
/*
test if all input vc are able to connect to out port and send free credit messages
test if lookahead is set correctly
test if vc is set correctly:
  if space, in correct, if no space, in other, if no other, dont send (yet)
*/
if(in_port==out_port||((in_port==East||in_port==West)&&(out_port==North||out_port==South)))
    $fatal(1, "in_port = %0d to %0d = out_port is impossible in xy routing", in_port, out_port);
flit = '0;
flit.hdr.last = 1'b1;
flit.hdr.lookahead = route_direction_e'(out_port);
next_in_port = (out_port + 2) % 4; // out-> next_in: 0->2, 1->3, 2->0, 3->1

//input
randomize_flit();
flit.hdr.dst_id = '{x: 3'd2, y: 3'd1, port_id: 2'd0}; //should arrive with lookahead = Eject
flit.hdr.vc_id = '0;
input_queue[in_port].push_back(flit);
//expected output:
flit.hdr.lookahead = Eject;
get_preferred_vc(next_in_port, 4, flit.hdr.vc_id);
expected_result_queue[out_port].push_back(flit);

randomize_flit();
flit.hdr.dst_id = '{x: 3'd2, y: 3'd0, port_id: 2'd0}; //should arrive with lookahead = South
flit.hdr.lookahead = route_direction_e'(out_port);
flit.hdr.vc_id = 2'b1;
input_queue[in_port].push_back(flit);
get_preferred_vc(next_in_port, 2, flit.hdr.vc_id);
expected_result_queue[out_port].push_back(flit);

for(int t = 1; t < 10; t++) begin
  @(posedge clk);
  $display("t = %0d: ", t);
  for(int port = 0; port < NumPorts; port++) begin
      if(result_queue[port].size() != 0) begin
        $display("Got Something on port %0d", port);
        result = result_queue[port].pop_front();
        if(expected_result_queue[port].size() == 0) begin
          $error("Didnt expect anything here");
          $display("Unexpected flit hdr: %p", result.hdr);
        end else begin
          exp_result = expected_result_queue[port].pop_front();
          if(exp_result != result) begin
            $error("Results dont match");
            $display(exp_result.rsvd == result.rsvd ? "Data was correct": "Data was incorrect");
            if(exp_result.hdr != result.hdr) begin
              $display("Expected hdr: %p", exp_result.hdr);
              $display("Result hdr  : %p", result.hdr);
            end else $display("Hdr were correct");
          end else $display("Got correct result!");
        end
      end
  end
  $display(" ");
end
for(int port = 0; port < NumPorts; port++) begin
  if(expected_result_queue[port].size() != 0) begin
    $display("Port %0d was still expecting results:", port);
    for(; 0 < expected_result_queue[port].size();) begin
      exp_result = expected_result_queue[port].pop_front();
      $display("Expected hdr: %p", exp_result.hdr);
    end
  end
end


endtask

task automatic test_wormhole();
/* for each output dir:
start wormhole from any input dir,
then send packets to that output dir from all other input dirs
  -> no packet should be sent
then send packet (still not last) -> should get through
then send last packet, then all should get through
  -> ignore content at that point, that is tested in other test
*/

endtask



// "main"

initial begin : main_test_bench
@(posedge rst_n)
// initialize variables
credit_v_i ='0;
credit_id_i ='0;
automatically_free_credits = 1;
fork : start_send_and_recieve_threads
  begin
    forever begin
      apply_all_inputs();
    end
  end begin
    forever begin
      collect_all_results();
    end
  end
join_none

test_connection(0, 2); //North to South

$finish;

end : main_test_bench


endmodule
