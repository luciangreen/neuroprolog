# Tools

This directory contains utility scripts for NeuroProlog development.

## Available Tools

### self_build.sh — Self-Build Script

Rebuild NeuroProlog from its own source using one of four modes.

```sh
# Clean rebuild from plain Prolog source (default)
./tools/self_build.sh --clean

# Rebuild loading a prior optimisation dictionary
./tools/self_build.sh --with-dict optimisations/my_dict.pl

# Rebuild merging newly learned optimisations
./tools/self_build.sh --merge /tmp/new_opts.pl

# Safe fallback rebuild (experimental transforms disabled)
./tools/self_build.sh --safe
```

All modes write output to `neurocode/neuroprolog_nc.pl`.

### self_check.sh — Self-Check Script

Verify NeuroProlog self-hosting invariants and equivalence properties.

```sh
# Check invariants and equivalence tests
./tools/self_check.sh

# Also run the full test suite
./tools/self_check.sh --full
```

Exits with status 0 on success, 1 on any failure.

## Suggested Future Tools

- `lex_dump.pl` — Dump the token stream for a Prolog file
- `parse_dump.pl` — Dump the AST for a Prolog file
- `ir_dump.pl` — Dump the IR for a Prolog file
- `diff_nc.sh` — Diff two neurocode files and highlight semantic changes
- `check_markers.pl` — Verify all cognitive code markers are preserved in neurocode
