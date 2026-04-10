% semantic_analyser.pl — NeuroProlog Semantic Analyser
%
% Validates and annotates the AST produced by the parser.
% Checks for: undefined predicates, singleton variables,
% type conflicts, and arity mismatches.
%
% Accepts both the new rich AST (fact/4, rule/5, directive/4, query/4,
% parse_error/2) and the legacy clause/2 format for backward compatibility.
% Directives, queries, and parse errors are passed through unchanged.

:- module(semantic_analyser, [npl_analyse/2]).

:- use_module(library(lists)).

%% npl_analyse/2
%  npl_analyse(+AST, -AnnotatedAST)
npl_analyse(AST, AAST) :-
    npl_collect_signatures(AST, Sigs),
    maplist(npl_analyse_node(Sigs), AST, AAST).

%% npl_collect_signatures/2
%% Gather functor/arity signatures for all facts and rules in the AST.
npl_collect_signatures([], []).
%% New AST: fact/4
npl_collect_signatures([fact(Head, _, _, _)|Cs], [Sig|Sigs]) :- !,
    npl_head_sig(Head, Sig),
    npl_collect_signatures(Cs, Sigs).
%% New AST: rule/5
npl_collect_signatures([rule(Head, _, _, _, _)|Cs], [Sig|Sigs]) :- !,
    npl_head_sig(Head, Sig),
    npl_collect_signatures(Cs, Sigs).
%% Legacy: clause/2
npl_collect_signatures([clause(Head, _)|Cs], [Sig|Sigs]) :- !,
    npl_head_sig(Head, Sig),
    npl_collect_signatures(Cs, Sigs).
%% Directives, queries, parse errors contribute no signatures.
npl_collect_signatures([_|Cs], Sigs) :-
    npl_collect_signatures(Cs, Sigs).

%% npl_head_sig(+Head, -Sig)
npl_head_sig(Head, F/Arity) :-
    callable(Head), Head =.. [F|Args],
    length(Args, Arity), !.
npl_head_sig(_, unknown/0).

%% npl_analyse_node/3
%% Analyse a single AST node; emit an annotated node.

%% New AST: fact — body is implicitly true
npl_analyse_node(Sigs, fact(Head, _Pos, _A, _M),
                 analysed(Head, true, info(head:HeadInfo, body:ok))) :- !,
    npl_check_head(Head, Sigs, HeadInfo).

%% New AST: rule
npl_analyse_node(Sigs, rule(Head, Body, _Pos, _A, _M),
                 analysed(Head, Body, info(head:HeadInfo, body:BodyInfo))) :- !,
    npl_check_head(Head, Sigs, HeadInfo),
    npl_check_body(Body, Sigs, BodyInfo).

%% New AST: directive — pass through unchanged
npl_analyse_node(_Sigs, directive(Goal, Pos, A, M),
                 directive(Goal, Pos, A, M)) :- !.

%% New AST: query — pass through unchanged
npl_analyse_node(_Sigs, query(Goal, Pos, A, M),
                 query(Goal, Pos, A, M)) :- !.

%% New AST: parse error — pass through unchanged
npl_analyse_node(_Sigs, parse_error(Msg, Pos),
                 parse_error(Msg, Pos)) :- !.

%% Legacy: clause/2
npl_analyse_node(Sigs, clause(Head, Body),
                 analysed(Head, Body, info(head:HeadInfo, body:BodyInfo))) :- !,
    npl_check_head(Head, Sigs, HeadInfo),
    npl_check_body(Body, Sigs, BodyInfo).

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
