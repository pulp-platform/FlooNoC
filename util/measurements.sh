#!/bin/bash
# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

types=("nw" "wo")
measurement_type=("bw" "lat")
direction=("one_dir" "two_dir")
# direction=("one_dir")
num_injected=(0 2 4 8 16 32 64)
burst_len=(16)
num_bursts=(16)

# make a clean compilation
make clean sim_compile

for m in ${measurement_type[@]}
do
    for t in ${types[@]}
    do
        if [ $t == "wo" ]
        then
            tb_dut="tb_floo_dma_wide_only_chimney"
        else
            tb_dut="tb_floo_dma_nw_chimney"
        fi
        for d in ${direction[@]}
        do
            if [ $d == "one_dir" ]
            then
                dir_args=""
            else
                dir_args="--bidir"
            fi
            for i in ${num_injected[@]}
            do
                for b in ${!burst_len[@]}
                do
                    job_name="${m}_${d}_${t}_${i}_${burst_len[$b]}"
                    job_dir="test/jobs/${job_name}"
                    # Perform narrow wide BW measurements with constant number of wide bursts
                    # and increasing number of narrow bursts
                    if [ $m == "bw" ]
                    then
                        # Generate the job files
                        ./util/gen_jobs.py --out_dir $job_dir $dir_args --num_narrow_bursts $i --num_wide_bursts ${num_bursts[$b]} --wide_burst_length ${burst_len[$b]}
                        # Run the simulation
                        make sim_run_c VSIM_TB_DUT=$tb_dut JOB_DIR=$job_dir JOB_NAME=nw_chimney2chimney LOG_FILE=$job_dir/stats.log & > /dev/null
                    else
                        # Generate the job files
                        ./util/gen_jobs.py --out_dir $job_dir $dir_args --num_narrow_bursts ${num_bursts[$b]} --num_wide_bursts $i --wide_burst_length ${burst_len[$b]}
                        # Run the simulation
                        make sim_run_c VSIM_TB_DUT=$tb_dut JOB_DIR=$job_dir JOB_NAME=nw_chimney2chimney LOG_FILE=$job_dir/stats.log & > /dev/null
                    fi
                done
            done
        done
    done
done

# Wait for all simulations to finish
wait

echo "Finished all simulations"

# Generate csv files
for m in ${measurement_type[@]}
do
    for t in ${types[@]}
    do
        for d in ${direction[@]}
        do
            for b in ${!burst_len[@]}
            do
                file_name="${m}_${d}_${t}_${burst_len[$b]}.csv"
                # Headers
                echo "num_narrow_bursts,num_wide_bursts,narrow_read_bw,narrow_write_bw,wide_read_bw,wide_write_bw,narrow_read_lat,narrow_write_lat,wide_read_lat,wide_write_lat" > $file_name
                for i in ${num_injected[@]}
                do
                    job_name="${m}_${d}_${t}_${i}_${burst_len[$b]}"
                    job_dir="test/jobs/${job_name}"
                    log_file="${job_dir}/stats.log"
                    narrow_read_line=$(grep "\[Monitor narrow 0\]\[Read\]" ${log_file})
                    narrow_write_line=$(grep "\[Monitor narrow 0\]\[Write\]" ${log_file})
                    wide_read_line=$(grep "\[Monitor wide 0\]\[Read\]" ${log_file})
                    wide_write_line=$(grep "\[Monitor wide 0\]\[Write\]" ${log_file})
                    num_wide_bursts=$(cat ${log_file} | grep "\[DMA1\] Launching" | awk '{print $4}')
                    num_narrow_bursts=$(cat ${log_file} | grep "\[DMA101\] Launching" | awk '{print $4}')
                    wide_read_lat=$(echo $wide_read_line | awk '{print $6}')
                    wide_write_lat=$(echo $wide_write_line | awk '{print $6}')
                    narrow_read_lat=$(echo $narrow_read_line | awk '{print $6}')
                    narrow_write_lat=$(echo $narrow_write_line | awk '{print $6}')
                    wide_read_bw=$(echo $wide_read_line | awk '{print $13}' | sed 's/%//')
                    wide_write_bw=$(echo $wide_write_line | awk '{print $13}' | sed 's/%//')
                    narrow_read_bw=$(echo $narrow_read_line | awk '{print $13}' | sed 's/%//')
                    narrow_write_bw=$(echo $narrow_write_line | awk '{print $13}' | sed 's/%//')
                    echo "$num_narrow_bursts,$num_wide_bursts,$narrow_read_bw,$narrow_write_bw,$wide_read_bw,$wide_write_bw,$narrow_read_lat,$narrow_write_lat,$wide_read_lat,$wide_write_lat" >> $file_name
                done
            done
        done
    done
done
