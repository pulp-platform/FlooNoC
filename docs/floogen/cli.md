# CLI Usage

_FlooGen_ provides a structured command-line interface to perform specific generation tasks. Unlike previous versions which used a single entry point with many flags, the CLI uses **subcommands** to isolate different functionalities (RTL generation, visualization, querying, etc.).

## Synopsis

```bash
floogen <command> [options]
```

To see the available options for a specific command, pass the `-h` or `--help` flag after the command name:

```bash
floogen rtl --help
```

## Commands

### `rtl`

This is the primary command for generating the hardware description. It generates **both** the SystemVerilog package (containing types and routing tables) and the top-level module (instantiating the NoC).

**Usage:**

```bash
floogen rtl -c <config_file> -o <output_dir>
```

**Common Options:**

  * `-c, --config <file>`: Path to the YAML NoC configuration file.
  * `-o, --outdir <dir>`: Directory where generated files will be written. If omitted, output is printed to stdout.
  * `--no-format`: Disable auto-formatting (e.g., Verible) of the generated SystemVerilog.

-----

### `pkg`

Generates **only** the SystemVerilog package (`*_pkg.sv`). This is useful if you are iterating on the architecture but don't need to regenerate the structural top-level, or if you only need the type definitions for other parts of your design.

**Usage:**

```bash
floogen pkg -c <config_file> -o <output_dir>
```

-----

### `top`

Generates **only** the structural top-level module (`*_top.sv`).

**Usage:**

```bash
floogen top -c <config_file> -o <output_dir>
```

-----

### `visualize`

Generates a graphical representation of the network topology. This is critical for verifying that your complex graph connections match your mental model.

!!! note "Requires the optional `viz` extra"

    This command depends on `matplotlib`, which is **not** installed by default. The
    `visualize` command is only available once the optional `viz` extra is installed.
    Without it, `visualize` is hidden from the CLI and will not appear in `floogen --help`.

    === "uv"

        **As a global tool:**
        ```bash
        uv tool install 'floogen[viz]'
        ```

        **Inside the repository** (one-off, for the `visualize` command):
        ```bash
        uv run --extra viz floogen visualize -c <config_file>
        ```

    === "pip"

        ```bash
        pip install 'floogen[viz]'
        ```

**Usage:**

```bash
floogen visualize -c <config_file> [-o <output_dir>]
```

  * If `-o` is specified, it saves the plot (e.g., as a PDF or PNG).
  * If `-o` is omitted, it attempts to open an interactive window (requires a display server).

-----

### `rdl`

Generates the **SystemRDL** description for the endpoint address regions. This is used to integrate the NoC's address map into larger system-level register automation flows.

**Usage:**

```bash
floogen rdl -c <config_file> -o <output_dir>
```

By default, this produces a single `<name>_addrmap.rdl` file containing all endpoints.
If any endpoint declares [`rdl_addrmap_grp`](endpoints.md#systemrdl-addrmap-groups), one
`<name>_addrmap_<group>.rdl` file is generated per distinct group instead, each
containing only the endpoints tagged with that group (endpoints without
`rdl_addrmap_grp` are included in every group).

-----

### `query`

Introspection tool to query specific values from the internal graph representation without generating code. This is useful for scripts that need to know the number of endpoints, specific address ranges, or parameter values derived by the generator.

**Usage:**

```bash
# Example: Get the number of endpoints
floogen query -c <config_file> "endpoints"

# Example: Get a specific attribute
floogen query -c <config_file> "endpoints.my_cluster.addr_range.base"
```

-----

### `template`

Renders custom, user-provided Mako templates using the *FlooGen* network model. This allows you to generate auxiliary files (e.g., C headers, documentation, verification scripts) that are not part of the core *FlooNoC* distribution.

**Usage:**

```bash
floogen template -c <config_file> --template <template_file> -o <output_dir>
```

-----

### `traffic`

Generates DMA **job files** for simulating synthetic traffic loads in RTL simulation. These can be read by the DMA test nodes to drive AXI transactions over the NoC. The network model (`-c <config_file>`) provides the topology, address map, and protocol data widths, so the same traffic description adapts automatically to different NoC configurations.

traffic is currently generated either via:

1. A **traffic configuration file** (`--traffic-cfg`), which explicitly describes the traffic flows between endpoints.
2. A **built-in mesh traffic pattern** (`--traffic-type`), which does not require a dedicated traffic configuration file.

**Usage:**

```bash
# Generating traffic using traffic configuration files
floogen traffic -c <config_file> --traffic-cfg <traffic_file> -o <output_dir>

#  Generating traffic using built-in mesh traffic patterns
floogen traffic -c <config_file> --traffic-type <pattern> --traffic-rw <read|write> -o <output_dir>
```

**Common Options:**

  * `-c, --config <file>`: Path to the network (topology) YAML configuration file.
  * `-o, --outdir <dir>`: Directory where the job files are written. Defaults to `jobs`.
  * `--traffic-name <name>`: Base name of the emitted job files. Defaults to the traffic configuration's file stem (`--traffic`) or `mesh` (`--traffic-type`).
  * `-v, --verbose`: Print detailed information about what the tool is doing (the resolved traffic model, emitted job indices, and any warnings). Without it, generation is silent.

**Mode-specific Options:**

  * `--traffic-cfg <file>`: Path to the traffic configuration file (see the [traffic configuration format](../floonoc/getting_started.md#traffic-configuration-file)).
  * `--traffic-type <pattern>`: Name of the built-in traffic pattern to generate (e.g. `hbm`, `uniform`, `shuffle`). See the [full list of patterns](../floonoc/getting_started.md#built-in-mesh-traffic-patterns).
  * `--traffic-rw <read|write>`: Direction of the built-in traffic pattern (default: `write`). Only used with `--traffic-type`.
  * `--num-narrow-bursts <n>` / `--num-wide-bursts <n>`: Number of narrow/wide bursts generated per node (defaults: `10` / `100`). Only used with `--traffic-type`.
  * `--narrow-burst-length <n>` / `--wide-burst-length <n>`: Narrow/wide burst length in beats (defaults: `1` / `16`). Only used with `--traffic-type`.

!!! note
    The emitted files are named `<traffic_name>_<idx>.txt` for wide traffic and `<traffic_name>_<idx+100>.txt` for narrow traffic, where `idx = x * num_y + y` is the linear index of the initiator node at mesh coordinate `(x, y)`. For a network without a wide protocol (e.g. a single-AXI mesh), wide bursts are skipped and only the narrow job files carry transfers.
