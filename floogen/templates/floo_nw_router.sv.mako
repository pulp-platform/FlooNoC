<%!
    from floogen.model.routing import XYDirections, RouteAlgo
%>\
<% def camelcase(s):
  return ''.join(x.capitalize() or '_' for x in s.split('_'))
%>\
<% req_type = next(d for d in router.incoming if d is not None).req_type %>\
<% rsp_type = next(d for d in router.incoming if d is not None).rsp_type %>\
<% wide_type = next(d for d in router.incoming if d is not None).wide_type %>\
% if router.route_algo == RouteAlgo.ID:
${router.table.render()}
% endif

${req_type} [${len(router.incoming)-1}:0] ${router.name}_req_in;
${rsp_type} [${len(router.incoming)-1}:0] ${router.name}_rsp_out;
${req_type} [${len(router.outgoing)-1}:0] ${router.name}_req_out;
${rsp_type} [${len(router.outgoing)-1}:0] ${router.name}_rsp_in;
${wide_type} [${len(router.incoming)-1}:0] ${router.name}_wide_in;
${wide_type} [${len(router.outgoing)-1}:0] ${router.name}_wide_out;

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

% for i, link in enumerate(router.incoming):
  % if link is not None:
    assign ${router.name}_wide_in[${i}] = ${link.wide_name()};
  % else:
    assign ${router.name}_wide_in[${i}] = '0;
  % endif
% endfor

% for i, link in enumerate(router.outgoing):
  % if link is not None:
    assign ${link.wide_name()} = ${router.name}_wide_out[${i}];
  % endif
% endfor

floo_nw_router #(
  .AxiCfgN(AxiCfgN),
  .AxiCfgW(AxiCfgW),
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
  .floo_rsp_t(floo_rsp_t),
  .floo_wide_t(floo_wide_t)
) ${router.name} (
  .clk_i,
  .rst_ni,
  .test_enable_i,
% if router.route_algo == RouteAlgo.XY:
  .id_i (${router.id.render()}),
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
  .floo_rsp_i (${router.name}_rsp_in),
  .floo_wide_i (${router.name}_wide_in),
  .floo_wide_o (${router.name}_wide_out)
);
