// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead

`include "axi/typedef.svh"

package floo_${name}_pkg;

  import floo_pkg::*;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

  ${link.render_enum_decl()}

% for prot in noc.protocols:
  ${prot.render_params()}
% endfor
% for prot in noc.protocols:
  ${prot.render_typedefs()}
% endfor

  /////////////////////////
  //   Header Typedefs   //
  /////////////////////////

  ${noc.routing.render_param_decl()}

  ${noc.routing.render_typedefs()}

  ${noc.routing.render_flit_header()}

  /////////////////////
  //   Address Map   //
  /////////////////////

% if noc.routing.use_id_table:
  ${noc.routing.table.render(name="addr_map", aw=noc.routing.addr_width, id_offset=noc.routing.id_offset)}
% else:
  typedef logic addr_map_rule_t;
  localparam int unsigned AddrMapNumRules = 0;
  localparam addr_map_rule_t AddrMap = '0;
% endif

  ////////////////////////
  //   Flits Typedefs   //
  ////////////////////////

  ${link.render_flit(noc.protocols)}

  //////////////////////////
  //   Channel Typedefs   //
  //////////////////////////

  ${link.render_channels()}

  ///////////////////////
  //   Link Typedefs   //
  ///////////////////////

  ${link.render_link_typedefs()}
endpackage
