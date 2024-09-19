#!/bin/bash
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0


EXTRA_BENDER_FLAGS=""
SIMULATOR="vsim"
SIMULATOR_COUNT=0
VALID_SIMULATORS=("vsim")
WORK="work"
WORK_COUNT=0

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == -h || ${!i} == --help ]]; then
    echo "Compile all the IPs in the project."
    echo
    echo -e "\033[1;32mOptions:\033[0m"
    echo -e "  \033[1;34m-t, --target <target>\033[0m       Specify the additional bender targets."
    echo -e "  \033[1;34m-s, --simulator <simulator>\033[0m Specify the simulator to use. Valid options are: ${VALID_SIMULATORS[*]}"
    echo -e "  \033[1;34m--work <work>\033[0m               Specify the work library."
    echo -e "  \033[1;34m-h, --help\033[0m                  Display this help message."
    exit 0
  fi
done

for ((i=1; i<=$#; i++)); do
  if [[ ${!i} == -t || ${!i} == --target ]]; then
    ((i++))
    EXTRA_BENDER_FLAGS+=" -t ${!i}"
  fi
done

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

make compile-sim WORK=${WORK} EXTRA_BENDER_FLAGS="${EXTRA_BENDER_FLAGS}"
