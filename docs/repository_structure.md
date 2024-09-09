# Repository Structure and Contents

This document describes the structure of the repository and the contents of the directories.

## The `hw` hardware directory

The `hw` directory contains all the hardware-related files for all the SystemVerilog IPs. The directory is structured as follows:

- `*.sv`: SystemVerilog packages and modules for the IPs.
- `test`: Verification IPs (VIPs) such as monitors, random initiators for the testbenches.
- `tb`: Testbenches for the IPs.

## The `floogen` _FlooGen_ directory

The `floogen` directory contains the Python framework for _FlooGen_ to generate complete _FlooNoC_ networks based on a simple configuration file. The directory is structured as follows:

- `examples`: A couple of example configuration files.
- `model`: The python models for routers, network interfaces and endpoints that are used by _FlooGen_.
- `templates`: Mako templates for the generation of the SystemVerilog files.
- `tests`: Unit tests for the _FlooGen_ framework.
- `floo_gen.py`: The main script for _FlooGen_.
- `config_parser.py`: The configuration parser for _FlooGen_.
- `utils.py`: Various utility functions for _FlooGen_.
