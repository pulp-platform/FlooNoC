# Copyright 2023 University of Modena and Reggio Emilia.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Gianluca Bellocchi <gianluca.bellocchi@unimore.it>

#!/bin/bash

FLOOGEN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FLOOGEN_VENV_NAME=floogen # should match name specified in pyproject.toml

POETRY='poetry@main' # temporary

ENV_LIST=$($POETRY env list)
ENV_PATH=$($POETRY env info --path)

# check if previous floogen virtual environment exists
echo "$ENV_LIST" | grep "venv" &> /dev/null
if [ $? == 0 ]; then
	echo "Old $FLOOGEN_VENV_NAME virtual environment exists"
    echo "$ENV_PATH"
	echo "Do you want to proceed and install $FLOOGEN_VENV_NAME again?"

	select yn in "yes" "no"; do
		case $yn in
			yes ) 	break;;
			no ) 	exit;;
		esac
	done
fi

# check if other floogen virtual environments exist
echo "$ENV_LIST" | grep $FLOOGEN_VENV_NAME &> /dev/null
if [ $? == 0 ]; then
	echo "Old $FLOOGEN_VENV_NAME virtual environment exists"
    echo "$ENV_PATH"
	echo "Do you want to proceed and install $FLOOGEN_VENV_NAME again?"

	select yn in "yes" "no"; do
		case $yn in
			yes ) 	break;;
			no ) 	exit;;
		esac
	done
fi

# install environment (does not update lock if it exists)
echo "Installing $FLOOGEN_VENV_NAME virtual environment"
$POETRY install --sync

# to activate environment
if [[ "$VIRTUAL_ENV" == "" ]]
then
	echo "Activating $FLOOGEN_VENV_NAME virtual environment"
    $POETRY shell
fi