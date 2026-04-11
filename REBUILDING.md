# Rebuilding NeuroProlog

This document explains how to rebuild NeuroProlog from source, including
all four rebuild modes and how to preserve optimisations during rebuilds.

## Prerequisites

- A standard Prolog system (SWI-Prolog recommended)
- The NeuroProlog source in `src/`

---

## Quick Start

```sh
# Clean rebuild from source
./tools/self_build.sh --clean

# Verify all self-hosting invariants and equivalence tests
./tools/self_check.sh

# Full check including the complete test suite
./tools/self_check.sh --full
```

---

## Rebuild Modes

NeuroProlog supports four rebuild modes.  All modes compile
`src/neuroprolog.pl` to `neurocode/neuroprolog_nc.pl`.

### Mode 1 — Clean Rebuild

Rebuild from plain Prolog source using only the optimisation rules
compiled into the current image.

```sh
./tools/self_build.sh --clean
```

Or directly in Prolog:

```sh
swipl -g "consult('src/rebuild')" -g "rebuild_clean" -t halt
```

### Mode 2 — Rebuild Using a Prior Optimisation Dictionary

Load a previously saved dictionary snapshot and rebuild.  Rules in
the snapshot are merged with the current image; existing rules with
the same name are replaced.

```sh
./tools/self_build.sh --with-dict optimisations/my_dict.pl
```

Or directly in Prolog:

```sh
swipl -g "consult('src/rebuild')" \
      -g "rebuild_with_dict('optimisations/my_dict.pl')" \
      -t halt
```

Save the current optimisation dictionary to a snapshot file:

```sh
swipl -g "consult('src/neuroprolog')" \
      -g "npl_opt_dict_save('optimisations/snapshot.pl')" \
      -t halt
```

### Mode 3 — Rebuild with Newly Learned Optimisations Merged

Load a file of newly learned optimisation entries
(`npl_opt_entry/2` and/or `npl_opt_rule/3` terms) and merge them
with the current dictionary before rebuilding.  Existing entries
are preserved; new or updated entries are added.

```sh
./tools/self_build.sh --merge /tmp/new_opts.pl
```

Or directly in Prolog:

```sh
swipl -g "consult('src/rebuild')" \
      -g "rebuild_with_merged('/tmp/new_opts.pl')" \
      -t halt
```

### Mode 4 — Safe Fallback Rebuild

Rebuild using only the conservative baseline passes — dictionary
simplification and algebraic rules — while disabling the experimental
algorithmic transforms:

- `gaussian_elimination`
- `recursion_to_loop`
- `subterm_address_conversion`
- `nested_recursion_elimination`

The output is always correct but may be less optimised.

```sh
./tools/self_build.sh --safe
```

Or directly in Prolog:

```sh
swipl -g "consult('src/rebuild')" -g "rebuild_safe_fallback" -t halt
```

---

## Self-Compilation

To compile NeuroProlog using itself:

```sh
swipl -g "consult('src/self_host')" -g "self_compile" -t halt
```

The output is written to `neurocode/neuroprolog_nc.pl`.

---

## Verifying a Rebuild

### Self-Hosting Invariants

```sh
swipl -g "consult('src/self_host')" -g "check_self_hosting" -t halt
```

This verifies five invariants:

1. Plain source `src/neuroprolog.pl` is present.
2. `neurocode/neuroprolog_nc.pl` loads as valid Prolog.
3. Optimisation dictionary is populated.
4. Cognitive markers are recorded (if a compilation has been run).
5. Learned transform entries are present in the dictionary.

### Equivalence Tests

```sh
swipl -g "consult('tests/equivalence_tests')" \
      -g "run_equivalence_tests" -t halt
```

The equivalence test suite verifies that:

- Source-interpreted and compiled-neurocode forms produce identical
  results for a representative set of programs and queries.
- The optimisation dictionary survives a save/load round-trip.
- Cognitive marker mappings are preserved across the pipeline.
- Learned transform entries survive registration and recovery.
- Safe fallback pipeline configuration correctly disables experimental
  passes while keeping conservative passes enabled.

### Full Test Suite

```sh
swipl -g "consult('tests/run_tests')" -g "run_all_tests" -t halt
```

---

## Preserving Optimisations

Optimisations are stored in two places:

- `src/optimisation_dictionary.pl` — Named, versioned optimisation rules
- `optimisations/` — Standalone optimisation rule files

During a rebuild, `src/rebuild.pl` reads these files and ensures the
new build applies the same (or improved) set of optimisations.

To add a new optimisation:

1. Add the rule to `src/optimisation_dictionary.pl` using `opt_rule/3`.
2. Document it in `OPTIMISATION_RULES.md`.
3. Run a rebuild to verify the optimisation is applied correctly.

---

## Authoritative Source Constraint

A standard Prolog source version (`src/neuroprolog.pl`) must always
remain available and must run directly in a standard Prolog system
without preprocessing.  See `SELF_HOSTING.md` for the complete set
of self-hosting invariants.
