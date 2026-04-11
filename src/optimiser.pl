% optimiser.pl — NeuroProlog Optimiser
%
% Applies transformations to the IR to produce optimised IR.
% Delegates to sub-modules for specific optimisation strategies.

:- module(optimiser, [npl_optimise/2]).

:- use_module(library(lists)).

:- use_module('src/gaussian_recursion').
:- use_module('src/memoisation').
:- use_module('src/subterm_addressing').
:- use_module('src/optimisation_dictionary').
:- use_module('src/nested_recursion').

%% npl_optimise/2
%  npl_optimise(+IR, -OptIR)
npl_optimise(IR, OptIR) :-
    npl_apply_optimisations(IR, OptIR).

%% npl_apply_optimisations/2
%  Apply all registered optimisations in sequence.
npl_apply_optimisations(IR, OptIR) :-
    npl_opt_dict_rules(Rules),
    npl_apply_rules(Rules, IR, IR1),
    npl_gaussian_reduce(IR1, IR2),
    npl_nested_eliminate_pass(IR2, IR3),
    npl_memoisation_pass(IR3, IR4),
    npl_subterm_address_pass(IR4, OptIR).

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
