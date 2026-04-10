% control.pl — NeuroProlog Logical Control Structures
%
% Implements standard Prolog control predicates in the NeuroProlog context.

:- module(control, [
    npl_if/3,
    npl_if/2,
    npl_or/2,
    npl_not/1,
    npl_once/1,
    npl_ignore/1,
    npl_forall/2,
    npl_between/3,
    npl_succ/2,
    npl_plus/3,
    npl_true/0,
    npl_fail/0,
    npl_repeat/0,
    npl_conj/2,
    npl_call/2,
    npl_call/3,
    npl_call/4,
    npl_call/5,
    npl_call/6
]).

%% npl_if/3  — if-then-else
npl_if(Cond, Then, _Else) :- call(Cond), !, call(Then).
npl_if(_, _, Else) :- call(Else).

%% npl_if/2  — if-then (soft cut)
npl_if(Cond, Then) :- call(Cond), !, call(Then).
npl_if(_, _).

%% npl_or/2  — disjunction
npl_or(A, _) :- call(A).
npl_or(_, B) :- call(B).

%% npl_not/1  — negation as failure
npl_not(Goal) :- \+ call(Goal).

%% npl_once/1  — succeed at most once
npl_once(Goal) :- call(Goal), !.

%% npl_ignore/1  — always succeed
npl_ignore(Goal) :- call(Goal), !.
npl_ignore(_).

%% npl_forall/2  — true if Action succeeds for all solutions of Cond
npl_forall(Cond, Action) :- \+ (call(Cond), \+ call(Action)).

%% npl_between/3  — integer range
npl_between(Low, High, Low) :- Low =< High.
npl_between(Low, High, X) :-
    Low < High,
    Low1 is Low + 1,
    npl_between(Low1, High, X).

%% npl_succ/2
npl_succ(X, Y) :- ( var(Y) -> Y is X + 1 ; X is Y - 1 ).

%% npl_plus/3
npl_plus(X, Y, Z) :-
    ( ground(X), ground(Y) -> Z is X + Y
    ; ground(X), ground(Z) -> Y is Z - X
    ; ground(Y), ground(Z) -> X is Z - Y
    ).

%% npl_true/0
npl_true.

%% npl_fail/0
npl_fail :- fail.

%% npl_repeat/0  — nondeterministic: succeeds arbitrarily many times
npl_repeat.
npl_repeat :- npl_repeat.

%% npl_conj/2  — conjunction as a predicate
npl_conj(A, B) :- call(A), call(B).

%% npl_call/2-6  — higher-order call with extra arguments
npl_call(Goal, A) :- call(Goal, A).
npl_call(Goal, A, B) :- call(Goal, A, B).
npl_call(Goal, A, B, C) :- call(Goal, A, B, C).
npl_call(Goal, A, B, C, D) :- call(Goal, A, B, C, D).
npl_call(Goal, A, B, C, D, E) :- call(Goal, A, B, C, D, E).
