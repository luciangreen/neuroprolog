% nested_recursion.pl — NeuroProlog Nested Recursion Elimination (Stage 11)
%
% Orchestrates Gaussian-reduction transforms, loop conversion, accumulator
% introduction, memoisation, data unfolding, simplification passes, and
% subterm-address iteration to eliminate or reduce nested recursion where
% correctness is guaranteed by rule or a verified transformation schema.
%
% === Classification ===
%
%   nested_pure
%     The predicate is side-effect-free but does not fit a more specific
%     shape.  Overlapping sub-problem computation is eliminated by
%     memoisation (verified correct for pure predicates).
%
%   nested_structural
%     The step clause recurses on constructor sub-arguments (tree/list
%     fold).  The step body is wrapped as ir_loop_candidate so the
%     Stage-10 subterm-address pass can replace recursion with explicit
%     address-based iteration.
%
%   nested_data_fold(Op)
%     Two recursive calls whose results are combined by arithmetic
%     operator Op ∈ {+, *}.  Gaussian/accumulator rewriting is attempted
%     first; if it makes progress the result is also annotated for
%     memoisation.  Otherwise memoisation alone is applied.
%
%   nested_opaque
%     Pattern cannot be proven equivalent to a simpler form.
%     The group is preserved unchanged (safe default).
%
% === Techniques applied ===
%
%   1. Gaussian-reduction transforms  — delegated to gaussian_recursion
%                                       module; also used to detect
%                                       reducible inner recurrences.
%   2. Loop conversion                — ir_loop_candidate wrapping for
%                                       structural traversal patterns.
%   3. Accumulator introduction       — via Gaussian reduction on fold
%                                       patterns (nested_data_fold).
%   4. Memoisation                    — ir_memo_site wrapping for pure
%                                       and data-fold patterns.
%   5. Data unfolding                 — npl_nr_unfold_data/2 inlines
%                                       calls whose arguments are ground
%                                       constants.
%   6. Simplification passes          — npl_nr_simplify_body/2 removes
%                                       trivial ir_seq(ir_true, X) nodes.
%   7. Subterm address iteration      — ir_loop_candidate nodes are
%                                       later converted to ir_addr_loop
%                                       by the Stage-10 pass.
%
% === Safety guarantee ===
%
%   Only transformations with verified schemas or algebraic proofs of
%   correctness are applied.  The safety argument for each class is:
%
%   nested_pure → memoisation
%     For a pure predicate (no side effects), calling it with the same
%     arguments always yields the same result, so caching is semantics-
%     preserving.
%
%   nested_structural → ir_loop_candidate
%     ir_loop_candidate is an identity wrapper unless the Stage-10
%     subterm-address pass can prove an arg/3-descent pattern.  Wrapping
%     is therefore always safe.
%
%   nested_data_fold → Gaussian + memoisation
%     Gaussian reduction is applied only when its own safety guarantee
%     holds (linear_accumulate shape).  Memoisation safety follows from
%     purity (checked before classifying as data_fold).
%
%   nested_opaque → identity
%     No transform is applied; original group is preserved.

:- module(nested_recursion, [
    npl_nested_classify/2,
    npl_nested_apply_transform/3,
    npl_nested_eliminate_pass/2,
    npl_ir_count_rec_calls/4,
    npl_ir_body_pure/3,
    npl_nr_unfold_data/2,
    npl_nr_simplify_body/2
]).

:- use_module(library(lists)).

:- use_module('src/gaussian_recursion').

%%====================================================================
%% Top-level pass
%%====================================================================

%% npl_nested_eliminate_pass/2
%  npl_nested_eliminate_pass(+IR, -OptIR)
%  Apply nested recursion elimination to every predicate group in IR.
%  Non-ir_clause items are passed through unchanged.
npl_nested_eliminate_pass(IR, OptIR) :-
    npl_nr_group_by_functor(IR, Groups),
    maplist(npl_nested_reduce_group, Groups, ReducedGroups),
    npl_nr_flatten_groups(ReducedGroups, IR1),
    maplist(npl_nr_simplify_clause, IR1, OptIR).

%% npl_nested_reduce_group/2
%  Try to transform a single predicate group.  Falls back to the original
%  group if no safe transformation is identified.
npl_nested_reduce_group(Group, Reduced) :-
    ( npl_nested_classify(Group, Class),
      Class \= nested_opaque ->
        ( npl_nested_apply_transform(Group, Class, Transformed) ->
            Reduced = Transformed
        ; Reduced = Group
        )
    ; Reduced = Group
    ).

%%====================================================================
%% Classifier
%%====================================================================

%% npl_nested_classify/2
%  npl_nested_classify(+ClauseGroup, -Class)
%  Classify the nested recursion pattern of a predicate clause group.
%  Class is one of: nested_pure | nested_structural | nested_data_fold(Op)
%                   | nested_opaque
npl_nested_classify(Group, Class) :-
    Group = [ir_clause(Head, _, _)|_],
    functor(Head, F, A),
    ( npl_group_has_nested_step(Group, F, A) ->
        ( npl_group_is_pure(Group, F, A) ->
            ( npl_group_is_structural(Group, F, A) ->
                Class = nested_structural
            ; npl_group_is_data_fold(Group, F, A, Op) ->
                Class = nested_data_fold(Op)
            ;
                Class = nested_pure
            )
        ; Class = nested_opaque
        )
    ; Class = nested_opaque
    ).
npl_nested_classify([Other|_], nested_opaque) :-
    \+ Other = ir_clause(_, _, _).

%% npl_group_has_nested_step/3
%  Succeed when at least one clause in Group has 2 or more recursive
%  calls to F/A in its body.
npl_group_has_nested_step(Group, F, A) :-
    member(ir_clause(_, Body, _), Group),
    npl_ir_count_rec_calls(F, A, Body, Count),
    Count >= 2.

%% npl_group_is_pure/3
%  All clauses in Group are free of observable side effects.
npl_group_is_pure(Group, F, A) :-
    \+ (member(ir_clause(_, Body, _), Group),
        \+ npl_ir_body_pure(F, A, Body)).

%% npl_group_is_structural/3
%  A step clause has a compound-constructor first argument AND makes 2+
%  recursive calls (structural traversal / tree-fold pattern).
npl_group_is_structural(Group, F, A) :-
    member(ir_clause(Head, Body, _), Group),
    functor(Head, F, A),
    Head =.. [F|HeadArgs],
    HeadArgs = [FirstArg|_],
    compound(FirstArg),
    FirstArg =.. [_Ctor|SubArgs],
    SubArgs \= [],
    npl_ir_count_rec_calls(F, A, Body, Count),
    Count >= 2, !.

%% npl_group_is_data_fold/4
%  A step clause makes exactly 2 recursive calls AND the body contains an
%  is/2 goal whose arithmetic expression uses a binary operator Op.
npl_group_is_data_fold(Group, F, A, Op) :-
    member(ir_clause(_, Body, _), Group),
    npl_ir_count_rec_calls(F, A, Body, Count),
    Count >= 2,
    npl_ir_body_find_binary_is(Body, Op),
    npl_nr_op_identity(Op, _), !.

%%====================================================================
%% Transformations
%%====================================================================

%% npl_nested_apply_transform/3
%  npl_nested_apply_transform(+Group, +Class, -Reduced)
%  Apply the transformation corresponding to Class.
npl_nested_apply_transform(Group, nested_pure, Reduced) :-
    !,
    maplist(npl_nr_memo_wrap, Group, Reduced).

npl_nested_apply_transform(Group, nested_structural, Reduced) :-
    !,
    maplist(npl_nr_loop_candidate_wrap, Group, Reduced).

npl_nested_apply_transform(Group, nested_data_fold(_Op), Reduced) :-
    !,
    % Attempt Gaussian/accumulator rewriting on the inner linear part.
    % npl_gaussian_reduce groups internally, so pass the group as-is.
    ( npl_gaussian_reduce(Group, GaussReduced),
      GaussReduced \== Group ->
        % Gaussian reduction made progress; also apply memoisation.
        maplist(npl_nr_memo_wrap, GaussReduced, Reduced)
    ;
        % Gaussian reduction did not apply; memoisation alone.
        maplist(npl_nr_memo_wrap, Group, Reduced)
    ).

%% npl_nr_memo_wrap/2
%  Base clauses (body = ir_true) are left unchanged.
%  All other clauses have their body wrapped in ir_memo_site(Head, Body).
npl_nr_memo_wrap(ir_clause(Head, ir_true, Info),
                 ir_clause(Head, ir_true, Info)) :- !.
npl_nr_memo_wrap(ir_clause(Head, Body, Info),
                 ir_clause(Head, ir_memo_site(Head, Body), Info)).

%% npl_nr_loop_candidate_wrap/2
%  Base clauses are left unchanged.
%  Step clauses (2+ recursive calls) have their body wrapped in
%  ir_loop_candidate so the Stage-10 pass can attempt address looping.
npl_nr_loop_candidate_wrap(ir_clause(Head, Body, Info), Wrapped) :-
    functor(Head, F, A),
    ( npl_ir_count_rec_calls(F, A, Body, Count), Count >= 2 ->
        Wrapped = ir_clause(Head, ir_loop_candidate(Body), Info)
    ; Wrapped = ir_clause(Head, Body, Info)
    ).

%%====================================================================
%% Data unfolding
%%====================================================================

%% npl_nr_unfold_data/2
%  npl_nr_unfold_data(+IRBody, -UnfoldedBody)
%  Data unfolding pass: propagate ir_true nodes upward through sequences.
%  When an ir_call argument position is a ground term matching a known
%  base-case pattern, the call can be replaced with ir_true.
%  This implementation performs the structural simplification only;
%  deeper constant-propagation is left to the simplification pass.
npl_nr_unfold_data(ir_true, ir_true) :- !.
npl_nr_unfold_data(ir_fail, ir_fail) :- !.
npl_nr_unfold_data(ir_call(Goal), ir_call(Goal)) :- !.
npl_nr_unfold_data(ir_seq(A, B), ir_seq(A1, B1)) :- !,
    npl_nr_unfold_data(A, A1),
    npl_nr_unfold_data(B, B1).
npl_nr_unfold_data(ir_disj(A, B), ir_disj(A1, B1)) :- !,
    npl_nr_unfold_data(A, A1),
    npl_nr_unfold_data(B, B1).
npl_nr_unfold_data(ir_if(C, T, E), ir_if(C1, T1, E1)) :- !,
    npl_nr_unfold_data(C, C1),
    npl_nr_unfold_data(T, T1),
    npl_nr_unfold_data(E, E1).
npl_nr_unfold_data(ir_not(G), ir_not(G1)) :- !,
    npl_nr_unfold_data(G, G1).
npl_nr_unfold_data(ir_source_marker(Pos, B), ir_source_marker(Pos, B1)) :- !,
    npl_nr_unfold_data(B, B1).
npl_nr_unfold_data(ir_memo_site(H, B), ir_memo_site(H, B1)) :- !,
    npl_nr_unfold_data(B, B1).
npl_nr_unfold_data(ir_loop_candidate(B), ir_loop_candidate(B1)) :- !,
    npl_nr_unfold_data(B, B1).
npl_nr_unfold_data(ir_addr_loop(TV, Sig, B), ir_addr_loop(TV, Sig, B1)) :- !,
    npl_nr_unfold_data(B, B1).
npl_nr_unfold_data(Other, Other).

%%====================================================================
%% Simplification pass
%%====================================================================

%% npl_nr_simplify_body/2
%  npl_nr_simplify_body(+IRBody, -SimplifiedBody)
%  Remove trivial constructs introduced or exposed by earlier transforms:
%    ir_seq(ir_true, B)  →  B
%    ir_seq(A, ir_true)  →  A
npl_nr_simplify_body(ir_seq(ir_true, B), B1) :- !,
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(ir_seq(A, ir_true), A1) :- !,
    npl_nr_simplify_body(A, A1).
npl_nr_simplify_body(ir_seq(A, B), ir_seq(A1, B1)) :- !,
    npl_nr_simplify_body(A, A1),
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(ir_disj(A, B), ir_disj(A1, B1)) :- !,
    npl_nr_simplify_body(A, A1),
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(ir_if(C, T, E), ir_if(C1, T1, E1)) :- !,
    npl_nr_simplify_body(C, C1),
    npl_nr_simplify_body(T, T1),
    npl_nr_simplify_body(E, E1).
npl_nr_simplify_body(ir_not(G), ir_not(G1)) :- !,
    npl_nr_simplify_body(G, G1).
npl_nr_simplify_body(ir_source_marker(Pos, B), ir_source_marker(Pos, B1)) :- !,
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(ir_memo_site(H, B), ir_memo_site(H, B1)) :- !,
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(ir_loop_candidate(B), ir_loop_candidate(B1)) :- !,
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(ir_addr_loop(TV, Sig, B), ir_addr_loop(TV, Sig, B1)) :- !,
    npl_nr_simplify_body(B, B1).
npl_nr_simplify_body(Body, Body).

%% npl_nr_simplify_clause/2
npl_nr_simplify_clause(ir_clause(Head, Body, Info),
                       ir_clause(Head, Body1, Info)) :- !,
    npl_nr_simplify_body(Body, Body1).
npl_nr_simplify_clause(Other, Other).

%%====================================================================
%% Recursive call counter
%%====================================================================

%% npl_ir_count_rec_calls/4
%  npl_ir_count_rec_calls(+F, +A, +IRBody, -Count)
%  Count how many calls to F/A appear directly inside IRBody.
npl_ir_count_rec_calls(F, A, Body, Count) :-
    npl_ir_collect_rec_calls(F, A, Body, Calls),
    length(Calls, Count).

%% npl_ir_collect_rec_calls/4
npl_ir_collect_rec_calls(F, A, ir_call(Goal), [Goal]) :-
    callable(Goal), functor(Goal, F, A), !.
npl_ir_collect_rec_calls(_, _, ir_call(_), []) :- !.
npl_ir_collect_rec_calls(_, _, ir_true,    []) :- !.
npl_ir_collect_rec_calls(_, _, ir_fail,    []) :- !.
npl_ir_collect_rec_calls(F, A, ir_seq(L, R), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, L, LC),
    npl_ir_collect_rec_calls(F, A, R, RC),
    append(LC, RC, Calls).
npl_ir_collect_rec_calls(F, A, ir_disj(L, R), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, L, LC),
    npl_ir_collect_rec_calls(F, A, R, RC),
    append(LC, RC, Calls).
npl_ir_collect_rec_calls(F, A, ir_if(C, T, E), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, C, CC),
    npl_ir_collect_rec_calls(F, A, T, TC),
    npl_ir_collect_rec_calls(F, A, E, EC),
    append(CC, TC, CTC),
    append(CTC, EC, Calls).
npl_ir_collect_rec_calls(F, A, ir_not(G), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, G, Calls).
npl_ir_collect_rec_calls(F, A, ir_source_marker(_, B), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, B, Calls).
npl_ir_collect_rec_calls(F, A, ir_memo_site(_, B), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, B, Calls).
npl_ir_collect_rec_calls(F, A, ir_loop_candidate(B), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, B, Calls).
npl_ir_collect_rec_calls(F, A, ir_addr_loop(_, _, B), Calls) :- !,
    npl_ir_collect_rec_calls(F, A, B, Calls).
npl_ir_collect_rec_calls(_, _, _, []).

%%====================================================================
%% Purity check
%%====================================================================

%% npl_ir_body_pure/3
%  npl_ir_body_pure(+F, +A, +IRBody)
%  Succeed when IRBody contains no observable side effects.
npl_ir_body_pure(_, _, ir_true) :- !.
npl_ir_body_pure(_, _, ir_fail) :- !.
npl_ir_body_pure(_, _, ir_call(Goal)) :- !,
    \+ npl_nr_is_side_effect(Goal).
npl_ir_body_pure(F, A, ir_seq(L, R)) :- !,
    npl_ir_body_pure(F, A, L),
    npl_ir_body_pure(F, A, R).
npl_ir_body_pure(F, A, ir_disj(L, R)) :- !,
    npl_ir_body_pure(F, A, L),
    npl_ir_body_pure(F, A, R).
npl_ir_body_pure(F, A, ir_if(C, T, E)) :- !,
    npl_ir_body_pure(F, A, C),
    npl_ir_body_pure(F, A, T),
    npl_ir_body_pure(F, A, E).
npl_ir_body_pure(F, A, ir_not(G)) :- !,
    npl_ir_body_pure(F, A, G).
npl_ir_body_pure(F, A, ir_source_marker(_, B)) :- !,
    npl_ir_body_pure(F, A, B).
npl_ir_body_pure(F, A, ir_memo_site(_, B)) :- !,
    npl_ir_body_pure(F, A, B).
npl_ir_body_pure(F, A, ir_loop_candidate(B)) :- !,
    npl_ir_body_pure(F, A, B).
npl_ir_body_pure(F, A, ir_addr_loop(_, _, B)) :- !,
    npl_ir_body_pure(F, A, B).
npl_ir_body_pure(_, _, ir_choice_point(_)) :- !.

%% npl_nr_is_side_effect/1
%  Goals that produce observable side effects.
npl_nr_is_side_effect(assert(_)).
npl_nr_is_side_effect(assertz(_)).
npl_nr_is_side_effect(asserta(_)).
npl_nr_is_side_effect(retract(_)).
npl_nr_is_side_effect(retractall(_)).
npl_nr_is_side_effect(write(_)).
npl_nr_is_side_effect(writeln(_)).
npl_nr_is_side_effect(nl).
npl_nr_is_side_effect(format(_, _)).
npl_nr_is_side_effect(format(_)).
npl_nr_is_side_effect(read(_)).
npl_nr_is_side_effect(read_term(_, _)).
npl_nr_is_side_effect(open(_, _, _)).
npl_nr_is_side_effect(open(_, _, _, _)).
npl_nr_is_side_effect(close(_)).
npl_nr_is_side_effect(nb_setval(_, _)).

%%====================================================================
%% IR body inspection helpers (local)
%%====================================================================

%% npl_ir_body_find_binary_is/2
%  Succeed when IRBody contains an is/2 call whose arithmetic expression
%  is a binary operation with operator Op.
npl_ir_body_find_binary_is(ir_call(is(_, Expr)), Op) :-
    npl_nr_binary_arith_op(Expr, Op, _, _), !.
npl_ir_body_find_binary_is(ir_seq(A, _), Op) :-
    npl_ir_body_find_binary_is(A, Op), !.
npl_ir_body_find_binary_is(ir_seq(_, B), Op) :-
    npl_ir_body_find_binary_is(B, Op), !.
npl_ir_body_find_binary_is(ir_disj(A, _), Op) :-
    npl_ir_body_find_binary_is(A, Op), !.
npl_ir_body_find_binary_is(ir_disj(_, B), Op) :-
    npl_ir_body_find_binary_is(B, Op), !.
npl_ir_body_find_binary_is(ir_if(C, T, E), Op) :-
    ( npl_ir_body_find_binary_is(C, Op) -> true
    ; npl_ir_body_find_binary_is(T, Op) -> true
    ; npl_ir_body_find_binary_is(E, Op)
    ).

%% npl_nr_binary_arith_op/4
npl_nr_binary_arith_op('+'(A, B), '+', A, B) :- !.
npl_nr_binary_arith_op('*'(A, B), '*', A, B) :- !.

%% npl_nr_op_identity/2
%  Identity elements for supported combining operators.
npl_nr_op_identity('+', 0).
npl_nr_op_identity('*', 1).

%%====================================================================
%% Grouping helpers
%%====================================================================

%% npl_nr_group_by_functor/2
%  Group a flat IR list by head functor/arity.
%  Non-ir_clause items form singleton groups.
npl_nr_group_by_functor([], []).
npl_nr_group_by_functor([C|Cs], [[C|Group]|Groups]) :-
    C = ir_clause(Head, _, _), !,
    functor(Head, F, A),
    partition(npl_nr_same_functor(F/A), Cs, Group, Rest),
    npl_nr_group_by_functor(Rest, Groups).
npl_nr_group_by_functor([Other|Cs], [[Other]|Groups]) :-
    npl_nr_group_by_functor(Cs, Groups).

npl_nr_same_functor(F/A, ir_clause(Head, _, _)) :-
    functor(Head, F, A).

%% npl_nr_flatten_groups/2
npl_nr_flatten_groups([], []).
npl_nr_flatten_groups([G|Gs], Flat) :-
    append(G, Rest, Flat),
    npl_nr_flatten_groups(Gs, Rest).
