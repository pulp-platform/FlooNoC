# Installation

_FlooGen_ is distributed as a standard Python package available on PyPI. It provides the `floogen` command-line interface (CLI) to generate your networks.

## Prerequisites

- **Python**: Version 3.10 or higher.
- **Git**: To clone the repository (only required for source installation).

---

## Install from PyPI

If you just want to use the tool to generate networks, install it directly from PyPI with either [`uv`](https://github.com/astral-sh/uv) (recommended) or `pip`.

=== "uv"

    **To install globally (recommended):**
    This makes the `floogen` command available everywhere in your terminal.
    ```bash
    uv tool install floogen
    # and verify installation
    floogen --help
    ```

    **To run without installing (ephemeral):**
    You can run _FlooGen_ instantly without cluttering your system:
    ```bash
    uvx floogen --help
    ```

=== "pip"

    1.  **Create and activate a virtual environment** (recommended):
        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        ```

    2.  **Install the package**:
        ```bash
        pip install floogen
        ```
        
    3.  **Verify installation:**
        ```bash
        floogen --help
        ```
        
---

## Install from Source

Use this method if you need to modify _FlooGen_, contribute to the project, or if you are working with the full _FlooNoC_ hardware repository.

First, clone the _FlooNoC_ repository:

```bash
git clone https://github.com/pulp-platform/FlooNoC.git && cd FlooNoC
```

=== "uv"

    When using `uv` inside the repository, no manual installation step is strictly necessary. `uv` will automatically detect the project configuration.
    
    ```bash
    uv run floogen --help
    ```

    _This command will automatically set up the environment and install dependencies defined in `pyproject.toml`._
=== "pip"

    1.  **Create and activate a virtual environment**:
        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        ```
    
    2.  **Install in editable mode**:
        ```bash
        pip install -e .
        ```

## Documentation

The documentation is built using [`zensical`](https://zensical.org/), which is defined as a development dependency. To build it you can run:

=== "uv"
    ```bash
    uv run zensical build
    ```
    
    _The development dependencies are implicit in `uv` i.e. `uv run --group dev` is not necessary._

=== "pip"
    1.  **Create and activate a virtual environment** (if not already done):
        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        ```
        
    2.  **Install the development dependencies**:
        ```bash
        pip install .[dev]
        ```
    
If you want to serve the documentation locally for easier browsing, run:

=== "uv"
    ```bash
    uv run zensical serve -o
    ```

=== "pip"
    ```bash
    zensical serve -o
    ```
