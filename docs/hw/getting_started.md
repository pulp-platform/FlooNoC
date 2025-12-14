

# Getting Started with FlooNoC

This guide covers how to set up the environment to simulate and verify the *FlooNoC* hardware IPs (SystemVerilog). If you are looking to generate a network configuration, please refer to the [FlooGen](../floogen/overview.md) documentation.

## Prerequisites

### 1. Bender
*FlooNoC* uses [Bender](https://github.com/pulp-platform/bender) for hardware IP management and dependency handling. Bender is available as pre-compiled binaries for Linux, macOS, and Windows (or can be installed via Cargo).

=== "Precompiled"

    ```bash
    curl --proto '=https' --tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh
    ```

=== "Cargo"

    ```bash
    cargo install bender
    ```


!!! note
    Ensure the Bender binary is in your `PATH`, or set the `BENDER` environment variable to point to it.

Then you can check whether Bender is installed correctly by fetching the dependencies:

```bash
bender checkout
```

This is not strictly necessary since subsequent Make commands will perform this step automatically, but it is useful to verify that Bender is set up correctly.

### 2. Simulation Tools

The testbenches provided with *FlooNoC* are designed to be run with QuestaSim and VCS.

!!! note
    Other simulators might work, but are not officially supported. Verilator is known to have issues with testbench components that use advanced SystemVerilog features.

## Installation

Clone the repository to get the hardware IPs and verification environment:

```bash
git clone https://github.com/pulp-platform/FlooNoC.git && cd FlooNoC
```

## Running Simulations

We provide a Makefile to simplify compiling and running the testbenches.

### 1\. Compile the Hardware

Compile the RTL and testbenches:

=== "QuestaSim"

    ```bash
    make compile-vsim
    ```

=== "VCS"

    ```bash
    make compile-vcs TB_DUT=<testbench_name>
    ```

### 2\. Run a Testbench

You can run specific testbenches by setting the `TB_DUT` variable:

=== "QuestaSim"

    ```bash
    make run-vsim TB_DUT=<testbench_name>
    ```

    or in batch mode:

    ```bash
    make run-vsim-batch TB_DUT=<testbench_name>
    ```

=== "VCS"

    ```bash
    make run-vcs TB_DUT=<testbench_name>
    ```

### Available Testbenches

You can substitute `<testbench_name>` with other testbenches found in `hw/tb/`:

| Testbench | Description |
| :--- | :--- |
| `tb_floo_router` | Verifies a single router instance. |
| `tb_floo_axi_chimney` | Verifies the AXI-to-NoC network interface. |
| `tb_floo_nw_mesh` | Simulates a small mesh network of routers. |
| `tb_floo_rob` | Simulates out-of-order buffer behavior. |
