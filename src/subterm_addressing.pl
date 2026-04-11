% subterm_addressing.pl — NeuroProlog Subterm-Address Looping (Stage 10)
%
% Replaces subterm traversal via recursion with bounded-address
% iteration using positional subterm references.
%
% A subterm address is a list of argument positions, e.g.
%   [1,2,3] means arg(1, arg(2, arg(3, Term))).
%
% === Stage 10: Subterm-Address Looping ===
%
%   npl_subterm_addr_bounded/3
%     Enumerates subterm addresses within a maximum-depth bound.  Used to
%     convert bounded pretty-printing and serialisation from recursive
%     descent to explicit address stepping.
%
%   npl_subterm_iter_bounded/4
%     Iterates over all bounded subterm addresses and applies a goal to
%     each (addr, subterm) pair, replacing recursive descent with a loop.
%
%   npl_addr_copy_term/2
%     Copies a term by walking all of its subterm addresses, replacing the
%     recursive copy_term pattern with address-based iteration.
%
%   npl_subterm_flatten_by_addr/2
%     Flattens a term to a list of atomic leaves by iterating addresses
%     rather than recursing.
%
%   npl_subterm_address_pass/2
%     IR optimisation pass.  Detects ir_loop_candidate bodies that contain
%     a structural arg/3 descent pattern and rewrites them to ir_addr_loop
%     nodes, eliminating the recursive call in favour of address iteration.

:- module(subterm_addressing, [
    npl_subterm_at/3,
    npl_subterm_set/4,
    npl_subterm_address_pass/2,
    npl_subterm_addresses/2,
    npl_subterm_addr_bounded/3,
    npl_subterm_iter_bounded/4,
    npl_addr_copy_term/2,
    npl_subterm_flatten_by_addr/2
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
%  Enumerate all subterm addresses in a term in BFS order.
%  The root address [] is first; sibling addresses precede their children.
npl_subterm_addresses(Term, Addresses) :-
    npl_subterm_addresses_queue([[]], Term, [], RevAddrs),
    reverse(RevAddrs, Addresses).

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

%%====================================================================
%% Bounded address enumeration (Stage 10)
%%====================================================================

%% npl_subterm_addr_bounded/3
%  npl_subterm_addr_bounded(+Term, +MaxDepth, -Addresses)
%  Enumerate all subterm addresses whose depth (length) is at most
%  MaxDepth.  Depth 0 means only the root address [].
%  This supports the "bounded output-character framework": caller can
%  choose MaxDepth to limit total traversal work.
npl_subterm_addr_bounded(Term, MaxDepth, Addresses) :-
    integer(MaxDepth), MaxDepth >= 0,
    npl_bounded_queue([[]], Term, MaxDepth, [], RevAddrs),
    reverse(RevAddrs, Addresses).

npl_bounded_queue([], _, _, Acc, Acc).
npl_bounded_queue([Addr|Queue], Term, MaxDepth, Acc, All) :-
    npl_subterm_at(Term, Addr, Sub),
    length(Addr, Depth),
    ( compound(Sub), Depth < MaxDepth ->
        Sub =.. [_|Args],
        length(Args, Arity),
        numlist(1, Arity, Positions),
        maplist(npl_extend_addr(Addr), Positions, NewAddrs),
        append(Queue, NewAddrs, Queue1)
    ; Queue1 = Queue
    ),
    npl_bounded_queue(Queue1, Term, MaxDepth, [Addr|Acc], All).

%%====================================================================
%% Address iterator (Stage 10)
%%====================================================================

%% npl_subterm_iter_bounded/4
%  npl_subterm_iter_bounded(+Term, +MaxDepth, :Goal, -Results)
%  Enumerate every subterm address within MaxDepth and call
%    call(Goal, Addr, Subterm, Result)
%  for each, collecting Results in BFS order.  This replaces recursive
%  structural descent with explicit address stepping.
:- meta_predicate npl_subterm_iter_bounded(+, +, 3, -).
npl_subterm_iter_bounded(Term, MaxDepth, Goal, Results) :-
    npl_subterm_addr_bounded(Term, MaxDepth, Addrs),
    maplist(npl_apply_addr_goal(Term, Goal), Addrs, Results).

npl_apply_addr_goal(Term, Goal, Addr, Result) :-
    npl_subterm_at(Term, Addr, Sub),
    call(Goal, Addr, Sub, Result).

%%====================================================================
%% Address-based term copy (Stage 10)
%%====================================================================

%% npl_addr_copy_term/2
%  npl_addr_copy_term(+Original, -Copy)
%  Copy a term by iterating its subterm addresses rather than recursing.
%  Equivalent to copy_term/2 for ground terms.  For terms with variables,
%  a fresh variable is placed at each variable address.
npl_addr_copy_term(Original, Copy) :-
    npl_subterm_addresses(Original, Addrs),
    npl_build_copy(Addrs, Original, Copy).

%  Start with a copy of the root structure (functor/arity), then fill in
%  leaves by iterating over non-compound (leaf) addresses.
npl_build_copy(Addrs, Original, Copy) :-
    % Obtain only the leaf addresses (deepest nodes where no further descent occurs).
    include(npl_is_leaf_addr(Original), Addrs, LeafAddrs),
    % Build the copy skeleton by iterating over leaves.
    npl_addr_copy_term_skeleton(Original, Skeleton),
    npl_set_leaves(LeafAddrs, Original, Skeleton, Copy).

%  npl_is_leaf_addr/2: true when the subterm at Addr is not compound.
npl_is_leaf_addr(Term, Addr) :-
    npl_subterm_at(Term, Addr, Sub),
    \+ compound(Sub).

%  npl_addr_copy_term_skeleton/2: build an isomorphic compound skeleton
%  with fresh variables at every leaf position.
npl_addr_copy_term_skeleton(Term, Skeleton) :-
    ( compound(Term) ->
        Term =.. [F|Args],
        maplist(npl_addr_copy_term_skeleton, Args, SArgs),
        Skeleton =.. [F|SArgs]
    ; Skeleton = _  % fresh variable
    ).

%  npl_set_leaves/4: set every leaf in Skeleton to the corresponding
%  value from Original, producing Copy.
npl_set_leaves([], _Original, Acc, Acc).
npl_set_leaves([Addr|Rest], Original, Acc0, Copy) :-
    npl_subterm_at(Original, Addr, Val),
    npl_subterm_set(Acc0, Addr, Val, Acc1),
    npl_set_leaves(Rest, Original, Acc1, Copy).

%%====================================================================
%% Address-based term flattening (Stage 10)
%%====================================================================

%% npl_subterm_flatten_by_addr/2
%  npl_subterm_flatten_by_addr(+Term, -Leaves)
%  Collect all atomic/variable leaves of Term in BFS order by
%  iterating subterm addresses instead of recursing.
npl_subterm_flatten_by_addr(Term, Leaves) :-
    npl_subterm_addresses(Term, Addrs),
    include(npl_is_leaf_addr(Term), Addrs, LeafAddrs),
    maplist(npl_subterm_at(Term), LeafAddrs, Leaves).

%%====================================================================
%% IR optimisation pass — recursion-to-loop transform (Stage 10)
%%====================================================================

%% npl_subterm_address_pass/2
%  npl_subterm_address_pass(+IR, -OptIR)
%  Walk the IR list and apply the subterm-address looping transform
%  to every ir_loop_candidate node whose body matches the structural
%  arg-descent pattern.  Other nodes are passed through unchanged.
npl_subterm_address_pass(IR, OptIR) :-
    maplist(npl_addr_transform_clause, IR, OptIR).

%% npl_addr_transform_clause/2
%  Transform a single ir_clause, rewriting eligible loop-candidate bodies.
npl_addr_transform_clause(ir_clause(Head, Body, Info),
                          ir_clause(Head, Body1, Info)) :-
    npl_addr_transform_body(Body, Body1), !.
npl_addr_transform_clause(Node, Node).

%% npl_addr_transform_body/2
%  Recursively walk IR body nodes and rewrite eligible sub-bodies.
%  An ir_loop_candidate whose body contains a structural arg/3 descent
%  is rewritten to ir_addr_loop/2.
npl_addr_transform_body(ir_loop_candidate(Body), Result) :-
    npl_is_arg_descent_body(Body, TermVar, RecFunctor/RecArity),
    !,
    Result = ir_addr_loop(TermVar, RecFunctor/RecArity, Body).
npl_addr_transform_body(ir_seq(A, B), ir_seq(A1, B1)) :-
    npl_addr_transform_body(A, A1),
    npl_addr_transform_body(B, B1).
npl_addr_transform_body(ir_disj(A, B), ir_disj(A1, B1)) :-
    npl_addr_transform_body(A, A1),
    npl_addr_transform_body(B, B1).
npl_addr_transform_body(ir_if(C, T, E), ir_if(C1, T1, E1)) :-
    npl_addr_transform_body(C, C1),
    npl_addr_transform_body(T, T1),
    npl_addr_transform_body(E, E1).
npl_addr_transform_body(ir_not(G), ir_not(G1)) :-
    npl_addr_transform_body(G, G1).
npl_addr_transform_body(ir_source_marker(Pos, B), ir_source_marker(Pos, B1)) :-
    npl_addr_transform_body(B, B1).
npl_addr_transform_body(ir_memo_site(H, B), ir_memo_site(H, B1)) :-
    npl_addr_transform_body(B, B1).
npl_addr_transform_body(Node, Node).

%% npl_is_arg_descent_body/3
%  npl_is_arg_descent_body(+Body, -TermVar, -RecSig)
%  Succeed when Body represents a structural arg-based descent pattern:
%    ir_seq(ir_call(arg(_, TermVar, Sub)), Continuation)
%  where Continuation contains a call F(…,Sub,…) with F \= arg.
%  Returns the term variable being descended and the recursive functor/arity.
npl_is_arg_descent_body(ir_seq(ir_call(arg(_, TermVar, Sub)), Continuation),
                        TermVar, F/A) :-
    npl_ir_contains_rec_on_sub(Continuation, Sub, F, A),
    F \= arg.
npl_is_arg_descent_body(ir_seq(Left, Right), TV, Sig) :-
    ( npl_is_arg_descent_body(Left, TV, Sig) ->
        true
    ; npl_is_arg_descent_body(Right, TV, Sig)
    ).

%  npl_ir_contains_rec_on_sub/4: find a call F(…,Sub,…) in the body.
npl_ir_contains_rec_on_sub(ir_call(Goal), Sub, F, A) :-
    callable(Goal),
    functor(Goal, F, A),
    Goal =.. [F|Args],
    memberchk(Sub, Args), !.
npl_ir_contains_rec_on_sub(ir_seq(Left, _), Sub, F, A) :-
    npl_ir_contains_rec_on_sub(Left, Sub, F, A), !.
npl_ir_contains_rec_on_sub(ir_seq(_, Right), Sub, F, A) :-
    npl_ir_contains_rec_on_sub(Right, Sub, F, A), !.
