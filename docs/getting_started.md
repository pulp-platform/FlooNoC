# Getting Started

## Prerequisites

### Bender

_FlooNoC_ uses [Bender](https://github.com/pulp-platform/bender) for hardware IPs and dependency management. Bender is available through Cargo or as pre-compiled binaries for Linux, macOS, and Windows:

=== "Cargo"

    ```bash
    cargo install bender
    ```

=== "Precompiled"

    ```bash
    curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh
    ```

Make sure that the Bender binary directory is in your `PATH`, or set the `BENDER` environment variable to the path of the Bender binary.

### Python

Some parts of _FlooNoC_ including the _FlooGen_ generator are written in Python. The required Python version is 3.10 or higher. You can install Python from the [official website](https://www.python.org/downloads/).

### Simulation Tools

Currently, we don't provide any open-source simulation setup such as Verilator. _FlooNoC_ was internally tested and verified with QuestaSim-2023.4. To run the RTL simulations you need to have QuestaSim installed. By default, _FlooNoC_ uses the `vsim` command to run the simulations, which can be overridden by setting the `VSIM` environment variable.

## Installation

Clone the repository from GitHub:

```bash
git clone https://github.com/pulp-platform/FlooNoC.git
```
Install the python dependencies and _FlooGen_:

```bash
pip install .
```

## Usage

### Running the Testbenches

Now you can compile and run the testbenches with the following command:

```bash
make compile-sim
make run-sim VSIM_TB_DUT=tb_floo_dut
```

### Generating a _FlooNoC_ Network

where you replace `tb_floo_dut` with the testbench that you want to simulate.

To generate a _FlooNoC_ network using the _FlooGen_ generator, you can use the following command:

```bash
floogen -c examples/floo_dut.yaml -o generated
```

## Optional dependencies

For the development on _FlooGen_, it is recommended to install the `dev` dependencies for python linting and testing:

=== "bash"

    ```bash
    pip install .[dev]
    ```

=== "zsh"

    ```zsh
    pip install .\[dev\]

    ```
For documentation generation, you can install the `docs` dependencies:

=== "bash"

    ```bash
    pip install .[docs]
    ```

=== "zsh"

    ```zsh
    pip install .\[docs\]

    ```
