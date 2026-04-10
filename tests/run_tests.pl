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
    test(exec_equiv_cut).

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
