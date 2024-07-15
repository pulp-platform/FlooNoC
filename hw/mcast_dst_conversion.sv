module mcast_dst_conversion
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
#(
  parameter int unsigned NumRoutes = 0,
  parameter bit          Mesh      = 1'b1
) (
  input select_t mask_i,
  input id_t xy_id_i,
  input id_t src_id_i,
  // output id_t [NumDst-1:0] dst_o,
  output logic [NumRoutes-1:0] route_sel_o
  // output logic [NumDst-1:0][4:0] routes_onehot_o,
  // output logic [NumDst-1:0]
);

  id_t [SamNumRules-1:0] id_in_mcast;
  logic [SamNumRules-1:0][NumRoutes-1:0] routes;

  id_t [4:0] id_lut = '{
    '{x: 0, y: 0}, // idle position
    '{x: 0, y: 1},
    '{x: 1, y: 0},
    '{x: 2, y: 1}, 
    '{x: 1, y: 2}
  };

  assign route_sel_o = (Mesh) ?
                       routes[15] | routes[14] | routes[13] | routes[12] |
                       routes[11] | routes[10] | routes[9] | routes[8] |
                       routes[7] | routes[6] | routes[5] | routes[4] |
                       routes[3] | routes[2] | routes[1] | routes[0] :
                       routes[3] | routes[2] | routes[1] | routes[0];

  for (genvar i = 0; i < SamNumRules; i++) begin
    always_comb begin
      if (Mesh) begin
        id_in_mcast[i] = (mask_i[i]) ? Sam[SamNumRules-1-i].idx : '{x:0, y:0};
      end else begin
        id_in_mcast[i] = (mask_i[i]) ? id_lut[i] : id_lut[SamNumRules];
      end
      routes[i] = '0;
      if (mask_i[i] && (id_in_mcast[i] != src_id_i)) begin
        if (id_in_mcast[i] == xy_id_i) begin
          routes[i][Eject] = 1'b1;
          // routes_onehot_o[i] = 5'b00001;
        end else if (id_in_mcast[i].x == xy_id_i.x) begin
          if (id_in_mcast[i].y < xy_id_i.y) begin
            routes[i][South] = 1'b1;
            // routes_onehot_o[i] = 5'b01000;
          end else begin
            routes[i][North] = 1'b1;
            // routes_onehot_o[i] = 5'b00010;
          end
        end else begin
          if (id_in_mcast[i].x < xy_id_i.x) begin
            routes[i][West] = 1'b1;
            // routes_onehot_o[i] = 5'b10000;
          end else begin
            routes[i][East] = 1'b1;
            // routes_onehot_o[i] = 5'b00100;
          end
        end
      end
    end
  end  	

endmodule