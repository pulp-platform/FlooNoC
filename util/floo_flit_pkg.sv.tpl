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
<%
  max_virt_ch_per_phys = max([len(i) for i in cfg['map'].values()])
%> \

`include "axi/typedef.svh"

package floo_${cfg['name']}_flit_pkg;

  localparam int unsigned NumPhysChannels = ${len(cfg['phys_channels'])};
  localparam int unsigned NumAxiChannels = ${len(cfg['axi_order'])};

  ////////////////////////
  //   AXI Parameters   //
  ////////////////////////

% for axi_ch in cfg['axi_channels']:
  localparam int unsigned ${camelcase(axi_ch['name'])}AddrWidth = ${axi_ch['params']['aw']};
  localparam int unsigned ${camelcase(axi_ch['name'])}DataWidth = ${axi_ch['params']['dw']};
  localparam int unsigned ${camelcase(axi_ch['name'])}IdWidth = ${axi_ch['params']['iw']};
  localparam int unsigned ${camelcase(axi_ch['name'])}UserWidth = ${axi_ch['params']['uw']};

% endfor

% for axi_ch in cfg['axi_channels']:
  typedef logic [${axi_ch['params']['aw']-1}:0] ${axi_ch['name']}_addr_t;
  typedef logic [${axi_ch['params']['dw']-1}:0] ${axi_ch['name']}_data_t;
  typedef logic [${axi_ch['params']['dw']//8-1}:0] ${axi_ch['name']}_strb_t;
  typedef logic [${axi_ch['params']['iw']-1}:0] ${axi_ch['name']}_id_t;
  typedef logic [${axi_ch['params']['uw']-1}:0] ${axi_ch['name']}_user_t;

% endfor

% for axi_ch in cfg['axi_channels']:
  `AXI_TYPEDEF_ALL(${axi_ch['name']}, ${axi_ch['name']}_addr_t, ${axi_ch['name']}_id_t, ${axi_ch['name']}_data_t, ${axi_ch['name']}_strb_t, ${axi_ch['name']}_user_t)
% endfor

  //////////////////////
  //   AXI Channels   //
  //////////////////////

  typedef enum logic[${clog2(len(cfg['axi_order']))-1}:0] {
  % for axi_ch in cfg['axi_order']:
    ${camelcase(axi_ch)}${'' if loop.last else ','}
  % endfor
  } axi_ch_e;

  ///////////////////////////
  //   Physical Channels   //
  ///////////////////////////

  typedef enum int {
  % for phys_ch in cfg['phys_channels']:
    Phys${camelcase(phys_ch)}${'' if loop.last else ','}
  % endfor
  } phys_chan_e;

  /////////////////////////
  //   Channel Mapping   //
  /////////////////////////

  localparam int NumVirtPerPhys[NumPhysChannels] = '${list2array([len(axi_chs) for axi_chs in cfg['map'].values()])};

  localparam int PhysChanMapping[NumAxiChannels] = '{
  % for i in cfg['inv_map'].values():
    ${'Phys' + camelcase(i)}${'' if loop.last else ','}
  % endfor
  };

  localparam int VirtChanMapping[NumPhysChannels][${max_virt_ch_per_phys}] = '{
  % for axi_chs in cfg['map'].values():
    '${list2array(zero_pad([camelcase(i) for i in axi_chs], max_virt_ch_per_phys))}${'' if loop.last else ','}
  % endfor
  };

  ///////////////////////
  //   Meta Typedefs   //
  ///////////////////////

% for m, l in cfg['meta'].items():
  typedef logic [${l-1}:0] ${m}_t;
% endfor

  ////////////////////////////
  //   AXI Packet Structs   //
  ////////////////////////////

% for phys_ch, axi_chs in cfg['map'].items():
  % for axi_ch in axi_chs:
  typedef struct packed {
    % for m, l in cfg['meta'].items():
    ${m}_t ${m};
    % endfor
    ${axi_ch}_chan_t ${axi_ch.split('_')[-1]};
    % if cfg['rsvd_bits'][axi_ch] != 0:
    logic [${cfg['rsvd_bits'][axi_ch]-1}:0] rsvd;
    % endif
  } ${axi_ch}_data_t;

  % endfor
  typedef struct packed {
    % for m, l in cfg['meta'].items():
    ${m}_t ${m};
    % endfor
    logic [${cfg['phys_ch_sizes'][phys_ch]-1}:0] rsvd;
  } ${phys_ch}_generic_t;

% endfor


  ///////////////////////////
  //   AXI Packet Unions   //
  ///////////////////////////

% for phys_ch, axi_chs in cfg['map'].items():
  typedef union packed {
  % for axi_ch in axi_chs:
    ${axi_ch}_data_t ${axi_ch};
  % endfor
  ${phys_ch}_generic_t gen;
  } ${phys_ch}_data_t;

% endfor

  ///////////////////////////////
  //   Physical Flit Structs   //
  ///////////////////////////////

  % for phys_ch in cfg['phys_channels']:
    typedef struct packed {
      logic valid;
      logic ready;
      ${phys_ch}_data_t data;
    } ${phys_ch}_flit_t;

  % endfor

  //////////////////////////////
  //   Phys Packeed Structs   //
  //////////////////////////////

  typedef struct packed {
% for phys_ch, axi_chs in cfg['map'].items():
    ${phys_ch}_flit_t ${phys_ch};
% endfor
  } flit_t;

endpackage
