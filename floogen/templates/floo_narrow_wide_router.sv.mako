<% def camelcase(s):
  return ''.join(x.capitalize() or '_' for x in s.split('_'))
%>\
% if router.route_algo == 'IdTable':
${router.table.render(name=router.name + "_table")}
% endif

${router.incoming[0].req_type} [${len(router.incoming)-1}:0] ${router.name}_req_in;
${router.incoming[0].rsp_type} [${len(router.incoming)-1}:0] ${router.name}_rsp_out;
${router.outgoing[0].req_type} [${len(router.outgoing)-1}:0] ${router.name}_req_out;
${router.outgoing[0].rsp_type} [${len(router.outgoing)-1}:0] ${router.name}_rsp_in;
${router.incoming[0].wide_type} [${len(router.incoming)-1}:0] ${router.name}_wide_in;
${router.outgoing[0].wide_type} [${len(router.outgoing)-1}:0] ${router.name}_wide_out;

% for i, link in enumerate(router.incoming):
  assign ${router.name}_req_in[${i}] = ${link.req_name()};
% endfor

% for i, link in enumerate(router.incoming):
  assign ${link.rsp_name()} = ${router.name}_rsp_out[${i}];
% endfor

% for i, link in enumerate(router.outgoing):
  assign ${link.req_name()} = ${router.name}_req_out[${i}];
% endfor

% for i, link in enumerate(router.outgoing):
  assign ${router.name}_rsp_in[${i}] = ${link.rsp_name()};
% endfor

% for i, link in enumerate(router.incoming):
  assign ${router.name}_wide_in[${i}] = ${link.wide_name()};
% endfor

% for i, link in enumerate(router.outgoing):
  assign ${link.wide_name()} = ${router.name}_wide_out[${i}];
% endfor

floo_narrow_wide_router #(
  .NumRoutes (${router.degree}),
  .NumInputs (${len(router.incoming)}),
  .NumOutputs (${len(router.outgoing)}),
  .ChannelFifoDepth (2),
  .OutputFifoDepth (2),
  .id_t(id_t),
% if router.route_algo == 'IdTable':
  .NumAddrRules (${len(router.table.rules)}),
  .addr_rule_t (${router.name}_table_rule_t)
% endif
  .RouteAlgo (${router.route_algo.value})
) ${router.name} (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i ('0),
% if router.route_algo == 'IdTable':
  .id_route_map_i (${camelcase(router.name + "_table")}),
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
