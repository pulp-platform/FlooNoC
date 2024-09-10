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

_FlooGen_ is a python framework that requires Python 3.10 or later. _FlooGen_ and its dependencies can be installed using pip:

```bash
pip install .
```

### Tools

Currently, we don't provide any open-source simulation setup such as Verilator. _FlooNoC_ was internally tested and verified with QuestaSim-2023.4. To run the RTL simulations you need to have QuestaSim installed. By default, _FlooNoC_ uses the `vsim` command to run the simulations, which can be overridden by setting the `VSIM` environment variable.

### Optional dependencies

For the development with _FlooGen_, it is recommended to install the `dev` dependencies for python linting and testing:

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
