// Chen Wu

module floo_reduction_arbiter import floo_pkg::*;
#(
  parameter int unsigned NumRoutes  = 1,
  parameter type         flit_t     = logic,
  parameter type         payload_t  = logic,
  parameter payload_t    NarrowRspMask = '0,
  parameter payload_t    WideRspMask = '0,
  parameter type         id_t       = logic
) (
  /// Ports towards the input routes
  input  logic  [NumRoutes-1:0]  valid_i,
  output logic  [NumRoutes-1:0]  ready_o,
  input  flit_t [NumRoutes-1:0]  data_i,
  input  id_t                    node_id_i,
  /// Ports towards the output route
  output logic                   valid_o,
  input  logic                   ready_i,
  output flit_t                  data_o
);

  // calculated expected input source lists for each input flit
  logic [NumRoutes-1:0]  in_route_mask;

  typedef logic [cf_math_pkg::idx_width(NumRoutes)-1:0] arb_idx_t;
  arb_idx_t selected_idx;
  flit_t normal_data;

  lzc #(
    .WIDTH(NumRoutes)
  ) i_lzc (
    .in_i  ( valid_i ),
    .cnt_o ( selected_idx ),
    .empty_o ()
  );

  floo_reduction_sync #(
    .NumRoutes ( NumRoutes ),
    .arb_idx_t     ( arb_idx_t  ),
    .flit_t    ( flit_t    ),
    .id_t      ( id_t      )
  ) i_reduction_sync (
    .index            ( selected_idx           ),
    .data_i           ( data_i                   ),
    .valid_i          ( valid_i                  ),
    .node_id_i        ( node_id_i                ),
    .valid_o          ( valid_o ),
    .in_route_mask_o  ( in_route_mask  )
  );

  payload_t ReduceMask;
  assign ReduceMask = data_i[selected_idx].hdr.axi_ch==NarrowB? NarrowRspMask : WideRspMask;

  // reduction operation
  always_comb begin : gen_reduced_B
    logic error_found;
    logic [1:0] resp;

    normal_data = data_i[selected_idx];
    error_found = 0;
    data_o = '0;
    for (int i = 0; i < NumRoutes; i++) begin
      if(in_route_mask[i]) begin
        for (int j = 0; j < $bits(ReduceMask); j++) begin
          if (ReduceMask[j]) begin
            resp = data_i[i].payload[j +: $bits(resp)];
          end
        end
        if(resp==axi_pkg::RESP_SLVERR) begin
          data_o = data_i[i];
          error_found = 1;
          break;
        end
      end
    end

    if(!error_found) begin
      data_o = normal_data;
    end
  end

  assign ready_o = (ready_i&valid_o)? valid_i&in_route_mask : '0;

endmodule
