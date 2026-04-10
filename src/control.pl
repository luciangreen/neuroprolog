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
    npl_plus/3
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
