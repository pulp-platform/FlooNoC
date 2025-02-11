<%! from floogen.utils import snake_to_camel, bool_to_sv %>\
<% actual_xy_id = ni.id - ni.routing.xy_id_offset if ni.routing.xy_id_offset is not None else ni.id %>\
<% narrow_in_prot = next((prot for prot in noc.protocols if prot.type == "narrow" and prot.direction == "input"), None) %>\
<% narrow_out_prot = next((prot for prot in noc.protocols if prot.type == "narrow" and prot.direction == "output"), None) %>\
<% wide_in_prot = next((prot for prot in noc.protocols if prot.type == "wide" and prot.direction == "input"), None) %>\
<% wide_out_prot = next((prot for prot in noc.protocols if prot.type == "wide" and prot.direction == "output"), None) %>\

% if ni.routing.route_algo.value == 'XYRouting':
  localparam id_t ${ni.name.upper()}_ID = ${actual_xy_id.render()};
% else:
  localparam id_t ${ni.name.upper()}_ID = id_t'(${ni.id.render()});
% endif

floo_nw_chimney  #(
  .AxiCfgN(AxiCfgN),
  .AxiCfgW(AxiCfgW),
  .ChimneyCfgN(set_ports(ChimneyDefaultCfg, ${bool_to_sv(ni.sbr_narrow_port != None)}, ${bool_to_sv(ni.mgr_narrow_port != None)})),
  .ChimneyCfgW(set_ports(ChimneyDefaultCfg, ${bool_to_sv(ni.sbr_wide_port != None)}, ${bool_to_sv(ni.mgr_wide_port != None)})),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
% if ni.routing.route_algo.value == 'SourceRouting':
  .route_t (route_t),
  .dst_t   (route_t),
% endif
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_narrow_in_req_t(${narrow_in_prot.type_name()}_req_t),
  .axi_narrow_in_rsp_t(${narrow_in_prot.type_name()}_rsp_t),
  .axi_narrow_out_req_t(${narrow_out_prot.type_name()}_req_t),
  .axi_narrow_out_rsp_t(${narrow_out_prot.type_name()}_rsp_t),
  .axi_wide_in_req_t(${wide_in_prot.type_name()}_req_t),
  .axi_wide_in_rsp_t(${wide_in_prot.type_name()}_rsp_t),
  .axi_wide_out_req_t(${wide_out_prot.type_name()}_req_t),
  .axi_wide_out_rsp_t(${wide_out_prot.type_name()}_rsp_t),
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
  .id_i             ( ${ni.name.upper()}_ID       ),
% if ni.routing.route_algo.value == 'SourceRouting':
  .route_table_i    ( RoutingTables[${snake_to_camel(ni.render_enum_name())}]  ),
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
