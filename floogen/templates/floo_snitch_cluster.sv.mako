<% narrow_mgr_port = next(port for port in ep.mgr_ports if port.name == "narrow") %>\
<% wide_mgr_port = next(port for port in ep.mgr_ports if port.name == "wide") %>\
<% narrow_sbr_port = next(port for port in ep.sbr_ports if port.name == "narrow") %>\
<% wide_sbr_port = next(port for port in ep.sbr_ports if port.name == "wide") %>\
snitch_cluster_wrapper i_${ep.name} (
  .clk_i,
  .rst_ni,
  .debug_req_i('0),  // TODO: expose additional ports to the top-level
  .meip_i('0),  // TODO: expose additional ports to the top-level
  .mtip_i('0),  // TODO: expose additional ports to the top-level
  .msip_i('0),  // TODO: expose additional ports to the top-level
  .narrow_in_req_i(${narrow_mgr_port.req_name()}),
  .narrow_in_resp_o(${narrow_mgr_port.rsp_name()}),
  .narrow_out_req_o(${narrow_sbr_port.req_name()}),
  .narrow_out_resp_i(${narrow_sbr_port.rsp_name()}),
  .wide_out_req_o(${wide_mgr_port.req_name()}),
  .wide_out_resp_i(${wide_mgr_port.rsp_name()}),
  .wide_in_req_i(${wide_sbr_port.req_name()}),
  .wide_in_resp_o(${wide_sbr_port.rsp_name()})
);
