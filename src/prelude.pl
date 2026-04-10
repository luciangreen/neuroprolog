% prelude.pl — NeuroProlog Standard Prelude
%
% Provides standard list, arithmetic, and meta predicates.

:- module(prelude, [
    npl_append/3,
    npl_length/2,
    npl_member/2,
    npl_reverse/2,
    npl_last/2,
    npl_nth/3,
    npl_nth0/3,
    npl_nth1/3,
    npl_flatten/2,
    npl_msort/2,
    npl_sort/2,
    npl_numlist/3,
    npl_max_list/2,
    npl_min_list/2,
    npl_sum_list/2,
    npl_select/3,
    npl_delete/3,
    npl_subtract/3,
    npl_intersection/3,
    npl_union/3,
    npl_list_to_set/2,
    npl_permutation/2,
    npl_functor/3,
    npl_arg/3,
    npl_univ/2,
    npl_copy_term/2,
    npl_var/1,
    npl_nonvar/1,
    npl_atom/1,
    npl_number/1,
    npl_integer/1,
    npl_float/1,
    npl_compound/1,
    npl_atomic/1,
    npl_callable/1,
    npl_ground/1,
    npl_is_list/1,
    npl_unify/2,
    npl_unify_with_occurs_check/2,
    npl_compare/3,
    npl_maplist/2,
    npl_maplist/3,
    npl_maplist/4,
    npl_foldl/4,
    npl_foldl/5,
    npl_include/3,
    npl_exclude/3
]).

%% npl_marker/2 — Cognitive code marker directive (no-op at runtime)
:- meta_predicate npl_marker(+, +).
npl_marker(_, _).

%% npl_append/3
npl_append([], L, L).
npl_append([H|T], L, [H|R]) :- npl_append(T, L, R).

%% npl_length/2
npl_length(L, N) :- npl_length_acc(L, 0, N).
npl_length_acc([], Acc, Acc).
npl_length_acc([_|T], Acc, N) :- Acc1 is Acc + 1, npl_length_acc(T, Acc1, N).

:- npl_marker(npl_length/2, recursion_reduced).

%% npl_member/2
npl_member(X, [X|_]).
npl_member(X, [_|T]) :- npl_member(X, T).

%% npl_reverse/2
npl_reverse(L, R) :- npl_reverse_acc(L, [], R).
npl_reverse_acc([], Acc, Acc).
npl_reverse_acc([H|T], Acc, R) :- npl_reverse_acc(T, [H|Acc], R).

:- npl_marker(npl_reverse/2, recursion_reduced).

%% npl_last/2
npl_last([X], X).
npl_last([_|T], X) :- npl_last(T, X).

%% npl_nth/3  (1-indexed)
npl_nth(1, [H|_], H) :- !.
npl_nth(N, [_|T], X) :- N > 1, N1 is N - 1, npl_nth(N1, T, X).

%% npl_flatten/2
npl_flatten([], []).
npl_flatten([H|T], F) :-
    is_list(H), !,
    npl_flatten(H, FH),
    npl_flatten(T, FT),
    npl_append(FH, FT, F).
npl_flatten([H|T], [H|FT]) :- npl_flatten(T, FT).

%% npl_msort/2
npl_msort([], []).
npl_msort([H|T], Sorted) :-
    npl_partition(H, T, Less, Greater),
    npl_msort(Less, SortedLess),
    npl_msort(Greater, SortedGreater),
    npl_append(SortedLess, [H|SortedGreater], Sorted).

npl_partition(_, [], [], []).
npl_partition(Pivot, [H|T], [H|Less], Greater) :-
    H @=< Pivot, !,
    npl_partition(Pivot, T, Less, Greater).
npl_partition(Pivot, [H|T], Less, [H|Greater]) :-
    npl_partition(Pivot, T, Less, Greater).

%% npl_numlist/3
npl_numlist(Low, High, List) :-
    Low =< High,
    npl_numlist_acc(Low, High, [], List).

npl_numlist_acc(Low, High, Acc, List) :-
    ( Low > High
    -> npl_reverse(Acc, List)
    ;  Low1 is Low + 1,
       npl_numlist_acc(Low1, High, [Low|Acc], List)
    ).

%% npl_max_list/2
npl_max_list([H|T], Max) :- npl_max_list_acc(T, H, Max).
npl_max_list_acc([], Max, Max).
npl_max_list_acc([H|T], Cur, Max) :-
    ( H > Cur -> npl_max_list_acc(T, H, Max)
    ; npl_max_list_acc(T, Cur, Max)
    ).

%% npl_min_list/2
npl_min_list([H|T], Min) :- npl_min_list_acc(T, H, Min).
npl_min_list_acc([], Min, Min).
npl_min_list_acc([H|T], Cur, Min) :-
    ( H < Cur -> npl_min_list_acc(T, H, Min)
    ; npl_min_list_acc(T, Cur, Min)
    ).

%% npl_sum_list/2
npl_sum_list(L, S) :- npl_sum_list_acc(L, 0, S).
npl_sum_list_acc([], Acc, Acc).
npl_sum_list_acc([H|T], Acc, S) :- Acc1 is Acc + H, npl_sum_list_acc(T, Acc1, S).

:- npl_marker(npl_sum_list/2, recursion_reduced).

%% npl_nth0/3  (0-indexed)
npl_nth0(0, [H|_], H) :- !.
npl_nth0(N, [_|T], X) :- N > 0, N1 is N - 1, npl_nth0(N1, T, X).

%% npl_nth1/3  (1-indexed, same as npl_nth/3)
npl_nth1(N, L, X) :- npl_nth(N, L, X).

%% npl_select/3  — select element from list leaving remainder
npl_select(X, [X|T], T).
npl_select(X, [H|T], [H|R]) :- npl_select(X, T, R).

%% npl_delete/3  — delete all occurrences of element from list
npl_delete([], _, []).
npl_delete([H|T], H, R) :- !, npl_delete(T, H, R).
npl_delete([H|T], X, [H|R]) :- npl_delete(T, X, R).

%% npl_subtract/3  — list difference (elements of List1 not in List2)
npl_subtract([], _, []).
npl_subtract([H|T], L2, R) :-
    ( npl_member(H, L2) -> npl_subtract(T, L2, R)
    ; R = [H|R1], npl_subtract(T, L2, R1)
    ).

%% npl_intersection/3
npl_intersection([], _, []).
npl_intersection([H|T], L2, [H|R]) :-
    npl_member(H, L2), !,
    npl_intersection(T, L2, R).
npl_intersection([_|T], L2, R) :- npl_intersection(T, L2, R).

%% npl_union/3
npl_union([], L, L).
npl_union([H|T], L2, R) :-
    ( npl_member(H, L2) -> npl_union(T, L2, R)
    ; R = [H|R1], npl_union(T, L2, R1)
    ).

%% npl_list_to_set/2  — remove duplicates preserving first occurrence
npl_list_to_set([], []).
npl_list_to_set([H|T], [H|R]) :-
    npl_delete(T, H, T1),
    npl_list_to_set(T1, R).

%% npl_permutation/2
npl_permutation([], []).
npl_permutation(List, [H|Perm]) :-
    npl_select(H, List, Rest),
    npl_permutation(Rest, Perm).

%% npl_sort/2  — sort removing duplicates
npl_sort([], []).
npl_sort([H|T], Sorted) :-
    npl_sort_partition(H, T, Less, Greater),
    npl_sort(Less, SortedLess),
    npl_sort(Greater, SortedGreater),
    npl_append(SortedLess, [H|SortedGreater], Sorted).

npl_sort_partition(_, [], [], []).
npl_sort_partition(Pivot, [H|T], Less, Greater) :-
    compare(Order, H, Pivot),
    ( Order == (<) -> Less = [H|Less1], npl_sort_partition(Pivot, T, Less1, Greater)
    ; Order == (>) -> Greater = [H|Greater1], npl_sort_partition(Pivot, T, Less, Greater1)
    ; npl_sort_partition(Pivot, T, Less, Greater)  % equal: skip duplicate
    ).

%% --- Term predicates ---

%% npl_functor/3
npl_functor(Term, F, A) :- functor(Term, F, A).

%% npl_arg/3
npl_arg(N, Term, Arg) :- arg(N, Term, Arg).

%% npl_univ/2  — =.. (univ)
npl_univ(Term, List) :- Term =.. List.

%% npl_copy_term/2
npl_copy_term(Term, Copy) :- copy_term(Term, Copy).

%% --- Type check predicates ---

npl_var(X) :- var(X).
npl_nonvar(X) :- nonvar(X).
npl_atom(X) :- atom(X).
npl_number(X) :- number(X).
npl_integer(X) :- integer(X).
npl_float(X) :- float(X).
npl_compound(X) :- compound(X).
npl_atomic(X) :- atomic(X).
npl_callable(X) :- callable(X).
npl_ground(X) :- ground(X).
npl_is_list(X) :- is_list(X).

%% --- Unification helpers ---

%% npl_unify/2
npl_unify(X, X).

%% npl_unify_with_occurs_check/2
npl_unify_with_occurs_check(X, Y) :- unify_with_occurs_check(X, Y).

%% --- Comparison predicates ---

%% npl_compare/3
npl_compare(Order, X, Y) :- compare(Order, X, Y).

%% --- Meta helpers ---

%% npl_maplist/2  — call Goal for each element
npl_maplist(_, []).
npl_maplist(Goal, [H|T]) :- call(Goal, H), npl_maplist(Goal, T).

%% npl_maplist/3  — map Goal over list producing result list
npl_maplist(_, [], []).
npl_maplist(Goal, [H|T], [R|Rs]) :- call(Goal, H, R), npl_maplist(Goal, T, Rs).

%% npl_maplist/4  — map Goal over two lists
npl_maplist(_, [], [], []).
npl_maplist(Goal, [H1|T1], [H2|T2], [R|Rs]) :-
    call(Goal, H1, H2, R),
    npl_maplist(Goal, T1, T2, Rs).

%% npl_foldl/4  — fold Goal over list: call(Goal, Elem, V0, V1)
npl_foldl(_, [], V, V).
npl_foldl(Goal, [H|T], V0, V) :-
    call(Goal, H, V0, V1),
    npl_foldl(Goal, T, V1, V).

%% npl_foldl/5  — fold Goal over two lists
npl_foldl(_, [], [], V, V).
npl_foldl(Goal, [H1|T1], [H2|T2], V0, V) :-
    call(Goal, H1, H2, V0, V1),
    npl_foldl(Goal, T1, T2, V1, V).

%% npl_include/3  — filter list keeping elements satisfying Goal
npl_include(_, [], []).
npl_include(Goal, [H|T], R) :-
    ( call(Goal, H) -> R = [H|R1] ; R = R1 ),
    npl_include(Goal, T, R1).

%% npl_exclude/3  — filter list removing elements satisfying Goal
npl_exclude(_, [], []).
npl_exclude(Goal, [H|T], R) :-
    ( call(Goal, H) -> R = R1 ; R = [H|R1] ),
    npl_exclude(Goal, T, R1).
