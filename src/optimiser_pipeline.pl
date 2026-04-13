% optimiser_pipeline.pl — NeuroProlog Optimiser Pipeline (Stage 15)
%
% Combines all optimisation passes into a controlled, configurable pipeline.
%
% == Pass order ==
%
%   1.  semantic_annotation           — collect and report IR annotation metadata
%   2.  simplification                — apply simplification rules from the dictionary
%   3.  recurrence_detection          — detect and report recurrence patterns
%   2b. variable_instantiation        — convert var(Name) to actual Prolog variables
%   4.  gaussian_elimination          — Gaussian-elimination recursion transforms
%   5.  recursion_to_loop             — wrap structural nested bodies in ir_loop_candidate
%   6.  subterm_address_conversion    — convert ir_loop_candidate to ir_addr_loop
%   7.  nested_recursion_elimination  — memo-wrap pure and data-fold nested patterns
%   8.  memoisation_insertion         — insert ir_memo_site annotations for registered preds
%   9.  dict_learned_opt              — apply dictionary-based learned optimisation rules
%   10. final_simplification          — final simplification sweep
%   10b.arithmetic_inlining           — inline single-use arithmetic temporaries
%   11. neurocode_emission            — emit neurocode terms from optimised IR
%
% == Configuration ==
%
%   A pipeline config is a list of pass(Name, Enabled) terms.
%   npl_pipeline_default_config/1 returns the default (all passes enabled).
%   npl_pipeline_enable/3 and npl_pipeline_disable/3 modify a config.
%   npl_pipeline_is_enabled/2 tests whether a named pass is enabled.
%
% == Running the pipeline ==
%
%   npl_pipeline_run/4
%     Runs IR-transform passes 1-10; returns optimised IR and a report.
%
%   npl_pipeline_run_full/5
%     Runs all 11 passes; returns optimised IR, neurocode, and a report.
%
% == Report ==
%
%   Each pass appends a pass_report/3 term to the report list:
%     pass_report(PassName, Status, Info)
%       PassName — atom identifying the pass
%       Status   — applied | skipped
%       Info     — list of Key:Value annotation pairs
%
% == Benchmark harness ==
%
%   npl_pipeline_benchmark/4 measures wall-clock time for a pipeline run.

:- module(optimiser_pipeline, [
    npl_pipeline_run/4,
    npl_pipeline_run_full/5,
    npl_pipeline_default_config/1,
    npl_pipeline_enable/3,
    npl_pipeline_disable/3,
    npl_pipeline_is_enabled/2,
    npl_pipeline_report_print/1,
    npl_pipeline_benchmark/4,
    npl_pipeline_pass_names/1
]).

:- use_module(library(lists)).

:- use_module('./intermediate_codegen').
:- use_module('./gaussian_recursion').
:- use_module('./nested_recursion').
:- use_module('./memoisation').
:- use_module('./subterm_addressing').
:- use_module('./optimisation_dictionary').
:- use_module('./optimiser').
:- use_module('./codegen').

%%====================================================================
%% Pass ordering
%%====================================================================

%% npl_pipeline_pass_names/1
%  Return the canonical ordered list of pass name atoms.
npl_pipeline_pass_names([
    semantic_annotation,
    simplification,
    recurrence_detection,
    variable_instantiation,
    gaussian_elimination,
    recursion_to_loop,
    subterm_address_conversion,
    nested_recursion_elimination,
    memoisation_insertion,
    dict_learned_opt,
    final_simplification,
    arithmetic_inlining,
    neurocode_emission
]).

%%====================================================================
%% Default configuration
%%====================================================================

%% npl_pipeline_default_config/1
%  Return the default configuration with all passes enabled.
npl_pipeline_default_config(Config) :-
    npl_pipeline_pass_names(Names),
    maplist(npl_pipeline_pass_default, Names, Config).

npl_pipeline_pass_default(Name, pass(Name, true)).

%%====================================================================
%% Configuration helpers
%%====================================================================

%% npl_pipeline_enable/3
%  npl_pipeline_enable(+Name, +ConfigIn, -ConfigOut)
%  Enable the named pass in a configuration.
npl_pipeline_enable(Name, ConfigIn, ConfigOut) :-
    npl_pipeline_update_config(Name, true, ConfigIn, ConfigOut).

%% npl_pipeline_disable/3
%  npl_pipeline_disable(+Name, +ConfigIn, -ConfigOut)
%  Disable the named pass in a configuration.
npl_pipeline_disable(Name, ConfigIn, ConfigOut) :-
    npl_pipeline_update_config(Name, false, ConfigIn, ConfigOut).

%% npl_pipeline_update_config/4
npl_pipeline_update_config(_, _, [], []).
npl_pipeline_update_config(Name, Val, [pass(Name, _)|Rest], [pass(Name, Val)|Rest]) :- !.
npl_pipeline_update_config(Name, Val, [P|Rest], [P|Rest1]) :-
    npl_pipeline_update_config(Name, Val, Rest, Rest1).

%% npl_pipeline_is_enabled/2
%  npl_pipeline_is_enabled(+Name, +Config)
%  Succeed when the named pass is enabled in Config.
npl_pipeline_is_enabled(Name, Config) :-
    member(pass(Name, true), Config).

%%====================================================================
%% Pipeline runner — IR-transform passes (1-10)
%%====================================================================

%% npl_pipeline_run/4
%  npl_pipeline_run(+Config, +IR, -OptIR, -Report)
%  Run all enabled IR-transform passes (1-10) in order.
%  Produces an optimised IR list and a structured report.
npl_pipeline_run(Config, IR, OptIR, Report) :-
    npl_pipeline_ir_pass_names(IRPasses),
    npl_pipeline_run_passes(IRPasses, Config, IR, OptIR, [], RevReport),
    reverse(RevReport, Report).

%% npl_pipeline_ir_pass_names/1
%  Ordered list of IR-transform passes (neurocode_emission excluded).
npl_pipeline_ir_pass_names([
    semantic_annotation,
    simplification,
    recurrence_detection,
    variable_instantiation,
    gaussian_elimination,
    recursion_to_loop,
    subterm_address_conversion,
    nested_recursion_elimination,
    memoisation_insertion,
    dict_learned_opt,
    final_simplification,
    arithmetic_inlining
]).

%% npl_pipeline_run_passes/6
npl_pipeline_run_passes([], _, IR, IR, Acc, Acc).
npl_pipeline_run_passes([Pass|Passes], Config, IR, FinalIR, Acc, Report) :-
    ( npl_pipeline_is_enabled(Pass, Config) ->
        npl_pipeline_apply_pass(Pass, IR, IR1, PassInfo),
        PassReport = pass_report(Pass, applied, PassInfo)
    ;
        IR1 = IR,
        length(IR, N),
        PassReport = pass_report(Pass, skipped, [ir_items:N])
    ),
    npl_pipeline_run_passes(Passes, Config, IR1, FinalIR, [PassReport|Acc], Report).

%%====================================================================
%% Full pipeline runner — passes 1-11
%%====================================================================

%% npl_pipeline_run_full/5
%  npl_pipeline_run_full(+Config, +IR, -OptIR, -Neurocode, -Report)
%  Run all passes including neurocode emission.
npl_pipeline_run_full(Config, IR, OptIR, Neurocode, Report) :-
    npl_pipeline_run(Config, IR, OptIR, Report0),
    ( npl_pipeline_is_enabled(neurocode_emission, Config) ->
        npl_generate(OptIR, Neurocode),
        length(OptIR, N),
        EmitReport = pass_report(neurocode_emission, applied, [ir_items:N]),
        append(Report0, [EmitReport], Report)
    ;
        Neurocode = [],
        length(OptIR, N),
        append(Report0, [pass_report(neurocode_emission, skipped, [ir_items:N])], Report)
    ).

%%====================================================================
%% Individual pass implementations
%%====================================================================

%% Pass 1: semantic_annotation
%  Collect recursion-class and other annotations from IR info fields.
%  No structural transform is applied; this pass produces a report only.
npl_pipeline_apply_pass(semantic_annotation, IR, IR, Info) :-
    npl_pipeline_collect_annotations(IR, Annotations),
    length(IR, N),
    Info = [ir_items:N, annotations:Annotations].

npl_pipeline_collect_annotations([], []).
npl_pipeline_collect_annotations([ir_clause(Head, _, IRInfo)|Rest],
                                  [Sig:rc(RC)|Anns]) :- !,
    functor(Head, F, A),
    Sig = F/A,
    ( npl_ir_info_get(IRInfo, recursion_class, RC) -> true ; RC = none ),
    npl_pipeline_collect_annotations(Rest, Anns).
npl_pipeline_collect_annotations([_|Rest], Anns) :-
    npl_pipeline_collect_annotations(Rest, Anns).

%% Pass 2: simplification
%  Apply all dictionary simplification rules to IR.
npl_pipeline_apply_pass(simplification, IR, OptIR, Info) :-
    npl_opt_dict_rules(Rules),
    npl_pipeline_apply_rules(Rules, IR, OptIR),
    length(IR, NIn),
    length(OptIR, NOut),
    length(Rules, NRules),
    Info = [ir_items_in:NIn, ir_items_out:NOut, rules_available:NRules].

%% Pass 3: recurrence_detection
%  Detect recurrence patterns in each clause group; no IR transform.
npl_pipeline_apply_pass(recurrence_detection, IR, IR, Info) :-
    npl_pipeline_group_by_functor(IR, Groups),
    maplist(npl_pipeline_safe_extract_recurrence, Groups, Recs),
    length(IR, N),
    Info = [ir_items:N, recurrences:Recs].

npl_pipeline_safe_extract_recurrence(Group, Rec) :-
    ( Group = [ir_clause(_,_,_)|_] ->
        npl_extract_recurrence(Group, Rec)
    ;
        Rec = recurrence(none/0, none, info(reason:non_clause))
    ).

%% Pass 4: gaussian_elimination
%  Apply Gaussian-elimination recursion transforms to clause groups.
npl_pipeline_apply_pass(gaussian_elimination, IR, OptIR, Info) :-
    length(IR, NIn),
    npl_gaussian_reduce(IR, OptIR),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

%% Pass 5: recursion_to_loop
%  Wrap structural nested recursive bodies in ir_loop_candidate.
%  Only the nested_structural class is handled here; pure/data-fold
%  patterns are deferred to the nested_recursion_elimination pass.
npl_pipeline_apply_pass(recursion_to_loop, IR, OptIR, Info) :-
    length(IR, NIn),
    npl_pipeline_group_by_functor(IR, Groups),
    maplist(npl_pipeline_rtl_reduce_group, Groups, ReducedGroups),
    npl_pipeline_flatten_groups(ReducedGroups, IR1),
    maplist(npl_pipeline_simplify_clause, IR1, OptIR),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

npl_pipeline_rtl_reduce_group(Group, Reduced) :-
    ( npl_nested_classify(Group, nested_structural) ->
        ( npl_nested_apply_transform(Group, nested_structural, Transformed) ->
            Reduced = Transformed
        ; Reduced = Group
        )
    ; Reduced = Group
    ).

%% Pass 6: subterm_address_conversion
%  Convert ir_loop_candidate bodies matching the structural arg-descent
%  pattern to ir_addr_loop nodes.
npl_pipeline_apply_pass(subterm_address_conversion, IR, OptIR, Info) :-
    length(IR, NIn),
    npl_subterm_address_pass(IR, OptIR),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

%% Pass 7: nested_recursion_elimination
%  Eliminate nested_pure and nested_data_fold patterns via memo wrapping
%  and/or Gaussian/accumulator rewriting.
npl_pipeline_apply_pass(nested_recursion_elimination, IR, OptIR, Info) :-
    length(IR, NIn),
    npl_pipeline_group_by_functor(IR, Groups),
    maplist(npl_pipeline_nre_reduce_group, Groups, ReducedGroups),
    npl_pipeline_flatten_groups(ReducedGroups, IR1),
    maplist(npl_pipeline_simplify_clause, IR1, OptIR),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

npl_pipeline_nre_reduce_group(Group, Reduced) :-
    ( npl_nested_classify(Group, Class),
      ( Class = nested_pure ; Class = nested_data_fold(_) ) ->
        ( npl_nested_apply_transform(Group, Class, Transformed) ->
            Reduced = Transformed
        ; Reduced = Group
        )
    ; Reduced = Group
    ).

%% Pass 8: memoisation_insertion
%  Annotate IR info for predicates registered via npl_memo/1.
npl_pipeline_apply_pass(memoisation_insertion, IR, OptIR, Info) :-
    length(IR, NIn),
    npl_memoisation_pass(IR, OptIR),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

%% Pass 9: dict_learned_opt
%  Reapply all registered optimisation rules (learned patterns from dictionary).
npl_pipeline_apply_pass(dict_learned_opt, IR, OptIR, Info) :-
    npl_opt_dict_rules(Rules),
    npl_pipeline_apply_rules(Rules, IR, OptIR),
    length(Rules, NRules),
    length(IR, NIn),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut, rules_applied:NRules].

%% Pass 10: final_simplification
%  Final sweep with all dictionary simplification rules.
npl_pipeline_apply_pass(final_simplification, IR, OptIR, Info) :-
    npl_opt_dict_rules(Rules),
    npl_pipeline_apply_rules(Rules, IR, OptIR),
    length(IR, NIn),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

%% Pass variable_instantiation: convert var(Name) compound terms to Prolog vars.
%  Must run after simplification (which matches on var/1 ground terms safely)
%  and before gaussian_elimination (which requires actual Prolog variables for
%  copy_term-based structural analysis).
npl_pipeline_apply_pass(variable_instantiation, IR, OptIR, Info) :-
    npl_ir_instantiate_all(IR, OptIR),
    length(IR, N),
    Info = [ir_items:N].

%% Pass arithmetic_inlining: inline single-use arithmetic temporaries.
%  Removes intermediate variables of the form  V is Expr  when V is not a
%  head variable and appears exactly once in subsequent body goals.
npl_pipeline_apply_pass(arithmetic_inlining, IR, OptIR, Info) :-
    npl_arith_inline_pass(IR, OptIR),
    length(IR, NIn),
    length(OptIR, NOut),
    Info = [ir_items_in:NIn, ir_items_out:NOut].

%%====================================================================
%% Rule application helpers
%%====================================================================

npl_pipeline_apply_rules([], IR, IR).
npl_pipeline_apply_rules([Rule|Rules], IR, OptIR) :-
    ( npl_opt_rule(Rule, Pattern, Replacement) ->
        npl_pipeline_transform_ir(IR, Pattern, Replacement, IR1)
    ; IR1 = IR
    ),
    npl_pipeline_apply_rules(Rules, IR1, OptIR).

npl_pipeline_transform_ir([], _, _, []).
npl_pipeline_transform_ir([Node|Nodes], Pat, Rep, [Opt|Opts]) :-
    npl_pipeline_rewrite_term(Node, Pat, Rep, Opt),
    npl_pipeline_transform_ir(Nodes, Pat, Rep, Opts).

npl_pipeline_rewrite_term(Term, Pattern, Replacement, Result) :-
    copy_term(Pattern-Replacement, P-R),
    Term = P, !,
    Result = R.
npl_pipeline_rewrite_term(ir_clause(H, B, I), Pat, Rep,
                           ir_clause(H, B1, I)) :- !,
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_seq(A, B), Pat, Rep, ir_seq(A1, B1)) :- !,
    npl_pipeline_rewrite_term(A, Pat, Rep, A1),
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_disj(A, B), Pat, Rep, ir_disj(A1, B1)) :- !,
    npl_pipeline_rewrite_term(A, Pat, Rep, A1),
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_if(C, T, E), Pat, Rep, ir_if(C1, T1, E1)) :- !,
    npl_pipeline_rewrite_term(C, Pat, Rep, C1),
    npl_pipeline_rewrite_term(T, Pat, Rep, T1),
    npl_pipeline_rewrite_term(E, Pat, Rep, E1).
npl_pipeline_rewrite_term(ir_not(G), Pat, Rep, ir_not(G1)) :- !,
    npl_pipeline_rewrite_term(G, Pat, Rep, G1).
npl_pipeline_rewrite_term(ir_source_marker(Pos, B), Pat, Rep,
                           ir_source_marker(Pos, B1)) :- !,
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_memo_site(H, B), Pat, Rep,
                           ir_memo_site(H, B1)) :- !,
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_loop_candidate(B), Pat, Rep,
                           ir_loop_candidate(B1)) :- !,
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_addr_loop(TV, Sig, B), Pat, Rep,
                           ir_addr_loop(TV, Sig, B1)) :- !,
    npl_pipeline_rewrite_term(B, Pat, Rep, B1).
npl_pipeline_rewrite_term(ir_choice_point(Alts), Pat, Rep,
                           ir_choice_point(Alts1)) :- !,
    maplist(npl_pipeline_rewrite_term_alt(Pat, Rep), Alts, Alts1).
npl_pipeline_rewrite_term(Term, _, _, Term).

npl_pipeline_rewrite_term_alt(Pat, Rep, Alt, Alt1) :-
    npl_pipeline_rewrite_term(Alt, Pat, Rep, Alt1).

%%====================================================================
%% Grouping helpers (local)
%%====================================================================

%% npl_pipeline_group_by_functor/2
%  Group a flat IR list by head functor/arity.
%  Non-ir_clause items form singleton groups.
npl_pipeline_group_by_functor([], []).
npl_pipeline_group_by_functor([C|Cs], [[C|Group]|Groups]) :-
    C = ir_clause(Head, _, _), !,
    functor(Head, F, A),
    partition(npl_pipeline_same_functor(F/A), Cs, Group, Rest),
    npl_pipeline_group_by_functor(Rest, Groups).
npl_pipeline_group_by_functor([Other|Cs], [[Other]|Groups]) :-
    npl_pipeline_group_by_functor(Cs, Groups).

npl_pipeline_same_functor(F/A, ir_clause(Head, _, _)) :-
    functor(Head, F, A).

%% npl_pipeline_flatten_groups/2
npl_pipeline_flatten_groups([], []).
npl_pipeline_flatten_groups([G|Gs], Flat) :-
    append(G, Rest, Flat),
    npl_pipeline_flatten_groups(Gs, Rest).

%% npl_pipeline_simplify_clause/2
%  Simplify an ir_clause body using npl_nr_simplify_body/2.
npl_pipeline_simplify_clause(ir_clause(H, B, I), ir_clause(H, B1, I)) :- !,
    npl_nr_simplify_body(B, B1).
npl_pipeline_simplify_clause(Other, Other).

%%====================================================================
%% Report printing
%%====================================================================

%% npl_pipeline_report_print/1
%  Print a human-readable pipeline report to the current output stream.
npl_pipeline_report_print([]).
npl_pipeline_report_print([pass_report(Name, Status, Info)|Rest]) :-
    format('  [~w] ~w', [Status, Name]),
    ( Info = []
    -> nl
    ;  write(' — '),
       npl_pipeline_print_info(Info),
       nl
    ),
    npl_pipeline_report_print(Rest).

npl_pipeline_print_info([]).
npl_pipeline_print_info([K:V]) :- !,
    format('~w: ~w', [K, V]).
npl_pipeline_print_info([K:V|Rest]) :-
    format('~w: ~w, ', [K, V]),
    npl_pipeline_print_info(Rest).

%%====================================================================
%% Benchmark harness
%%====================================================================

%% npl_pipeline_benchmark/4
%  npl_pipeline_benchmark(+Config, +IR, -Report, -TimeMs)
%  Run the IR-transform pipeline and report wall-clock time in milliseconds.
npl_pipeline_benchmark(Config, IR, Report, TimeMs) :-
    get_time(T0),
    npl_pipeline_run(Config, IR, _OptIR, Report),
    get_time(T1),
    TimeMs is (T1 - T0) * 1000.0.
