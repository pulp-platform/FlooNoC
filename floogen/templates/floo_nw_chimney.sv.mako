<%! from floogen.utils import snake_to_camel, bool_to_sv %>\
<% actual_xy_id = ni.id - ni.routing.id_offset if ni.routing.id_offset is not None else ni.id %>\
<% has_narrow_sbr = ni.sbr_narrow_port is not None %>\
<% has_narrow_mgr = ni.mgr_narrow_port is not None %>\
<% has_wide_sbr = ni.sbr_wide_port is not None %>\
<% has_wide_mgr = ni.mgr_wide_port is not None %>\

floo_nw_chimney  #(
  .AxiCfgN(AxiCfgN),
  .AxiCfgW(AxiCfgW),
  .ChimneyCfgN(set_ports(ChimneyDefaultCfg, ${bool_to_sv(has_narrow_sbr)}, ${bool_to_sv(has_narrow_mgr)})),
  .ChimneyCfgW(set_ports(ChimneyDefaultCfg, ${bool_to_sv(has_wide_sbr)}, ${bool_to_sv(has_wide_mgr)})),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
% if ni.routing.route_algo.value == 'SourceRouting':
  .route_t (route_t),
% endif
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
% if has_narrow_mgr:
  .axi_narrow_in_req_t(${ni.mgr_narrow_port.type_name()}_req_t),
  .axi_narrow_in_rsp_t(${ni.mgr_narrow_port.type_name()}_rsp_t),
% endif
% if has_narrow_sbr:
  .axi_narrow_out_req_t(${ni.sbr_narrow_port.type_name()}_req_t),
  .axi_narrow_out_rsp_t(${ni.sbr_narrow_port.type_name()}_rsp_t),
% endif
% if has_wide_mgr:
  .axi_wide_in_req_t(${ni.mgr_wide_port.type_name()}_req_t),
  .axi_wide_in_rsp_t(${ni.mgr_wide_port.type_name()}_rsp_t),
% endif
% if has_wide_sbr:
  .axi_wide_out_req_t(${ni.sbr_wide_port.type_name()}_req_t),
  .axi_wide_out_rsp_t(${ni.sbr_wide_port.type_name()}_rsp_t),
% endif
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t),
  .floo_wide_t(floo_wide_t)
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
% if ni.routing.route_algo.value == 'XYRouting':
  .id_i             ( ${actual_xy_id.render()}    ),
% else:
  .id_i             ( id_t'(${ni.id.render()}) ),
% endif
% if ni.routing.route_algo.value == 'SourceRouting':
  .route_table_i    ( RoutingTables[${snake_to_camel(ni.name)}]  ),
% else:
  .route_table_i    ( '0                          ),
% endif
  .floo_req_o       ( ${ni.mgr_link.req_name()}   ),
  .floo_rsp_i       ( ${ni.mgr_link.rsp_name()}   ),
  .floo_wide_o      ( ${ni.mgr_link.wide_name()}  ),
  .floo_req_i       ( ${ni.sbr_link.req_name()}   ),
  .floo_rsp_o       ( ${ni.sbr_link.rsp_name()}   ),
  .floo_wide_i      ( ${ni.sbr_link.wide_name()}  )
);
