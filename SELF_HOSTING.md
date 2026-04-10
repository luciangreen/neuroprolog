# Self-Hosting Invariants

NeuroProlog is self-hosting. This document defines the invariants that must be maintained.

## Invariant 1: Plain Source Always Present

A plain Prolog source version of NeuroProlog must always exist in `src/`. It must:

- Run directly in a standard Prolog system without preprocessing.
- Compile itself into neurocode using `src/self_host.pl`.
- Rebuild the interpreter from source using `src/rebuild.pl`.
- Produce identical behaviour to the neurocode version on all tests.

## Invariant 2: Neurocode Is Valid Prolog

All files in `neurocode/` must be valid Prolog. They must not contain:
- Binary or byte-level representations.
- Opaque encoded data.
- Chatbot, attention, or extra reasoning code.

## Invariant 3: Optimisations Are Preserved

Every rebuild must preserve:
- All entries in `src/optimisation_dictionary.pl`.
- All memoisation patterns registered in `src/memoisation.pl`.
- All cognitive code markers embedded in source.

## Invariant 4: Self-Compilation Produces Equivalent Output

Running `self_compile` on the source must produce neurocode that:
- Passes all tests in `tests/`.
- Produces correct results for all examples in `examples/`.
- Contains no regressions relative to the previous build.

## Invariant 5: Cognitive Code Markers

Source predicates may be annotated with cognitive code markers using the `:- npl_marker/2` directive. These markers must survive compilation into neurocode.

```prolog
:- npl_marker(predicate_name/arity, marker_type).
```

Recognised marker types:
- `hot_path` — frequently executed predicate; prioritise for optimisation.
- `memoised` — results are cached; do not re-evaluate unnecessarily.
- `recursion_reduced` — Gaussian elimination has been applied.
- `unfolded` — data unfolding has been applied.

## Checking Self-Hosting

```sh
swipl -g "consult('src/self_host')" -g "check_self_hosting" -t halt
```

This verifies all five invariants above.
