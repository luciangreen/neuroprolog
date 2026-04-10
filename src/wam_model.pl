% wam_model.pl — NeuroProlog WAM Model
%
% Models the Warren Abstract Machine (WAM) instruction set.
% Used as the execution substrate for compiled neurocode.

:- module(wam_model, [
    wam_execute/2,
    wam_compile_clause/2,
    wam_instruction/3
]).

:- use_module(library(lists)).

%% wam_compile_clause/2
%  Compile a Prolog clause to WAM instructions.
%  wam_compile_clause(+Clause, -Instructions)
wam_compile_clause(Head, [get_constant(F/A)]) :-
    \+ compound(Head), !,
    functor(Head, F, A).
wam_compile_clause(Head, [get_constant(F/A)]) :-
    compound(Head),
    Head \= (_:-_), !,
    functor(Head, F, A).
wam_compile_clause((Head :- Body), Instructions) :-
    functor(Head, F, A),
    Head =.. [_|Args],
    maplist(wam_get_arg, Args, GetArgs),
    wam_compile_body(Body, BodyInstr),
    append([enter(F/A)|GetArgs], [proceed|BodyInstr], Instructions).

wam_get_arg(Arg, get_variable(Arg)) :- var(Arg), !.
wam_get_arg(Arg, get_constant(Arg)) :- atomic(Arg), !.
wam_get_arg(Arg, get_structure(F/A)) :- compound(Arg), functor(Arg, F, A).

wam_compile_body(true, []) :- !.
wam_compile_body(','(A, B), Instr) :- !,
    wam_compile_body(A, IA),
    wam_compile_body(B, IB),
    append(IA, IB, Instr).
wam_compile_body(Goal, [call(Goal)]) :- callable(Goal).

%% wam_execute/2
%  Execute WAM instructions against a state.
%  wam_execute(+Instructions, +State)
wam_execute([], _).
wam_execute([I|Is], State) :-
    wam_instruction(I, State, State1),
    wam_execute(Is, State1).

%% wam_instruction/3
%  Semantics of individual WAM instructions.
wam_instruction(enter(_FA), S, S).
wam_instruction(proceed, S, S).
wam_instruction(get_constant(C), S, S) :- ground(C).
wam_instruction(get_variable(_), S, S).
wam_instruction(get_structure(_FA), S, S).
wam_instruction(call(Goal), S, S) :- call(Goal).
wam_instruction(put_constant(_C, _Reg), S, S).
wam_instruction(put_variable(_V, _Reg), S, S).
wam_instruction(unify_variable(_V), S, S).
wam_instruction(unify_constant(C), S, S) :- ground(C).
