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
localparam type credit_id_t = logic[NumVCWidth-1:0];
credit_id_t received_credits_queue [NumPorts][$];
credit_id_t expected_credits_queue [NumPorts][$];
credit_id_t free_credits_queue [NumPorts][$];


int automatically_free_credits;

flit_t flit;
flit_t random_flit;
int any_credit_v, any_output_v;

flit_t result;
flit_t exp_result;
credit_id_t result_credit;
credit_id_t exp_credit;


id_t xy_id = '{x: 3'd2, y: 3'd2, port_id: 2'd0};
logic [NumPorts-1:0] credit_v_o;
assign any_credit_v = |credit_v_o;
logic [NumPorts-1:0][NumVCWidth-1:0] credit_id_o;
logic [NumPorts-1:0] data_v_i;
flit_t [NumPorts-1:0] data_i;
logic [NumPorts-1:0] credit_v_i;
logic [NumPorts-1:0][NumVCWidth-1:0] credit_id_i;
logic [NumPorts-1:0] data_v_o;
assign any_output_v = |data_v_o;
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
      if(automatically_free_credits)
        free_credits_queue[port].push_back(data_o[port].hdr.vc_id);
    end
    if (credit_v_o[port])
      received_credits_queue[port].push_back(credit_id_o[port]);
  end
  if(any_credit_v != any_output_v)
    $error("A output was valid but no credit was freed");
endtask

// send available free credit msg
task automatic free_credits();
    @(posedge clk);
    #ApplTime;
    for (int port=0; port<NumPorts; port++) begin
      if(free_credits_queue[port].size() > 0) begin
        credit_v_i[port] = 1'b1;
        credit_id_i[port] = free_credits_queue[port].pop_front();
      end else begin
        credit_v_i[port] = '0;
      end
    end
endtask

task automatic check_received_results(int unsigned num_cycles);
  for(int t = 1; t < num_cycles; t++) begin
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
endtask

task automatic check_received_credits();
  for(int port = 0; port < NumPorts; port++) begin
      while(received_credits_queue[port].size() != 0) begin
        result_credit = received_credits_queue[port].pop_front();
        if(expected_credits_queue[port].size() == 0) begin
          $error("On port %0d: got credit %0d but did not expect one",
                port, result_credit);
        end else begin
          exp_credit = expected_credits_queue[port].pop_front();
          if(exp_credit != result_credit) begin
            $error("On port %0d: got credit %0d, but expected %0d",
                port, result_credit, exp_credit);
          end else
            $display("On port %0d: got correct credit", port);
        end
      end
      while(expected_credits_queue[port].size() != 0) begin
        $error("On port %0d: did not receive credit %0d",
                port, expected_credits_queue[port].pop_front());
      end
  end
  $display(" ");
endtask


task automatic check_exp_queue_empty();
  for(int port = 0; port < NumPorts; port++) begin
    if(expected_result_queue[port].size() != 0) begin
      $error("Port %0d was still expecting results:", port);
      for(; 0 < expected_result_queue[port].size();) begin
        exp_result = expected_result_queue[port].pop_front();
        $display("Expected hdr: %p", exp_result.hdr);
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

// set vc_id to the preferred vc: in, out port are of receiving (next) router
task automatic get_preferred_vc(int unsigned in_port,
  int unsigned out_port, output logic[NumVCWidth-1:0] vc_id);
if(in_port==out_port||((out_port==East||out_port==West)&&(in_port==North||in_port==South)))
  $fatal(1, "in_port = %0d to %0d = out_port is impossible in xy routing", in_port, out_port);
vc_id = (NumVCWidth)'((in_port >= Eject || in_port == East || in_port == West) ?
                      (out_port < in_port ? out_port : out_port - 1) :
            (out_port >= Eject ? out_port - 3 : 0));
endtask

//return required lookahead if wanting the router to set a specific out vc
task automatic get_direction_from_vc(int unsigned next_in_port, vc_id_t vc_id,
                              output route_direction_e direction);
  if(next_in_port == North || next_in_port == South)
    direction = vc_id == 0 ? route_direction_e'((next_in_port + 2) % 4) : Eject;
  else if(next_in_port >= Eject)
    direction = route_direction_e'(next_in_port);
  else
    direction = route_direction_e'(vc_id >= next_in_port ? vc_id + 1 : vc_id);
endtask

task automatic get_dst_id(route_direction_e direction, route_direction_e lookahead,
                  output id_t dst_id);
  //expect router_id to be '{x: 3'd2, y: 3'd2, port_id: 2'd0}
  case (direction)
    North: begin
      if(lookahead == North) dst_id = '{x: 3'd2, y: 3'd4, port_id: 2'd0};
      else dst_id = '{x: 3'd2, y: 3'd3, port_id: lookahead - Eject};
    end
    East:
      dst_id = '{x: 3'd3 + (lookahead == East),
      y: 3'd2 + (lookahead == North) - (lookahead == South),
      port_id: lookahead >= Eject ? lookahead - Eject : 2'd0};
    South:
      if(lookahead == South) dst_id = '{x: 3'd2, y: 3'd0, port_id: 2'd0};
      else dst_id = '{x: 3'd2, y: 3'd1, port_id: lookahead - Eject};
    West:
      dst_id = '{x: 3'd1 - (lookahead == West),
      y: 3'd2 + (lookahead == North) - (lookahead == South),
      port_id: lookahead >= Eject ? lookahead - Eject : 2'd0};
    default: //Eject
      dst_id = '{x: 3'd2, y: 3'd2, port_id: direction - Eject};
  endcase
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

int next_in_port, num_vc_in, num_vc_out;
route_direction_e expected_lookahead;

task automatic test_connection(int unsigned in_port, int unsigned out_port);
/*
test if all input vc are able to connect to out port and send free credit messages
test if lookahead is set correctly
test if vc is set correctly:
  if space, in correct, if no space, in other, if no other, dont send (yet)
*/
if(in_port==out_port||((in_port==North||in_port==South)&&(out_port==East||out_port==West)))
    $fatal(1, "in_port = %0d to %0d = out_port is impossible in xy routing", in_port, out_port);
flit = '0;
flit.hdr.last = 1'b1;
num_vc_in = (in_port == North || in_port == South) ? 2 : 4;
next_in_port = out_port >= Eject ? out_port : (out_port + 2) % 4; // out->n_in:0->2,1->3,2->0,3->1
num_vc_out = (next_in_port == North || next_in_port == South) ? 2 :
              next_in_port >= Eject ? 1 : 4;
// Explanation for batching: sending more than 2 directly consecutive messages to the same vc does not work due to buffer size
for(vc_id_t vc_out_batch = 0; vc_out_batch < num_vc_out; vc_out_batch += 2) begin
  for(vc_id_t vc_in = 0; vc_in < num_vc_in; vc_in ++) begin
    for(vc_id_t vc_out = vc_out_batch; vc_out < vc_out_batch+2 && vc_out<num_vc_out; vc_out++) begin
      get_direction_from_vc(next_in_port, vc_out, expected_lookahead);
      //input
      randomize_flit();
      flit.hdr.lookahead = route_direction_e'(out_port);
      get_dst_id(route_direction_e'(out_port), expected_lookahead, flit.hdr.dst_id);
      $display("%0d:%0d->%0d:%0d, expected_lookahead: %p, dst_id: %p",
        in_port, vc_in, out_port, vc_out, expected_lookahead, flit.hdr.dst_id);
      flit.hdr.vc_id = vc_in;
      input_queue[in_port].push_back(flit);
      expected_credits_queue[in_port].push_back(vc_in);
      //expected output:
      flit.hdr.lookahead = expected_lookahead;
      flit.hdr.vc_id = vc_out;
      expected_result_queue[out_port].push_back(flit);
    end
  end
end

check_received_results(num_vc_in * num_vc_out + 4);
check_received_credits();
check_exp_queue_empty();

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
  forever
      apply_all_inputs();
  forever
      collect_all_results();
  forever
      free_credits();
join_none

for(int in_port = 0; in_port < NumPorts; in_port++)
  for(int out_port = 0; out_port < NumPorts; out_port++)
    if(in_port!=out_port && !((in_port==North||in_port==South)&&(out_port==East||out_port==West)))
      test_connection(in_port, out_port);


$finish;

end : main_test_bench


endmodule
