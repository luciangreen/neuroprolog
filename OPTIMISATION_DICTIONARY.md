# Optimisation Dictionary

The optimisation dictionary is a named, versioned store of algorithm
transformations maintained by `src/optimisation_dictionary.pl`.  Every
optimisation rule known to NeuroProlog lives in this dictionary so that
it can be queried, updated, serialised, and restored across rebuilds.

## Purpose

- Provide a single authoritative source of all optimisation rules.
- Make every rule named, versioned, and diffable in Git.
- Allow new rules to be registered at runtime and persisted.
- Prevent learned optimisations from being silently lost during rebuilds.
- Link algorithm transformations to their cognitive code markers.

## Two-Level Schema

The dictionary has two levels that serve different parts of the pipeline:

### Level 1 — `npl_opt_rule/3` (term-rewriting rules)

Used by the optimiser's term-rewriting pass.  Each fact maps a rule name
to a pattern/replacement pair:

```prolog
npl_opt_rule(+Name, +Pattern, +Replacement)
```

The optimiser matches `Pattern` against IR nodes and replaces with
`Replacement`.  Both are IR terms (see `src/intermediate_codegen.pl`
for the IR vocabulary).

**Example**:

```prolog
% identity: ir_call(true) → ir_true
npl_opt_rule(identity,
    ir_call(true),
    ir_true).

% add_zero_right: R is X + 0 → R is X
npl_opt_rule(add_zero_right,
    ir_call(is(R, X + 0)),
    ir_call(is(R, X))).
```

### Level 2 — `npl_opt_entry/2` (rich metadata entries)

Extends Level 1 with full provenance metadata for documentation,
rebuild guards, and cognitive-marker linkage:

```prolog
npl_opt_entry(+Name, +Fields)
```

`Fields` is a list of `Key:Value` pairs:

| Field | Type | Description |
|---|---|---|
| `category` | atom | Optimisation category (see below). |
| `trigger` | IR term | IR pattern that activates the rule. |
| `original` | atom | Human-readable description of the unoptimised form. |
| `transformed` | atom | Human-readable description of the optimised form. |
| `proof` | atom | Proof or justification tag. |
| `conditions` | list | List of applicability condition atoms. |
| `perf_notes` | atom | Performance impact notes. |
| `cognitive_marker` | atom | Linked cognitive-marker atom, or `none`. |
| `examples` | list | List of `example(Input, Expected)` terms. |
| `version` | integer | Version number; increment on every change. |

**Example**:

```prolog
npl_opt_entry(add_zero_right,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, x + 0)),
      original:'R is X + 0 — adds zero unnecessarily',
      transformed:'R is X — zero term eliminated',
      proof:additive_identity,
      conditions:[arithmetic_pure],
      perf_notes:'Removes one arithmetic operation per call site',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, x+0)), ir_call(is(r, x))) ],
      version:1 ]).
```

## Supported Categories

| Category | Description |
|---|---|
| `simplification` | Boolean/control-flow simplifications (identity, fail elimination). |
| `algebraic_reduction` | Arithmetic identities (add zero, multiply by one, etc.). |
| `memoisation` | Cache repeated calls to pure predicates. |
| `recursion_elimination` | Convert tail-recursion or linear recursion to accumulator form. |
| `loop_conversion` | Convert recursion to bounded-iteration loops. |
| `accumulator_introduction` | Introduce accumulator arguments to enable tail-call optimisation. |
| `constant_folding` | Evaluate constant sub-expressions at compile time. |
| `gaussian_transform` | Gaussian-elimination-style recursion reduction. |
| `subterm_address_iteration` | Replace subterm traversal with bounded-address iteration. |

## API

| Predicate | Mode | Description |
|---|---|---|
| `npl_opt_rule/3` | `(?Name, ?Pattern, ?Replacement)` | Query/assert term-rewriting rules. |
| `npl_opt_entry/2` | `(?Name, ?Fields)` | Query/assert rich metadata entries. |
| `npl_opt_dict_rules/1` | `(-Rules)` | Retrieve all rules as a list. |
| `npl_opt_dict_entries/1` | `(-Entries)` | Retrieve all entries as a list. |
| `npl_opt_register/3` | `(+Name, +Pattern, +Replacement)` | Register a new rule (idempotent). |
| `npl_opt_entry_register/2` | `(+Name, +Fields)` | Register a new entry (idempotent). |
| `npl_opt_lookup/2` | `(+Name, -Rule)` | Look up a rule by name. |
| `npl_opt_entry_lookup/2` | `(+Name, -Entry)` | Look up an entry by name. |
| `npl_opt_entry_field/3` | `(+Name, +Field, -Value)` | Read one field from a named entry. |
| `npl_opt_entry_to_rule/3` | `(+Name, -Pattern, -Replacement)` | Project an entry to a rule triple. |
| `npl_opt_dict_save/1` | `(+File)` | Serialise all rules and entries to a Prolog file. |
| `npl_opt_dict_load/1` | `(+File)` | Load (consult) a previously saved dictionary file. |

## Adding a New Rule

1. Add the `npl_opt_rule/3` fact to `src/optimisation_dictionary.pl`.
2. Add a corresponding `npl_opt_entry/2` fact with full metadata.
3. Set `version:1` (or increment if updating an existing entry).
4. Document the rule in [OPTIMISATION_RULES.md](OPTIMISATION_RULES.md).
5. Run a rebuild to verify the rule is applied correctly.

Every pull request that introduces an optimisation rule **must** include
all five steps; see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

**Example — adding a new algebraic identity**:

```prolog
% In src/optimisation_dictionary.pl

npl_opt_rule(sub_zero_right,
    ir_call(is(R, X - 0)),
    ir_call(is(R, X))).

npl_opt_entry(sub_zero_right,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, x - 0)),
      original:'R is X - 0 — subtracts zero unnecessarily',
      transformed:'R is X — zero term eliminated',
      proof:subtractive_identity,
      conditions:[arithmetic_pure],
      perf_notes:'Removes one arithmetic operation per call site',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, x-0)), ir_call(is(r, x))) ],
      version:1 ]).
```

## Persistence and Snapshots

The dictionary is stored entirely as plain Prolog facts in
`src/optimisation_dictionary.pl`.  It can also be saved to and loaded
from standalone snapshot files in `optimisations/`.

### Saving a snapshot

```sh
swipl -g "consult('src/neuroprolog')" \
      -g "npl_opt_dict_save('optimisations/snapshot.pl')" \
      -t halt
```

### Loading a snapshot

```sh
swipl -g "consult('src/neuroprolog')" \
      -g "npl_opt_dict_load('optimisations/snapshot.pl')" \
      -t halt
```

Snapshot files are plain Prolog and can be inspected, diffed, and
committed to Git like any other source file.

## Rebuild Guard

During every rebuild, `src/rebuild.pl` calls `rebuild_guard/0`, which:

1. Reads the pre-build dictionary snapshot saved at the start of the run.
2. Computes the set difference of `npl_opt_rule/3` entries.
3. If any entry is missing and `--approve-opt-loss` was not passed,
   throws `error(opt_loss(Rules), rebuild_guard/0)` and halts with
   exit code 1.
4. If approval was given, writes a structured entry to
   `optimisations/rebuild_log.txt`.

Silent loss of a validated optimisation is a **build failure**, not a warning.
See [REBUILDING.md](REBUILDING.md) for the full rebuild protocol.

## Backward Compatibility

`npl_opt_rule/3` is preserved for the optimiser's term-rewriting pass.
`npl_opt_entry/2` extends the schema; it does not replace `npl_opt_rule/3`.
`npl_opt_entry_to_rule/3` projects a rich entry back to a rule triple
where the `trigger` field contains a usable IR pattern.

## Constraints

- All dictionary data is valid Prolog; no binary or opaque formats.
- Rule names are atoms; they must be unique within the dictionary.
- Every entry must include the `version` field; increment on every change.
- No entry may introduce chatbot, attention, or extra reasoning logic.
- Correctness of every transform must be justified by the `proof` field.
