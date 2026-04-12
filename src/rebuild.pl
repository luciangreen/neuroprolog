% rebuild.pl — NeuroProlog Self-Rebuild Orchestration
%
% Provides four rebuild modes for recompiling NeuroProlog from its own
% source using the current interpreter:
%
%   rebuild_clean/0              — clean rebuild from plain Prolog source
%   rebuild_with_dict/1          — rebuild loading a prior optimisation dictionary
%   rebuild_with_merged/1        — rebuild merging in newly learned optimisations
%   rebuild_safe_fallback/0      — rebuild disabling experimental transforms
%
% rebuild_neuroprolog/0 is retained as an alias for rebuild_clean/0.

:- module(rebuild, [
    rebuild_neuroprolog/0,
    rebuild_clean/0,
    rebuild_with_dict/1,
    rebuild_with_merged/1,
    rebuild_safe_fallback/0,
    verify_rebuild/0
]).

:- use_module(library(lists)).
:- consult('./neuroprolog').

%%====================================================================
%% Mode 1: Clean rebuild from plain Prolog source
%%====================================================================

%% rebuild_neuroprolog/0
%  Alias for rebuild_clean/0 — retained for backward compatibility.
rebuild_neuroprolog :-
    rebuild_clean.

%% rebuild_clean/0
%  Rebuild NeuroProlog from source without loading any external
%  dictionary.  Uses only the optimisation rules compiled into the
%  current image.
rebuild_clean :-
    write('[rebuild:clean] Compiling src/neuroprolog.pl to neurocode...'), nl,
    npl_opt_dict_rules(Rules),
    length(Rules, NR),
    format('[rebuild:clean] Active optimisation rules: ~w~n', [NR]),
    npl_compile('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
    write('[rebuild:clean] Verifying output...'), nl,
    verify_rebuild,
    write('[rebuild:clean] Clean rebuild complete.'), nl.

%%====================================================================
%% Mode 2: Rebuild using a prior optimisation dictionary
%%====================================================================

%% rebuild_with_dict/1
%  rebuild_with_dict(+DictFile)
%  Load the named dictionary snapshot file (as produced by
%  npl_opt_dict_save/1) and rebuild.  Rules in DictFile are merged
%  into the running image; existing rules with the same name are
%  replaced.
rebuild_with_dict(DictFile) :-
    ( exists_file(DictFile) ->
        format('[rebuild:with-dict] Loading dictionary: ~w~n', [DictFile]),
        npl_opt_dict_load(DictFile),
        npl_opt_dict_rules(Rules),
        length(Rules, NR),
        format('[rebuild:with-dict] Active optimisation rules after load: ~w~n', [NR]),
        write('[rebuild:with-dict] Compiling src/neuroprolog.pl to neurocode...'), nl,
        npl_compile('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
        write('[rebuild:with-dict] Verifying output...'), nl,
        verify_rebuild,
        write('[rebuild:with-dict] Rebuild with dictionary complete.'), nl
    ;
        format('[rebuild:with-dict] ERROR: dictionary file not found: ~w~n', [DictFile]),
        fail
    ).

%%====================================================================
%% Mode 3: Rebuild with newly learned optimisations merged in
%%====================================================================

%% rebuild_with_merged/1
%  rebuild_with_merged(+NewOptsFile)
%  Load a file of newly learned optimisation entries (npl_opt_entry/2
%  and/or npl_opt_rule/3 terms) and merge them with the currently
%  active dictionary before rebuilding.  Existing entries/rules are
%  preserved; newly learned ones are added or updated.
rebuild_with_merged(NewOptsFile) :-
    ( exists_file(NewOptsFile) ->
        npl_opt_dict_rules(RulesBefore),
        length(RulesBefore, NB),
        format('[rebuild:merged] Merging new optimisations from: ~w~n', [NewOptsFile]),
        npl_opt_dict_load(NewOptsFile),
        npl_opt_dict_rules(RulesAfter),
        length(RulesAfter, NA),
        format('[rebuild:merged] Rules before merge: ~w  after: ~w~n', [NB, NA]),
        write('[rebuild:merged] Compiling src/neuroprolog.pl to neurocode...'), nl,
        npl_compile('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
        write('[rebuild:merged] Verifying output...'), nl,
        verify_rebuild,
        write('[rebuild:merged] Rebuild with merged optimisations complete.'), nl
    ;
        format('[rebuild:merged] ERROR: new-optimisations file not found: ~w~n', [NewOptsFile]),
        fail
    ).

%%====================================================================
%% Mode 4: Safe fallback rebuild without experimental transforms
%%====================================================================

%% rebuild_safe_fallback/0
%  Rebuild using only the conservative baseline passes — dictionary
%  simplification and algebraic rules — while disabling the
%  experimental algorithmic transforms:
%    gaussian_elimination, recursion_to_loop,
%    subterm_address_conversion, nested_recursion_elimination.
%  The output is always correct but may be less optimised.
rebuild_safe_fallback :-
    write('[rebuild:safe] Starting safe-fallback rebuild...'), nl,
    write('[rebuild:safe] Experimental transforms: DISABLED'), nl,
    npl_compile_safe('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
    write('[rebuild:safe] Verifying output...'), nl,
    verify_rebuild,
    write('[rebuild:safe] Safe-fallback rebuild complete.'), nl.

%%====================================================================
%% Verify helper
%%====================================================================

%% verify_rebuild/0
%  Verify that the rebuilt neurocode passes basic consistency checks.
verify_rebuild :-
    ( exists_file('neurocode/neuroprolog_nc.pl') ->
        write('[verify] neurocode/neuroprolog_nc.pl exists.'), nl,
        rebuild_verify_plain_source,
        rebuild_verify_dict_non_empty
    ; write('[verify] ERROR: neurocode output missing!'), nl, fail
    ).

%% rebuild_verify_plain_source/0
rebuild_verify_plain_source :-
    ( exists_file('src/neuroprolog.pl') ->
        write('[verify] Plain source src/neuroprolog.pl present: OK'), nl
    ;
        write('[verify] WARNING: src/neuroprolog.pl missing'), nl
    ).

%% rebuild_verify_dict_non_empty/0
rebuild_verify_dict_non_empty :-
    npl_opt_dict_rules(Rules),
    ( Rules \= [] ->
        length(Rules, N),
        format('[verify] Optimisation dictionary: ~w rules present: OK~n', [N])
    ;
        write('[verify] WARNING: optimisation dictionary is empty'), nl
    ).
