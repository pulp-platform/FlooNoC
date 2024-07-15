// // Copyright 2022 ETH Zurich and University of Bologna.
// // Solderpad Hardware License, Version 0.51, see LICENSE for details.
// // SPDX-License-Identifier: SHL-0.51
// //
// // Michael Rogenmoser <michaero@iis.ee.ethz.ch>

// `include "common_cells/registers.svh"

// module floo_route_select 
//   import floo_pkg::*;
//   import floo_narrow_wide_pkg::*;
//  #(
//   parameter int unsigned NumRoutes     = 0,
//   // parameter int unsigned NumVirtChannels  = 0,
//   // parameter int unsigned NumInput         = NumRoutes,
//   parameter type         flit_t        = logic,
//   parameter route_algo_e RouteAlgo     = IdTable,
//   parameter bit          LockRouting   = 1'b1,
//   /// Used for ID-based and XY routing
//   parameter int unsigned IdWidth       = 0,
//   /// Used for ID-based routing
//   parameter int unsigned NumAddrRules  = 0,
//   // parameter int unsigned NumDst        = 1,
//   // parameter bit          McastFlag     = 1'b0,
//   parameter type         addr_rule_t   = logic,
//   parameter type         id_t          = logic[IdWidth-1:0],
//   /// Used for source-based routing
//   parameter int unsigned RouteSelWidth = $clog2(NumRoutes),
//   parameter bit          Mesh          = 1'b1
//   ) (
//   input  logic                         clk_i,
//   input  logic                         rst_ni,
//   input  logic                         test_enable_i,

//   input  id_t                           xy_id_i,
//   input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,

//   input  flit_t                         channel_i,
//   input  logic                          valid_i,
//   input  logic                          ready_i,
//   output flit_t      [NumRoutes-1:0]    channel_o,
//   output logic       [NumRoutes-1:0]    route_sel_o, // One-hot route (unicast), for multicast this is not one-hot.
//   output logic [$clog2(NumRoutes)-1:0]  rep_coeff_o
// );

//   logic [NumRoutes-1:0] route_sel, route_sel_mcast, route_res;
//   logic mcast_flag;
//   assign mcast_flag = (channel_i.hdr.mcast_flag && RouteAlgo == XYRouting);
//   // int NumDst = $countones(channel_i.hdr.dst_mask_id);
//   // assign num_dst_o = NumDst;

//   if (RouteAlgo == IdIsPort) begin : gen_id_is_port
//     // Routing assuming the ID is the port to be taken

//     for (genvar out_route=0; out_route<NumRoutes; out_route++) begin
//       assign channel_o[out_route] = channel_i;
//     end

//     // One-hot encoding of the decoded route
//     always_comb begin : proc_route_sel
//       rep_coeff_o = '0;
//       route_sel = '0;
//       // if (channel_i.hdr.mcast_flag) begin
//       //   route_sel 
//       // end else begin
//       //   route_sel[channel_i.hdr.dst_id] = 1'b1; // Here multicast dst_mask needs changing.
//       // end
//       route_sel[channel_i.hdr.dst_id] = 1'b1;      
//     end

//   end else if (RouteAlgo == IdTable) begin : gen_id_table
//     // Routing based on an ID table passed into the router (TBD parameter or signal)
//     // Assumes an ID field present in the flit_t

//     typedef logic [$clog2(NumRoutes)-1:0] out_id_t;
//     out_id_t out_id;

//     for (genvar out_route=0; out_route<NumRoutes; out_route++) begin
//       assign channel_o[out_route] = channel_i;
//     end
    
//     addr_decode #(
//       .NoIndices ( NumRoutes    ),
//       .NoRules   ( NumAddrRules ),
//       .addr_t    ( id_t         ),
//       .rule_t    ( addr_rule_t  ),
//       .Napot     ( 0            )
//     ) i_id_decode (
//       .addr_i           ( channel_i.hdr.dst_id  ),
//       .addr_map_i       ( id_route_map_i    ),
//       .idx_o            ( out_id            ),
//       .dec_valid_o      (),
//       .dec_error_o      (),
//       .default_idx_i    ('0),
//       .en_default_idx_i ('0)
//     );

//     // One-hot encoding of the decoded route
//     always_comb begin : proc_route_sel
//       rep_coeff_o = '0;
//       route_sel = '0;
//       route_sel[out_id] = 1'b1;
//     end

//   end else if (RouteAlgo == SourceRouting) begin : gen_consumption
//     // Routing based on a consumable header in the flit
//     always_comb begin : proc_route_sel
//       rep_coeff_o = '0;
//       route_sel = '0;
//       route_sel[channel_i.hdr.dst_id[RouteSelWidth-1:0]] = 1'b1;
//       for (int unsigned out_route=0; out_route<NumRoutes; out_route++) begin
//         channel_o[out_route] = channel_i;
//         channel_o[out_route].hdr.dst_id = channel_i.hdr.dst_id >> RouteSelWidth;
//       end      
//     end

//   end else if (RouteAlgo == XYRouting) begin : gen_xy_routing
//     // Routing based on simple XY routing
//     // Assumes an even-bit ID field in the flit_t used for xy
//     // assert ((IdWidth/2)*2 == IdWidth);
//     // assert (NumRoutes == 5);

//     // Port map:
//     //   - 0: target/destination
//     //   - 1: upper bits decreasing (South)
//     //   - 2: lower bits decreasing (West )
//     //   - 3: upper bits increasing (North)
//     //   - 4: lower bits increasing (East )

//     // One-hot encoding of the decoded route

//     id_t id_in;
//     assign id_in = id_t'(channel_i.hdr.dst_id);
    
//     // id_t [3:0] id_in_mask;
  
//     mcast_dst_conversion # (
//       .NumRoutes(NumRoutes)
//     ) i_mcast_dst_conversion (
//       .mask_i(channel_i.hdr.dst_mask_id),
//       .xy_id_i    (xy_id_i),
//       .src_id_i   (channel_i.hdr.src_id),
//       .route_sel_o(route_sel_mcast)
//     );

//     always_comb begin
//       rep_coeff_o = '0;
//       for (int unsigned out_route = 0; out_route < NumRoutes; out_route++) begin
//         rep_coeff_o += route_sel_mcast[out_route];
//       end
//     end

//     always_comb begin : proc_route_sel
//       route_sel = '0;
//       // if (id_in.x=='0 && id_in.y=='0) begin
//       if (~valid_i) begin
//         route_sel = '0;
//       end else if (id_in == xy_id_i) begin
//         route_sel[Eject] = 1'b1;
//       end else if (id_in.x == xy_id_i.x) begin
//         if (id_in.y < xy_id_i.y) begin
//           route_sel[South] = 1'b1;
//         end else begin
//           route_sel[North] = 1'b1;
//         end
//       end else begin
//         if (id_in.x < xy_id_i.x) begin
//           route_sel[West] = 1'b1;
//         end else begin
//           route_sel[East] = 1'b1;
//         end
//       end            
//     end

//     // logic [NumXEP-1:0][SamNumRules-1:0] x_axis_mask = '0;
//     // for (genvar x = 0; x < NumXEP; x++) begin
//     //   always_comb begin
//     //     x_axis_mask[x][(x+1)*NumYEP-1:x*NumYEP] = '1;
//     //   end
//     // end 


//     // for (genvar out_route = 0; out_route < NumRoutes; out_route++) begin
//     //   always_comb begin : flit_replication  
//     //     if (rep_coeff_o <= 1'b1 || out_route==Eject) begin
//     //       channel_o[out_route] = channel_i;
//     //     end else begin
//     //       channel_o[out_route] = channel_i;
//     //       if (out_route==North || out_route==South) begin
//     //         channel_o[out_route].hdr.dst_mask_id = channel_i.hdr.dst_mask_id & x_axis_mask[xy_id_i.x];
//     //       end else begin
//     //         channel_o[out_route].hdr.dst_mask_id = channel_i.hdr.dst_mask_id & ~x_axis_mask[xy_id_i.x];
//     //       end
//     //     end
//     //   end
//     // end      

//     for (genvar out_route=0; out_route<NumRoutes; out_route++) begin
//       assign channel_o[out_route] = channel_i;
//     end

//   end else begin : gen_err
//     // Unknown or unimplemented routing otherwise
//     initial begin
//       $fatal(1, "Routing algorithm unknown");
//     end
//   end

//   assign route_res = (mcast_flag) ? route_sel_mcast : route_sel;

//   if (LockRouting) begin : gen_lock
//     logic locked_route_d, locked_route_q;
//     logic [NumRoutes-1:0] route_sel_q;

//     assign route_sel_o = locked_route_q ? route_sel_q : route_res;

//     always_comb begin
//       locked_route_d = locked_route_q;

//       if (ready_i && valid_i) begin
//         locked_route_d = ~channel_i.hdr.last;

//       end
//     end

//     always @(posedge clk_i) begin
//       if (ready_i && valid_i && locked_route_q && (route_sel_q != route_res))
//         $warning("Mismatch in route selection!");
//     end

//     `FF(locked_route_q, locked_route_d, '0)
//     `FFL(route_sel_q, route_res, ~locked_route_q, '0)

//   end else begin : gen_no_lock
//     assign route_sel_o = route_res;
//   end

// endmodule


`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

module floo_route_select 
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
 #(
  parameter int unsigned NumRoutes     = 0,
  // parameter int unsigned NumVirtChannels  = 0,
  // parameter int unsigned NumInput         = NumRoutes,
  parameter type         flit_t        = logic,
  parameter route_algo_e RouteAlgo     = IdTable,
  parameter bit          LockRouting   = 1'b1,
  /// Used for ID-based and XY routing
  parameter int unsigned IdWidth       = 0,
  /// Used for ID-based routing
  parameter int unsigned NumAddrRules  = 0,
  // parameter int unsigned NumDst        = 1,
  // parameter bit          McastFlag     = 1'b0,
  parameter type         addr_rule_t   = logic,
  parameter type         id_t          = logic[IdWidth-1:0],
  /// Used for source-based routing
  parameter int unsigned RouteSelWidth = $clog2(NumRoutes),
  parameter bit          Mesh          = 1'b1
) (
  input  logic                         clk_i,
  input  logic                         rst_ni,
  input  logic                         test_enable_i,

  input  id_t                           xy_id_i,
  input  addr_rule_t [NumAddrRules-1:0] id_route_map_i,

  input  flit_t                         channel_i,
  input  logic                          valid_i,
  input  logic                          ready_i,
  output flit_t      [NumRoutes-1:0]    channel_o,
  output logic       [NumRoutes-1:0]    route_sel_o, // One-hot route (unicast), for multicast this is not one-hot.
  output logic [$clog2(NumRoutes)-1:0]  rep_coeff_o
);

  logic [NumRoutes-1:0] route_sel, route_sel_mcast, route_res;
  logic mcast_flag;
  assign mcast_flag = (channel_i.hdr.mcast_flag && RouteAlgo == XYRouting);
  // int NumDst = $countones(channel_i.hdr.dst_mask_id);
  // assign num_dst_o = NumDst;

  if (RouteAlgo == IdIsPort) begin : gen_id_is_port
    // Routing assuming the ID is the port to be taken

    for (genvar out_route=0; out_route<NumRoutes; out_route++) begin
      assign channel_o[out_route] = channel_i;
    end

    // One-hot encoding of the decoded route
    always_comb begin : proc_route_sel
      rep_coeff_o = '0;
      route_sel = '0;
      // if (channel_i.hdr.mcast_flag) begin
      //   route_sel 
      // end else begin
      //   route_sel[channel_i.hdr.dst_id] = 1'b1; // Here multicast dst_mask needs changing.
      // end
      route_sel[channel_i.hdr.dst_id] = 1'b1;      
    end

  end else if (RouteAlgo == IdTable) begin : gen_id_table
    // Routing based on an ID table passed into the router (TBD parameter or signal)
    // Assumes an ID field present in the flit_t

    typedef logic [$clog2(NumRoutes)-1:0] out_id_t;
    out_id_t out_id;

    for (genvar out_route=0; out_route<NumRoutes; out_route++) begin
      assign channel_o[out_route] = channel_i;
    end
    
    addr_decode #(
      .NoIndices ( NumRoutes    ),
      .NoRules   ( NumAddrRules ),
      .addr_t    ( id_t         ),
      .rule_t    ( addr_rule_t  ),
      .Napot     ( 0            )
    ) i_id_decode (
      .addr_i           ( channel_i.hdr.dst_id  ),
      .addr_map_i       ( id_route_map_i    ),
      .idx_o            ( out_id            ),
      .dec_valid_o      (),
      .dec_error_o      (),
      .default_idx_i    ('0),
      .en_default_idx_i ('0)
    );

    // One-hot encoding of the decoded route
    always_comb begin : proc_route_sel
      rep_coeff_o = '0;
      route_sel = '0;
      route_sel[out_id] = 1'b1;
    end

  end else if (RouteAlgo == SourceRouting) begin : gen_consumption
    // Routing based on a consumable header in the flit
    always_comb begin : proc_route_sel
      rep_coeff_o = '0;
      route_sel = '0;
      route_sel[channel_i.hdr.dst_id[RouteSelWidth-1:0]] = 1'b1;
      for (int unsigned out_route=0; out_route<NumRoutes; out_route++) begin
        channel_o[out_route] = channel_i;
        channel_o[out_route].hdr.dst_id = channel_i.hdr.dst_id >> RouteSelWidth;
      end      
    end

  end else if (RouteAlgo == XYRouting) begin : gen_xy_routing
    // Routing based on simple XY routing
    // Assumes an even-bit ID field in the flit_t used for xy
    // assert ((IdWidth/2)*2 == IdWidth);
    // assert (NumRoutes == 5);

    // Port map:
    //   - 0: target/destination
    //   - 1: upper bits decreasing (South)
    //   - 2: lower bits decreasing (West )
    //   - 3: upper bits increasing (North)
    //   - 4: lower bits increasing (East )

    // One-hot encoding of the decoded route

    id_t id_in;
    assign id_in = id_t'(channel_i.hdr.dst_id);
    
    // id_t [3:0] id_in_mask;
  
    mcast_dst_conversion # (
      .NumRoutes(NumRoutes),
      .Mesh(Mesh)
    ) i_mcast_dst_conversion (
      .mask_i(channel_i.hdr.dst_mask_id),
      .xy_id_i    (xy_id_i),
      .src_id_i   (channel_i.hdr.src_id),
      .route_sel_o(route_sel_mcast)
    );

    always_comb begin
      rep_coeff_o = '0;
      for (int unsigned out_route = 0; out_route < NumRoutes; out_route++) begin
        rep_coeff_o += route_sel_mcast[out_route];
      end
    end

    always_comb begin : proc_route_sel
      route_sel = '0;
      // if (id_in.x=='0 && id_in.y=='0) begin
      if (~valid_i) begin
        route_sel = '0;
      end else if (id_in == xy_id_i) begin
        route_sel[Eject] = 1'b1;
      end else if (id_in.x == xy_id_i.x) begin
        if (id_in.y < xy_id_i.y) begin
          route_sel[South] = 1'b1;
        end else begin
          route_sel[North] = 1'b1;
        end
      end else begin
        if (id_in.x < xy_id_i.x) begin
          route_sel[West] = 1'b1;
        end else begin
          route_sel[East] = 1'b1;
        end
      end            
    end

    if (Mesh) begin
      logic [NumXEP-1:0][SamNumRules-1:0] x_axis_mask = '0;
      logic [NumXEP-1:0][SamNumRules-1:0] x_axis_stair_mask = '0;
      logic [NumYEP-1:0][SamNumRules-1:0] y_axis_mask = '0;
      logic [NumYEP-1:0][SamNumRules-1:0] y_axis_stair_mask = '0;
      for (genvar x = 0; x < NumXEP; x++) begin
        always_comb begin
          x_axis_mask[x][(x+1)*NumYEP-1:x*NumYEP] = '1;
        end
      end
      always_comb begin
        x_axis_stair_mask[0] = x_axis_mask[0];
      end
      for (genvar x = 1; x < NumXEP; x++) begin
        always_comb begin
          x_axis_stair_mask[x] = x_axis_mask[x] | x_axis_stair_mask[x-1];
        end
      end 
      for (genvar y = 0; y < NumYEP; y++) begin
        for (genvar x = 0; x < NumXEP; x++) begin
          always_comb begin
            y_axis_mask[y][x*NumYEP+y] = 1'b1;
          end
        end
      end
      always_comb begin
        y_axis_stair_mask[0] = y_axis_mask[0];
      end
      for (genvar y = 1; y < NumYEP; y++) begin
        always_comb begin
          y_axis_stair_mask[y] = y_axis_mask[y] | y_axis_stair_mask[y-1];
        end
      end   


      for (genvar out_route = 0; out_route < NumRoutes; out_route++) begin
        always_comb begin : flit_replication  
          if (rep_coeff_o <= 1'b1 || out_route==Eject) begin
            channel_o[out_route] = channel_i;
          end else begin
            channel_o[out_route] = channel_i;
            if (out_route==East) begin
              channel_o[out_route].hdr.dst_mask_id = channel_i.hdr.dst_mask_id & ~x_axis_stair_mask[xy_id_i.x];
            end else if (out_route==West) begin
              channel_o[out_route].hdr.dst_mask_id = channel_i.hdr.dst_mask_id & x_axis_stair_mask[xy_id_i.x-1];
            end else if (out_route==North) begin
              // `ASSERT(NorthEndRouteNorth, xy_id_i.y<NumXEP-1)
              channel_o[out_route].hdr.dst_mask_id = channel_i.hdr.dst_mask_id & 
                                                    x_axis_mask[xy_id_i.x] &
                                                    ~y_axis_stair_mask[xy_id_i.y];
            end else begin
              // `ASSERT(SouthEndRouteSouth, xy_id_i.y>0)
              channel_o[out_route].hdr.dst_mask_id = channel_i.hdr.dst_mask_id & 
                                                    x_axis_mask[xy_id_i.x] &
                                                    y_axis_stair_mask[xy_id_i.y-1];
            end
          end
        end
      end   
    end else begin
      for (genvar out_route=0; out_route<NumRoutes; out_route++) begin
        assign channel_o[out_route] = channel_i;
      end 
    end 

  end else begin : gen_err
    // Unknown or unimplemented routing otherwise
    initial begin
      $fatal(1, "Routing algorithm unknown");
    end
  end

  assign route_res = (mcast_flag) ? route_sel_mcast : route_sel;

  if (LockRouting) begin : gen_lock
    logic locked_route_d, locked_route_q;
    logic [NumRoutes-1:0] route_sel_q;

    assign route_sel_o = locked_route_q ? route_sel_q : route_res;

    always_comb begin
      locked_route_d = locked_route_q;

      if (ready_i && valid_i) begin
        locked_route_d = ~channel_i.hdr.last;

      end
    end

    always @(posedge clk_i) begin
      if (ready_i && valid_i && locked_route_q && (route_sel_q != route_res))
        $warning("Mismatch in route selection!");
    end

    `FF(locked_route_q, locked_route_d, '0)
    `FFL(route_sel_q, route_res, ~locked_route_q, '0)

  end else begin : gen_no_lock
    assign route_sel_o = route_res;
  end

endmodule