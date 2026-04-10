# NeuroProlog Parser — Error Recovery Strategy

## Overview

The NeuroProlog parser (`src/parser.pl`) implements a *clause-level* error recovery
strategy: when parsing a single clause fails, the parser emits a `parse_error/2` AST
node and resumes from the next clause boundary (`.`).  Subsequent clauses are parsed
normally, so a single bad clause cannot prevent the rest of the file from loading.

---

## Error Node Format

```prolog
parse_error(Msg, Pos)
```

| Field | Description |
|-------|-------------|
| `Msg` | Atom describing the failure; currently always `syntax_error` |
| `Pos` | `pos(Line, Col)` of the first offending token, or `no_pos` for plain-token input |

---

## Recovery Algorithm

Implemented in `npl_parse_program/3`:

```
1.  Strip any leading annotation tokens.
2.  Attempt npl_parse_one_clause/4 (wrapped in catch/3 to absorb exceptions).
3a. If it succeeds → emit the parsed node, continue from the token after '.'.
3b. If it fails or throws →
      • Record the position of the first remaining token.
      • Call npl_skip_to_dot/2 to discard tokens up to and including the
        next '.' punctuation.
      • Emit parse_error(syntax_error, Pos).
      • Resume parsing from the token after '.'.
```

### `npl_skip_to_dot/2`

Consumes tokens one by one until it finds `tok(punct('.'), _)`, then returns
the remaining token list (the `.` itself is consumed, not returned).  If the
input is exhausted before a `.` is found the remainder is the empty list,
preventing an infinite loop on malformed end-of-file input.

---

## Downstream Handling

| Stage | Behaviour |
|-------|-----------|
| Semantic analyser (`src/semantic_analyser.pl`) | Passes `parse_error/2` nodes through unchanged. |
| Intermediate code generator (`src/intermediate_codegen.pl`) | Filters them out; only `analysed/3` and `clause/2` nodes are compiled into IR. |
| `npl_run/1` (parser module) | Silently skips `parse_error/2` nodes during execution. |

---

## Source Mapping

When the parser is invoked via `npl_parse_pos/2` or `npl_parse_string_pos/2`
(which use the lexer's positioned output), every AST node carries a
`pos(Line, Col)` term derived from the first token of the clause.

Plain-token input (`npl_parse/2`, `npl_parse_string/2`) uses `no_pos` throughout
because positional information is unavailable after wrapping.

---

## Limitations and Future Work

1. **Single-level recovery only.**  The parser recovers at clause granularity; it
   does not attempt to recover within a clause (e.g. skip a bad argument and
   continue parsing the rest of the argument list).

2. **No error messages yet.**  The `Msg` field is a fixed atom.  Future work should
   include the offending token text and a human-readable description.

3. **Module system.**  The parser recognises `:- module(Name, Exports).` directives
   syntactically but does not yet interpret them to switch the active module context.
   Module-qualified terms (`Module:Goal`) are parsed correctly via the `:` operator
   (xfy, 600).

4. **Operator declarations.**  `:- op(Prec, Type, Op).` directives are parsed as
   ordinary directives but do not dynamically extend the operator table at parse
   time.  A future stage can process the directive list before or during parsing.

5. **Exception propagation.**  Parser exceptions (e.g. stack overflow on pathological
   input) are caught by `catch/3` and treated as syntax errors to prevent crashes,
   but the exception detail is currently discarded.
