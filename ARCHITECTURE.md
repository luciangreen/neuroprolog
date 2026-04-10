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

## Performance Direction

The system aims toward:
- O(1) lookup and dispatch via tabling and hash-based indexing
- Polynomial-time loop forms replacing suitable recursive structures
- Bounded-address iteration replacing subterm recursion
- Memoisation of recurring logical patterns
- An algorithm dictionary storing reusable optimisation transforms
