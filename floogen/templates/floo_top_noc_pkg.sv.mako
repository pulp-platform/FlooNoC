<%!
    import datetime
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_${noc.name}_noc_pkg;

  import floo_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

  ${noc.render_ep_enum()}

  ${noc.render_sam_idx_enum()}

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

  ${noc.routing.render_hdr_typedef(network_type=noc.network_type)}
  ${noc.render_link_typedefs()}

endpackage
