// Chen Wu

module floo_route_xymask import floo_pkg::*;
# (
  parameter int unsigned NumRoutes     = 0,
  parameter type         flit_t        = logic,
  parameter type         id_t          = logic,
  /// Mode 1 for deciding the output directions, Mode 0 for spefifying the expected input directions 
  parameter bit          Mode          = 1
) (
  input  flit_t                         channel_i,
  input  id_t                           xy_id_i,
  output logic [NumRoutes-1:0]          route_sel_o
);

  logic [NumRoutes-1:0] route_sel;
  
  id_t dst_id, mask_in, src_id;
  id_t dst_id_max, dst_id_min;
  logic x_matched, y_matched;

  assign dst_id = Mode? id_t'(channel_i.hdr.dst_id) : id_t'(channel_i.hdr.src_id);
  assign mask_in = Mode? (channel_i.hdr.commtype==CollectB? '0 : id_t'(channel_i.hdr.mask)) : id_t'(channel_i.hdr.mask);
  assign src_id = Mode? id_t'(channel_i.hdr.src_id) : id_t'(channel_i.hdr.dst_id);
  
  assign dst_id_max.x = dst_id.x | mask_in.x;
  assign dst_id_max.y = dst_id.y | mask_in.y;
  assign dst_id_min.x = dst_id.x & (~mask_in.x);
  assign dst_id_min.y = dst_id.y & (~mask_in.y);

  assign x_matched = &(mask_in.x | ~(xy_id_i.x ^ dst_id.x));
  assign y_matched = &(mask_in.y | ~(xy_id_i.y ^ dst_id.y));

  always_comb begin
    route_sel = '0;
    if (Mode) begin : decide_output
      if (x_matched && y_matched) begin
        route_sel[Eject] = 1;
      end
      if (xy_id_i.y == src_id.y) begin
        if (xy_id_i.x >= src_id.x && xy_id_i.x < dst_id_max.x) begin
          route_sel[East] = 1;
        end
        if (xy_id_i.x <= src_id.x && xy_id_i.x > dst_id_min.x) begin
          route_sel[West] = 1;
        end
      end
      if (x_matched) begin
        if (xy_id_i.y >= src_id.y && xy_id_i.y < dst_id_max.y) begin
          route_sel[North] = 1;
        end
        if (xy_id_i.y <= src_id.y && xy_id_i.y > dst_id_min.y) begin
          route_sel[South] = 1;
        end
      end
    end
    else begin : specify_input
      if (x_matched && y_matched) begin
        route_sel[Eject] = 1;
      end
      if (xy_id_i.x == src_id.x) begin
        if (xy_id_i.y >= src_id.y && xy_id_i.y < dst_id_max.y) begin
          route_sel[North] = 1;
        end
        if (xy_id_i.y <= src_id.y && xy_id_i.y > dst_id_min.y) begin
          route_sel[South] = 1;
        end
      end
      if (y_matched) begin
        if (xy_id_i.x >= src_id.x && xy_id_i.x < dst_id_max.x) begin
          route_sel[East] = 1;
        end
        if (xy_id_i.x <= src_id.x && xy_id_i.x > dst_id_min.x) begin
          route_sel[West] = 1;
        end
      end
    end
  end
  assign route_sel_o = route_sel;
endmodule