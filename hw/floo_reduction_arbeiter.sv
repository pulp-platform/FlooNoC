// Chen Wu

module floo_reduction_arbeiter import floo_pkg::*;
#(
  parameter int unsigned NumRoutes  = 1,
  parameter type         flit_t     = logic,
  parameter type         id_t       = logic
) (
  input  logic                   clk_i,
  input  logic                   rst_ni,
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

  logic [NumRoutes-1:0]  reducing_valid;
  logic [NumRoutes-1:0][NumRoutes-1:0]  in_route_mask; // calculated expected input source lists for each input flit

  for (genvar in_route = 0; in_route < NumRoutes; in_route++) begin
    floo_reduction_sync #(
      .NumRoutes ( NumRoutes ),
      .index     ( in_route  ),
      .flit_t    ( flit_t    ),
      .id_t      ( id_t      )
    ) i_reduction_sync (
      .clk_i,
      .rst_ni,
      .data_i           ( data_i                   ),
      .valid_i          ( valid_i                  ),
      .node_id_i        ( node_id_i                ),
      .valid_o          ( reducing_valid[in_route] ),
      .in_route_mask_o  ( in_route_mask[in_route]  )
    );
  end

  typedef logic [cf_math_pkg::idx_width(NumRoutes)-1:0] arb_idx_t;
  arb_idx_t selected_idx;

  lzc #(
    .WIDTH(NumRoutes)
  ) i_lzc (
    .in_i  ( reducing_valid ),
    .cnt_o ( selected_idx ),
    .empty_o ()
  );

  // reduction operation
  always_comb begin : proc_data_o
    flit_t normal_data;
    logic error_found;

    normal_data = data_i[selected_idx];
    error_found = 0;
    data_o = '0;
    if(data_i[selected_idx].hdr.commtype == CollectB) begin : gen_reduced_B
      for (int i = 0; i < NumRoutes; i++) begin
        if(in_route_mask[selected_idx][i]) begin
          if(data_i[i].payload[99:98]==2'b10) begin
            data_o = data_i[i];
            error_found = 1;
            break;
          end
          else begin
            normal_data = data_i[i];
          end
        end
      end

      if(!error_found) begin
        data_o = normal_data;
      end
    end
    else begin: gen_default_reduced_data
      data_o = data_i[selected_idx];
    end
  end

  assign valid_o = |reducing_valid;
  assign ready_o = (ready_i&valid_o)? valid_i&in_route_mask[selected_idx] : '0;
  
endmodule