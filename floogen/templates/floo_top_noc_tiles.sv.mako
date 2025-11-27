<%!
    import datetime
    from floogen.utils import snake_to_camel, bool_to_sv
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module floo_${noc.name}_noc
  import floo_pkg::*;
  import floo_${noc.name}_noc_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  ${noc.render_ports()}
);

<%
# Get mesh dimensions from the router configuration
router_desc = noc.routers[0]
if router_desc.array is not None and len(router_desc.array) == 2:
    x_max = router_desc.array[0]
    y_max = router_desc.array[1]
else:
    x_max = 1
    y_max = 1

in_prot = next((prot for prot in noc.protocols if prot.direction == "input"), None)
out_prot = next((prot for prot in noc.protocols if prot.direction == "output"), None)

# Get endpoint name for port mapping
ep_name = noc.endpoints[0].name
%>\

  // Mesh dimensions: ${x_max} x ${y_max}
  localparam int unsigned NumX = ${x_max};
  localparam int unsigned NumY = ${y_max};

  // Inter-tile links (horizontal: East-West)
  // Link from tile[x][y] going East to tile[x+1][y]
  floo_req_t [NumX-2:0][NumY-1:0] ew_req;  // East-bound requests
  floo_rsp_t [NumX-2:0][NumY-1:0] ew_rsp;  // East-bound responses
  floo_req_t [NumX-2:0][NumY-1:0] we_req;  // West-bound requests
  floo_rsp_t [NumX-2:0][NumY-1:0] we_rsp;  // West-bound responses

  // Inter-tile links (vertical: North-South)
  // Link from tile[x][y] going North to tile[x][y+1]
  floo_req_t [NumX-1:0][NumY-2:0] ns_req;  // North-bound requests
  floo_rsp_t [NumX-1:0][NumY-2:0] ns_rsp;  // North-bound responses
  floo_req_t [NumX-1:0][NumY-2:0] sn_req;  // South-bound requests
  floo_rsp_t [NumX-1:0][NumY-2:0] sn_rsp;  // South-bound responses

  // Generate tile instances
  for (genvar x = 0; x < NumX; x++) begin : gen_x
    for (genvar y = 0; y < NumY; y++) begin : gen_y

      // Local coordinate for this tile
      id_t tile_id;
      assign tile_id = '{x: x, y: y, port_id: 0};

      // Tile neighbor connections (directly connected without gating)
      floo_req_t north_req_out, north_req_in;
      floo_rsp_t north_rsp_out, north_rsp_in;
      floo_req_t east_req_out, east_req_in;
      floo_rsp_t east_rsp_out, east_rsp_in;
      floo_req_t south_req_out, south_req_in;
      floo_rsp_t south_rsp_out, south_rsp_in;
      floo_req_t west_req_out, west_req_in;
      floo_rsp_t west_rsp_out, west_rsp_in;

      // North connections
      if (y < NumY - 1) begin : gen_north_conn
        assign ns_req[x][y] = north_req_out;
        assign ns_rsp[x][y] = north_rsp_out;
        assign north_req_in = sn_req[x][y];
        assign north_rsp_in = sn_rsp[x][y];
      end else begin : gen_north_edge
        assign north_req_in = '0;
        assign north_rsp_in = '0;
      end

      // South connections
      if (y > 0) begin : gen_south_conn
        assign sn_req[x][y-1] = south_req_out;
        assign sn_rsp[x][y-1] = south_rsp_out;
        assign south_req_in = ns_req[x][y-1];
        assign south_rsp_in = ns_rsp[x][y-1];
      end else begin : gen_south_edge
        assign south_req_in = '0;
        assign south_rsp_in = '0;
      end

      // East connections
      if (x < NumX - 1) begin : gen_east_conn
        assign ew_req[x][y] = east_req_out;
        assign ew_rsp[x][y] = east_rsp_out;
        assign east_req_in = we_req[x][y];
        assign east_rsp_in = we_rsp[x][y];
      end else begin : gen_east_edge
        assign east_req_in = '0;
        assign east_rsp_in = '0;
      end

      // West connections
      if (x > 0) begin : gen_west_conn
        assign we_req[x-1][y] = west_req_out;
        assign we_rsp[x-1][y] = west_rsp_out;
        assign west_req_in = ew_req[x-1][y];
        assign west_rsp_in = ew_rsp[x-1][y];
      end else begin : gen_west_edge
        assign west_req_in = '0;
        assign west_rsp_in = '0;
      end

      // Tile instantiation
      floo_${noc.name}_tile #(
        .EnSbrPort ( 1'b1 ),
        .EnMgrPort ( 1'b1 )
      ) i_tile (
        .clk_i,
        .rst_ni,
        .test_enable_i,
        .id_i            ( tile_id ),
% if in_prot is not None:
        .axi_in_req_i    ( ${ep_name}_axi_in_req_i[x][y] ),
        .axi_in_rsp_o    ( ${ep_name}_axi_in_rsp_o[x][y] ),
% endif
% if out_prot is not None:
        .axi_out_req_o   ( ${ep_name}_axi_out_req_o[x][y] ),
        .axi_out_rsp_i   ( ${ep_name}_axi_out_rsp_i[x][y] ),
% endif
        .floo_north_req_o( north_req_out ),
        .floo_north_rsp_o( north_rsp_out ),
        .floo_north_req_i( north_req_in  ),
        .floo_north_rsp_i( north_rsp_in  ),
        .floo_east_req_o ( east_req_out  ),
        .floo_east_rsp_o ( east_rsp_out  ),
        .floo_east_req_i ( east_req_in   ),
        .floo_east_rsp_i ( east_rsp_in   ),
        .floo_south_req_o( south_req_out ),
        .floo_south_rsp_o( south_rsp_out ),
        .floo_south_req_i( south_req_in  ),
        .floo_south_rsp_i( south_rsp_in  ),
        .floo_west_req_o ( west_req_out  ),
        .floo_west_rsp_o ( west_rsp_out  ),
        .floo_west_req_i ( west_req_in   ),
        .floo_west_rsp_i ( west_rsp_in   )
      );

    end // gen_y
  end // gen_x

endmodule
