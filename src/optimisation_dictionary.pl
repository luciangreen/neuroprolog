% optimisation_dictionary.pl — NeuroProlog Optimisation Dictionary
%
% Stores named, versioned algorithm transformations.
% Each entry maps a recognised algorithmic pattern to a known
% efficient implementation.
%
% Format: npl_opt_rule(Name, Pattern, Replacement).

:- module(optimisation_dictionary, [
    npl_opt_rule/3,
    npl_opt_dict_rules/1,
    npl_opt_register/3,
    npl_opt_lookup/2
]).

:- dynamic npl_opt_rule/3.

%% Builtin optimisation rules

%% identity: call(true) → ir_true
npl_opt_rule(identity,
    ir_call(true),
    ir_true).

%% fail_branch: a disjunct that always fails can be removed
npl_opt_rule(fail_branch,
    ir_disj(ir_fail, B),
    B).

npl_opt_rule(fail_branch_right,
    ir_disj(A, ir_fail),
    A).

%% seq_true: sequencing with true is identity
npl_opt_rule(seq_true_left,
    ir_seq(ir_true, B),
    B).

npl_opt_rule(seq_true_right,
    ir_seq(A, ir_true),
    A).

%% if_true_cond: if true -> Then ; Else reduces to Then
npl_opt_rule(if_true,
    ir_if(ir_true, Then, _),
    Then).

%% if_fail_cond: if fail -> Then ; Else reduces to Else
npl_opt_rule(if_fail,
    ir_if(ir_fail, _, Else),
    Else).

%% npl_opt_dict_rules/1
%  Return list of all registered rule names.
npl_opt_dict_rules(Rules) :-
    findall(Name, npl_opt_rule(Name, _, _), Rules).

%% npl_opt_register/3
%  Register a new optimisation rule.
npl_opt_register(Name, Pattern, Replacement) :-
    ( npl_opt_rule(Name, _, _) ->
        retract(npl_opt_rule(Name, _, _)),
        assertz(npl_opt_rule(Name, Pattern, Replacement))
    ; assertz(npl_opt_rule(Name, Pattern, Replacement))
    ).

%% npl_opt_lookup/2
%  Look up the optimisation registered under Name.
npl_opt_lookup(Name, opt(Name, Pattern, Replacement)) :-
    npl_opt_rule(Name, Pattern, Replacement).
