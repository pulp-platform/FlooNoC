# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

onerror {resume}
quietly WaveActivateNextPane {} 0

delete wave *

add wave -noupdate -expand -group {DMA 0} -expand -group {WIDE} tb_floo_dma_nw_chimney/i_wide_dma_node_0/*
add wave -noupdate -expand -group {DMA 0} -expand -group {NARROW} tb_floo_dma_nw_chimney/i_narrow_dma_node_0/*
add wave -noupdate -expand -group {DMA 1} -expand -group {WIDE} tb_floo_dma_nw_chimney/i_wide_dma_node_1/*
add wave -noupdate -expand -group {DMA 1} -expand -group {NARROW} tb_floo_dma_nw_chimney/i_narrow_dma_node_1/*


TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 110
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
