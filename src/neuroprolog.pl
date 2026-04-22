% neuroprolog.pl — NeuroProlog main entry point
%
% Loads all modules and provides the top-level interpreter loop.
%
% Usage:
%   swipl -g "consult('src/neuroprolog')" -g "npl_main" -t halt

:- module(neuroprolog, [npl_main/0, npl_compile/2, npl_interpret/1,
                         npl_compile_with_pipeline/3,
                         npl_compile_safe/2,
                         npl_write_neurocode/2, npl_write_neurocode/3,
                         npl_ir_to_source/2,
                         npl_ir_to_source/3,
                         npl_ir_to_source_text/2,
                         npl_ir_to_source_text/3,
                         npl_ir_to_source_file/2,
                         npl_ir_to_source_file/3,
                         npl_ir_to_clause_public/2,
                         npl_ir_to_body_public/2,
                         npl_source_to_ir/2,
                         npl_source_to_optimised_ir/2,
                         npl_roundtrip_source/2,
                         npl_roundtrip_source_text/2,
                         npl_roundtrip_source_file/2,
                         npl_code_generate/2]).

:- use_module(library(lists)).

:- consult('./prelude').
:- consult('./control').
:- consult('./wam_model').
:- consult('./lexer').
:- consult('./parser').
:- consult('./semantic_analyser').
:- consult('./intermediate_codegen').
:- consult('./optimiser').
:- consult('./optimiser_pipeline').
:- consult('./codegen').
:- consult('./cognitive_markers').
:- consult('./memoisation').
:- consult('./gaussian_recursion').
:- consult('./subterm_addressing').
:- consult('./optimisation_dictionary').
:- consult('./interpreter').

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
    npl_write_neurocode(OptIR, SourceFile, OutputFile).

%% npl_compile_with_pipeline/3
%  Compile a Prolog source file using a custom pipeline configuration.
%  npl_compile_with_pipeline(+SourceFile, +OutputFile, +PipelineConfig)
%  PipelineConfig is a list of pass(Name, Enabled) terms as produced by
%  npl_pipeline_default_config/1 and npl_pipeline_disable/3.
npl_compile_with_pipeline(SourceFile, OutputFile, PipelineConfig) :-
    npl_lex(SourceFile, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_pipeline_run(PipelineConfig, IR, OptIR, _Report),
    npl_write_neurocode(OptIR, SourceFile, OutputFile).

%% npl_compile_safe/2
%  Compile a Prolog source file using only conservative (non-experimental)
%  pipeline passes.  Experimental passes disabled:
%    gaussian_elimination, recursion_to_loop,
%    subterm_address_conversion, nested_recursion_elimination.
%  npl_compile_safe(+SourceFile, +OutputFile)
npl_compile_safe(SourceFile, OutputFile) :-
    npl_pipeline_default_config(Cfg0),
    npl_safe_pipeline_config(Cfg0, SafeCfg),
    npl_compile_with_pipeline(SourceFile, OutputFile, SafeCfg).

%% npl_safe_pipeline_config/2
%  Build a conservative pipeline config from a base config.
npl_safe_pipeline_config(Cfg0, SafeCfg) :-
    npl_pipeline_disable(gaussian_elimination,       Cfg0,  Cfg1),
    npl_pipeline_disable(recursion_to_loop,          Cfg1,  Cfg2),
    npl_pipeline_disable(subterm_address_conversion, Cfg2,  Cfg3),
    npl_pipeline_disable(nested_recursion_elimination, Cfg3, SafeCfg).

%% npl_interpret/1
%  Load and interpret a Prolog source file.
npl_interpret(File) :-
    npl_lex(File, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_run(AAST).

%% npl_write_neurocode/3
%  Write neurocode to an output file, annotated with the original source path.
%  Uses portray_clause/2 for human-readable, operator-aware output.
%  npl_write_neurocode(+OptIR, +SrcFile, +OutputFile)
npl_write_neurocode(OptIR, SrcFile, OutputFile) :-
    npl_generate_full(OptIR, SrcFile, Segments),
    open(OutputFile, write, Stream),
    format(atom(Header), 'NeuroProlog neurocode — source: ~w', [SrcFile]),
    npl_write_neurocode_full(Stream, Segments, Header),
    close(Stream).

%% npl_write_neurocode/2 — legacy two-argument form (output file is used as source label).
%  npl_write_neurocode(+OptIR, +File)
npl_write_neurocode(OptIR, File) :-
    npl_write_neurocode(OptIR, File, File).
