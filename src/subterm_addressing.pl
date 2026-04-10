% subterm_addressing.pl — NeuroProlog Subterm-Address Looping
%
% Replaces subterm traversal via recursion with bounded-address
% iteration using positional subterm references.
%
% A subterm address is a list of argument positions, e.g.
%   [1,2,3] means arg(1, arg(2, arg(3, Term))).

:- module(subterm_addressing, [
    npl_subterm_at/3,
    npl_subterm_set/4,
    npl_subterm_address_pass/2,
    npl_subterm_addresses/2
]).

:- use_module(library(lists)).

%% npl_subterm_at/3
%  npl_subterm_at(+Term, +Address, -Subterm)
%  Retrieve the subterm at a positional address.
npl_subterm_at(Term, [], Term).
npl_subterm_at(Term, [N|Ns], Sub) :-
    arg(N, Term, Arg),
    npl_subterm_at(Arg, Ns, Sub).

%% npl_subterm_set/4
%  npl_subterm_set(+Term, +Address, +New, -Result)
%  Replace the subterm at Address with New.
npl_subterm_set(_Term, [], New, New).
npl_subterm_set(Term, [N|Ns], New, Result) :-
    Term =.. [F|Args],
    nth1(N, Args, Old, Rest),
    npl_subterm_set(Old, Ns, New, NewSub),
    nth1(N, NewArgs, NewSub, Rest),
    Result =.. [F|NewArgs].

%% npl_subterm_addresses/2
%  npl_subterm_addresses(+Term, -Addresses)
%  Enumerate all subterm addresses in a term (BFS order).
npl_subterm_addresses(Term, Addresses) :-
    npl_subterm_addresses_queue([[]], Term, [], Addresses).

npl_subterm_addresses_queue([], _, Acc, Acc).
npl_subterm_addresses_queue([Addr|Queue], Term, Acc, All) :-
    npl_subterm_at(Term, Addr, Sub),
    ( compound(Sub) ->
        Sub =.. [_|Args],
        length(Args, Arity),
        numlist(1, Arity, Positions),
        maplist(npl_extend_addr(Addr), Positions, NewAddrs),
        append(Queue, NewAddrs, Queue1)
    ; Queue1 = Queue
    ),
    npl_subterm_addresses_queue(Queue1, Term, [Addr|Acc], All).

npl_extend_addr(Addr, N, Extended) :- append(Addr, [N], Extended).

%% npl_subterm_address_pass/2
%  Apply subterm-address looping optimisation to IR.
%  Currently a no-op placeholder; actual transforms are applied
%  when specific traversal patterns are recognised.
npl_subterm_address_pass(IR, IR).
