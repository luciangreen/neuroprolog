# Optimisations

This directory contains standalone optimisation rule files that can be loaded into the optimisation dictionary.

Each file defines a set of `npl_opt_rule/3` facts in the format:

```prolog
npl_opt_rule(Name, Pattern, Replacement).
```

## Built-in Optimisation Rules

Built-in rules are defined in `src/optimisation_dictionary.pl`.

## Adding New Optimisations

1. Create a new `.pl` file in this directory.
2. Define `npl_opt_rule/3` facts.
3. Register the file in `src/optimisation_dictionary.pl` or load it at runtime with:

```prolog
:- consult('optimisations/my_rules.pl').
```

4. Document the new rules in `OPTIMISATION_RULES.md`.
