#!/bin/bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Lukas Berner <bernerl@student.ethz.ch>


traffic_type_list=("random" "hbm" "onehop" "bit_complement" "bit_reverse" "bit_rotation" "neighbor" "shuffle" "transpose" "tornado" "single_dest_boundary" "single_dest_center")
traffic_rw_list=("read" "write")
router_tb_list=("tb_floo_dma_mesh" "tb_floo_vc_dma_mesh")

num_n_injected_list=(4  4  4  4  16 16 16 16 16 32 64 64 64 64  1  4 16 32 )
num_w_injected_list=(4  4  16 16 16 16 16 32 64 16 16  1  4 16 64 64 64 64 )
wide_burst_len_list=(1  16 1  16 4  8  16 16 16 16 16  4  4  4  4  4  4  4 )
# num_n_injected_list=(16 16 32 64  64  64 64 )
# num_w_injected_list=(32 64 16 16   1   4 16 )
# wide_burst_len_list=(16 16 16 16   4   4  4 )
# num_n_injected_list=( 1  4 16 32 )
# num_w_injected_list=(64 64 64 64 )
# wide_burst_len_list=( 4  4  4  4 )

printf -v date '%(%Y%m%d_%H%M%S)T' -1
#contains the raw output spam of the experiments (for debugging useful)
output_file_raw="util/output/dma_experiments_raw_${date}.txt"
#contains the raw output of 1 experiment, will be read by sript to extract the relevant information
output_file_temp="util/output/dma_experiment_temp_${date}.txt"

#should contain the output of python script:
# for each benchmark:
#  for each injection rate:
#   for each router:
#     -  narrow latency
#     -  wide latency
#     -  narrow Bandwidth
#     -  wide Bandwidth
output_file="util/output/dma_experiments_${date}.txt"

#bash settings
set -e #exit on error
set -o noclobber #do not overwrite files (file should be new)

# clean install
# make clean all
make all

# for each benchmark:
for traffic_type in ${traffic_type_list[@]}
do
  for traffic_rw in ${traffic_rw_list[@]}
  do
    printf "Experiment: $traffic_type $traffic_rw\n" | tee -a $output_file $output_file_raw
    # for each injection rate:
    for i in ${!num_n_injected_list[@]}
    do
      num_n_injected=${num_n_injected_list[$i]}
      num_w_injected=${num_w_injected_list[$i]}
      wide_burst_len=${wide_burst_len_list[$i]}
      # print the current experiment
      printf "Experiment: $traffic_type $traffic_rw num_narrow_bursts: $num_n_injected num_wide_bursts: $num_w_injected wide_burst_length: $wide_burst_len\n" | tee -a $output_file $output_file_raw

      # do several runs if random traffic
      if [ "${traffic_type}" == "random" ]; then num_iterations=5; else num_iterations=1; fi
      for ((iterations_index=0; iterations_index<$num_iterations ; iterations_index++  ))
      do
        # generate jobs
        ./util/gen_jobs.py --num_narrow_bursts $num_n_injected --num_wide_bursts $num_w_injected --wide_burst_length $wide_burst_len --traffic_type $traffic_type --rw $traffic_rw --out_dir hw/test/jobs --tb dma_mesh >> $output_file_raw
        # for each router:
        for router_tb in ${router_tb_list[@]}
        do
          # Run the simulation
          printf "$router_tb\n" >| $output_file_temp #clear file
          make run-sim-batch VSIM_TB_DUT=$router_tb JOB_NAME=mesh | tee -a $output_file_raw $output_file_temp >/dev/null
          ./util/dma_experiments_analysis.py --output_file $output_file_temp --results_file $output_file --traffic_rw $traffic_rw --router_tb $router_tb
        done
      done
    done
    printf "\n" | tee -a $output_file $output_file_raw
  done
done

printf "\n" >| $output_file_temp #clear file
rm $output_file_temp
