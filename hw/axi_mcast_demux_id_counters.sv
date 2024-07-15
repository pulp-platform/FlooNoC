`include "common_cells/registers.svh"

module delta_counter #(
    parameter int unsigned WIDTH = 4,
    parameter bit STICKY_OVERFLOW = 1'b0,
    parameter int unsigned NumAddrRules = 0,
    parameter bit          McastBFifo = 1'b0,
    parameter int unsigned FifoDepth = 1
)(
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             clear_i, // synchronous clear
    input  logic             en_i,    // enable the counter
    input  logic             load_i,  // load a new value
    input  logic             down_i,  // downcount, default is up
    input  logic [$clog2(NumAddrRules):0] rep_coeff_i,
    input  logic [WIDTH-1:0] delta_i,
    input  logic [WIDTH-1:0] d_i,
    output logic [WIDTH-1:0] q_o,
    output logic             f_o,
    output logic             overflow_o,
    output logic             merged_pop_o
);
    
    logic full, empty;
    assign f_o = (McastBFifo) ? full : 1'b0;
    logic [WIDTH:0] counter_q, counter_d;
    if (STICKY_OVERFLOW) begin : gen_sticky_overflow
        logic overflow_d, overflow_q;
        always_ff @(posedge clk_i or negedge rst_ni) overflow_q <= ~rst_ni ? 1'b0 : overflow_d;
        always_comb begin
            overflow_d = overflow_q;
            if (clear_i || load_i) begin
                overflow_d = 1'b0;
            end else if (!overflow_q && en_i) begin
                if (down_i) begin
                    overflow_d = delta_i > counter_q[WIDTH-1:0];
                end else begin
                    overflow_d = counter_q[WIDTH-1:0] > ({WIDTH{1'b1}} - delta_i);
                end
            end
        end
        assign overflow_o = overflow_q;
    end else begin : gen_transient_overflow
        // counter overflowed if the MSB is set
        assign overflow_o = counter_q[WIDTH];
    end
    assign q_o = counter_q[WIDTH-1:0];

    always_comb begin
        counter_d = counter_q;

        if (clear_i) begin
            counter_d = '0;
        end else if (load_i) begin
            counter_d = {1'b0, d_i};
        end else if (en_i) begin
            if (down_i) begin
                counter_d = counter_q - delta_i;
            end else begin
                counter_d = counter_q + delta_i;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
           counter_q <= '0;
        end else begin
           counter_q <= counter_d;
        end
    end

// multicast.
  if (McastBFifo) begin: Mcast
    logic [$clog2(NumAddrRules):0] rsp_rep_coeff, rsp_cnt_d, rsp_cnt_q;
    assign merged_pop_o = (rsp_rep_coeff>0) && (rsp_cnt_d == rsp_rep_coeff);

    always_comb begin
        rsp_cnt_d = rsp_cnt_q;
        if ((rsp_rep_coeff>0) && (rsp_cnt_q == rsp_rep_coeff)) begin
            rsp_cnt_d = '0;
        end else if (en_i && down_i) begin
            rsp_cnt_d = rsp_cnt_q + 1'b1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
           rsp_cnt_q  <= '0;
        end else begin
           rsp_cnt_q  <= rsp_cnt_d;
        end
    end
    fifo_v3 # (
      .DEPTH       (FifoDepth), // How to set depth?
      .dtype       (logic [$clog2(NumAddrRules):0]) // need parameters
    ) i_nrsp_buffer (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (full),
      .empty_o   (empty),
      .usage_o   (),
      .data_i    (rep_coeff_i),
      .push_i    (en_i && ~down_i && ~full),
      .data_o    (rsp_rep_coeff),
      .pop_i     ((rsp_rep_coeff>0) && (rsp_cnt_d == rsp_rep_coeff) && ~empty)
    );
  end else begin
    assign merged_pop_o = 1'b0;
  end
endmodule

module axi_mcast_demux_id_counters #(
  // the lower bits of the AXI ID that should be considered, results in 2**AXI_ID_BITS counters
  parameter int unsigned AxiIdBits         = 2,
  parameter int unsigned CounterWidth      = 4,
  parameter int unsigned NumAddrRules      = 0,
  parameter bit          McastBFifo        = 1'b0,
  parameter type         mst_port_select_t = logic,
  parameter type         mcast_select_t    = logic
) (
  input                        clk_i,   // Clock
  input                        rst_ni,  // Asynchronous reset active low
  // lookup
  input  logic [AxiIdBits-1:0] lookup_axi_id_i,
  output mst_port_select_t     lookup_mst_select_o,
  output mcast_select_t        lookup_mcast_select_o,
  output logic                 lookup_mst_select_occupied_o,
  // push
  output logic                 full_o,
  input  logic [AxiIdBits-1:0] push_axi_id_i,
  input  mst_port_select_t     push_mst_select_i,
  input  mcast_select_t        push_mcast_select_i,
  input  logic                 push_i,
  input  logic [$clog2(NumAddrRules):0] rep_coeff_i,
  // inject ATOPs in AR channel
  input  logic [AxiIdBits-1:0] inject_axi_id_i,
  input  logic                 inject_i,
  // pop
  input  logic [AxiIdBits-1:0] pop_axi_id_i,
  input  logic                 pop_i,
  output logic                 merged_pop_o
);
  localparam int unsigned NoCounters = 2**AxiIdBits;
  typedef logic [CounterWidth-1:0] cnt_t;

  // registers, each gets loaded when push_en[i]
  mst_port_select_t [NoCounters-1:0] mst_select_q;
  mcast_select_t [NoCounters-1:0] mcast_mst_select_q;

  // counter signals
  logic [NoCounters-1:0] push_en, inject_en, pop_en, occupied, cnt_full, merged_pop;

  //-----------------------------------
  // Lookup
  //-----------------------------------
  assign lookup_mst_select_o          = mst_select_q[lookup_axi_id_i];
  assign lookup_mcast_select_o        = mcast_mst_select_q[lookup_axi_id_i];
  assign lookup_mst_select_occupied_o = occupied[lookup_axi_id_i];
  //-----------------------------------
  // Push and Pop
  //-----------------------------------
  assign push_en   = (push_i)   ? (1 << push_axi_id_i)   : '0;
  assign inject_en = (inject_i) ? (1 << inject_axi_id_i) : '0;
  assign pop_en    = (pop_i)    ? (1 << pop_axi_id_i)    : '0;
  assign full_o    = |cnt_full;
  assign merged_pop_o = |merged_pop;
  // counters
  for (genvar i = 0; i < NoCounters; i++) begin : gen_counters
    logic cnt_en, cnt_down, overflow, rsp_buf_full;
    cnt_t cnt_delta, in_flight;
    always_comb begin
      unique case ({push_en[i], inject_en[i], pop_en[i]})
        3'b001  : begin // pop_i = -1
          cnt_en    = 1'b1;
          cnt_down  = 1'b1;
          cnt_delta = cnt_t'(1);
        end
        3'b010  : begin // inject_i = +1
          cnt_en    = 1'b1;
          cnt_down  = 1'b0;
          cnt_delta = cnt_t'(1);
        end
     // 3'b011, inject_i & pop_i = 0 --> use default
        3'b100  : begin // push_i = +1
          cnt_en    = 1'b1;
          cnt_down  = 1'b0;
          // cnt_delta = cnt_t'(1);
          cnt_delta = cnt_t'(rep_coeff_i);
        end
     // 3'b101, push_i & pop_i = 0 --> use default
        3'b110  : begin // push_i & inject_i = +2
          cnt_en    = 1'b1;
          cnt_down  = 1'b0;
          cnt_delta = cnt_t'(2);
        end
        3'b111  : begin // push_i & inject_i & pop_i = +1
          cnt_en    = 1'b1;
          cnt_down  = 1'b0;
          cnt_delta = cnt_t'(1);
        end
        default : begin // do nothing to the counters // why no 3'b101?
          cnt_en    = 1'b0;
          cnt_down  = 1'b0;
          cnt_delta = cnt_t'(0);
        end
      endcase
    end

    delta_counter #(
      .WIDTH           ( CounterWidth ),
      .STICKY_OVERFLOW ( 1'b0         ),
      .NumAddrRules    ( NumAddrRules ),
      .McastBFifo      ( McastBFifo   )
    ) i_in_flight_cnt (
      .clk_i      ( clk_i     ),
      .rst_ni     ( rst_ni    ),
      .clear_i    ( 1'b0      ),
      .en_i       ( cnt_en    ),
      .load_i     ( 1'b0      ),
      .down_i     ( cnt_down  ),
      .rep_coeff_i(rep_coeff_i),
      .delta_i    ( cnt_delta ),
      .d_i        ( '0        ),
      .q_o        ( in_flight ),
      .f_o        (rsp_buf_full),
      .overflow_o ( overflow  ),
      .merged_pop_o (merged_pop[i])
    );
    assign occupied[i] = |in_flight;
    assign cnt_full[i] = overflow | (&in_flight) | rsp_buf_full;

    // holds the selection signal for this id
    `FFLARN(mst_select_q[i], push_mst_select_i, push_en[i], '0, clk_i, rst_ni)
    `FFLARN(mcast_mst_select_q[i], push_mcast_select_i, push_en[i], '0, clk_i, rst_ni)

// pragma translate_off
`ifndef VERILATOR
`ifndef XSIM
    // Validate parameters.
    cnt_underflow: assert property(
      @(posedge clk_i) disable iff (~rst_ni) (pop_en[i] |=> !overflow)) else
        $fatal(1, "axi_demux_id_counters > Counter: %0d underflowed.\
                   The reason is probably a faulty AXI response.", i);
`endif
`endif
// pragma translate_on
  end
endmodule