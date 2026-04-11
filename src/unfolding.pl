% unfolding.pl — NeuroProlog Data Unfolding Engine (Stage 12)
%
% Implements transparent data unfolding for the memoisation pipeline.
%
% == Term normalisation ==
%
%   Every term is mapped to a structural pattern that abstracts away
%   concrete leaf values while preserving functor/arity structure:
%
%     var          → pat(var)
%     atom         → pat(atom)
%     number       → pat(number)
%     f(A1,...,An) → pat(f, [P1,...,Pn])   (Pi = npl_unfold_term(Ai))
%
%   Two terms share a pattern iff they have identical functor/arity trees.
%
% == Key derivation ==
%
%   A memoisable key for a term T is a ground Prolog term that uniquely
%   identifies the structural pattern of T.  For ground terms the key is
%   T itself (maximum specificity).  For terms with unbound variables the
%   key is the structural pattern, enabling cache sharing across different
%   variable instantiations with the same shape.
%
% == Repeated substructure detection ==
%
%   npl_unfold_detect_repeated/2 scans an IR body for call goals whose
%   structural keys appear more than once; these are candidates for
%   memoisation.
%
% == IR pass ==
%
%   npl_unfold_pass/2 applies the detector across a flat IR list and
%   annotates clauses whose bodies contain repeated-key subgoals.

:- module(unfolding, [
    npl_unfold_term/2,
    npl_unfold_goal/2,
    npl_unfold_key/2,
    npl_unfold_match/2,
    npl_unfold_detect_repeated/2,
    npl_unfold_pass/2,
    npl_record_transformation/2,
    npl_transformation_recorded/2
]).

:- use_module(library(lists)).

:- dynamic npl_transformation_recorded/2.
%  npl_transformation_recorded(+Key, +Result)
%  Records a transformation that was successfully applied.

%%====================================================================
%% Term normalisation
%%====================================================================

%% npl_unfold_term/2
%  npl_unfold_term(+Term, -Pattern)
%  Normalise Term to its structural pattern.
%    Variables     → pat(var)
%    Atoms         → pat(atom)
%    Numbers       → pat(number)
%    Compound f/n  → pat(f, [P1,...,Pn])
npl_unfold_term(T, pat(var))    :- var(T), !.
npl_unfold_term(T, pat(number)) :- number(T), !.
npl_unfold_term(T, pat(atom))   :- atom(T), !.
npl_unfold_term(T, pat(F, PArgs)) :-
    T =.. [F|Args],
    maplist(npl_unfold_term, Args, PArgs).

%%====================================================================
%% Goal normalisation
%%====================================================================

%% npl_unfold_goal/2
%  npl_unfold_goal(+IRBody, -Pattern)
%  Normalise an IR body node to a structural pattern.
%  IR nodes that are transparent wrappers recurse into their sub-body.
npl_unfold_goal(ir_true,  pat(ir_true))  :- !.
npl_unfold_goal(ir_fail,  pat(ir_fail))  :- !.
npl_unfold_goal(ir_cut,   pat(ir_cut))   :- !.
npl_unfold_goal(ir_repeat, pat(ir_repeat)) :- !.
npl_unfold_goal(ir_call(Goal), pat(ir_call, [P])) :- !,
    npl_unfold_term(Goal, P).
npl_unfold_goal(ir_not(G), pat(ir_not, [P])) :- !,
    npl_unfold_goal(G, P).
npl_unfold_goal(ir_seq(A, B), pat(ir_seq, [PA, PB])) :- !,
    npl_unfold_goal(A, PA),
    npl_unfold_goal(B, PB).
npl_unfold_goal(ir_disj(A, B), pat(ir_disj, [PA, PB])) :- !,
    npl_unfold_goal(A, PA),
    npl_unfold_goal(B, PB).
npl_unfold_goal(ir_if(C, T, E), pat(ir_if, [PC, PT, PE])) :- !,
    npl_unfold_goal(C, PC),
    npl_unfold_goal(T, PT),
    npl_unfold_goal(E, PE).
npl_unfold_goal(ir_source_marker(_, B), P) :- !,
    npl_unfold_goal(B, P).
npl_unfold_goal(ir_memo_site(_, B), pat(ir_memo_site, [P])) :- !,
    npl_unfold_goal(B, P).
npl_unfold_goal(ir_loop_candidate(B), pat(ir_loop_candidate, [P])) :- !,
    npl_unfold_goal(B, P).
npl_unfold_goal(ir_addr_loop(_, _, B), pat(ir_addr_loop, [P])) :- !,
    npl_unfold_goal(B, P).
npl_unfold_goal(ir_choice_point(Alts), pat(ir_choice_point, PS)) :- !,
    maplist(npl_unfold_goal, Alts, PS).
npl_unfold_goal(Other, P) :-
    npl_unfold_term(Other, P).

%%====================================================================
%% Key derivation
%%====================================================================

%% npl_unfold_key/2
%  npl_unfold_key(+Term, -Key)
%  Derive a ground memoisable key for Term.
%  For fully ground terms the key is Term itself (maximal specificity).
%  For terms containing variables the key is the structural pattern.
npl_unfold_key(T, T) :- ground(T), !.
npl_unfold_key(T, Key) :-
    npl_unfold_term(T, Pat),
    npl_pat_to_ground(Pat, Key).

%% npl_pat_to_ground/2
%  Convert a structural pattern term to a ground Prolog term suitable
%  for use as a dictionary key.
npl_pat_to_ground(pat(var),    '$var')    :- !.
npl_pat_to_ground(pat(atom),   '$atom')   :- !.
npl_pat_to_ground(pat(number), '$number') :- !.
npl_pat_to_ground(pat(F, PArgs), Key) :-
    maplist(npl_pat_to_ground, PArgs, KArgs),
    Key =.. [F|KArgs].

%%====================================================================
%% Pattern matching
%%====================================================================

%% npl_unfold_match/2
%  npl_unfold_match(+Term1, +Term2)
%  Succeed when Term1 and Term2 share the same structural pattern.
npl_unfold_match(T1, T2) :-
    npl_unfold_term(T1, P1),
    npl_unfold_term(T2, P2),
    P1 == P2.

%%====================================================================
%% Repeated substructure detection
%%====================================================================

%% npl_unfold_detect_repeated/2
%  npl_unfold_detect_repeated(+IRBody, -RepeatedKeys)
%  Collect the structural keys of all ir_call goals in IRBody, then
%  return those keys that appear more than once (repeated substructures).
npl_unfold_detect_repeated(IRBody, RepeatedKeys) :-
    npl_unfold_collect_call_keys(IRBody, Keys),
    npl_find_repeated(Keys, RepeatedKeys).

%% npl_unfold_collect_call_keys/2
%  Gather a key for every ir_call node reachable in IRBody.
npl_unfold_collect_call_keys(ir_call(Goal), [Key]) :- !,
    npl_unfold_key(Goal, Key).
npl_unfold_collect_call_keys(ir_true,  []) :- !.
npl_unfold_collect_call_keys(ir_fail,  []) :- !.
npl_unfold_collect_call_keys(ir_cut,   []) :- !.
npl_unfold_collect_call_keys(ir_repeat, []) :- !.
npl_unfold_collect_call_keys(ir_seq(A, B), Keys) :- !,
    npl_unfold_collect_call_keys(A, KA),
    npl_unfold_collect_call_keys(B, KB),
    append(KA, KB, Keys).
npl_unfold_collect_call_keys(ir_disj(A, B), Keys) :- !,
    npl_unfold_collect_call_keys(A, KA),
    npl_unfold_collect_call_keys(B, KB),
    append(KA, KB, Keys).
npl_unfold_collect_call_keys(ir_if(C, T, E), Keys) :- !,
    npl_unfold_collect_call_keys(C, KC),
    npl_unfold_collect_call_keys(T, KT),
    npl_unfold_collect_call_keys(E, KE),
    append(KC, KT, KCT),
    append(KCT, KE, Keys).
npl_unfold_collect_call_keys(ir_not(G), Keys) :- !,
    npl_unfold_collect_call_keys(G, Keys).
npl_unfold_collect_call_keys(ir_source_marker(_, B), Keys) :- !,
    npl_unfold_collect_call_keys(B, Keys).
npl_unfold_collect_call_keys(ir_memo_site(_, B), Keys) :- !,
    npl_unfold_collect_call_keys(B, Keys).
npl_unfold_collect_call_keys(ir_loop_candidate(B), Keys) :- !,
    npl_unfold_collect_call_keys(B, Keys).
npl_unfold_collect_call_keys(ir_addr_loop(_, _, B), Keys) :- !,
    npl_unfold_collect_call_keys(B, Keys).
npl_unfold_collect_call_keys(ir_choice_point(Alts), Keys) :- !,
    maplist(npl_unfold_collect_call_keys, Alts, KLists),
    append(KLists, Keys).
npl_unfold_collect_call_keys(_, []).

%% npl_find_repeated/2
%  npl_find_repeated(+List, -RepeatedElements)
%  Return elements of List that appear more than once (deduped).
npl_find_repeated(List, Repeated) :-
    msort(List, Sorted),
    npl_collect_duplicates(Sorted, Repeated).

npl_collect_duplicates([], []) :- !.
npl_collect_duplicates([X, X | Rest], [X | Dups]) :- !,
    npl_skip_value(X, Rest, Rest1),
    npl_collect_duplicates(Rest1, Dups).
npl_collect_duplicates([_ | Rest], Dups) :-
    npl_collect_duplicates(Rest, Dups).

npl_skip_value(_, [], []) :- !.
npl_skip_value(X, [X | Rest], Rest1) :- !,
    npl_skip_value(X, Rest, Rest1).
npl_skip_value(_, Rest, Rest).

%%====================================================================
%% IR pass
%%====================================================================

%% npl_unfold_pass/2
%  npl_unfold_pass(+IR, -OptIR)
%  Apply data unfolding to a flat IR list.  For each ir_clause whose body
%  contains repeated structural keys, annotate its IRInfo with a
%  `repeated_substructures` entry listing the keys.  Non-ir_clause items
%  are passed through unchanged.
npl_unfold_pass(IR, OptIR) :-
    maplist(npl_unfold_annotate_clause, IR, OptIR).

npl_unfold_annotate_clause(ir_clause(Head, Body, Info),
                            ir_clause(Head, Body, Info1)) :- !,
    npl_unfold_detect_repeated(Body, Reps),
    ( Reps = [] ->
        Info1 = Info
    ;
        Info1 = [repeated_substructures:Reps | Info]
    ).
npl_unfold_annotate_clause(Other, Other).

%%====================================================================
%% Transformation recording
%%====================================================================

%% npl_record_transformation/2
%  npl_record_transformation(+Key, +Result)
%  Record that a transformation identified by Key produced Result.
%  Idempotent: re-recording the same Key updates the Result.
npl_record_transformation(Key, Result) :-
    ( retract(npl_transformation_recorded(Key, _)) -> true ; true ),
    assertz(npl_transformation_recorded(Key, Result)).
