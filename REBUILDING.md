# Rebuilding NeuroProlog

This document explains how to rebuild NeuroProlog from source, including how to preserve optimisations during rebuilds.

## Prerequisites

- A standard Prolog system (SWI-Prolog recommended)
- The NeuroProlog source in `src/`

## Standard Rebuild

```sh
swipl -g "consult('src/rebuild')" -g "rebuild_neuroprolog" -t halt
```

This will:
1. Load the current source from `src/`
2. Compile the source to neurocode using `src/codegen.pl`
3. Apply all optimisations from `optimisations/`
4. Restore learned optimisations from `src/optimisation_dictionary.pl`
5. Write updated neurocode to `neurocode/`
6. Verify self-consistency of the output

## Preserving Optimisations

Optimisations are stored in two places:

- `src/optimisation_dictionary.pl` — Named, versioned optimisation rules
- `optimisations/` — Standalone optimisation rule files

During a rebuild, `src/rebuild.pl` reads these files and ensures the new build applies the same (or improved) set of optimisations.

To add a new optimisation:

1. Add the rule to `src/optimisation_dictionary.pl` using `opt_rule/3`.
2. Document it in `OPTIMISATION_RULES.md`.
3. Run a rebuild to verify the optimisation is applied correctly.

## Self-Compilation

To compile NeuroProlog using itself:

```sh
swipl -g "consult('src/self_host')" -g "self_compile" -t halt
```

The output is written to `neurocode/neuroprolog_nc.pl`.

## Verifying a Rebuild

After a rebuild, verify the output:

```sh
swipl -g "consult('neurocode/neuroprolog_nc.pl')" -g "npl_main" -t halt
```

The rebuilt interpreter must produce identical results to the source interpreter on the test suite:

```sh
swipl -g "consult('tests/run_tests')" -g "run_all_tests" -t halt
```
