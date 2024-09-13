<%!
    import datetime
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

`include "axi/typedef.svh"

package floo_${noc.name}_noc_pkg;

  import floo_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

% if noc.routing.route_algo.value != "XYRouting":
  ${noc.render_ep_enum()}
% endif

  ${noc.routing.render_typedefs()}

% if noc.routing.use_id_table:
  ${noc.routing.sam.render(aw=noc.routing.addr_width)}
% else:
  localparam int unsigned NumSamRules = 1;
  typedef logic sam_rule_t;
  localparam sam_rule_t Sam = '0;
% endif

% if noc.routing.route_algo.value == "SourceRouting":
  ${noc.render_ni_tables()}
% endif

  ${noc.routing.render_route_cfg(name="RouteCfg")}

% for prot in noc.protocols:
  ${prot.render_typedefs()}
% endfor

  ${noc.routing.render_hdr_typedef()}
  ${noc.render_link_typedefs()}

endpackage

module floo_${noc.name}_noc
  import floo_pkg::*;
  import floo_${noc.name}_noc_pkg::*;
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
