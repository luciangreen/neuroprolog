% neuroprolog.pl — NeuroProlog main entry point
%
% Loads all modules and provides the top-level interpreter loop.
%
% Usage:
%   swipl -g "consult('src/neuroprolog')" -g "npl_main" -t halt

:- module(neuroprolog, [npl_main/0, npl_compile/2, npl_interpret/1]).

:- use_module(library(lists)).

:- consult('src/prelude').
:- consult('src/control').
:- consult('src/wam_model').
:- consult('src/lexer').
:- consult('src/parser').
:- consult('src/semantic_analyser').
:- consult('src/intermediate_codegen').
:- consult('src/optimiser').
:- consult('src/codegen').
:- consult('src/memoisation').
:- consult('src/gaussian_recursion').
:- consult('src/subterm_addressing').
:- consult('src/optimisation_dictionary').

%% npl_main/0
%  Start the NeuroProlog interactive interpreter.
npl_main :-
    write('NeuroProlog — self-hosting Prolog interpreter'), nl,
    write('Type :- halt. to exit.'), nl,
    npl_repl.

%% npl_repl/0
%  Read-Eval-Print loop.
npl_repl :-
    write('?- '),
    flush_output,
    catch(
        read(Goal),
        _,
        ( write('Syntax error'), nl, npl_repl )
    ),
    ( Goal == end_of_file -> true
    ; Goal = (:- halt) -> true
    ; npl_eval(Goal),
      npl_repl
    ).

%% npl_eval/1
%  Evaluate a goal in the NeuroProlog context.
npl_eval(Goal) :-
    ( catch(call(Goal), Error, (write('ERROR: '), write(Error), nl, fail))
    -> write('true'), nl
    ;  write('false'), nl
    ).

%% npl_compile/2
%  Compile a Prolog source file to neurocode.
%  npl_compile(+SourceFile, +OutputFile)
npl_compile(SourceFile, OutputFile) :-
    npl_lex(SourceFile, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_optimise(IR, OptIR),
    npl_generate(OptIR, Neurocode),
    npl_write_neurocode(Neurocode, OutputFile).

%% npl_interpret/1
%  Load and interpret a Prolog source file.
npl_interpret(File) :-
    npl_lex(File, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_run(AAST).

%% npl_write_neurocode/2
%  Write neurocode terms to a file.
npl_write_neurocode(Terms, File) :-
    open(File, write, Stream),
    write(Stream, '% NeuroProlog generated neurocode'), nl(Stream),
    write(Stream, '% This file is valid Prolog — do not add binary representations.'), nl(Stream),
    nl(Stream),
    maplist(npl_write_term(Stream), Terms),
    close(Stream).

npl_write_term(Stream, Term) :-
    write_canonical(Stream, Term),
    write(Stream, '.'), nl(Stream).
