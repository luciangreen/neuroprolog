% memoisation.pl — NeuroProlog Logical Memoisation (Stage 12)
%
% Provides transparent, logic-preserving memoisation at both predicate
% level and subgoal level.  Results are stored as Prolog structures and
% retrieved via first-argument indexing (near-constant time for ground keys).
%
% == Safety ==
%
%   Safe memoisation requires that the goal is pure (no side effects) and
%   that the cache key is ground (ensuring the same key always maps to the
%   same result).  npl_memo_is_safe/1 performs this check.  Unsafe goals
%   are executed directly without caching.
%
% == Storage ==
%
%   npl_memo_cache/3 stores entries as:
%     npl_memo_cache(+Key, +Mode, ?Value)
%   where Mode is `det` (single result), `all` (solution list), or
%   `subgoal` (explicit-key boolean).  SWI-Prolog indexes on the first
%   argument, giving O(1) lookup for ground keys.
%
% == Transparency ==
%
%   npl_memo_inspect/2 and npl_memo_stats/3 allow full inspection of
%   cache state and hit/miss statistics.

:- module(memoisation, [
    npl_memo/1,
    npl_memo_call/1,
    npl_memo_call_det/2,
    npl_memo_call_all/3,
    npl_memo_subgoal/2,
    npl_memo_clear/1,
    npl_memo_clear_all/0,
    npl_memo_is_safe/1,
    npl_memo_inspect/2,
    npl_memo_stats/3,
    npl_memoisation_pass/2,
    npl_memo_cache/3
]).

:- use_module(library(lists)).

:- dynamic npl_memo_cache/3.      % npl_memo_cache(+Key, +Mode, ?Value)
:- dynamic npl_is_memoised/1.     % npl_is_memoised(F/A)
:- dynamic npl_memo_hit_count/2.  % npl_memo_hit_count(+Key, +Count)
:- dynamic npl_memo_miss_count/2. % npl_memo_miss_count(+Key, +Count)

%%====================================================================
%% Predicate-level memoisation registration
%%====================================================================

%% npl_memo/1
%  Declare a predicate as memoised.
%  npl_memo(+Functor/Arity)
npl_memo(F/A) :-
    ( npl_is_memoised(F/A) -> true ; assertz(npl_is_memoised(F/A)) ).

%%====================================================================
%% Safety checking
%%====================================================================

%% npl_memo_is_safe/1
%  Succeed when Goal is safe to memoise: ground (binding-safe) and pure.
%  npl_memo_is_safe(+Goal)
npl_memo_is_safe(Goal) :-
    ground(Goal),
    \+ npl_memo_has_side_effect(Goal).

%% npl_memo_has_side_effect/1
%  Goals with observable side effects that must not be memoised.
npl_memo_has_side_effect(assert(_)).
npl_memo_has_side_effect(assertz(_)).
npl_memo_has_side_effect(asserta(_)).
npl_memo_has_side_effect(retract(_)).
npl_memo_has_side_effect(retractall(_)).
npl_memo_has_side_effect(write(_)).
npl_memo_has_side_effect(writeln(_)).
npl_memo_has_side_effect(nl).
npl_memo_has_side_effect(format(_, _)).
npl_memo_has_side_effect(format(_)).
npl_memo_has_side_effect(read(_)).
npl_memo_has_side_effect(read_term(_, _)).
npl_memo_has_side_effect(open(_, _, _)).
npl_memo_has_side_effect(open(_, _, _, _)).
npl_memo_has_side_effect(close(_)).
npl_memo_has_side_effect(nb_setval(_, _)).
npl_memo_has_side_effect(nb_getval(_, _)).

%%====================================================================
%% Memoised call variants
%%====================================================================

%% npl_memo_call/1
%  Call a boolean goal, caching its success on first call.
%  For non-ground or impure goals falls back to direct call.
%  npl_memo_call(+Goal)
npl_memo_call(Goal) :-
    ( npl_memo_is_safe(Goal) ->
        ( npl_memo_cache(Goal, det, true) ->
            npl_memo_record_hit(Goal)
        ;   npl_memo_record_miss(Goal),
            call(Goal),
            assertz(npl_memo_cache(Goal, det, true))
        )
    ; call(Goal)
    ).

%% npl_memo_call_det/2
%  Memoise a deterministic call that produces one result value.
%  npl_memo_call_det(+Key, -Result)
%  Key is a ground term identifying the computation; Result is the value
%  cached on first execution and retrieved on subsequent calls.
npl_memo_call_det(Key, Result) :-
    ( ground(Key) ->
        ( npl_memo_cache(Key, det, Result) ->
            npl_memo_record_hit(Key)
        ;   npl_memo_record_miss(Key),
            call(Key),
            ( ground(Result) ->
                assertz(npl_memo_cache(Key, det, Result))
            ; true
            )
        )
    ; call(Key)
    ).

%% npl_memo_call_all/3
%  Collect all solutions and cache the complete solution set.
%  npl_memo_call_all(+Goal, ?Template, -Solutions)
%  Subsequent calls retrieve the cached solution list directly.
npl_memo_call_all(Goal, Template, Solutions) :-
    ( npl_memo_is_safe(Goal) ->
        ( npl_memo_cache(Goal, all, Solutions) ->
            npl_memo_record_hit(Goal)
        ;   npl_memo_record_miss(Goal),
            findall(Template, call(Goal), Solutions),
            assertz(npl_memo_cache(Goal, all, Solutions))
        )
    ; findall(Template, call(Goal), Solutions)
    ).

%% npl_memo_subgoal/2
%  Subgoal-level memoisation with an explicit ground key.
%  npl_memo_subgoal(+Key, +Goal)
%  Key is a user-supplied ground term used as the cache key, allowing
%  memoisation even when Goal itself is not fully ground.
npl_memo_subgoal(Key, Goal) :-
    ( ground(Key) ->
        ( npl_memo_cache(Key, subgoal, true) ->
            npl_memo_record_hit(Key)
        ;   npl_memo_record_miss(Key),
            call(Goal),
            assertz(npl_memo_cache(Key, subgoal, true))
        )
    ; call(Goal)
    ).

%%====================================================================
%% Cache management
%%====================================================================

%% npl_memo_clear/1
%  Clear memoisation cache for a given functor/arity.
%  npl_memo_clear(+F/A)
npl_memo_clear(F/A) :-
    functor(Head, F, A),
    retractall(npl_memo_cache(Head, _, _)),
    retractall(npl_memo_hit_count(Head, _)),
    retractall(npl_memo_miss_count(Head, _)).

%% npl_memo_clear_all/0
%  Clear all memoisation caches and statistics.
npl_memo_clear_all :-
    retractall(npl_memo_cache(_, _, _)),
    retractall(npl_memo_hit_count(_, _)),
    retractall(npl_memo_miss_count(_, _)).

%%====================================================================
%% Inspection and statistics
%%====================================================================

%% npl_memo_inspect/2
%  Inspect the current cache entries for a given functor/arity.
%  npl_memo_inspect(+F/A, -Entries)
%  Entries is a list of cache_entry(Key, Mode, Value) terms.
npl_memo_inspect(F/A, Entries) :-
    functor(Head, F, A),
    findall(cache_entry(Key, Mode, Val),
            ( npl_memo_cache(Key, Mode, Val),
              functor(Key, F, A) ),
            Entries).

%% npl_memo_stats/3
%  Query cache statistics for a given goal key.
%  npl_memo_stats(+Goal, -Hits, -Misses)
npl_memo_stats(Goal, Hits, Misses) :-
    ( npl_memo_hit_count(Goal, Hits) -> true ; Hits = 0 ),
    ( npl_memo_miss_count(Goal, Misses) -> true ; Misses = 0 ).

%%====================================================================
%% Internal statistics helpers
%%====================================================================

npl_memo_record_hit(Goal) :-
    ( retract(npl_memo_hit_count(Goal, N)) ->
        N1 is N + 1
    ; N1 = 1
    ),
    assertz(npl_memo_hit_count(Goal, N1)).

npl_memo_record_miss(Goal) :-
    ( retract(npl_memo_miss_count(Goal, N)) ->
        N1 is N + 1
    ; N1 = 1
    ),
    assertz(npl_memo_miss_count(Goal, N1)).

%%====================================================================
%% IR annotation pass
%%====================================================================

%% npl_memoisation_pass/2
%  Apply memoisation annotations to IR.
%  npl_memoisation_pass(+IR, -OptIR)
npl_memoisation_pass(IR, OptIR) :-
    maplist(npl_memo_annotate, IR, OptIR).

npl_memo_annotate(ir_clause(Head, Body, Info), ir_clause(Head, Body, Info1)) :-
    ( callable(Head), Head =.. [F|Args], length(Args, A),
      npl_is_memoised(F/A) ->
        Info1 = memoised(Info)
    ; Info1 = Info
    ).
