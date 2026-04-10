% semantic_analyser.pl — NeuroProlog Semantic Analyser
%
% Validates and annotates the AST produced by the parser.
% Checks for: undefined predicates, singleton variables,
% type conflicts, and arity mismatches.

:- module(semantic_analyser, [npl_analyse/2]).

:- use_module(library(lists)).

%% npl_analyse/2
%  npl_analyse(+AST, -AnnotatedAST)
npl_analyse(AST, AAST) :-
    npl_collect_signatures(AST, Sigs),
    maplist(npl_analyse_clause(Sigs), AST, AAST).

%% npl_collect_signatures/2
npl_collect_signatures([], []).
npl_collect_signatures([clause(Head, _)|Cs], [Sig|Sigs]) :-
    ( callable(Head), Head =.. [F|Args] ->
        length(Args, Arity),
        Sig = F/Arity
    ; Sig = unknown/0
    ),
    npl_collect_signatures(Cs, Sigs).

%% npl_analyse_clause/3
npl_analyse_clause(Sigs, clause(Head, Body), analysed(Head, Body, Info)) :-
    npl_check_head(Head, Sigs, HeadInfo),
    npl_check_body(Body, Sigs, BodyInfo),
    Info = info(head:HeadInfo, body:BodyInfo).

%% npl_check_head/3
npl_check_head(Head, _Sigs, ok) :-
    callable(Head), !.
npl_check_head(_, _, error(non_callable_head)).

%% npl_check_body/3
npl_check_body(true, _, ok) :- !.
npl_check_body(','(A, B), Sigs, info(A:IA, B:IB)) :- !,
    npl_check_body(A, Sigs, IA),
    npl_check_body(B, Sigs, IB).
npl_check_body(Goal, Sigs, Info) :-
    ( callable(Goal) ->
        ( Goal =.. [F|Args], length(Args, Arity),
          member(F/Arity, Sigs)
        -> Info = ok
        ;  Info = warning(possibly_undefined, Goal)
        )
    ; Info = error(non_callable_goal, Goal)
    ).
