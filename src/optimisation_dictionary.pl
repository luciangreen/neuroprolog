% optimisation_dictionary.pl — NeuroProlog Optimisation Dictionary (Stage 13)
%
% Stores named, versioned algorithm transformations.
% Each entry maps a recognised algorithmic pattern to a known
% efficient implementation.
%
% == Schema ==
%
%   npl_opt_entry(+Name, +Fields)
%   Fields is a list of key:value pairs:
%     category:Category          — optimisation category atom
%     trigger:TriggerPattern     — IR pattern that activates the rule
%     original:OriginalForm      — description of the unoptimised form
%     transformed:TransformedForm— description of the optimised form
%     proof:ProofTag             — proof or justification tag atom
%     conditions:Conditions      — list of applicability condition atoms
%     perf_notes:PerfNotes       — performance notes atom
%     cognitive_marker:CogMarker — cognitive-code-marker linkage atom (none if absent)
%     examples:Examples          — list of example(Input, Expected) terms
%     version:Version            — version integer; increment on change
%
% == Supported categories ==
%
%   memoisation              simplification           recursion_elimination
%   loop_conversion          accumulator_introduction  constant_folding
%   algebraic_reduction      gaussian_transform        subterm_address_iteration
%
% == Backward compatibility ==
%
%   npl_opt_rule/3 is preserved for the optimiser's term-rewriting pass.
%   npl_opt_entry/2 extends the schema with full Stage 13 metadata.
%   npl_opt_entry_to_rule/3 projects a rich entry to a rule triple where possible.
%
% == Persistence ==
%
%   npl_opt_dict_save/1 writes all dynamic entries and rules to a file.
%   npl_opt_dict_load/1 loads (consults) a previously saved dictionary file.

:- module(optimisation_dictionary, [
    npl_opt_rule/3,
    npl_opt_entry/2,
    npl_opt_dict_rules/1,
    npl_opt_dict_entries/1,
    npl_opt_register/3,
    npl_opt_entry_register/2,
    npl_opt_lookup/2,
    npl_opt_entry_lookup/2,
    npl_opt_entry_field/3,
    npl_opt_entry_to_rule/3,
    npl_opt_dict_load/1,
    npl_opt_dict_save/1
]).

:- dynamic npl_opt_rule/3.   % npl_opt_rule(+Name, +Pattern, +Replacement)
:- dynamic npl_opt_entry/2.  % npl_opt_entry(+Name, +Fields)

%%====================================================================
%% Simplification rules — term-rewriting (npl_opt_rule/3)
%%====================================================================

%% identity: call(true) → ir_true
npl_opt_rule(identity,
    ir_call(true),
    ir_true).

%% fail_branch: a disjunct that always fails can be removed
npl_opt_rule(fail_branch,
    ir_disj(ir_fail, B),
    B).

npl_opt_rule(fail_branch_right,
    ir_disj(A, ir_fail),
    A).

%% seq_true: sequencing with true is identity
npl_opt_rule(seq_true_left,
    ir_seq(ir_true, B),
    B).

npl_opt_rule(seq_true_right,
    ir_seq(A, ir_true),
    A).

%% if_true_cond: if true -> Then ; Else reduces to Then
npl_opt_rule(if_true,
    ir_if(ir_true, Then, _),
    Then).

%% if_fail_cond: if fail -> Then ; Else reduces to Else
npl_opt_rule(if_fail,
    ir_if(ir_fail, _, Else),
    Else).

%%====================================================================
%% Algebraic reduction rules — term-rewriting (npl_opt_rule/3)
%%====================================================================

%% add_zero_right: X + 0 → X
npl_opt_rule(add_zero_right,
    ir_call(is(R, X + 0)),
    ir_call(is(R, X))).

%% add_zero_left: 0 + X → X
npl_opt_rule(add_zero_left,
    ir_call(is(R, 0 + X)),
    ir_call(is(R, X))).

%% mul_one_right: X * 1 → X
npl_opt_rule(mul_one_right,
    ir_call(is(R, X * 1)),
    ir_call(is(R, X))).

%% mul_one_left: 1 * X → X
npl_opt_rule(mul_one_left,
    ir_call(is(R, 1 * X)),
    ir_call(is(R, X))).

%% mul_zero_right: _ * 0 → 0  (arithmetic purity assumed)
npl_opt_rule(mul_zero_right,
    ir_call(is(R, _ * 0)),
    ir_call(is(R, 0))).

%% mul_zero_left: 0 * _ → 0  (arithmetic purity assumed)
npl_opt_rule(mul_zero_left,
    ir_call(is(R, 0 * _)),
    ir_call(is(R, 0))).

%%====================================================================
%% Rich entries — npl_opt_entry/2 (Stage 13 dictionary schema)
%%====================================================================

%% ---- category: memoisation ----

npl_opt_entry(memo_pure_predicate,
    [ category:memoisation,
      trigger:ir_clause(head, ir_memo_site(head, body), info),
      original:'Predicate re-evaluated on every call',
      transformed:'Result cached after first ground call; ir_memo_site wraps body',
      proof:memoisation_referential_transparency,
      conditions:[pure_predicate, ground_key_at_callsite],
      perf_notes:'Cache hit is O(1) via first-argument indexing; eliminates redundant computation',
      cognitive_marker:'memoisation:hint',
      examples:[ example(fib(5,_), cached_after_first_call),
                 example(sum_list([1,2,3],_), cached_after_first_call) ],
      version:1 ]).

%% ---- category: simplification ----

npl_opt_entry(identity,
    [ category:simplification,
      trigger:ir_call(true),
      original:'ir_call(true) — calls the built-in true/0',
      transformed:'ir_true — canonical IR no-op node',
      proof:call_true_identity,
      conditions:[],
      perf_notes:'Removes an unnecessary call instruction',
      cognitive_marker:none,
      examples:[ example(ir_call(true), ir_true) ],
      version:1 ]).

npl_opt_entry(seq_true_left,
    [ category:simplification,
      trigger:ir_seq(ir_true, b),
      original:'ir_seq(ir_true, B) — sequence with trivial left operand',
      transformed:'B — trivial prefix removed',
      proof:seq_identity_left,
      conditions:[],
      perf_notes:'Removes one sequence node from the IR tree',
      cognitive_marker:none,
      examples:[ example(ir_seq(ir_true, ir_call(foo)), ir_call(foo)) ],
      version:1 ]).

npl_opt_entry(seq_true_right,
    [ category:simplification,
      trigger:ir_seq(a, ir_true),
      original:'ir_seq(A, ir_true) — sequence with trivial right operand',
      transformed:'A — trivial suffix removed',
      proof:seq_identity_right,
      conditions:[],
      perf_notes:'Removes one sequence node from the IR tree',
      cognitive_marker:none,
      examples:[ example(ir_seq(ir_call(foo), ir_true), ir_call(foo)) ],
      version:1 ]).

npl_opt_entry(fail_branch,
    [ category:simplification,
      trigger:ir_disj(ir_fail, b),
      original:'ir_disj(ir_fail, B) — left branch always fails',
      transformed:'B — failing branch eliminated',
      proof:disjunction_fail_identity,
      conditions:[],
      perf_notes:'Removes a dead branch; reduces choice-point overhead',
      cognitive_marker:none,
      examples:[ example(ir_disj(ir_fail, ir_call(ok)), ir_call(ok)) ],
      version:1 ]).

npl_opt_entry(if_true,
    [ category:simplification,
      trigger:ir_if(ir_true, then, else),
      original:'ir_if(ir_true, Then, Else) — condition always succeeds',
      transformed:'Then — else branch unreachable',
      proof:if_true_condition_reduction,
      conditions:[],
      perf_notes:'Eliminates branch test and dead else branch',
      cognitive_marker:none,
      examples:[ example(ir_if(ir_true, ir_call(a), ir_call(b)), ir_call(a)) ],
      version:1 ]).

npl_opt_entry(if_fail,
    [ category:simplification,
      trigger:ir_if(ir_fail, then, else),
      original:'ir_if(ir_fail, Then, Else) — condition always fails',
      transformed:'Else — then branch unreachable',
      proof:if_fail_condition_reduction,
      conditions:[],
      perf_notes:'Eliminates branch test and dead then branch',
      cognitive_marker:none,
      examples:[ example(ir_if(ir_fail, ir_call(a), ir_call(b)), ir_call(b)) ],
      version:1 ]).

%% ---- category: recursion_elimination ----

npl_opt_entry(linear_tail_recursion_tco,
    [ category:recursion_elimination,
      trigger:ir_clause(head, ir_seq(body, ir_call(rec_call)), info),
      original:'f(n) :- ..., f(n-1)  — tail-recursive with stack per call',
      transformed:'Loop form; recursive call replaced by jump to entry label',
      proof:tail_call_elimination_correctness,
      conditions:[tail_recursive, deterministic, last_call_is_self],
      perf_notes:'O(1) stack instead of O(n); enables very deep recursion',
      cognitive_marker:'recursion:tail',
      examples:[ example('last([_|T],E) :- last(T,E)', loop_form) ],
      version:1 ]).

%% ---- category: loop_conversion ----

npl_opt_entry(structural_loop_candidate,
    [ category:loop_conversion,
      trigger:ir_loop_candidate(body),
      original:'ir_loop_candidate(Body) — recursive structural descent via arg/3',
      transformed:'ir_addr_loop(TV, Sig, Body) — address-based BFS iteration',
      proof:subterm_address_iteration_correctness,
      conditions:[structural_arg_descent_detectable, arg_descent_pattern_in_body],
      perf_notes:'Replaces O(depth) stack with O(1) explicit iteration',
      cognitive_marker:'loop:structural',
      examples:[ example('walk(f(a,b)) :- arg(_,T,S), walk(S)', ir_addr_loop_form) ],
      version:1 ]).

%% ---- category: accumulator_introduction ----

npl_opt_entry(linear_accumulate_rewrite,
    [ category:accumulator_introduction,
      trigger:clause_group([base_clause, step_clause]),
      original:'f(n, R) :- f(n-1, R1), R is Op(R1, Extra)  — reversal needed',
      transformed:'f(n, R) :- f_gauss_acc(n, Id, R)  — accumulator-passing form',
      proof:gaussian_accumulator_correctness,
      conditions:[ linear_accumulate_pattern,
                   op_in_set([+, *]),
                   identity_matches_base_result ],
      perf_notes:'Converts O(n) stack to O(1) accumulator; enables tail-call opt',
      cognitive_marker:'accumulator:linear',
      examples:[ example('sum([],0). sum([H|T],S) :- sum(T,S1), S is S1+H',
                         accumulator_form) ],
      version:1 ]).

%% ---- category: constant_folding ----

npl_opt_entry(arith_ground_eval,
    [ category:constant_folding,
      trigger:ir_call(is(result, ground_expr)),
      original:'ir_call(is(R, Expr)) — arithmetic evaluated at runtime each call',
      transformed:'ir_call(is(R, Value)) — Value is the precomputed result',
      proof:arithmetic_purity_ground_evaluation,
      conditions:[ expression_ground_at_compile_time,
                   no_arithmetic_instantiation_error ],
      perf_notes:'Eliminates runtime arithmetic; expression becomes an inline constant',
      cognitive_marker:'const:fold',
      examples:[ example(ir_call(is(r, 3+5)), ir_call(is(r, 8))),
                 example(ir_call(is(r, 2*10)), ir_call(is(r, 20))) ],
      version:1 ]).

%% ---- category: algebraic_reduction ----

npl_opt_entry(add_zero_right,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, x+0)),
      original:'ir_call(is(R, X + 0)) — add zero to expression',
      transformed:'ir_call(is(R, X)) — additive identity eliminated',
      proof:additive_identity_law,
      conditions:[arithmetic_purity_required],
      perf_notes:'Removes one addition operation',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, n+0)), ir_call(is(r, n))) ],
      version:1 ]).

npl_opt_entry(add_zero_left,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, 0+x)),
      original:'ir_call(is(R, 0 + X)) — add expression to zero',
      transformed:'ir_call(is(R, X)) — additive identity eliminated',
      proof:additive_identity_law,
      conditions:[arithmetic_purity_required],
      perf_notes:'Removes one addition operation',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, 0+n)), ir_call(is(r, n))) ],
      version:1 ]).

npl_opt_entry(mul_one_right,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, x*1)),
      original:'ir_call(is(R, X * 1)) — multiply expression by one',
      transformed:'ir_call(is(R, X)) — multiplicative identity eliminated',
      proof:multiplicative_identity_law,
      conditions:[arithmetic_purity_required],
      perf_notes:'Removes one multiplication operation',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, n*1)), ir_call(is(r, n))) ],
      version:1 ]).

npl_opt_entry(mul_one_left,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, 1*x)),
      original:'ir_call(is(R, 1 * X)) — multiply one by expression',
      transformed:'ir_call(is(R, X)) — multiplicative identity eliminated',
      proof:multiplicative_identity_law,
      conditions:[arithmetic_purity_required],
      perf_notes:'Removes one multiplication operation',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, 1*n)), ir_call(is(r, n))) ],
      version:1 ]).

npl_opt_entry(mul_zero_right,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, x*0)),
      original:'ir_call(is(R, X * 0)) — multiply expression by zero',
      transformed:'ir_call(is(R, 0)) — zero annihilation',
      proof:multiplicative_zero_law,
      conditions:[arithmetic_purity_required, no_expression_side_effects],
      perf_notes:'Eliminates expression evaluation and multiplication',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, n*0)), ir_call(is(r, 0))) ],
      version:1 ]).

npl_opt_entry(mul_zero_left,
    [ category:algebraic_reduction,
      trigger:ir_call(is(r, 0*x)),
      original:'ir_call(is(R, 0 * X)) — multiply zero by expression',
      transformed:'ir_call(is(R, 0)) — zero annihilation',
      proof:multiplicative_zero_law,
      conditions:[arithmetic_purity_required, no_expression_side_effects],
      perf_notes:'Eliminates expression evaluation and multiplication',
      cognitive_marker:none,
      examples:[ example(ir_call(is(r, 0*n)), ir_call(is(r, 0))) ],
      version:1 ]).

%% ---- category: gaussian_transform ----

npl_opt_entry(gaussian_linear_accumulate,
    [ category:gaussian_transform,
      trigger:clause_group([base_clause, step_clause]),
      original:'Mutually linear recurrence f(n) = Op(f(n-1), extra(n)) with identity Id',
      transformed:'Accumulator form derived via Gaussian row-echelon analysis',
      proof:gaussian_elimination_row_echelon_correctness,
      conditions:[ linear_accumulate_pattern,
                   op_associative,
                   identity_verified_against_base ],
      perf_notes:'Row reduction reveals reducible coefficient matrix; enables accumulator rewrite',
      cognitive_marker:'recursion:gaussian',
      examples:[ example('sum([],0). sum([H|T],S) :- sum(T,S1), S is S1+H',
                         gauss_acc_form),
                 example('prod([],1). prod([H|T],P) :- prod(T,P1), P is P1*H',
                         gauss_acc_form) ],
      version:1 ]).

%% ---- category: subterm_address_iteration ----

npl_opt_entry(arg_descent_to_addr_loop,
    [ category:subterm_address_iteration,
      trigger:ir_seq(ir_call(arg(n, term_var, sub)), continuation),
      original:'Recursive structural descent: arg/3 followed by recursive self-call on Sub',
      transformed:'ir_addr_loop(TermVar, F/A, Body) — BFS address enumeration loop',
      proof:subterm_bfs_completeness,
      conditions:[ arg_descent_pattern_present,
                   continuation_calls_f_on_sub,
                   functor_is_not_arg ],
      perf_notes:'Replaces O(depth)-stack recursion with O(1) iterative address stepping',
      cognitive_marker:'loop:addr',
      examples:[ example(walk(T) :- arg(_,T,S), walk(S), ir_addr_loop_form) ],
      version:1 ]).

%%====================================================================
%% Dictionary query predicates
%%====================================================================

%% npl_opt_dict_rules/1
%  Return list of all registered rule names.
npl_opt_dict_rules(Rules) :-
    findall(Name, npl_opt_rule(Name, _, _), Rules).

%% npl_opt_dict_entries/1
%  Return list of all registered entry names.
npl_opt_dict_entries(Names) :-
    findall(Name, npl_opt_entry(Name, _), Names).

%% npl_opt_register/3
%  Register a new optimisation rule.
npl_opt_register(Name, Pattern, Replacement) :-
    ( npl_opt_rule(Name, _, _) ->
        retract(npl_opt_rule(Name, _, _)),
        assertz(npl_opt_rule(Name, Pattern, Replacement))
    ; assertz(npl_opt_rule(Name, Pattern, Replacement))
    ).

%% npl_opt_entry_register/2
%  Register a new rich optimisation entry.  Replaces any existing entry
%  with the same name.  Also registers a corresponding npl_opt_rule/3
%  if trigger and transformed fields can be projected to a rule pair.
npl_opt_entry_register(Name, Fields) :-
    ( npl_opt_entry(Name, _) ->
        retract(npl_opt_entry(Name, _))
    ; true
    ),
    assertz(npl_opt_entry(Name, Fields)),
    ( npl_opt_entry_to_rule(Name, Pattern, Replacement) ->
        npl_opt_register(Name, Pattern, Replacement)
    ; true
    ).

%% npl_opt_lookup/2
%  Look up the optimisation rule registered under Name.
npl_opt_lookup(Name, opt(Name, Pattern, Replacement)) :-
    npl_opt_rule(Name, Pattern, Replacement).

%% npl_opt_entry_lookup/2
%  Look up the rich entry registered under Name.
npl_opt_entry_lookup(Name, entry(Name, Fields)) :-
    npl_opt_entry(Name, Fields).

%% npl_opt_entry_field/3
%  npl_opt_entry_field(+Fields, +Key, -Value)
%  Retrieve the value of a named field from an entry's field list.
npl_opt_entry_field(Fields, Key, Value) :-
    member(Key:Value, Fields).

%% npl_opt_entry_to_rule/3
%  npl_opt_entry_to_rule(+Name, -Pattern, -Replacement)
%  Project a rich entry to a rule triple when an npl_opt_rule/3 fact
%  with the same name already exists.
npl_opt_entry_to_rule(Name, Pattern, Replacement) :-
    npl_opt_rule(Name, Pattern, Replacement).

%%====================================================================
%% Persistence — load / save
%%====================================================================

%% npl_opt_dict_save/1
%  npl_opt_dict_save(+File)
%  Write all currently registered npl_opt_entry/2 and npl_opt_rule/3
%  facts to File as valid Prolog terms (one fact per line, sorted by name).
%  The saved file can be reloaded with npl_opt_dict_load/1.
npl_opt_dict_save(File) :-
    setup_call_cleanup(
        open(File, write, Stream),
        npl_opt_dict_write(Stream),
        close(Stream)
    ).

npl_opt_dict_write(Stream) :-
    format(Stream, '%% NeuroProlog Optimisation Dictionary — saved snapshot~n', []),
    format(Stream, ':- dynamic npl_opt_entry/2.~n', []),
    format(Stream, ':- dynamic npl_opt_rule/3.~n~n', []),
    forall(npl_opt_entry(Name, Fields),
           ( format(Stream, 'npl_opt_entry(', []),
             writeq(Stream, Name),
             write(Stream, ',\n    '),
             writeq(Stream, Fields),
             write(Stream, ').\n\n') )),
    forall(npl_opt_rule(Name, Pattern, Replacement),
           ( format(Stream, 'npl_opt_rule(', []),
             writeq(Stream, Name),
             write(Stream, ',\n    '),
             writeq(Stream, Pattern),
             write(Stream, ',\n    '),
             writeq(Stream, Replacement),
             write(Stream, ').\n\n') )).

%% npl_opt_dict_load/1
%  npl_opt_dict_load(+File)
%  Load a previously saved dictionary file, adding its entries and rules
%  to the running database.  Duplicate entries are replaced.
npl_opt_dict_load(File) :-
    setup_call_cleanup(
        open(File, read, Stream),
        npl_opt_dict_read_terms(Stream),
        close(Stream)
    ).

npl_opt_dict_read_terms(Stream) :-
    read_term(Stream, Term, []),
    ( Term == end_of_file -> true
    ; npl_opt_dict_assert_term(Term),
      npl_opt_dict_read_terms(Stream)
    ).

npl_opt_dict_assert_term(npl_opt_entry(Name, Fields)) :- !,
    ( npl_opt_entry(Name, _) -> retract(npl_opt_entry(Name, _)) ; true ),
    assertz(npl_opt_entry(Name, Fields)).
npl_opt_dict_assert_term(npl_opt_rule(Name, Pat, Rep)) :- !,
    npl_opt_register(Name, Pat, Rep).
npl_opt_dict_assert_term(:- _) :- !.  % skip directives in saved files
npl_opt_dict_assert_term(_).
