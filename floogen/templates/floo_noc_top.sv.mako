<%!
    import datetime
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

package ${noc.name}_floo_noc_pkg;

  import floo_narrow_wide_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

% if noc.routing.route_algo.value != "XYRouting":
  ${noc.render_ep_enum()}
% endif

% if noc.routing.use_id_table:
  ${noc.routing.sam.render(aw=noc.routing.addr_width)}
% else:
  localparam int unsigned SamNumRules = 1;
  typedef logic sam_rule_t;
  localparam sam_rule_t Sam = '0;
% endif

% if noc.routing.route_algo.value == "SourceRouting":
  ${noc.render_ni_tables()}
% endif

endpackage

module ${noc.name}_floo_noc
  import floo_pkg::*;
  import floo_narrow_wide_pkg::*;
  import ${noc.name}_floo_noc_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  ${noc.render_ports()}
);

${noc.render_links()}
${noc.render_nis()}
${noc.render_routers()}

endmodule
