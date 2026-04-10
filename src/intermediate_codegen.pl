% intermediate_codegen.pl — NeuroProlog Intermediate Code Generator
%
% Translates the annotated AST into an Intermediate Representation (IR).
% IR is a list of ir_clause/3 terms: ir_clause(Head, Body, Annotations).
%
% Directives, queries, and parse errors (pass-through nodes from the semantic
% analyser) are skipped; only analysed/3 and legacy clause/2 nodes are compiled.

:- module(intermediate_codegen, [npl_intermediate/2, npl_body_to_ir/2]).

:- use_module(library(lists)).

%% npl_intermediate/2
%  npl_intermediate(+AAST, -IR)
npl_intermediate(AAST, IR) :-
    npl_filter_compilable(AAST, Compilable),
    maplist(npl_clause_to_ir, Compilable, IR).

%% npl_filter_compilable(+Nodes, -Compilable)
%% Keep only nodes that map to IR clauses (analysed/3 and legacy clause/2).
npl_filter_compilable([], []).
npl_filter_compilable([H|T], [H|Rest]) :-
    npl_is_compilable_node(H), !,
    npl_filter_compilable(T, Rest).
npl_filter_compilable([_|T], Rest) :-
    npl_filter_compilable(T, Rest).

%% npl_is_compilable_node/1
%% Succeeds for nodes that should be compiled into IR clauses.
npl_is_compilable_node(analysed(_, _, _)).
npl_is_compilable_node(clause(_, _)).

%% npl_clause_to_ir/2
npl_clause_to_ir(analysed(Head, Body, Info),
                 ir_clause(Head, IRBody, Info)) :-
    npl_body_to_ir(Body, IRBody).
npl_clause_to_ir(clause(Head, Body),
                 ir_clause(Head, IRBody, info(head:ok, body:ok))) :-
    npl_body_to_ir(Body, IRBody).

%% npl_body_to_ir/2
%% NOTE: The if-then-else clause (';'('->'(...), ...)) MUST appear before
%% the general disjunction clause (';'(A, B)) so that (Cond -> Then ; Else)
%% is correctly recognised as ir_if rather than ir_disj.
npl_body_to_ir(true, ir_true) :- !.
npl_body_to_ir(fail, ir_fail) :- !.
npl_body_to_ir(repeat, ir_repeat) :- !.
npl_body_to_ir(\+(Goal), ir_not(IRGoal)) :- !,
    npl_body_to_ir(Goal, IRGoal).
npl_body_to_ir(','(A, B), ir_seq(IRA, IRB)) :- !,
    npl_body_to_ir(A, IRA),
    npl_body_to_ir(B, IRB).
npl_body_to_ir(';'('->'(Cond, Then), Else), ir_if(IRCond, IRThen, IRElse)) :- !,
    npl_body_to_ir(Cond, IRCond),
    npl_body_to_ir(Then, IRThen),
    npl_body_to_ir(Else, IRElse).
npl_body_to_ir(';'(A, B), ir_disj(IRA, IRB)) :- !,
    npl_body_to_ir(A, IRA),
    npl_body_to_ir(B, IRB).
npl_body_to_ir('->'(Cond, Then), ir_if(IRCond, IRThen, ir_fail)) :- !,
    npl_body_to_ir(Cond, IRCond),
    npl_body_to_ir(Then, IRThen).
npl_body_to_ir(!, ir_cut) :- !.
npl_body_to_ir(Goal, ir_call(Goal)).
