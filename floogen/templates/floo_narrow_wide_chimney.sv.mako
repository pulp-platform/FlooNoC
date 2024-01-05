<%def name="int2hex(val, width)">
  <% return f"{width}\'h{val:0{width//4}x}" %>
</%def>\
<% actual_xy_id = ni.id - ni.routing.id_offset if ni.routing.id_offset is not None else ni.id %>\

floo_narrow_wide_chimney  #(
% if ni.sbr_narrow_port is None:
  .EnNarrowSbrPort(1'b0),
% endif
% if ni.mgr_narrow_port is None:
  .EnNarrowMgrPort(1'b0),
% endif
% if ni.sbr_wide_port is None:
  .EnWideSbrPort(1'b0),
% endif
% if ni.mgr_wide_port is None:
  .EnWideMgrPort(1'b0),
% endif
  .RouteAlgo(${ni.routing.route_algo.value}),
% if ni.routing.use_id_table:
  .id_t(id_t),
  .id_rule_t(${noc.name}_table_rule_t),
  .NumIDs(${noc.routing.num_endpoints}),
  .NumRules(${len(ni.routing.table)})
% elif ni.routing.route_algo.value == 'XYRouting':
  .XYAddrOffsetX(${ni.routing.addr_offset_bits}),
  .XYAddrOffsetY(${ni.routing.addr_offset_bits + ni.routing.num_x_bits}),
  .id_t(xy_id_t)
% endif
) ${ni.name} (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
% if ni.mgr_narrow_port is not None:
  .axi_narrow_in_req_i  ( ${ni.mgr_narrow_port.req_name(port=True, idx=True)} ),
  .axi_narrow_in_rsp_o  ( ${ni.mgr_narrow_port.rsp_name(port=True, idx=True)} ),
% else:
  .axi_narrow_in_req_i  ( '0 ),
  .axi_narrow_in_rsp_o  (    ),
% endif
% if ni.sbr_narrow_port is not None:
  .axi_narrow_out_req_o ( ${ni.sbr_narrow_port.req_name(port=True, idx=True)} ),
  .axi_narrow_out_rsp_i ( ${ni.sbr_narrow_port.rsp_name(port=True, idx=True)} ),
% else:
  .axi_narrow_out_req_o (    ),
  .axi_narrow_out_rsp_i ( '0 ),
% endif
% if ni.mgr_wide_port is not None:
  .axi_wide_in_req_i  ( ${ni.mgr_wide_port.req_name(port=True, idx=True)} ),
  .axi_wide_in_rsp_o  ( ${ni.mgr_wide_port.rsp_name(port=True, idx=True)} ),
% else:
  .axi_wide_in_req_i  ( '0 ),
  .axi_wide_in_rsp_o  (    ),
% endif
% if ni.sbr_wide_port is not None:
  .axi_wide_out_req_o ( ${ni.sbr_wide_port.req_name(port=True, idx=True)} ),
  .axi_wide_out_rsp_i ( ${ni.sbr_wide_port.rsp_name(port=True, idx=True)} ),
% else:
  .axi_wide_out_req_o (    ),
  .axi_wide_out_rsp_i ( '0 ),
% endif
% if ni.routing.use_id_table:
  .id_map_i         ( ${noc.name}_table             ),
% else:
  .id_map_i         ( '0                          ),
% endif
% if ni.routing.route_algo.value == 'XYRouting':
  .id_i             ( ${actual_xy_id.render()}    ),
% else:
  .id_i             ( ${ni.id.render()}                    ),
% endif
  .floo_req_o       ( ${ni.mgr_link.req_name()}   ),
  .floo_rsp_i       ( ${ni.mgr_link.rsp_name()}   ),
  .floo_wide_o      ( ${ni.mgr_link.wide_name()}  ),
  .floo_req_i       ( ${ni.sbr_link.req_name()}   ),
  .floo_rsp_o       ( ${ni.sbr_link.rsp_name()}   ),
  .floo_wide_i      ( ${ni.sbr_link.wide_name()}  )
);
