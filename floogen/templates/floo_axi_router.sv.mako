<%!
    from floogen.model.routing import XYDirections, RouteAlgo
%>\
<% def camelcase(s):
  return ''.join(x.capitalize() or '_' for x in s.split('_'))
%>\
<% offset_xy_id = router.id - network.routing.xy_id_offset if network.routing.xy_id_offset is not None else router.id %>\
<% req_type = next(d for d in router.incoming if d is not None).req_type %>\
<% rsp_type = next(d for d in router.incoming if d is not None).rsp_type %>\
% if router.route_algo == RouteAlgo.ID:
${router.table.render()}
% endif

${req_type} [${len(router.incoming)-1}:0] ${router.name}_req_in;
${rsp_type} [${len(router.incoming)-1}:0] ${router.name}_rsp_out;
${req_type} [${len(router.outgoing)-1}:0] ${router.name}_req_out;
${rsp_type} [${len(router.outgoing)-1}:0] ${router.name}_rsp_in;

% for i, link in enumerate(router.incoming):
  % if link is not None:
    assign ${router.name}_req_in[${i}] = ${link.req_name()};
  % else:
    assign ${router.name}_req_in[${i}] = '0;
  % endif
% endfor

% for i, link in enumerate(router.incoming):
  % if link is not None:
    assign ${link.rsp_name()} = ${router.name}_rsp_out[${i}];
  % endif
% endfor

% for i, link in enumerate(router.outgoing):
  % if link is not None:
    assign ${link.req_name()} = ${router.name}_req_out[${i}];
  % endif
% endfor

% for i, link in enumerate(router.outgoing):
  % if link is not None:
    assign ${router.name}_rsp_in[${i}] = ${link.rsp_name()};
  % else:
    assign ${router.name}_rsp_in[${i}] = '0;
  % endif
% endfor

% if router.route_algo == RouteAlgo.XY:
  localparam id_t ${router.name.upper()}_ID = ${offset_xy_id.render()};
% endif

floo_axi_router #(
  .AxiCfg(AxiCfg),
  .RouteAlgo (${router.route_algo.value}),
  .NumRoutes (${router.degree}),
  .NumInputs (${len(router.incoming)}),
  .NumOutputs (${len(router.outgoing)}),
  .InFifoDepth (2),
  .OutFifoDepth (2),
  .id_t(id_t),
  .hdr_t(hdr_t),
% if router.route_algo == RouteAlgo.ID:
  .NumAddrRules (${len(router.table.rules)}),
  .addr_rule_t (${router.name}_map_rule_t),
% endif
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) ${router.name} (
  .clk_i,
  .rst_ni,
  .test_enable_i,
% if router.route_algo == RouteAlgo.XY:
  .id_i (${router.name.upper()}_ID),
% else:
  .id_i ('0),
% endif
% if router.route_algo == RouteAlgo.ID:
  .id_route_map_i (${camelcase(router.name + "_map")}),
% else:
  .id_route_map_i ('0),
% endif
  .floo_req_i (${router.name}_req_in),
  .floo_rsp_o (${router.name}_rsp_out),
  .floo_req_o (${router.name}_req_out),
  .floo_rsp_i (${router.name}_rsp_in)
);
