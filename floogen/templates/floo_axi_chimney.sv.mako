<%! from floogen.utils import snake_to_camel, bool_to_sv %>\
<% actual_xy_id = ni.id - ni.routing.xy_id_offset if ni.routing.xy_id_offset is not None else ni.id %>\
<% in_prot = next((prot for prot in noc.protocols if prot.direction == "input"), None) %>\
<% out_prot = next((prot for prot in noc.protocols if prot.direction == "output"), None) %>\

% if ni.routing.route_algo.value == 'XYRouting':
  localparam id_t ${ni.name.upper()}_ID = ${actual_xy_id.render()};
% else:
  localparam id_t ${ni.name.upper()}_ID = id_t'(${ni.id.render()});
% endif

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, ${bool_to_sv(ni.sbr_port != None)}, ${bool_to_sv(ni.mgr_port != None)})),
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
  .axi_in_req_t(${in_prot.type_name()}_req_t),
  .axi_in_rsp_t(${in_prot.type_name()}_rsp_t),
  .axi_out_req_t(${out_prot.type_name()}_req_t),
  .axi_out_rsp_t(${out_prot.type_name()}_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) ${ni.name} (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
% if ni.mgr_port is not None:
  .axi_in_req_i  ( ${ni.mgr_port.req_name(port=True, idx=True)} ),
  .axi_in_rsp_o  ( ${ni.mgr_port.rsp_name(port=True, idx=True)} ),
% else:
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
% endif
% if ni.sbr_port is not None:
  .axi_out_req_o ( ${ni.sbr_port.req_name(port=True, idx=True)} ),
  .axi_out_rsp_i ( ${ni.sbr_port.rsp_name(port=True, idx=True)} ),
% else:
  .axi_out_req_o (    ),
  .axi_out_rsp_i ( '0 ),
% endif
  .id_i             ( ${ni.name.upper()}_ID       ),
% if ni.routing.route_algo.value == 'SourceRouting':
  .route_table_i    ( RoutingTables[${snake_to_camel(ni.render_enum_name())}]  ),
% else:
  .route_table_i    ( '0                          ),
% endif
  .floo_req_o       ( ${ni.mgr_link.req_name()}   ),
  .floo_rsp_i       ( ${ni.mgr_link.rsp_name()}   ),
  .floo_req_i       ( ${ni.sbr_link.req_name()}   ),
  .floo_rsp_o       ( ${ni.sbr_link.rsp_name()}   )
);
