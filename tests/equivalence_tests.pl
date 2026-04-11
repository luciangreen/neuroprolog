% equivalence_tests.pl — NeuroProlog Stage 17 Equivalence Test Suite
%
% Tests that source-interpreted and compiled-neurocode forms of
% NeuroProlog programs produce identical results for a set of
% representative programs and queries.
%
% Also verifies that rebuilds preserve:
%   - optimisation dictionary contents
%   - cognitive markers
%   - learned transforms
%
% Run with:
%   swipl -g "consult('tests/equivalence_tests')" \
%         -g "run_equivalence_tests" -t halt

:- module(equivalence_tests, [run_equivalence_tests/0]).

:- use_module(library(lists)).

:- consult('src/prelude').
:- consult('src/lexer').
:- consult('src/parser').
:- consult('src/semantic_analyser').
:- consult('src/intermediate_codegen').
:- consult('src/optimisation_dictionary').
:- consult('src/memoisation').
:- consult('src/unfolding').
:- consult('src/pattern_correlation').
:- consult('src/gaussian_recursion').
:- consult('src/subterm_addressing').
:- consult('src/optimiser').
:- consult('src/nested_recursion').
:- consult('src/codegen').
:- consult('src/control').
:- consult('src/optimiser_pipeline').
:- consult('src/wam_model').
:- consult('src/interpreter').
:- consult('src/cognitive_markers').

:- dynamic eq_test_passed/1.
:- dynamic eq_test_failed/1.
:- discontiguous run_eq_test/1.

%%====================================================================
%% Top-level runner
%%====================================================================

run_equivalence_tests :-
    retractall(eq_test_passed(_)),
    retractall(eq_test_failed(_)),
    run_equivalence_suite,
    summarise_equivalence_tests.

run_equivalence_suite :-
    % --- Source / neurocode equivalence ---
    eq_test(equiv_fact_query),
    eq_test(equiv_rule_query),
    eq_test(equiv_recursive_sum),
    eq_test(equiv_recursive_length),
    eq_test(equiv_arithmetic),
    eq_test(equiv_list_append),
    eq_test(equiv_conjunction),
    eq_test(equiv_disjunction),
    eq_test(equiv_negation),
    eq_test(equiv_if_then_else),
    eq_test(equiv_cut),
    % --- Optimisation dictionary preservation ---
    eq_test(dict_preservation_rules_nonempty),
    eq_test(dict_preservation_entries_nonempty),
    eq_test(dict_preservation_save_load),
    eq_test(dict_preservation_identity_rule),
    eq_test(dict_preservation_algebraic_rules),
    % --- Cognitive marker preservation ---
    eq_test(cogmark_ncm_module_loaded),
    eq_test(cogmark_build_from_ir_preserves_marker),
    eq_test(cogmark_trace_report_contains_marker),
    % --- Learned transform preservation ---
    eq_test(learned_dict_entry_roundtrip),
    eq_test(learned_register_and_recover),
    eq_test(learned_merge_new_rule),
    % --- Rebuild mode: safe fallback config ---
    eq_test(rebuild_safe_config_disables_experimental),
    eq_test(rebuild_safe_config_retains_simplification),
    eq_test(rebuild_safe_config_enables_emission),
    % --- End-to-end compilation equivalence ---
    eq_test(e2e_compile_and_exec_fact),
    eq_test(e2e_compile_and_exec_rule),
    eq_test(e2e_compile_and_exec_arithmetic).

eq_test(Name) :-
    ( catch(run_eq_test(Name), Error,
            ( format('ERROR in ~w: ~w~n', [Name, Error]), fail ))
    -> assertz(eq_test_passed(Name)),
       format('PASS: ~w~n', [Name])
    ;  assertz(eq_test_failed(Name)),
       format('FAIL: ~w~n', [Name])
    ).

summarise_equivalence_tests :-
    findall(P, eq_test_passed(P), Passed),
    findall(F, eq_test_failed(F), Failed),
    length(Passed, NP),
    length(Failed, NF),
    Total is NP + NF,
    format('~nEquivalence results: ~w/~w tests passed.~n', [NP, Total]),
    ( Failed = []
    -> write('All equivalence tests passed.')
    ;  write('Failed tests: '), write(Failed)
    ), nl.

%%====================================================================
%% Helpers — compile a source string and compare interpreter results
%%====================================================================

%% eq_compile_src/2
%  eq_compile_src(+SourceAtom, -Neurocode)
%  Lex/parse/analyse/IR/optimise/generate a small program from an atom.
eq_compile_src(Source, Neurocode) :-
    npl_lex_string(Source, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_optimise(IR, OptIR),
    npl_generate(OptIR, Neurocode).

%% eq_run_interpreted/3
%  eq_run_interpreted(+SourceAtom, +Query, -Result)
%  Load the source into the meta-interpreter and run Query.
eq_run_interpreted(Source, Query, Result) :-
    npl_interp_reset,
    npl_lex_string(Source, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_interp_load(AAST),
    ( npl_interp_query(Query, R) -> Result = R ; Result = error ).

%% eq_run_compiled/3
%  eq_run_compiled(+SourceAtom, +Query, -Result)
%  Compile the source to neurocode, load it into the meta-interpreter,
%  and run Query.
eq_run_compiled(Source, Query, Result) :-
    npl_interp_reset,
    eq_compile_src(Source, Neurocode),
    npl_interp_load_clauses(Neurocode),
    ( npl_interp_query(Query, R) -> Result = R ; Result = error ).

%% eq_assert_equiv/3
%  Assert that interpreted and compiled results match for Query on Source.
eq_assert_equiv(Source, Query, ExpectedResult) :-
    eq_run_interpreted(Source, Query, IR),
    eq_run_compiled(Source, Query, CR),
    IR == ExpectedResult,
    CR == ExpectedResult.

%%====================================================================
%% Source / neurocode equivalence tests
%%====================================================================

run_eq_test(equiv_fact_query) :-
    Src = 'foo(a). foo(b).',
    eq_assert_equiv(Src, foo(a), true).

run_eq_test(equiv_rule_query) :-
    Src = 'bar(X) :- X = hello.',
    eq_assert_equiv(Src, bar(hello), true).

run_eq_test(equiv_recursive_sum) :-
    Src = 'mysum([], 0). mysum([H|T], S) :- mysum(T, S1), S is S1 + H.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(mysum([1,2,3], S), S, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(mysum([1,2,3], S), S, NCSols),
    SrcSols == NCSols.

run_eq_test(equiv_recursive_length) :-
    Src = 'mylen([], 0). mylen([_|T], N) :- mylen(T, N1), N is N1 + 1.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(mylen([a,b,c], L), L, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(mylen([a,b,c], L), L, NCSols),
    SrcSols == NCSols.

run_eq_test(equiv_arithmetic) :-
    Src = 'calc(X, Y) :- Y is X * X + 1.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(calc(5, R), R, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(calc(5, R), R, NCSols),
    SrcSols == NCSols.

run_eq_test(equiv_list_append) :-
    Src = 'myapp([], L, L). myapp([H|T], L, [H|R]) :- myapp(T, L, R).',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(myapp([1,2],[3,4],R), R, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(myapp([1,2],[3,4],R), R, NCSols),
    SrcSols == NCSols.

run_eq_test(equiv_conjunction) :-
    Src = 'both(X, Y) :- atom(X), number(Y).',
    eq_assert_equiv(Src, both(hello, 42), true).

run_eq_test(equiv_disjunction) :-
    Src = 'either(X) :- X = a ; X = b.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(either(X), X, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(either(X), X, NCSols),
    SrcSols == NCSols.

run_eq_test(equiv_negation) :-
    Src = 'not_a(X) :- \\+(X = a).',
    eq_assert_equiv(Src, not_a(b), true),
    eq_run_interpreted(Src, not_a(a), R1),
    eq_run_compiled(Src, not_a(a), R2),
    R1 == false,
    R2 == false.

run_eq_test(equiv_if_then_else) :-
    Src = 'classify(X, pos) :- X > 0, !. classify(_, neg).',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(classify(5, C), C, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(classify(5, C), C, NCSols),
    SrcSols == NCSols.

run_eq_test(equiv_cut) :-
    Src = 'first(X, [X|_]) :- !. first(X, [_|T]) :- first(X, T).',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(first(X, [a,b,c]), X, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(first(X, [a,b,c]), X, NCSols),
    SrcSols == NCSols.

%%====================================================================
%% Optimisation dictionary preservation tests
%%====================================================================

run_eq_test(dict_preservation_rules_nonempty) :-
    npl_opt_dict_rules(Rules),
    Rules \= [].

run_eq_test(dict_preservation_entries_nonempty) :-
    npl_opt_dict_entries(Names),
    Names \= [].

run_eq_test(dict_preservation_save_load) :-
    tmp_dict_file(TmpFile),
    npl_opt_dict_save(TmpFile),
    exists_file(TmpFile),
    npl_opt_dict_rules(RulesBefore),
    npl_opt_dict_load(TmpFile),
    npl_opt_dict_rules(RulesAfter),
    length(RulesBefore, N),
    length(RulesAfter, N),
    ( exists_file(TmpFile) -> delete_file(TmpFile) ; true ).

run_eq_test(dict_preservation_identity_rule) :-
    npl_opt_rule(identity, ir_call(true), ir_true).

run_eq_test(dict_preservation_algebraic_rules) :-
    npl_opt_rule(add_zero_right, _, _),
    npl_opt_rule(mul_one_right, _, _),
    npl_opt_rule(mul_zero_right, _, _).

%%====================================================================
%% Cognitive marker preservation tests
%%====================================================================

run_eq_test(cogmark_ncm_module_loaded) :-
    current_predicate(npl_ncm_record/5).

run_eq_test(cogmark_build_from_ir_preserves_marker) :-
    IR = [ ir_clause(foo(x), ir_true,
                     [cognitive_marker:'hot_path', source_marker:pos(1,1)]) ],
    npl_generate(IR, NC),
    npl_ncm_build_from_ir(IR, IR, NC, Mappings),
    member(ncm(_, Marker, _, _, _), Mappings),
    Marker == 'hot_path'.

run_eq_test(cogmark_trace_report_contains_marker) :-
    npl_ncm_clear,
    IR = [ ir_clause(traced_pred(x), ir_true,
                     [cognitive_marker:'memoised', source_marker:pos(1,1)]) ],
    npl_generate(IR, NC),
    npl_ncm_build_from_ir(IR, IR, NC, Mappings),
    maplist(eq_record_mapping, Mappings),
    npl_ncm_trace_report(Report),
    member(trace_entry('memoised', _, _, _), Report),
    npl_ncm_clear.

eq_record_mapping(ncm(Orig, Marker, Neuro, Steps, Meta)) :-
    npl_ncm_record(Orig, Marker, Neuro, Steps, Meta).

%%====================================================================
%% Learned transform preservation tests
%%====================================================================

run_eq_test(learned_dict_entry_roundtrip) :-
    Name = test_learned_entry_17,
    Fields = [ category:test,
               trigger:ir_call(dummy),
               original:'test original',
               transformed:'test transformed',
               proof:test_proof,
               conditions:[],
               perf_notes:'none',
               cognitive_marker:none,
               examples:[],
               version:1 ],
    npl_opt_entry_register(Name, Fields),
    npl_opt_entry_lookup(Name, entry(Name, StoredFields)),
    StoredFields == Fields,
    retract(npl_opt_entry(Name, _)).

run_eq_test(learned_register_and_recover) :-
    Name = test_learned_rule_17,
    npl_opt_register(Name, ir_call(test_dummy_17), ir_true),
    npl_opt_lookup(Name, opt(Name, ir_call(test_dummy_17), ir_true)),
    retract(npl_opt_rule(Name, _, _)).

run_eq_test(learned_merge_new_rule) :-
    Name = test_merge_rule_17,
    npl_opt_dict_rules(Before),
    \+ member(Name, Before),
    npl_opt_register(Name, ir_call(merge_test_17), ir_true),
    npl_opt_dict_rules(After),
    member(Name, After),
    retract(npl_opt_rule(Name, _, _)).

%%====================================================================
%% Rebuild mode: safe fallback configuration tests
%%====================================================================

run_eq_test(rebuild_safe_config_disables_experimental) :-
    npl_pipeline_default_config(Cfg0),
    ExperimentalPasses = [ gaussian_elimination,
                           recursion_to_loop,
                           subterm_address_conversion,
                           nested_recursion_elimination ],
    foldl(npl_pipeline_disable, ExperimentalPasses, Cfg0, SafeCfg),
    forall(
        member(P, ExperimentalPasses),
        \+ npl_pipeline_is_enabled(P, SafeCfg)
    ).

run_eq_test(rebuild_safe_config_retains_simplification) :-
    npl_pipeline_default_config(Cfg0),
    foldl(npl_pipeline_disable,
          [ gaussian_elimination,
            recursion_to_loop,
            subterm_address_conversion,
            nested_recursion_elimination ],
          Cfg0, SafeCfg),
    npl_pipeline_is_enabled(simplification, SafeCfg),
    npl_pipeline_is_enabled(memoisation_insertion, SafeCfg),
    npl_pipeline_is_enabled(dict_learned_opt, SafeCfg),
    npl_pipeline_is_enabled(final_simplification, SafeCfg).

run_eq_test(rebuild_safe_config_enables_emission) :-
    npl_pipeline_default_config(Cfg0),
    foldl(npl_pipeline_disable,
          [ gaussian_elimination,
            recursion_to_loop,
            subterm_address_conversion,
            nested_recursion_elimination ],
          Cfg0, SafeCfg),
    npl_pipeline_is_enabled(neurocode_emission, SafeCfg).

%%====================================================================
%% End-to-end compilation equivalence tests
%%====================================================================

run_eq_test(e2e_compile_and_exec_fact) :-
    Src = 'greet(world).',
    eq_run_interpreted(Src, greet(world), Ri),
    eq_run_compiled(Src, greet(world), Rc),
    Ri == true,
    Rc == true.

run_eq_test(e2e_compile_and_exec_rule) :-
    Src = 'double(X, Y) :- Y is X * 2.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(double(3, R), R, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(double(3, R), R, NCSols),
    SrcSols == NCSols.

run_eq_test(e2e_compile_and_exec_arithmetic) :-
    Src = 'sq(X, Y) :- Y is X * X.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(sq(7, R), R, SrcSols),
    npl_interp_reset,
    eq_compile_src(Src, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(sq(7, R), R, NCSols),
    SrcSols == NCSols.

%%====================================================================
%% Utilities
%%====================================================================

tmp_dict_file('/tmp/npl_equiv_test_dict.pl').

%% foldl/4 compatibility shim
:- if(\+ current_predicate(foldl/4)).
foldl(_, [], V, V).
foldl(Goal, [H|T], V0, V) :-
    call(Goal, H, V0, V1),
    foldl(Goal, T, V1, V).
:- endif.
