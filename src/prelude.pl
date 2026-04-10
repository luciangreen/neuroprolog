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
    npl_flatten/2,
    npl_msort/2,
    npl_numlist/3,
    npl_max_list/2,
    npl_min_list/2,
    npl_sum_list/2
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
    -> reverse(Acc, List)
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
