// Chen Wu

module floo_output_arbiter import floo_pkg::*;
#(
  parameter int unsigned NumRoutes  = 1,
  parameter type         flit_t     = logic,
  parameter type         payload_t  = logic,
  parameter payload_t    NarrowRspMask = '0,
  parameter payload_t    WideRspMask = '0,
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

  flit_t[NumRoutes-1:0]  in_reducing_data, in_normal_data;
  logic [NumRoutes-1:0]  in_reducing_valid, in_reducing_ready;
  logic [NumRoutes-1:0]  in_normal_valid, in_normal_ready;

  logic [NumRoutes-1:0]  path_mask; // 1 for every bit means that flit coming from the input port is normal, 0 means that it needs to be reduced

  flit_t out_reduced_data, out_normal_data;
  logic out_reduced_valid, out_reduced_ready;
  logic out_normal_valid, out_normal_ready;

  assign out_reduced_ready = ready_i;
  assign out_normal_ready = ready_i;

  floo_gen_path_mask #(
    .NumRoutes ( NumRoutes ),
    .flit_t    ( flit_t    )
  ) i_gen_path_mask (
    .clk_i,
    .rst_ni,
    .data_i ( data_i    ),
    .mask_o ( path_mask )
  );

  // the normal arbitrater side
  assign in_normal_valid = valid_i & path_mask;
  assign in_normal_data  = data_i ;

  floo_wormhole_arbiter #(
    .NumRoutes  ( NumRoutes ),
    .flit_t     ( flit_t          )
  ) i_wormhole_arbiter (
    .clk_i,
    .rst_ni,

    .valid_i ( in_normal_valid ),
    .ready_o ( in_normal_ready ),
    .data_i  ( in_normal_data  ),

    .valid_o ( out_normal_valid ),
    .ready_i ( out_reduced_ready ),
    .data_o  ( out_normal_data )
  );

  // the reduction side
  assign in_reducing_valid = valid_i & ~path_mask;
  assign in_reducing_data  = data_i ;

  floo_reduction_arbiter #(
    .NumRoutes  ( NumRoutes ),
    .flit_t     ( flit_t          ),
    .payload_t  ( payload_t       ),
    .NarrowRspMask ( NarrowRspMask ),
    .WideRspMask   ( WideRspMask   ),
    .id_t       ( id_t            )
  ) i_reduction_arbiter (
    .valid_i ( in_reducing_valid ),
    .ready_o ( in_reducing_ready ),
    .data_i  ( in_reducing_data  ),
    .node_id_i ( node_id_i ),

    .valid_o ( out_reduced_valid ),
    .ready_i ( out_normal_ready ),
    .data_o  ( out_reduced_data )
  );

  // choose which side to output, prefer the reduced side
  assign valid_o = (out_reduced_valid & |in_reducing_valid) ? out_reduced_valid : out_normal_valid;
  assign data_o  = (out_reduced_valid & |in_reducing_valid) ? out_reduced_data  : out_normal_data;
  assign ready_o = (out_reduced_valid & |in_reducing_valid) ? in_reducing_ready : in_normal_ready;
  
endmodule