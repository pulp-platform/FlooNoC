# Parameters

A configuration file can declare **parameters** in a top-level `params` block and refer
to them anywhere else in the file. This keeps a value that appears in several places —
a cluster count, a base address, a region size — in one spot, and lets it be overridden
from the command line without editing the configuration.

```yaml
name: my_noc

params:
  num_clusters: 4
  cluster_base: 0x1000_0000
  cluster_size: 0x0004_0000

endpoints:
  - name: "cluster"
    array: "${num_clusters}"
    addr_range:
      base: "${cluster_base}"
      size: "${cluster_size}"
    # ...
```

Parameters are a property of _FlooGen_'s **input**, not of its output. They are resolved
before the configuration is validated, so the generated SystemVerilog and SystemRDL
contain the resolved values inlined — there is nothing left to override downstream. The
declared values are additionally emitted as `localparam`s in the generated package for
reference (see [Generated localparams](#generated-localparams)).

## References and expressions

A reference is written `${...}`, and the text inside the braces is an **expression** over
the declared parameters, not just a name:

```yaml
params:
  num_x: 4
  num_y: 8
  num_tiles: "${num_x * num_y}"        # 32
  addr_bits: "${1 << 10}"              # 1024
```

Parameters may reference each other in any order — a declaration can use one written
below it. A reference cycle is reported as an error.

### Types are inferred

There is no type annotation: the type of a parameter is the type of its value. That
matters because of how a reference is substituted:

| Form | Example | Result |
| --- | --- | --- |
| The scalar is **exactly** one reference | `size: "${cluster_size}"` | the referenced value, with its type (an integer) |
| A reference is **embedded** in text | `desc: "cluster with ${num_x} cores"` | a string, with the value interpolated |

So `"${a}-${b}"` with `a: 1` and `b: 2` is the string `"1-2"` — it is *not* evaluated as
arithmetic, because only the inside of the braces is an expression. If you want the
subtraction, write `"${a - b}"`.

### Supported expression syntax

Arithmetic (`+ - * / // % **`), bit operations (`<< >> | & ^ ~`), comparisons
(`== != < <= > >=`) and boolean operators (`and or not`) over declared parameters and
literals.

There are deliberately **no** function calls, attribute accesses, subscripts,
comprehensions or conditionals. A configuration file that can generate *structure*
rather than values stops being checkable against the JSON schema and stops being
readable; if you need eight endpoints, declare eight endpoints or use the
[`array`](endpoints.md) support.

## Overriding from the command line

Any command that reads a configuration accepts `-P` / `--param`:

```bash
floogen rtl -c my_noc.yml -o output -P num_clusters=8 -P cluster_base=0x2000_0000
```

The value is parsed as the type inferred from the declaration, so `0x`, `0b` and `_`
separators work for integers, and `true`/`false` for booleans. Overriding a parameter
that is **not** declared is an error rather than a silent no-op, so that a typo in `-P`
is reported instead of being ignored.

Note that an override makes the generated output depend on more than the configuration
file alone. When archiving or reporting a problem, record the `-P` flags alongside the
configuration.

## Generated localparams

Every declared parameter is emitted as a `localparam` in the generated package, with its
name converted to camel case and its SystemVerilog type inferred from its value:

```systemverilog
package floo_my_noc_noc_pkg;

  ////////////////////
  //   Parameters   //
  ////////////////////

  localparam int unsigned NumClusters = 4;
  localparam int unsigned ClusterBase = 268435456;
  localparam bit EnableDebug = 1'b1;
```

| Value | SystemVerilog type |
| --- | --- |
| Boolean | `bit` |
| Integer within 32 bits | `int unsigned` / `int` |
| Integer beyond 32 bits | `longint unsigned` / `longint` |
| String | `string` |

The width is chosen by magnitude rather than declared, so a base address above 4 GiB
does not silently truncate.

All declared parameters are emitted, **including ones the configuration never
references**, so that the generated package documents the full set a configuration
exposes rather than only the subset that happened to be used.

## Relation to the JSON schema

The [JSON schema](cli.md#schema) describes the configuration **after** parameters are
resolved. A file that writes `size: "${cluster_size}"` into an integer-typed field will
therefore not validate against the schema directly, even though _FlooGen_ accepts it.

## YAML anchors

YAML anchors and aliases (`&name` / `*name`) still work and are the right tool for
reusing a whole subtree via merge keys (`<<: *base`). They cannot be overridden from the
command line and do not support arithmetic, which is what `params` adds.
