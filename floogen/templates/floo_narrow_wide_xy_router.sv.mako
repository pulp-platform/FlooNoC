<% def camelcase(s):
     return ''.join(x.capitalize() or '_' for x in s.split('_'))
%>\
<% req_type = next(d for d in router.incoming._asdict().values() if d is not None).req_type %>\
<% rsp_type = next(d for d in router.incoming._asdict().values() if d is not None).rsp_type %>\
<% wide_type = next(d for d in router.incoming._asdict().values() if d is not None).wide_type %>\

${req_type} [NumDirections-1:0] ${router.name}_req_in;
${rsp_type} [NumDirections-1:0] ${router.name}_rsp_out;
${req_type} [NumDirections-1:0] ${router.name}_req_out;
${rsp_type} [NumDirections-1:0] ${router.name}_rsp_in;
${wide_type} [NumDirections-1:0] ${router.name}_wide_in;
${wide_type} [NumDirections-1:0] ${router.name}_wide_out;

% for dir, link in router.incoming._asdict().items():
  assign ${router.name}_req_in[${camelcase(dir)}] = ${"'0" if link is None else link.req_name()};
% endfor

% for dir, link in router.incoming._asdict().items():
  % if link is not None:
  assign ${link.rsp_name()} = ${router.name}_rsp_out[${camelcase(dir)}];
  % endif
% endfor

% for dir, link in router.outgoing._asdict().items():
  % if link is not None:
  assign ${link.req_name()} = ${router.name}_req_out[${camelcase(dir)}];
  % endif
% endfor

% for dir, link in router.outgoing._asdict().items():
  assign ${router.name}_rsp_in[${camelcase(dir)}] = ${"'0" if link is None else link.rsp_name()};
% endfor

% for dir, link in router.incoming._asdict().items():
  assign ${router.name}_wide_in[${camelcase(dir)}] = ${"'0" if link is None else link.wide_name()};
% endfor

% for dir, link in router.outgoing._asdict().items():
  % if link is not None:
  assign ${link.wide_name()} = ${router.name}_wide_out[${camelcase(dir)}];
  % endif
% endfor

floo_narrow_wide_router #(
  .NumRoutes (NumDirections),
  .ChannelFifoDepth (2),
  .OutputFifoDepth (2),
  .RouteAlgo (XYRouting),
  .id_t(id_t)
) ${router.name} (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i (${router.id.render()}),
  .id_route_map_i ('0),
  .floo_req_i (${router.name}_req_in),
  .floo_rsp_o (${router.name}_rsp_out),
  .floo_req_o (${router.name}_req_out),
  .floo_rsp_i (${router.name}_rsp_in),
  .floo_wide_i (${router.name}_wide_in),
  .floo_wide_o (${router.name}_wide_out)
);
