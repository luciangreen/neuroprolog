% optimiser.pl — NeuroProlog Optimiser
%
% Applies transformations to the IR to produce optimised IR.
% Delegates to sub-modules for specific optimisation strategies.

:- module(optimiser, [npl_optimise/2,
                     npl_ir_instantiate_all/2,
                     npl_arith_inline_pass/2]).

:- use_module(library(lists)).

:- use_module('./gaussian_recursion').
:- use_module('./memoisation').
:- use_module('./subterm_addressing').
:- use_module('./optimisation_dictionary').
:- use_module('./nested_recursion').

%% npl_optimise/2
%  npl_optimise(+IR, -OptIR)
npl_optimise(IR, OptIR) :-
    npl_apply_optimisations(IR, OptIR).

%% npl_apply_optimisations/2
%  Apply all registered optimisations in sequence.
npl_apply_optimisations(IR, OptIR) :-
    npl_opt_dict_rules(Rules),
    npl_apply_rules(Rules, IR, IR1),
    npl_ir_instantiate_all(IR1, IR2),
    npl_gaussian_reduce(IR2, IR3),
    npl_nested_eliminate_pass(IR3, IR4),
    npl_memoisation_pass(IR4, IR5),
    npl_subterm_address_pass(IR5, IR6),
    npl_arith_inline_pass(IR6, OptIR).

%% npl_apply_rules/3
npl_apply_rules([], IR, IR).
npl_apply_rules([Rule|Rules], IR, OptIR) :-
    npl_apply_rule(Rule, IR, IR1),
    npl_apply_rules(Rules, IR1, OptIR).

%% npl_apply_rule/3
%  Apply a single named optimisation rule to IR.
npl_apply_rule(Rule, IR, OptIR) :-
    ( npl_opt_rule(Rule, Pattern, Replacement) ->
        npl_transform_ir(IR, Pattern, Replacement, OptIR)
    ; OptIR = IR
    ).

%% npl_transform_ir/4
%  Apply a term-rewriting rule to all IR nodes, recursively.
npl_transform_ir([], _, _, []).
npl_transform_ir([Node|Nodes], Pattern, Replacement, [OptNode|OptNodes]) :-
    npl_rewrite_term(Node, Pattern, Replacement, OptNode),
    npl_transform_ir(Nodes, Pattern, Replacement, OptNodes).

npl_rewrite_term(Term, Pattern, Replacement, Result) :-
    copy_term(Pattern-Replacement, P-R),
    Term = P, !,
    Result = R.
npl_rewrite_term(ir_clause(Head, Body, Info), Pattern, Replacement,
                 ir_clause(Head, Body1, Info)) :- !,
    npl_rewrite_term(Body, Pattern, Replacement, Body1).
npl_rewrite_term(ir_seq(A, B), Pattern, Replacement, ir_seq(A1, B1)) :- !,
    npl_rewrite_term(A, Pattern, Replacement, A1),
    npl_rewrite_term(B, Pattern, Replacement, B1).
npl_rewrite_term(ir_disj(A, B), Pattern, Replacement, ir_disj(A1, B1)) :- !,
    npl_rewrite_term(A, Pattern, Replacement, A1),
    npl_rewrite_term(B, Pattern, Replacement, B1).
npl_rewrite_term(ir_if(C, T, E), Pattern, Replacement, ir_if(C1, T1, E1)) :- !,
    npl_rewrite_term(C, Pattern, Replacement, C1),
    npl_rewrite_term(T, Pattern, Replacement, T1),
    npl_rewrite_term(E, Pattern, Replacement, E1).
npl_rewrite_term(ir_not(G), Pattern, Replacement, ir_not(G1)) :- !,
    npl_rewrite_term(G, Pattern, Replacement, G1).
npl_rewrite_term(ir_source_marker(Pos, B), Pattern, Replacement,
                 ir_source_marker(Pos, B1)) :- !,
    npl_rewrite_term(B, Pattern, Replacement, B1).
npl_rewrite_term(ir_memo_site(H, B), Pattern, Replacement,
                 ir_memo_site(H, B1)) :- !,
    npl_rewrite_term(B, Pattern, Replacement, B1).
npl_rewrite_term(ir_loop_candidate(B), Pattern, Replacement,
                 ir_loop_candidate(B1)) :- !,
    npl_rewrite_term(B, Pattern, Replacement, B1).
npl_rewrite_term(ir_addr_loop(TV, Sig, B), Pattern, Replacement,
                 ir_addr_loop(TV, Sig, B1)) :- !,
    npl_rewrite_term(B, Pattern, Replacement, B1).
npl_rewrite_term(ir_choice_point(Alts), Pattern, Replacement,
                 ir_choice_point(Alts1)) :- !,
    maplist(npl_rewrite_term_alt(Pattern, Replacement), Alts, Alts1).
npl_rewrite_term(Term, _, _, Term).

npl_rewrite_term_alt(Pattern, Replacement, Alt, Alt1) :-
    npl_rewrite_term(Alt, Pattern, Replacement, Alt1).

%% npl_unfold_data/2
%  Data unfolding: replace static compound terms with their unfolded form.
npl_unfold_data(ir_call(Goal), ir_call(Goal)) :- !.
npl_unfold_data(ir_seq(A, B), ir_seq(A1, B1)) :- !,
    npl_unfold_data(A, A1),
    npl_unfold_data(B, B1).
npl_unfold_data(IR, IR).

%% npl_pattern_correlate/2
%  Pattern-correlation: group and reorder clauses by head argument patterns.
npl_pattern_correlate([], []).
npl_pattern_correlate([C|Cs], [C|Sorted]) :-
    npl_pattern_correlate(Cs, Sorted).

%%====================================================================
%% Variable instantiation pass
%%====================================================================
%%
%% Converts var(Name) compound terms produced by the parser into actual
%% Prolog variables before the structural optimisation passes run.
%% All occurrences of the same var(Name) within a clause receive the
%% same fresh Prolog variable.  Each var('_') gets a fresh independent
%% anonymous variable.  This pass must run after npl_apply_rules (which
%% matches algebraic identities against var/1 ground terms safely) and
%% before npl_gaussian_reduce (which requires actual Prolog variables for
%% copy_term-based structural analysis).

%% npl_ir_instantiate_all/2
%  Apply variable instantiation to every IR clause in the list.
npl_ir_instantiate_all([], []).
npl_ir_instantiate_all([ir_clause(Head, Body, Info)|Rest],
                       [ir_clause(Head1, Body1, Info)|Rest1]) :- !,
    npl_ir_inst_clause(Head, Body, Head1, Body1),
    npl_ir_instantiate_all(Rest, Rest1).
npl_ir_instantiate_all([C|Rest], [C|Rest1]) :-
    npl_ir_instantiate_all(Rest, Rest1).

%% npl_ir_inst_clause/4
%  npl_ir_inst_clause(+Head, +Body, -Head1, -Body1)
%  Replace all var(Name) in Head and Body with a consistent set of fresh
%  Prolog variables (one per unique Name).
npl_ir_inst_clause(Head, Body, Head1, Body1) :-
    npl_ir_inst_collect(Head-Body, AllNames),
    sort(AllNames, UniqueNames),
    npl_ir_inst_build_map(UniqueNames, VarMap),
    npl_ir_inst_subst(Head, VarMap, Head1),
    npl_ir_inst_subst(Body, VarMap, Body1).

%% npl_ir_inst_collect/2
%  Collect Name atoms from all var(Name) compound terms inside Term.
npl_ir_inst_collect(var(Name), [Name]) :-
    atom(Name), !.
npl_ir_inst_collect(Term, Names) :-
    compound(Term), !,
    Term =.. [_|Args],
    maplist(npl_ir_inst_collect, Args, Lists),
    append(Lists, Names).
npl_ir_inst_collect(_, []).

%% npl_ir_inst_build_map/2
%  Build a Name-FreshVar association list.  The anonymous name '_' is
%  excluded; each var('_') creates its own fresh variable during substitution.
npl_ir_inst_build_map([], []).
npl_ir_inst_build_map(['_'|Names], Rest) :- !,
    npl_ir_inst_build_map(Names, Rest).
npl_ir_inst_build_map([Name|Names], [Name-_|Rest]) :-
    npl_ir_inst_build_map(Names, Rest).

%% npl_ir_inst_subst/3
%  npl_ir_inst_subst(+Term, +VarMap, -Term1)
%  Replace var(Name) with the corresponding Prolog variable from VarMap.
%  var('_') is replaced with a fresh anonymous variable (_).
npl_ir_inst_subst(var('_'), _, _) :- !.
npl_ir_inst_subst(var(Name), VarMap, V) :-
    atom(Name), memberchk(Name-V, VarMap), !.
npl_ir_inst_subst(Term, VarMap, Term1) :-
    compound(Term), !,
    Term =.. [F|Args],
    maplist(npl_ir_inst_subst_arg(VarMap), Args, Args1),
    Term1 =.. [F|Args1].
npl_ir_inst_subst(Term, _, Term).

npl_ir_inst_subst_arg(VarMap, Arg, Arg1) :-
    npl_ir_inst_subst(Arg, VarMap, Arg1).

%%====================================================================
%% Arithmetic inlining pass
%%====================================================================
%%
%% Inlines single-use intermediate arithmetic variables.  A goal
%%   Var is Expr
%% where Var is an actual Prolog variable that:
%%   (a) does not appear in the clause head, and
%%   (b) appears exactly once in the subsequent body goals,
%% is removed; every occurrence of Var in the remainder is replaced by Expr.
%%
%% Example:
%%   double_then_add(A,B,R) :- D is A*2, R is D+B.
%% becomes:
%%   double_then_add(A,B,R) :- R is A*2+B.

%% npl_arith_inline_pass/2
%  Apply arithmetic inlining to every IR clause in the list.
npl_arith_inline_pass([], []).
npl_arith_inline_pass([ir_clause(Head, Body, Info)|Rest],
                      [ir_clause(Head, Body1, Info)|Rest1]) :- !,
    npl_arith_inline_body(Head, Body, Body1),
    npl_arith_inline_pass(Rest, Rest1).
npl_arith_inline_pass([C|Rest], [C|Rest1]) :-
    npl_arith_inline_pass(Rest, Rest1).

%% npl_arith_inline_body/3
%  npl_arith_inline_body(+Head, +Body, -Body1)
%  Inline eligible single-use arithmetic temporaries in Body.
%  Head is passed so that variables appearing in the clause head are
%  not inlined (they are observable outputs, not private temporaries).
npl_arith_inline_body(Head,
                      ir_seq(ir_call(is(Var, Expr)), Rest),
                      Result) :-
    var(Var),                                    % only actual Prolog variables
    \+ npl_contains_var(Var, Head),              % not a head (output) variable
    \+ npl_contains_var(Var, Expr),              % no self-reference in Expr
    npl_ir_count_var(Var, Rest, 1),              % appears exactly once in rest
    !,
    npl_ir_substitute(Var, Expr, Rest, Rest1),
    npl_arith_inline_body(Head, Rest1, Result).
npl_arith_inline_body(Head, ir_seq(A, B), ir_seq(A1, B1)) :- !,
    npl_arith_inline_body(Head, A, A1),
    npl_arith_inline_body(Head, B, B1).
npl_arith_inline_body(_Head, Body, Body).

%%--------------------------------------------------------------------
%% npl_ir_count_var/3  — count occurrences of a variable in an IR tree
%%--------------------------------------------------------------------

npl_ir_count_var(Var, ir_true,  0) :- var(Var), !.
npl_ir_count_var(Var, ir_fail,  0) :- var(Var), !.
npl_ir_count_var(Var, ir_cut,   0) :- var(Var), !.
npl_ir_count_var(Var, ir_repeat,0) :- var(Var), !.
npl_ir_count_var(Var, ir_call(Goal), N) :- !,
    npl_term_count_var(Var, Goal, N).
npl_ir_count_var(Var, ir_seq(A, B), N) :- !,
    npl_ir_count_var(Var, A, NA),
    npl_ir_count_var(Var, B, NB),
    N is NA + NB.
npl_ir_count_var(Var, ir_disj(A, B), N) :- !,
    npl_ir_count_var(Var, A, NA),
    npl_ir_count_var(Var, B, NB),
    N is NA + NB.
npl_ir_count_var(Var, ir_if(C, T, E), N) :- !,
    npl_ir_count_var(Var, C, NC),
    npl_ir_count_var(Var, T, NT),
    npl_ir_count_var(Var, E, NE),
    N is NC + NT + NE.
npl_ir_count_var(Var, ir_not(G), N) :- !,
    npl_ir_count_var(Var, G, N).
npl_ir_count_var(Var, ir_source_marker(_, B), N) :- !,
    npl_ir_count_var(Var, B, N).
npl_ir_count_var(Var, ir_memo_site(_, B), N) :- !,
    npl_ir_count_var(Var, B, N).
npl_ir_count_var(Var, ir_loop_candidate(B), N) :- !,
    npl_ir_count_var(Var, B, N).
npl_ir_count_var(Var, ir_addr_loop(_, _, B), N) :- !,
    npl_ir_count_var(Var, B, N).
npl_ir_count_var(_, _, 0).

npl_term_count_var(Var, Term, 1) :- Var == Term, !.
npl_term_count_var(Var, Term, N) :-
    compound(Term), !,
    Term =.. [_|Args],
    maplist(npl_term_count_var(Var), Args, Counts),
    sumlist(Counts, N).
npl_term_count_var(_, _, 0).

%%--------------------------------------------------------------------
%% npl_ir_substitute/4  — substitute a variable in an IR tree
%%--------------------------------------------------------------------

npl_ir_substitute(Var, Repl, ir_call(Goal), ir_call(Goal1)) :- !,
    npl_term_substitute(Var, Repl, Goal, Goal1).
npl_ir_substitute(Var, Repl, ir_seq(A, B), ir_seq(A1, B1)) :- !,
    npl_ir_substitute(Var, Repl, A, A1),
    npl_ir_substitute(Var, Repl, B, B1).
npl_ir_substitute(Var, Repl, ir_disj(A, B), ir_disj(A1, B1)) :- !,
    npl_ir_substitute(Var, Repl, A, A1),
    npl_ir_substitute(Var, Repl, B, B1).
npl_ir_substitute(Var, Repl, ir_if(C, T, E), ir_if(C1, T1, E1)) :- !,
    npl_ir_substitute(Var, Repl, C, C1),
    npl_ir_substitute(Var, Repl, T, T1),
    npl_ir_substitute(Var, Repl, E, E1).
npl_ir_substitute(Var, Repl, ir_not(G), ir_not(G1)) :- !,
    npl_ir_substitute(Var, Repl, G, G1).
npl_ir_substitute(Var, Repl, ir_source_marker(Pos, B),
                             ir_source_marker(Pos, B1)) :- !,
    npl_ir_substitute(Var, Repl, B, B1).
npl_ir_substitute(Var, Repl, ir_memo_site(H, B), ir_memo_site(H, B1)) :- !,
    npl_ir_substitute(Var, Repl, B, B1).
npl_ir_substitute(Var, Repl, ir_loop_candidate(B),
                             ir_loop_candidate(B1)) :- !,
    npl_ir_substitute(Var, Repl, B, B1).
npl_ir_substitute(Var, Repl, ir_addr_loop(TV, Sig, B),
                             ir_addr_loop(TV, Sig, B1)) :- !,
    npl_ir_substitute(Var, Repl, B, B1).
npl_ir_substitute(_, _, IR, IR).

npl_term_substitute(Var, Repl, Term, Repl) :- Var == Term, !.
npl_term_substitute(Var, Repl, Term, Term1) :-
    compound(Term), !,
    Term =.. [F|Args],
    maplist(npl_term_substitute(Var, Repl), Args, Args1),
    Term1 =.. [F|Args1].
npl_term_substitute(_, _, Term, Term).

%%--------------------------------------------------------------------
%% npl_contains_var/2  — check whether a term contains a specific variable
%%--------------------------------------------------------------------

npl_contains_var(Var, Term) :- Var == Term, !.
npl_contains_var(Var, Term) :-
    compound(Term),
    Term =.. [_|Args],
    member(Arg, Args),
    npl_contains_var(Var, Arg).
