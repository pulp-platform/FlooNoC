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

  * `-c, --config <file>`: Path to the YAML configuration file.
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
