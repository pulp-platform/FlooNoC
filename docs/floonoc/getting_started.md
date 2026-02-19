

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
    Minimum required version of bender is `0.30.0`. Ensure the Bender binary is in your `PATH`, or set the `BENDER` environment variable to point to it.

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


## Advanced mesh testbenches

There are additional testbenches for entire mesh networks:

| Testbench | Description |
| :--- | :--- |
| `tb_floo_axi_mesh` | Simulates a full mesh network with single-AXI endpoints. |
| `tb_floo_nw_mesh` | Simulates a full mesh network with narrow-wide AXI endpoints. |

Those testbenches require generated networks from FlooGen. Please refer to the [FlooGen documentation](../floogen/installation.md) for instructions on how to install FlooGen.

### Generating Mesh Testbenches

Then, you can generate either of the testbenches with:

=== "uv"

    ```bash
    uv run floogen rtl -c floogen/examples<mesh>_<route_algo>.yml -o generated
    ```

=== "pip"

    ```bash
    floogen rtl -c floogen/examples<mesh>_<route_algo>.yml -o generated
    ```

Where `<mesh>` is either `axi_mesh` or `nw_mesh`, and `<route_algo>` is either `xy`, `id` or `src`.

### Compiling Testbenches

Then, you can compile and run the generated testbenches as described above, with additional Bender flags to include the generated files:

=== "QuestaSim"

    ```bash
    make compile-vsim EXTRA_BENDER_FLAGS="-t <mesh>"
    ```

=== "VCS"

    ```bash
    # Currently not supported
    ```

### Generating Traffic

The endpoint of those testbenches are DMA models that accept job files to perform AXI transactions over the network. This is better documented in the DMA documentation [here](https://github.com/pulp-platform/iDMA/tree/master/jobs). There is a script `util/gen_jobs.py` that can help generate job files for testing.

For instance you can generate random traffic with:

```bash
make jobs DUT=<mesh> ROUTE_ALGO=<route_algo> TRAFFIC_TYPE=<traffic_type> TRAFFIC_RW=<read_or_write>
```

Currently supported traffic types are:

| Traffic Type | Description |
| :--- | :--- |
| `hbm` | Traffic goes to boundary nodes (simulating HBM). |
| `uniform` | Traffic is uniformly distributed across all nodes. |
| `onehop` | Each node accesse its upper neighbor. |
| `bit_complement` | Each node accesses its bit-complement address. |
| `bit_reverse` | Each node accesses its bit-reversed address. |
| `bit_rotation` | Each node accesses its bit-rotated address. |
| `neighbor` | Each node accesses one of its neighbors (X-direction). |
| `shuffle` | Each node accesses another node in a shuffled manner. |
| `transpose` | Each node accesses another node in a transposed manner. |
| `tornado` | Each node accesses a node halfway across the network. |
| `hotspot` | Traffic goes to a single hotspot node. |
| `hotspot_boundary` | Traffic goes to a single hotspot node on the boundary. |

### Running Mesh Testbenches

You can run the generated testbenches with:

=== "QuestaSim"

    ```bash
    make run-vsim TB_DUT=tb_floo_<mesh> EXTRA_BENDER_FLAGS="-t <mesh>"
    ```
=== "VCS"

    ```bash
    # Currently not supported
    ```
