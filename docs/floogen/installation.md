# Installation

_FlooGen_ is distributed as a standard Python package. It provides the `floogen` command-line interface (CLI) to generate your networks.

!!! note "PyPI Availability"
    _FlooGen_ is currently **not** published on PyPI. You must clone the repository and install it locally from the source.

## Prerequisites

- **Python**: Version 3.10 or higher.
- **Git**: To clone the repository.


First, clone the _FlooNoC_ repository:

```bash
git clone https://github.com/pulp-platform/FlooNoC.git && cd FlooNoC
```

Then install _FlooGen_ using with either `uv` or `pip`. We recommend using [uv](https://github.com/astral-sh/uv) for installation. It is significantly faster than `pip` and automatically manages virtual environments and dependencies for you, keeping your system Python clean. However, if you prefer the standard Python workflow, `pip` works just as well.

=== "uv"



    1.  **Install uv** (if you haven't already):
        ```bash
        curl -LsSf https://astral.sh/uv/install.sh | sh
        ```
    2.  **Run with uv**:
        You can run _FlooGen_ directly in an ephemeral environment without manual installation:
        ```bash
        uv run floogen --help
        ```

=== "pip"

    1.  **Create and activate a virtual environment** (optional but recommended):
        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        ```

    2.  **Install the package**:
        ```bash
        pip install .
        ```

## Verification

To verify that the installation was successful, try running the help command. You should see the CLI usage information.

=== "uv"
    ```bash
    uv run floogen --help
    ```

=== "pip"
    ```bash
    floogen --help
    ```

## Development & Documentation

If you plan to contribute to _FlooGen_ or build the documentation locally, you should install the optional dependencies.

=== "uv"
    ```bash
    # Nothing to do, `uv run --group dev` will handle it automatically
    ```


=== "pip"
    ```bash
    pip install .[dev,docs]
    ```

The documentation is built using [Zensical](https://zensical.org/). To build the documentation locally, run:

=== "uv"
    ```bash
    uv run --group docs zensical build
    ```

=== "pip"
    ```bash
    zensical build
    ```

If you want to serve the documentation locally for easier browsing, run:

=== "uv"
    ```bash
    uv run --group docs zensical serve -o
    ```

=== "pip"
    ```bash
    zensical serve -o
    ```
