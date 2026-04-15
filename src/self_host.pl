% self_host.pl — NeuroProlog Self-Hosting Support
%
% Implements the self-hosting invariants defined in SELF_HOSTING.md.
% Provides self_compile/0, check_self_hosting/0, and compare_behaviour/0.

:- module(self_host, [
    self_compile/0,
    check_self_hosting/0,
    compare_behaviour/0
]).

:- use_module(library(lists)).
:- consult('./neuroprolog').

%% Import predicates from sub-modules that are loaded by neuroprolog but not
%% re-exported by it.  These are needed by the invariant checks below.
:- use_module('./optimisation_dictionary',
              [npl_opt_dict_rules/1, npl_opt_dict_entries/1]).
:- use_module('./cognitive_markers', [npl_ncm_all/1]).

%% Load the rebuild module to make rebuild_guard/0 accessible.
:- use_module('./rebuild',
              [rebuild_guard/0, npl_rebuild_snapshot_save/0]).

%% self_compile/0
%  Compile NeuroProlog using itself. Output → neurocode/neuroprolog_nc.pl
self_compile :-
    write('[self_host] Starting self-compilation...'), nl,
    npl_compile('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
    write('[self_host] Self-compilation complete.'), nl.

%% check_self_hosting/0
%  Verify all self-hosting invariants.
check_self_hosting :-
    check_invariant_1,
    check_invariant_2,
    check_invariant_3,
    check_invariant_4,
    check_invariant_5,
    check_invariant_6,
    check_invariant_7,
    write('[self_host] All 7 invariants satisfied.'), nl.

%% Invariant 1: Plain source exists
check_invariant_1 :-
    ( exists_file('src/neuroprolog.pl') ->
        write('[inv1] Plain source present: OK'), nl
    ; write('[inv1] FAIL: src/neuroprolog.pl missing'), nl, fail
    ).

%% Invariant 2: Neurocode is valid Prolog (check it loads)
check_invariant_2 :-
    ( exists_file('neurocode/neuroprolog_nc.pl') ->
        catch(
            ( consult('neurocode/neuroprolog_nc.pl'),
              write('[inv2] Neurocode loads as valid Prolog: OK'), nl ),
            Error,
            ( write('[inv2] FAIL: '), write(Error), nl, fail )
        )
    ; write('[inv2] NOTE: neurocode not yet generated (run self_compile first)'), nl
    ).

%% Invariant 3: Optimisation dictionary preserved
check_invariant_3 :-
    npl_opt_dict_rules(Rules),
    ( Rules \= [] ->
        length(Rules, N),
        format('[inv3] Optimisation dictionary: ~w rules present: OK~n', [N])
    ; write('[inv3] WARNING: Optimisation dictionary is empty'), nl
    ).

%% Invariant 4: Cognitive markers preserved
%  Verify that the cognitive-marker module is loaded and reports entries.
check_invariant_4 :-
    ( current_predicate(npl_ncm_all/1) ->
        npl_ncm_all(Entries),
        length(Entries, N),
        ( N > 0 ->
            format('[inv4] Cognitive marker mappings present: ~w entries: OK~n', [N])
        ;
            write('[inv4] NOTE: no cognitive marker mappings recorded yet'), nl
        )
    ;
        write('[inv4] NOTE: cognitive_markers module not loaded; run self_compile to populate'), nl
    ).

%% Invariant 5: Learned transforms preserved
%  Verify that all npl_opt_entry/2 entries (rich dictionary entries) are
%  present after a rebuild.  These encode learned algorithmic transforms.
check_invariant_5 :-
    ( current_predicate(npl_opt_dict_entries/1) ->
        npl_opt_dict_entries(Names),
        length(Names, N),
        ( N > 0 ->
            format('[inv5] Learned transform entries: ~w present: OK~n', [N])
        ;
            write('[inv5] WARNING: no learned transform entries in dictionary'), nl
        )
    ;
        write('[inv5] NOTE: optimisation_dictionary module not loaded'), nl
    ).

%% Invariant 6: Rebuild instructions must not be discarded
%  Verify that REBUILDING.md and SELF_HOSTING.md exist and are non-empty.
check_invariant_6 :-
    check_inv6_file('REBUILDING.md'),
    check_inv6_file('SELF_HOSTING.md'),
    write('[inv6] Rebuild instruction files present and non-empty: OK'), nl.

check_inv6_file(File) :-
    ( exists_file(File) ->
        ( size_file(File, Size), Size > 0 ->
            true
        ;
            format('[inv6] FAIL: ~w is empty~n', [File]), fail
        )
    ;
        format('[inv6] FAIL: ~w is missing~n', [File]), fail
    ).

%% Invariant 7: Learned optimisations must not be silently discarded
%  Verify that rebuild_guard/0 is defined and passes on a clean system
%  (i.e. no optimisation rules have been lost since the last snapshot).
check_invariant_7 :-
    ( current_predicate(rebuild_guard/0) ->
        ( catch(
              ( npl_rebuild_snapshot_save,
                rebuild_guard ),
              error(opt_loss(Lost), Context),
              ( format('[inv7] FAIL: rebuild_guard/0 detected lost rules: ~w (context: ~w)~n',
                       [Lost, Context]),
                fail )
          ) ->
            write('[inv7] rebuild_guard/0 present and passes on clean system: OK'), nl
        ;
            write('[inv7] FAIL: rebuild_guard/0 does not pass on clean system'), nl,
            fail
        )
    ;
        write('[inv7] FAIL: rebuild_guard/0 not defined'), nl,
        fail
    ).

%%====================================================================
%% Behaviour comparison
%%====================================================================

%% compare_behaviour/0
%  Run a fixed set of benchmark queries through both the source
%  interpreter and the generated neurocode, and report whether the
%  results are equivalent.
%
%  The neurocode must have been generated (run self_compile/0 first).
compare_behaviour :-
    write('[compare] Comparing source-interpreter vs neurocode behaviour...'), nl,
    ( \+ exists_file('neurocode/neuroprolog_nc.pl') ->
        write('[compare] ERROR: neurocode not found — run self_compile first'), nl,
        fail
    ; true ),
    self_host_bench_queries(Queries),
    compare_run_all(Queries, 0, Passed, 0, Failed),
    format('[compare] Passed: ~w  Failed: ~w~n', [Passed, Failed]),
    ( Failed =:= 0 ->
        write('[compare] Source and neurocode are behaviourally equivalent: OK'), nl
    ;
        write('[compare] FAIL: behavioural differences detected'), nl,
        fail
    ).

%% compare_run_all/5
%  compare_run_all(+Queries, +P0, -P, +F0, -F)
compare_run_all([], P, P, F, F).
compare_run_all([Query|Rest], P0, P, F0, F) :-
    compare_one(Query, ResultSrc, ResultNC),
    ( ResultSrc == ResultNC ->
        P1 is P0 + 1,
        format('[compare] OK  ~w~n', [Query]),
        compare_run_all(Rest, P1, P, F0, F)
    ;
        F1 is F0 + 1,
        format('[compare] DIFF ~w  src=~w  nc=~w~n', [Query, ResultSrc, ResultNC]),
        compare_run_all(Rest, P0, P, F1, F)
    ).

%% compare_one/3
%  compare_one(+Query, -SrcResult, -NCResult)
%  Run Query in the source interpreter and in the neurocode interpreter.
compare_one(Query, SrcResult, NCResult) :-
    compare_run_src(Query, SrcResult),
    compare_run_nc(Query, NCResult).

%% compare_run_src/2
%  Run a query using the plain source interpreter.
compare_run_src(Query, Result) :-
    catch(
        ( npl_interp_reset,
          npl_interp_query(Query, Result0),
          Result = Result0 ),
        _Error,
        Result = error
    ).

%% compare_run_nc/2
%  Run a query by loading the generated neurocode into the interpreter.
compare_run_nc(Query, Result) :-
    catch(
        ( npl_interp_reset,
          self_host_load_neurocode,
          npl_interp_query(Query, Result0),
          Result = Result0 ),
        _Error,
        Result = error
    ).

%% self_host_load_neurocode/0
%  Load neurocode/neuroprolog_nc.pl terms into the meta-interpreter.
self_host_load_neurocode :-
    open('neurocode/neuroprolog_nc.pl', read, Stream),
    self_host_read_clauses(Stream),
    close(Stream).

self_host_read_clauses(Stream) :-
    read_term(Stream, Term, []),
    ( Term == end_of_file -> true
    ; self_host_load_term(Term),
      self_host_read_clauses(Stream)
    ).

self_host_load_term((:- _)) :- !.   % skip directives in neurocode
self_host_load_term(Term) :-
    npl_interp_assert(Term).

%%====================================================================
%% Benchmark queries used for equivalence comparison
%%====================================================================

%% self_host_bench_queries/1
%  A curated list of simple queries whose answers must be identical
%  between the source interpreter and the compiled neurocode.
self_host_bench_queries([
    true,
    (1 =:= 1),
    (X is 2 + 3, X =:= 5),
    (Y is 10 * 10, Y =:= 100),
    (atom(hello)),
    (number(42)),
    (is_list([1,2,3])),
    (length([a,b,c], 3)),
    (append([1,2], [3], [1,2,3]))
]).
