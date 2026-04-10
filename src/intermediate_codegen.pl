% intermediate_codegen.pl — NeuroProlog Intermediate Code Generator
%
% Translates the annotated AST into an Intermediate Representation (IR).
% IR is a list of ir_clause/3 terms: ir_clause(Head, Body, Annotations).

:- module(intermediate_codegen, [npl_intermediate/2, npl_body_to_ir/2]).

:- use_module(library(lists)).

%% npl_intermediate/2
%  npl_intermediate(+AAST, -IR)
npl_intermediate(AAST, IR) :-
    maplist(npl_clause_to_ir, AAST, IR).

%% npl_clause_to_ir/2
npl_clause_to_ir(analysed(Head, Body, Info),
                 ir_clause(Head, IRBody, Info)) :-
    npl_body_to_ir(Body, IRBody).
npl_clause_to_ir(clause(Head, Body),
                 ir_clause(Head, IRBody, info(head:ok, body:ok))) :-
    npl_body_to_ir(Body, IRBody).

%% npl_body_to_ir/2
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
