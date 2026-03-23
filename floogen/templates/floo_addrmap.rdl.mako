## Copyright 2023 ETH Zurich and University of Bologna.
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0
<%!
    import datetime
%>\
// Copyright ${datetime.datetime.now().year} ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

${noc.routing.sam.render_rdl_inc()}

addrmap ${noc.name}_addrmap {

${noc.routing.sam.render_rdl(rdl_as_mem, rdl_memwidth)}

};
