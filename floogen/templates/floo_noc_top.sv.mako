<%!
    import datetime
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module ${noc.name}_floo_noc
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  ${noc.render_ports()}
);

% if noc.routing.use_id_table:
  % if noc.routing.route_algo.value == "IdTable":
  ${noc.routing.table.render(name=noc.name, aw=48)}
  % elif noc.routing.route_algo.value == "XYRouting":
  ${noc.routing.table.render(name=noc.name, aw=48, id_offset=noc.routing.id_offset)}
  % endif
% endif

${noc.render_links()}
${noc.render_nis()}
${noc.render_routers()}

endmodule
