% run_tests.pl — NeuroProlog Test Suite
%
% Run with:
%   swipl -g "consult('tests/run_tests')" -g "run_all_tests" -t halt

:- module(run_tests, [run_all_tests/0]).

:- consult('src/prelude').
:- consult('src/lexer').
:- consult('src/parser').
:- consult('src/semantic_analyser').
:- consult('src/intermediate_codegen').
:- consult('src/optimisation_dictionary').
:- consult('src/memoisation').
:- consult('src/gaussian_recursion').
:- consult('src/subterm_addressing').
:- consult('src/optimiser').
:- consult('src/codegen').
:- consult('src/control').
:- consult('src/wam_model').

:- dynamic test_passed/1.
:- dynamic test_failed/1.

run_all_tests :-
    retractall(test_passed(_)),
    retractall(test_failed(_)),
    run_test_suite,
    summarise_tests.

run_test_suite :-
    test(prelude_append),
    test(prelude_length),
    test(prelude_reverse),
    test(prelude_member),
    test(prelude_sum_list),
    test(lexer_basic),
    test(optimiser_identity),
    test(optimiser_seq_true),
    test(optimiser_fail_branch),
    test(subterm_at),
    test(subterm_set),
    test(control_if),
    test(control_not),
    test(control_forall),
    test(wam_compile),
    test(codegen_basic).

test(Name) :-
    ( catch(run_test(Name), Error, (write('ERROR in '), write(Name), write(': '), write(Error), nl, fail))
    -> assertz(test_passed(Name)),
       write('PASS: '), write(Name), nl
    ;  assertz(test_failed(Name)),
       write('FAIL: '), write(Name), nl
    ).

summarise_tests :-
    findall(P, test_passed(P), Passed),
    findall(F, test_failed(F), Failed),
    length(Passed, NP),
    length(Failed, NF),
    Total is NP + NF,
    format('~nResults: ~w/~w tests passed.~n', [NP, Total]),
    ( Failed = [] -> true
    ; write('Failed: '), write(Failed), nl
    ).

%% Individual tests

run_test(prelude_append) :-
    npl_append([1,2], [3,4], R),
    R == [1,2,3,4].

run_test(prelude_length) :-
    npl_length([a,b,c], N),
    N == 3.

run_test(prelude_reverse) :-
    npl_reverse([1,2,3], R),
    R == [3,2,1].

run_test(prelude_member) :-
    npl_member(2, [1,2,3]).

run_test(prelude_sum_list) :-
    npl_sum_list([1,2,3,4], S),
    S == 10.

run_test(lexer_basic) :-
    npl_lex_string('foo(X, 42)', Tokens),
    Tokens = [atom(foo), punct('('), var('X'), punct(','), integer(42), punct(')')].

run_test(optimiser_identity) :-
    npl_optimise([ir_clause(test, ir_call(true), info(head:ok,body:ok))], Opt),
    Opt = [ir_clause(test, ir_true, _)].

run_test(optimiser_seq_true) :-
    npl_optimise([ir_clause(test, ir_seq(ir_true, ir_call(foo)), info(head:ok,body:ok))], Opt),
    Opt = [ir_clause(test, ir_call(foo), _)].

run_test(optimiser_fail_branch) :-
    npl_optimise([ir_clause(test, ir_disj(ir_fail, ir_call(ok)), info(head:ok,body:ok))], Opt),
    Opt = [ir_clause(test, ir_call(ok), _)].

run_test(subterm_at) :-
    npl_subterm_at(f(a, g(b, c)), [2, 1], b).

run_test(subterm_set) :-
    npl_subterm_set(f(a, b), [2], x, R),
    R == f(a, x).

run_test(control_if) :-
    npl_if(true, (X = yes), (X = no)),
    X == yes.

run_test(control_not) :-
    npl_not(fail).

run_test(control_forall) :-
    npl_forall(member(X, [2,4,6]), 0 =:= X mod 2).

run_test(wam_compile) :-
    wam_compile_clause(foo(a), Instrs),
    Instrs = [get_constant(foo/1)].

run_test(codegen_basic) :-
    npl_generate([ir_clause(hello, ir_true, info(head:ok,body:ok))], Code),
    Code = [hello].
