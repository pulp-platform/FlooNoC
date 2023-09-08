// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This file is auto-generated. Do not edit! Edit the template file instead

<% def list2array(values: list):
  return '{' + ', '.join([str(a) for a in values]) + '}'
%> \
<% def camelcase(word: str):
  return ''.join([w.capitalize() for w in word.split('_')])
%> \
<% def clog2(value: int):
  import math
  return int(math.ceil(math.log(value, 2)))
%> \
<%def zero_pad(values: list, length: int):
  return values + [0] * (length - len(values))
%> \
<%def short_dir(direction: str):
  return 'in' if direction == 'input' else 'out'
%> \
<%def prot_full_name(name: str, direction: str, prefix: str="axi_", **kwargs):
  prefix = '' if name in prefix else prefix
  return prefix + name + '_' + short_dir(direction)
%> \

`include "axi/typedef.svh"

package floo_${name}_pkg;

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

% for prot in protocols:
  localparam int unsigned ${camelcase(prot_full_name(**prot, prefix=''))}AddrWidth = ${prot['params']['aw']};
  localparam int unsigned ${camelcase(prot_full_name(**prot, prefix=''))}DataWidth = ${prot['params']['dw']};
  localparam int unsigned ${camelcase(prot_full_name(**prot, prefix=''))}IdWidth = ${prot['params']['iw']};
  localparam int unsigned ${camelcase(prot_full_name(**prot, prefix=''))}UserWidth = ${prot['params']['uw']};

% endfor
% for prot in protocols:
  typedef logic [${camelcase(prot_full_name(**prot, prefix=''))}AddrWidth-1:0] ${prot_full_name(**prot)}_addr_t;
  typedef logic [${camelcase(prot_full_name(**prot, prefix=''))}DataWidth-1:0] ${prot_full_name(**prot)}_data_t;
  typedef logic [${camelcase(prot_full_name(**prot, prefix=''))}DataWidth/8-1:0] ${prot_full_name(**prot)}_strb_t;
  typedef logic [${camelcase(prot_full_name(**prot, prefix=''))}IdWidth-1:0] ${prot_full_name(**prot)}_id_t;
  typedef logic [${camelcase(prot_full_name(**prot, prefix=''))}UserWidth-1:0] ${prot_full_name(**prot)}_user_t;

% endfor
% for prot in protocols:
  `AXI_TYPEDEF_ALL_CT(${prot_full_name(**prot)}, ${prot_full_name(**prot)}_req_t, ${prot_full_name(**prot)}_rsp_t, ${prot_full_name(**prot)}_addr_t, ${prot_full_name(**prot)}_id_t, ${prot_full_name(**prot)}_data_t, ${prot_full_name(**prot)}_strb_t, ${prot_full_name(**prot)}_user_t)
% endfor

  /////////////////////////
  //   Header Typedefs   //
  /////////////////////////

% for m, l in header.items():
  % if l > 1:
  typedef logic [${l-1}:0] ${m}_t;
  % endif
% endfor

  typedef struct packed {
    % for m, l in header.items():
    % if l == 1:
    logic ${m};
    % else:
    ${m}_t ${m};
    % endif
    % endfor
  } hdr_t;


    ////////////////////////////
    //   AXI Flits Typedefs   //
    ////////////////////////////

    % for prot in protocols:
        % if prot['direction'] == 'input':
            % for axi_ch, size in get_axi_channel_sizes(**prot['params']).items():
<% phys_ch = inv_map[prot['name']][axi_ch] %>\
<% phys_ch_size = link_sizes[phys_ch] %>\
<% rsvd_space = phys_ch_size - size %>\
    typedef struct packed {
        logic valid;
        logic ready;
        hdr_t hdr;
        ${prot_full_name(**prot)}_${axi_ch}_chan_t ${axi_ch};
        % if rsvd_space > 0:
        logic [${rsvd_space-1}:0] rsvd;
        % endif
    } floo_${prot['name']}_${axi_ch}_flit_t;

            % endfor
        % endif
    % endfor

    ////////////////////////////////
    //   Generic Flits Typedefs   //
    ////////////////////////////////

    % for phys_ch in channel_mapping:
    typedef struct packed {
        logic valid;
        logic ready;
        hdr_t hdr;
        logic [${link_sizes[phys_ch]-1}:0] rsvd;
    } floo_${phys_ch}_generic_flit_t;

    % endfor

    ///////////////////////
    //   Link Typedefs   //
    ///////////////////////

    % for phys_ch, mapping in channel_mapping.items():
    typedef union packed {
        % for ch_type, axi_chs in mapping.items():
        % for axi_ch in axi_chs:
        floo_${ch_type}_${axi_ch}_flit_t ${ch_type}_${axi_ch};
        % endfor
        % endfor
        floo_${phys_ch}_generic_flit_t generic;
    } floo_${phys_ch}_t;

    % endfor
endpackage
