// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Michael Rogenmoser <michaero@iis.ee.ethz.ch>
// Lorenzo Leone <lleone@iis.ee.ethz.ch>
// Raphael Roth <raroth@student.ethz.ch>

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"

/// A simple router with configurable number of ports, physical and virtual channels, and input/output buffers
module floo_router
  import floo_pkg::*;
#(
  /// Number of ports
  parameter int unsigned NumRoutes            = 0,
  /// More fine-grained control over number of input ports
  parameter int unsigned NumInput             = NumRoutes,
  /// More fine-grained control over number of output ports
  parameter int unsigned NumOutput            = NumRoutes,
  /// Number of virtual channels
  parameter int unsigned NumVirtChannels      = 0,
  /// Number of physical channels
  parameter int unsigned NumPhysChannels      = 1,
  /// Depth of input FIFOs
  parameter int unsigned InFifoDepth          = 0,
  /// Depth of output FIFOs
  parameter int unsigned OutFifoDepth         = 0,
  /// Routing algorithm
  parameter route_algo_e RouteAlgo            = IdTable,
  /// Parameters, only used for ID-based and XY routing
  parameter int unsigned IdWidth              = 0,
  parameter type         id_t                 = logic[IdWidth-1:0],
  /// Used for ID-based routing
  parameter int unsigned NumAddrRules         = 1,
  /// Configuration parameters for special network topologies
  /// Disables Y->X connections in XYRouting
  parameter bit          XYRouteOpt           = 1'b1,
  /// Disables loopback connections
  parameter bit          NoLoopback           = 1'b1,
  /// Enable Multicast feature
  parameter bit          EnMultiCast          = 1'b0,
  /// Enable offload reduction feature
  parameter bit          EnOffloadReduction   = 1'b0,
  /// Enable parallel reduction feature
  parameter bit          EnParallelReduction  = 1'b0,
  /// Various types
  parameter type         addr_rule_t          = logic,
  parameter type         flit_t               = logic,
  parameter type         hdr_t                = logic,
  parameter type         payload_t            = logic,
  parameter payload_t    NarrowRspMask        = '0,
  parameter payload_t    WideRspMask          = '0,
  /// Offload reduction parameter
  /// Possible operation for offloading (must match type in header)
  parameter type         RdOperation_t        = logic,
  /// Data type of the offload reduction
  parameter type         RdData_t             = logic,
  /// Parameter for the reduction configuration
  parameter reduction_cfg_t RdCfg             = '0,
  /// AXI configurations
  parameter axi_cfg_t    AxiCfgOffload        = '0,
  parameter axi_cfg_t    AxiCfgParallel       = '0
) (
  input  logic                                       clk_i,
  input  logic                                       rst_ni,
  input  logic                                       test_enable_i,
  /// Only used for `XYRouting`, tie to '0 otherwise
  input  id_t                                        xy_id_i,
  /// Only used for `IdTable` routing, tie to '0 otherwise
  input  addr_rule_t [NumAddrRules-1:0]              id_route_map_i,
  /// Input channels
  input  logic  [NumInput-1:0][NumVirtChannels-1:0]  valid_i,
  output logic  [NumInput-1:0][NumVirtChannels-1:0]  ready_o,
  input  flit_t [NumInput-1:0][NumPhysChannels-1:0]  data_i,
  /// Output channels
  output logic  [NumOutput-1:0][NumVirtChannels-1:0] valid_o,
  input  logic  [NumOutput-1:0][NumVirtChannels-1:0] ready_i,
  output flit_t [NumOutput-1:0][NumPhysChannels-1:0] data_o,
  /// IF towards the offload logic
  output RdOperation_t                               offload_req_op_o,
  output RdData_t                                    offload_req_operand1_o,
  output RdData_t                                    offload_req_operand2_o,
  output logic                                       offload_req_valid_o,
  input logic                                        offload_req_ready_i,
  /// IF from external FPU
  input RdData_t                                     offload_resp_result_i,
  input logic                                        offload_resp_valid_i,
  output logic                                       offload_resp_ready_o
);

  // TODO MICHAERO: assert NumPhysChannels <= NumVirtChannels

  // When a offloadable reduction is dedected then the data will be brunched off infront
  // of the router crossbar. The reduction logic will reduce the incoming flits and deliver
  // a single flit instead. When finished the result will be merged as an extra port into
  // the output arbiter.

  // Generate local Number of routes
  localparam int unsigned localNumInputs = (EnOffloadReduction == 1'b1) ? (NumInput + 1) : (NumInput);

  // Generate the vars to handle the input of the router
  flit_t [NumInput-1:0][NumVirtChannels-1:0] in_data, in_routed_data;
  logic  [NumInput-1:0][NumVirtChannels-1:0] in_valid, in_ready;
  logic  [NumInput-1:0][NumVirtChannels-1:0][NumOutput-1:0] route_mask;

  // Router input part
  for (genvar in = 0; in < NumInput; in++) begin : gen_input
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_input

      logic [cf_math_pkg::idx_width(NumPhysChannels)-1:0] in_p;
      if (NumPhysChannels == 1) begin : gen_single_phys
        assign in_p = '0;
      end else if (NumPhysChannels == NumVirtChannels) begin : gen_virt_eq_phys
        assign in_p = v;
      end else begin : gen_odd_phys
        $fatal(1, "unimplemented");
      end

      (* ungroup *)
      stream_fifo_optimal_wrap #(
        .Depth  ( InFifoDepth ),
        .type_t ( flit_t      )
      ) i_stream_fifo (
        .clk_i      ( clk_i         ),
        .rst_ni     ( rst_ni        ),
        .testmode_i ( test_enable_i ),
        .flush_i    ( 1'b0  ),
        .usage_o    (       ),
        .data_i     ( data_i  [in][in_p] ),
        .valid_i    ( valid_i [in][v]    ),
        .ready_o    ( ready_o [in][v]    ),
        .data_o     ( in_data [in][v]    ),
        .valid_o    ( in_valid[in][v]    ),
        .ready_i    ( in_ready[in][v]    )
      );

      floo_route_select #(
        .NumRoutes        ( NumOutput        ),
        .flit_t           ( flit_t           ),
        .RouteAlgo        ( RouteAlgo        ),
        .IdWidth          ( IdWidth          ),
        .id_t             ( id_t             ),
        .NumAddrRules     ( NumAddrRules     ),
        .addr_rule_t      ( addr_rule_t      ),
        .EnMultiCast      ( EnMultiCast      )
      ) i_route_select (
        .clk_i,
        .rst_ni,
        .test_enable_i,
        .xy_id_i        ( xy_id_i               ),
        .id_route_map_i ( id_route_map_i        ),
        .channel_i      ( in_data       [in][v] ),
        .valid_i        ( in_valid      [in][v] ),
        .ready_i        ( in_ready      [in][v] ),
        .channel_o      ( in_routed_data[in][v] ),
        .route_sel_o    ( route_mask    [in][v] ),
        .route_sel_id_o (                       )
      );

    end
  end

  // Var for the "normal" dataflow without any reduction
  logic  [NumInput-1:0][NumVirtChannels-1:0] cross_valid, cross_ready;

  // Vars to branch the reduction off the main path (No virtual channel support for reduction)
  logic  [NumInput-1:0][NumVirtChannels-1:0] red_valid_in, red_ready_in;
  logic  [NumInput-1:0][NumOutput-1:0] red_route_selected;
  flit_t [NumInput-1:0] red_data_in;

  // Vars for the data comming from the reduction
  logic  [NumOutput-1:0] red_valid_out, red_ready_out;
  flit_t [NumOutput-1:0] red_data_out;

  // Vars to separate reductions with only one member
  logic [NumInput-1:0][NumVirtChannels-1:0][NumInput-1:0] red_expected_in_route, red_expected_in_route_loopback;
  logic [NumInput-1:0][NumVirtChannels-1:0][$clog2(NumInput):0] red_how_many_participants;
  logic [NumInput-1:0][NumVirtChannels-1:0] red_single_member, offload_reduction;
  logic [NumInput-1:0][NumVirtChannels-1:0] red_ignore_loopback_port;

  // If we support offload reduction and a reduction is dedected then we split the signal and forward it to the reduction
  if(EnOffloadReduction == 1'b1) begin : gen_offload_reduction_demux
    for (genvar in = 0; in < NumInput; in++) begin : gen_input
      for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_input
        // Generate the mask for all inputs to determint if we have a reduction with only one member.
        // Any reduction with one member will be directly forwarded to its destination without reduction!
        floo_route_xymask #(
          .NumRoutes    (NumInput),
          .flit_t       (flit_t),
          .id_t         (id_t),
          .FwdMode      (0)
        ) i_gen_route_xymask (
          .channel_i    (in_routed_data[in][v]),
          .xy_id_i      (xy_id_i),
          .route_sel_o  (red_expected_in_route[in][v])
        );

        // If the option RdSupportLoopback is disabled, then the local port
        // must be ignored and removed from the list of participants because the last step of
        // the reduction will be handled downsteram.
        always_comb begin: gen_ignore_loopback
          red_ignore_loopback_port[in][v] = ((route_mask[in][v][Eject] == 1'b1) && (!RdCfg.RdSupportLoopback));
          red_expected_in_route_loopback[in][v] = red_expected_in_route[in][v];
          red_expected_in_route_loopback[in][v][Eject] = red_expected_in_route[in][v][Eject] & (~red_ignore_loopback_port[in][v]);
        end

        // onehot decoding of the input direction
        // bypass the reduction if only on  e input member is selected (if none is selected then bypass too [should never occure but to avoid deadlocks])
        popcount #(
          .INPUT_WIDTH (NumInput)
        ) i_red_list_counter (
          .data_i       (red_expected_in_route_loopback[in][v]),
          .popcount_o   (red_how_many_participants[in][v])
        );
        assign red_single_member[in][v] = (red_how_many_participants[in][v] <= 1);

        // Generate the handshaking
        // Outoput 0: unicast
        // Output 1: reduction
        assign offload_reduction[in][v] = (~red_single_member[in][v]) &
                                          (in_routed_data[in][v].hdr.commtype == OffloadReduction);
        stream_demux #(
          .N_OUP              (2)
        ) i_stream_demux (
          .inp_valid_i        (in_valid[in][v]),
          .inp_ready_o        (in_ready[in][v]),
          .oup_sel_i          (offload_reduction[in][v]),
          .oup_valid_o        ({red_valid_in[in][v], cross_valid[in][v]}),
          .oup_ready_i        ({red_ready_in[in][v], cross_ready[in][v]})
        );
        // Assign the data
        assign red_data_in[in] = in_routed_data[in][v];
        assign red_route_selected[in] = route_mask[in][v];
      end
    end
  end else begin
    assign cross_valid = in_valid;
    assign in_ready = cross_ready;
    assign red_valid_in = '0;
    assign red_data_in = '0;
    assign red_route_selected = '0;
    assign red_expected_in_route_loopback = '0;
  end

  // Reduction logic
  if(EnOffloadReduction == 1'b1) begin : gen_reduction_logic
    floo_offload_reduction #(
      .NumRoutes                  (NumInput),
      .flit_t                     (flit_t),
      .hdr_t                      (hdr_t),
      .id_t                       (id_t),
      .RdData_t                   (RdData_t),
      .RdOperation_t              (RdOperation_t),
      .RdCfg                      (RdCfg),
      .AxiCfg                     (AxiCfgOffload)
    ) i_offload_reduction_logic (
      .clk_i                      (clk_i),
      .rst_ni                     (rst_ni),
      .flush_i                    (1'b0),
      .node_id_i                  (xy_id_i),
      .valid_i                    (red_valid_in),
      .ready_o                    (red_ready_in),
      .data_i                     (red_data_in),
      .output_route_i             (red_route_selected),
      .expected_input_i           (red_expected_in_route_loopback),
      .valid_o                    (red_valid_out),
      .ready_i                    (red_ready_out),
      .data_o                     (red_data_out),
      .reduction_req_type_o       (offload_req_op_o),
      .reduction_req_op1_o        (offload_req_operand1_o),
      .reduction_req_op2_o        (offload_req_operand2_o),
      .reduction_req_valid_o      (offload_req_valid_o),
      .reduction_req_ready_i      (offload_req_ready_i),
      .reduction_resp_data_i      (offload_resp_result_i),
      .reduction_resp_valid_i     (offload_resp_valid_i),
      .reduction_resp_ready_o     (offload_resp_ready_o)
    );
  end else begin
    assign red_data_out = '0;
    assign red_valid_out = '0;
    assign offload_req_op_o = '0;
    assign offload_req_operand1_o = '0;
    assign offload_req_operand2_o = '0;
    assign offload_req_valid_o = '0;
    assign offload_resp_ready_o = '0;
  end

  // Normal crossbar between all in / out routes
  logic [NumOutput-1:0][NumVirtChannels-1:0][NumInput-1:0] masked_valid, masked_ready;
  logic [NumInput-1:0][NumVirtChannels-1:0][NumOutput-1:0] masked_valid_transposed;
  logic [NumInput-1:0][NumVirtChannels-1:0][NumOutput-1:0] masked_ready_transposed;
  logic [NumInput-1:0][NumVirtChannels-1:0][NumOutput-1:0] past_handshakes_q, past_handshakes_d;
  logic [NumInput-1:0][NumVirtChannels-1:0][NumOutput-1:0] current_handshakes, all_handshakes;
  logic [NumInput-1:0][NumVirtChannels-1:0][NumOutput-1:0] ignore_routes, expected_handshakes;

  flit_t [NumOutput-1:0][NumVirtChannels-1:0][NumInput-1:0] masked_data;

  for (genvar in = 0; in < NumInput; in++) begin : gen_hs_input
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_hs_virt
      for (genvar out = 0; out < NumOutput; out++) begin : gen_hs_output
        // In case of loopback connections (to itself) and Y->X connections in XYRouting,
        // we tie the handshake & data signals to 0, to optimize them away during synthesis
        if((NoLoopback && (in == out)) ||
           ((RouteAlgo == XYRouting) && XYRouteOpt &&
            (in == South || in == North) && (out == East || out == West)))
        begin : gen_no_conn
          assign masked_ready_transposed[in][v][out] = '0;
          assign masked_valid[out][v][in]     = '0;
          assign masked_data[out][v][in]      = '0;
        end else begin : gen_conn
          assign masked_ready_transposed[in][v][out] = masked_ready[out][v][in];
          assign masked_valid[out][v][in]     = cross_valid[in][v] & route_mask[in][v][out] &
                                                (!EnMultiCast || ~past_handshakes_q[in][v][out]);
          assign masked_data[out][v][in]      = in_routed_data[in][v];
        end
        assign masked_valid_transposed[in][v][out] = masked_valid[out][v][in];
      end
      if (!EnMultiCast) begin : gen_unicast
        assign cross_ready[in][v] = |(masked_ready_transposed[in][v] & route_mask[in][v]);
      end else begin : gen_multicast
        // In the case of multicast transactions, each destination can assert the ready signal
        // independently and potentially at different clock cycles. This logic ensures that
        // the upstream sender is only acknowledged when all selected downstream destinations
        // have successfully completed their handshake (valid & ready).
        //
        // Handshake received in current cycle
        assign current_handshakes[in][v] = masked_valid_transposed[in][v] &
                                           masked_ready_transposed[in][v];
        // Handhsake received in previous cycles
        assign past_handshakes_d[in][v] = (cross_ready[in][v] & cross_valid[in][v]) ? '0 :
                                            (past_handshakes_q[in][v] | current_handshakes[in][v]);
        // History of handshake received (past + present)
        assign all_handshakes[in][v] = past_handshakes_q[in][v] | current_handshakes[in][v];

        // Handshake are excepeted on all selected routes except the loopback
        assign ignore_routes[in][v] = NoLoopback ? (1 << in) : '0;
        assign expected_handshakes[in][v] = route_mask[in][v] & ~ignore_routes[in][v];

        // Send ready upstream only when all expected downstream handhsalkes have been received
        assign cross_ready[in][v] = &(all_handshakes[in][v] | ~expected_handshakes[in][v]);
      end
    end
  end

  `FF(past_handshakes_q, past_handshakes_d, '0)

  // We merge the data from the reduction module as an additional input of our output arbiter.
  logic [NumOutput-1:0][NumVirtChannels-1:0][localNumInputs-1:0] merged_valid, merged_ready;
  flit_t [NumOutput-1:0][NumVirtChannels-1:0][localNumInputs-1:0] merged_data;

  if(EnOffloadReduction == 1'b1) begin : gen_assign_data_output
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_con_virt
      for (genvar out = 0; out < NumOutput; out++) begin : gen_con_output
        assign merged_data[out][v] = {red_data_out[out], masked_data[out][v]};
        assign merged_valid[out][v] = {red_valid_out[out], masked_valid[out][v]};
        assign masked_ready[out][v] = merged_ready[out][v][localNumInputs-2:0];
        assign red_ready_out[out] = merged_ready[out][v][localNumInputs-1];
      end
    end
  end else begin
    assign merged_data = masked_data;
    assign merged_valid = masked_valid;
    assign masked_ready = merged_ready;
  end

  // Vars to handle the output of the arbiter and the optinal fifos
  flit_t [NumOutput-1:0][NumVirtChannels-1:0] out_data, out_buffered_data;
  logic  [NumOutput-1:0][NumVirtChannels-1:0] out_valid, out_ready;
  logic  [NumOutput-1:0][NumVirtChannels-1:0] out_buffered_valid, out_buffered_ready;

  for (genvar out = 0; out < NumOutput; out++) begin : gen_output

    // arbitrate input fifos per virtual channel
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_output
      // Output arbiter
      floo_output_arbiter #(
        .NumRoutes            ( NumInput                    ),
        .NumSlaveRoutes       ( localNumInputs - NumInput   ),
        .EnParallelReduction  ( EnParallelReduction         ),
        .flit_t               ( flit_t                      ),
        .hdr_t                ( hdr_t                       ),
        .payload_t            ( payload_t                   ),
        .NarrowRspMask        ( NarrowRspMask               ),
        .WideRspMask          ( WideRspMask                 ),
        .id_t                 ( id_t                        ),
        .RdSupportLoopback    ( RdCfg.RdSupportLoopback     ),
        .RdSupportAxi         ( RdCfg.RdSupportAxi          ),
        .AxiCfg               ( AxiCfgParallel              )
      ) i_output_arbiter (
        .clk_i,
        .rst_ni,

        .valid_i  ( merged_valid[out][v] ),
        .ready_o  ( merged_ready[out][v] ),
        .data_i   ( merged_data [out][v] ),
        .xy_id_i  ( xy_id_i              ),

        .valid_o ( out_valid[out][v] ),
        .ready_i ( out_ready[out][v] ),
        .data_o  ( out_data [out][v] )
      );

      if (OutFifoDepth > 0) begin : gen_out_fifo
        (* ungroup *)
        stream_fifo_optimal_wrap #(
          .Depth  ( OutFifoDepth  ),
          .type_t ( flit_t        )
        ) i_stream_fifo (
          .clk_i      ( clk_i         ),
          .rst_ni     ( rst_ni        ),
          .testmode_i ( test_enable_i ),
          .flush_i    ( 1'b0          ),
          .usage_o    (               ),
          .data_i     ( out_data          [out][v] ),
          .valid_i    ( out_valid         [out][v] ),
          .ready_o    ( out_ready         [out][v] ),
          .data_o     ( out_buffered_data [out][v] ),
          .valid_o    ( out_buffered_valid[out][v] ),
          .ready_i    ( out_buffered_ready[out][v] )
        );
      end else begin : gen_no_out_fifo
        assign out_buffered_data [out][v] = out_data          [out][v];
        assign out_buffered_valid[out][v] = out_valid         [out][v];
        assign out_ready         [out][v] = out_buffered_ready[out][v];
      end
    end

    // Arbitrate virtual channels onto the physical channel
    floo_vc_arbiter #(
      .NumVirtChannels ( NumVirtChannels ),
      .flit_t          ( flit_t          ),
      .NumPhysChannels ( NumPhysChannels )
    ) i_vc_arbiter (
      .clk_i,
      .rst_ni,

      .valid_i ( out_buffered_valid[out] ),
      .ready_o ( out_buffered_ready[out] ),
      .data_i  ( out_buffered_data [out] ),

      .ready_i ( ready_i  [out] ),
      .valid_o ( valid_o  [out] ),
      .data_o  ( data_o   [out] )
    );
  end

  for (genvar i = 0; i < NumInput; i++) begin : gen_input_assert
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_assert
      // Assert that the input data is stable when valid is asserted
      // `ASSERT(StableDataIn, valid_i[i][v] && !ready_o[i][v] |=> $stable(data_i[i][v]))
      // Assert that valid is stable when ready is not asserted
      `ASSERT(StableValidIn, valid_i[i][v] && !ready_o[i][v] |=> $stable(valid_i[i][v]))
    end
  end

  for (genvar o = 0; o < NumOutput; o++) begin : gen_output_assert
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt_assert
      // Assert that the input data is stable when valid is asserted
      // `ASSERT(StableDataOut, valid_o[o][v] && !ready_i[o][v] |=> $stable(data_o[o][v]))
      // Assert that valid is stable when ready is not asserted
      `ASSERT(StableValidOut, valid_o[o][v] && !ready_i[o][v] |=> $stable(valid_o[o][v]))
    end
  end

  // If XYRouting optimization is enabled, assert that not Y->X routing occurs
  if ((RouteAlgo == XYRouting) && XYRouteOpt) begin : gen_xy_opt_assert
    for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt
      `ASSERT(XYDirectionNotAllowed,
          !(in_valid[South][v] && route_mask[South][v][East]) &&
          !(in_valid[South][v] && route_mask[South][v][West]) &&
          !(in_valid[North][v] && route_mask[North][v][East]) &&
          !(in_valid[North][v] && route_mask[North][v][West]))
    end
  end

  // If `NoLoopback` is enabled, assert that no loopback occurs
  if (NoLoopback) begin: gen_no_loopback_assert
    for (genvar in = 0; in < NumInput; in++) begin : gen_input
      for (genvar v = 0; v < NumVirtChannels; v++) begin : gen_virt
        `ASSERT(NoLoopback, !(in_valid[in][v] && route_mask[in][v][in] &&
                            (in_data[in][v].hdr.commtype == Unicast)))
      end
    end
  end

  // Multicast is currently only supported for `XYRouting`
  `ASSERT_INIT(NoMultiCastSupport, !(EnMultiCast && RouteAlgo != XYRouting))
  // Assertion check that when we use the FP reduction no virtual channel are init
  `ASSERT_INIT(NoVirtChanSupport, !(EnOffloadReduction && (NumVirtChannels != 1)))
  // We only support symmetrical configuration for the FP reduction
  `ASSERT_INIT(NoSymConfig, !(EnOffloadReduction && (NumInput != NumOutput)))
  // Currently the AXI support must be enabled
  `ASSERT_INIT(SupportAXI, !EnOffloadReduction || RdCfg.RdSupportAxi)
  // We can not support Loopback when the option is not enabled
  `ASSERT_INIT(SupportLoopback, !(RdCfg.RdSupportLoopback && NoLoopback))

endmodule
