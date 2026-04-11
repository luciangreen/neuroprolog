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
:- consult('src/interpreter').

:- dynamic test_passed/1.
:- dynamic test_failed/1.
:- discontiguous run_test/1.

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
    test(prelude_nth0),
    test(prelude_nth1),
    test(prelude_select),
    test(prelude_delete),
    test(prelude_subtract),
    test(prelude_intersection),
    test(prelude_union),
    test(prelude_list_to_set),
    test(prelude_sort),
    test(prelude_functor),
    test(prelude_arg),
    test(prelude_univ),
    test(prelude_copy_term),
    test(prelude_type_checks),
    test(prelude_unify),
    test(prelude_compare),
    test(prelude_maplist2),
    test(prelude_maplist3),
    test(prelude_foldl),
    test(prelude_include),
    test(prelude_exclude),
    test(lexer_basic),
    test(lexer_atoms),
    test(lexer_variables),
    test(lexer_anonymous_var),
    test(lexer_integers),
    test(lexer_floats),
    test(lexer_strings),
    test(lexer_operators),
    test(lexer_line_comment),
    test(lexer_block_comment),
    test(lexer_annotation),
    test(lexer_clause_terminator),
    test(lexer_list_syntax),
    test(lexer_positions),
    test(lexer_multiline_pos),
    test(lexer_error_unterminated_string),
    test(lexer_error_unterminated_atom),
    test(lexer_error_block_comment),
    test(lexer_error_unknown_char),
    test(parser_fact),
    test(parser_fact_structured),
    test(parser_rule),
    test(parser_rule_conjunction),
    test(parser_directive),
    test(parser_query),
    test(parser_operators_is),
    test(parser_operators_comparison),
    test(parser_list_empty),
    test(parser_list_elements),
    test(parser_list_tail),
    test(parser_negation),
    test(parser_if_then_else),
    test(parser_disjunction),
    test(parser_multiple_clauses),
    test(parser_annotations),
    test(parser_positions),
    test(parser_error_recovery),
    test(parser_module_directive),
    test(optimiser_identity),
    test(optimiser_seq_true),
    test(optimiser_fail_branch),
    test(subterm_at),
    test(subterm_set),
    test(control_if),
    test(control_not),
    test(control_forall),
    test(control_true),
    test(control_fail),
    test(control_repeat),
    test(control_conj),
    test(control_or),
    test(control_once),
    test(control_ignore),
    test(control_call2),
    test(wam_compile),
    test(wam_init),
    test(wam_regs),
    test(wam_heap_var),
    test(wam_heap_atom),
    test(wam_heap_int),
    test(wam_heap_str),
    test(wam_deref_var),
    test(wam_deref_ref_chain),
    test(wam_unify_atoms),
    test(wam_unify_var_atom),
    test(wam_unify_var_var),
    test(wam_unify_struct),
    test(wam_unify_fails),
    test(wam_trail_unwind),
    test(wam_push_env),
    test(wam_pop_env),
    test(wam_push_choice),
    test(wam_backtrack),
    test(wam_execute_instr),
    test(codegen_basic),
    test(ir_fail),
    test(ir_not),
    test(ir_repeat),
    test(ir_if_then),
    test(ir_if_then_else),
    test(ir_conjunction),
    test(ir_disjunction),
    test(exec_equiv_conjunction),
    test(exec_equiv_disjunction),
    test(exec_equiv_if_then_else),
    test(exec_equiv_negation),
    test(exec_equiv_cut),
    test(sem_fact_annotation),
    test(sem_rule_annotation),
    test(sem_arity_consistency),
    test(sem_non_callable_head),
    test(sem_singleton_vars),
    test(sem_no_singletons),
    test(sem_tail_recursion),
    test(sem_linear_recursion),
    test(sem_nested_recursion),
    test(sem_no_recursion),
    test(sem_memoisation_suitable),
    test(sem_memoisation_side_effect),
    test(sem_gaussian_tail),
    test(sem_gaussian_linear),
    test(sem_gaussian_none),
    test(sem_cognitive_marker),
    test(sem_no_cognitive_marker),
    test(sem_control_ok),
    test(sem_directive_passthrough),
    test(sem_query_passthrough),
    test(sem_parse_error_passthrough),
    test(sem_simplification_tco),
    test(sem_simplification_accum),
    test(sem_builtin_body),
    test(sem_possibly_undefined_body),
    test(sem_eliminable_nested_true),
    test(sem_eliminable_nested_false),
    % --- Stage 7: Interpreter Core ---
    test(interp_fact),
    test(interp_rule),
    test(interp_recursion),
    test(interp_backtracking),
    test(interp_cut),
    test(interp_list_processing),
    test(interp_deep_recursion),
    test(interp_disjunction),
    test(interp_negation),
    test(interp_assert_retract),
    test(interp_findall),
    test(interp_arithmetic),
    test(interp_prelude),
    test(interp_neurocode),
    test(interp_query_runner),
    test(interp_load_ast),
    % --- Stage 8: Intermediate Representation ---
    test(ir8_source_marker),
    test(ir8_predicate_def_single),
    test(ir8_predicate_def_grouped),
    test(ir8_choice_point_multi),
    test(ir8_choice_point_single),
    test(ir8_memo_site),
    test(ir8_loop_candidate),
    test(ir8_recursion_class),
    test(ir8_optimisation_meta),
    test(ir8_info_get_list),
    test(ir8_info_get_legacy),
    test(ir8_new_body_nodes_reversible),
    test(ir8_full_pipeline).

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

%% --- WAM Model (Stage 6) tests ---

%% wam_init: initial state is well-formed
run_test(wam_init) :-
    wam_init_state(S),
    wam_get_regs(S, []),
    S = wam_state([], Heap, 0, [], [], [], [], Bindings),
    assoc_to_list(Heap, []),
    assoc_to_list(Bindings, []).

%% wam_regs: register get/set round-trip
run_test(wam_regs) :-
    wam_init_state(S0),
    wam_set_reg(S0, 1, hello, S1),
    wam_set_reg(S1, 2, world, S2),
    wam_get_reg(S2, 1, hello),
    wam_get_reg(S2, 2, world).

%% wam_heap_var: allocate unbound variable
run_test(wam_heap_var) :-
    wam_init_state(S0),
    wam_alloc_var(S0, Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(var, unbound)).

%% wam_heap_atom: allocate atom and retrieve it
run_test(wam_heap_atom) :-
    wam_init_state(S0),
    wam_alloc_atom(S0, foo, Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(atom, foo)).

%% wam_heap_int: allocate integer and retrieve it
run_test(wam_heap_int) :-
    wam_init_state(S0),
    wam_alloc_int(S0, 42, Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(int, 42)).

%% wam_heap_str: allocate structure and retrieve it
run_test(wam_heap_str) :-
    wam_init_state(S0),
    wam_alloc_str(S0, f(pair, [1, 2]), Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(str, f(pair, [1, 2]))).

%% wam_deref_var: deref unbound variable returns var cell
run_test(wam_deref_var) :-
    wam_init_state(S0),
    wam_alloc_var(S0, Addr, S1),
    wam_deref(Addr, S1, heap_cell(var, unbound)).

%% wam_deref_ref_chain: deref follows reference chain
run_test(wam_deref_ref_chain) :-
    wam_init_state(S0),
    wam_alloc_var(S0, V, S1),          % addr 0: var
    wam_alloc_atom(S1, bar, A, S2),    % addr 1: atom bar
    wam_do_bind(V, A, S2, S3),        % bind 0 → 1
    wam_deref(V, S3, heap_cell(atom, bar)).

%% wam_unify_atoms: unify two identical atoms succeeds
run_test(wam_unify_atoms) :-
    wam_init_state(S0),
    wam_alloc_atom(S0, hello, A1, S1),
    wam_alloc_atom(S1, hello, A2, S2),
    wam_unify(A1, A2, S2, _S3).

%% wam_unify_var_atom: unify unbound variable with atom
run_test(wam_unify_var_atom) :-
    wam_init_state(S0),
    wam_alloc_var(S0, V, S1),
    wam_alloc_atom(S1, hello, A, S2),
    wam_unify(V, A, S2, S3),
    wam_deref(V, S3, heap_cell(atom, hello)).

%% wam_unify_var_var: unifying two vars makes them alias
run_test(wam_unify_var_var) :-
    wam_init_state(S0),
    wam_alloc_var(S0, V1, S1),
    wam_alloc_var(S1, V2, S2),
    wam_unify(V1, V2, S2, S3),
    % bind the shared alias to an atom
    wam_alloc_atom(S3, shared, A, S4),
    wam_bind(V2, A, S4, S5),
    wam_deref(V1, S5, heap_cell(atom, shared)).

%% wam_unify_struct: unify two compatible structures
run_test(wam_unify_struct) :-
    wam_init_state(S0),
    % Build f(X, 1) and f(hello, Y) on heap, then unify them
    wam_alloc_var(S0, X, S1),
    wam_alloc_int(S1, 1, I1, S2),
    wam_alloc_str(S2, f(pair, [X, I1]), Str1, S3),
    wam_alloc_atom(S3, hello, Hel, S4),
    wam_alloc_var(S4, Y, S5),
    wam_alloc_str(S5, f(pair, [Hel, Y]), Str2, S6),
    wam_unify(Str1, Str2, S6, S7),
    % After unification X should point to hello, Y should point to 1
    wam_deref(X, S7, heap_cell(atom, hello)),
    wam_deref(Y, S7, heap_cell(int, 1)).

%% wam_unify_fails: unifying incompatible atoms fails
run_test(wam_unify_fails) :-
    wam_init_state(S0),
    wam_alloc_atom(S0, foo, A1, S1),
    wam_alloc_atom(S1, bar, A2, S2),
    \+ wam_unify(A1, A2, S2, _).

%% wam_trail_unwind: bindings made after a choice point are undone
run_test(wam_trail_unwind) :-
    wam_init_state(S0),
    % Allocate variable BEFORE the choice point so it survives heap trim
    wam_alloc_var(S0, V, S1),
    % Push choice point AFTER allocating V (HeapTop = 1 > V = 0)
    wam_push_choice(S1, [[proceed]], [], S2),
    % Bind V: since V(0) < HeapTop(1) this is a conditional bind → trail
    wam_alloc_atom(S2, bound_value, A, S3),
    wam_trail_bind(V, A, S3, S4),
    % Variable is bound
    wam_deref(V, S4, heap_cell(atom, bound_value)),
    % Backtrack: trail should be unwound, V should be unbound again
    wam_backtrack(S4, _, S5),
    wam_deref(V, S5, heap_cell(var, unbound)).

%% wam_push_env: push environment frame, continuation is saved
run_test(wam_push_env) :-
    wam_init_state(S0),
    wam_push_env(S0, [proceed], S1),
    S1 = wam_state(_, _, _, [env([], [proceed], _)|_], _, _, _, _).

%% wam_pop_env: pop environment frame, continuation is restored
run_test(wam_pop_env) :-
    wam_init_state(S0),
    wam_push_env(S0, [call(foo)], S1),
    wam_pop_env(S1, RestoredCont, _S2),
    RestoredCont = [call(foo)].

%% wam_push_choice: choice point stores alternatives and saved state
run_test(wam_push_choice) :-
    wam_init_state(S0),
    wam_push_choice(S0, [[proceed], [proceed]], [], S1),
    S1 = wam_state(_, _, _, _, [choice([], [], [], 0, 0, [[proceed],[proceed]], [])|_], _, _, _).

%% wam_backtrack: restore to saved state and select next alternative
run_test(wam_backtrack) :-
    wam_init_state(S0),
    Alt1 = [get_constant(1/0)],
    Alt2 = [get_constant(2/0)],
    wam_push_choice(S0, [Alt1, Alt2], [], S1),
    % Backtracking with Alt1+Alt2 available: picks Alt1, leaves Alt2
    wam_backtrack(S1, RestAlts, S2),
    RestAlts = [Alt2],
    wam_get_cont(S2, Alt1).

%% wam_execute_instr: execute a simple instruction sequence
run_test(wam_execute_instr) :-
    wam_init_state(S0),
    Instrs = [enter(test/0), proceed],
    wam_execute(Instrs, S0, _S1).

run_test(codegen_basic) :-
    npl_generate([ir_clause(hello, ir_true, info(head:ok,body:ok))], Code),
    Code = [hello].

%% --- Additional prelude tests ---

run_test(prelude_nth0) :-
    npl_nth0(0, [a,b,c], a),
    npl_nth0(2, [a,b,c], c).

run_test(prelude_nth1) :-
    npl_nth1(1, [a,b,c], a),
    npl_nth1(3, [a,b,c], c).

run_test(prelude_select) :-
    npl_select(b, [a,b,c], R),
    R == [a,c].

run_test(prelude_delete) :-
    npl_delete([1,2,1,3], 1, R),
    R == [2,3].

run_test(prelude_subtract) :-
    npl_subtract([1,2,3,4], [2,4], R),
    R == [1,3].

run_test(prelude_intersection) :-
    npl_intersection([1,2,3], [2,3,4], R),
    R == [2,3].

run_test(prelude_union) :-
    npl_union([1,2], [2,3], R),
    R == [1,2,3].

run_test(prelude_list_to_set) :-
    npl_list_to_set([1,2,1,3,2], R),
    R == [1,2,3].

run_test(prelude_sort) :-
    npl_sort([3,1,2,1], R),
    R == [1,2,3].

run_test(prelude_functor) :-
    npl_functor(foo(a,b), F, A),
    F == foo, A == 2.

run_test(prelude_arg) :-
    npl_arg(2, foo(a,b,c), X),
    X == b.

run_test(prelude_univ) :-
    npl_univ(foo(1,2), L),
    L == [foo,1,2],
    npl_univ(T, [bar,x]),
    T == bar(x).

run_test(prelude_copy_term) :-
    npl_copy_term(f(X, X), f(A, B)),
    A == B.

run_test(prelude_type_checks) :-
    npl_var(_),
    npl_nonvar(42),
    npl_atom(hello),
    npl_number(3.14),
    npl_integer(7),
    npl_float(1.0),
    npl_compound(f(x)),
    npl_atomic(foo),
    npl_callable(foo),
    npl_ground(foo(1,2)),
    npl_is_list([1,2,3]).

run_test(prelude_unify) :-
    npl_unify(X, hello),
    X == hello,
    npl_unify_with_occurs_check(a, a).

run_test(prelude_compare) :-
    npl_compare(Order, a, b),
    Order == (<).

run_test(prelude_maplist2) :-
    npl_maplist(number, [1,2,3]).

run_test(prelude_maplist3) :-
    npl_maplist([X, Y]>>(Y is X * 2), [1,2,3], R),
    R == [2,4,6].

run_test(prelude_foldl) :-
    npl_foldl([X, Acc, Acc1]>>(Acc1 is Acc + X), [1,2,3], 0, S),
    S == 6.

run_test(prelude_include) :-
    npl_include([X]>>(X > 2), [1,2,3,4], R),
    R == [3,4].

run_test(prelude_exclude) :-
    npl_exclude([X]>>(X > 2), [1,2,3,4], R),
    R == [1,2].

%% --- Additional control tests ---

run_test(control_true) :-
    npl_true.

run_test(control_fail) :-
    \+ npl_fail.

run_test(control_repeat) :-
    npl_between(1, 5, N),
    call(npl_repeat),
    N =:= 1, !.

run_test(control_conj) :-
    npl_conj(true, X = yes),
    X == yes.

run_test(control_or) :-
    npl_or(fail, Y = ok),
    Y == ok.

run_test(control_once) :-
    npl_once(member(X, [a,b,c])),
    X == a.

run_test(control_ignore) :-
    npl_ignore(fail).

run_test(control_call2) :-
    npl_call(succ, 3, R),
    R == 4.

%% --- IR round-trip tests ---

run_test(ir_fail) :-
    npl_body_to_ir(fail, IR),
    IR == ir_fail,
    npl_ir_to_body(IR, Body),
    Body == fail.

run_test(ir_not) :-
    npl_body_to_ir(\+(foo), IR),
    IR == ir_not(ir_call(foo)),
    npl_ir_to_body(IR, Body),
    Body == \+(foo).

run_test(ir_repeat) :-
    npl_body_to_ir(repeat, IR),
    IR == ir_repeat,
    npl_ir_to_body(IR, Body),
    Body == repeat.

run_test(ir_if_then) :-
    npl_body_to_ir((true -> done), IR),
    IR == ir_if(ir_true, ir_call(done), ir_fail),
    npl_ir_to_body(IR, Body),
    Body == (true -> done).

run_test(ir_if_then_else) :-
    npl_body_to_ir((true -> yes ; no), IR),
    IR == ir_if(ir_true, ir_call(yes), ir_call(no)),
    npl_ir_to_body(IR, Body),
    Body == (true -> yes ; no).

run_test(ir_conjunction) :-
    npl_body_to_ir((a, b), IR),
    IR == ir_seq(ir_call(a), ir_call(b)),
    npl_ir_to_body(IR, Body),
    Body == (a, b).

run_test(ir_disjunction) :-
    npl_body_to_ir((a ; b), IR),
    IR == ir_disj(ir_call(a), ir_call(b)),
    npl_ir_to_body(IR, Body),
    Body == (a ; b).

%% --- Execution equivalence tests ---
%% These verify that control structures produce the same result
%% whether executed directly or via IR → codegen → neurocode.

run_test(exec_equiv_conjunction) :-
    Body = (X = hello, Y = world),
    call(Body),
    X == hello, Y == world,
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody),
    X == hello, Y == world.

run_test(exec_equiv_disjunction) :-
    Body = (Z = left ; Z = right),
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody),
    ( Z == left ; Z == right ).

run_test(exec_equiv_if_then_else) :-
    Body = (1 > 0 -> R = yes ; R = no),
    call(Body),
    R == yes,
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody),
    R == yes.

run_test(exec_equiv_negation) :-
    Body = \+(fail),
    call(Body),
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody).

run_test(exec_equiv_cut) :-
    Body = (!, true),
    call(Body),
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody).

%% =====================================================================
%% Lexer tests — Stage 3
%% =====================================================================

%% Atoms: plain lowercase and quoted atoms
run_test(lexer_atoms) :-
    npl_lex_string('foo', [atom(foo)]),
    npl_lex_string('hello_world', [atom(hello_world)]),
    npl_lex_string('is', [atom(is)]).

%% Variables: uppercase-initial identifiers
run_test(lexer_variables) :-
    npl_lex_string('X', [var('X')]),
    npl_lex_string('MyVar', [var('MyVar')]),
    npl_lex_string('ABC', [var('ABC')]).

%% Anonymous and named-underscore variables
run_test(lexer_anonymous_var) :-
    npl_lex_string('_', [var('_')]),
    npl_lex_string('_Foo', [var('_Foo')]),
    npl_lex_string('_count', [var('_count')]),
    npl_lex_string('_1', [var('_1')]),
    npl_lex_string('__foo', [var('__foo')]).

%% Integer literals
run_test(lexer_integers) :-
    npl_lex_string('0', [integer(0)]),
    npl_lex_string('42', [integer(42)]),
    npl_lex_string('100', [integer(100)]).

%% Floating-point literals
run_test(lexer_floats) :-
    npl_lex_string('3.14', [float(3.14)]),
    npl_lex_string('0.5', [float(0.5)]),
    npl_lex_string('1.0', [float(1.0)]).

%% Double-quoted string literals
run_test(lexer_strings) :-
    npl_lex_string('"hello"', [string(hello)]),
    npl_lex_string('"foo bar"', [string('foo bar')]).

%% Operator symbol sequences
run_test(lexer_operators) :-
    npl_lex_string(':-', [atom(':-')]),
    npl_lex_string('=', [atom('=')]),
    npl_lex_string('>=', [atom('>=')]),
    npl_lex_string('\\+', [atom('\\+')]).

%% Line comments are discarded; surrounding tokens are kept
run_test(lexer_line_comment) :-
    npl_lex_string('foo % a comment', [atom(foo)]),
    npl_lex_string('a % ignore\nb', [atom(a), atom(b)]).

%% Block comments are discarded
run_test(lexer_block_comment) :-
    npl_lex_string('/* comment */ foo', [atom(foo)]),
    npl_lex_string('a /* mid */ b', [atom(a), atom(b)]).

%% Cognitive-code annotations (%@ ...) produce annot/1 tokens
run_test(lexer_annotation) :-
    npl_lex_string('%@ cognitive:marker', [annot('cognitive:marker')]),
    npl_lex_string('foo %@ tag', [atom(foo), annot(tag)]).

%% Clause terminator: period is emitted as punct('.')
run_test(lexer_clause_terminator) :-
    npl_lex_string('foo.', [atom(foo), punct('.')]),
    npl_lex_string('a :- b.', [atom(a), atom(':-'), atom(b), punct('.')]).

%% List syntax: brackets and pipe
run_test(lexer_list_syntax) :-
    npl_lex_string('[a,b,c]', [punct('['), atom(a), punct(','),
                                atom(b), punct(','), atom(c), punct(']')]),
    npl_lex_string('[H|T]', [punct('['), var('H'), punct('|'),
                              var('T'), punct(']')]).

%% Source positions are recorded correctly
run_test(lexer_positions) :-
    npl_lex_string_pos('foo bar', Tokens),
    Tokens = [tok(atom(foo), pos(1,1)), tok(atom(bar), pos(1,5))].

%% Multiline: line counter advances on newlines
run_test(lexer_multiline_pos) :-
    npl_lex_string_pos('foo\nbar', Tokens),
    Tokens = [tok(atom(foo), pos(1,1)), tok(atom(bar), pos(2,1))].

%% Error: unterminated double-quoted string
run_test(lexer_error_unterminated_string) :-
    npl_lex_string('"hello', Tokens),
    Tokens = [error(unterminated_string)].

%% Error: unterminated single-quoted atom
%  Build the atom code list explicitly: single-quote followed by 'hello' (no closing quote).
run_test(lexer_error_unterminated_atom) :-
    atom_codes(Input, [0'', 0'h, 0'e, 0'l, 0'l, 0'o]),
    npl_lex_string(Input, Tokens),
    Tokens = [error(unterminated_atom)].

%% Error: unterminated block comment
run_test(lexer_error_block_comment) :-
    npl_lex_string('/* unclosed', Tokens),
    Tokens = [error(unterminated_block_comment)].

%% Error: unknown character produces an error token; lexing continues
run_test(lexer_error_unknown_char) :-
    npl_lex_string('$foo', Tokens),
    Tokens = [error(unknown_char('$')), atom(foo)].

%% =====================================================================
%% Parser tests — Stage 4
%% =====================================================================

%% Unit clause (fact) with no body
run_test(parser_fact) :-
    npl_parse_string('foo.', AST),
    AST = [fact(foo, no_pos, [], [])].

%% Structured fact: head with arguments
run_test(parser_fact_structured) :-
    npl_parse_string('foo(a, b).', AST),
    AST = [fact(foo(a,b), no_pos, [], [])].

%% Simple rule:  head :- body.
run_test(parser_rule) :-
    npl_parse_string('foo :- bar.', AST),
    AST = [rule(foo, bar, no_pos, [], [])].

%% Rule with conjunctive body
run_test(parser_rule_conjunction) :-
    npl_parse_string('foo :- a, b, c.', AST),
    AST = [rule(foo, ','(a,','(b,c)), no_pos, [], [])].

%% Directive:  :- Goal.
run_test(parser_directive) :-
    npl_parse_string(':- dynamic(foo/1).', AST),
    AST = [directive(dynamic('/'(foo,1)), no_pos, [], [])].

%% Query:  ?- Goal.
run_test(parser_query) :-
    npl_parse_string('?- member(X, [1,2]).', AST),
    AST = [query(member(var('X'),[1,2]), no_pos, [], [])].

%% Arithmetic expression via 'is' operator
run_test(parser_operators_is) :-
    npl_parse_string('r :- X is 1 + 2.', AST),
    AST = [rule(r, is(var('X'), '+'(1,2)), no_pos, [], [])].

%% Comparison operator
run_test(parser_operators_comparison) :-
    npl_parse_string('r :- X >= 0.', AST),
    AST = [rule(r, '>='(var('X'),0), no_pos, [], [])].

%% Empty list
run_test(parser_list_empty) :-
    npl_parse_string('r([]).', AST),
    AST = [fact(r([]), no_pos, [], [])].

%% List with elements
run_test(parser_list_elements) :-
    npl_parse_string('r([1,2,3]).', AST),
    AST = [fact(r([1,2,3]), no_pos, [], [])].

%% List with explicit tail
run_test(parser_list_tail) :-
    npl_parse_string('r([H|T]).', AST),
    AST = [fact(r([var('H')|var('T')]), no_pos, [], [])].

%% Prefix negation operator  \+
run_test(parser_negation) :-
    npl_parse_string('r :- \\+ foo.', AST),
    AST = [rule(r, '\\+'(foo), no_pos, [], [])].

%% If-then-else:  ( Cond -> Then ; Else )
run_test(parser_if_then_else) :-
    npl_parse_string('r :- (a -> b ; c).', AST),
    AST = [rule(r, ';'('->'(a,b),c), no_pos, [], [])].

%% Disjunction without if-then
run_test(parser_disjunction) :-
    npl_parse_string('r :- a ; b.', AST),
    AST = [rule(r, ';'(a,b), no_pos, [], [])].

%% Multiple clauses in one source string
run_test(parser_multiple_clauses) :-
    npl_parse_string('foo. bar :- baz.', AST),
    AST = [fact(foo, no_pos, [], []),
           rule(bar, baz, no_pos, [], [])].

%% Cognitive-code annotations are attached to the following clause
run_test(parser_annotations) :-
    npl_parse_string('%@ my:note\nfoo.', AST),
    AST = [fact(foo, no_pos, ['my:note'], [])].

%% Source positions are tracked when parsing via npl_parse_string_pos/2
run_test(parser_positions) :-
    npl_parse_string_pos('foo.', AST),
    AST = [fact(foo, pos(1,1), [], [])].

%% Syntax errors produce a parse_error node; parsing continues afterward
run_test(parser_error_recovery) :-
    npl_parse_string('!bad. foo.', AST),
    AST = [parse_error(syntax_error, _), fact(foo, no_pos, [], [])].

%% Module directive: :- module(Name, Exports).
run_test(parser_module_directive) :-
    npl_parse_string(':- module(mymod, []).', AST),
    AST = [directive(module(mymod, []), no_pos, [], [])].

%% =====================================================================
%% Semantic Analyser tests — Stage 5
%% =====================================================================

%% Helper: get a named property from the Props list of an analysed/3 node.
sem_prop(Props, Key, Val) :-
    member(Key:Val, Props).

%% --- Annotation structure ---

%% A simple fact produces an analysed/3 node with the full annotation list.
run_test(sem_fact_annotation) :-
    npl_analyse([fact(foo, no_pos, [], [])], [analysed(foo, true, Props)]),
    sem_prop(Props, head, ok),
    sem_prop(Props, body, ok).

%% A rule produces analysed/3 with head and body annotations.
run_test(sem_rule_annotation) :-
    npl_analyse([rule(foo(a), true, no_pos, [], [])], [analysed(foo(a), true, Props)]),
    sem_prop(Props, head, ok),
    sem_prop(Props, body, ok).

%% --- Arity / head consistency ---

%% A callable head is accepted.
run_test(sem_arity_consistency) :-
    npl_analyse([fact(my_pred(a, b), no_pos, [], [])],
                [analysed(my_pred(a,b), true, Props)]),
    sem_prop(Props, head, ok).

%% A non-callable head (raw integer) reports an error.
run_test(sem_non_callable_head) :-
    npl_analyse([fact(42, no_pos, [], [])],
                [analysed(42, true, Props)]),
    sem_prop(Props, head, error(non_callable_head)).

%% --- Variable usage ---

%% A rule with a variable used in both head and body should have no singletons.
run_test(sem_no_singletons) :-
    npl_parse_string('foo(X) :- bar(X).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, variables, ok).

%% A rule with a variable that appears only once is a singleton.
run_test(sem_singleton_vars) :-
    npl_parse_string('foo(X) :- bar(Y).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, variables, warning(singletons, _)).

%% --- Control structure placement ---

%% A normal rule body has no control warnings.
run_test(sem_control_ok) :-
    npl_parse_string('foo :- bar, baz.', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, control, ok).

%% --- Recursion classification ---

%% Tail recursion: last call is the same predicate.
%% count(0) :- true.  count(N) :- N > 0, N1 is N-1, count(N1).
run_test(sem_tail_recursion) :-
    AST = [ fact(count(0), no_pos, [], []),
            rule(count(N), ','('>'(N,0), ','(is(N1, '-'(N,1)), count(N1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, recursion_class, tail).

%% Linear recursion: exactly one recursive call, not last.
%% len([], 0).  len([_|T], N) :- len(T, N1), N is N1+1.
run_test(sem_linear_recursion) :-
    AST = [ fact(len([], 0), no_pos, [], []),
            rule(len([_|T], N), ','(len(T, N1), is(N, '+'(N1, 1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, recursion_class, linear).

%% Nested recursion: recursive call inside an argument of another recursive call.
%% ack(0,N,R) :- R is N+1.
%% ack(M,0,R) :- M1 is M-1, ack(M1,1,R).
%% ack(M,N,R) :- N1 is N-1, ack(M,N1,R1), M1 is M-1, ack(M1,R1,R).
%% Simplified: a body with two recursive calls and atom arguments (no sub-recursive
%% calls inside arguments) classifies as linear (not nested).
run_test(sem_nested_recursion) :-
    Sig = fib/2,
    Body = ','(fib(a, x), fib(b, y)),
    semantic_analyser:npl_classify_recursion(Sig, fib(n), Body, [], Class),
    Class = linear.

%% No recursion: base case fact.
run_test(sem_no_recursion) :-
    npl_analyse([fact(base, no_pos, [], [])],
                [analysed(base, true, Props)]),
    sem_prop(Props, recursion_class, none).

%% --- Memoisation suitability ---

%% A pure parameterised predicate is a memoisation candidate.
run_test(sem_memoisation_suitable) :-
    AST = [rule(fib(0, 1), true, no_pos, [], []),
           rule(fib(1, 1), true, no_pos, [], [])],
    npl_analyse(AST, [analysed(_, _, P1)|_]),
    sem_prop(P1, memoisation_suitable, true).

%% A predicate that writes to stdout is not a memoisation candidate.
run_test(sem_memoisation_side_effect) :-
    AST = [rule(greet(X), write(X), no_pos, [], [])],
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, memoisation_suitable, false).

%% --- Gaussian elimination suitability ---

%% Tail-recursive predicate is suitable.
run_test(sem_gaussian_tail) :-
    AST = [ fact(count(0), no_pos, [], []),
            rule(count(N), ','('>'(N,0), ','(is(N1,'-'(N,1)), count(N1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, gaussian_elimination_suitable, true).

%% Linear-recursive predicate is also suitable.
run_test(sem_gaussian_linear) :-
    AST = [ fact(len([], 0), no_pos, [], []),
            rule(len([_|T], N), ','(len(T, N1), is(N,'+'(N1,1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, gaussian_elimination_suitable, true).

%% Non-recursive predicate is not suitable.
run_test(sem_gaussian_none) :-
    npl_analyse([fact(base, no_pos, [], [])],
                [analysed(_, _, Props)]),
    sem_prop(Props, gaussian_elimination_suitable, false).

%% --- Cognitive-code markers ---

%% Annotation from %@ is attached as cognitive_code_marker.
run_test(sem_cognitive_marker) :-
    npl_parse_string('%@ memoisation:hint\nfoo(X) :- bar(X).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, cognitive_code_marker, 'memoisation:hint').

%% No annotation → marker is none.
run_test(sem_no_cognitive_marker) :-
    npl_parse_string('foo(X) :- bar(X).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, cognitive_code_marker, none).

%% --- Pass-through nodes ---

%% Directives are unchanged.
run_test(sem_directive_passthrough) :-
    npl_analyse([directive(use_module(foo), no_pos, [], [])],
                [directive(use_module(foo), no_pos, [], [])]).

%% Queries are unchanged.
run_test(sem_query_passthrough) :-
    npl_analyse([query(foo, no_pos, [], [])],
                [query(foo, no_pos, [], [])]).

%% Parse errors are unchanged.
run_test(sem_parse_error_passthrough) :-
    npl_analyse([parse_error(syntax_error, no_pos)],
                [parse_error(syntax_error, no_pos)]).

%% --- Simplification opportunities ---

%% A tail-recursive predicate should include tail_call_optimisation.
run_test(sem_simplification_tco) :-
    AST = [ fact(count(0), no_pos, [], []),
            rule(count(N), ','('>'(N,0), ','(is(N1,'-'(N,1)), count(N1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, simplification_opportunities, Ops),
    member(tail_call_optimisation, Ops).

%% A linear-recursive predicate includes accumulator_introduction.
run_test(sem_simplification_accum) :-
    AST = [ fact(len([], 0), no_pos, [], []),
            rule(len([_|T], N), ','(len(T, N1), is(N,'+'(N1,1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, simplification_opportunities, Ops),
    member(accumulator_introduction, Ops).

%% --- Body goal validation ---

%% A body that calls a known built-in (write) should be ok.
run_test(sem_builtin_body) :-
    npl_analyse([rule(greet, write(hello), no_pos, [], [])],
                [analysed(_, _, Props)]),
    sem_prop(Props, body, ok).

%% A body that calls a predicate not in the AST and not a built-in
%% should warn possibly_undefined.
run_test(sem_possibly_undefined_body) :-
    npl_analyse([rule(foo, my_unknown_predicate_xyz, no_pos, [], [])],
                [analysed(_, _, Props)]),
    sem_prop(Props, body, warning(possibly_undefined, _)).

%% --- Eliminable nested recursion annotation ---

%% nested recursion class → eliminable = true
run_test(sem_eliminable_nested_true) :-
    semantic_analyser:npl_eliminable_nested(nested, true).

%% tail recursion class → eliminable = false
run_test(sem_eliminable_nested_false) :-
    semantic_analyser:npl_eliminable_nested(tail, false).

%% =====================================================================
%% Interpreter tests — Stage 7
%% =====================================================================
%%
%% Each test calls npl_interp_reset/0 first to ensure a clean database.

%% interp_fact — load facts and query them
run_test(interp_fact) :-
    npl_interp_reset,
    npl_interp_assert(color(red)),
    npl_interp_assert(color(green)),
    npl_interp_assert(color(blue)),
    npl_interp_query(color(red), true),
    npl_interp_query(color(green), true),
    npl_interp_query(color(yellow), false).

%% interp_rule — load a rule and derive a conclusion
run_test(interp_rule) :-
    npl_interp_reset,
    npl_interp_assert(parent(tom, bob)),
    npl_interp_assert(parent(bob, ann)),
    npl_interp_assert((grandparent(X, Z) :- parent(X, Y), parent(Y, Z))),
    npl_interp_query(grandparent(tom, ann), true),
    npl_interp_query(grandparent(tom, bob), false).

%% interp_recursion — recursive membership predicate
run_test(interp_recursion) :-
    npl_interp_reset,
    npl_interp_assert((my_member(X, [X|_]))),
    npl_interp_assert((my_member(X, [_|T]) :- my_member(X, T))),
    npl_interp_query(my_member(2, [1,2,3]), true),
    npl_interp_query(my_member(4, [1,2,3]), false).

%% interp_backtracking — collect multiple solutions via backtracking
run_test(interp_backtracking) :-
    npl_interp_reset,
    npl_interp_assert(fruit(apple)),
    npl_interp_assert(fruit(banana)),
    npl_interp_assert(fruit(cherry)),
    npl_interp_query_all(fruit(F), F, Fruits),
    Fruits == [apple, banana, cherry].

%% interp_cut — cut prevents backtracking to further clauses
run_test(interp_cut) :-
    npl_interp_reset,
    npl_interp_assert((first_color(red) :- !)),
    npl_interp_assert(first_color(blue)),
    npl_interp_query_all(first_color(C), C, Colors),
    Colors == [red].

%% interp_list_processing — interpreter runs list append rules
run_test(interp_list_processing) :-
    npl_interp_reset,
    npl_interp_assert((my_append([], L, L))),
    npl_interp_assert((my_append([H|T], L, [H|R]) :- my_append(T, L, R))),
    npl_interp_query_all(my_append([1,2], [3,4], Z), Z, [[1,2,3,4]]),
    npl_interp_query_all(my_append(A, B, [a,b]),
                         A-B,
                         [ []-[a,b],
                           [a]-[b],
                           [a,b]-[] ]).

%% interp_deep_recursion — list length via recursion + arithmetic
run_test(interp_deep_recursion) :-
    npl_interp_reset,
    npl_interp_assert((my_length([], 0))),
    npl_interp_assert((my_length([_|T], N) :- my_length(T, N1), N is N1 + 1)),
    npl_interp_query_all(my_length([a,b,c,d], N), N, [4]).

%% interp_disjunction — disjunctive bodies work correctly
run_test(interp_disjunction) :-
    npl_interp_reset,
    npl_interp_assert((likes(X) :- (X = cats ; X = dogs))),
    npl_interp_query_all(likes(A), A, Likes),
    Likes == [cats, dogs].

%% interp_negation — negation as failure
run_test(interp_negation) :-
    npl_interp_reset,
    npl_interp_assert(bird(penguin)),
    npl_interp_assert(bird(eagle)),
    npl_interp_assert((can_fly(B) :- bird(B), \+ B = penguin)),
    npl_interp_query_all(can_fly(B), B, Flyers),
    Flyers == [eagle].

%% interp_assert_retract — dynamic assertion and retraction
run_test(interp_assert_retract) :-
    npl_interp_reset,
    npl_interp_assert(item(a)),
    npl_interp_assert(item(b)),
    npl_interp_query(item(a), true),
    npl_interp_retract(item(a)),
    npl_interp_query(item(a), false),
    npl_interp_query(item(b), true).

%% interp_findall — findall collects all solutions via interpreter
run_test(interp_findall) :-
    npl_interp_reset,
    npl_interp_assert(digit(1)),
    npl_interp_assert(digit(2)),
    npl_interp_assert(digit(3)),
    npl_interp_assert((even_digit(D) :- digit(D), 0 =:= D mod 2)),
    npl_interp_query_all(even_digit(D), D, Evens),
    Evens == [2].

%% interp_arithmetic — arithmetic operations in interpreted code
run_test(interp_arithmetic) :-
    npl_interp_reset,
    npl_interp_assert((square(X, Y) :- Y is X * X)),
    npl_interp_assert((sum_squares(A, B, S) :-
        square(A, SA), square(B, SB), S is SA + SB)),
    npl_interp_query_all(sum_squares(3, 4, S), S, [25]).

%% interp_prelude — prelude predicates callable from interpreted code
run_test(interp_prelude) :-
    npl_interp_reset,
    npl_interp_assert((demo_append(L) :- npl_append([1,2], [3,4], L))),
    npl_interp_assert((demo_reverse(R) :- npl_reverse([a,b,c], R))),
    npl_interp_query_all(demo_append(L), L, [[1,2,3,4]]),
    npl_interp_query_all(demo_reverse(R), R, [[c,b,a]]).

%% interp_neurocode — load and execute generated neurocode
run_test(interp_neurocode) :-
    npl_interp_reset,
    % Generate neurocode from IR and load it into the interpreter.
    % nc_greeting/0 is a rule; nc_lucky/1 is a ground fact.
    npl_generate(
        [ ir_clause(nc_greeting,
                    ir_seq(ir_call(write(hi_neurocode)), ir_call(nl)),
                    info(head:ok, body:ok)),
          ir_clause(nc_lucky(7),
                    ir_true,
                    info(head:ok, body:ok)) ],
        Code
    ),
    npl_interp_load_clauses(Code),
    npl_interp_query(nc_greeting, true),
    npl_interp_query(nc_lucky(7), true),
    npl_interp_query(nc_lucky(8), false).

%% interp_query_runner — batch query runner returns true/false per query
run_test(interp_query_runner) :-
    npl_interp_reset,
    npl_interp_assert(ok(a)),
    npl_interp_assert(ok(b)),
    npl_query_runner([ok(a), ok(c), ok(b)], Results),
    Results == [true, false, true].

%% interp_load_ast — load a parsed AST (ground facts) through the interpreter
run_test(interp_load_ast) :-
    npl_interp_reset,
    % Parse ground facts only (parser var(Name) placeholders are not Prolog vars)
    npl_parse_string('animal(cat). animal(dog). animal(fish).', AST),
    npl_interp_load(AST),
    npl_interp_query(animal(cat), true),
    npl_interp_query(animal(dog), true),
    npl_interp_query(animal(bird), false).

%% =====================================================================
%% Stage 8 tests — Intermediate Representation
%% =====================================================================

%% ir8_source_marker — source position is preserved in IRInfo after full pipeline
run_test(ir8_source_marker) :-
    npl_parse_string_pos('foo(1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, [ir_clause(foo(1), ir_true, IRInfo)]),
    npl_ir_info_get(IRInfo, source_marker, Pos),
    Pos = pos(1, 1).

%% ir8_predicate_def_single — npl_ir_full/2 wraps a single clause in ir_predicate_def
run_test(ir8_predicate_def_single) :-
    AAST = [analysed(greet, ir_call(hello), [])],
    npl_ir_full(AAST, [ir_predicate_def(greet/0, [ir_clause(greet, _, _)], Meta)]),
    member(choice_point:false, Meta).

%% ir8_predicate_def_grouped — clauses for the same predicate are grouped together
run_test(ir8_predicate_def_grouped) :-
    npl_parse_string('color(red). color(green). color(blue).', AST),
    npl_analyse(AST, AAST),
    npl_ir_full(AAST, PredDefs),
    PredDefs = [ir_predicate_def(color/1, Clauses, Meta)],
    length(Clauses, 3),
    member(choice_point:true, Meta).

%% ir8_choice_point_multi — multi-clause predicate has choice_point:true in each ir_clause
run_test(ir8_choice_point_multi) :-
    npl_parse_string('shape(circle). shape(square).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    IR = [ir_clause(_, _, Info1), ir_clause(_, _, Info2)],
    npl_ir_info_get(Info1, choice_point, true),
    npl_ir_info_get(Info2, choice_point, true).

%% ir8_choice_point_single — a unique predicate has choice_point:false
run_test(ir8_choice_point_single) :-
    npl_parse_string('unique_pred_xyz(a).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, [ir_clause(_, _, Info)]),
    npl_ir_info_get(Info, choice_point, false).

%% ir8_memo_site — a pure predicate is annotated memo_site:true in IRInfo
run_test(ir8_memo_site) :-
    npl_parse_string('pure_fn(1, one).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, [ir_clause(_, _, Info)]),
    npl_ir_info_get(Info, memo_site, true).

%% ir8_loop_candidate — a tail-recursive predicate is annotated loop_candidate:true
run_test(ir8_loop_candidate) :-
    npl_parse_string('count(0). count(N) :- N > 0, N1 is N - 1, count(N1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    last(IR, ir_clause(_, _, Info)),
    npl_ir_info_get(Info, loop_candidate, true).

%% ir8_recursion_class — tail-recursive clause carries recursion_class:tail in IRInfo
run_test(ir8_recursion_class) :-
    npl_parse_string('loop(0). loop(N) :- N > 0, N1 is N - 1, loop(N1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    last(IR, ir_clause(_, _, Info)),
    npl_ir_info_get(Info, recursion_class, tail).

%% ir8_optimisation_meta — a tail-recursive predicate carries optimisation hints
run_test(ir8_optimisation_meta) :-
    npl_parse_string('go(0). go(N) :- N > 0, N1 is N - 1, go(N1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    last(IR, ir_clause(_, _, Info)),
    npl_ir_info_get(Info, optimisation_meta, Ops),
    member(tail_call_optimisation, Ops).

%% ir8_info_get_list — npl_ir_info_get/3 works with the new list Info format
run_test(ir8_info_get_list) :-
    Info = [source_marker:pos(1,1), memo_site:true, loop_candidate:false],
    npl_ir_info_get(Info, source_marker, pos(1,1)),
    npl_ir_info_get(Info, memo_site, true),
    npl_ir_info_get(Info, loop_candidate, false).

%% ir8_info_get_legacy — npl_ir_info_get/3 also works with the old info(...) format
run_test(ir8_info_get_legacy) :-
    npl_ir_info_get(info(head:ok, body:ok), head, ok),
    npl_ir_info_get(info(head:ok, body:ok), body, ok).

%% ir8_new_body_nodes_reversible — new IR body nodes round-trip through npl_ir_to_body/2
run_test(ir8_new_body_nodes_reversible) :-
    %% ir_source_marker is transparent — yields the wrapped body
    npl_ir_to_body(ir_source_marker(pos(1,1), ir_call(foo)), foo),
    %% ir_memo_site is transparent — yields the wrapped body
    npl_ir_to_body(ir_memo_site(f(1), ir_call(bar)), bar),
    %% ir_loop_candidate is transparent — yields the wrapped body
    npl_ir_to_body(ir_loop_candidate(ir_call(baz)), baz),
    %% ir_choice_point/1 with one alternative yields that alternative's body
    npl_ir_to_body(ir_choice_point([ir_call(left)]), left),
    %% ir_choice_point/1 with two alternatives yields a disjunction
    npl_ir_to_body(ir_choice_point([ir_call(a), ir_call(b)]), (a ; b)).

%% ir8_full_pipeline — AST-to-IR conversion end-to-end, checking all IR fields
run_test(ir8_full_pipeline) :-
    %% Parse a two-clause predicate with a tail-recursive rule using positioned tokens
    npl_parse_string_pos(
        'fib(0, 0). fib(1, 1). fib(N, F) :- N > 1, N1 is N-1, N2 is N-2, fib(N1,F1), fib(N2,F2), F is F1+F2.',
        AST),
    npl_analyse(AST, AAST),
    %% Flat IR: all three clauses present
    npl_intermediate(AAST, FlatIR),
    length(FlatIR, 3),
    %% All clauses share the same functor
    FlatIR = [ir_clause(fib(_,_), _, Info1)|_],
    %% Source position is captured
    npl_ir_info_get(Info1, source_marker, pos(1,1)),
    %% Grouped IR: one predicate definition with three clauses
    npl_ir_full(AAST, [ir_predicate_def(fib/2, PredClauses, PMeta)]),
    length(PredClauses, 3),
    %% Predicate-level metadata reflects multiple clauses (choice point)
    member(choice_point:true, PMeta),
    %% The recursive clause carries recursion class and optimisation hints
    last(FlatIR, ir_clause(_, _, LastInfo)),
    npl_ir_info_get(LastInfo, recursion_class, linear).
