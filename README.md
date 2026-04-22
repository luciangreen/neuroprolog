# NeuroProlog

* Note: NeuroProlog is a WAM interpreter, not a neuro-optimising interpreter (this feature doesn't work). A new interpreter with these features is needed.

NeuroProlog is a Prolog interpreter written in Prolog that compiles Prolog into *neurocode* — an optimised, transparent Prolog representation. It is self-hosting: it can compile itself, rebuild itself, and preserve its own optimisations during rebuilds.

## Design Principles

- **Prolog-first**: The entire system, including neurocode, is valid Prolog.
- **Self-hosting**: NeuroProlog can compile itself to neurocode using itself.
- **Transparent neurocode**: All compiled output is inspectable, editable, and diffable in Git.
- **Optimisation preservation**: Learned optimisations and cognitive markers survive rebuilds.
- **Performance direction**: Aims toward O(1) lookup and dispatch; reduces recursion to polynomial-time loop forms where possible.

## Project Structure

```
src/             Source modules (interpreter, compiler pipeline)
tests/           Test suite
examples/        Example Prolog programs
prelude/         Standard prelude definitions
optimisations/   Reusable optimisation rules
neurocode/       Generated neurocode output
tools/           Utility scripts
```

## Quick Start

Run the interpreter with a standard Prolog system (e.g. SWI-Prolog):

```sh
swipl -g "consult('src/neuroprolog')" -g "npl_main" -t halt
```

To compile a Prolog file to neurocode:

```sh
swipl -g "consult('src/neuroprolog')" -g "npl_compile('examples/hello.pl','neurocode/hello_nc.pl')" -t halt
```

To rebuild NeuroProlog from source:

```sh
swipl -g "consult('src/rebuild')" -g "rebuild_neuroprolog" -t halt
```

To run all tests:

```sh
swipl -g "run_all_tests, halt" -t halt       tests/run_tests.pl
```

To run equivalence tests:

```sh
swipl -g "run_equivalence_tests, halt" -t halt       tests/equivalence_tests.pl
```

## IR Round-Trip Inspection

Generate optimised source and inspect original-vs-regenerated reports:

```prolog
?- consult('src/neuroprolog').
?- npl_roundtrip_source_file('examples/lists.pl', 'out/lists_optimised.pl').
?- npl_roundtrip_source_diff_text('examples/lists.pl', Diff).
?- npl_roundtrip_source_side_by_side_text('examples/lists.pl', SideBySide).
```

Or use the CLI helper:

```sh
./tools/roundtrip_regen.sh examples/lists.pl out/lists_optimised.pl --diff --side-by-side
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — System architecture overview
- [REBUILDING.md](REBUILDING.md) — How to rebuild and self-optimise
- [OPTIMISATION_RULES.md](OPTIMISATION_RULES.md) — Optimisation rules and transformations
- [OPTIMISATION_DICTIONARY.md](OPTIMISATION_DICTIONARY.md) — Optimisation dictionary schema and API
- [COGNITIVE_MARKERS.md](COGNITIVE_MARKERS.md) — Cognitive markers and provenance mappings
- [SELF_HOSTING.md](SELF_HOSTING.md) — Self-hosting invariants and constraints
- [CONTRIBUTING.md](CONTRIBUTING.md) — Pull request acceptance criteria

## Non-Negotiable Constraints

1. The interpreter is written in Prolog.
2. Neurocode remains valid Prolog.
3. No chatbot, attention, or extra reasoning code.
4. A plain Prolog source version always exists and can rebuild the system.
5. Learned optimisations and cognitive markers are preserved during rebuilds.
6. Gaussian elimination and other transforms are applied only where correctness is preserved.
7. O(1) lookup and dispatch is aimed for but never falsely claimed.
8. All transformations are transparent and inspectable.
9. The interpreter can compile itself to neurocode using itself.
10. Rebuild instructions maintain self-optimisation across updates.
