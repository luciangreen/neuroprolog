% memoisation.pl — NeuroProlog Logical Memoisation
%
% Provides assert-based and tabling-based memoisation of recurring
% logical patterns to avoid redundant recomputation.

:- module(memoisation, [
    npl_memo/1,
    npl_memo_call/1,
    npl_memo_clear/1,
    npl_memoisation_pass/2
]).

:- dynamic npl_memo_cache/2.
:- dynamic npl_is_memoised/1.

%% npl_memo/1
%  Declare a predicate as memoised.
%  npl_memo(+Functor/Arity)
npl_memo(F/A) :-
    assertz(npl_is_memoised(F/A)).

%% npl_memo_call/1
%  Call a goal, caching the result on first call.
npl_memo_call(Goal) :-
    ( npl_memo_cache(Goal, true) ->
        true
    ;   call(Goal),
        assertz(npl_memo_cache(Goal, true))
    ).

%% npl_memo_clear/1
%  Clear memoisation cache for a given functor/arity.
npl_memo_clear(F/A) :-
    functor(Head, F, A),
    retractall(npl_memo_cache(Head, _)).

%% npl_memoisation_pass/2
%  Apply memoisation annotations to IR.
npl_memoisation_pass(IR, OptIR) :-
    maplist(npl_memo_annotate, IR, OptIR).

npl_memo_annotate(ir_clause(Head, Body, Info), ir_clause(Head, Body, Info1)) :-
    ( callable(Head), Head =.. [F|Args], length(Args, A),
      npl_is_memoised(F/A) ->
        Info1 = memoised(Info)
    ; Info1 = Info
    ).
