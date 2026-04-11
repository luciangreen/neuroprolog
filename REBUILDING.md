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

## Mandatory Rebuild Process

Every rebuild — whether triggered manually or by tooling — **must** execute
the following ten steps in order.  Skipping any step is prohibited.

1. **Keep the plain Prolog source intact.**
   Confirm that `src/neuroprolog.pl` is present and loads cleanly in a
   standard Prolog system before touching anything else.

2. **Load the existing optimisation dictionary.**
   Read `src/optimisation_dictionary.pl` (and any snapshot listed in
   `optimisations/`) into the build image before compilation begins.

3. **Load existing cognitive-code-marker mappings.**
   Read all `:- npl_marker/2` directives from the source and confirm
   they are registered in the build image.

4. **Compile source to new neurocode.**
   Run the compiler pipeline against `src/neuroprolog.pl` to produce a
   candidate `neurocode/neuroprolog_nc.pl`.

5. **Run source and neurocode test suites side by side.**

   ```sh
   swipl -g "consult('tests/run_tests')" -g "run_all_tests" -t halt
   swipl -g "consult('neurocode/neuroprolog_nc')" \
         -g "consult('tests/run_tests')" -g "run_all_tests" -t halt
   ```

6. **Compare outputs and bindings.**
   Run the equivalence test suite and confirm every test produces
   identical bindings from both the source and neurocode paths:

   ```sh
   swipl -g "consult('tests/equivalence_tests')" \
         -g "run_equivalence_tests" -t halt
   ```

7. **Reject any rebuild that loses required optimisations without explicit approval.**
   After compilation, verify that every `opt_rule/3` entry present in
   the pre-build dictionary is also present in the post-build dictionary.
   If any entry is missing the rebuild must abort with a logged error.
   Override (explicit approval) requires a separate invocation with the
   `--approve-opt-loss` flag:

   ```sh
   ./tools/self_build.sh --clean --approve-opt-loss
   ```

   Missing optimisations and the approval flag must both be written to
   `optimisations/rebuild_log.txt` with a timestamp.

8. **Merge newly learned valid optimisations into the dictionary.**
   Any `npl_opt_entry/2` or `npl_opt_rule/3` terms encountered during
   compilation that are not already present must be appended to
   `src/optimisation_dictionary.pl`:

   ```sh
   swipl -g "consult('src/rebuild')" \
         -g "rebuild_with_merged('/tmp/new_opts.pl')" \
         -t halt
   ```

9. **Write updated provenance mappings.**
   After a successful build, update `neurocode/provenance.pl` with a
   record of the form:

   ```prolog
   npl_provenance(SourceFile, NeurocodeFile, Timestamp, OptDictHash).
   ```

   This maintains a full audit trail of source → neurocode derivation.

10. **Keep previous rebuild artifacts for rollback.**
    Before overwriting `neurocode/neuroprolog_nc.pl`, copy the current
    file to `neurocode/neuroprolog_nc.pl.bak` (and rotate older backups
    to `.bak.1`, `.bak.2`, up to three generations).

---

## Rebuild Guard

`src/rebuild.pl` enforces step 7 automatically.  The predicate
`rebuild_guard/0` is called after every compilation pass and:

- reads the pre-build dictionary snapshot stored at the start of the run;
- computes the set difference of `opt_rule/3` entries;
- if the difference is non-empty and `--approve-opt-loss` was not passed,
  throws `error(opt_loss(Rules), rebuild_guard/0)` and halts with exit
  code 1;
- if approval was given, writes a structured entry to
  `optimisations/rebuild_log.txt`.

---

## Provenance Mappings

Every successful build writes a provenance record to
`neurocode/provenance.pl`.  The file is a plain Prolog file containing
one `npl_provenance/4` fact per build:

```prolog
npl_provenance(
    'src/neuroprolog.pl',           % plain source
    'neurocode/neuroprolog_nc.pl',  % compiled output
    '2026-04-11T21:00:00Z',         % UTC timestamp
    'abc123def456'                  % SHA-256 prefix of opt dict
).
```

To query the most recent provenance record:

```sh
swipl -g "consult('neurocode/provenance')" \
      -g "last_provenance(S,N,T,H), format('~w -> ~w @ ~w (~w)~n',[S,N,T,H])" \
      -t halt
```

---

## Rollback Artifacts

Before overwriting the neurocode output the build script rotates
existing files:

```
neurocode/neuroprolog_nc.pl       ← new build
neurocode/neuroprolog_nc.pl.bak   ← previous build
neurocode/neuroprolog_nc.pl.bak.1 ← build before that
neurocode/neuroprolog_nc.pl.bak.2 ← oldest retained
```

Up to three generations are kept.  See [Rollback Procedure](#rollback-procedure)
for how to restore a previous build.

---

## Maintenance Rules

Updates to NeuroProlog **must not**:

| Prohibited action | Reason |
|---|---|
| Replace neurocode with opaque encodings | Breaks human readability and Git diffability |
| Remove source-to-neurocode traceability | Breaks provenance and audit trail |
| Introduce chatbot logic | Outside scope; pollutes the interpreter |
| Introduce attention layers | Outside scope; not part of the Prolog model |
| Discard rebuild instructions | Future updates depend on them |
| Discard learned optimisations without a logged reason | Permanent loss of validated improvements |

Any pull request that violates these rules must be rejected during code
review regardless of other merit.

---

## Update Checklist

Use this checklist for every update or release.

### Pre-build

- [ ] Plain source `src/neuroprolog.pl` loads cleanly in SWI-Prolog.
- [ ] Optimisation dictionary `src/optimisation_dictionary.pl` is present
      and parses without errors.
- [ ] Cognitive-code-marker directives in source are all recognised.
- [ ] Existing `neurocode/neuroprolog_nc.pl` has been backed up (`.bak`).

### Compilation

- [ ] `./tools/self_build.sh` (or chosen mode) completes without errors.
- [ ] No `opt_rule/3` entries were lost (or loss was explicitly approved
      and logged).
- [ ] Newly discovered optimisations were merged into the dictionary.
- [ ] `neurocode/provenance.pl` was updated.

### Verification

- [ ] `./tools/self_check.sh` passes all self-hosting invariants.
- [ ] `./tools/self_check.sh --full` passes the complete test suite.
- [ ] Equivalence tests confirm identical outputs from source and neurocode.
- [ ] No regressions introduced in `tests/`.

### Post-build

- [ ] `REBUILDING.md` is still accurate for the new build.
- [ ] `SELF_HOSTING.md` invariants are still satisfied.
- [ ] `optimisations/rebuild_log.txt` is committed alongside any
      approved optimisation-loss entries.
- [ ] Rollback artifacts (`.bak` files) are present in `neurocode/`.

---

## Rollback Procedure

If a build is found to be defective after deployment, use the following
steps to restore the previous working version.

### Step 1 — Identify the last good build

```sh
# Show provenance history
swipl -g "consult('neurocode/provenance')" \
      -g "forall(npl_provenance(S,N,T,H), \
                 format('~w -> ~w @ ~w (~w)~n',[S,N,T,H]))" \
      -t halt
```

### Step 2 — Restore the neurocode file

```sh
# Restore from the most recent backup
cp neurocode/neuroprolog_nc.pl.bak neurocode/neuroprolog_nc.pl

# Or restore from an older backup
cp neurocode/neuroprolog_nc.pl.bak.1 neurocode/neuroprolog_nc.pl
cp neurocode/neuroprolog_nc.pl.bak.2 neurocode/neuroprolog_nc.pl
```

### Step 3 — Verify the restored build

```sh
./tools/self_check.sh --full
```

All invariants and tests must pass before the rollback is considered
complete.

### Step 4 — Restore the optimisation dictionary (if needed)

If the defective build also corrupted or altered the optimisation
dictionary, restore it from Git:

```sh
git checkout HEAD~1 -- src/optimisation_dictionary.pl
```

or from a snapshot:

```sh
swipl -g "consult('src/rebuild')" \
      -g "rebuild_with_dict('optimisations/snapshot.pl')" \
      -t halt
```

### Step 5 — Record the rollback

Append a rollback entry to `optimisations/rebuild_log.txt`:

```
[ROLLBACK] <timestamp> Restored neuroprolog_nc.pl from .bak due to: <reason>
```

### Step 6 — Investigate root cause

Do not proceed with a new build until the root cause of the defective
build is understood and documented.

---

## Authoritative Source Constraint

A standard Prolog source version (`src/neuroprolog.pl`) must always
remain available and must run directly in a standard Prolog system
without preprocessing.  See `SELF_HOSTING.md` for the complete set
of self-hosting invariants.
