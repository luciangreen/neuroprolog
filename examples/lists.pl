% lists.pl — NeuroProlog example: List operations

:- module(lists_example, [demo_lists/0]).

:- consult('src/prelude').

demo_lists :-
    npl_append([1,2,3], [4,5,6], L),
    write('append: '), write(L), nl,
    npl_length(L, Len),
    write('length: '), write(Len), nl,
    npl_reverse(L, R),
    write('reverse: '), write(R), nl,
    npl_sum_list(L, S),
    write('sum: '), write(S), nl.
