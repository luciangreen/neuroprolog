# Nested Recursion Elimination — Stage 11

## Overview

Stage 11 of the NeuroProlog optimiser attempts to eliminate or reduce
nested recursion in predicate clause groups.  A predicate is considered
*nested-recursive* when one of its clauses makes two or more direct
recursive calls in its body.

Transformation is only applied when:

- **Equivalence can be shown by rule** — e.g., memoisation is provably
  correct for any side-effect-free predicate.
- **A verified transformation schema exists** — e.g., the structural-
  traversal → address-loop schema of Stage 10, or the
  linear-accumulate schema of Stage 9.

Otherwise the original clause group is preserved unchanged.

---

## Classification

The classifier (`npl_nested_classify/2`) assigns each multi-clause
predicate group one of four patterns:

### `nested_pure`

**Condition**  
Two or more recursive calls in a step body; predicate is free of
observable side effects; no more specific shape is detected.

**Transform applied**  
Memoisation — each non-base clause body is wrapped in
`ir_memo_site(Head, Body)`.

**Safety argument**  
For a pure predicate, every call with the same arguments produces the
same result.  Caching repeated sub-problems is therefore semantics-
preserving.

**Example**  
```prolog
rep(0, a).
rep(N, R) :- rep(N, T), rep(T, R).
```
Step clause becomes:
```
ir_memo_site(rep(N,R), ir_seq(ir_call(rep(N,T)), ir_call(rep(T,R))))
```

---

### `nested_structural`

**Condition**  
A step clause whose head's first argument is a compound constructor
term (e.g., `node(L, R)`, `s(X)`) and that makes two or more recursive
calls in its body.

**Transform applied**  
Loop conversion — each multi-recursive step body is wrapped in
`ir_loop_candidate(Body)`.  The Stage-10 subterm-address pass then
converts eligible candidates to `ir_addr_loop` nodes, replacing
structural recursion with explicit address-based iteration.

**Safety argument**  
`ir_loop_candidate` is an identity wrapper unless Stage 10 can prove an
`arg/3`-descent pattern.  Wrapping is therefore always safe; the
Stage-10 pass applies address iteration only when it is equivalence-
preserving.

**Example**  
```prolog
tree_sum(leaf(X), X).
tree_sum(node(L, R), S) :-
    tree_sum(L, SL), tree_sum(R, SR), S is SL + SR.
```
Step clause body becomes:
```
ir_loop_candidate(
    ir_seq(ir_call(tree_sum(L, SL)),
           ir_seq(ir_call(tree_sum(R, SR)),
                  ir_call(is(S, SL + SR)))))
```

---

### `nested_data_fold(Op)`

**Condition**  
A step clause with two or more recursive calls whose body contains an
`is/2` goal with a binary arithmetic operator `Op` ∈ `{+, *}`.

**Transform applied**  
1. Gaussian/accumulator rewriting via `npl_gaussian_reduce/2` (Stage 9).
   If Stage 9 can reduce the group (e.g., it exposes a linear-
   accumulate shape after analysing the inner call), the reduced form
   is used.
2. Memoisation is applied to the (possibly Gaussian-reduced) group.

**Safety argument**  
Gaussian reduction is safe under its own schema guarantee.  Memoisation
safety follows from purity (purity is checked before classifying as
`nested_data_fold`).

**Example**  
```prolog
fib(0, 0).
fib(1, 1).
fib(N, R) :-
    N1 is N - 1, fib(N1, R1),
    N2 is N - 2, fib(N2, R2),
    R is R1 + R2.
```

---

### `nested_opaque`

**Condition**  
Any of the following:
- Fewer than two recursive calls in all clause bodies (linear or
  tail-recursive — already handled by Stage 9).
- Two or more recursive calls but the predicate has observable side
  effects (`write`, `assert`, `retract`, I/O, etc.).
- Pattern not matched by the structural or data-fold classifiers and
  the predicate is impure.

**Transform applied**  
None.  The clause group is preserved unchanged.

---

## The Seven Techniques

| # | Technique | Where applied in Stage 11 |
|---|-----------|--------------------------|
| 1 | Gaussian-reduction transforms | `nested_data_fold`: `npl_gaussian_reduce/2` is attempted first |
| 2 | Loop conversion | `nested_structural`: step bodies wrapped in `ir_loop_candidate` |
| 3 | Accumulator introduction | `nested_data_fold`: via the Gaussian-reduction module |
| 4 | Memoisation | `nested_pure`, `nested_data_fold`: `ir_memo_site` wrapping |
| 5 | Data unfolding | `npl_nr_unfold_data/2`: propagates `ir_true` through sequences |
| 6 | Simplification passes | `npl_nr_simplify_body/2`: removes `ir_seq(ir_true, X)` and `ir_seq(X, ir_true)` |
| 7 | Subterm address iteration | `nested_structural` + Stage-10 pass converts `ir_loop_candidate` to `ir_addr_loop` |

---

## Unsupported Patterns

The following nested-recursion patterns are recognised as `nested_opaque`
and are **not** transformed.  The reason is given for each.

### True nested call in argument position

```prolog
f(N, R) :- f(N, R1), f(R1, R).
```

This calls `f` on its own output.  Without a known fixed-point or
idempotence law for `f`, the transformation would change observable
behaviour.  The predicate can still benefit from memoisation if it is
pure (classified `nested_pure`).

### Mutual nested recursion

```prolog
even(0).    even(N) :- N > 0, odd(N1), N1 is N - 1.
odd(N)  :- N > 0, even(N1), N1 is N - 1.
```

Mutual recursion is detected separately by the semantic analyser
(`recursion_class: mutual`) and is outside the scope of Stage 11.

### Non-linear arithmetic combination

```prolog
g(N, R) :- g(N, R1), g(N, R2), R is R1 * R1 + R2.
```

The combining expression `R1 * R1 + R2` is non-linear in `R1`.
Stage 9's Gaussian reduction requires a linear combination, so it
cannot reduce this group.  Stage 11 will still apply memoisation if
the predicate is pure.

### Predicates with side effects

Any predicate that calls `write`, `writeln`, `nl`, `format`, `assert`,
`retract`, `read`, `nb_setval`, or similar side-effecting goals is
classified `nested_opaque` regardless of its recursion structure.
Memoisation of such predicates would suppress repeated side effects,
altering the observable behaviour of the program.

### Ackermann and hyperexponential recursion

```prolog
ack(0, N, V)  :- V is N + 1.
ack(M, 0, V)  :- M1 is M - 1, ack(M1, 1, V).
ack(M, N, V)  :- N > 0, N1 is N - 1, ack(M, N1, V1),
                 M1 is M - 1, ack(M1, V1, V).
```

The step clause makes two recursive calls where the second call's
first argument depends on the *result* of the first call.  This makes
the structure hyperexponential and prevents accumulator introduction.
The predicate is pure, so Stage 11 classifies it as `nested_pure` and
applies memoisation, which limits the growth of repeated sub-problems
at the cost of memo-table memory.

---

## Module Interface

```prolog
:- use_module('src/nested_recursion').

% Top-level pass (used by the optimiser pipeline)
npl_nested_eliminate_pass(+IR, -OptIR)

% Classifier
npl_nested_classify(+ClauseGroup, -Class)

% Per-class transform
npl_nested_apply_transform(+Group, +Class, -Reduced)

% Utilities
npl_ir_count_rec_calls(+F, +A, +IRBody, -Count)
npl_ir_body_pure(+F, +A, +IRBody)          % succeeds when pure
npl_nr_unfold_data(+IRBody, -Unfolded)
npl_nr_simplify_body(+IRBody, -Simplified)
```

---

## Integration in the Optimiser Pipeline

Stage 11 is inserted between Stage 9 (Gaussian reduction) and the
memoisation annotation pass:

```
dict-rule rewriting
  → Stage 9 Gaussian reduction
  → Stage 11 Nested recursion elimination   ← new
  → Memoisation annotation pass
  → Stage 10 Subterm-address looping
```

This ordering ensures that:

1. Linear-accumulate patterns are already reduced by Stage 9 before
   Stage 11 inspects the groups.
2. `ir_memo_site` nodes introduced by Stage 11 are visible to code
   generation downstream.
3. `ir_loop_candidate` nodes introduced by Stage 11 are picked up by
   the Stage-10 subterm-address pass.
