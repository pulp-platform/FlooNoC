// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"
`include "register_interface/typedef.svh"

package floo_synth_params_pkg;
  import floo_pkg::*;

  // Router parameters
  localparam int unsigned InFifoDepth = 16;
  localparam int unsigned OutFifoDepth = 16;

  // Default route config for testing
  localparam floo_pkg::route_cfg_t RouteCfg = '{
    RouteAlgo: floo_pkg::XYRouting,
    UseIdTable: 0,
    XYAddrOffsetX: 16,
    XYAddrOffsetY: 20,
    default: '0 // Potentially enable Multicast features
  };

  // Common chimney parameters
  localparam bit AtopSupport = 1'b1;
  localparam int unsigned MaxAtomicTxns = 4;

  // Default chimney config for testing
  localparam floo_pkg::chimney_cfg_t ChimneyCfg = '{
    EnSbrPort: 1'b1,
    EnMgrPort: 1'b1,
    MaxTxns: 32,
    MaxUniqueIds: 1,
    MaxTxnsPerId: 32,
    BRoBType: floo_pkg::NoRoB,
    BRoBSize: 0,
    RRoBType: floo_pkg::NoRoB,
    RRoBSize: 0,
    CutAx: 1'b0,
    CutOup: 1'b0,
    CutRsp: 1'b0
  };

  typedef logic [1:0] x_bits_t;
  typedef logic [1:0] y_bits_t;
  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, logic)

  // Unused types
  typedef logic route_t;

endpackage

package floo_synth_axi_pkg;

  import floo_synth_params_pkg::*;

  // Axi chimney parameters
  localparam floo_pkg::axi_cfg_t AxiCfg = '{
    AddrWidth: 32,
    DataWidth: 64,
    UserWidth: 1,
    InIdWidth: 3,
    OutIdWidth: 3
  };

  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::axi_ch_e, logic)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi, AxiCfg)
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, AxiCfg, hdr_t)
  `FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)

endpackage

package floo_synth_nw_pkg;

  import floo_synth_params_pkg::*;

  localparam floo_pkg::axi_cfg_t AxiCfgN = '{
    AddrWidth: 48,
    DataWidth: 64,
    UserWidth: 5,
    InIdWidth: 4,
    OutIdWidth: 2
  };

  // AXI nw_chimney parameters
  localparam floo_pkg::axi_cfg_t AxiCfgW = '{
    AddrWidth: 48,
    DataWidth: 512,
    UserWidth: 1,
    InIdWidth: 3,
    OutIdWidth: 1
  };

  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, floo_pkg::nw_ch_e, logic)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_narrow, AxiCfgN)
  `FLOO_TYPEDEF_AXI_FROM_CFG(axi_wide, AxiCfgW)
  `FLOO_TYPEDEF_NW_CHAN_ALL(axi, req, rsp, wide, axi_narrow_in, axi_wide_in,
      AxiCfgN, AxiCfgW, hdr_t)

  localparam floo_pkg::wide_rw_decouple_e WideRwDecouple = floo_pkg::Phys;
  localparam floo_pkg::vc_impl_e VcImpl = floo_pkg::VcNaive;

  localparam int unsigned NumVirtualChannels = (WideRwDecouple == floo_pkg::None) ? 1 : 2;
  localparam int unsigned NumWidePhysChannels = (WideRwDecouple == floo_pkg::Phys) ? 2 : 1;
  `FLOO_TYPEDEF_NW_VIRT_CHAN_LINK_ALL(req, rsp, wide, req, rsp, wide,
                                      NumVirtualChannels, NumWidePhysChannels)

  typedef logic [AxiCfgW.DataWidth-1:0] floo_wide_red_data_t;
  typedef logic [AxiCfgN.DataWidth-1:0] floo_narrow_red_data_t;
  `FLOO_RED_TYPEDEF_REQ_RSP_LINK(wide, floo_wide_red_data_t, wide_req, wide_rsp)
  `FLOO_RED_TYPEDEF_REQ_RSP_LINK(narrow, floo_narrow_red_data_t, narrow_req, narrow_rsp)

endpackage


// Package to define the AXI interface at the NI for chimney synthesis
// It's taken for the standard snitch pkg interface used in Picobello
// This package is necessary to correctly configure the chimney in a
// realistic manner for a possible endpoint.
package endpoint_axi_pkg;
  localparam int unsigned AtomicIdWidth = 5;
  localparam int unsigned AddrWidth = 48;
  localparam int unsigned NarrowDataWidth = 64;
  localparam int unsigned WideDataWidth = 512;
  localparam int unsigned NarrowIdWidthIn = 2;
  localparam int unsigned NrNarrowMasters = 3;
  localparam int unsigned NarrowIdWidthOut = $clog2(NrNarrowMasters) + NarrowIdWidthIn;
  localparam int unsigned NrWideMasters = 1 + 1 + 1;
  localparam int unsigned WideIdWidthIn = 1;
  localparam int unsigned WideIdWidthOut = $clog2(NrWideMasters) + WideIdWidthIn;

  typedef logic [AddrWidth-1:0]         addr_t;
  typedef logic [NarrowDataWidth-1:0]   data_t;
  typedef logic [NarrowDataWidth/8-1:0] strb_t;
  typedef logic [WideDataWidth-1:0]     data_dma_t;
  typedef logic [WideDataWidth/8-1:0]   strb_dma_t;
  typedef logic [NarrowIdWidthIn-1:0]   narrow_in_id_t;
  typedef logic [NarrowIdWidthOut-1:0]  narrow_out_id_t;
  typedef logic [WideIdWidthIn-1:0]     wide_in_id_t;
  typedef logic [WideIdWidthOut-1:0]    wide_out_id_t;

  localparam int unsigned CollectiveWidth = 4;

  typedef struct packed {
    addr_t                          collective_mask;
    logic [CollectiveWidth-1:0]     collective_op;
    logic [AtomicIdWidth-1:0]       atomic_id;
  } user_narrow_t;

// Will be extended when implementing collective operation on the wide dma link
  typedef struct packed {
    addr_t                          collective_mask;
    logic [CollectiveWidth-1:0]     collective_op;
  } user_dma_t;

  localparam int unsigned NarrowUserWidth = $bits(user_narrow_t);
  localparam int unsigned WideUserWidth = $bits(user_dma_t);

  // AXI interface
  `AXI_TYPEDEF_ALL(narrow_in, addr_t, narrow_in_id_t, data_t, strb_t, user_narrow_t)
  `AXI_TYPEDEF_ALL(narrow_out, addr_t, narrow_out_id_t, data_t, strb_t, user_narrow_t)
  `AXI_TYPEDEF_ALL(wide_in, addr_t, wide_in_id_t, data_dma_t, strb_dma_t, user_dma_t)
  `AXI_TYPEDEF_ALL(wide_out, addr_t, wide_out_id_t, data_dma_t, strb_dma_t, user_dma_t)
endpackage


// Package to define all the types and information to analyyze collective support
package floo_synth_collective_pkg;
  import floo_pkg::*;
  import floo_synth_params_pkg::*;
  import floo_synth_nw_pkg::*;
  import endpoint_axi_pkg::*;

  typedef logic [0:0] rob_idx_t;

  // Low-latency reduction config for narrow integer ops (short pipeline, cut offload interface)
  localparam reduction_cfg_t NarrowReductionCfg = '{
    RdPipelineDepth: 1,
    CutOffloadIntf: 1'b1
  };

  // High-throughput reduction config for wide FP ops (deep pipeline, cut offload interface)
  localparam reduction_cfg_t WideReductionCfg = '{
    RdPipelineDepth: 5,
    CutOffloadIntf: 1'b1
  };

  // Route config with collective support enabled
  // This configuration is the one to be changed in order to enable or disable
  // different collective operation support
  // TODO (lleone): Script this with Python

  localparam floo_pkg::collect_op_fe_cfg_t CollectiveOpCfg = '{
    EnNarrowMulticast:  1'b1,
    EnWideMulticast:    1'b1,
    EnLsbAnd:           1'b1,
    EnFpAdd:            1'b1,
    EnFpMul:            1'b1,
    EnFpMin:            1'b1,
    EnFpMax:            1'b1,
    EnIntAdd:            1'b1,
    EnIntMul:            1'b1,
    EnIntMinS:          1'b1,
    EnIntMinU:          1'b1,
    EnIntMaxS:          1'b1,
    EnIntMaxU:          1'b1
  };

  localparam floo_pkg::collect_op_fe_cfg_t MulticastOpCfg = '{
    EnNarrowMulticast:  1'b1,
    EnWideMulticast:    1'b1,
    EnLsbAnd:           1'b0,
    EnFpAdd:            1'b0,
    EnFpMul:            1'b0,
    EnFpMin:            1'b0,
    EnFpMax:            1'b0,
    default:            '0
  };

  localparam floo_pkg::collect_op_fe_cfg_t ParallelOpCfg = '{
    EnNarrowMulticast:  1'b1,
    EnWideMulticast:    1'b1,
    EnLsbAnd:           1'b1,
    EnFpAdd:            1'b0,
    EnFpMul:            1'b0,
    EnFpMin:            1'b0,
    EnFpMax:            1'b0,
    default:            '0
  };

  localparam floo_pkg::collect_op_fe_cfg_t NarrSequentialOpCfg = '{
    EnNarrowMulticast:  1'b1,
    EnWideMulticast:    1'b1,
    EnLsbAnd:           1'b1,
    EnFpAdd:            1'b0,
    EnFpMul:            1'b0,
    EnFpMin:            1'b0,
    EnFpMax:            1'b0,
    EnIntAdd:            1'b1,
    EnIntMul:            1'b1,
    EnIntMinS:          1'b1,
    EnIntMinU:          1'b1,
    EnIntMaxS:          1'b1,
    EnIntMaxU:          1'b1
  };

  localparam floo_pkg::collect_op_fe_cfg_t WideSequentialOpCfg = '{
    EnNarrowMulticast:  1'b1,
    EnWideMulticast:    1'b1,
    EnLsbAnd:           1'b1,
    EnFpAdd:            1'b1,
    EnFpMul:            1'b1,
    EnFpMin:            1'b1,
    EnFpMax:            1'b1,
    EnIntAdd:            1'b1,
    EnIntMul:            1'b1,
    EnIntMinS:          1'b1,
    EnIntMinU:          1'b1,
    EnIntMaxS:          1'b1,
    EnIntMaxU:          1'b1
  };

  localparam floo_pkg::collect_op_fe_cfg_t CollectOpCfgList [6] = '{
    0: '0,
    1: CollectiveOpCfg,
    2: MulticastOpCfg,
    3: ParallelOpCfg,
    4: NarrSequentialOpCfg,
    5: WideSequentialOpCfg
  };

  // Index enum matching CollectOpCfgList — use as CollectCfgIdx parameter in synth wrappers
  typedef enum int unsigned {
    CollectNone     = 0,  // No collective
    CollectAll      = 1,  // All ops (multicast + barrier + narrow/wide reduction)
    CollectMcast    = 2,  // Multicast only
    CollectParallel = 3,  // Multicast + barrier (parallel reductions only)
    CollectNarrSeq  = 4,  // Multicast + barrier + narrow integer reductions
    CollectWideSeq  = 5   // All ops including wide FP reductions
  } collective_cfg_idx_e;

  typedef logic[AxiCfgW.DataWidth-1:0] RdDataWide_t;
  typedef logic[AxiCfgN.DataWidth-1:0] RdDataNarrow_t;

  `FLOO_TYPEDEF_HDR_T(hdr_coll_t, id_t, id_t, nw_ch_e, rob_idx_t, id_t, collect_op_e)

  // Collective SAM types — names and field types match the generated floo_*_noc_pkg
  typedef struct packed {
    int unsigned offset;
    int unsigned len;
    int unsigned base_id;
  } collective_mask_sel_t;

  typedef struct packed {
    id_t                  id;
    collective_mask_sel_t mask_x;
    collective_mask_sel_t mask_y;
  } collective_idx_t;

  typedef struct packed {
    collective_idx_t              idx;
    logic [AxiCfgN.AddrWidth-1:0] start_addr;
    logic [AxiCfgN.AddrWidth-1:0] end_addr;
  } collective_sam_rule_t;

  typedef logic [AxiCfgN.AddrWidth-1:0] user_mask_t;

  typedef struct packed {
    user_mask_t                 collective_mask;
    floo_pkg::collect_op_e      collective_op;
    logic [AtomicIdWidth-1:0]   atomic;
  } collective_narrow_user_t;

  typedef struct packed {
    user_mask_t             collective_mask;
    floo_pkg::collect_op_e  collective_op;
  } collective_wide_user_t;

  localparam floo_pkg::route_cfg_t CollectRouteCfg = '{
    RouteAlgo: floo_pkg::XYRouting,
    UseIdTable: 1,
    XYAddrOffsetX: 16,
    XYAddrOffsetY: 20,
    CollectiveCfg: '{
      OpCfg:      CollectOpCfgList[CollectNone],
      NarrRedCfg: NarrowReductionCfg,
      WideRedCfg: WideReductionCfg
    },
    default: '0
  };

endpackage

package floo_synth_qos_pkg;
  import endpoint_axi_pkg::*;
  import floo_synth_nw_pkg::*;

  // AXI-Realm regfile
  localparam int unsigned NumMrg     = axi_rt_reg_pkg::NumMrg;  // managers per RT unit
  localparam int unsigned NumSub     = axi_rt_reg_pkg::NumSub;  // address (sub)regions
  localparam int unsigned NumReg     = axi_rt_reg_pkg::NumReg;  // register banks
  localparam int unsigned RegBlockAw = axi_rt_reg_pkg::BlockAw; // reg-file byte-addr width

  // Tile topology
  localparam int unsigned NumCores          = 1;    // single accelerator manager
  localparam int unsigned NumNoCPlanes      = 2;    // narrow + wide NoC plane
  localparam int unsigned IdxNoCPlaneWide   = 0;
  localparam int unsigned IdxNoCPlaneNarrow = 1;
  localparam int unsigned MeshDimY          = 32'd4; // used for the reg-file guard ID

  // AXI-Realm sizing
  localparam int unsigned NumManagers        = NumMrg;    // == NumCores
  localparam int unsigned NumRegions         = 32'd1;     // active regions (<= NumSub)
  localparam int unsigned MaxBurstLength     = 32'd256;
  localparam int unsigned NumPending         = MaxBurstLength;
  localparam int unsigned WBufferDepth       = MaxBurstLength;
  localparam int unsigned PeriodWidth        = 32'd32;
  localparam int unsigned BudgetWidth        = 32'd32;
  localparam int unsigned RegIdWidth         = 32'd8;
  localparam bit          CutDecErrors       = 1'b0;
  localparam bit          CutSplitterPaths   = 1'b0;
  localparam bit          DisableSplitChecks = 1'b0;
  localparam int unsigned WideAxiSizeWidth   = axi_pkg::SizeWidth + 4; // FlooNoC wide: 512-bit
  localparam int unsigned NarrowAxiSizeWidth = axi_pkg::SizeWidth;     // FlooNoC wide: 64-bit
  localparam bit          UseWriteBuffer     = 1'b0;
  localparam bit          UseSplitterReconf  = 1'b0;

  typedef logic [RegIdWidth-1:0] reg_id_t;

  // ---------------------------------------------------------------------------
  // Per-plane AXI widths handed to `axi_rt_unit_top`, sourced from
  // `endpoint_axi_pkg` so the RT unit always matches the chimney AXI datapath.
  // ---------------------------------------------------------------------------
  localparam int unsigned RtAddrWidth       = endpoint_axi_pkg::AddrWidth;
  localparam int unsigned RtWideDataWidth   = endpoint_axi_pkg::WideDataWidth;
  localparam int unsigned RtWideIdWidth     = endpoint_axi_pkg::WideIdWidthOut;
  localparam int unsigned RtWideUserWidth   = endpoint_axi_pkg::WideUserWidth;
  localparam int unsigned RtNarrowDataWidth = endpoint_axi_pkg::NarrowDataWidth;
  localparam int unsigned RtNarrowIdWidth   = endpoint_axi_pkg::NarrowIdWidthOut;
  localparam int unsigned RtNarrowUserWidth = endpoint_axi_pkg::NarrowUserWidth;

  // ---------------------------------------------------------------------------
  // Configuration decode + conversion chain
  //   AXI64 -> [dw 64->32] -> [modify addr 48->32] -> AXI-Lite -> reg-bus
  // ---------------------------------------------------------------------------
  localparam int unsigned CfgAddrSpaceDim   = 32'h0000_2000; // per-plane cfg window
  localparam int unsigned CfgAddrWidth      = 32'd32;        // downsized address width
  localparam int unsigned CfgDataWidth      = 32'd32;        // downsized data width
  localparam int unsigned CfgDwMaxReads     = 32'd8;         // axi_dw_converter max reads
  localparam int unsigned CfgLiteMaxTxns    = 32'd1;         // axi_to_axi_lite max r/w txns
  localparam int unsigned CfgRegBufferDepth = 32'd2;         // axi_lite_to_reg buffer depth

  typedef logic [CfgAddrWidth-1:0]   cfg_addr32_t;
  typedef logic [CfgDataWidth-1:0]   cfg_data32_t;
  typedef logic [CfgDataWidth/8-1:0] cfg_strb32_t;

  // AXI-Lite (feeds the conversion chain) and register bus (feeds `reg_req_i`).
  `AXI_LITE_TYPEDEF_ALL(cfg_lite, cfg_addr32_t, cfg_data32_t, cfg_strb32_t)
  `REG_BUS_TYPEDEF_ALL(cfg, cfg_addr32_t, cfg_data32_t, cfg_strb32_t)

endpackage
