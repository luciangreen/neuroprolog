# Optimisation Rules

This document describes the optimisation transformations applied by NeuroProlog.

## Rule Categories

### 1. Gaussian Recursion Reduction

**Module**: `src/gaussian_recursion.pl`

Applies elimination-style transforms to recursive predicate definitions, converting linear recursion into iterative accumulator form where correctness is guaranteed.

**Example**:
```prolog
% Before
length([], 0).
length([_|T], N) :- length(T, N1), N is N1 + 1.

% After (accumulator form)
length(L, N) :- length_acc(L, 0, N).
length_acc([], Acc, Acc).
length_acc([_|T], Acc, N) :- Acc1 is Acc + 1, length_acc(T, Acc1, N).
```

### 2. Subterm-Address Looping

**Module**: `src/subterm_addressing.pl`

Replaces subterm traversal via recursion with bounded-address iteration using positional subterm references.

### 3. Logical Memoisation

**Module**: `src/memoisation.pl`

Identifies recurring logical patterns and adds tabling or assert-based caching to avoid redundant recomputation.

### 4. Data Unfolding

**Within**: `src/optimiser.pl`

Unfolds finite data structures inline to enable further simplification and constant-folding.

### 5. Pattern-Correlation Optimisation

**Within**: `src/optimiser.pl`

Groups clauses by head-argument patterns and restructures dispatch to reduce unification overhead.

### 6. Optimisation Dictionary

**Module**: `src/optimisation_dictionary.pl`

Stores named algorithm transformations learned across builds. Each entry maps a recognised algorithmic pattern to a known efficient implementation.

**Format**:
```prolog
opt_rule(Name, Pattern, Replacement).
```

## Constraints

- Optimisations are applied only where correctness is preserved.
- All transforms are transparent and reversible.
- Optimisation rules are versioned and diffable in Git.
- No optimisation may introduce chatbot, attention, or reasoning code.
