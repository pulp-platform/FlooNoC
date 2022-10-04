// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Authors:
//  - Thomas Benz <tbenz@iis.ee.ethz.ch>
//  - Paul Scheffler <paulsc@iis.ee.ethz.ch>
//  - Tim Fischer <fischeti@iis.ee.ethz.ch>

module axi_channel_compare #(
    parameter type aw_chan_t = logic,
    parameter type w_chan_t  = logic,
    parameter type b_chan_t  = logic,
    parameter type ar_chan_t = logic,
    parameter type r_chan_t  = logic,
    parameter type req_t     = logic,
    parameter type resp_t    = logic
)(
    input logic  clk_i,
    input req_t  axi_a_req,
    input resp_t axi_a_res,
    input req_t  axi_b_req,
    input resp_t axi_b_res
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
        $display("user:   | %64d | %64d", aw_expected.user, aw_received.user);
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
        $display("user:   | %64d | %64d", ar_expected.user, ar_received.user);
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
        $display("user:   | %64d | %64d", w_expected.user, w_received.user);
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
        $display("user:   | %64d | %64d", b_expected.user, b_received.user);
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
        $display("user:   | %64d | %64d", r_expected.user, r_received.user);
        $display("--------|------------------------------------------------------------------|-----------------------------------------------------------------");
        // verilog_lint: waive-stop line-length
    endfunction

    // queues
    aw_chan_t aw_queue [$];
    w_chan_t  w_queue  [$];
    b_chan_t  b_queue  [$];
    ar_chan_t ar_queue [$];
    r_chan_t  r_queue  [$];

    // requests generated at axi A: enqueue elements
    always_ff @(posedge clk_i) begin : proc_enqueue_a
        // aw
        if (axi_a_req.aw_valid & axi_a_res.aw_ready)
            aw_queue.push_back(axi_a_req.aw);
        // w
        if (axi_a_req.w_valid & axi_a_res.w_ready)
            w_queue.push_back(axi_a_req.w);
        // ar
        if (axi_a_req.ar_valid & axi_a_res.ar_ready)
            ar_queue.push_back(axi_a_req.ar);
    end

    // responses generated at axi B: enqueue elements
    always_ff @(posedge clk_i) begin : proc_enqueue_b
        // b
        if (axi_b_res.b_valid & axi_b_req.b_ready)
            b_queue.push_back(axi_b_res.b);
        // r
        if (axi_b_res.r_valid & axi_b_req.r_ready)
            r_queue.push_back(axi_b_res.r);
    end

    // requests arriving at axi B from A: dequeue elements and check
    always_ff @(posedge clk_i) begin : proc_dequeue_and_check_b
        // aw
        if (axi_b_req.aw_valid & axi_b_res.aw_ready) begin
            automatic aw_chan_t aw_exp, aw_act;
            if (aw_queue.size() == 0) $error("AW queue is empty!");
            aw_exp = aw_queue.pop_front(); // verilog_lint: waive always-ff-non-blocking
            aw_act = axi_b_req.aw;
            // Ignore ID
            aw_exp.id = 'X;
            aw_act.id = 'X;
            if (aw_exp !== aw_act) begin
                $error("AW mismatch!");
                print_aw(aw_exp, aw_act);
            end
        end
        // w
        if (axi_b_req.w_valid & axi_b_res.w_ready) begin
            automatic w_chan_t w_exp, w_act;
            if (w_queue.size() == 0) $error("W queue is empty!");
            w_exp = w_queue.pop_front(); // verilog_lint: waive always-ff-non-blocking
            w_act = axi_b_req.w;
            if (w_exp !== w_act) begin
                $error("W mismatch!");
                print_w(w_exp, w_act);
            end
        end
        // ar
        if (axi_b_req.ar_valid & axi_b_res.ar_ready) begin
            automatic ar_chan_t ar_exp, ar_act;
            if (ar_queue.size() == 0) $error("AR queue is empty!");
            ar_exp = ar_queue.pop_front(); // verilog_lint: waive always-ff-non-blocking
            ar_act = axi_b_req.ar;
            // Ignore ID
            ar_exp.id = 'X;
            ar_act.id = 'X;
            if (ar_exp !== ar_act) begin
                $error("AR mismatch!");
                print_ar(ar_exp, ar_act);
            end
        end
    end

    // responses arriving at axi A from B: dequeue elements and check
    always_ff @(posedge clk_i) begin : proc_dequeue_and_check_a
        // b
        if (axi_a_res.b_valid & axi_a_req.b_ready) begin
            automatic b_chan_t b_exp, b_act;
            if (b_queue.size() == 0) $error("B queue is empty!");
            b_exp = b_queue.pop_front(); // verilog_lint: waive always-ff-non-blocking
            b_act = axi_a_res.b;
            // Ignore ID
            b_exp.id = 'X;
            b_act.id = 'X;
            if (b_exp !== b_act) begin
                $error("B mismatch!");
                print_b(b_exp, b_act);
            end
        end
        // r
        if (axi_a_res.r_valid & axi_a_req.r_ready) begin
            automatic r_chan_t r_exp, r_act;
            if (r_queue.size() == 0) $error("R queue is empty!");
            r_exp = r_queue.pop_front(); // verilog_lint: waive always-ff-non-blocking
            r_act = axi_a_res.r;
            // Ignore ID
            r_exp.id = 'X;
            r_act.id = 'X;
            if (r_exp !== r_act) begin
                $error("R mismatch!");
                print_r(r_exp, r_act);
            end
        end
    end

endmodule : axi_channel_compare
