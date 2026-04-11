# Cognitive Markers

Cognitive markers record the correspondence between original Prolog source
predicates and their compiled neurocode equivalents.  They provide
provenance, maintainability, and self-rebuild continuity.

## Purpose

When the compiler transforms a source predicate into neurocode, the
structural relationship between the two forms would otherwise be lost.
Cognitive markers preserve that relationship so that:

- The origin of every neurocode clause is traceable.
- Rebuilds can confirm that optimised output derives from the correct
  source clause.
- Developers can inspect which optimisations were applied to any predicate.
- The compiler's self-rebuild step can verify its own output.

## Marker Directive

A predicate in a Prolog source file can be annotated with a cognitive
marker using the `:- npl_marker/2` directive:

```prolog
:- npl_marker(predicate_name/arity, marker_type).
```

The directive is placed immediately before the first clause of the
predicate.  It is preserved verbatim in the compiled neurocode.

### Recognised marker types

| Marker | Meaning |
|---|---|
| `hot_path` | Frequently executed; prioritise for optimisation. |
| `memoised` | Results are cached; do not re-evaluate unnecessarily. |
| `recursion_reduced` | Gaussian elimination has been applied. |
| `unfolded` | Data unfolding has been applied. |

Any atom may be used as a marker type; the four values above are
semantically understood by the optimiser pipeline.

### Example

```prolog
:- npl_marker(fib/2, hot_path).
:- npl_marker(fib/2, memoised).

fib(0, 0) :- !.
fib(1, 1) :- !.
fib(N, F) :-
    N > 1,
    N1 is N - 1,
    N2 is N - 2,
    fib(N1, F1),
    fib(N2, F2),
    F is F1 + F2.
```

## Mapping Schema

The compiler module `src/cognitive_markers.pl` stores mappings as dynamic
facts using the `npl_ncm_entry/5` predicate:

```prolog
npl_ncm_entry(
    OriginalClause,      % ir_clause/3 before optimisation
    CogMarker,           % marker atom, or 'none'
    NeurocodeFragment,   % Prolog clause term after optimisation
    OptSteps,            % list of optimisation step name atoms applied
    Meta                 % list of key:value metadata pairs
)
```

> **Note**: `npl_ncm_entry/5` is the internal dynamic fact.  The public
> API predicates (`npl_ncm_lookup_by_marker/2`, `npl_ncm_lookup_by_head/2`,
> `npl_ncm_all/1`, `npl_ncm_build_from_ir/4`) return results as `ncm/5`
> compound terms with the same argument order, providing a lightweight
> distinction between stored facts and returned values.

The `Meta` list always includes:

| Key | Value |
|---|---|
| `pred_sig` | `F/A` — functor/arity of the predicate |
| `source_marker` | source position term, or `no_pos` |
| `rebuild_version` | integer, starting at `1` |

## API

| Predicate | Mode | Description |
|---|---|---|
| `npl_ncm_record/5` | `(+,+,+,+,+)` | Assert a new mapping entry. |
| `npl_ncm_lookup_by_marker/2` | `(+,-)` | Retrieve entries by cognitive marker atom. |
| `npl_ncm_lookup_by_head/2` | `(+,-)` | Retrieve entries by head functor/arity. |
| `npl_ncm_all/1` | `(-)` | Retrieve all mapping entries as a list. |
| `npl_ncm_clear/0` | | Retract all mapping entries. |
| `npl_ncm_build_from_ir/4` | `(+,+,+,-)` | Build mappings from `(OrigIR, OptIR, Neurocode)`. |
| `npl_ncm_trace_report/1` | `(-)` | Produce a structured trace report list. |
| `npl_ncm_report_entry/2` | `(+,-)` | Format a single `ncm/5` entry as a report line. |

### Looking up by marker

```prolog
:- use_module('src/cognitive_markers').

% Find all predicates annotated hot_path
?- npl_ncm_lookup_by_marker(hot_path, Entry).
Entry = ncm(OrigClause, hot_path, NeurocodeFragment, OptSteps, Meta).
```

### Looking up by predicate

```prolog
% Find all mappings for fib/2
?- npl_ncm_lookup_by_head(fib(_, _), Entry).
Entry = ncm(OrigClause, Marker, NeurocodeFragment, OptSteps, Meta).
```

### Generating a trace report

```prolog
?- npl_ncm_trace_report(Report).
% Report is a list of trace_entry/4 terms:
%   trace_entry(CogMarker, OrigHead, NeurocodeFragment, OptSteps)
```

## Building Mappings During Compilation

`npl_ncm_build_from_ir/4` is called by the compiler pipeline after code
generation:

```
OrigIR     — list of ir_clause/3 terms (before optimisation)
OptIR      — list of ir_clause/3 terms (after all optimisations)
Neurocode  — list of Prolog clause terms generated from OptIR (1-to-1)
Mappings   — list of ncm/5 terms (output)
```

The mapping strategy:

1. `OptIR` and `Neurocode` are zipped 1-to-1 (code generation produces
   exactly one clause per `ir_clause`).
2. Each `OrigIR` clause is paired with the first `Neurocode` clause
   sharing the same head functor/arity.
3. `OptSteps` is the union of all registered `npl_opt_rule/3` names and
   the fixed algorithmic pass names.

## Rebuild Invariant

Cognitive markers must survive compilation and rebuilds.  During every
rebuild, `src/self_host.pl` verifies that:

- All `:- npl_marker/2` directives in the source are recognised.
- The mapping table is non-empty after compilation.

See [SELF_HOSTING.md](SELF_HOSTING.md) (Invariant 5) and
[REBUILDING.md](REBUILDING.md) (Step 3) for the enforcement procedure.

## Constraints

- All data is stored as Prolog terms; no binary or opaque formats.
- No chatbot-style reasoning is introduced by this module.
- Markers are purely for provenance, maintainability, and rebuild continuity.
- Marker types must not include attention layers or extra reasoning logic.
