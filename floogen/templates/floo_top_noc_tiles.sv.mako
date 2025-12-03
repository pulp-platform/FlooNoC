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

      // Direction-indexed arrays for tile ports (North=0, East=1, South=2, West=3)
      floo_req_t [West:North] tile_req_out, tile_req_in;
      floo_rsp_t [West:North] tile_rsp_out, tile_rsp_in;

      // North connections
      if (y < NumY - 1) begin : gen_north_conn
        assign ns_req[x][y] = tile_req_out[North];
        assign ns_rsp[x][y] = tile_rsp_out[North];
        assign tile_req_in[North] = sn_req[x][y];
        assign tile_rsp_in[North] = sn_rsp[x][y];
      end else begin : gen_north_edge
        assign tile_req_in[North] = '0;
        assign tile_rsp_in[North] = '0;
      end

      // South connections
      if (y > 0) begin : gen_south_conn
        assign sn_req[x][y-1] = tile_req_out[South];
        assign sn_rsp[x][y-1] = tile_rsp_out[South];
        assign tile_req_in[South] = ns_req[x][y-1];
        assign tile_rsp_in[South] = ns_rsp[x][y-1];
      end else begin : gen_south_edge
        assign tile_req_in[South] = '0;
        assign tile_rsp_in[South] = '0;
      end

      // East connections
      if (x < NumX - 1) begin : gen_east_conn
        assign ew_req[x][y] = tile_req_out[East];
        assign ew_rsp[x][y] = tile_rsp_out[East];
        assign tile_req_in[East] = we_req[x][y];
        assign tile_rsp_in[East] = we_rsp[x][y];
      end else begin : gen_east_edge
        assign tile_req_in[East] = '0;
        assign tile_rsp_in[East] = '0;
      end

      // West connections
      if (x > 0) begin : gen_west_conn
        assign we_req[x-1][y] = tile_req_out[West];
        assign we_rsp[x-1][y] = tile_rsp_out[West];
        assign tile_req_in[West] = ew_req[x-1][y];
        assign tile_rsp_in[West] = ew_rsp[x-1][y];
      end else begin : gen_west_edge
        assign tile_req_in[West] = '0;
        assign tile_rsp_in[West] = '0;
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
        .floo_req_o      ( tile_req_out ),
        .floo_rsp_o      ( tile_rsp_out ),
        .floo_req_i      ( tile_req_in  ),
        .floo_rsp_i      ( tile_rsp_in  )
      );

    end // gen_y
  end // gen_x

endmodule
