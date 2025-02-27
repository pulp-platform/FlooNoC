<%!
    import datetime
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

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
