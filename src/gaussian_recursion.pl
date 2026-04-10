% gaussian_recursion.pl — NeuroProlog Gaussian Recursion Reduction
%
% Applies elimination-style transforms to convert linear-recursive
% predicate definitions into accumulator (iterative) form, where
% correctness is guaranteed.
%
% Only applies when the recursive call is the last call in the body
% (tail recursion) or when the recursion pattern matches a known
% Gaussian-reducible form.

:- module(gaussian_recursion, [
    npl_gaussian_reduce/2,
    npl_is_reducible/2,
    npl_reduce_clause_group/2
]).

:- use_module(library(lists)).

%% npl_gaussian_reduce/2
%  npl_gaussian_reduce(+IR, -ReducedIR)
npl_gaussian_reduce(IR, ReducedIR) :-
    npl_group_by_functor(IR, Groups),
    maplist(npl_reduce_group, Groups, ReducedGroups),
    npl_flatten_groups(ReducedGroups, ReducedIR).

%% npl_group_by_functor/2
%  Group IR clauses by head functor/arity.
npl_group_by_functor([], []).
npl_group_by_functor([C|Cs], [[C|Group]|Groups]) :-
    C = ir_clause(Head, _, _),
    functor(Head, F, A),
    partition(npl_same_functor(F/A), Cs, Group, Rest),
    npl_group_by_functor(Rest, Groups).

npl_same_functor(F/A, ir_clause(Head, _, _)) :-
    functor(Head, F, A).

%% npl_reduce_group/2
%  Attempt to reduce a group of clauses for the same predicate.
npl_reduce_group(Group, Reduced) :-
    ( npl_is_reducible(Group, linear_tail_recursion) ->
        npl_reduce_clause_group(Group, Reduced)
    ; Reduced = Group
    ).

%% npl_is_reducible/2
%  Check if a clause group is amenable to Gaussian reduction.
%  Currently recognises: linear tail recursion.
npl_is_reducible(Group, linear_tail_recursion) :-
    length(Group, 2),
    Group = [Base, Step],
    Base  = ir_clause(BaseHead, ir_true, _),
    Step  = ir_clause(StepHead, ir_seq(_, ir_call(RecCall)), _),
    functor(BaseHead, F, A),
    functor(StepHead, F, A),
    functor(RecCall,  F, A).

%% npl_reduce_clause_group/2
%  Apply accumulator transformation to a linear tail-recursive group.
%  Falls back to identity if the transform cannot be safely constructed.
npl_reduce_clause_group(Group, Group) :-
    % Placeholder: full accumulator rewrite requires variable-level
    % analysis; the structure is recognised but emitted unchanged until
    % a safe variable-threading pass is implemented.
    true.

%% npl_flatten_groups/2
npl_flatten_groups([], []).
npl_flatten_groups([G|Gs], Flat) :-
    append(G, Rest, Flat),
    npl_flatten_groups(Gs, Rest).
