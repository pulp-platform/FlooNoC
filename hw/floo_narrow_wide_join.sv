// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "axi/assign.svh"

/// Joins a narrow and a wide AXI bus to a wide AXI bus.
/// This module is intended to be used for instance in front
/// of an HBM controller to enable access from both the
/// narrow and the wide AXI bus.
module floo_narrow_wide_join #(
  /// Filter Atops on the Narrow AXI bus
  parameter bit FilterNarrowAtops                     = 1'b0,
  /// Filter Atops on the Wide AXI bus
  parameter bit FilterWideAtops                       = 1'b0,
  /// ID width of the narrow AXI bus
  parameter int unsigned AxiNarrowIdInWidth           = 0,
  /// ID width of the wide AXI bus
  parameter int unsigned AxiWideIdInWidth             = 0,
  /// User width of the narrow AXI bus
  parameter int unsigned AxiNarrowUserInWidth         = 0,
  /// User width of the wide AXI bus
  parameter int unsigned AxiWideUserInWidth           = 0,
  /// ID width of the resulting AXI bus
  /// To prevent the instantiation of any ID remappers,
  /// `AxiIdOutWidth` should be chosen, such that:
  /// max(`AxiNarrowIdWidth` and `AxiWideIdWidth`) == AxidOutWidth - 1
  parameter int unsigned AxiIdOutWidth                = 0,
  /// ID width of the busses before muxing them together.
  localparam int unsigned AxiIdConvWidth              = AxiIdOutWidth - 1,
  /// Default parameter for number of inflight narrow transactions
  localparam int unsigned AxiNarrowMaxTxns            = 8,
  /// Maximum number of in-flight AXI narrow write transactions
  parameter int unsigned AxiNarrowMaxWriteTxns        = AxiNarrowMaxTxns,
  /// Maximum number of in-flight AXI narrow read transactions
  parameter int unsigned AxiNarrowMaxReadTxns         = AxiNarrowMaxTxns,
  /// Number of unique IDs on the narrow AXI bus
  parameter int unsigned AxiNarrowSlvPortMaxUniqIds   = 2**AxiNarrowIdInWidth,
  /// Maximum number of in-flight AXI transactions on the narrow AXI bus
  parameter int unsigned AxiNarrowSlvPortMaxTxnsPerId = AxiNarrowMaxTxns,
  /// Maximum number of in-flight transactions at the narrow slave port
  parameter int unsigned AxiNarrowSlvPortMaxTxns      = AxiNarrowMaxTxns,
  /// Maximum number of different IDs that can be in flight at the narrow master port
  parameter int unsigned AxiNarrowMstPortMaxUniqIds   = 2**AxiIdConvWidth,
  /// Maximum number of in-flight transactions with the same ID at the narrow master port.
  parameter int unsigned AxiNarrowMstPortMaxTxnsPerId = AxiNarrowMaxTxns,
  /// Default parameter for number of inflight wide transactions
  localparam int unsigned AxiWideMaxTxns              = 32,
  /// Maximum number of in-flight AXI wide write transactions
  parameter int unsigned AxiWideMaxWriteTxns          = AxiWideMaxTxns,
  /// Number of unique IDs on the wide AXI bus
  parameter int unsigned AxiWideSlvPortMaxUniqIds     = 2**AxiWideIdInWidth,
  /// Maximum number of in-flight AXI transactions on the wide AXI bus
  parameter int unsigned AxiWideSlvPortMaxTxnsPerId   = AxiWideMaxTxns,
  /// Maximum number of in-flight transactions at the wide slave port
  parameter int unsigned AxiWideSlvPortMaxTxns        = AxiWideMaxTxns,
  /// Maximum number of different IDs that can be in flight at the wide master port
  parameter int unsigned AxiWideMstPortMaxUniqIds     = 2**AxiIdConvWidth,
  /// Maximum number of in-flight transactions with the same ID at the wide master port.
  parameter int unsigned AxiWideMstPortMaxTxnsPerId   = AxiWideMaxTxns,
    /// Address width of both AXI4+ATOP ports
  parameter int unsigned AxiAddrWidth                 = 32'd0,
  /// Data width of narrow AXI4+ATOP ports
  parameter int unsigned AxiNarrowDataWidth           = 32'd0,
  /// Data width of wide AXI4+ATOP ports
  parameter int unsigned AxiWideDataWidth             = 32'd0,
  /// User signal width of both AXI4+ATOP ports
  parameter int unsigned AxiUserWidth                 = 32'd0,
  /// Use user signals for the ATOP adapter
  parameter bit AtopUserAsId                          = 1'b1,
  /// MSB of the ID field of the ATOP adapter
  parameter int unsigned AtopAxiUserIdMsb             = AxiUserWidth-1,
  /// LSB of the ID field of the ATOP adapter
  parameter int unsigned AtopAxiUserIdLsb             = 0,
  /// AXI type of the narrow AXI bus
  parameter type axi_narrow_req_t = logic,
  parameter type axi_narrow_rsp_t = logic,
  /// AXI type of the wide AXI bus
  parameter type axi_wide_req_t = logic,
  parameter type axi_wide_rsp_t = logic,
  /// AXI type of the resulting wide AXI bus
  parameter type axi_req_t = logic,
  parameter type axi_rsp_t = logic
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic test_enable_i,
  input  axi_narrow_req_t axi_narrow_req_i,
  output axi_narrow_rsp_t axi_narrow_rsp_o,
  input  axi_wide_req_t   axi_wide_req_i,
  output axi_wide_rsp_t   axi_wide_rsp_o,
  output axi_req_t        axi_req_o,
  input  axi_rsp_t        axi_rsp_i
);

  typedef logic [AxiIdOutWidth-1:0] id_t;
  typedef logic [AxiIdConvWidth-1:0] id_conv_t;
  typedef logic [AxiAddrWidth-1:0] addr_t;
  typedef logic [AxiNarrowDataWidth-1:0] narrow_data_t;
  typedef logic [AxiNarrowDataWidth/8-1:0] narrow_strb_t;
  typedef logic [AxiWideDataWidth-1:0] wide_data_t;
  typedef logic [AxiWideDataWidth/8-1:0] wide_strb_t;
  typedef logic [AxiNarrowUserInWidth-1:0] narrow_user_t;
  typedef logic [AxiWideUserInWidth-1:0] wide_user_t;
  typedef logic [AxiUserWidth-1:0] user_t;

  `AXI_TYPEDEF_ALL_CT(axi_narrow_iw_conv, axi_narrow_iw_conv_req_t, axi_narrow_iw_conv_rsp_t,
                      addr_t, id_conv_t, narrow_data_t, narrow_strb_t, narrow_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_narrow_dw_conv, axi_narrow_dw_conv_req_t, axi_narrow_dw_conv_rsp_t,
                      addr_t, id_conv_t, wide_data_t, wide_strb_t, narrow_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide_iw_conv, axi_wide_iw_conv_req_t, axi_wide_iw_conv_rsp_t,
                      addr_t, id_conv_t, wide_data_t, wide_strb_t, wide_user_t)
  `AXI_TYPEDEF_ALL_CT(axi_wide_uw_conv, axi_wide_uw_conv_req_t, axi_wide_uw_conv_rsp_t,
                      addr_t, id_conv_t, wide_data_t, wide_strb_t, user_t)
  `AXI_TYPEDEF_ALL_CT(axi_out, axi_out_req_t, axi_out_rsp_t,
                      addr_t, id_t, wide_data_t, wide_strb_t, user_t)

  /////////////////////
  ///  Atop Filters  //
  /////////////////////

  axi_narrow_req_t axi_narrow_req_filter_atop;
  axi_narrow_rsp_t axi_narrow_rsp_filter_atop;
  axi_wide_req_t axi_wide_req_filter_atop;
  axi_wide_rsp_t axi_wide_rsp_filter_atop;

  if (FilterNarrowAtops) begin : gen_narrow_atop_filter
    axi_atop_filter #(
      .AxiIdWidth       ( AxiNarrowIdInWidth    ),
      .AxiMaxWriteTxns  ( AxiNarrowMaxWriteTxns ),
      .axi_req_t        ( axi_narrow_req_t      ),
      .axi_resp_t       ( axi_narrow_rsp_t      )
    ) i_axi_atop_filter (
      .clk_i,
      .rst_ni,
      .slv_req_i  ( axi_narrow_req_i            ),
      .slv_resp_o ( axi_narrow_rsp_o            ),
      .mst_req_o  ( axi_narrow_req_filter_atop  ),
      .mst_resp_i ( axi_narrow_rsp_filter_atop  )
    );
  end else begin : gen_narrow_atop_passthrough
    assign axi_narrow_req_filter_atop = axi_narrow_req_i;
    assign axi_narrow_rsp_o = axi_narrow_rsp_filter_atop;
  end

  if (FilterWideAtops) begin : gen_wide_atop_filter
    axi_atop_filter #(
      .AxiIdWidth       ( AxiWideIdInWidth    ),
      .AxiMaxWriteTxns  ( AxiWideMaxWriteTxns ),
      .axi_req_t        ( axi_wide_req_t      ),
      .axi_resp_t       ( axi_wide_rsp_t      )
    ) i_axi_atop_filter (
      .clk_i,
      .rst_ni,
      .slv_req_i  ( axi_wide_req_i            ),
      .slv_resp_o ( axi_wide_rsp_o            ),
      .mst_req_o  ( axi_wide_req_filter_atop  ),
      .mst_resp_i ( axi_wide_rsp_filter_atop  )
    );
  end else begin : gen_wide_atop_passthrough
    assign axi_wide_req_filter_atop = axi_wide_req_i;
    assign axi_wide_rsp_o = axi_wide_rsp_filter_atop;
  end

  ////////////////////////////
  ///  ID width conversion  //
  ////////////////////////////

  axi_narrow_iw_conv_req_t axi_narrow_req_iw_conv;
  axi_narrow_iw_conv_rsp_t axi_narrow_rsp_iw_conv;
  axi_wide_iw_conv_req_t axi_wide_req_iw_conv;
  axi_wide_iw_conv_rsp_t axi_wide_rsp_iw_conv;

  axi_iw_converter #(
    .AxiSlvPortIdWidth      ( AxiNarrowIdInWidth            ),
    .AxiMstPortIdWidth      ( AxiIdConvWidth                ),
    .AxiSlvPortMaxUniqIds   ( AxiNarrowSlvPortMaxUniqIds    ),
    .AxiSlvPortMaxTxnsPerId ( AxiNarrowSlvPortMaxTxnsPerId  ),
    .AxiSlvPortMaxTxns      ( AxiNarrowSlvPortMaxTxns       ),
    .AxiMstPortMaxUniqIds   ( AxiNarrowMstPortMaxUniqIds    ),
    .AxiMstPortMaxTxnsPerId ( AxiNarrowMstPortMaxTxnsPerId  ),
    .AxiAddrWidth           ( AxiAddrWidth                  ),
    .AxiDataWidth           ( AxiNarrowDataWidth            ),
    .AxiUserWidth           ( AxiNarrowUserInWidth          ),
    .slv_req_t              ( axi_narrow_req_t              ),
    .slv_resp_t             ( axi_narrow_rsp_t              ),
    .mst_req_t              ( axi_narrow_iw_conv_req_t      ),
    .mst_resp_t             ( axi_narrow_iw_conv_rsp_t      )
  ) i_axi_narrow_iw_converter (
    .clk_i      ( clk_i                       ),
    .rst_ni     ( rst_ni                      ),
    .slv_req_i  ( axi_narrow_req_filter_atop  ),
    .slv_resp_o ( axi_narrow_rsp_filter_atop  ),
    .mst_req_o  ( axi_narrow_req_iw_conv      ),
    .mst_resp_i ( axi_narrow_rsp_iw_conv      )
  );

  axi_iw_converter #(
    .AxiSlvPortIdWidth        ( AxiWideIdInWidth            ),
    .AxiMstPortIdWidth        ( AxiIdConvWidth              ),
    .AxiSlvPortMaxUniqIds     ( AxiWideSlvPortMaxUniqIds    ),
    .AxiSlvPortMaxTxnsPerId   ( AxiWideSlvPortMaxTxnsPerId  ),
    .AxiSlvPortMaxTxns        ( AxiWideSlvPortMaxTxns       ),
    .AxiMstPortMaxUniqIds     ( AxiWideMstPortMaxUniqIds    ),
    .AxiMstPortMaxTxnsPerId   ( AxiWideMstPortMaxTxnsPerId  ),
    .AxiAddrWidth             ( AxiAddrWidth                ),
    .AxiDataWidth             ( AxiWideDataWidth            ),
    .AxiUserWidth             ( AxiWideUserInWidth          ),
    .slv_req_t                ( axi_wide_req_t              ),
    .slv_resp_t               ( axi_wide_rsp_t              ),
    .mst_req_t                ( axi_wide_iw_conv_req_t      ),
    .mst_resp_t               ( axi_wide_iw_conv_rsp_t      )
  ) i_axi_wide_iw_converter (
    .clk_i      ( clk_i                     ),
    .rst_ni     ( rst_ni                    ),
    .slv_req_i  ( axi_wide_req_filter_atop  ),
    .slv_resp_o ( axi_wide_rsp_filter_atop  ),
    .mst_req_o  ( axi_wide_req_iw_conv      ),
    .mst_resp_i ( axi_wide_rsp_iw_conv      )
  );

  //////////////////////////////
  ///  Data width conversion  //
  //////////////////////////////

  axi_narrow_dw_conv_req_t axi_narrow_req_dw_conv;
  axi_narrow_dw_conv_rsp_t axi_narrow_rsp_dw_conv;

  axi_dw_converter #(
    .AxiMaxReads          ( AxiNarrowMaxReadTxns          ),
    .AxiSlvPortDataWidth  ( AxiNarrowDataWidth            ),
    .AxiMstPortDataWidth  ( AxiWideDataWidth              ),
    .AxiAddrWidth         ( AxiAddrWidth                  ),
    .AxiIdWidth           ( AxiIdConvWidth                ),
    .aw_chan_t            ( axi_narrow_iw_conv_aw_chan_t  ),
    .mst_w_chan_t         ( axi_narrow_dw_conv_w_chan_t   ),
    .slv_w_chan_t         ( axi_narrow_iw_conv_w_chan_t   ),
    .b_chan_t             ( axi_narrow_iw_conv_b_chan_t   ),
    .ar_chan_t            ( axi_narrow_iw_conv_ar_chan_t  ),
    .mst_r_chan_t         ( axi_narrow_dw_conv_r_chan_t   ),
    .slv_r_chan_t         ( axi_narrow_iw_conv_r_chan_t   ),
    .axi_mst_req_t        ( axi_narrow_dw_conv_req_t      ),
    .axi_mst_resp_t       ( axi_narrow_dw_conv_rsp_t      ),
    .axi_slv_req_t        ( axi_narrow_iw_conv_req_t      ),
    .axi_slv_resp_t       ( axi_narrow_iw_conv_rsp_t      )
  ) i_axi_dw_converter (
    .clk_i      ( clk_i       ),
    .rst_ni     ( rst_ni      ),
    .slv_req_i  ( axi_narrow_req_iw_conv  ),
    .slv_resp_o ( axi_narrow_rsp_iw_conv  ),
    .mst_req_o  ( axi_narrow_req_dw_conv  ),
    .mst_resp_i ( axi_narrow_rsp_dw_conv  )
  );

  //////////////////////////////
  ///  User Width Conversion  //
  //////////////////////////////

  axi_wide_uw_conv_req_t axi_wide_req_uw_conv, axi_narrow_req_uw_conv;
  axi_wide_uw_conv_rsp_t axi_wide_rsp_uw_conv, axi_narrow_rsp_uw_conv;

  `AXI_ASSIGN_REQ_STRUCT(axi_wide_req_uw_conv, axi_wide_req_iw_conv)
  `AXI_ASSIGN_RESP_STRUCT(axi_wide_rsp_iw_conv, axi_wide_rsp_uw_conv)
  `AXI_ASSIGN_REQ_STRUCT(axi_narrow_req_uw_conv, axi_narrow_req_dw_conv)
  `AXI_ASSIGN_RESP_STRUCT(axi_narrow_rsp_dw_conv, axi_narrow_rsp_uw_conv)

  ////////////
  ///  MUX  //
  ////////////

  axi_out_req_t axi_out_req;
  axi_out_rsp_t axi_out_rsp;

  axi_mux #(
    .SlvAxiIDWidth  ( AxiIdConvWidth              ),
    .NoSlvPorts     ( 2                           ),
    .MaxWTrans      ( AxiWideMaxWriteTxns         ),
    .slv_aw_chan_t  ( axi_wide_uw_conv_aw_chan_t  ),
    .mst_aw_chan_t  ( axi_out_aw_chan_t           ),
    .w_chan_t       ( axi_out_w_chan_t            ),
    .slv_b_chan_t   ( axi_wide_uw_conv_b_chan_t   ),
    .mst_b_chan_t   ( axi_out_b_chan_t            ),
    .slv_ar_chan_t  ( axi_wide_uw_conv_ar_chan_t  ),
    .mst_ar_chan_t  ( axi_out_ar_chan_t           ),
    .slv_r_chan_t   ( axi_wide_uw_conv_r_chan_t   ),
    .mst_r_chan_t   ( axi_out_r_chan_t            ),
    .slv_req_t      ( axi_wide_uw_conv_req_t      ),
    .slv_resp_t     ( axi_wide_uw_conv_rsp_t      ),
    .mst_req_t      ( axi_out_req_t               ),
    .mst_resp_t     ( axi_out_rsp_t               )
  ) i_axi_mux (
    .clk_i        ( clk_i                                           ),
    .rst_ni       ( rst_ni                                          ),
    .test_i       ( test_enable_i                                   ),
    .slv_reqs_i   ( {axi_narrow_req_uw_conv, axi_wide_req_uw_conv}  ),
    .slv_resps_o  ( {axi_narrow_rsp_uw_conv, axi_wide_rsp_uw_conv}  ),
    .mst_req_o    ( axi_out_req                                     ),
    .mst_resp_i   ( axi_out_rsp                                     )
  );

  ////////////////////////
  ///  Atomics Adapter  //
  ////////////////////////

  axi_out_req_t axi_out_req_atop;
  axi_out_rsp_t axi_out_rsp_atop;

  axi_riscv_atomics_structs #(
    .AxiAddrWidth     ( AxiAddrWidth        ),
    .AxiDataWidth     ( AxiWideDataWidth    ),
    .AxiIdWidth       ( AxiIdOutWidth       ),
    .AxiUserWidth     ( AxiUserWidth        ),
    .AxiMaxReadTxns   ( AxiWideMaxTxns      ),
    .AxiMaxWriteTxns  ( AxiWideMaxWriteTxns ),
    .AxiUserAsId      ( int'(AtopUserAsId)  ),
    .AxiUserIdMsb     ( AtopAxiUserIdMsb    ),
    .AxiUserIdLsb     ( AtopAxiUserIdLsb    ),
    .RiscvWordWidth   ( AxiNarrowDataWidth  ),
    .axi_req_t        ( axi_out_req_t       ),
    .axi_rsp_t        ( axi_out_rsp_t       )
  ) i_axi_riscv_atomics_structs (
    .clk_i          ( clk_i             ),
    .rst_ni         ( rst_ni            ),
    .axi_slv_req_i  ( axi_out_req       ),
    .axi_slv_rsp_o  ( axi_out_rsp       ),
    .axi_mst_req_o  ( axi_out_req_atop  ),
    .axi_mst_rsp_i  ( axi_out_rsp_atop  )
  );

  `AXI_ASSIGN_REQ_STRUCT(axi_req_o, axi_out_req_atop)
  `AXI_ASSIGN_RESP_STRUCT(axi_out_rsp_atop, axi_rsp_i)

endmodule
