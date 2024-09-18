#!/bin/bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

GUI=""
WORK="work"
WORK_COUNT=0
SIMULATOR="vsim"
SIMULATOR_COUNT=0
VALID_SIMULATORS=("vsim")
TRAFFIC_DIR="hw/test/jobs"
TRAFFIC_DIR_COUNT=0
TRAFFIC_PATTERN=""
TRAFFIC_PATTERN_COUNT=0
VALID_TRAFFIC_PATTERNS=("random" "hbm" "onehop" "bit_complement" "bit_reverse" "bit_rotation" "neighbor" "shuffle" "transpose" "tornado" "single_dest_boundary" "single_dest_center")
TRAFFIC_RW="read"
TRAFFIC_RW_COUNT=0
VALID_TRAFFIC_RW=("read" "write")
TB_DUT=""
TB_FLAG_COUNT=0

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == -h || ${!i} == --help ]]; then
    echo "Run the simulation with the specified options."
    echo
    echo -e "\033[1;32mOptions:\033[0m"
    echo -e "  \033[1;34m--tb <testbench>\033[0m            Specify the testbench to use."
    echo -e "  \033[1;34m-s, --simulator <simulator>\033[0m Specify the simulator to use. Valid options are: ${VALID_SIMULATORS[*]}"
    echo -e "  \033[1;34m--gui\033[0m                       Run the simulation with GUI mode enabled."
    echo -e "  \033[1;34m--work <work>\033[0m               Specify the work library."
    echo -e "  \033[1;34m-h, --help\033[0m                  Display this help message."
    echo
    echo -e "\033[1;32mTraffic Options:\033[0m"
    echo -e "  \033[1;34m--traffic <pattern>\033[0m         Simulate a traffic pattern. Use --show-traffic-patterns to see valid options."
    echo -e "  \033[1;34m--show-traffic-patterns\033[0m     Display the valid traffic patterns."
    echo -e "  \033[1;34m--traffic-dir <directory>\033[0m   Specify the job directory."
    echo -e "  \033[1;34m--traffic-rw <type>\033[0m         Specify the traffic read/write type. Valid options are: ${VALID_TRAFFIC_RW[*]}"
    exit 0
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --show-traffic-patterns ]]; then
    echo "Valid traffic patterns are: ${VALID_TRAFFIC_PATTERNS[*]}"
    exit 0
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --tb ]]; then
    ((TB_FLAG_COUNT++))
    if [[ $TB_FLAG_COUNT -gt 1 ]]; then
      echo "Error: --tb flag specified more than once."
      exit 1
    fi
    ((i++))
    TB_DUT=${!i}
  fi
done

if [[ -z $TB_DUT ]]; then
  echo "Error: --tb flag not specified."
  exit 1
fi

if [[ ! -f "hw/tb/$TB_DUT.sv" ]]; then
  echo "Error: Testbench file hw/tb/$TB_DUT.sv not found."
  exit 1
fi

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == -s || ${!i} == --simulator ]]; then
    ((SIMULATOR_COUNT++))
    if [[ $SIMULATOR_COUNT -gt 1 ]]; then
      echo "Error: -s or --simulator specified more than once."
      exit 1
    fi
    ((i++))
    SIMULATOR=${!i}
    if [[ ! " ${VALID_SIMULATORS[@]} " =~ " ${SIMULATOR} " ]]; then
      echo "Error: Invalid simulator specified. Valid options are: ${VALID_SIMULATORS[*]}"
      exit 1
    fi
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --gui ]]; then
    GUI="--gui"
    break
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --work ]]; then
    ((WORK_COUNT++))
    if [[ $WORK_COUNT -gt 1 ]]; then
      echo "Error: --work specified more than once."
      exit 1
    fi
    ((i++))
    WORK=${!i}
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --traffic-dir ]]; then
    ((TRAFFIC_DIR_COUNT++))
    if [[ $TRAFFIC_DIR_COUNT -gt 1 ]]; then
      echo "Error: --traffic-dir specified more than once."
      exit 1
    fi
    ((i++))
    TRAFFIC_DIR=${!i}
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --traffic ]]; then
    ((TRAFFIC_PATTERN_COUNT++))
    if [[ $TRAFFIC_PATTERN_COUNT -gt 1 ]]; then
      echo "Error: --traffic specified more than once."
      exit 1
    fi
    ((i++))
    TRAFFIC_PATTERN=${!i}
    if [[ ! " ${VALID_TRAFFIC_PATTERNS[@]} " =~ " ${TRAFFIC_PATTERN} " ]]; then
      echo "Error: Invalid traffic name specified. Valid options are: ${VALID_TRAFFIC_PATTERNS[*]}"
      exit 1
    fi
  fi
done


for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == --traffic-rw ]]; then
    ((TRAFFIC_RW_COUNT++))
    if [[ $TRAFFIC_RW_COUNT -gt 1 ]]; then
      echo "Error: --traffic-rw specified more than once."
      exit 1
    fi
    ((i++))
    TRAFFIC_RW=${!i}
    if [[ ! " ${VALID_TRAFFIC_RW[@]} " =~ " ${TRAFFIC_RW} " ]]; then
      echo "Error: Invalid traffic rw specified. Valid options are: ${VALID_TRAFFIC_RW[*]}"
      exit 1
    fi
  fi
done

if [[ -n $TRAFFIC_PATTERN ]]; then
  make jobs TRAFFIC_OUTDIR=$TRAFFIC_DIR TRAFFIC_TYPE=$TRAFFIC_PATTERN TRAFFIC_RW=$TRAFFIC_RW
fi

if [[ -n $GUI ]]; then
  make run-sim VSIM_TB_DUT=$TB_DUT JOB_DIR=$TRAFFIC_DIR WORK=$WORK
else
  make run-sim-batch VSIM_TB_DUT=$TB_DUT JOB_DIR=$TRAFFIC_DIR WORK=$WORK
fi
