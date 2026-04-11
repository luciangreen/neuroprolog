# Stage 9 — Gaussian-Recursion Reduction

`src/gaussian_recursion.pl`

## Overview

The Gaussian-Recursion Reduction pass transforms recursive predicate
definitions into more efficient forms by recognising linear recurrence
patterns and, where correctness can be established, rewriting them into
accumulator-passing (tail-recursive) form.

The name "Gaussian" refers to the use of Gaussian (row) elimination on
the coefficient matrices extracted from systems of mutually recursive
linear recurrences, as a prerequisite for reducing mutual or nested
recursion.

---

## Supported Recursion Classes

### `linear_tail_recursion`

```prolog
count(0).
count(N) :- N > 0, N1 is N - 1, count(N1).
```

The recursive call is the last goal in the clause body.  The predicate is
already in optimal loop form; the pass emits the group **unchanged**.
Tail-call optimisation (stack elision) is handled at the code-generation
level.

Detection criteria:
- Exactly two clauses.
- Base clause body is `ir_true`.
- Step clause body ends with `ir_seq(_, ir_call(RecCall))` where `RecCall`
  shares the same functor/arity as the head.

### `linear_accumulate(Op, Id)`

```prolog
sum([], 0).
sum([H|T], S) :- sum(T, S1), S is S1 + H.
```

A single recursive call whose result is immediately combined with extra
terms via an arithmetic operator before being returned.  The recurrence
has the shape

```
f(n) = Op(f(n-1), extra(n))
```

with identity element `Id` for `Op`.

| Operator | Identity |
|----------|----------|
| `+`      | `0`      |
| `*`      | `1`      |

The group is **rewritten** to an accumulator-passing form:

```prolog
sum(List, Result) :-
    sum_gauss_acc(List, 0, Result).

sum_gauss_acc([], Acc, Acc).
sum_gauss_acc([H|T], Acc0, Result) :-
    Acc1 is Acc0 + H,
    sum_gauss_acc(T, Acc1, Result).
```

The transformed predicate:
- Has identical observable behaviour for all ground inputs.
- Uses O(1) stack space instead of O(n) for a list of length n.
- Can be further optimised by the tail-call pass because the recursive
  call is now last.

Detection criteria:
- Exactly two clauses.
- Base clause body is `ir_true`; last argument of the base head is a
  concrete integer (the identity).
- Step clause body contains exactly one recursive call followed by an
  `is/2` goal of the form `R is Op(RecResult, Extra)` where `Op` is
  `+` or `*`.

---

## Recognised Mutual Recurrences (analysis only)

Systems of mutually recursive predicates are analysed by extracting their
coefficient matrix and applying Gaussian elimination, but are **not yet
rewritten** unless they reduce to one of the single-predicate forms above.
The matrix analysis is available as a public predicate for external passes.

---

## Public API

### `npl_gaussian_reduce(+IR, -ReducedIR)`

Top-level entry point.  Groups IR clauses by functor/arity, attempts
reduction on each group, and concatenates the results.

### `npl_is_reducible(+Group, -Pattern)`

Succeeds when `Group` matches a rewritable pattern.  Returns one of:

| Pattern | Description |
|---------|-------------|
| `linear_tail_recursion` | Last call is recursive; no arithmetic accumulation |
| `linear_accumulate(Op, Id)` | Additive/multiplicative linear recursion |

### `npl_reduce_clause_group(+Group, -Reduced)`

Apply the transformation for the detected pattern.  Falls back to
emitting `Group` unchanged if:
- The pattern is `linear_tail_recursion` (no rewrite needed), or
- The structural analysis of a `linear_accumulate` group fails.

### `npl_extract_recurrence(+Group, -Recurrence)`

Return a structured descriptor:

```prolog
recurrence(F/A, linear_tail,       info(base:BaseHead))
recurrence(F/A, linear_accumulate, info(op:Op, identity:Id, base:BaseHead))
recurrence(F/A, none,              info(reason:unrecognised))
```

### `npl_gauss_eliminate(+Matrix, -RowEchelon)`

Perform exact Gaussian (row) elimination on a matrix of `frac(N, D)`
rational numbers.  Returns the row echelon form.

### `npl_build_coefficient_matrix(+RecurrenceList, -Matrix)`

Build an n×n coefficient matrix from a list of `recurrence/3` terms.
Diagonal entries carry the linear coefficient of each recurrence; all
off-diagonal entries are `frac(0,1)`.

---

## Safety Guarantee

> **The pass never changes program semantics.**

A transformation is applied only when a syntactic proof of correctness
can be established for the recognised pattern.  Any group that does not
match a supported pattern is emitted unchanged.

The `npl_accumulator_rewrite/2` predicate calls `fail` rather than
producing incorrect output if any structural check fails, causing
`npl_reduce_clause_group/2` to fall back to the identity transform.

---

## Tests

Stage 9 tests live in `tests/run_tests.pl` under the section heading
`Stage 9: Gaussian-Recursion Reduction`.  They cover:

| Test | What is verified |
|------|-----------------|
| `gauss9_reducible_tail` | `npl_is_reducible` for tail recursion |
| `gauss9_reducible_accum_add` | `npl_is_reducible` for additive accumulate |
| `gauss9_reducible_accum_mul` | `npl_is_reducible` for multiplicative accumulate |
| `gauss9_nonreducible` | Single-clause predicate is not reducible |
| `gauss9_extract_tail` | Recurrence extractor: tail class |
| `gauss9_extract_accumulate` | Recurrence extractor: accumulate class |
| `gauss9_extract_none` | Recurrence extractor: unrecognised returns `none` |
| `gauss9_gauss_eliminate_identity` | Gaussian engine: identity matrix |
| `gauss9_gauss_eliminate_rank1` | Gaussian engine: rank-1 matrix collapses |
| `gauss9_gauss_eliminate_triangular` | Gaussian engine: upper-triangular input |
| `gauss9_build_coeff_matrix` | Coefficient matrix for a 2-recurrence system |
| `gauss9_reduce_clause_group_sum` | IR rewrite of additive `sum/2` |
| `gauss9_reduce_clause_group_tail_unchanged` | Tail group emitted unchanged |
| `gauss9_correctness_sum` | Interpreter: original sum ≡ accumulator sum |
| `gauss9_correctness_length` | Interpreter: original length ≡ accumulator length |
