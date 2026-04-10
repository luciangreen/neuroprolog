% rebuild.pl — NeuroProlog Self-Rebuild Orchestration
%
% Provides the rebuild_neuroprolog/0 predicate that recompiles
% NeuroProlog from its own source using the current interpreter,
% preserving all learned optimisations.

:- module(rebuild, [rebuild_neuroprolog/0, verify_rebuild/0]).

:- consult('src/neuroprolog').

%% rebuild_neuroprolog/0
%  Rebuild NeuroProlog from source, preserving optimisations.
rebuild_neuroprolog :-
    write('[rebuild] Loading optimisation dictionary...'), nl,
    npl_opt_dict_rules(Rules),
    write('[rebuild] Rules: '), write(Rules), nl,
    write('[rebuild] Compiling src/neuroprolog.pl to neurocode...'), nl,
    npl_compile('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
    write('[rebuild] Verifying output...'), nl,
    verify_rebuild,
    write('[rebuild] Rebuild complete.'), nl.

%% verify_rebuild/0
%  Verify that the rebuilt neurocode passes basic consistency checks.
verify_rebuild :-
    ( exists_file('neurocode/neuroprolog_nc.pl') ->
        write('[verify] neurocode/neuroprolog_nc.pl exists.'), nl
    ; write('[verify] ERROR: neurocode output missing!'), nl, fail
    ).
