# Contributing to NeuroProlog

Thank you for contributing.  This document explains the rules that every
contribution must follow in order to keep NeuroProlog self-hosting,
transparent, and maintainable.

## Guiding Principles

1. **Prolog-first** — The entire system, including neurocode, is valid Prolog.
2. **Transparency** — All transforms are readable, inspectable, and diffable.
3. **Self-hosting continuity** — Every change must preserve the ability of
   the system to compile and rebuild itself.
4. **No scope creep** — Chatbot, attention, or extra reasoning code is
   out of scope and must not be introduced.

---

## Pull Request Acceptance Criteria

A pull request is acceptable **only if** it satisfies all of the
following criteria.

### 1. Plain Prolog interpreter source is preserved

- `src/neuroprolog.pl` must remain present and must load cleanly in a
  standard Prolog system (e.g. SWI-Prolog) without preprocessing.
- No part of the plain-Prolog interpreter may be removed, obfuscated,
  or replaced with a non-Prolog representation.

### 2. Neurocode remains valid Prolog

- All files in `neurocode/` must be valid, loadable Prolog.
- Neurocode must not contain binary encodings, opaque data, or formats
  that cannot be read and edited as plain text.
- Every neurocode clause must be traceable back to a source clause via
  the cognitive-marker mapping table.

### 3. Tests pass

- `./tools/self_check.sh` must pass all self-hosting invariants.
- `./tools/self_check.sh --full` must pass the complete test suite.
- The equivalence test suite must confirm identical outputs from the
  plain-source and neurocode paths:

  ```sh
  swipl -g "consult('tests/equivalence_tests')" \
        -g "run_equivalence_tests" -t halt
  ```

- No existing tests may be removed or weakened.

### 4. No chatbot or attention code

- The pull request must not introduce chatbot, language-model, attention,
  or neural-network code anywhere in the repository.
- Optimisation logic must remain in explicit, inspectable Prolog rules.

### 5. No optimisation logic hidden in opaque formats

- All optimisation rules must remain as `npl_opt_rule/3` and
  `npl_opt_entry/2` facts in `src/optimisation_dictionary.pl`.
- Optimisation logic must not be encoded in binary files, compiled
  blobs, or any format that cannot be read as Prolog text.

### 6. New optimisation rules are documented

Every pull request that adds or changes an optimisation rule **must**:

1. Add or update the `npl_opt_rule/3` fact in
   `src/optimisation_dictionary.pl`.
2. Add or update the corresponding `npl_opt_entry/2` fact with full
   metadata (category, trigger, original, transformed, proof,
   conditions, perf_notes, cognitive_marker, examples, version).
3. Increment the `version` field of any changed entry.
4. Add or update the rule description in
   [OPTIMISATION_RULES.md](OPTIMISATION_RULES.md).
5. Run a full rebuild and confirm the rule is applied correctly.

See [OPTIMISATION_DICTIONARY.md](OPTIMISATION_DICTIONARY.md) for the
dictionary schema and [OPTIMISATION_RULES.md](OPTIMISATION_RULES.md) for
rule descriptions.

### 7. Rebuild continuity is preserved or improved

- `REBUILDING.md`, `SELF_HOSTING.md`, and all rebuild scripts under
  `tools/` must not be removed or emptied.
- The mandatory ten-step rebuild process documented in `REBUILDING.md`
  must continue to work after the change.
- Learned optimisations (`npl_opt_rule/3` entries) must not be silently
  removed.  Any intentional removal requires the `--approve-opt-loss`
  flag and a log entry in `optimisations/rebuild_log.txt`.
- Cognitive-marker mappings must be preserved across the pipeline.

---

## Checklist for Contributors

Before opening a pull request, verify each item:

### General

- [ ] `src/neuroprolog.pl` loads cleanly in SWI-Prolog.
- [ ] `neurocode/neuroprolog_nc.pl` loads as valid Prolog.
- [ ] No chatbot, attention, or language-model code has been introduced.
- [ ] No optimisation logic has been hidden in opaque formats.

### If adding or changing an optimisation rule

- [ ] `npl_opt_rule/3` fact added or updated in
      `src/optimisation_dictionary.pl`.
- [ ] `npl_opt_entry/2` fact added or updated with full metadata fields.
- [ ] `version` field incremented.
- [ ] Rule described in `OPTIMISATION_RULES.md`.
- [ ] Full rebuild completed and rule verified as applied.

### Tests

- [ ] `./tools/self_check.sh` passes.
- [ ] `./tools/self_check.sh --full` passes.
- [ ] Equivalence tests pass.
- [ ] No existing tests removed or weakened.

### Rebuild continuity

- [ ] `REBUILDING.md` and `SELF_HOSTING.md` still accurate.
- [ ] Rebuild scripts under `tools/` still functional.
- [ ] No `npl_opt_rule/3` entries silently removed.
- [ ] Cognitive-marker mappings survive the pipeline.

---

## Grounds for Automatic Rejection

A pull request **must be rejected** if it:

| Violation | Reason |
|---|---|
| Removes `src/neuroprolog.pl` or makes it non-loadable | Breaks Prolog-first invariant |
| Adds non-Prolog content to `neurocode/` | Breaks neurocode-as-Prolog invariant |
| Introduces chatbot or attention code | Out of scope |
| Hides optimisation logic in opaque formats | Breaks transparency |
| Adds an optimisation rule without documentation | Breaks dictionary integrity |
| Removes `REBUILDING.md` or `SELF_HOSTING.md` | Breaks rebuild continuity |
| Removes learned optimisations without approval and logging | Silent loss of validated improvements |
| Causes any test to fail | Regression |

---

## Commit Messages

Use short, imperative commit messages:

- `add optimisation rule: sub_zero_right`
- `fix: parser handles empty clause body`
- `docs: update REBUILDING.md for Mode 4`
- `refactor: extract unification helper`

---

## Further Reading

- [ARCHITECTURE.md](ARCHITECTURE.md) — System architecture and pipeline
- [OPTIMISATION_RULES.md](OPTIMISATION_RULES.md) — Optimisation rule descriptions
- [OPTIMISATION_DICTIONARY.md](OPTIMISATION_DICTIONARY.md) — Dictionary schema and API
- [COGNITIVE_MARKERS.md](COGNITIVE_MARKERS.md) — Cognitive markers and provenance
- [REBUILDING.md](REBUILDING.md) — Rebuild procedure and modes
- [SELF_HOSTING.md](SELF_HOSTING.md) — Self-hosting invariants
