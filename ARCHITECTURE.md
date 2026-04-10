# NeuroProlog Architecture

## Overview

NeuroProlog is a self-hosting Prolog interpreter written in Prolog. It compiles standard Prolog programs into *neurocode* — an optimised, transparent Prolog representation — while preserving its own optimisations during rebuilds.

## Pipeline

```
Source Prolog
     │
     ▼
 [Lexer]          src/lexer.pl
     │
     ▼
 [Parser]         src/parser.pl
     │
     ▼
 [Semantic        src/semantic_analyser.pl
  Analyser]
     │
     ▼
 [Intermediate    src/intermediate_codegen.pl
  Code Gen]
     │
     ▼
 [Optimiser]      src/optimiser.pl
     │
     ├── Gaussian Recursion Reduction   src/gaussian_recursion.pl
     ├── Subterm-Address Looping        src/subterm_addressing.pl
     ├── Logical Memoisation            src/memoisation.pl
     ├── Data Unfolding                 (within optimiser)
     ├── Pattern-Correlation            (within optimiser)
     └── Optimisation Dictionary        src/optimisation_dictionary.pl
     │
     ▼
 [Code Generator] src/codegen.pl
     │
     ▼
 Neurocode (valid Prolog)
```

## Modules

| Module | File | Purpose |
|--------|------|---------|
| Main entry | src/neuroprolog.pl | Entry point; loads all modules |
| Prelude | src/prelude.pl | Standard built-in predicates |
| Control | src/control.pl | Logical control structures |
| WAM Model | src/wam_model.pl | Warren Abstract Machine model |
| Lexer | src/lexer.pl | Tokenises Prolog source |
| Parser | src/parser.pl | Parses tokens into AST |
| Semantic Analyser | src/semantic_analyser.pl | Type-checks and validates AST |
| Intermediate Code Gen | src/intermediate_codegen.pl | Produces intermediate representation |
| Optimiser | src/optimiser.pl | Applies transformations to IR |
| Code Generator | src/codegen.pl | Emits neurocode from optimised IR |
| Memoisation | src/memoisation.pl | Logical memoisation layer |
| Gaussian Recursion | src/gaussian_recursion.pl | Recursion-elimination transforms |
| Subterm Addressing | src/subterm_addressing.pl | Bounded-address iteration |
| Optimisation Dictionary | src/optimisation_dictionary.pl | Learned algorithm transformations |
| Rebuild | src/rebuild.pl | Self-rebuild orchestration |
| Self-Host | src/self_host.pl | Self-hosting invariants |

## Neurocode

Neurocode is valid Prolog code that has been optimised by the NeuroProlog pipeline. It must be:

- Valid Prolog (loadable into any standard Prolog system)
- Inspectable and editable
- Diffable in Git
- Traceable back to original cognitive code markers
- Free of chatbot, attention, or extra reasoning logic

## WAM Model (Stage 6)

The `wam_model.pl` module implements a logical Warren Abstract Machine model in pure Prolog.  It is an *execution substrate* rather than a byte emulator — all WAM concepts are represented as Prolog data structures.

### Execution State

```
wam_state(Regs, Heap, HTop, EnvStack, ChoiceStack, Trail, Cont, Bindings)
```

| Field         | Type                       | WAM Equivalent          |
|---------------|----------------------------|-------------------------|
| `Regs`        | list of terms              | Argument registers A1…  |
| `Heap`        | assoc addr→heap_cell       | Global (heap) stack     |
| `HTop`        | integer                    | Heap top pointer (H)    |
| `EnvStack`    | list of `env/3`            | Environment stack (E)   |
| `ChoiceStack` | list of `choice/7`         | Choice point stack (B)  |
| `Trail`       | list of heap addresses     | Trail register (TR)     |
| `Cont`        | list of WAM instructions   | Program counter (P/CP)  |
| `Bindings`    | assoc                      | Dereferenced bindings   |

### Heap Cells

| Cell                     | Meaning                        |
|--------------------------|--------------------------------|
| `heap_cell(var, unbound)`| Unbound logic variable         |
| `heap_cell(ref, Addr)`   | Bound reference to Addr        |
| `heap_cell(atom, A)`     | Atomic constant A              |
| `heap_cell(int, N)`      | Integer N                      |
| `heap_cell(float, F)`    | Float F                        |
| `heap_cell(str, f(F,As))`| Structure f/n with arg addrs   |

### Environments and Choice Points

**Environment** `env(CE, CP, Vars)` — activation record for a clause body:
- `CE`: parent environment stack (restored on `proceed`)
- `CP`: saved continuation (instruction list to resume)
- `Vars`: local variable bindings

**Choice point** `choice(B, E, CP, TrailLen, HeapTop, Alts, SavedRegs)` — backtrack frame:
- `B`: saved previous choice point stack
- `E`: saved environment stack
- `CP`: saved continuation
- `TrailLen`: trail length at creation time
- `HeapTop`: heap top at creation time
- `Alts`: remaining clause alternatives
- `SavedRegs`: saved argument registers

### Trail and Backtracking

Variables allocated before the current choice point are *conditional* — any binding must be recorded on the trail.  `wam_backtrack/3` restores the trail and heap to their saved states, undoing all conditional bindings made since the choice point was created.

### Key Predicates

| Predicate                  | Purpose                                      |
|----------------------------|----------------------------------------------|
| `wam_init_state/1`         | Create empty execution state                 |
| `wam_alloc_var/3`          | Allocate unbound variable on heap            |
| `wam_alloc_atom/4`         | Allocate atom constant on heap               |
| `wam_alloc_str/4`          | Allocate compound term on heap               |
| `wam_deref/3`              | Dereference address (follows ref chain)      |
| `wam_unify/4`              | Robinson unification over heap addresses     |
| `wam_bind/4`               | Bind variable (conditional trail recording)  |
| `wam_trail_bind/4`         | Bind variable and push address to trail      |
| `wam_unwind_trail/3`       | Undo bindings back to a saved trail point    |
| `wam_push_env/3`           | Push environment frame (call)                |
| `wam_pop_env/3`            | Pop environment frame (proceed/return)       |
| `wam_push_choice/4`        | Push choice point (try first alternative)    |
| `wam_backtrack/3`          | Restore state and select next alternative    |
| `wam_execute/3`            | Execute WAM instruction list with state      |
| `wam_compile_clause/2`     | Compile Prolog clause to WAM instructions    |



The system aims toward:
- O(1) lookup and dispatch via tabling and hash-based indexing
- Polynomial-time loop forms replacing suitable recursive structures
- Bounded-address iteration replacing subterm recursion
- Memoisation of recurring logical patterns
- An algorithm dictionary storing reusable optimisation transforms
