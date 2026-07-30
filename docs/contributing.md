# Contributing

## Git Hooks

The repository ships a set of [`pre-commit`](https://pre-commit.com) hooks that catch
formatting, linting and licensing problems before they reach a pull request. The same
hooks run on every pull request in the `lint` workflow, so installing them locally saves
a review cycle.

Hooks are managed with [`prek`](https://prek.j178.dev), a drop-in replacement for
`pre-commit` written in Rust. It is part of the `dev` dependency group, so no separate
installation is needed:

```bash
uv run prek install --allow-missing-config --hook-type pre-commit --hook-type pre-push
```

`--allow-missing-config` keeps `git commit` working when you check out a branch that
predates the hook configuration, for instance an older pull request.

!!! tip "You can keep using `pre-commit`"

    The configuration in `.pre-commit-config.yaml` is the standard format, so
    `pre-commit install` works just as well if you already have it installed. `prek` is
    only the recommended runner because it is faster and needs no Python environment of
    its own.

### What Runs When

| Stage | Hooks |
| ----- | ----- |
| `pre-commit` | `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-toml`, `check-merge-conflict`, `check-case-conflict`, `mixed-line-ending`, `ruff check`, `ty check`, `reuse lint-file`, `typos` |
| `pre-push` | `pytest` |

`ruff`, `ty`, `reuse`, `typos` and `pytest` run through `uv`, so their versions come from
`uv.lock` and are identical locally and in CI. Verible and Slang are *not* part of the
hooks, they only run in CI.

### Running the Hooks Manually

```bash
# All hooks over the whole repository, as CI does it.
uv run prek run --all-files

# A single hook, e.g. after adding a waiver.
uv run prek run typos --all-files

# Only the files changed in the last commit.
uv run prek run --last-commit
```

Some hooks fix files instead of just reporting, for example `trailing-whitespace`. When
that happens the commit is aborted with the fixes applied but unstaged; review them,
`git add` them and commit again.

To skip the hooks for a single commit, use `git commit --no-verify`. Please only do this
for work-in-progress commits that you clean up before opening a pull request, since CI
runs the same checks anyway.

### Adding New Files

Two hooks regularly trip up new files:

`reuse lint-file` requires every file to carry copyright and license information, see
the [REUSE specification](https://reuse.software/spec/). For new SystemVerilog and Python
files, copy the header from a neighbouring file. Files that cannot hold a comment, such
as images, are annotated by path in `REUSE.toml` instead.

`typos` spell-checks comments, documentation and identifiers. It deliberately runs
without `--write-changes`, because its guesses for identifiers can be wrong. If it
flags a term that is spelled correctly, add it to `_typos.toml`:

```toml
[default.extend-words]
# An `inport` is an input port, not an `import`.
inport = "inport"
```
