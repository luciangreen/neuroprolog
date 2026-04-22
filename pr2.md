Yes — in your intended meaning, +1 and ^ should cover index-formula relationships like that.

More precisely, I should have said:

* +1, -1, offsets, and similar operations refer to formulas for indexed variables such as
    * x_i = 4 + i - 1
    * y_i = 5 + i - 1
        so that for i = 1..3, you get:
    * x_1=4, x_2=5, x_3=6
    * y_1=5, y_2=6, y_3=7
* ^ refers to powers in index formulas when the traced dependency is polynomial, such as:
    * a_0 + a_1*i + a_2*i^2
    * or higher powers if needed.

So yes: your meaning includes deriving formulas for indexed variables like the x=4..6 and y=5..7 sequences behind x_1..x_3 and y_1..y_3, not just generic arithmetic syntax.

Because that point is important, here is the fully corrected and completely reoutput program requirements in full.

⸻

Full further program requirements for NeuroProlog

Overall objective

The WAM interpreter already works. The remaining required work is to complete and integrate:

1. Gaussian elimination based formula discovery for polynomial numeric optimisation.
2. General subterm index optimisation from first principles, without hardcoded diagonal or other named special-case pattern classes.
3. Support for tracing indexed variables through pattern matching, built-ins, and reducible custom predicates.
4. Support for reconstructing formulas for indexed variables such as:
    * x_i = 4+i-1
    * y_i = 5+i-1
    * and more generally polynomial relations in independent indices.
5. Emission of direct optimised neurocode or generated Prolog.
6. Alignment with Starlog where useful.
7. Clear examples, comments, tests, documentation, and self-hosting compatibility.

These requirements replace narrower earlier wording that described subterm optimisation mainly in terms of diagonals or a small set of matrix cases.

⸻

Core rules

Rule 1 — Gaussian elimination must always be used for polynomial discovery

Whenever NeuroProlog discovers or confirms a polynomial formula for a recurrence, sequence, indexed computation, or derived direct formula, it must derive that polynomial using Gaussian elimination.

It must not use:

* guessed coefficients
* enumerated coefficient lists
* arbitrary candidate values
* hardcoded formula templates
* naming-based recognition
* ad hoc direct insertion of known formulas

Finite differences may still be used to estimate likely degree, but coefficient discovery itself must always use Gaussian elimination.

This includes discovering:

* 0.5*N^2 + 0.5*N
* N*(N+1)/2
* linear formulas
* quadratic formulas
* cubic formulas
* polynomial formulas in index variables introduced during subterm tracing

⸻

Rule 2 — Subterm index optimisation must work from first principles, not from diagonal cases

Do not implement a “diagonal optimisation”, “row optimisation”, “anti-diagonal optimisation”, or any other named special case as the core design.

Instead, implement a general symbolic system that:

1. assigns symbolic indices to generated values and structures,
2. traces indexed variables through pattern matching and irreducible commands,
3. identifies how output expressions depend on independent indices,
4. reconstructs formulas for those indexed dependencies from first principles,
5. uses Gaussian elimination where polynomial formulas must be discovered,
6. emits direct indexed formulas or direct indexed access rules.

The system may later discover that a user program happens to describe what people informally call a diagonal, row, column, stripe, window, or other structure, but these must arise from the general method rather than from hardcoded cases.

⸻

Rule 3 — Indexed-variable formulas must include offset and polynomial relations

Subterm index optimisation must support discovering formulas for indexed variables themselves, not only final output formulas.

This includes deriving relationships such as:

* x_i = 4+i-1
* y_i = 5+i-1
* z_i = 2*i+3
* u_i = i^2 + i
* v_i = a_0 + a_1*i + a_2*i^2

So when the user refers to +1 and ^, this includes:

* offset formulas like i+1, i-1, 4+i-1
* powers like i^2, i^3
* polynomial expressions in one or more independent indices

The optimiser must work out these formulas from traced index behaviour, not merely preserve them if already written explicitly.

⸻

Rule 4 — Generality comes from reducibility, not from vague claims

Subterm index optimisation should apply to any computation whose traced indexed behaviour reduces to:

1. pattern matching, and
2. irreducible commands

where irreducible commands are primitive operations the optimiser does not further decompose unless explicit reduction rules exist.

This includes:

* built-ins
* pattern-matching predicates
* custom predicates
* recursive traversals

provided they can be reduced to structural matching plus irreducible operations.

Do not describe the optimisation as “works for any computation” unless the code proves reducibility and equivalence.

⸻

Stage 1 — Audit and failing tests first

Required files to inspect and update

At minimum inspect and modify these NeuroProlog files as needed:

* src/gaussian_recursion.pl
* src/subterm_addressing.pl
* src/optimiser.pl
* src/optimiser_pipeline.pl
* src/intermediate_codegen.pl
* tests/equivalence_tests.pl
* tests/run_tests.pl
* relevant example files
* GAUSSIAN_RECURSION.md
* NESTED_RECURSION.md
* OPTIMISATION_RULES.md
* README.md

Also inspect Starlog where relevant:

* gaussian_elimination.pl
* GAUSSIAN_ELIMINATION.md
* demo_gaussian_elimination.pl
* demo_starlog_gaussian.pl

If other files are required for self-hosting, rebuilds, or codegen, include them.

⸻

Tests must be added before implementation

Before changing optimiser logic, add failing tests for the required supported behaviours.

⸻

Stage 1A — Failing tests for Gaussian elimination polynomial discovery

Add tests showing that coefficient discovery is performed by Gaussian elimination and not by guessing.

Required tests

Test A1 — triangular numbers

Input:

* a recurrence or sample set equivalent to 1+2+...+N

Expected:

* degree 2 inferred or supplied
* linear system built from basis terms
* Gaussian elimination solves coefficients
* reconstructed formula equivalent to:
    * 0.5*N^2 + 0.5*N
    * or N*(N+1)/2

The test must reject any implementation that bypasses Gaussian elimination.

Test A2 — linear sequence

Input samples:

* (1,4)
* (2,7)
* (3,10)

Expected:

* solved linear formula equivalent to:
    * 3*N + 1

Test A3 — cubic sequence

Use a known cubic example and require:

* degree 3 solving by Gaussian elimination
* validated reconstruction

Test A4 — unsupported non-polynomial recurrence

Input:

* Fibonacci or similar non-polynomial recurrence

Expected:

* no polynomial rewrite applied

Test A5 — impure predicate

Input:

* recurrence involving side effects or impurity

Expected:

* no Gaussian polynomial rewrite applied

⸻

Stage 1B — Failing tests for first-principles subterm index optimisation

These tests must avoid naming diagonal or other special cases as implementation categories. They should test general tracing and formula discovery.

Required tests

Test B1 — indexed structure generation and selected output formula

Input:

* a program that generates intermediate indexed structures and then selects outputs through traced variable correspondences

Expected:

* optimiser derives direct indexed formula from first principles
* intermediate structure can be avoided if safe
* output preserved exactly

Test B2 — indexed-variable sequence reconstruction

Input:

* a program where traced indexed variables correspond to sequences such as:
    * x_1=4, x_2=5, x_3=6
    * y_1=5, y_2=6, y_3=7

Expected:

* optimiser reconstructs formulas such as:
    * x_i = 4+i-1
    * y_i = 5+i-1
* these formulas are treated as derived indexed-variable formulas, not hardcoded assumptions

Test B3 — multiplication-derived selected pattern

Input:

* a matrix-like or list-of-lists computation where selected output cells or elements arise from traced indexed multiplicative formulas

Expected:

* traced operand formulas reconstructed
* output formula expressed through independent indices
* direct result preserved

Test B4 — addition-derived selected pattern

Input:

* similar structure, but with addition rather than multiplication

Expected:

* formula rebuilt from traced indices and independent index variables
* exact output preserved

Test B5 — non-special-case patterned extraction

Input:

* a case that is not informally a diagonal, to ensure the optimiser is not diagonal-specific

Expected:

* direct indexed formula or direct indexed access rule derived by tracing, not by named case logic

Test B6 — polynomial indexed-variable derivation

Input:

* a traced indexed computation whose variable lineage depends polynomially on an independent variable, such as:
    * u_i = i^2 + i

Expected:

* optimiser recognises polynomial dependency
* collects sufficient sample points or equations
* uses Gaussian elimination to derive the polynomial coefficients

Test B7 — negative test, full structure required

If the whole materialised structure is observably needed later, expected:

* no rewrite that removes the structure

Test B8 — negative test, ambiguous variable mapping

If variable identity or index mapping is ambiguous, expected:

* no rewrite

Test B9 — negative test, non-reducible predicate use

If a predicate cannot be reduced to pattern matching plus irreducible commands, expected:

* no rewrite

⸻

Stage 2 — Gaussian elimination core

Objective

Implement or complete a true Gaussian elimination engine for polynomial coefficient solving.

This must be the required solver for polynomial discovery across the optimiser.

⸻

Required behaviour

Given sample points and a target degree, NeuroProlog must:

1. choose or confirm a degree bound,
2. construct the coefficient system from basis terms,
3. solve the coefficient matrix by Gaussian elimination,
4. reconstruct the formula,
5. validate the formula.

⸻

Required basis construction

For samples (X, Y) and degree K, construct equations of the form:

a_0*X^0 + a_1*X^1 + ... + a_K*X^K = Y

Then solve for:

* a_0
* a_1
* …
* a_K

using Gaussian elimination.

This applies whether the variable is:

* N
* I
* J
* an index expression variable
* a traced independent variable introduced during subterm optimisation

⸻

Mandatory examples

Example 1 — triangular numbers

Given:

* (1,1)
* (2,3)
* (3,6)

NeuroProlog must construct the degree-2 system and solve:

* a_2 = 0.5
* a_1 = 0.5
* a_0 = 0

then reconstruct:

* 0.5*N^2 + 0.5*N

and may simplify to:

* N*(N+1)/2

This must come from Gaussian elimination, not by recognising the formula in advance.

⸻

Example 2 — linear polynomial

Given:

* (1,4)
* (2,7)
* (3,10)

solve:

* a_1 = 3
* a_0 = 1

and reconstruct:

* 3*N + 1

⸻

Example 3 — polynomial in derived index variable

If subterm tracing produces an independent variable K, and sample outputs suggest a polynomial in K, the system must build and solve:

* a_0 + a_1*K + a_2*K^2 + ...

by Gaussian elimination.

⸻

Required predicates

Add or complete predicates equivalent to:

* npl_detect_polynomial_degree(+Samples,-Degree)
* npl_build_polynomial_system(+Samples,+Degree,-Matrix,-Vector)
* npl_gaussian_elimination(+Matrix,+Vector,-Coefficients)
* npl_reconstruct_polynomial(+Var,+Coefficients,-Expr)
* npl_validate_polynomial_formula(+Samples,+Expr,+Var,-Result)

If multiple variables are supported later, structure the code so it can be extended cleanly.

⸻

Arithmetic requirements

Use exact or stable rational handling where possible.

Preferred behaviour:

* preserve exact rational forms
* simplify zero coefficients away
* simplify 1*X to X
* optionally factor polynomials when safe

Do not silently introduce floating approximation unless explicitly documented.

⸻

Acceptance criteria

* every successful polynomial discovery path uses Gaussian elimination,
* no coefficient enumeration remains as an alternative,
* formulas validate against samples,
* inconsistent or unsupported systems fail cleanly.

⸻

Stage 3 — Gaussian elimination in the optimiser pipeline

Objective

Integrate Gaussian elimination as the mandatory polynomial-discovery mechanism inside the optimiser pipeline.

⸻

Required supported class

Apply this optimisation when all of the following hold:

1. the predicate is pure,
2. the output is numeric or reducible to numeric expression discovery,
3. the recurrence or sampled output is polynomial in one or more traced independent variables,
4. sufficient samples can be collected safely,
5. the Gaussian-solved formula validates.

⸻

Permitted helpers

Finite differences may be used only for:

* estimating degree,
* choosing matrix size,
* checking plausibility.

But the actual coefficients must still be solved by Gaussian elimination.

⸻

Must not transform

Do not apply the polynomial rewrite when:

1. the predicate is impure,
2. the recurrence is not polynomial,
3. validation fails,
4. the output multiplicity is ambiguous,
5. required samples cannot be safely obtained,
6. the expression depends on unsupported effects or non-reducible behaviour.

⸻

Required predicates

Add or complete logic equivalent to:

* npl_extract_numeric_samples/4
* npl_detect_polynomial_degree/3
* npl_build_polynomial_system/4
* npl_gaussian_elimination/3
* npl_validate_polynomial_fit/4
* npl_rewrite_recurrence_to_closed_form/4

⸻

Acceptance criteria

* sum(1..N) can be rewritten through Gaussian elimination to a closed form,
* linear and higher polynomial examples work,
* unsupported recurrences remain unchanged.

⸻

Stage 4 — General first-principles subterm index optimisation

Objective

Implement a general symbolic tracing system for indexed variables through structures and predicates, without named special cases such as diagonal logic.

The optimiser should derive formulas and direct rules from first principles.

⸻

Formal model

Subterm index optimisation must proceed through these phases.

⸻

Phase 4A — symbolic index assignment

Assign symbolic indices to generated values and structures.

Examples include:

* list positions,
* nested list positions,
* matrix coordinates,
* subterm addresses,
* string positions,
* atom positions,
* recursive constructor positions.

Example symbolic names may include:

* x_1, x_2, x_3
* y_1, y_2, y_3
* M_(I,J)
* Term_(Addr)
* Chars_(K)

The exact naming convention may differ, but the mapping must be explicit and inspectable.

⸻

Phase 4B — reduction to pattern matching and irreducible commands

Analyse built-ins and custom predicates to reduce them into a supported internal form composed of:

* pattern matching,
* structural traversal,
* irreducible commands.

Irreducible commands are atomic operations such as arithmetic or primitive operations that the optimiser treats as leaves unless separate reduction rules exist.

This must work through:

* unification,
* list decomposition,
* term decomposition,
* common built-ins such as member/2, nth1/3, arg/3, append/3, sub_string/5, =../2,
* custom recursive predicates if reducible.

⸻

Phase 4C — trace indexed variable flow

Trace how indexed variables:

* move,
* match,
* combine,
* transform,
* are selected,
* are reconstructed,
* contribute to output formulas.

This tracing must preserve variable identity correspondences explicitly.

If two values in the computation refer to the same logical variable lineage, that must be representable in the trace.

⸻

Phase 4D — identify independent and dependent variables

Determine:

* independent index variables,
* dependent variables,
* derived address variables,
* derived expression variables.

Example:

* an output loop variable may be independent,
* source operand indices may be derived from it by expressions such as I+1, I-1, 2*I, or powers such as I^2,
* source indexed variables may satisfy formulas such as:
    * x_i = 4+i-1
    * y_i = 5+i-1
* output values may then depend polynomially on that independent variable.

This stage must not rely on named geometric cases.

⸻

Phase 4E — reconstruct formulas from first principles

Once indexed relationships are traced, reconstruct formulas from first principles.

This includes formulas involving:

* +
* -
* *
* /
* powers such as ^
* affine transformations such as I+1
* polynomial combinations of index variables

This explicitly includes deriving formulas for indexed variables such as:

* x_i = 4+i-1
* y_i = 5+i-1

Where a polynomial relationship is discovered, NeuroProlog must use Gaussian elimination to derive the polynomial coefficients.

This means that if traced expressions imply outputs such as:

* a_0 + a_1*I + a_2*I^2

or indexed-variable relations such as:

* x_i = b_0 + b_1*i
* u_i = c_0 + c_1*i + c_2*i^2

then the coefficients must be obtained by Gaussian elimination from samples or derived equations, not by guesswork.

⸻

Phase 4F — emit direct indexed rule or formula

Construct an optimised form that:

* avoids unnecessary intermediate structures where safe,
* computes outputs directly from independent indices,
* preserves variable identity tracing,
* preserves observable behaviour.

The result may be:

1. a direct arithmetic formula,
2. a direct indexed term-construction rule,
3. a direct indexed extraction rule,
4. a simplified loop over independent indices,
5. a mixed symbolic/numeric direct rule.

⸻

Stage 5 — removal of named special-case structural logic

Required correction

Do not implement or document dedicated diagonal, row, column, anti-diagonal, or similar named cases as the main optimisation pattern.

If the user program happens to describe equal row/column indices or another familiar shape, the optimiser should derive that from the general trace and index-formula method.

So instead of:

* “detect diagonal and optimise it”

the optimiser should:

1. assign symbolic indices,
2. trace address equalities or relationships,
3. infer output dependencies,
4. reconstruct formulas for indexed variables and outputs,
5. use Gaussian elimination for polynomial formula discovery where needed.

⸻

Documentation rule

Examples may still include programs that humans might describe informally with structural names, but the documentation must explain them only as instances of the general first-principles indexed tracing method.

Do not frame them as dedicated optimisation classes.

⸻

Stage 6 — first-principles formula discovery for indexed variables

Required correction from earlier scope

The system must not just recognise address relationships. It must also work out formulas for variable indices from first principles.

This includes deriving formulas involving:

* +1
* -1
* offsets
* strides
* powers such as ^
* polynomial combinations of indices

This includes cases like:

* x_i = 4+i-1
* y_i = 5+i-1

which correspond to indexed sequences such as:

* x_1=4, x_2=5, x_3=6
* y_1=5, y_2=6, y_3=7

If an output depends on a traced index variable through a polynomial pattern, Gaussian elimination must be used to derive the formula.

⸻

Example requirement

Suppose tracing shows a variable lineage such as:

* source index transformed by I+1
* another term transformed by I^2
* source indexed variables reconstructed as affine or polynomial functions of I
* final output polynomial in I

The optimiser must:

1. treat I as the independent variable,
2. collect sufficient relationships or samples,
3. build the polynomial system,
4. solve it by Gaussian elimination,
5. reconstruct the formula.

This is required even if the formulas are not immediately obvious from local simplification.

⸻

Stage 7 — required predicates for general indexed tracing

Add or revise predicates equivalent to:

* npl_assign_symbolic_indices(+Structure,-IndexedStructure,-IndexMap)
* npl_reduce_predicate_to_pattern_irreducibles(+Predicate,-ReducedForm)
* npl_trace_index_flow(+Goal,+IndexMap,-FlowGraph)
* npl_identify_independent_indices(+FlowGraph,-IndependentVars)
* npl_reconstruct_index_relations(+FlowGraph,+IndependentVars,-Relations)
* npl_collect_formula_samples(+Relations,+IndependentVar,-Samples)
* npl_build_polynomial_system(+Samples,+Degree,-Matrix,-Vector)
* npl_gaussian_elimination(+Matrix,+Vector,-Coefficients)
* npl_reconstruct_direct_indexed_rule(+Relations,+Coefficients,-DirectRule)
* npl_validate_direct_rule(+OriginalGoal,+DirectRule,-Result)

These names may vary, but the functionality must be present.

⸻

Stage 8 — optimiser IR and pipeline changes

Objective

Represent these optimisations explicitly in IR, not only as undocumented source rewrites.

⸻

Add or complete IR support for:

1. polynomial closed-form evaluation,
2. direct indexed rule generation,
3. index-relation metadata,
4. provenance of derived formulas,
5. optional rational coefficient representation.

Possible node ideas include:

* ir_poly_eval(IndexVar,Coeffs,ResultVar)
* ir_index_relation(IndependentVars,Relations)
* ir_direct_index_rule(IndexSpec,RuleBody,ResultCollector)
* ir_provenance(Note,InnerIR)

The exact names may differ, but the semantics must be documented.

⸻

Required pipeline order

Unless a better justified order is documented, apply passes in this order:

1. parse and analyse,
2. semantic analysis,
3. recurrence classification,
4. sample extraction,
5. degree estimation,
6. Gaussian elimination polynomial solve,
7. polynomial validation and rewrite,
8. symbolic index assignment,
9. predicate reduction to pattern matching plus irreducibles,
10. indexed variable flow tracing,
11. independent-variable identification,
12. formula reconstruction from first principles,
13. Gaussian elimination for indexed polynomial formulas where needed,
14. direct indexed rule reconstruction,
15. simplification,
16. code generation.

⸻

Acceptance criteria

* pass ordering is documented,
* passes are deterministic,
* new IR nodes lower correctly,
* provenance is inspectable.

⸻

Stage 9 — code generation and neurocode emission

Objective

The optimiser must emit runnable optimised code, not only analysis metadata.

⸻

Requirements

Generated code or neurocode must:

1. reflect Gaussian-solved polynomial formulas,
2. reflect direct indexed rewrites,
3. preserve readability for rebuild/self-hosting,
4. preserve existing no-extra-attention/no-chatbot-style design constraints.

⸻

Required behaviours

Behaviour 1 — closed-form numeric output

For supported recurrence examples, codegen should emit equivalent of:

* R is N*(N+1)/2
    or equivalent rational polynomial steps.

Behaviour 2 — direct indexed formula loop

For supported traced indexed examples, codegen should emit:

* a loop over independent indices,
* direct formula computation for the output,
* no unnecessary materialised intermediate structure if safe.

Behaviour 3 — indexed-variable reconstruction

For supported traced indexed-variable examples, codegen should be able to emit logic equivalent to:

* X is 4+I-1
* Y is 5+I-1

or simplified equivalents,
when those formulas are derived from tracing rather than copied directly.

Behaviour 4 — mixed symbolic/numeric extraction

For non-numeric supported examples, codegen should emit:

* direct pattern-based extraction or reconstruction,
* preserving output behaviour.

⸻

Acceptance criteria

* all new IR forms compile,
* generated code passes equivalence tests,
* transformed and original programs agree.

⸻

Stage 10 — Starlog integration

Objective

Starlog already contains Gaussian elimination logic. Reuse or align with it where sensible.

⸻

Required decision

Choose and document one of these:

Option A — shared Gaussian core

Create a shared Gaussian elimination core used by both Starlog and NeuroProlog.

Option B — port and align

Port relevant Gaussian elimination functionality into NeuroProlog while keeping interfaces and behaviour aligned.

⸻

Requirements

1. document which repository is canonical for Gaussian elimination logic,
2. if code is copied, say so in comments and docs,
3. if Starlog needs updates, keep them minimal and relevant,
4. if Starlog demos are updated, ensure they still demonstrate Gaussian solving clearly.

⸻

Comment on examples

Where examples are provided:

* comment them clearly,
* explain variable tracing,
* explain independent and dependent indices,
* explain how Gaussian elimination is used,
* explain how formulas like x_i = 4+i-1 and y_i = 5+i-1 were reconstructed,
* explain how the final formula was reconstructed from first principles.

Do not present examples as named special cases.

⸻

Stage 11 — documentation rewrite

GAUSSIAN_RECURSION.md

Must explicitly state:

* Gaussian elimination is mandatory for polynomial discovery,
* finite differences may estimate degree but do not replace Gaussian elimination,
* triangular number discovery must be shown as a worked example,
* polynomial indexed-variable discovery must be documented,
* unsupported cases must be documented.

⸻

OPTIMISATION_RULES.md

Must explicitly distinguish:

1. accumulator rewrites,
2. polynomial discovery by Gaussian elimination,
3. general indexed-variable tracing,
4. reduction to pattern matching plus irreducibles,
5. formula reconstruction from first principles,
6. indexed-variable formula derivation,
7. direct indexed rule generation.

Do not present diagonal or other named cases as optimisation categories.

⸻

Example files

Update examples so they:

* show unoptimised and optimised versions,
* comment variable lineage clearly,
* explain index assignment,
* explain how formulas are reconstructed,
* include at least one nontrivial indexed case,
* include indexed-variable derivation examples like x_i = 4+i-1, y_i = 5+i-1,
* avoid describing examples as diagonal-special-case logic.

⸻

README.md

Must state:

* WAM works,
* Gaussian elimination is used for polynomial formula discovery,
* general indexed subterm optimisation works by first-principles symbolic tracing,
* indexed-variable formulas such as affine and polynomial index relations are reconstructed from tracing,
* named structural cases are not hardcoded as the design basis,
* unsupported or ambiguous cases remain unchanged.

⸻

Stage 12 — safety and correctness rules

Must only transform when:

1. variable correspondences are explicit,
2. independent variables are identifiable,
3. required predicates reduce to pattern matching plus irreducible commands,
4. polynomial formulas are solved by Gaussian elimination where applicable,
5. validation succeeds,
6. observable behaviour is preserved,
7. eliminated intermediate structures are not needed elsewhere.

⸻

Must not transform when:

1. variable identity is ambiguous,
2. predicates are impure,
3. required reduction to supported primitives fails,
4. index relationships cannot be reconstructed cleanly,
5. polynomial validation fails,
6. output multiplicity or ordering changes cannot be justified,
7. full structure materialisation is observably required.

⸻

Stage 13 — self-hosting and rebuild alignment

Required work

Ensure the new optimisation passes do not break:

* self-hosting
* rebuild scripts
* self-check scripts
* provenance logs
* equivalence tests

⸻

Requirements

1. new passes should be toggleable if necessary,
2. rebuild logs should record which transforms were applied,
3. derived formulas should have inspectable provenance,
4. self-hosting invariants should still pass.

⸻

Acceptance criteria

* self-check runs cleanly,
* rebuild continues to work,
* optimisation metadata does not break parser, IR, or codegen.

⸻

Stage 14 — delivery rules for GitHub Agent

Tell GitHub Agent to work in this order:

1. audit current implementation,
2. add failing tests first,
3. implement Gaussian elimination as the universal polynomial solver,
4. integrate it into recurrence optimisation,
5. implement general indexed-variable tracing from first principles,
6. implement formula reconstruction for indexed variables,
7. use Gaussian elimination wherever indexed polynomial formulas are discovered,
8. add IR and codegen support,
9. update examples and comments,
10. update docs,
11. run tests and self-check,
12. clearly document unsupported cases.

⸻

Additional delivery rules

Tell the agent:

* do not upload files without meaningful code or docs changes,
* do not guess coefficients,
* do not insert hardcoded closed forms as discovery shortcuts,
* do not build the optimiser around diagonal or other named structural cases,
* do not claim “works for any computation” without proving reducibility and equivalence,
* prefer smaller correct passes over broad unverifiable rewrites.

⸻

Concise GitHub Agent prompt version

Implement the missing NeuroProlog optimiser work in stages. The WAM interpreter already works. First add failing tests. Then make Gaussian elimination the mandatory and universal mechanism for polynomial formula discovery: whenever NeuroProlog derives a polynomial closed form for a recurrence, generated sequence, or traced indexed computation, it must construct the basis-term system and solve the coefficients by Gaussian elimination, never by coefficient guessing, enumeration, or hardcoded templates. This includes deriving 0.5*N^2 + 0.5*N and optionally simplifying it to N*(N+1)/2 for sum(1..N). Next implement general subterm index optimisation from first principles, not as a diagonal or other named special case. Assign symbolic indices to generated structures, reduce built-ins and custom predicates to pattern matching plus irreducible commands where possible, trace indexed variable flow, identify independent variables, reconstruct formula relations including indexed-variable formulas such as x_i = 4+i-1 and y_i = 5+i-1, and when the resulting dependency is polynomial, use Gaussian elimination again to derive the formula. This also includes powers such as i^2 and higher polynomial terms where supported. Then emit direct indexed rules or formulas, avoiding unnecessary intermediate structures where safe. Update optimiser pipeline, IR/codegen, examples, comments, docs, and tests. Keep Starlog Gaussian logic aligned or reused where documented. Unsupported or ambiguous cases must remain unchanged and be documented explicitly.

The cleanest shorthand for your intended meaning is: “derive affine and polynomial formulas for indexed variables, such as x_i=4+i-1 and y_i=5+i-1, from traced variable correspondences.”