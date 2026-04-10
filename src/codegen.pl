% codegen.pl — NeuroProlog Code Generator
%
% Translates optimised IR into neurocode (valid Prolog).
% Neurocode is inspectable, editable, and diffable in Git.

:- module(codegen, [npl_generate/2, npl_ir_to_body/2]).

%% npl_generate/2
%  npl_generate(+OptIR, -Neurocode)
%  Convert optimised IR to a list of Prolog clause terms (neurocode).
npl_generate(IR, Neurocode) :-
    maplist(npl_ir_to_clause, IR, Neurocode).

%% npl_ir_to_clause/2
npl_ir_to_clause(ir_clause(Head, ir_true, _), Head) :- !.
npl_ir_to_clause(ir_clause(Head, IRBody, _), (Head :- Body)) :-
    npl_ir_to_body(IRBody, Body).

%% npl_ir_to_body/2
npl_ir_to_body(ir_true, true) :- !.
npl_ir_to_body(ir_fail, fail) :- !.
npl_ir_to_body(ir_cut, !) :- !.
npl_ir_to_body(ir_repeat, repeat) :- !.
npl_ir_to_body(ir_not(G), \+ Body) :- !,
    npl_ir_to_body(G, Body).
npl_ir_to_body(ir_call(Goal), Goal) :- !.
npl_ir_to_body(ir_seq(A, B), (BodyA, BodyB)) :- !,
    npl_ir_to_body(A, BodyA),
    npl_ir_to_body(B, BodyB).
npl_ir_to_body(ir_disj(A, B), (BodyA ; BodyB)) :- !,
    npl_ir_to_body(A, BodyA),
    npl_ir_to_body(B, BodyB).
npl_ir_to_body(ir_if(Cond, Then, ir_fail), (CondB -> ThenB)) :- !,
    npl_ir_to_body(Cond, CondB),
    npl_ir_to_body(Then, ThenB).
npl_ir_to_body(ir_if(Cond, Then, Else), (CondB -> ThenB ; ElseB)) :-
    npl_ir_to_body(Cond, CondB),
    npl_ir_to_body(Then, ThenB),
    npl_ir_to_body(Else, ElseB).
