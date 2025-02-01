// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

/// A AXI4 Bus Monitor for verifying the order of AXI transactions with the same ID
module axi_reorder_compare_multicast #(
  parameter int unsigned NumSlaves = 4,
  parameter int unsigned AxiIdWidth = 4,
  parameter int unsigned NumAddrRegions  = 1,
  parameter type addr_t = logic,
  parameter type rule_t = logic,
  parameter rule_t [NumAddrRegions-1:0] AddrRegions = '0,
  parameter type mask_rule_t = logic,
  parameter rule_t [NumAddrRegions-1:0] MaskAddrRegions = '0,
  parameter bit Verbose = 0,
  parameter type aw_chan_t = logic,
  parameter type w_chan_t = logic,
  parameter type b_chan_t = logic,
  parameter type ar_chan_t = logic,
  parameter type r_chan_t = logic,
  parameter type req_t = logic,
  parameter type rsp_t = logic,
  // Derived parameters, do not change
  localparam type id_t = logic [AxiIdWidth-1:0],
  localparam int unsigned NumAxiIds = 2**AxiIdWidth
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  req_t mon_mst_req_i,
  input  rsp_t mon_mst_rsp_i,
  input  req_t [NumSlaves-1:0] mon_slv_req_i,
  input  rsp_t [NumSlaves-1:0] mon_slv_rsp_i,
  output logic end_of_sim_o
);

  function automatic void print_aw (
      input aw_chan_t aw_expected,
      input aw_chan_t aw_received
  );
      // verilog_lint: waive-start line-length
      $display("AW      | expected                                                         | received                                                         ");
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      $display("id:     | %64d | %64d", aw_expected.id, aw_received.id);
      $display("addr:   | %64x | %64x", aw_expected.addr, aw_received.addr);
      $display("len:    | %64d | %64d", aw_expected.len, aw_received.len);
      $display("size:   | %64d | %64d", aw_expected.size, aw_received.size);
      $display("burst:  | %64d | %64d", aw_expected.burst, aw_received.burst);
      $display("lock:   | %64d | %64d", aw_expected.lock, aw_received.lock);
      $display("cache:  | %64d | %64d", aw_expected.cache, aw_received.cache);
      $display("prot:   | %64d | %64d", aw_expected.prot, aw_received.prot);
      $display("qos:    | %64d | %64d", aw_expected.qos, aw_received.qos);
      $display("region: | %64d | %64d", aw_expected.region, aw_received.region);
      $display("user:   | %64x | %64x", aw_expected.user, aw_received.user);
      $display("atop:   | %64d | %64d", aw_expected.atop, aw_received.atop);
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      // verilog_lint: waive-stop line-length
  endfunction

  function automatic void print_ar (
      input ar_chan_t ar_expected,
      input ar_chan_t ar_received
  );
      // verilog_lint: waive-start line-length
      $display("AR      | expected                                                         | received                                                         ");
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      $display("id:     | %64d | %64d", ar_expected.id, ar_received.id);
      $display("addr:   | %64x | %64x", ar_expected.addr, ar_received.addr);
      $display("len:    | %64d | %64d", ar_expected.len, ar_received.len);
      $display("size:   | %64d | %64d", ar_expected.size, ar_received.size);
      $display("burst:  | %64d | %64d", ar_expected.burst, ar_received.burst);
      $display("lock:   | %64d | %64d", ar_expected.lock, ar_received.lock);
      $display("cache:  | %64d | %64d", ar_expected.cache, ar_received.cache);
      $display("prot:   | %64d | %64d", ar_expected.prot, ar_received.prot);
      $display("qos:    | %64d | %64d", ar_expected.qos, ar_received.qos);
      $display("region: | %64d | %64d", ar_expected.region, ar_received.region);
      $display("user:   | %64x | %64x", ar_expected.user, ar_received.user);
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      // verilog_lint: waive-stop line-length
  endfunction

  function automatic void print_w (
      input w_chan_t w_expected,
      input w_chan_t w_received
  );
      // verilog_lint: waive-start line-length
      $display("W       | expected                                                         | received                                                         ");
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      $display("data:   | %64x | %64x", w_expected.data, w_received.data);
      $display("strb:   | %64d | %64d", w_expected.strb, w_received.strb);
      $display("last:   | %64d | %64d", w_expected.last, w_received.last);
      $display("user:   | %64x | %64x", w_expected.user, w_received.user);
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      // verilog_lint: waive-stop line-length
  endfunction

  function automatic void print_b (
      input b_chan_t b_expected,
      input b_chan_t b_received
  );
      // verilog_lint: waive-start line-length
      $display("B       | expected                                                         | received                                                         ");
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      $display("id:     | %64d | %64d", b_expected.id, b_received.id);
      $display("resp:   | %64d | %64d", b_expected.resp, b_received.resp);
      $display("user:   | %64x | %64x", b_expected.user, b_received.user);
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      // verilog_lint: waive-stop line-length
  endfunction

  function automatic void print_r (
      input r_chan_t r_expected,
      input r_chan_t r_received
  );
      // verilog_lint: waive-start line-length
      $display("R       | expected                                                         | received                                                         ");
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      $display("id:     | %64d | %64d", r_expected.id, r_received.id);
      $display("data:   | %64x | %64x", r_expected.data, r_received.data);
      $display("resp:   | %64d | %64d", r_expected.resp, r_received.resp);
      $display("last:   | %64d | %64d", r_expected.last, r_received.last);
      $display("user:   | %64x | %64x", r_expected.user, r_received.user);
      $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
      // verilog_lint: waive-stop line-length
  endfunction

  typedef struct packed {
    int unsigned slv_id;
    int unsigned num_rsp;
  } out_rsp_t;

  aw_chan_t aw_queue [NumSlaves][$];
  w_chan_t  w_queue  [NumSlaves][$];
  ar_chan_t ar_queue [NumSlaves][$];
  b_chan_t  b_queue  [NumSlaves][NumAxiIds][$];
  r_chan_t  r_queue  [NumSlaves][NumAxiIds][$];

  out_rsp_t r_out_rsp_queue[NumAxiIds][$];
  out_rsp_t b_out_rsp_queue[NumAxiIds][$];

  id_t aw_id_queue [NumSlaves][$];
  id_t ar_id_queue [NumSlaves][$];

  typedef logic [$clog2(NumSlaves)-1:0] slv_id_t;
  slv_id_t w_slv_idx[$];
  slv_id_t aw_slv_idx, ar_slv_idx;
  logic [NumAddrRegions-1:0] multiaddr_decode_sel;


  addr_decode #(
    .NoIndices  ( NumAddrRegions  ),
    .NoRules    ( NumAddrRegions  ),
    .addr_t     ( addr_t          ),
    .rule_t     ( rule_t          )
  ) i_aw_addr_decode (
    .addr_i           ( mon_mst_req_i.aw.addr ),
    .addr_map_i       ( AddrRegions           ),
    .dec_error_o      (                       ),
    .dec_valid_o      (                       ),
    .default_idx_i    ( '0                    ),
    .en_default_idx_i ( 1'b0                  ),
    .idx_o            ( aw_slv_idx            )
  );

  multiaddr_decode #(
    .NoIndices  ( NumAddrRegions  ),
    .NoRules    ( NumAddrRegions  ),
    .addr_t     ( addr_t          ),
    .rule_t     ( mask_rule_t     )
  ) i_aw_multiaddr_decode (
    .addr_i           ( mon_mst_req_i.aw.addr ),
    .mask_i           ( mon_mst_req_i.aw.user ),
    .addr_map_i       ( MaskAddrRegions       ),
    .select_o         ( multiaddr_decode_sel  ),
    .addr_o           (),
    .mask_o           (),
    .dec_valid_o      (),
    .dec_error_o      (),
    .en_default_idx_i ( '0                    ),
    .default_idx_i    ( '0                    )
  );

  addr_decode #(
    .NoIndices  ( NumAddrRegions  ),
    .NoRules    ( NumAddrRegions  ),
    .addr_t     ( addr_t          ),
    .rule_t     ( rule_t          )
  ) i_ar_addr_decode (
    .addr_i           ( mon_mst_req_i.ar.addr ),
    .addr_map_i       ( AddrRegions           ),
    .dec_error_o      (                       ),
    .dec_valid_o      (                       ),
    .default_idx_i    ( '0                    ),
    .en_default_idx_i ( 1'b0                  ),
    .idx_o            ( ar_slv_idx            )
  );

  always_ff @(posedge clk_i) begin : step_1
    if (mon_mst_req_i.aw_valid && mon_mst_rsp_i.aw_ready) begin
      // for (int i=0; i<w_slv_idx.size(); i++) begin
      //   $display("before new aw issued: w_slv_idx[%0d]=%0d",i,w_slv_idx[i]);
      // end
      if(mon_mst_req_i.aw.user=='0) begin
        aw_queue[aw_slv_idx].push_back(mon_mst_req_i.aw);
        w_slv_idx.push_back(aw_slv_idx);
        b_out_rsp_queue[mon_mst_req_i.aw.id].push_back('{slv_id: aw_slv_idx, num_rsp: 0});
      end else begin
        for (int i = 0; i < $bits(multiaddr_decode_sel); i++) begin
          if (multiaddr_decode_sel[i]==1) begin
            aw_queue[i].push_back(mon_mst_req_i.aw);
            w_slv_idx.push_back(i);
          end
        end
        b_out_rsp_queue[mon_mst_req_i.aw.id].push_back('{slv_id: 0, num_rsp: multiaddr_decode_sel});
      end
      // for (int i=0; i<w_slv_idx.size(); i++) begin
      //   $display("after new aw issued: w_slv_idx[%0d]=%0d",i,w_slv_idx[i]);
      // end
      if (Verbose) $info("Issued AW: id=%0d, len=%0d, route_mask=%0b", mon_mst_req_i.aw.id, mon_mst_req_i.aw.len+1, multiaddr_decode_sel);
    end
    if (mon_mst_req_i.w_valid && mon_mst_rsp_i.w_ready) begin
      // w_queue[w_slv_idx[0]].push_back(mon_mst_req_i.w);
      foreach (w_slv_idx[i]) begin
        w_queue[w_slv_idx[i]].push_back(mon_mst_req_i.w);
        // $display("insert into expected queue %0d:", w_slv_idx[i]);
        // print_w('0,mon_mst_req_i.w);
      end
      if (Verbose) $info("Issued W");
      if (mon_mst_req_i.w.last) begin
        // void'(w_slv_idx.pop_front()); // before: every AW only has 1 single slave so just safely pop front
        w_slv_idx.delete(); // now: need to pop all slaves. TODO: is delete all correct?
      end
    end
    if (mon_mst_req_i.ar_valid && mon_mst_rsp_i.ar_ready) begin
      ar_queue[ar_slv_idx].push_back(mon_mst_req_i.ar);
      r_out_rsp_queue[mon_mst_req_i.ar.id].push_back(
        '{slv_id: ar_slv_idx, num_rsp: mon_mst_req_i.ar.len});
      if (Verbose) $info("Issued AR: id=%0d, len=%0d, route_dir=%0d",
                         mon_mst_req_i.ar.id, mon_mst_req_i.ar.len+1, ar_slv_idx);
    end
  end

  // verilog_lint: waive-start always-ff-non-blocking
  for (genvar i = 0; i < NumSlaves; i++) begin : gen_slv_step_2
    always_ff @(posedge clk_i) begin : step_2
      if (mon_slv_req_i[i].aw_valid && mon_slv_rsp_i[i].aw_ready) begin
        automatic aw_chan_t aw_exp, aw_act;
        automatic id_t aw_id;
        aw_act = mon_slv_req_i[i].aw;
        if (aw_queue[i].size() == 0) $error("AW queue empty");
        aw_exp = aw_queue[i].pop_front();
        aw_id = aw_exp.id;
        // Ignore ID since it is modified in the network interface
        aw_act.id = 'X;
        aw_exp.id = 'X;
        if (aw_exp !== aw_act) begin
          $error("AW mismatch");
          $info("Slave[%0d] port output AW: id=%0d, len=%0d (not added to compare queue)", i, aw_id, aw_exp.len+1);
          print_aw(aw_exp, aw_act);
        end else begin
          aw_id_queue[i].push_back(aw_id);
          if (Verbose) $info("Slave[%0d] Received AW: id=%0d, len=%0d", i, aw_id, aw_exp.len+1);
        end
      end
      if (mon_slv_req_i[i].w_valid && mon_slv_rsp_i[i].w_ready) begin
        automatic w_chan_t w_exp, w_act;
        automatic id_t w_id;
        w_act = mon_slv_req_i[i].w;
        if (w_queue[i].size() == 0) $error("W queue is empty!");
        w_exp = w_queue[i].pop_front();
        if (w_exp !== w_act) begin
          $error("W mismatch");
          print_w(w_exp, w_act);
        end else begin
          if (Verbose) $info("Slave[%0d] Received W", i);
        end
      end
      if (mon_slv_req_i[i].ar_valid && mon_slv_rsp_i[i].ar_ready) begin
        automatic ar_chan_t ar_exp, ar_act;
        automatic id_t ar_id;
        ar_act = mon_slv_req_i[i].ar;
        if (ar_queue[i].size() == 0) $error("AR queue is empty!");
        ar_exp = ar_queue[i].pop_front();
        ar_id = ar_exp.id;
        // Ignore ID since it is modified in the network interface
        ar_act.id = 'X;
        ar_exp.id = 'X;
        if (ar_exp !== ar_act) begin
          $error("AR mismatch");
          print_ar(ar_exp, ar_act);
        end else begin
          ar_id_queue[i].push_back(ar_id);
          if (Verbose) $info("Slave[%0d] Received AR: id=%0d, len=%0d", i, ar_id, ar_exp.len+1);
        end
      end
    end
  end
  // verilog_lint: waive-stop always-ff-non-blocking

  // verilog_lint: waive-start always-ff-non-blocking
  for (genvar i = 0; i < NumSlaves; i++) begin : gen_slv_step_3
    always_ff @(posedge clk_i) begin : slv_step_3
      if (mon_slv_rsp_i[i].b_valid && mon_slv_req_i[i].b_ready) begin
        automatic b_chan_t b;
        b = mon_slv_rsp_i[i].b;
        b.id = aw_id_queue[i].pop_front();
        b_queue[i][b.id].push_back(b);
        if (Verbose) $info("Slave[%0d] Issued B: id=%0d, user=%0x", i, b.id, b.user);
      end
      if (mon_slv_rsp_i[i].r_valid && mon_slv_req_i[i].r_ready) begin
        automatic r_chan_t r;
        r = mon_slv_rsp_i[i].r;
        r.id = ar_id_queue[i][0];
        if (r.last) void'(ar_id_queue[i].pop_front());
        r_queue[i][r.id].push_back(r);
        if (Verbose) $info("Slave[%0d] Issued R: id=%0d, data=%0x, last=%0b",
                           i, r.id, r.data, r.last);
      end
    end
  end
  // verilog_lint: waive-stop always-ff-non-blocking

  // verilog_lint: waive-start always-ff-non-blocking
  always_ff @(posedge clk_i) begin : step_4
    if (mon_mst_rsp_i.b_valid && mon_mst_req_i.b_ready) begin
      automatic b_chan_t b_exp, b_act;
      automatic b_chan_t b_tmp;
      automatic id_t b_id;
      automatic int unsigned slv_id;
      automatic b_chan_t b_mcast_exp [NumSlaves];
      automatic int find_flag=0;
      b_act = mon_mst_rsp_i.b;
      b_id = b_act.id;
      if (Verbose) $info("Received B: id=%0d, user=%0x", b_id, b_act.user);
      if (b_out_rsp_queue[b_id].size() == 0) $error("B: id=%0d out rsp queue is empty!", b_id);
      // slv_id = b_out_rsp_queue[b_id][0].slv_id;
      // if (b_queue[slv_id][b_id].size() == 0) $error("Slave [%0d] B queue is empty!", slv_id);
      // b_exp = b_queue[slv_id][b_id].pop_front();
      if(b_out_rsp_queue[b_id][0].num_rsp==0) begin
        $display("This is a normal B");
        slv_id = b_out_rsp_queue[b_id][0].slv_id;
        if (b_queue[slv_id][b_id].size() == 0) $error("Slave [%0d] B queue is empty!", slv_id);
        b_exp = b_queue[slv_id][b_id].pop_front();
        if (b_exp !== b_act) begin
          $error("B mismatch");
          print_b(b_exp, b_act);
        end else begin
          $display("B matched!");
          print_b(b_exp, b_act);
          // This should always be true for B
          if (b_out_rsp_queue[b_id][0].num_rsp == 0) begin
            if (b_out_rsp_queue[b_id].size() == 0)
              $error("B: id=%0d out response queue is empty!", b_id);
            void'(b_out_rsp_queue[b_id].pop_front());
          end else begin
            b_out_rsp_queue[b_id][0].num_rsp--;
          end
        end
      end else begin
        $display("This is a mcast B");
        for(int i=0; i<$bits(multiaddr_decode_sel); i++) begin
          if(b_out_rsp_queue[b_id][0].num_rsp[i]==1 && b_queue[i][b_id][0]==b_act) begin
            find_flag = 1;
            $display("B matched with slave[%0d]",i);
            break;
          end
        end
        if(!find_flag) begin
          $error("mcast B mismatch");
        end else begin
          // $display("B matched!");
          $display("b_out_rsp_queue[b_id].size()=%0d",b_out_rsp_queue[b_id].size());
          if (b_out_rsp_queue[b_id].size() == 0)
              $error("B: id=%0d out response queue is empty!", b_id);
          for(int i=0; i<$bits(multiaddr_decode_sel); i++) begin
            if(b_out_rsp_queue[b_id][0].num_rsp[i]==1) begin
              if (b_queue[i][b_id].size() == 0) $error("Slave [%0d] B queue is empty!", i);
              b_tmp = b_queue[i][b_id].pop_front();
              $display("pop b_queue[%0d], id=%0d, user=%0x", i, b_tmp.id, b_tmp.user);
            end
          end
          void'(b_out_rsp_queue[b_id].pop_front());
          $display("b_out_rsp_queue[b_id].size()=%0d",b_out_rsp_queue[b_id].size());
        end
      end
    end
    if (mon_mst_rsp_i.r_valid && mon_mst_req_i.r_ready) begin
      automatic r_chan_t r_exp, r_act;
      automatic id_t r_id;
      automatic int unsigned slv_id;
      r_act = mon_mst_rsp_i.r;
      r_id = r_act.id;
      if (Verbose) $info("Received R: id=%0d, data=%0x, last=%0b", r_id, r_act.data, r_act.last);
      if (r_out_rsp_queue[r_id].size() == 0) $error("R: id=%0d out rsp queue is empty!", r_id);
      slv_id = r_out_rsp_queue[r_id][0].slv_id;
      if (r_queue[slv_id][r_id].size() == 0) $error("Slave [%0d] R queue is empty!", slv_id);
      r_exp = r_queue[slv_id][r_id].pop_front();
      if (r_exp !== r_act) begin
        $error("R mismatch");
        print_r(r_exp, r_act);
      end else begin
        if (r_out_rsp_queue[r_id][0].num_rsp == 0) begin
          if (r_out_rsp_queue[r_id].size() == 0) $error("R: id=%0d queue is empty!", r_id);
          void'(r_out_rsp_queue[r_id].pop_front());
          if (Verbose) $info("R: id=%0d slv_id=%0d r_out_rsp_queue popped", r_id, slv_id);
        end else begin
          r_out_rsp_queue[r_id][0].num_rsp--;
        end
      end
    end
    $display("&aw_queue_empty=%0d, &w_queue_empty=%0d, &ar_queue_empty=%0d, &b_queue_empty=%0d, &r_queue_empty=%0d, &r_out_rsp_queue_empty=%0d, &b_out_rsp_queue_empty=%0d, end_of_sim_o=%0d",
            &aw_queue_empty, &w_queue_empty, &ar_queue_empty, &b_queue_empty, &r_queue_empty, &r_out_rsp_queue_empty, &b_out_rsp_queue_empty, end_of_sim_o);
  end
  // verilog_lint: waive-stop always-ff-non-blocking

  logic [NumSlaves-1:0] aw_queue_empty;
  logic [NumSlaves-1:0] w_queue_empty;
  logic [NumSlaves-1:0] ar_queue_empty;
  logic [NumSlaves-1:0][NumAxiIds-1:0] b_queue_empty;
  logic [NumSlaves-1:0][NumAxiIds-1:0] r_queue_empty;

  logic [NumAxiIds-1:0] r_out_rsp_queue_empty;
  logic [NumAxiIds-1:0] b_out_rsp_queue_empty;

  logic [NumSlaves-1:0][31:0] aw_queue_state;
  logic [NumSlaves-1:0][31:0] w_queue_state;
  logic [NumSlaves-1:0][31:0] ar_queue_state;
  logic [NumSlaves-1:0][NumAxiIds-1:0][31:0] b_queue_state;
  logic [NumSlaves-1:0][NumAxiIds-1:0][31:0] r_queue_state;

  always_comb begin
    for (int i = 0; i < NumSlaves; i++) begin : gen_b_queue_state
      aw_queue_state[i] = aw_queue[i].size();
      w_queue_state[i] = w_queue[i].size();
      ar_queue_state[i] = ar_queue[i].size();
      for (int j = 0; j < NumAxiIds; j++) begin : gen_b_queue_state
        b_queue_state[i][j] = b_queue[i][j].size();
        r_queue_state[i][j] = r_queue[i][j].size();
      end
    end
  end

  always_comb begin
    for (int i = 0; i < NumSlaves; i++) begin
      aw_queue_empty[i] = (aw_queue[i].size() == 0);
      w_queue_empty[i] = (w_queue[i].size() == 0);
      ar_queue_empty[i] = (ar_queue[i].size() == 0);
      for (int j = 0; j < NumAxiIds; j++) begin
        b_queue_empty[i][j] = (b_queue[i][j].size() == 0);
        r_queue_empty[i][j] = (r_queue[i][j].size() == 0);
      end
    end
    for (int i = 0; i < NumAxiIds; i++) begin
      r_out_rsp_queue_empty[i] = (r_out_rsp_queue[i].size() == 0);
      b_out_rsp_queue_empty[i] = (b_out_rsp_queue[i].size() == 0);
    end

    end_of_sim_o =  &aw_queue_empty &&
                    &w_queue_empty &&
                    &ar_queue_empty &&
                    &b_queue_empty &&
                    &r_queue_empty &&
                    &r_out_rsp_queue_empty &&
                    &b_out_rsp_queue_empty;
  end


endmodule
