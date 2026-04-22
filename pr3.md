Title

Add public IR-to-source regeneration pipeline to NeuroProlog

Goal

Implement a stable, documented, user-facing pipeline that converts NeuroProlog IR back into readable, valid Prolog source.

This should let users:

* inspect optimiser output
* round-trip source through IR and back
* write optimised regenerated .pl files
* compare original and transformed programs
* support future self-hosting and rebuild workflows

The current repo already has low-level generation support through npl_generate/2, but it lacks a clear public API, compatibility naming, polished round-trip helpers, rich emitting mode, and end-to-end tests.

Problem

Users naturally try commands like:

?- npl_code_generate(IR, Clauses).

but currently receive:

ERROR: Unknown procedure: npl_code_generate/2

The repo needs a proper public API for IR-to-source generation.

Scope

Build this in stages.

The initial deliverable should be small and reliable:

* public wrapper predicates
* round-trip helpers
* readable output
* tests
* docs

Later stages may add:

* annotated emitting mode
* special-node rendering
* source comments/metadata
* CLI utilities

Non-goals for initial stage

Do not try to:

* perfectly preserve original formatting
* preserve source comments exactly
* preserve original variable names in all cases
* build a full decompiler with exact source reconstruction
* implement new optimiser passes unrelated to IR→source

The aim is:

* valid Prolog regeneration
* readable output
* semantic faithfulness to IR

Required architecture understanding

The intended pipeline is:

Source
-> npl_lex/2
-> npl_parse/2
-> npl_analyse/2
-> npl_intermediate/2
-> npl_optimise/2
-> IR-to-source generation
-> .pl output

The repo already has low-level generation support in codegen, including:

* npl_generate/2
* npl_generate_full/3
* npl_ir_to_body/2
* npl_ir_to_body_emitting/3
* file/text writing helpers

This task is to expose and stabilise that as a public subsystem.

⸻

Stage 1 — Public API wrappers

Objective

Expose a clear public IR→source API without forcing users to know internal predicate names.

Requirements

Add and export the following predicates:

npl_ir_to_source(+IR, -Clauses).
npl_ir_to_source_text(+IR, -Text).
npl_ir_to_source_file(+IR, +File).
npl_code_generate(+IR, -Clauses).

Behaviour

npl_ir_to_source/2

* Input: IR list, usually a list of ir_clause/3
* Output: list of Prolog clause terms
* Internally delegate to existing npl_generate/2

npl_code_generate/2

* Compatibility alias to npl_ir_to_source/2
* Must exist because users will reasonably expect this name

npl_ir_to_source_text/2

* Convert IR to clauses, then serialise to readable Prolog text
* Output should be a string or atom
* Text should be valid Prolog and loadable after writing to file

npl_ir_to_source_file/2

* Write regenerated source text to file
* Output must be consultable with consult/1

Acceptance examples

?- IR = [ir_clause(p, ir_call(q), info([]))],
   npl_ir_to_source(IR, Clauses).
Clauses = [(p :- q)].
?- IR = [ir_clause(foo(1), ir_true, info([]))],
   npl_code_generate(IR, Clauses).
Clauses = [foo(1)].

⸻

Stage 2 — Clause/body conversion wrappers

Objective

Provide safe, public wrappers around low-level IR conversion helpers.

Requirements

Export:

npl_ir_to_clause_public(+IRClause, -Clause).
npl_ir_to_body_public(+IRBody, -Body).

Behaviour

* Wrap internal npl_ir_to_clause/2
* Wrap internal npl_ir_to_body/2
* Fail clearly or throw structured errors for malformed IR
* Document which IR nodes are supported in basic mode

Acceptance examples

?- npl_ir_to_clause_public(ir_clause(p, ir_call(q), info([])), Clause).
Clause = (p :- q).
?- npl_ir_to_body_public(ir_seq(ir_call(a), ir_call(b)), Body).
Body = (a, b).

⸻

Stage 3 — Source round-trip helpers

Objective

Make it easy to go from source file to optimised regenerated source.

Requirements

Add and export:

npl_source_to_ir(+SourceFile, -IR).
npl_source_to_optimised_ir(+SourceFile, -OptIR).
npl_roundtrip_source(+SourceFile, -Clauses).
npl_roundtrip_source_text(+SourceFile, -Text).
npl_roundtrip_source_file(+SourceFile, +OutFile).

Behaviour

npl_source_to_ir/2

Internally perform:

npl_lex(SourceFile, Tokens),
npl_parse(Tokens, AST),
npl_analyse(AST, AAST),
npl_intermediate(AAST, IR).

npl_source_to_optimised_ir/2

As above, then:

npl_optimise(IR, OptIR).

npl_roundtrip_source/2

Return regenerated clauses from optimised IR.

npl_roundtrip_source_text/2

Return readable optimised source text.

npl_roundtrip_source_file/2

Write optimised regenerated source to a file.

Acceptance examples

?- npl_roundtrip_source_text('examples/lists.pl', Text).
?- npl_roundtrip_source_file('examples/lists.pl', 'out/lists_optimised.pl').

⸻

Stage 4 — Formatting and readability

Objective

Ensure generated Prolog is pleasant to inspect, compare, and debug.

Requirements

The output formatter should:

* print facts without :- true
* indent conjunctions consistently
* parenthesise ->, ;, and nested conjunctions correctly
* keep one clause block per clause
* insert blank lines between predicate groups where practical
* use readable operator notation rather than raw canonical terms when safe

Required handling

Support readable regeneration for:

* ir_true
* ir_fail
* ir_call/1
* ir_seq/2
* ir_disj/2
* ir_if/3
* ir_not/1
* ir_cut
* arithmetic is/2
* comparisons
* simple built-ins already represented as ir_call(...)

Acceptance examples

Input IR:

[ir_clause(p, ir_seq(ir_call(a), ir_call(b)), info([]))]

Regenerated text should be roughly:

p :-
    a,
    b.

Input IR:

[ir_clause(p(X,Y), ir_call(is(Y,X)), info([]))]

Regenerated text should be roughly:

p(X, Y) :-
    Y is X.

⸻

Stage 5 — Rich emitting mode for special IR nodes

Objective

Allow users to inspect optimisation-specific nodes instead of silently flattening or hiding them.

Requirements

Add option-aware APIs:

npl_ir_to_source(+IR, +Options, -Clauses).
npl_ir_to_source_text(+IR, +Options, -Text).
npl_ir_to_source_file(+IR, +Options, +File).

Supported options

mode(simple).
mode(emitting).
include_comments(true).
include_comments(false).
source_file(File).

Behaviour

Simple mode

* Use existing simple generation route
* Prioritise readability
* Hide low-level wrappers where possible

Emitting mode

* Use richer generation path such as npl_generate_full/3
* Render optimisation structures explicitly when possible
* Preserve extra optimisation intent

Special nodes to support

Where meaningful, emitting mode should handle:

* ir_memo_site(...)
* ir_addr_loop(...)
* ir_loop_candidate(...)
* ir_source_marker(...)
* any currently used wrapper nodes in the optimiser pipeline

If a node cannot yet be emitted directly as normal Prolog, emit a readable fallback plus comment annotation rather than failing silently.

Acceptance expectation

For special nodes, output may include explanatory comments such as:

%% emitted from memo site

or explicit helper wrappers if the runtime supports them.

⸻

Stage 6 — Annotated source regeneration

Objective

Show where regenerated code came from and which optimisation structures are present.

Requirements

Add:

npl_ir_to_annotated_source_text(+IR, +Context, -Text).
npl_ir_to_annotated_source_file(+IR, +Context, +OutFile).

Context may include:

* original source file
* source metadata
* optimisation report
* line info if available

Behaviour

When metadata exists, annotate regenerated code with comments such as:

* original source location
* recursion classification
* applied optimisation passes
* memoisation markers
* address-loop markers

This stage is for debugging and inspection, not exact comment preservation.

⸻

Stage 7 — Error handling

Objective

Make failures understandable.

Requirements

Public predicates should:

* validate IR shape
* throw structured errors for malformed IR
* fail with useful messages when unsupported nodes are encountered
* never expose confusing raw internal failures where avoidable

Example behaviours

If input is not a valid IR list:

* throw domain/type error

If an unsupported node appears in simple mode:

* either emit a fallback comment form
* or throw an informative structured error naming the unsupported node

⸻

Stage 8 — Tests

Objective

Prove that regeneration works and stays stable.

Required tests

Unit tests

Test IR→clause and IR→body for:

* facts
* plain goals
* conjunction
* disjunction
* if-then-else
* arithmetic is
* fail
* negation
* cut

Public API tests

Test:

* npl_ir_to_source/2
* npl_ir_to_source_text/2
* npl_ir_to_source_file/2
* npl_code_generate/2

Round-trip tests

For example programs:

* parse source
* analyse
* generate IR
* optimise IR
* regenerate source
* consult regenerated source
* compare behaviour against expected results

Regression tests

Specifically cover the user-facing case:

?- IR = [ir_clause(p(X,Y), ir_call(is(Y,X+0)), info([]))],
   npl_optimise(IR, OptIR),
   npl_code_generate(OptIR, Clauses).

Expected:

Clauses = [(p(X,Y) :- Y is X)].

File output tests

Verify that files written by npl_ir_to_source_file/2 can be loaded by SWI-Prolog.

⸻

Stage 9 — Documentation

Objective

Make the feature discoverable and easy to use.

Requirements

Update README and architecture docs with a section like:

Inspecting optimiser output

Include examples:

?- consult('src/neuroprolog').
?- npl_source_to_optimised_ir('examples/lists.pl', OptIR).
?- npl_ir_to_source_text(OptIR, Text).
?- writeln(Text).

Direct IR regeneration

?- IR = [ir_clause(p, ir_call(q), info([]))],
   npl_ir_to_source(IR, Clauses).

Compatibility naming

Document that:

* npl_generate/2 is the existing low-level generator
* npl_code_generate/2 is the new public compatibility wrapper
* npl_ir_to_source/2 is the preferred public name

⸻

Stage 10 — Optional future improvements

Later enhancements

After the core feature works, optionally add:

* predicate grouping with section headers
* better stable variable naming
* source diff reports
* preservation of selected source metadata
* optional original-vs-optimised side-by-side output
* CLI script for round-trip regeneration
* exact pretty-printer control options
* comment preservation if lexer/parser later supports it

⸻

Implementation notes

Naming

Prefer these public names:

* npl_ir_to_source/2
* npl_ir_to_source_text/2
* npl_ir_to_source_file/2

Keep:

* npl_code_generate/2 as a convenience alias

Backward compatibility

Do not remove existing low-level generator predicates. Wrap them.

Style

* keep public APIs small and predictable
* avoid exposing internal-only node constructors unless needed
* document all exported predicates in module headers
* make examples runnable from the REPL

⸻

Minimal MVP

If time is limited, deliver this first:

1. export npl_ir_to_source/2
2. add npl_code_generate/2 alias
3. add npl_ir_to_source_text/2
4. add npl_source_to_optimised_ir/2
5. add tests for facts, conjunctions, arithmetic simplification round-trip
6. update README with two examples

That alone would solve the current user pain point.

⸻

Example acceptance workflow

The following should work after implementation:

?- consult('src/neuroprolog').
?- npl_parse_string("p(X,Y) :- Y is X+0.", AST),
   npl_analyse(AST, AAST),
   npl_intermediate(AAST, IR),
   npl_optimise(IR, OptIR),
   npl_code_generate(OptIR, Clauses).

Expected:

Clauses = [(p(X,Y) :- Y is X)].

And this should also work:

?- consult('src/neuroprolog').
?- npl_roundtrip_source_file('examples/lists.pl', 'out/lists_optimised.pl').

If you want, I can now convert this into a tighter 500-character GitHub Agent brief or a full PR checklist with file-by-file changes.
