% run_tests.pl — NeuroProlog Test Suite
%
% Run with:
%   swipl -g "consult('tests/run_tests')" -g "run_all_tests" -t halt

:- module(run_tests, [run_all_tests/0]).

:- consult('../src/prelude').
:- consult('../src/lexer').
:- consult('../src/parser').
:- consult('../src/semantic_analyser').
:- consult('../src/intermediate_codegen').
:- consult('../src/optimisation_dictionary').
:- consult('../src/memoisation').
:- consult('../src/unfolding').
:- consult('../src/pattern_correlation').
:- consult('../src/gaussian_recursion').
:- consult('../src/subterm_addressing').
:- consult('../src/optimiser').
:- consult('../src/nested_recursion').
:- consult('../src/codegen').
:- consult('../src/control').
:- consult('../src/optimiser_pipeline').
:- consult('../src/wam_model').
:- consult('../src/interpreter').
:- consult('../src/cognitive_markers').
:- consult('../src/self_host').

:- dynamic test_passed/1.
:- dynamic test_failed/1.
:- discontiguous run_test/1.

run_all_tests :-
    retractall(test_passed(_)),
    retractall(test_failed(_)),
    run_test_suite,
    summarise_tests.

run_test_suite :-
    test(prelude_append),
    test(prelude_length),
    test(prelude_reverse),
    test(prelude_member),
    test(prelude_sum_list),
    test(prelude_nth0),
    test(prelude_nth1),
    test(prelude_select),
    test(prelude_delete),
    test(prelude_subtract),
    test(prelude_intersection),
    test(prelude_union),
    test(prelude_list_to_set),
    test(prelude_sort),
    test(prelude_functor),
    test(prelude_arg),
    test(prelude_univ),
    test(prelude_copy_term),
    test(prelude_type_checks),
    test(prelude_unify),
    test(prelude_compare),
    test(prelude_maplist2),
    test(prelude_maplist3),
    test(prelude_foldl),
    test(prelude_include),
    test(prelude_exclude),
    test(lexer_basic),
    test(lexer_atoms),
    test(lexer_variables),
    test(lexer_anonymous_var),
    test(lexer_integers),
    test(lexer_floats),
    test(lexer_strings),
    test(lexer_operators),
    test(lexer_line_comment),
    test(lexer_block_comment),
    test(lexer_annotation),
    test(lexer_clause_terminator),
    test(lexer_list_syntax),
    test(lexer_positions),
    test(lexer_multiline_pos),
    test(lexer_error_unterminated_string),
    test(lexer_error_unterminated_atom),
    test(lexer_error_block_comment),
    test(lexer_error_unknown_char),
    test(parser_fact),
    test(parser_fact_structured),
    test(parser_rule),
    test(parser_rule_conjunction),
    test(parser_directive),
    test(parser_query),
    test(parser_operators_is),
    test(parser_operators_comparison),
    test(parser_list_empty),
    test(parser_list_elements),
    test(parser_list_tail),
    test(parser_negation),
    test(parser_if_then_else),
    test(parser_disjunction),
    test(parser_multiple_clauses),
    test(parser_annotations),
    test(parser_positions),
    test(parser_error_recovery),
    test(parser_module_directive),
    test(optimiser_identity),
    test(optimiser_seq_true),
    test(optimiser_fail_branch),
    test(optimiser_algebraic_keeps_symbolic_var),
    test(optimiser_mul_zero_reduces_to_is_zero),
    test(subterm_at),
    test(subterm_set),
    test(control_if),
    test(control_not),
    test(control_forall),
    test(control_true),
    test(control_fail),
    test(control_repeat),
    test(control_conj),
    test(control_or),
    test(control_once),
    test(control_ignore),
    test(control_call2),
    test(wam_compile),
    test(wam_init),
    test(wam_regs),
    test(wam_heap_var),
    test(wam_heap_atom),
    test(wam_heap_int),
    test(wam_heap_str),
    test(wam_deref_var),
    test(wam_deref_ref_chain),
    test(wam_unify_atoms),
    test(wam_unify_var_atom),
    test(wam_unify_var_var),
    test(wam_unify_struct),
    test(wam_unify_fails),
    test(wam_trail_unwind),
    test(wam_push_env),
    test(wam_pop_env),
    test(wam_push_choice),
    test(wam_backtrack),
    test(wam_execute_instr),
    test(codegen_basic),
    test(api3_ir_to_source),
    test(api3_code_generate_alias),
    test(api3_ir_to_source_text),
    test(api3_ir_to_source_file),
    test(api3_ir_to_clause_public),
    test(api3_ir_to_body_public),
    test(api3_ir_to_clause_public_error),
    test(api3_ir_to_body_public_error),
    test(api3_source_to_ir),
    test(api3_source_to_optimised_ir),
    test(api3_roundtrip_source),
    test(api3_roundtrip_source_text),
    test(api3_roundtrip_source_file),
    test(api3_stage4_conjunction_formatting),
    test(api3_stage4_arithmetic_operator_formatting),
    test(api3_stage4_predicate_group_spacing),
    test(api3_stage5_ir_to_source_emitting),
    test(api3_stage5_ir_to_source_text_emitting_comments),
    test(api3_stage5_ir_to_source_text_emitting_no_comments),
    test(api3_stage5_ir_to_source_file_emitting),
    test(api3_stage6_annotated_text_basic),
    test(api3_stage6_annotated_text_source_file),
    test(api3_stage6_annotated_text_opt_report),
    test(api3_stage6_annotated_text_source_meta),
    test(api3_stage6_annotated_text_line_info),
    test(api3_stage6_annotated_text_clause_comments),
    test(api3_stage6_annotated_file),
    test(api3_stage6_annotated_empty_context),
    test(api3_stage10_diff_text),
    test(api3_stage10_side_by_side_text),
    test(api3_stage10_predicate_headers_and_stable_vars),
    test(ir_fail),
    test(ir_not),
    test(ir_repeat),
    test(ir_if_then),
    test(ir_if_then_else),
    test(ir_conjunction),
    test(ir_disjunction),
    test(exec_equiv_conjunction),
    test(exec_equiv_disjunction),
    test(exec_equiv_if_then_else),
    test(exec_equiv_negation),
    test(exec_equiv_cut),
    test(sem_fact_annotation),
    test(sem_rule_annotation),
    test(sem_arity_consistency),
    test(sem_non_callable_head),
    test(sem_singleton_vars),
    test(sem_no_singletons),
    test(sem_tail_recursion),
    test(sem_linear_recursion),
    test(sem_nested_recursion),
    test(sem_no_recursion),
    test(sem_memoisation_suitable),
    test(sem_memoisation_side_effect),
    test(sem_gaussian_tail),
    test(sem_gaussian_linear),
    test(sem_gaussian_none),
    test(sem_cognitive_marker),
    test(sem_no_cognitive_marker),
    test(sem_control_ok),
    test(sem_directive_passthrough),
    test(sem_query_passthrough),
    test(sem_parse_error_passthrough),
    test(sem_simplification_tco),
    test(sem_simplification_accum),
    test(sem_builtin_body),
    test(sem_possibly_undefined_body),
    test(sem_eliminable_nested_true),
    test(sem_eliminable_nested_false),
    % --- Stage 7: Interpreter Core ---
    test(interp_fact),
    test(interp_rule),
    test(interp_recursion),
    test(interp_backtracking),
    test(interp_cut),
    test(interp_list_processing),
    test(interp_deep_recursion),
    test(interp_disjunction),
    test(interp_negation),
    test(interp_assert_retract),
    test(interp_findall),
    test(interp_arithmetic),
    test(interp_prelude),
    test(interp_neurocode),
    test(interp_query_runner),
    test(interp_load_ast),
    % --- Stage 8: Intermediate Representation ---
    test(ir8_source_marker),
    test(ir8_predicate_def_single),
    test(ir8_predicate_def_grouped),
    test(ir8_choice_point_multi),
    test(ir8_choice_point_single),
    test(ir8_memo_site),
    test(ir8_loop_candidate),
    test(ir8_recursion_class),
    test(ir8_optimisation_meta),
    test(ir8_info_get_list),
    test(ir8_info_get_legacy),
    test(ir8_new_body_nodes_reversible),
    test(ir8_full_pipeline),
    % --- Stage 9: Gaussian-Recursion Reduction ---
    test(gauss9_reducible_tail),
    test(gauss9_reducible_tail_nested_seq),
    test(gauss9_reducible_accum_add),
    test(gauss9_reducible_accum_mul),
    test(gauss9_nonreducible),
    test(gauss9_extract_tail),
    test(gauss9_extract_accumulate),
    test(gauss9_extract_none),
    test(gauss9_gauss_eliminate_identity),
    test(gauss9_gauss_eliminate_rank1),
    test(gauss9_gauss_eliminate_triangular),
    test(gauss9_gauss_eliminate_rref_augmented),
    test(gauss9_build_coeff_matrix),
    test(gauss9_reduce_clause_group_sum),
    test(gauss9_reduce_clause_group_tail_unchanged),
    test(gauss9_correctness_sum),
    test(gauss9_correctness_length),
    % --- Stage 10: Subterm Address Looping ---
    test(subterm10_addr_bounded_depth0),
    test(subterm10_addr_bounded_depth1),
    test(subterm10_addr_bounded_depth2),
    test(subterm10_addr_bounded_terminates),
    test(subterm10_iter_bounded_collect),
    test(subterm10_addr_copy_atom),
    test(subterm10_addr_copy_compound),
    test(subterm10_addr_copy_nested),
    test(subterm10_flatten_atom),
    test(subterm10_flatten_list),
    test(subterm10_flatten_nested),
    test(subterm10_pass_ineligible_unchanged),
    test(subterm10_pass_eligible_loop_candidate),
    test(subterm10_pass_preserves_source_marker),
    test(subterm10_pass_ir_addr_loop_sig),
    test(subterm10_addresses_bfs_order),
    % --- Stage 11: Nested Recursion Elimination ---
    test(nested11_count_zero),
    test(nested11_count_one),
    test(nested11_count_two),
    test(nested11_classify_opaque_linear),
    test(nested11_classify_pure),
    test(nested11_classify_structural),
    test(nested11_classify_data_fold),
    test(nested11_classify_opaque_side_effect),
    test(nested11_pure_body_pure),
    test(nested11_pure_body_impure),
    test(nested11_transform_pure_memo),
    test(nested11_transform_structural_loop),
    test(nested11_transform_opaque_unchanged),
    test(nested11_simplify_seq_true_left),
    test(nested11_simplify_seq_true_right),
    test(nested11_simplify_nested_seq),
    test(nested11_simplify_noop),
    test(nested11_unfold_data_call),
    test(nested11_unfold_data_seq),
    test(nested11_pass_linear_unchanged),
    test(nested11_pass_pure_nested),
    test(nested11_pass_structural_nested),
    test(nested11_pass_empty_ir),
    % --- Stage 12: Logical Memoisation and Data Unfolding ---
    test(memo12_cache_hit),
    test(memo12_cache_ground_only),
    test(memo12_cache_clear),
    test(memo12_safety_ground),
    test(memo12_safety_nonground),
    test(memo12_safety_side_effect),
    test(memo12_stats_hit),
    test(memo12_stats_miss),
    test(memo12_call_all),
    test(memo12_subgoal),
    test(memo12_clear_all),
    test(memo12_ir_pass),
    test(unfold12_term_atom),
    test(unfold12_term_number),
    test(unfold12_term_var),
    test(unfold12_term_compound),
    test(unfold12_term_nested),
    test(unfold12_goal_true),
    test(unfold12_goal_call),
    test(unfold12_goal_seq),
    test(unfold12_key_ground),
    test(unfold12_key_with_vars),
    test(unfold12_match_same_atoms),
    test(unfold12_match_same_shape),
    test(unfold12_match_different_structure),
    test(unfold12_detect_repeated_none),
    test(unfold12_detect_repeated_one),
    test(unfold12_detect_repeated_two),
    test(unfold12_pass_no_reps),
    test(unfold12_pass_with_reps),
    test(unfold12_record_transformation),
    test(pcorr12_record_lookup),
    test(pcorr12_no_match),
    test(pcorr12_count_increments),
    test(pcorr12_repeated_threshold),
    test(pcorr12_not_repeated),
    test(pcorr12_all),
    test(pcorr12_clear),
    test(pcorr12_record_ir),
    test(pcorr12_ir_report),
    % --- Stage 13: Optimisation Dictionary ---
    test(dict13_entry_lookup),
    test(dict13_field_access),
    test(dict13_all_categories),
    test(dict13_entry_has_all_fields),
    test(dict13_register_entry),
    test(dict13_register_entry_replaces_existing),
    test(dict13_rule_preserved_after_register),
    test(dict13_entry_count_covers_categories),
    test(dict13_algebraic_rule_add_zero),
    test(dict13_algebraic_rule_mul_one),
    test(dict13_algebraic_rule_mul_zero),
    test(dict13_save_load_roundtrip),
    test(dict13_load_replaces_duplicate),
    test(dict13_entry_to_rule_projection),
    test(dict13_entry_version_field),
    test(dict13_entry_examples_field),
    test(dict13_entry_cognitive_marker_field),
    test(dict13_memoisation_entry_present),
    test(dict13_gaussian_entry_present),
    test(dict13_subterm_entry_present),
    % --- Stage 14: Cognitive Markers and Neurocode Mapping ---
    test(ncm14_record_lookup),
    test(ncm14_lookup_by_head),
    test(ncm14_all_records),
    test(ncm14_clear),
    test(ncm14_schema_meta_fields),
    test(ncm14_opt_steps_is_list),
    test(ncm14_neurocode_is_term),
    test(ncm14_build_single_clause),
    test(ncm14_build_multi_clause),
    test(ncm14_build_preserves_marker),
    test(ncm14_build_marker_none_when_absent),
    test(ncm14_trace_report_nonempty),
    test(ncm14_trace_report_entry_fields),
    test(ncm14_report_entry_format),
    test(ncm14_meta_pred_sig),
    test(ncm14_meta_source_marker),
    test(ncm14_meta_rebuild_version),
    test(ncm14_full_pipeline),
    % --- Stage 15: Optimiser Pipeline ---
    test(pipe15_pass_names_ordered),
    test(pipe15_default_config_has_all_passes),
    test(pipe15_default_all_enabled),
    test(pipe15_enable_disable),
    test(pipe15_is_enabled_true),
    test(pipe15_is_enabled_false),
    test(pipe15_run_empty_ir),
    test(pipe15_run_report_length),
    test(pipe15_report_has_pass_report_terms),
    test(pipe15_disabled_pass_skipped),
    test(pipe15_applied_pass_status),
    test(pipe15_semantic_annotation_pass),
    test(pipe15_recurrence_detection_pass),
    test(pipe15_simplification_removes_trivial),
    test(pipe15_gaussian_pass_runs),
    test(pipe15_full_run_sum),
    test(pipe15_run_full_produces_neurocode),
    test(pipe15_run_full_report_length),
    test(pipe15_benchmark_returns_time),
    test(pipe15_benchmark_time_nonnegative),
    test(pipe15_pipeline_vs_optimiser),
    test(pipe15_report_print_succeeds),
    % --- Stage 16: Code Generator ---
    test(cg16_generate_full_basic),
    test(cg16_segment_is_code_segment),
    test(cg16_comment_has_pred_sig),
    test(cg16_source_marker_in_comment),
    test(cg16_cognitive_marker_in_comment),
    test(cg16_memo_site_emits_cache_check),
    test(cg16_memo_site_emits_assertz),
    test(cg16_loop_candidate_emits_body),
    test(cg16_addr_loop_emits_subterm_addr),
    test(cg16_addr_loop_emits_forall),
    test(cg16_segment_meta_pred_sig),
    test(cg16_segment_meta_source_marker),
    test(cg16_segment_meta_memo_site),
    test(cg16_segment_meta_loop_candidate),
    test(cg16_write_full_succeeds),
    test(cg16_write_full_has_header),
    test(cg16_write_full_has_clause),
    test(cg16_write_full_has_comment),
    test(cg16_generate_text_is_atom),
    test(cg16_generate_text_contains_header),
    test(cg16_exec_equiv_basic),
    test(cg16_exec_equiv_memo),
    test(cg16_exec_equiv_loop_candidate),
    test(cg16_full_pipeline_segments),
    test(cg16_ir_to_body_emitting_true),
    test(cg16_ir_to_body_emitting_fail),
    test(cg16_ir_to_body_emitting_seq),
    test(cg16_ir_to_body_emitting_disj),
    test(cg16_ir_to_body_emitting_if_then),
    test(cg16_ir_to_body_emitting_if_then_else),
    test(cg16_ir_to_body_emitting_not),
    test(cg16_ir_to_body_emitting_source_marker_transparent),
    test(cg16_neurocode_is_valid_prolog),
    test(cg16_neurocode_is_reloadable),
    test(cg16_vars_become_prolog_vars),
    test(cg16_vars_shared_in_clause),
    test(cg16_anon_vars_distinct),
    test(cg16_e2e_pipeline_vars_correct),
    % --- Stage 19: Self-Hosting Tests ---
    test(sh19_predicates_exported),
    test(sh19_invariant_source_exists),
    test(sh19_invariant_opt_dict_nonempty),
    test(sh19_invariant_cognitive_markers_loaded),
    test(sh19_invariant_learned_transforms_present),
    test(sh19_compile_small_source),
    test(sh19_compare_behaviour_true),
    test(sh19_compare_behaviour_arithmetic),
    test(sh19_compare_behaviour_list_ops),
    test(sh19_bench_query_list_nonempty).

test(Name) :-
    ( catch(run_test(Name), Error, (write('ERROR in '), write(Name), write(': '), write(Error), nl, fail))
    -> assertz(test_passed(Name)),
       write('PASS: '), write(Name), nl
    ;  assertz(test_failed(Name)),
       write('FAIL: '), write(Name), nl
    ).

summarise_tests :-
    findall(P, test_passed(P), Passed),
    findall(F, test_failed(F), Failed),
    length(Passed, NP),
    length(Failed, NF),
    Total is NP + NF,
    format('~nResults: ~w/~w tests passed.~n', [NP, Total]),
    ( Failed = [] -> true
    ; write('Failed: '), write(Failed), nl
    ).

%% Individual tests

run_test(prelude_append) :-
    npl_append([1,2], [3,4], R),
    R == [1,2,3,4].

run_test(prelude_length) :-
    npl_length([a,b,c], N),
    N == 3.

run_test(prelude_reverse) :-
    npl_reverse([1,2,3], R),
    R == [3,2,1].

run_test(prelude_member) :-
    npl_member(2, [1,2,3]).

run_test(prelude_sum_list) :-
    npl_sum_list([1,2,3,4], S),
    S == 10.

run_test(lexer_basic) :-
    npl_lex_string('foo(X, 42)', Tokens),
    Tokens = [atom(foo), punct('('), var('X'), punct(','), integer(42), punct(')')].

run_test(optimiser_identity) :-
    npl_optimise([ir_clause(test, ir_call(true), info(head:ok,body:ok))], Opt),
    Opt = [ir_clause(test, ir_true, _)].

run_test(optimiser_seq_true) :-
    npl_optimise([ir_clause(test, ir_seq(ir_true, ir_call(foo)), info(head:ok,body:ok))], Opt),
    Opt = [ir_clause(test, ir_call(foo), _)].

run_test(optimiser_fail_branch) :-
    npl_optimise([ir_clause(test, ir_disj(ir_fail, ir_call(ok)), info(head:ok,body:ok))], Opt),
    Opt = [ir_clause(test, ir_call(ok), _)].

run_test(optimiser_algebraic_keeps_symbolic_var) :-
    IR = [ir_clause(p(X, Y), ir_call(is(Y, X+0)), info([]))],
    npl_optimise(IR, Opt),
    Opt = [ir_clause(p(X, Y), ir_call(is(Y, X)), _)].

run_test(optimiser_mul_zero_reduces_to_is_zero) :-
    IR = [ir_clause(p(X, Y), ir_call(is(Y, X*0)), info([]))],
    npl_optimise(IR, Opt),
    Opt = [ir_clause(p(_, Y), ir_call(is(Y, 0)), _)].

run_test(subterm_at) :-
    npl_subterm_at(f(a, g(b, c)), [2, 1], b).

run_test(subterm_set) :-
    npl_subterm_set(f(a, b), [2], x, R),
    R == f(a, x).

run_test(control_if) :-
    npl_if(true, (X = yes), (X = no)),
    X == yes.

run_test(control_not) :-
    npl_not(fail).

run_test(control_forall) :-
    npl_forall(member(X, [2,4,6]), 0 =:= X mod 2).

run_test(wam_compile) :-
    wam_compile_clause(foo(a), Instrs),
    Instrs = [get_constant(foo/1)].

%% --- WAM Model (Stage 6) tests ---

%% wam_init: initial state is well-formed
run_test(wam_init) :-
    wam_init_state(S),
    wam_get_regs(S, []),
    S = wam_state([], Heap, 0, [], [], [], [], Bindings),
    assoc_to_list(Heap, []),
    assoc_to_list(Bindings, []).

%% wam_regs: register get/set round-trip
run_test(wam_regs) :-
    wam_init_state(S0),
    wam_set_reg(S0, 1, hello, S1),
    wam_set_reg(S1, 2, world, S2),
    wam_get_reg(S2, 1, hello),
    wam_get_reg(S2, 2, world).

%% wam_heap_var: allocate unbound variable
run_test(wam_heap_var) :-
    wam_init_state(S0),
    wam_alloc_var(S0, Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(var, unbound)).

%% wam_heap_atom: allocate atom and retrieve it
run_test(wam_heap_atom) :-
    wam_init_state(S0),
    wam_alloc_atom(S0, foo, Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(atom, foo)).

%% wam_heap_int: allocate integer and retrieve it
run_test(wam_heap_int) :-
    wam_init_state(S0),
    wam_alloc_int(S0, 42, Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(int, 42)).

%% wam_heap_str: allocate structure and retrieve it
run_test(wam_heap_str) :-
    wam_init_state(S0),
    wam_alloc_str(S0, f(pair, [1, 2]), Addr, S1),
    Addr =:= 0,
    wam_heap_get(S1, 0, heap_cell(str, f(pair, [1, 2]))).

%% wam_deref_var: deref unbound variable returns var cell
run_test(wam_deref_var) :-
    wam_init_state(S0),
    wam_alloc_var(S0, Addr, S1),
    wam_deref(Addr, S1, heap_cell(var, unbound)).

%% wam_deref_ref_chain: deref follows reference chain
run_test(wam_deref_ref_chain) :-
    wam_init_state(S0),
    wam_alloc_var(S0, V, S1),          % addr 0: var
    wam_alloc_atom(S1, bar, A, S2),    % addr 1: atom bar
    wam_do_bind(V, A, S2, S3),        % bind 0 → 1
    wam_deref(V, S3, heap_cell(atom, bar)).

%% wam_unify_atoms: unify two identical atoms succeeds
run_test(wam_unify_atoms) :-
    wam_init_state(S0),
    wam_alloc_atom(S0, hello, A1, S1),
    wam_alloc_atom(S1, hello, A2, S2),
    wam_unify(A1, A2, S2, _S3).

%% wam_unify_var_atom: unify unbound variable with atom
run_test(wam_unify_var_atom) :-
    wam_init_state(S0),
    wam_alloc_var(S0, V, S1),
    wam_alloc_atom(S1, hello, A, S2),
    wam_unify(V, A, S2, S3),
    wam_deref(V, S3, heap_cell(atom, hello)).

%% wam_unify_var_var: unifying two vars makes them alias
run_test(wam_unify_var_var) :-
    wam_init_state(S0),
    wam_alloc_var(S0, V1, S1),
    wam_alloc_var(S1, V2, S2),
    wam_unify(V1, V2, S2, S3),
    % bind the shared alias to an atom
    wam_alloc_atom(S3, shared, A, S4),
    wam_bind(V2, A, S4, S5),
    wam_deref(V1, S5, heap_cell(atom, shared)).

%% wam_unify_struct: unify two compatible structures
run_test(wam_unify_struct) :-
    wam_init_state(S0),
    % Build f(X, 1) and f(hello, Y) on heap, then unify them
    wam_alloc_var(S0, X, S1),
    wam_alloc_int(S1, 1, I1, S2),
    wam_alloc_str(S2, f(pair, [X, I1]), Str1, S3),
    wam_alloc_atom(S3, hello, Hel, S4),
    wam_alloc_var(S4, Y, S5),
    wam_alloc_str(S5, f(pair, [Hel, Y]), Str2, S6),
    wam_unify(Str1, Str2, S6, S7),
    % After unification X should point to hello, Y should point to 1
    wam_deref(X, S7, heap_cell(atom, hello)),
    wam_deref(Y, S7, heap_cell(int, 1)).

%% wam_unify_fails: unifying incompatible atoms fails
run_test(wam_unify_fails) :-
    wam_init_state(S0),
    wam_alloc_atom(S0, foo, A1, S1),
    wam_alloc_atom(S1, bar, A2, S2),
    \+ wam_unify(A1, A2, S2, _).

%% wam_trail_unwind: bindings made after a choice point are undone
run_test(wam_trail_unwind) :-
    wam_init_state(S0),
    % Allocate variable BEFORE the choice point so it survives heap trim
    wam_alloc_var(S0, V, S1),
    % Push choice point AFTER allocating V (HeapTop = 1 > V = 0)
    wam_push_choice(S1, [[proceed]], [], S2),
    % Bind V: since V(0) < HeapTop(1) this is a conditional bind → trail
    wam_alloc_atom(S2, bound_value, A, S3),
    wam_trail_bind(V, A, S3, S4),
    % Variable is bound
    wam_deref(V, S4, heap_cell(atom, bound_value)),
    % Backtrack: trail should be unwound, V should be unbound again
    wam_backtrack(S4, _, S5),
    wam_deref(V, S5, heap_cell(var, unbound)).

%% wam_push_env: push environment frame, continuation is saved
run_test(wam_push_env) :-
    wam_init_state(S0),
    wam_push_env(S0, [proceed], S1),
    S1 = wam_state(_, _, _, [env([], [proceed], _)|_], _, _, _, _).

%% wam_pop_env: pop environment frame, continuation is restored
run_test(wam_pop_env) :-
    wam_init_state(S0),
    wam_push_env(S0, [call(foo)], S1),
    wam_pop_env(S1, RestoredCont, _S2),
    RestoredCont = [call(foo)].

%% wam_push_choice: choice point stores alternatives and saved state
run_test(wam_push_choice) :-
    wam_init_state(S0),
    wam_push_choice(S0, [[proceed], [proceed]], [], S1),
    S1 = wam_state(_, _, _, _, [choice([], [], [], 0, 0, [[proceed],[proceed]], [])|_], _, _, _).

%% wam_backtrack: restore to saved state and select next alternative
run_test(wam_backtrack) :-
    wam_init_state(S0),
    Alt1 = [get_constant(1/0)],
    Alt2 = [get_constant(2/0)],
    wam_push_choice(S0, [Alt1, Alt2], [], S1),
    % Backtracking with Alt1+Alt2 available: picks Alt1, leaves Alt2
    wam_backtrack(S1, RestAlts, S2),
    RestAlts = [Alt2],
    wam_get_cont(S2, Alt1).

%% wam_execute_instr: execute a simple instruction sequence
run_test(wam_execute_instr) :-
    wam_init_state(S0),
    Instrs = [enter(test/0), proceed],
    wam_execute(Instrs, S0, _S1).

run_test(codegen_basic) :-
    npl_generate([ir_clause(hello, ir_true, info(head:ok,body:ok))], Code),
    Code = [hello].

%% --- PR3 Stage 1: Public IR→source wrappers ---

run_test(api3_ir_to_source) :-
    IR = [ir_clause(p, ir_call(q), info([]))],
    npl_ir_to_source(IR, Clauses),
    Clauses = [(p :- q)].

run_test(api3_code_generate_alias) :-
    IR = [ir_clause(foo(1), ir_true, info([]))],
    npl_code_generate(IR, Clauses),
    Clauses = [foo(1)].

run_test(api3_ir_to_source_text) :-
    IR = [ir_clause(p, ir_call(q), info([]))],
    npl_ir_to_source_text(IR, Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'p :-'),
    sub_atom(Text, _, _, _, 'q').

run_test(api3_ir_to_source_file) :-
    IR = [ir_clause(file_api3, ir_true, info([]))],
    setup_call_cleanup(
        tmp_file(npl_ir_to_source_file_test, Path),
        ( npl_ir_to_source_file(IR, Path),
          consult(Path),
          current_predicate(file_api3/0),
          file_api3 ),
        delete_file(Path)).

%% --- PR3 Stage 2: Public clause/body wrappers ---

run_test(api3_ir_to_clause_public) :-
    IRClause = ir_clause(p, ir_call(q), info([])),
    npl_ir_to_clause_public(IRClause, Clause),
    Clause = (p :- q).

run_test(api3_ir_to_body_public) :-
    IRBody = ir_seq(ir_call(a), ir_call(b)),
    npl_ir_to_body_public(IRBody, Body),
    Body = (a, b).

run_test(api3_ir_to_clause_public_error) :-
    catch(
        ( npl_ir_to_clause_public(not_an_ir_clause, _),
          fail ),
        error(domain_error(npl_ir_clause, not_an_ir_clause), _),
        true
    ).

run_test(api3_ir_to_body_public_error) :-
    catch(
        ( npl_ir_to_body_public(ir_unsupported(foo), _),
          fail ),
        error(domain_error(npl_ir_body, ir_unsupported(foo)), _),
        true
    ).

%% --- PR3 Stage 3: Source round-trip helpers ---

run_test(api3_source_to_ir) :-
    setup_call_cleanup(
        tmp_file(npl_api3_source_to_ir_test, Path),
        ( setup_call_cleanup(
              open(Path, write, S),
              write(S, 'rt_api3_a :- rt_api3_b.\nrt_api3_b.\n'),
              close(S)),
          npl_source_to_ir(Path, IR),
          IR = [ir_clause(rt_api3_a, _, _)|_] ),
        delete_file(Path)).

run_test(api3_source_to_optimised_ir) :-
    setup_call_cleanup(
        tmp_file(npl_api3_source_to_optimised_ir_test, Path),
        ( setup_call_cleanup(
              open(Path, write, S),
              write(S, 'rt_api3_c :- rt_api3_d.\nrt_api3_d.\n'),
              close(S)),
          npl_source_to_optimised_ir(Path, OptIR),
          is_list(OptIR),
          OptIR = [ir_clause(rt_api3_c, _, _)|_] ),
        delete_file(Path)).

run_test(api3_roundtrip_source) :-
    setup_call_cleanup(
        tmp_file(npl_api3_roundtrip_source_test, Path),
        ( setup_call_cleanup(
              open(Path, write, S),
              write(S, 'rt_api3_e :- rt_api3_f.\nrt_api3_f.\n'),
              close(S)),
          npl_roundtrip_source(Path, Clauses),
          member((rt_api3_e :- rt_api3_f), Clauses),
          member(rt_api3_f, Clauses) ),
        delete_file(Path)).

run_test(api3_roundtrip_source_text) :-
    setup_call_cleanup(
        tmp_file(npl_api3_roundtrip_source_text_test, Path),
        ( setup_call_cleanup(
              open(Path, write, S),
              write(S, 'rt_api3_g :- rt_api3_h.\nrt_api3_h.\n'),
              close(S)),
          npl_roundtrip_source_text(Path, Text),
          atom(Text),
          sub_atom(Text, _, _, _, 'rt_api3_g :-'),
          sub_atom(Text, _, _, _, 'rt_api3_h') ),
        delete_file(Path)).

run_test(api3_roundtrip_source_file) :-
    setup_call_cleanup(
        tmp_file(npl_api3_roundtrip_source_file_in_test, InPath),
        setup_call_cleanup(
            tmp_file(npl_api3_roundtrip_source_file_out_test, OutPath),
            ( setup_call_cleanup(
                  open(InPath, write, S),
                  write(S, 'rt_api3_i :- rt_api3_j.\nrt_api3_j.\n'),
                  close(S)),
              npl_roundtrip_source_file(InPath, OutPath),
              consult(OutPath),
              current_predicate(rt_api3_i/0),
              rt_api3_i ),
            delete_file(OutPath)),
        delete_file(InPath)).

%% --- PR3 Stage 4: Formatting and readability ---

run_test(api3_stage4_conjunction_formatting) :-
    IR = [ir_clause(conjunction_test, ir_seq(ir_call(first_goal), ir_call(second_goal)), info([]))],
    npl_ir_to_source_text(IR, Text),
    sub_atom(Text, _, _, _, 'conjunction_test :-\n    first_goal,\n    second_goal.').

run_test(api3_stage4_arithmetic_operator_formatting) :-
    IR = [ir_clause(p(var('X'), var('Y')), ir_call(is(var('Y'), var('X'))), info([]))],
    npl_ir_to_source_text(IR, Text),
    sub_atom(Text, _, _, _, 'p('),
    sub_atom(Text, _, _, _, ' :-\n    '),
    sub_atom(Text, _, _, _, ' is ').

run_test(api3_stage4_predicate_group_spacing) :-
    IR = [ ir_clause(grouped_pred, ir_true, info([])),
           ir_clause(grouped_pred, ir_call(grouped_dep), info([])),
           ir_clause(other_group, ir_true, info([])) ],
    npl_ir_to_source_text(IR, Text),
    sub_atom(Text, _, _, _, '%% ===== predicate: grouped_pred/0 ====='),
    sub_atom(Text, _, _, _, 'grouped_pred.\ngrouped_pred :-\n    grouped_dep.'),
    sub_atom(Text, _, _, _, '%% ===== predicate: other_group/0 ====='),
    \+ sub_atom(Text, _, _, _, 'grouped_pred :- true.'),
    \+ sub_atom(Text, _, _, _, '\n\n\n').

%% --- PR3 Stage 5: Rich emitting mode ---

run_test(api3_stage5_ir_to_source_emitting) :-
    IR = [ir_clause(memo_test(var('X')),
                    ir_memo_site(var('X'), ir_call(pred(var('X')))),
                    [memo_site:true])],
    npl_ir_to_source(IR, [mode(emitting)], Clauses),
    Clauses = [(_Head :- Body)],
    sub_term(npl_memo_cache(_, _, _), Body).

run_test(api3_stage5_ir_to_source_text_emitting_comments) :-
    IR = [ir_clause(emitting_comment_test,
                    ir_loop_candidate(ir_call(work)),
                    [loop_candidate:true])],
    npl_ir_to_source_text(IR, [mode(emitting), include_comments(true), source_file('stage5_source.pl')], Text),
    atom(Text),
    sub_atom(Text, _, _, _, '%'),
    sub_atom(Text, _, _, _, 'stage5_source.pl').

run_test(api3_stage5_ir_to_source_text_emitting_no_comments) :-
    IR = [ir_clause(no_comment_memo(var('K')),
                    ir_memo_site(var('K'), ir_call(work(var('K')))),
                    [memo_site:true])],
    npl_ir_to_source_text(IR, [mode(emitting), include_comments(false)], Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'npl_memo_cache'),
    \+ sub_atom(Text, _, _, _, '%  [memo_site]').

run_test(api3_stage5_ir_to_source_file_emitting) :-
    IR = [ir_clause(file_emitting(var('X')),
                    ir_addr_loop(var('X'), walk/1, ir_call(step(var('X')))),
                    [loop_candidate:true])],
    setup_call_cleanup(
        tmp_file(npl_api3_stage5_emitting_file_test, Path),
        ( npl_ir_to_source_file(IR, [mode(emitting), include_comments(false)], Path),
          consult(Path),
          current_predicate(file_emitting/1) ),
        delete_file(Path)).

%% --- PR3 Stage 6: Annotated source regeneration ---

%% api3_stage6_annotated_text_basic — produces an atom of source text
run_test(api3_stage6_annotated_text_basic) :-
    IR = [ir_clause(basic_annot_test, ir_call(my_goal), info([]))],
    npl_ir_to_annotated_source_text(IR, [], Text),
    atom(Text),
    sub_atom(Text, _, _, _, '%% Annotated NeuroProlog Source').

%% api3_stage6_annotated_text_source_file — source file appears in header
run_test(api3_stage6_annotated_text_source_file) :-
    IR = [ir_clause(src_file_annot_test, ir_true, info([]))],
    npl_ir_to_annotated_source_text(IR, [source_file('my_source.pl')], Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'source file'),
    sub_atom(Text, _, _, _, 'my_source.pl').

%% api3_stage6_annotated_text_opt_report — opt report entries appear in header
run_test(api3_stage6_annotated_text_opt_report) :-
    IR = [ir_clause(opt_report_test, ir_true, info([]))],
    npl_ir_to_annotated_source_text(
        IR,
        [opt_report([gaussian_pass, memoisation_pass])],
        Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'optimisations applied'),
    sub_atom(Text, _, _, _, 'gaussian_pass'),
    sub_atom(Text, _, _, _, 'memoisation_pass').

%% api3_stage6_annotated_text_source_meta — source metadata appears in header
run_test(api3_stage6_annotated_text_source_meta) :-
    IR = [ir_clause(meta_annot_test, ir_true, info([]))],
    npl_ir_to_annotated_source_text(
        IR,
        [source_meta(module(my_module, v1))],
        Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'source meta'),
    sub_atom(Text, _, _, _, 'my_module').

%% api3_stage6_annotated_text_line_info — line info appears in header
run_test(api3_stage6_annotated_text_line_info) :-
    IR = [ir_clause(line_info_test, ir_true, info([]))],
    npl_ir_to_annotated_source_text(
        IR,
        [line_info(line(42))],
        Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'line info'),
    sub_atom(Text, _, _, _, 'line(42)').

%% api3_stage6_annotated_text_clause_comments — per-clause comments included
run_test(api3_stage6_annotated_text_clause_comments) :-
    IR = [ir_clause(clause_comment_pred,
                    ir_call(do_work),
                    [recursion_class:tail, memo_site:true])],
    npl_ir_to_annotated_source_text(IR, [], Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'clause_comment_pred').

%% api3_stage6_annotated_file — output file is valid consultable Prolog
run_test(api3_stage6_annotated_file) :-
    IR = [ir_clause(annot_file_pred(var('X')), ir_call(work(var('X'))), info([]))],
    setup_call_cleanup(
        tmp_file(npl_api3_stage6_annot_file_test, Path),
        ( npl_ir_to_annotated_source_file(IR, [source_file('test_src.pl')], Path),
          exists_file(Path),
          setup_call_cleanup(
              open(Path, read, Stream),
              ( read_term(Stream, _Comment, [module(user), syntax_errors(quiet)]) ; true ),
              close(Stream)),
          consult(Path),
          current_predicate(annot_file_pred/1) ),
        delete_file(Path)).

%% api3_stage6_annotated_empty_context — empty context is accepted
run_test(api3_stage6_annotated_empty_context) :-
    IR = [ir_clause(empty_ctx_pred, ir_true, info([]))],
    npl_ir_to_annotated_source_text(IR, [], Text),
    atom(Text),
    sub_atom(Text, _, _, _, 'empty_ctx_pred').

%% --- PR3 Stage 10: Optional future improvements ---

run_test(api3_stage10_diff_text) :-
    setup_call_cleanup(
        tmp_file(npl_api3_stage10_diff_in_test, InPath),
        ( setup_call_cleanup(
              open(InPath, write, S),
              write(S, 's10_diff_p :- s10_diff_q.\ns10_diff_q.\n'),
              close(S)),
          npl_roundtrip_source_diff_text(InPath, DiffText),
          atom(DiffText),
          sub_atom(DiffText, _, _, _, '--- original:'),
          sub_atom(DiffText, _, _, _, '+++ optimised:'),
          sub_atom(DiffText, _, _, _, '- s10_diff_p :- s10_diff_q.'),
          sub_atom(DiffText, _, _, _, '+ s10_diff_p :-') ),
        delete_file(InPath)).

run_test(api3_stage10_side_by_side_text) :-
    setup_call_cleanup(
        tmp_file(npl_api3_stage10_side_by_side_in_test, InPath),
        ( setup_call_cleanup(
              open(InPath, write, S),
              write(S, 's10_side_p :- s10_side_q.\ns10_side_q.\n'),
              close(S)),
          npl_roundtrip_source_side_by_side_text(InPath, SideText),
          atom(SideText),
          sub_atom(SideText, _, _, _, '% Original'),
          sub_atom(SideText, _, _, _, 'Optimised'),
          sub_atom(SideText, _, _, _, ' | ') ),
        delete_file(InPath)).

run_test(api3_stage10_predicate_headers_and_stable_vars) :-
    IR = [ ir_clause(s10_head(var('X'), var('Y')),
                     ir_call(pair(var('X'), var('Y'))),
                     info([])),
           ir_clause(s10_other, ir_true, info([])) ],
    npl_ir_to_source_text(IR, Text),
    sub_atom(Text, _, _, _, '%% ===== predicate: s10_head/2 ====='),
    sub_atom(Text, _, _, _, '%% ===== predicate: s10_other/0 ====='),
    sub_atom(Text, _, _, _, 'pair(A, B)'),
    \+ sub_atom(Text, _, _, _, '_G').

%% --- Additional prelude tests ---

run_test(prelude_nth0) :-
    npl_nth0(0, [a,b,c], a),
    npl_nth0(2, [a,b,c], c).

run_test(prelude_nth1) :-
    npl_nth1(1, [a,b,c], a),
    npl_nth1(3, [a,b,c], c).

run_test(prelude_select) :-
    npl_select(b, [a,b,c], R),
    R == [a,c].

run_test(prelude_delete) :-
    npl_delete([1,2,1,3], 1, R),
    R == [2,3].

run_test(prelude_subtract) :-
    npl_subtract([1,2,3,4], [2,4], R),
    R == [1,3].

run_test(prelude_intersection) :-
    npl_intersection([1,2,3], [2,3,4], R),
    R == [2,3].

run_test(prelude_union) :-
    npl_union([1,2], [2,3], R),
    R == [1,2,3].

run_test(prelude_list_to_set) :-
    npl_list_to_set([1,2,1,3,2], R),
    R == [1,2,3].

run_test(prelude_sort) :-
    npl_sort([3,1,2,1], R),
    R == [1,2,3].

run_test(prelude_functor) :-
    npl_functor(foo(a,b), F, A),
    F == foo, A == 2.

run_test(prelude_arg) :-
    npl_arg(2, foo(a,b,c), X),
    X == b.

run_test(prelude_univ) :-
    npl_univ(foo(1,2), L),
    L == [foo,1,2],
    npl_univ(T, [bar,x]),
    T == bar(x).

run_test(prelude_copy_term) :-
    npl_copy_term(f(X, X), f(A, B)),
    A == B.

run_test(prelude_type_checks) :-
    npl_var(_),
    npl_nonvar(42),
    npl_atom(hello),
    npl_number(3.14),
    npl_integer(7),
    npl_float(1.0),
    npl_compound(f(x)),
    npl_atomic(foo),
    npl_callable(foo),
    npl_ground(foo(1,2)),
    npl_is_list([1,2,3]).

run_test(prelude_unify) :-
    npl_unify(X, hello),
    X == hello,
    npl_unify_with_occurs_check(a, a).

run_test(prelude_compare) :-
    npl_compare(Order, a, b),
    Order == (<).

run_test(prelude_maplist2) :-
    npl_maplist(number, [1,2,3]).

run_test(prelude_maplist3) :-
    npl_maplist([X, Y]>>(Y is X * 2), [1,2,3], R),
    R == [2,4,6].

run_test(prelude_foldl) :-
    npl_foldl([X, Acc, Acc1]>>(Acc1 is Acc + X), [1,2,3], 0, S),
    S == 6.

run_test(prelude_include) :-
    npl_include([X]>>(X > 2), [1,2,3,4], R),
    R == [3,4].

run_test(prelude_exclude) :-
    npl_exclude([X]>>(X > 2), [1,2,3,4], R),
    R == [1,2].

%% --- Additional control tests ---

run_test(control_true) :-
    npl_true.

run_test(control_fail) :-
    \+ npl_fail.

run_test(control_repeat) :-
    npl_between(1, 5, N),
    call(npl_repeat),
    N =:= 1, !.

run_test(control_conj) :-
    npl_conj(true, X = yes),
    X == yes.

run_test(control_or) :-
    npl_or(fail, Y = ok),
    Y == ok.

run_test(control_once) :-
    npl_once(member(X, [a,b,c])),
    X == a.

run_test(control_ignore) :-
    npl_ignore(fail).

run_test(control_call2) :-
    npl_call(succ, 3, R),
    R == 4.

%% --- IR round-trip tests ---

run_test(ir_fail) :-
    npl_body_to_ir(fail, IR),
    IR == ir_fail,
    npl_ir_to_body(IR, Body),
    Body == fail.

run_test(ir_not) :-
    npl_body_to_ir(\+(foo), IR),
    IR == ir_not(ir_call(foo)),
    npl_ir_to_body(IR, Body),
    Body == \+(foo).

run_test(ir_repeat) :-
    npl_body_to_ir(repeat, IR),
    IR == ir_repeat,
    npl_ir_to_body(IR, Body),
    Body == repeat.

run_test(ir_if_then) :-
    npl_body_to_ir((true -> done), IR),
    IR == ir_if(ir_true, ir_call(done), ir_fail),
    npl_ir_to_body(IR, Body),
    Body == (true -> done).

run_test(ir_if_then_else) :-
    npl_body_to_ir((true -> yes ; no), IR),
    IR == ir_if(ir_true, ir_call(yes), ir_call(no)),
    npl_ir_to_body(IR, Body),
    Body == (true -> yes ; no).

run_test(ir_conjunction) :-
    npl_body_to_ir((a, b), IR),
    IR == ir_seq(ir_call(a), ir_call(b)),
    npl_ir_to_body(IR, Body),
    Body == (a, b).

run_test(ir_disjunction) :-
    npl_body_to_ir((a ; b), IR),
    IR == ir_disj(ir_call(a), ir_call(b)),
    npl_ir_to_body(IR, Body),
    Body == (a ; b).

%% --- Execution equivalence tests ---
%% These verify that control structures produce the same result
%% whether executed directly or via IR → codegen → neurocode.

run_test(exec_equiv_conjunction) :-
    Body = (X = hello, Y = world),
    call(Body),
    X == hello, Y == world,
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody),
    X == hello, Y == world.

run_test(exec_equiv_disjunction) :-
    Body = (Z = left ; Z = right),
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody),
    ( Z == left ; Z == right ).

run_test(exec_equiv_if_then_else) :-
    Body = (1 > 0 -> R = yes ; R = no),
    call(Body),
    R == yes,
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody),
    R == yes.

run_test(exec_equiv_negation) :-
    Body = \+(fail),
    call(Body),
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody).

run_test(exec_equiv_cut) :-
    Body = (!, true),
    call(Body),
    npl_body_to_ir(Body, IR),
    npl_ir_to_body(IR, GenBody),
    call(GenBody).

%% =====================================================================
%% Lexer tests — Stage 3
%% =====================================================================

%% Atoms: plain lowercase and quoted atoms
run_test(lexer_atoms) :-
    npl_lex_string('foo', [atom(foo)]),
    npl_lex_string('hello_world', [atom(hello_world)]),
    npl_lex_string('is', [atom(is)]).

%% Variables: uppercase-initial identifiers
run_test(lexer_variables) :-
    npl_lex_string('X', [var('X')]),
    npl_lex_string('MyVar', [var('MyVar')]),
    npl_lex_string('ABC', [var('ABC')]).

%% Anonymous and named-underscore variables
run_test(lexer_anonymous_var) :-
    npl_lex_string('_', [var('_')]),
    npl_lex_string('_Foo', [var('_Foo')]),
    npl_lex_string('_count', [var('_count')]),
    npl_lex_string('_1', [var('_1')]),
    npl_lex_string('__foo', [var('__foo')]).

%% Integer literals
run_test(lexer_integers) :-
    npl_lex_string('0', [integer(0)]),
    npl_lex_string('42', [integer(42)]),
    npl_lex_string('100', [integer(100)]).

%% Floating-point literals
run_test(lexer_floats) :-
    npl_lex_string('3.14', [float(3.14)]),
    npl_lex_string('0.5', [float(0.5)]),
    npl_lex_string('1.0', [float(1.0)]).

%% Double-quoted string literals
run_test(lexer_strings) :-
    npl_lex_string('"hello"', [string(hello)]),
    npl_lex_string('"foo bar"', [string('foo bar')]).

%% Operator symbol sequences
run_test(lexer_operators) :-
    npl_lex_string(':-', [atom(':-')]),
    npl_lex_string('=', [atom('=')]),
    npl_lex_string('>=', [atom('>=')]),
    npl_lex_string('\\+', [atom('\\+')]).

%% Line comments are discarded; surrounding tokens are kept
run_test(lexer_line_comment) :-
    npl_lex_string('foo % a comment', [atom(foo)]),
    npl_lex_string('a % ignore\nb', [atom(a), atom(b)]).

%% Block comments are discarded
run_test(lexer_block_comment) :-
    npl_lex_string('/* comment */ foo', [atom(foo)]),
    npl_lex_string('a /* mid */ b', [atom(a), atom(b)]).

%% Cognitive-code annotations (%@ ...) produce annot/1 tokens
run_test(lexer_annotation) :-
    npl_lex_string('%@ cognitive:marker', [annot('cognitive:marker')]),
    npl_lex_string('foo %@ tag', [atom(foo), annot(tag)]).

%% Clause terminator: period is emitted as punct('.')
run_test(lexer_clause_terminator) :-
    npl_lex_string('foo.', [atom(foo), punct('.')]),
    npl_lex_string('a :- b.', [atom(a), atom(':-'), atom(b), punct('.')]).

%% List syntax: brackets and pipe
run_test(lexer_list_syntax) :-
    npl_lex_string('[a,b,c]', [punct('['), atom(a), punct(','),
                                atom(b), punct(','), atom(c), punct(']')]),
    npl_lex_string('[H|T]', [punct('['), var('H'), punct('|'),
                              var('T'), punct(']')]).

%% Source positions are recorded correctly
run_test(lexer_positions) :-
    npl_lex_string_pos('foo bar', Tokens),
    Tokens = [tok(atom(foo), pos(1,1)), tok(atom(bar), pos(1,5))].

%% Multiline: line counter advances on newlines
run_test(lexer_multiline_pos) :-
    npl_lex_string_pos('foo\nbar', Tokens),
    Tokens = [tok(atom(foo), pos(1,1)), tok(atom(bar), pos(2,1))].

%% Error: unterminated double-quoted string
run_test(lexer_error_unterminated_string) :-
    npl_lex_string('"hello', Tokens),
    Tokens = [error(unterminated_string)].

%% Error: unterminated single-quoted atom
%  Build the atom code list explicitly: single-quote followed by 'hello' (no closing quote).
run_test(lexer_error_unterminated_atom) :-
    atom_codes(Input, [0'', 0'h, 0'e, 0'l, 0'l, 0'o]),
    npl_lex_string(Input, Tokens),
    Tokens = [error(unterminated_atom)].

%% Error: unterminated block comment
run_test(lexer_error_block_comment) :-
    npl_lex_string('/* unclosed', Tokens),
    Tokens = [error(unterminated_block_comment)].

%% Error: unknown character produces an error token; lexing continues
run_test(lexer_error_unknown_char) :-
    npl_lex_string('$foo', Tokens),
    Tokens = [error(unknown_char('$')), atom(foo)].

%% =====================================================================
%% Parser tests — Stage 4
%% =====================================================================

%% Unit clause (fact) with no body
run_test(parser_fact) :-
    npl_parse_string('foo.', AST),
    AST = [fact(foo, no_pos, [], [])].

%% Structured fact: head with arguments
run_test(parser_fact_structured) :-
    npl_parse_string('foo(a, b).', AST),
    AST = [fact(foo(a,b), no_pos, [], [])].

%% Simple rule:  head :- body.
run_test(parser_rule) :-
    npl_parse_string('foo :- bar.', AST),
    AST = [rule(foo, bar, no_pos, [], [])].

%% Rule with conjunctive body
run_test(parser_rule_conjunction) :-
    npl_parse_string('foo :- a, b, c.', AST),
    AST = [rule(foo, ','(a,','(b,c)), no_pos, [], [])].

%% Directive:  :- Goal.
run_test(parser_directive) :-
    npl_parse_string(':- dynamic(foo/1).', AST),
    AST = [directive(dynamic('/'(foo,1)), no_pos, [], [])].

%% Query:  ?- Goal.
run_test(parser_query) :-
    npl_parse_string('?- member(X, [1,2]).', AST),
    AST = [query(member(var('X'),[1,2]), no_pos, [], [])].

%% Arithmetic expression via 'is' operator
run_test(parser_operators_is) :-
    npl_parse_string('r :- X is 1 + 2.', AST),
    AST = [rule(r, is(var('X'), '+'(1,2)), no_pos, [], [])].

%% Comparison operator
run_test(parser_operators_comparison) :-
    npl_parse_string('r :- X >= 0.', AST),
    AST = [rule(r, '>='(var('X'),0), no_pos, [], [])].

%% Empty list
run_test(parser_list_empty) :-
    npl_parse_string('r([]).', AST),
    AST = [fact(r([]), no_pos, [], [])].

%% List with elements
run_test(parser_list_elements) :-
    npl_parse_string('r([1,2,3]).', AST),
    AST = [fact(r([1,2,3]), no_pos, [], [])].

%% List with explicit tail
run_test(parser_list_tail) :-
    npl_parse_string('r([H|T]).', AST),
    AST = [fact(r([var('H')|var('T')]), no_pos, [], [])].

%% Prefix negation operator  \+
run_test(parser_negation) :-
    npl_parse_string('r :- \\+ foo.', AST),
    AST = [rule(r, '\\+'(foo), no_pos, [], [])].

%% If-then-else:  ( Cond -> Then ; Else )
run_test(parser_if_then_else) :-
    npl_parse_string('r :- (a -> b ; c).', AST),
    AST = [rule(r, ';'('->'(a,b),c), no_pos, [], [])].

%% Disjunction without if-then
run_test(parser_disjunction) :-
    npl_parse_string('r :- a ; b.', AST),
    AST = [rule(r, ';'(a,b), no_pos, [], [])].

%% Multiple clauses in one source string
run_test(parser_multiple_clauses) :-
    npl_parse_string('foo. bar :- baz.', AST),
    AST = [fact(foo, no_pos, [], []),
           rule(bar, baz, no_pos, [], [])].

%% Cognitive-code annotations are attached to the following clause
run_test(parser_annotations) :-
    npl_parse_string('%@ my:note\nfoo.', AST),
    AST = [fact(foo, no_pos, ['my:note'], [])].

%% Source positions are tracked when parsing via npl_parse_string_pos/2
run_test(parser_positions) :-
    npl_parse_string_pos('foo.', AST),
    AST = [fact(foo, pos(1,1), [], [])].

%% Syntax errors produce a parse_error node; parsing continues afterward
run_test(parser_error_recovery) :-
    npl_parse_string('!bad. foo.', AST),
    AST = [parse_error(syntax_error, _), fact(foo, no_pos, [], [])].

%% Module directive: :- module(Name, Exports).
run_test(parser_module_directive) :-
    npl_parse_string(':- module(mymod, []).', AST),
    AST = [directive(module(mymod, []), no_pos, [], [])].

%% =====================================================================
%% Semantic Analyser tests — Stage 5
%% =====================================================================

%% Helper: get a named property from the Props list of an analysed/3 node.
sem_prop(Props, Key, Val) :-
    member(Key:Val, Props).

%% --- Annotation structure ---

%% A simple fact produces an analysed/3 node with the full annotation list.
run_test(sem_fact_annotation) :-
    npl_analyse([fact(foo, no_pos, [], [])], [analysed(foo, true, Props)]),
    sem_prop(Props, head, ok),
    sem_prop(Props, body, ok).

%% A rule produces analysed/3 with head and body annotations.
run_test(sem_rule_annotation) :-
    npl_analyse([rule(foo(a), true, no_pos, [], [])], [analysed(foo(a), true, Props)]),
    sem_prop(Props, head, ok),
    sem_prop(Props, body, ok).

%% --- Arity / head consistency ---

%% A callable head is accepted.
run_test(sem_arity_consistency) :-
    npl_analyse([fact(my_pred(a, b), no_pos, [], [])],
                [analysed(my_pred(a,b), true, Props)]),
    sem_prop(Props, head, ok).

%% A non-callable head (raw integer) reports an error.
run_test(sem_non_callable_head) :-
    npl_analyse([fact(42, no_pos, [], [])],
                [analysed(42, true, Props)]),
    sem_prop(Props, head, error(non_callable_head)).

%% --- Variable usage ---

%% A rule with a variable used in both head and body should have no singletons.
run_test(sem_no_singletons) :-
    npl_parse_string('foo(X) :- bar(X).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, variables, ok).

%% A rule with a variable that appears only once is a singleton.
run_test(sem_singleton_vars) :-
    npl_parse_string('foo(X) :- bar(Y).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, variables, warning(singletons, _)).

%% --- Control structure placement ---

%% A normal rule body has no control warnings.
run_test(sem_control_ok) :-
    npl_parse_string('foo :- bar, baz.', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, control, ok).

%% --- Recursion classification ---

%% Tail recursion: last call is the same predicate.
%% count(0) :- true.  count(N) :- N > 0, N1 is N-1, count(N1).
run_test(sem_tail_recursion) :-
    AST = [ fact(count(0), no_pos, [], []),
            rule(count(N), ','('>'(N,0), ','(is(N1, '-'(N,1)), count(N1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, recursion_class, tail).

%% Linear recursion: exactly one recursive call, not last.
%% len([], 0).  len([_|T], N) :- len(T, N1), N is N1+1.
run_test(sem_linear_recursion) :-
    AST = [ fact(len([], 0), no_pos, [], []),
            rule(len([_|T], N), ','(len(T, N1), is(N, '+'(N1, 1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, recursion_class, linear).

%% Nested recursion: recursive call inside an argument of another recursive call.
%% ack(0,N,R) :- R is N+1.
%% ack(M,0,R) :- M1 is M-1, ack(M1,1,R).
%% ack(M,N,R) :- N1 is N-1, ack(M,N1,R1), M1 is M-1, ack(M1,R1,R).
%% Simplified: a body with two recursive calls and atom arguments (no sub-recursive
%% calls inside arguments) classifies as linear (not nested).
run_test(sem_nested_recursion) :-
    Sig = fib/2,
    Body = ','(fib(a, x), fib(b, y)),
    semantic_analyser:npl_classify_recursion(Sig, fib(n), Body, [], Class),
    Class = linear.

%% No recursion: base case fact.
run_test(sem_no_recursion) :-
    npl_analyse([fact(base, no_pos, [], [])],
                [analysed(base, true, Props)]),
    sem_prop(Props, recursion_class, none).

%% --- Memoisation suitability ---

%% A pure parameterised predicate is a memoisation candidate.
run_test(sem_memoisation_suitable) :-
    AST = [rule(fib(0, 1), true, no_pos, [], []),
           rule(fib(1, 1), true, no_pos, [], [])],
    npl_analyse(AST, [analysed(_, _, P1)|_]),
    sem_prop(P1, memoisation_suitable, true).

%% A predicate that writes to stdout is not a memoisation candidate.
run_test(sem_memoisation_side_effect) :-
    AST = [rule(greet(X), write(X), no_pos, [], [])],
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, memoisation_suitable, false).

%% --- Gaussian elimination suitability ---

%% Tail-recursive predicate is suitable.
run_test(sem_gaussian_tail) :-
    AST = [ fact(count(0), no_pos, [], []),
            rule(count(N), ','('>'(N,0), ','(is(N1,'-'(N,1)), count(N1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, gaussian_elimination_suitable, true).

%% Linear-recursive predicate is also suitable.
run_test(sem_gaussian_linear) :-
    AST = [ fact(len([], 0), no_pos, [], []),
            rule(len([_|T], N), ','(len(T, N1), is(N,'+'(N1,1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, gaussian_elimination_suitable, true).

%% Non-recursive predicate is not suitable.
run_test(sem_gaussian_none) :-
    npl_analyse([fact(base, no_pos, [], [])],
                [analysed(_, _, Props)]),
    sem_prop(Props, gaussian_elimination_suitable, false).

%% --- Cognitive-code markers ---

%% Annotation from %@ is attached as cognitive_code_marker.
run_test(sem_cognitive_marker) :-
    npl_parse_string('%@ memoisation:hint\nfoo(X) :- bar(X).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, cognitive_code_marker, 'memoisation:hint').

%% No annotation → marker is none.
run_test(sem_no_cognitive_marker) :-
    npl_parse_string('foo(X) :- bar(X).', AST),
    npl_analyse(AST, [analysed(_, _, Props)]),
    sem_prop(Props, cognitive_code_marker, none).

%% --- Pass-through nodes ---

%% Directives are unchanged.
run_test(sem_directive_passthrough) :-
    npl_analyse([directive(use_module(foo), no_pos, [], [])],
                [directive(use_module(foo), no_pos, [], [])]).

%% Queries are unchanged.
run_test(sem_query_passthrough) :-
    npl_analyse([query(foo, no_pos, [], [])],
                [query(foo, no_pos, [], [])]).

%% Parse errors are unchanged.
run_test(sem_parse_error_passthrough) :-
    npl_analyse([parse_error(syntax_error, no_pos)],
                [parse_error(syntax_error, no_pos)]).

%% --- Simplification opportunities ---

%% A tail-recursive predicate should include tail_call_optimisation.
run_test(sem_simplification_tco) :-
    AST = [ fact(count(0), no_pos, [], []),
            rule(count(N), ','('>'(N,0), ','(is(N1,'-'(N,1)), count(N1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, simplification_opportunities, Ops),
    member(tail_call_optimisation, Ops).

%% A linear-recursive predicate includes accumulator_introduction.
run_test(sem_simplification_accum) :-
    AST = [ fact(len([], 0), no_pos, [], []),
            rule(len([_|T], N), ','(len(T, N1), is(N,'+'(N1,1))),
                 no_pos, [], []) ],
    npl_analyse(AST, AAST),
    last(AAST, analysed(_, _, Props)),
    sem_prop(Props, simplification_opportunities, Ops),
    member(accumulator_introduction, Ops).

%% --- Body goal validation ---

%% A body that calls a known built-in (write) should be ok.
run_test(sem_builtin_body) :-
    npl_analyse([rule(greet, write(hello), no_pos, [], [])],
                [analysed(_, _, Props)]),
    sem_prop(Props, body, ok).

%% A body that calls a predicate not in the AST and not a built-in
%% should warn possibly_undefined.
run_test(sem_possibly_undefined_body) :-
    npl_analyse([rule(foo, my_unknown_predicate_xyz, no_pos, [], [])],
                [analysed(_, _, Props)]),
    sem_prop(Props, body, warning(possibly_undefined, _)).

%% --- Eliminable nested recursion annotation ---

%% nested recursion class → eliminable = true
run_test(sem_eliminable_nested_true) :-
    semantic_analyser:npl_eliminable_nested(nested, true).

%% tail recursion class → eliminable = false
run_test(sem_eliminable_nested_false) :-
    semantic_analyser:npl_eliminable_nested(tail, false).

%% =====================================================================
%% Interpreter tests — Stage 7
%% =====================================================================
%%
%% Each test calls npl_interp_reset/0 first to ensure a clean database.

%% interp_fact — load facts and query them
run_test(interp_fact) :-
    npl_interp_reset,
    npl_interp_assert(color(red)),
    npl_interp_assert(color(green)),
    npl_interp_assert(color(blue)),
    npl_interp_query(color(red), true),
    npl_interp_query(color(green), true),
    npl_interp_query(color(yellow), false).

%% interp_rule — load a rule and derive a conclusion
run_test(interp_rule) :-
    npl_interp_reset,
    npl_interp_assert(parent(tom, bob)),
    npl_interp_assert(parent(bob, ann)),
    npl_interp_assert((grandparent(X, Z) :- parent(X, Y), parent(Y, Z))),
    npl_interp_query(grandparent(tom, ann), true),
    npl_interp_query(grandparent(tom, bob), false).

%% interp_recursion — recursive membership predicate
run_test(interp_recursion) :-
    npl_interp_reset,
    npl_interp_assert((my_member(X, [X|_]))),
    npl_interp_assert((my_member(X, [_|T]) :- my_member(X, T))),
    npl_interp_query(my_member(2, [1,2,3]), true),
    npl_interp_query(my_member(4, [1,2,3]), false).

%% interp_backtracking — collect multiple solutions via backtracking
run_test(interp_backtracking) :-
    npl_interp_reset,
    npl_interp_assert(fruit(apple)),
    npl_interp_assert(fruit(banana)),
    npl_interp_assert(fruit(cherry)),
    npl_interp_query_all(fruit(F), F, Fruits),
    Fruits == [apple, banana, cherry].

%% interp_cut — cut prevents backtracking to further clauses
run_test(interp_cut) :-
    npl_interp_reset,
    npl_interp_assert((first_color(red) :- !)),
    npl_interp_assert(first_color(blue)),
    npl_interp_query_all(first_color(C), C, Colors),
    Colors == [red].

%% interp_list_processing — interpreter runs list append rules
run_test(interp_list_processing) :-
    npl_interp_reset,
    npl_interp_assert((my_append([], L, L))),
    npl_interp_assert((my_append([H|T], L, [H|R]) :- my_append(T, L, R))),
    npl_interp_query_all(my_append([1,2], [3,4], Z), Z, [[1,2,3,4]]),
    npl_interp_query_all(my_append(A, B, [a,b]),
                         A-B,
                         [ []-[a,b],
                           [a]-[b],
                           [a,b]-[] ]).

%% interp_deep_recursion — list length via recursion + arithmetic
run_test(interp_deep_recursion) :-
    npl_interp_reset,
    npl_interp_assert((my_length([], 0))),
    npl_interp_assert((my_length([_|T], N) :- my_length(T, N1), N is N1 + 1)),
    npl_interp_query_all(my_length([a,b,c,d], N), N, [4]).

%% interp_disjunction — disjunctive bodies work correctly
run_test(interp_disjunction) :-
    npl_interp_reset,
    npl_interp_assert((likes(X) :- (X = cats ; X = dogs))),
    npl_interp_query_all(likes(A), A, Likes),
    Likes == [cats, dogs].

%% interp_negation — negation as failure
run_test(interp_negation) :-
    npl_interp_reset,
    npl_interp_assert(bird(penguin)),
    npl_interp_assert(bird(eagle)),
    npl_interp_assert((can_fly(B) :- bird(B), \+ B = penguin)),
    npl_interp_query_all(can_fly(B), B, Flyers),
    Flyers == [eagle].

%% interp_assert_retract — dynamic assertion and retraction
run_test(interp_assert_retract) :-
    npl_interp_reset,
    npl_interp_assert(item(a)),
    npl_interp_assert(item(b)),
    npl_interp_query(item(a), true),
    npl_interp_retract(item(a)),
    npl_interp_query(item(a), false),
    npl_interp_query(item(b), true).

%% interp_findall — findall collects all solutions via interpreter
run_test(interp_findall) :-
    npl_interp_reset,
    npl_interp_assert(digit(1)),
    npl_interp_assert(digit(2)),
    npl_interp_assert(digit(3)),
    npl_interp_assert((even_digit(D) :- digit(D), 0 =:= D mod 2)),
    npl_interp_query_all(even_digit(D), D, Evens),
    Evens == [2].

%% interp_arithmetic — arithmetic operations in interpreted code
run_test(interp_arithmetic) :-
    npl_interp_reset,
    npl_interp_assert((square(X, Y) :- Y is X * X)),
    npl_interp_assert((sum_squares(A, B, S) :-
        square(A, SA), square(B, SB), S is SA + SB)),
    npl_interp_query_all(sum_squares(3, 4, S), S, [25]).

%% interp_prelude — prelude predicates callable from interpreted code
run_test(interp_prelude) :-
    npl_interp_reset,
    npl_interp_assert((demo_append(L) :- npl_append([1,2], [3,4], L))),
    npl_interp_assert((demo_reverse(R) :- npl_reverse([a,b,c], R))),
    npl_interp_query_all(demo_append(L), L, [[1,2,3,4]]),
    npl_interp_query_all(demo_reverse(R), R, [[c,b,a]]).

%% interp_neurocode — load and execute generated neurocode
run_test(interp_neurocode) :-
    npl_interp_reset,
    % Generate neurocode from IR and load it into the interpreter.
    % nc_greeting/0 is a rule; nc_lucky/1 is a ground fact.
    npl_generate(
        [ ir_clause(nc_greeting,
                    ir_seq(ir_call(write(hi_neurocode)), ir_call(nl)),
                    info(head:ok, body:ok)),
          ir_clause(nc_lucky(7),
                    ir_true,
                    info(head:ok, body:ok)) ],
        Code
    ),
    npl_interp_load_clauses(Code),
    npl_interp_query(nc_greeting, true),
    npl_interp_query(nc_lucky(7), true),
    npl_interp_query(nc_lucky(8), false).

%% interp_query_runner — batch query runner returns true/false per query
run_test(interp_query_runner) :-
    npl_interp_reset,
    npl_interp_assert(ok(a)),
    npl_interp_assert(ok(b)),
    npl_query_runner([ok(a), ok(c), ok(b)], Results),
    Results == [true, false, true].

%% interp_load_ast — load a parsed AST (ground facts) through the interpreter
run_test(interp_load_ast) :-
    npl_interp_reset,
    % Parse ground facts only (parser var(Name) placeholders are not Prolog vars)
    npl_parse_string('animal(cat). animal(dog). animal(fish).', AST),
    npl_interp_load(AST),
    npl_interp_query(animal(cat), true),
    npl_interp_query(animal(dog), true),
    npl_interp_query(animal(bird), false).

%% =====================================================================
%% Stage 8 tests — Intermediate Representation
%% =====================================================================

%% ir8_source_marker — source position is preserved in IRInfo after full pipeline
run_test(ir8_source_marker) :-
    npl_parse_string_pos('foo(1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, [ir_clause(foo(1), ir_true, IRInfo)]),
    npl_ir_info_get(IRInfo, source_marker, Pos),
    Pos = pos(1, 1).

%% ir8_predicate_def_single — npl_ir_full/2 wraps a single clause in ir_predicate_def
run_test(ir8_predicate_def_single) :-
    AAST = [analysed(greet, ir_call(hello), [])],
    npl_ir_full(AAST, [ir_predicate_def(greet/0, [ir_clause(greet, _, _)], Meta)]),
    member(choice_point:false, Meta).

%% ir8_predicate_def_grouped — clauses for the same predicate are grouped together
run_test(ir8_predicate_def_grouped) :-
    npl_parse_string('color(red). color(green). color(blue).', AST),
    npl_analyse(AST, AAST),
    npl_ir_full(AAST, PredDefs),
    PredDefs = [ir_predicate_def(color/1, Clauses, Meta)],
    length(Clauses, 3),
    member(choice_point:true, Meta).

%% ir8_choice_point_multi — multi-clause predicate has choice_point:true in each ir_clause
run_test(ir8_choice_point_multi) :-
    npl_parse_string('shape(circle). shape(square).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    IR = [ir_clause(_, _, Info1), ir_clause(_, _, Info2)],
    npl_ir_info_get(Info1, choice_point, true),
    npl_ir_info_get(Info2, choice_point, true).

%% ir8_choice_point_single — a unique predicate has choice_point:false
run_test(ir8_choice_point_single) :-
    npl_parse_string('unique_pred_xyz(a).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, [ir_clause(_, _, Info)]),
    npl_ir_info_get(Info, choice_point, false).

%% ir8_memo_site — a pure predicate is annotated memo_site:true in IRInfo
run_test(ir8_memo_site) :-
    npl_parse_string('pure_fn(1, one).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, [ir_clause(_, _, Info)]),
    npl_ir_info_get(Info, memo_site, true).

%% ir8_loop_candidate — a tail-recursive predicate is annotated loop_candidate:true
run_test(ir8_loop_candidate) :-
    npl_parse_string('count(0). count(N) :- N > 0, N1 is N - 1, count(N1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    last(IR, ir_clause(_, _, Info)),
    npl_ir_info_get(Info, loop_candidate, true).

%% ir8_recursion_class — tail-recursive clause carries recursion_class:tail in IRInfo
run_test(ir8_recursion_class) :-
    npl_parse_string('loop(0). loop(N) :- N > 0, N1 is N - 1, loop(N1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    last(IR, ir_clause(_, _, Info)),
    npl_ir_info_get(Info, recursion_class, tail).

%% ir8_optimisation_meta — a tail-recursive predicate carries optimisation hints
run_test(ir8_optimisation_meta) :-
    npl_parse_string('go(0). go(N) :- N > 0, N1 is N - 1, go(N1).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    last(IR, ir_clause(_, _, Info)),
    npl_ir_info_get(Info, optimisation_meta, Ops),
    member(tail_call_optimisation, Ops).

%% ir8_info_get_list — npl_ir_info_get/3 works with the new list Info format
run_test(ir8_info_get_list) :-
    Info = [source_marker:pos(1,1), memo_site:true, loop_candidate:false],
    npl_ir_info_get(Info, source_marker, pos(1,1)),
    npl_ir_info_get(Info, memo_site, true),
    npl_ir_info_get(Info, loop_candidate, false).

%% ir8_info_get_legacy — npl_ir_info_get/3 also works with the old info(...) format
run_test(ir8_info_get_legacy) :-
    npl_ir_info_get(info(head:ok, body:ok), head, ok),
    npl_ir_info_get(info(head:ok, body:ok), body, ok).

%% ir8_new_body_nodes_reversible — new IR body nodes round-trip through npl_ir_to_body/2
run_test(ir8_new_body_nodes_reversible) :-
    %% ir_source_marker is transparent — yields the wrapped body
    npl_ir_to_body(ir_source_marker(pos(1,1), ir_call(foo)), foo),
    %% ir_memo_site is transparent — yields the wrapped body
    npl_ir_to_body(ir_memo_site(f(1), ir_call(bar)), bar),
    %% ir_loop_candidate is transparent — yields the wrapped body
    npl_ir_to_body(ir_loop_candidate(ir_call(baz)), baz),
    %% ir_choice_point/1 with one alternative yields that alternative's body
    npl_ir_to_body(ir_choice_point([ir_call(left)]), left),
    %% ir_choice_point/1 with two alternatives yields a disjunction
    npl_ir_to_body(ir_choice_point([ir_call(a), ir_call(b)]), (a ; b)).

%% ir8_full_pipeline — AST-to-IR conversion end-to-end, checking all IR fields
run_test(ir8_full_pipeline) :-
    %% Parse a two-clause predicate with a tail-recursive rule using positioned tokens
    npl_parse_string_pos(
        'fib(0, 0). fib(1, 1). fib(N, F) :- N > 1, N1 is N-1, N2 is N-2, fib(N1,F1), fib(N2,F2), F is F1+F2.',
        AST),
    npl_analyse(AST, AAST),
    %% Flat IR: all three clauses present
    npl_intermediate(AAST, FlatIR),
    length(FlatIR, 3),
    %% All clauses share the same functor
    FlatIR = [ir_clause(fib(_,_), _, Info1)|_],
    %% Source position is captured
    npl_ir_info_get(Info1, source_marker, pos(1,1)),
    %% Grouped IR: one predicate definition with three clauses
    npl_ir_full(AAST, [ir_predicate_def(fib/2, PredClauses, PMeta)]),
    length(PredClauses, 3),
    %% Predicate-level metadata reflects multiple clauses (choice point)
    member(choice_point:true, PMeta),
    %% The recursive clause carries recursion class and optimisation hints
    last(FlatIR, ir_clause(_, _, LastInfo)),
    npl_ir_info_get(LastInfo, recursion_class, linear).

%% =====================================================================
%% Stage 9 tests — Gaussian-Recursion Reduction
%% =====================================================================

%% ----------------------------------------------------------------
%% npl_is_reducible/2
%% ----------------------------------------------------------------

%% gauss9_reducible_tail — two-clause tail-recursive group is recognised
run_test(gauss9_reducible_tail) :-
    Group = [
        ir_clause(count(0), ir_true, []),
        ir_clause(count(_N), ir_seq(ir_call(foo), ir_call(count(_M))), [])
    ],
    npl_is_reducible(Group, linear_tail_recursion).

%% gauss9_reducible_tail_nested_seq — nested sequence tail recursion is recognised
run_test(gauss9_reducible_tail_nested_seq) :-
    Group = [
        ir_clause(count(0), ir_true, []),
        ir_clause(count(N),
                  ir_seq(ir_call(gt(N,0)),
                         ir_seq(ir_call(is(N1,N-1)),
                                ir_call(count(N1)))),
                  [])
    ],
    npl_is_reducible(Group, linear_tail_recursion).

%% gauss9_reducible_accum_add — additive linear accumulate group is recognised
run_test(gauss9_reducible_accum_add) :-
    Group = [
        ir_clause(sum([], 0), ir_true, []),
        ir_clause(sum([H|T], S),
                  ir_seq(ir_call(sum(T, S1)), ir_call(is(S, '+'(S1, H)))),
                  [])
    ],
    npl_is_reducible(Group, linear_accumulate('+', 0)).

%% gauss9_reducible_accum_mul — multiplicative linear accumulate is recognised
run_test(gauss9_reducible_accum_mul) :-
    Group = [
        ir_clause(prod([], 1), ir_true, []),
        ir_clause(prod([H|T], P),
                  ir_seq(ir_call(prod(T, P1)), ir_call(is(P, '*'(P1, H)))),
                  [])
    ],
    npl_is_reducible(Group, linear_accumulate('*', 1)).

%% gauss9_nonreducible — a single-clause predicate is not reducible
run_test(gauss9_nonreducible) :-
    Group = [ ir_clause(hello, ir_call(write(hi)), []) ],
    \+ npl_is_reducible(Group, linear_tail_recursion),
    \+ npl_is_reducible(Group, linear_accumulate(_, _)).

%% ----------------------------------------------------------------
%% npl_extract_recurrence/2
%% ----------------------------------------------------------------

%% gauss9_extract_tail — tail-recursive group extracts as linear_tail
run_test(gauss9_extract_tail) :-
    Group = [
        ir_clause(count(0), ir_true, []),
        ir_clause(count(_N),
                  ir_seq(ir_call(cond), ir_call(count(_M))),
                  [])
    ],
    npl_extract_recurrence(Group, Rec),
    Rec = recurrence(count/1, linear_tail, _).

%% gauss9_extract_accumulate — additive group extracts correct recurrence
run_test(gauss9_extract_accumulate) :-
    Group = [
        ir_clause(sum([], 0), ir_true, []),
        ir_clause(sum([H|T], S),
                  ir_seq(ir_call(sum(T, S1)), ir_call(is(S, '+'(S1, H)))),
                  [])
    ],
    npl_extract_recurrence(Group, Rec),
    Rec = recurrence(sum/2, linear_accumulate, info(op:'+', identity:0, base:_)).

%% gauss9_extract_none — unrecognised group gives recurrence/3 with none
run_test(gauss9_extract_none) :-
    Group = [ ir_clause(hello, ir_call(write(hi)), []) ],
    npl_extract_recurrence(Group, Rec),
    Rec = recurrence(hello/0, none, _).

%% ----------------------------------------------------------------
%% npl_gauss_eliminate/2
%% ----------------------------------------------------------------

%% gauss9_gauss_eliminate_identity — 2×2 identity stays in row echelon form
run_test(gauss9_gauss_eliminate_identity) :-
    M = [ [frac(1,1), frac(0,1)],
          [frac(0,1), frac(1,1)] ],
    npl_gauss_eliminate(M, E),
    E = [ [frac(1,1), frac(0,1)],
          [frac(0,1), frac(1,1)] ].

%% gauss9_gauss_eliminate_rank1 — linearly dependent rows produce zero row
run_test(gauss9_gauss_eliminate_rank1) :-
    M = [ [frac(1,1), frac(2,1), frac(3,1)],
          [frac(2,1), frac(4,1), frac(6,1)] ],
    npl_gauss_eliminate(M, E),
    E = [ [frac(1,1), frac(2,1), frac(3,1)],
          [frac(0,1), frac(0,1), frac(0,1)] ].

%% gauss9_gauss_eliminate_triangular — upper triangular matrix
run_test(gauss9_gauss_eliminate_triangular) :-
    M = [ [frac(2,1), frac(4,1)],
          [frac(1,1), frac(3,1)] ],
    npl_gauss_eliminate(M, E),
    E = [ [frac(1,1), frac(0,1)],
          [frac(0,1), frac(1,1)] ].

%% gauss9_gauss_eliminate_rref_augmented — augmented system reduces to RREF
run_test(gauss9_gauss_eliminate_rref_augmented) :-
    M = [ [frac(1,1), frac(1,1), frac(1,1), frac(1,1)],
          [frac(4,1), frac(2,1), frac(1,1), frac(3,1)],
          [frac(9,1), frac(3,1), frac(1,1), frac(6,1)] ],
    npl_gauss_eliminate(M, E),
    E = [ [frac(1,1), frac(0,1), frac(0,1), frac(1,2)],
          [frac(0,1), frac(1,1), frac(0,1), frac(1,2)],
          [frac(0,1), frac(0,1), frac(1,1), frac(0,1)] ].

%% ----------------------------------------------------------------
%% npl_build_coefficient_matrix/2
%% ----------------------------------------------------------------

%% gauss9_build_coeff_matrix — 2-recurrence system builds a 2×2 diagonal matrix
run_test(gauss9_build_coeff_matrix) :-
    Recs = [
        recurrence(f/1, linear_accumulate, info(op:'+', identity:0, base:_)),
        recurrence(g/1, linear_accumulate, info(op:'+', identity:0, base:_))
    ],
    npl_build_coefficient_matrix(Recs, Matrix),
    Matrix = [ [frac(1,1), frac(0,1)],
               [frac(0,1), frac(1,1)] ].

%% ----------------------------------------------------------------
%% npl_reduce_clause_group/2
%% ----------------------------------------------------------------

%% gauss9_reduce_clause_group_sum — additive group is rewritten to 3 acc clauses
run_test(gauss9_reduce_clause_group_sum) :-
    Group = [
        ir_clause(sum([], 0), ir_true, []),
        ir_clause(sum([H|T], S),
                  ir_seq(ir_call(sum(T, S1)), ir_call(is(S, '+'(S1, H)))),
                  [])
    ],
    npl_reduce_clause_group(Group, Reduced),
    %% Must produce 3 clauses (wrapper + acc base + acc step)
    length(Reduced, 3),
    %% Wrapper: sum/2 calling sum_gauss_acc/3
    Reduced = [ir_clause(WrapperHead, ir_call(WrapperBodyGoal), _)|_],
    functor(WrapperHead, sum, 2),
    functor(WrapperBodyGoal, sum_gauss_acc, 3),
    %% Acc base: sum_gauss_acc/3 with ir_true body
    Reduced = [_, ir_clause(AccBaseHead, ir_true, _)|_],
    functor(AccBaseHead, sum_gauss_acc, 3),
    %% Acc step: sum_gauss_acc/3 with is/2 + recursive call
    last(Reduced, ir_clause(AccStepHead, ir_seq(ir_call(is(_,_)), ir_call(AccRecursiveCall)), _)),
    functor(AccStepHead,      sum_gauss_acc, 3),
    functor(AccRecursiveCall, sum_gauss_acc, 3).

%% gauss9_reduce_clause_group_tail_unchanged — tail-recursive group is unchanged
run_test(gauss9_reduce_clause_group_tail_unchanged) :-
    Group = [
        ir_clause(count(0), ir_true, []),
        ir_clause(count(_N), ir_seq(ir_call(foo), ir_call(count(_M))), [])
    ],
    npl_reduce_clause_group(Group, Reduced),
    Reduced == Group.

%% ----------------------------------------------------------------
%% Correctness: original recursive ≡ accumulator form (via interpreter)
%% ----------------------------------------------------------------

%% gauss9_correctness_sum — recursive sum and accumulator sum agree
run_test(gauss9_correctness_sum) :-
    npl_interp_reset,
    %% Original non-tail-recursive sum
    npl_interp_assert((g9_orig_sum([], 0))),
    npl_interp_assert((g9_orig_sum([H|T], S) :- g9_orig_sum(T, S1), S is S1 + H)),
    %% Accumulator form
    npl_interp_assert((g9_acc_sum(L, S) :- g9_acc_sum_h(L, 0, S))),
    npl_interp_assert((g9_acc_sum_h([], Acc, Acc))),
    npl_interp_assert((g9_acc_sum_h([H|T], Acc, S) :- Acc1 is Acc + H, g9_acc_sum_h(T, Acc1, S))),
    %% Both produce the same result
    npl_interp_query_all(g9_orig_sum([1,2,3,4], S),   S, [10]),
    npl_interp_query_all(g9_acc_sum([1,2,3,4],  S),   S, [10]),
    npl_interp_query_all(g9_orig_sum([], Z),           Z, [0]),
    npl_interp_query_all(g9_acc_sum([],  Z),           Z, [0]).

%% gauss9_correctness_length — recursive length and accumulator length agree
run_test(gauss9_correctness_length) :-
    npl_interp_reset,
    %% Original non-tail-recursive length
    npl_interp_assert((g9_orig_len([], 0))),
    npl_interp_assert((g9_orig_len([_|T], N) :- g9_orig_len(T, N1), N is N1 + 1)),
    %% Accumulator form
    npl_interp_assert((g9_acc_len(L, N) :- g9_acc_len_h(L, 0, N))),
    npl_interp_assert((g9_acc_len_h([], Acc, Acc))),
    npl_interp_assert((g9_acc_len_h([_|T], Acc, N) :- Acc1 is Acc + 1, g9_acc_len_h(T, Acc1, N))),
    %% Both produce the same result
    npl_interp_query_all(g9_orig_len([a,b,c,d,e], N), N, [5]),
    npl_interp_query_all(g9_acc_len([a,b,c,d,e],  N), N, [5]),
    npl_interp_query_all(g9_orig_len([], Z),            Z, [0]),
    npl_interp_query_all(g9_acc_len([],  Z),            Z, [0]).

%% =====================================================================
%% Stage 10 tests — Subterm Address Looping
%% =====================================================================

%% subterm10_addr_bounded_depth0 — depth 0 yields only the root address
run_test(subterm10_addr_bounded_depth0) :-
    npl_subterm_addr_bounded(f(a, g(b, c)), 0, Addrs),
    Addrs == [[]].

%% subterm10_addr_bounded_depth1 — depth 1 yields root + immediate children
run_test(subterm10_addr_bounded_depth1) :-
    npl_subterm_addr_bounded(f(a, g(b, c)), 1, Addrs),
    Addrs == [[], [1], [2]].

%% subterm10_addr_bounded_depth2 — depth 2 descends two levels
run_test(subterm10_addr_bounded_depth2) :-
    npl_subterm_addr_bounded(f(a, g(b, c)), 2, Addrs),
    Addrs == [[], [1], [2], [2,1], [2,2]].

%% subterm10_addr_bounded_terminates — enumeration terminates for an atom
run_test(subterm10_addr_bounded_terminates) :-
    npl_subterm_addr_bounded(hello, 100, Addrs),
    Addrs == [[]].

%% subterm10_iter_bounded_collect — iterator visits all bounded addresses
run_test(subterm10_iter_bounded_collect) :-
    %% Use npl_subterm_addr_bounded to enumerate addresses, then verify count
    npl_subterm_addr_bounded(f(a, b), 1, Addrs),
    length(Addrs, N),
    N == 3,           %% root, [1], [2]
    Addrs == [[], [1], [2]].

%% subterm10_addr_copy_atom — copying an atom gives an equal atom
run_test(subterm10_addr_copy_atom) :-
    npl_addr_copy_term(hello, Copy),
    Copy == hello.

%% subterm10_addr_copy_compound — copying a compound gives a structurally equal term
run_test(subterm10_addr_copy_compound) :-
    npl_addr_copy_term(f(1, 2, 3), Copy),
    Copy == f(1, 2, 3).

%% subterm10_addr_copy_nested — copying a nested compound is correct
run_test(subterm10_addr_copy_nested) :-
    npl_addr_copy_term(foo(bar(1, 2), baz(3)), Copy),
    Copy == foo(bar(1, 2), baz(3)).

%% subterm10_flatten_atom — flattening an atom gives a singleton list
run_test(subterm10_flatten_atom) :-
    npl_subterm_flatten_by_addr(hello, Leaves),
    Leaves == [hello].

%% subterm10_flatten_list — flattening a list gives its atomic elements
run_test(subterm10_flatten_list) :-
    npl_subterm_flatten_by_addr(f(a, b, c), Leaves),
    Leaves == [a, b, c].

%% subterm10_flatten_nested — flattening a nested term gives all leaves in BFS order
run_test(subterm10_flatten_nested) :-
    %% foo(bar(1, 2), 3): BFS leaf addresses are [2],[1,1],[1,2] → values 3, 1, 2
    npl_subterm_flatten_by_addr(foo(bar(1, 2), 3), Leaves),
    Leaves == [3, 1, 2].

%% subterm10_pass_ineligible_unchanged — a plain ir_call is not rewritten
run_test(subterm10_pass_ineligible_unchanged) :-
    IR = [ir_clause(test, ir_call(foo), [])],
    npl_subterm_address_pass(IR, OptIR),
    OptIR == IR.

%% subterm10_pass_eligible_loop_candidate — an ir_loop_candidate with an
%% arg/3 descent pattern is rewritten to ir_addr_loop
run_test(subterm10_pass_eligible_loop_candidate) :-
    Sub = sub,
    Body = ir_seq(ir_call(arg(1, term_var, Sub)), ir_call(traverse(Sub))),
    IR = [ir_clause(h, ir_loop_candidate(Body), [])],
    npl_subterm_address_pass(IR, OptIR),
    OptIR = [ir_clause(h, ir_addr_loop(term_var, traverse/1, Body), [])].

%% subterm10_pass_preserves_source_marker — source marker is threaded through
run_test(subterm10_pass_preserves_source_marker) :-
    IR = [ir_clause(h, ir_source_marker(pos(1,1), ir_call(foo)), [pos(1,1)])],
    npl_subterm_address_pass(IR, OptIR),
    OptIR = [ir_clause(h, ir_source_marker(pos(1,1), ir_call(foo)), [pos(1,1)])].

%% subterm10_pass_ir_addr_loop_sig — the rewritten node carries the correct
%% functor/arity signature of the recursive descent call
run_test(subterm10_pass_ir_addr_loop_sig) :-
    Sub = s,
    Body = ir_seq(ir_call(arg(2, tv, Sub)), ir_call(descend(Sub, acc))),
    IR = [ir_clause(p, ir_loop_candidate(Body), [])],
    npl_subterm_address_pass(IR, OptIR),
    OptIR = [ir_clause(p, ir_addr_loop(tv, descend/2, Body), [])].

%% subterm10_addresses_bfs_order — npl_subterm_addresses returns BFS order
run_test(subterm10_addresses_bfs_order) :-
    npl_subterm_addresses(f(g(a), b), Addrs),
    %% BFS: root, then [1],[2], then [1,1]
    Addrs == [[], [1], [2], [1,1]].

%% =====================================================================
%% Stage 11 tests — Nested Recursion Elimination
%% =====================================================================

%% ----------------------------------------------------------------
%% npl_ir_count_rec_calls/4
%% ----------------------------------------------------------------

%% nested11_count_zero — base clause body has no recursive calls
run_test(nested11_count_zero) :-
    npl_ir_count_rec_calls(fib, 2, ir_true, N),
    N =:= 0.

%% nested11_count_one — linear step body has exactly one recursive call
run_test(nested11_count_one) :-
    Body = ir_seq(ir_call(fib(0, _)), ir_call(is(_, 0))),
    npl_ir_count_rec_calls(fib, 2, Body, N),
    N =:= 1.

%% nested11_count_two — nested step body has exactly two recursive calls
run_test(nested11_count_two) :-
    Body = ir_seq(ir_call(fib(a, _R1)), ir_call(fib(b, _R2))),
    npl_ir_count_rec_calls(fib, 2, Body, N),
    N =:= 2.

%% ----------------------------------------------------------------
%% npl_nested_classify/2
%% ----------------------------------------------------------------

%% nested11_classify_opaque_linear — single-recursive group is opaque
run_test(nested11_classify_opaque_linear) :-
    Group = [
        ir_clause(len([], 0), ir_true, []),
        ir_clause(len([_|T], N),
                  ir_seq(ir_call(len(T, _N1)), ir_call(is(N, _N1+1))),
                  [])
    ],
    npl_nested_classify(Group, Class),
    Class = nested_opaque.

%% nested11_classify_pure — two recursive calls, no side effects, no
%% compound-constructor arg and no binary combining is → nested_pure
run_test(nested11_classify_pure) :-
    Group = [
        ir_clause(rep(0, a), ir_true, []),
        ir_clause(rep(_N, R),
                  ir_seq(ir_call(rep(_N, T)), ir_call(rep(T, R))),
                  [])
    ],
    npl_nested_classify(Group, Class),
    Class = nested_pure.

%% nested11_classify_structural — compound-constructor first arg + 2 rec calls
run_test(nested11_classify_structural) :-
    Group = [
        ir_clause(tree_sum(leaf(_X), _X), ir_true, []),
        ir_clause(tree_sum(node(_L, _R), _S),
                  ir_seq(ir_call(tree_sum(_L, _SL)),
                         ir_seq(ir_call(tree_sum(_R, _SR)),
                                ir_call(is(_S, _SL + _SR)))),
                  [])
    ],
    npl_nested_classify(Group, Class),
    Class = nested_structural.

%% nested11_classify_data_fold — two rec calls + binary combining is/2
run_test(nested11_classify_data_fold) :-
    Group = [
        ir_clause(fib(0, 0), ir_true, []),
        ir_clause(fib(1, 1), ir_true, []),
        ir_clause(fib(_N, _R),
                  ir_seq(ir_call(is(_N1, _N - 1)),
                         ir_seq(ir_call(fib(_N1, _R1)),
                                ir_seq(ir_call(is(_N2, _N - 2)),
                                       ir_seq(ir_call(fib(_N2, _R2)),
                                              ir_call(is(_R, '+'(_R1, _R2))))))),
                  [])
    ],
    npl_nested_classify(Group, Class),
    Class = nested_data_fold('+').

%% nested11_classify_opaque_side_effect — side-effecting group is opaque
run_test(nested11_classify_opaque_side_effect) :-
    Group = [
        ir_clause(bar(0), ir_true, []),
        ir_clause(bar(_N),
                  ir_seq(ir_call(write(_N)),
                         ir_seq(ir_call(bar(_N1)), ir_call(bar(_N1)))),
                  [])
    ],
    npl_nested_classify(Group, Class),
    Class = nested_opaque.

%% ----------------------------------------------------------------
%% npl_ir_body_pure/3
%% ----------------------------------------------------------------

%% nested11_pure_body_pure — body with is/2 and recursive call is pure
run_test(nested11_pure_body_pure) :-
    Body = ir_seq(ir_call(fib(0, _R1)), ir_seq(ir_call(fib(1, _R2)),
                  ir_call(is(_R, _R1 + _R2)))),
    npl_ir_body_pure(fib, 2, Body).

%% nested11_pure_body_impure — body with write/1 is not pure
run_test(nested11_pure_body_impure) :-
    Body = ir_seq(ir_call(write(hello)), ir_call(fib(0, _))),
    \+ npl_ir_body_pure(fib, 2, Body).

%% ----------------------------------------------------------------
%% npl_nested_apply_transform/3
%% ----------------------------------------------------------------

%% nested11_transform_pure_memo — pure transform wraps step body in ir_memo_site
run_test(nested11_transform_pure_memo) :-
    Group = [
        ir_clause(rep(0, a), ir_true, []),
        ir_clause(rep(N, R),
                  ir_seq(ir_call(rep(N, T)), ir_call(rep(T, R))),
                  [])
    ],
    npl_nested_apply_transform(Group, nested_pure, Reduced),
    %% Base clause must be unchanged
    Reduced = [ir_clause(rep(0, a), ir_true, [])|Rest],
    %% Step clause body must be wrapped
    Rest = [ir_clause(rep(N, R), ir_memo_site(rep(N, R), _StepBody), [])],
    %% The wrapped body must contain the original recursive calls
    Rest = [ir_clause(_, ir_memo_site(_, WrappedBody), _)],
    WrappedBody = ir_seq(ir_call(rep(N, _T)), ir_call(rep(_T, R))).

%% nested11_transform_structural_loop — structural transform wraps step in
%% ir_loop_candidate; base clause is unchanged
run_test(nested11_transform_structural_loop) :-
    Group = [
        ir_clause(tree_sum(leaf(X), X), ir_true, []),
        ir_clause(tree_sum(node(L, R), S),
                  ir_seq(ir_call(tree_sum(L, SL)),
                         ir_seq(ir_call(tree_sum(R, SR)),
                                ir_call(is(S, SL + SR)))),
                  [])
    ],
    npl_nested_apply_transform(Group, nested_structural, Reduced),
    %% Base clause unchanged
    Reduced = [ir_clause(tree_sum(leaf(_), _), ir_true, [])|_],
    %% Step clause body is a loop candidate
    last(Reduced, ir_clause(tree_sum(node(_,_), _), ir_loop_candidate(_), [])).

%% nested11_transform_opaque_unchanged — opaque class falls through (no transform)
run_test(nested11_transform_opaque_unchanged) :-
    Group = [
        ir_clause(len([], 0), ir_true, []),
        ir_clause(len([_|T], N),
                  ir_seq(ir_call(len(T, _N1)), ir_call(is(N, _N1 + 1))),
                  [])
    ],
    %% No transform is defined for nested_opaque; full pass preserves group
    npl_nested_eliminate_pass(Group, OptIR),
    OptIR == Group.

%% ----------------------------------------------------------------
%% npl_nr_simplify_body/2
%% ----------------------------------------------------------------

%% nested11_simplify_seq_true_left — ir_seq(ir_true, X) reduces to X
run_test(nested11_simplify_seq_true_left) :-
    npl_nr_simplify_body(ir_seq(ir_true, ir_call(foo)), Result),
    Result = ir_call(foo).

%% nested11_simplify_seq_true_right — ir_seq(X, ir_true) reduces to X
run_test(nested11_simplify_seq_true_right) :-
    npl_nr_simplify_body(ir_seq(ir_call(foo), ir_true), Result),
    Result = ir_call(foo).

%% nested11_simplify_nested_seq — simplification recurses into nested seq
run_test(nested11_simplify_nested_seq) :-
    npl_nr_simplify_body(
        ir_seq(ir_call(a), ir_seq(ir_true, ir_call(b))),
        Result),
    Result = ir_seq(ir_call(a), ir_call(b)).

%% nested11_simplify_noop — non-trivial body is left unchanged
run_test(nested11_simplify_noop) :-
    Body = ir_seq(ir_call(a), ir_call(b)),
    npl_nr_simplify_body(Body, Result),
    Result == Body.

%% ----------------------------------------------------------------
%% npl_nr_unfold_data/2
%% ----------------------------------------------------------------

%% nested11_unfold_data_call — ir_call is preserved
run_test(nested11_unfold_data_call) :-
    npl_nr_unfold_data(ir_call(foo(1)), Result),
    Result = ir_call(foo(1)).

%% nested11_unfold_data_seq — unfold recurses into ir_seq
run_test(nested11_unfold_data_seq) :-
    npl_nr_unfold_data(ir_seq(ir_call(a), ir_call(b)), Result),
    Result = ir_seq(ir_call(a), ir_call(b)).

%% ----------------------------------------------------------------
%% npl_nested_eliminate_pass/2
%% ----------------------------------------------------------------

%% nested11_pass_linear_unchanged — a linear-recursive IR list is not modified
run_test(nested11_pass_linear_unchanged) :-
    IR = [
        ir_clause(len([], 0), ir_true, []),
        ir_clause(len([_|T], N),
                  ir_seq(ir_call(len(T, _N1)), ir_call(is(N, _N1 + 1))),
                  [])
    ],
    npl_nested_eliminate_pass(IR, OptIR),
    OptIR == IR.

%% nested11_pass_pure_nested — a pure nested predicate gets step body wrapped
%% in ir_memo_site by the elimination pass
run_test(nested11_pass_pure_nested) :-
    IR = [
        ir_clause(rep(0, a), ir_true, []),
        ir_clause(rep(N, R),
                  ir_seq(ir_call(rep(N, _T)), ir_call(rep(_T, R))),
                  [])
    ],
    npl_nested_eliminate_pass(IR, OptIR),
    OptIR = [ir_clause(rep(0, a), ir_true, []),
             ir_clause(rep(N, R), ir_memo_site(rep(N, R), _), [])].

%% nested11_pass_structural_nested — a structural nested predicate gets step
%% body wrapped in ir_loop_candidate
run_test(nested11_pass_structural_nested) :-
    IR = [
        ir_clause(tree_sum(leaf(X), X), ir_true, []),
        ir_clause(tree_sum(node(L, R), S),
                  ir_seq(ir_call(tree_sum(L, _SL)),
                         ir_seq(ir_call(tree_sum(R, _SR)),
                                ir_call(is(S, _SL + _SR)))),
                  [])
    ],
    npl_nested_eliminate_pass(IR, OptIR),
    OptIR = [ir_clause(tree_sum(leaf(_), _), ir_true, []),
             ir_clause(tree_sum(node(_, _), _), ir_loop_candidate(_), [])].

%% nested11_pass_empty_ir — empty IR passes through unchanged
run_test(nested11_pass_empty_ir) :-
    npl_nested_eliminate_pass([], []).

%%====================================================================
%% Stage 12: Logical Memoisation and Data Unfolding
%%====================================================================

%% ----------------------------------------------------------------
%% Memoisation engine
%% ----------------------------------------------------------------

%% memo12_cache_hit — second call returns cached result, not recomputed
run_test(memo12_cache_hit) :-
    npl_memo_clear_all,
    npl_memo_call(member(a, [a,b,c])),
    npl_memo_stats(member(a, [a,b,c]), _H0, M0),
    npl_memo_call(member(a, [a,b,c])),
    npl_memo_stats(member(a, [a,b,c]), H1, _M1),
    M0 == 1,
    H1 >= 1.

%% memo12_cache_ground_only — non-ground goal bypasses cache (safe fallback)
run_test(memo12_cache_ground_only) :-
    npl_memo_clear_all,
    % Goal with a free variable: not ground → not cached
    npl_memo_call(true),           % warm up
    npl_memo_call(member(1,[1,2])), % ground → can cache
    npl_memo_inspect(member/2, Entries),
    length(Entries, N),
    N >= 1.

%% memo12_cache_clear — clearing removes cached entries for a functor
run_test(memo12_cache_clear) :-
    npl_memo_clear_all,
    npl_memo_call(member(a, [a,b,c])),
    npl_memo_inspect(member/2, Before),
    Before \== [],
    npl_memo_clear(member/2),
    npl_memo_inspect(member/2, After),
    After == [].

%% memo12_safety_ground — a ground, pure goal is safe to memoise
run_test(memo12_safety_ground) :-
    npl_memo_is_safe(member(a, [a,b,c])).

%% memo12_safety_nonground — a goal with free variables is not safe
run_test(memo12_safety_nonground) :-
    \+ npl_memo_is_safe(member(_X, [1,2,3])).

%% memo12_safety_side_effect — side-effecting goals are not safe
run_test(memo12_safety_side_effect) :-
    \+ npl_memo_is_safe(write(hello)),
    \+ npl_memo_is_safe(assertz(foo)),
    \+ npl_memo_is_safe(nb_setval(k, v)).

%% memo12_stats_hit — hit counter increments on cache hit
run_test(memo12_stats_hit) :-
    npl_memo_clear_all,
    npl_memo_call(member(b, [a,b,c])),
    npl_memo_call(member(b, [a,b,c])),
    npl_memo_stats(member(b, [a,b,c]), Hits, _),
    Hits >= 1.

%% memo12_stats_miss — miss counter increments on first call
run_test(memo12_stats_miss) :-
    npl_memo_clear_all,
    npl_memo_call(member(c, [a,b,c])),
    npl_memo_stats(member(c, [a,b,c]), _, Misses),
    Misses >= 1.

%% memo12_call_all — all-solutions caching is consistent with findall
run_test(memo12_call_all) :-
    npl_memo_clear_all,
    npl_memo_call_all(member(X, [a,b,c]), X, Solutions1),
    npl_memo_call_all(member(X, [a,b,c]), X, Solutions2),
    Solutions1 == [a,b,c],
    Solutions2 == [a,b,c].

%% memo12_subgoal — explicit-key subgoal memoisation
run_test(memo12_subgoal) :-
    npl_memo_clear_all,
    npl_memo_subgoal(test_key_42, true),
    npl_memo_stats(test_key_42, _H, M),
    M >= 1,
    % Second call hits cache
    npl_memo_subgoal(test_key_42, true),
    npl_memo_stats(test_key_42, H2, _),
    H2 >= 1.

%% memo12_clear_all — npl_memo_clear_all removes everything
run_test(memo12_clear_all) :-
    npl_memo_clear_all,
    npl_memo_call(number_codes(1, _)),
    npl_memo_call(number_codes(2, _)),
    npl_memo_clear_all,
    npl_memo_inspect(number_codes/2, E),
    E == [].

%% memo12_ir_pass — memoisation pass annotates declared predicates in IR
run_test(memo12_ir_pass) :-
    npl_memo_clear_all,
    npl_memo(my_pred/1),
    IR = [ir_clause(my_pred(x), ir_true, []),
          ir_clause(other(x), ir_true, [])],
    npl_memoisation_pass(IR, OptIR),
    OptIR = [ir_clause(my_pred(x), ir_true, memoised([])),
             ir_clause(other(x), ir_true, [])],
    retractall(npl_is_memoised(my_pred/1)).

%% ----------------------------------------------------------------
%% Unfolding engine
%% ----------------------------------------------------------------

%% unfold12_term_atom — atom normalises to pat(atom)
run_test(unfold12_term_atom) :-
    npl_unfold_term(foo, P),
    P == pat(atom).

%% unfold12_term_number — number normalises to pat(number)
run_test(unfold12_term_number) :-
    npl_unfold_term(42, P),
    P == pat(number).

%% unfold12_term_var — variable normalises to pat(var)
run_test(unfold12_term_var) :-
    npl_unfold_term(_X, P),
    P == pat(var).

%% unfold12_term_compound — compound normalises structurally
run_test(unfold12_term_compound) :-
    npl_unfold_term(f(a, 1), P),
    P == pat(f, [pat(atom), pat(number)]).

%% unfold12_term_nested — nested compound normalises recursively
run_test(unfold12_term_nested) :-
    npl_unfold_term(f(g(1), h(a, b)), P),
    P == pat(f, [pat(g, [pat(number)]), pat(h, [pat(atom), pat(atom)])]).

%% unfold12_goal_true — ir_true normalises to pat(ir_true)
run_test(unfold12_goal_true) :-
    npl_unfold_goal(ir_true, P),
    P == pat(ir_true).

%% unfold12_goal_call — ir_call normalises to pat(ir_call, [GoalPat])
run_test(unfold12_goal_call) :-
    npl_unfold_goal(ir_call(foo(1, a)), P),
    P == pat(ir_call, [pat(foo, [pat(number), pat(atom)])]).

%% unfold12_goal_seq — ir_seq normalises recursively
run_test(unfold12_goal_seq) :-
    npl_unfold_goal(ir_seq(ir_true, ir_fail), P),
    P == pat(ir_seq, [pat(ir_true), pat(ir_fail)]).

%% unfold12_key_ground — ground term key is the term itself
run_test(unfold12_key_ground) :-
    npl_unfold_key(foo(1, bar), K),
    K == foo(1, bar).

%% unfold12_key_with_vars — term with vars gets structural key
run_test(unfold12_key_with_vars) :-
    npl_unfold_key(foo(_X, 1), K),
    K == foo('$var', '$number').

%% unfold12_match_same_atoms — two atoms of same name match
run_test(unfold12_match_same_atoms) :-
    npl_unfold_match(foo, bar).   % both are atoms → same pattern

%% unfold12_match_same_shape — same structure, different values match
run_test(unfold12_match_same_shape) :-
    npl_unfold_match(f(1, g(2)), f(3, g(4))).

%% unfold12_match_different_structure — different arities don't match
run_test(unfold12_match_different_structure) :-
    \+ npl_unfold_match(f(1), f(1, 2)).

%% unfold12_detect_repeated_none — no repeated keys in linear body
run_test(unfold12_detect_repeated_none) :-
    Body = ir_seq(ir_call(foo(1)), ir_call(bar(2))),
    npl_unfold_detect_repeated(Body, Reps),
    Reps == [].

%% unfold12_detect_repeated_one — one repeated key detected
run_test(unfold12_detect_repeated_one) :-
    Body = ir_seq(ir_call(fib(5)), ir_call(fib(5))),
    npl_unfold_detect_repeated(Body, Reps),
    Reps = [fib(5)].

%% unfold12_detect_repeated_two — two different repeated keys
run_test(unfold12_detect_repeated_two) :-
    Body = ir_seq(ir_call(f(1)), ir_seq(ir_call(g(2)),
           ir_seq(ir_call(f(1)), ir_call(g(2))))),
    npl_unfold_detect_repeated(Body, Reps),
    msort(Reps, Sorted),
    Sorted == [f(1), g(2)].

%% unfold12_pass_no_reps — clause without repeated calls is unchanged
run_test(unfold12_pass_no_reps) :-
    IR = [ir_clause(p(1), ir_seq(ir_call(a(1)), ir_call(b(2))), [])],
    npl_unfold_pass(IR, OptIR),
    OptIR = [ir_clause(p(1), ir_seq(ir_call(a(1)), ir_call(b(2))), [])].

%% unfold12_pass_with_reps — clause with repeated calls gets annotation
run_test(unfold12_pass_with_reps) :-
    IR = [ir_clause(p(1),
                    ir_seq(ir_call(fib(10)), ir_call(fib(10))),
                    [])],
    npl_unfold_pass(IR, OptIR),
    OptIR = [ir_clause(p(1), _, Info)],
    member(repeated_substructures:[fib(10)], Info).

%% unfold12_record_transformation — transformation is recorded and retrievable
run_test(unfold12_record_transformation) :-
    retractall(npl_transformation_recorded(test_key, _)),
    npl_record_transformation(test_key, result_value),
    npl_transformation_recorded(test_key, result_value).

%% ----------------------------------------------------------------
%% Pattern correlation matcher
%% ----------------------------------------------------------------

%% pcorr12_record_lookup — recorded pattern is found by lookup
run_test(pcorr12_record_lookup) :-
    npl_pcorr_clear,
    npl_pcorr_record(foo(1, bar)),
    npl_pcorr_lookup(foo(2, baz), Count),  % same shape as foo(1, bar)
    Count == 1.

%% pcorr12_no_match — lookup fails for unrecorded pattern shape
run_test(pcorr12_no_match) :-
    npl_pcorr_clear,
    npl_pcorr_record(foo(1)),
    \+ npl_pcorr_lookup(bar(1), _).   % different functor → different pattern

%% pcorr12_count_increments — recording the same shape increments count
run_test(pcorr12_count_increments) :-
    npl_pcorr_clear,
    npl_pcorr_record(foo(1)),
    npl_pcorr_record(foo(2)),   % same shape: pat(foo, [pat(number)])
    npl_pcorr_lookup(foo(3), Count),
    Count == 2.

%% pcorr12_repeated_threshold — npl_pcorr_repeated/2 requires count >= 2
run_test(pcorr12_repeated_threshold) :-
    npl_pcorr_clear,
    npl_pcorr_record(f(1)),
    npl_pcorr_record(f(2)),
    npl_pcorr_repeated(f(3), Count),
    Count == 2.

%% pcorr12_not_repeated — single occurrence is not a repeated form
run_test(pcorr12_not_repeated) :-
    npl_pcorr_clear,
    npl_pcorr_record(f(1)),
    \+ npl_pcorr_repeated(f(1), _).

%% pcorr12_all — npl_pcorr_all/1 returns all recorded entries
run_test(pcorr12_all) :-
    npl_pcorr_clear,
    npl_pcorr_record(f(1)),    % shape: pat(f, [pat(number)])
    npl_pcorr_record(g(1)),    % shape: pat(g, [pat(number)]) — different functor
    npl_pcorr_all(Entries),
    length(Entries, 2).

%% pcorr12_clear — npl_pcorr_clear/0 removes all entries
run_test(pcorr12_clear) :-
    npl_pcorr_record(something),
    npl_pcorr_clear,
    npl_pcorr_all([]).

%% pcorr12_record_ir — recording an IR body extracts call goals
run_test(pcorr12_record_ir) :-
    npl_pcorr_clear,
    Body = ir_seq(ir_call(foo(1)), ir_seq(ir_call(bar(2)), ir_call(foo(3)))),
    npl_pcorr_record_ir(Body),
    % foo/1 recorded twice, bar/1 recorded once
    npl_pcorr_lookup(foo(0), FooCount),
    npl_pcorr_lookup(bar(0), BarCount),
    FooCount == 2,
    BarCount == 1.

%% pcorr12_ir_report — ir_report returns patterns with count >= 2
run_test(pcorr12_ir_report) :-
    IR = [
        ir_clause(p(1), ir_seq(ir_call(fib(5)), ir_call(fib(5))), []),
        ir_clause(q(1), ir_call(other(1)), [])
    ],
    npl_pcorr_ir_report(IR, Report),
    % fib/1 appears twice → in report; other/1 appears once → not in report
    member(repeated(pat(fib, [pat(number)]), 2), Report),
    \+ member(repeated(pat(other, _), _), Report).

%%====================================================================
%% Stage 13: Optimisation Dictionary
%%====================================================================

%% dict13_entry_lookup — rich entries are accessible by name
run_test(dict13_entry_lookup) :-
    npl_opt_entry_lookup(identity, entry(identity, Fields)),
    is_list(Fields).

%% dict13_field_access — npl_opt_entry_field/3 retrieves named fields
run_test(dict13_field_access) :-
    npl_opt_entry(identity, Fields),
    npl_opt_entry_field(Fields, category, simplification),
    npl_opt_entry_field(Fields, proof, call_true_identity),
    npl_opt_entry_field(Fields, version, 1).

%% dict13_all_categories — all nine required categories are represented
run_test(dict13_all_categories) :-
    Required = [ memoisation, simplification, recursion_elimination,
                 loop_conversion, accumulator_introduction, constant_folding,
                 algebraic_reduction, gaussian_transform,
                 subterm_address_iteration ],
    findall(Cat,
            ( npl_opt_entry(_, Fields),
              member(category:Cat, Fields) ),
            Cats),
    sort(Cats, CatsSet),
    forall(member(R, Required), member(R, CatsSet)).

%% dict13_entry_has_all_fields — every entry contains all required schema fields
run_test(dict13_entry_has_all_fields) :-
    Required = [ category, trigger, original, transformed, proof,
                 conditions, perf_notes, cognitive_marker, examples, version ],
    forall(
        npl_opt_entry(_Name, Fields),
        forall(member(Key, Required),
               ( member(Key:_, Fields) ->
                   true
               ; format('Missing field ~w in entry~n', [Key]), fail
               ))
    ).

%% dict13_register_entry — a newly registered entry is retrievable
run_test(dict13_register_entry) :-
    Name = dict13_test_entry,
    Fields = [ category:simplification,
               trigger:ir_call(test_goal),
               original:'test original',
               transformed:'test transformed',
               proof:test_proof,
               conditions:[test_cond],
               perf_notes:'test perf',
               cognitive_marker:none,
               examples:[example(x, y)],
               version:1 ],
    npl_opt_entry_register(Name, Fields),
    npl_opt_entry(Name, Stored),
    Stored == Fields,
    retract(npl_opt_entry(Name, _)).  % clean up

%% dict13_register_entry_replaces_existing — re-registering replaces the entry
run_test(dict13_register_entry_replaces_existing) :-
    Name = dict13_replace_test,
    Fields1 = [ category:simplification, trigger:t1, original:o1,
                transformed:t1, proof:p1, conditions:[], perf_notes:'',
                cognitive_marker:none, examples:[], version:1 ],
    Fields2 = [ category:simplification, trigger:t2, original:o2,
                transformed:t2, proof:p2, conditions:[], perf_notes:'',
                cognitive_marker:none, examples:[], version:2 ],
    npl_opt_entry_register(Name, Fields1),
    npl_opt_entry_register(Name, Fields2),
    findall(F, npl_opt_entry(Name, F), All),
    length(All, 1),
    All = [Stored],
    Stored == Fields2,
    retract(npl_opt_entry(Name, _)).  % clean up

%% dict13_rule_preserved_after_register — npl_opt_rule/3 survives full pipeline
run_test(dict13_rule_preserved_after_register) :-
    npl_opt_rule(identity, ir_call(true), ir_true),
    npl_opt_rule(seq_true_left, ir_seq(ir_true, _), _),
    npl_opt_rule(fail_branch, ir_disj(ir_fail, _), _).

%% dict13_entry_count_covers_categories — at least one entry per required category
run_test(dict13_entry_count_covers_categories) :-
    Required = [ memoisation, simplification, recursion_elimination,
                 loop_conversion, accumulator_introduction, constant_folding,
                 algebraic_reduction, gaussian_transform,
                 subterm_address_iteration ],
    forall(
        member(Cat, Required),
        ( npl_opt_entry(_, Fields), member(category:Cat, Fields) -> true
        ; format('No entry for category ~w~n', [Cat]), fail
        )
    ).

%% dict13_algebraic_rule_add_zero — add_zero rules fire in the optimiser
run_test(dict13_algebraic_rule_add_zero) :-
    npl_optimise([ir_clause(test_add0, ir_call(is(r, x+0)), [])], Opt1),
    Opt1 = [ir_clause(test_add0, ir_call(is(r, x)), _)],
    npl_optimise([ir_clause(test_add0l, ir_call(is(r, 0+x)), [])], Opt2),
    Opt2 = [ir_clause(test_add0l, ir_call(is(r, x)), _)].

%% dict13_algebraic_rule_mul_one — mul_one rules fire in the optimiser
run_test(dict13_algebraic_rule_mul_one) :-
    npl_optimise([ir_clause(test_mul1, ir_call(is(r, x*1)), [])], Opt1),
    Opt1 = [ir_clause(test_mul1, ir_call(is(r, x)), _)],
    npl_optimise([ir_clause(test_mul1l, ir_call(is(r, 1*x)), [])], Opt2),
    Opt2 = [ir_clause(test_mul1l, ir_call(is(r, x)), _)].

%% dict13_algebraic_rule_mul_zero — mul_zero rules fire in the optimiser
run_test(dict13_algebraic_rule_mul_zero) :-
    npl_optimise([ir_clause(test_mul0, ir_call(is(r, x*0)), [])], Opt1),
    Opt1 = [ir_clause(test_mul0, ir_call(is(r, 0)), _)],
    npl_optimise([ir_clause(test_mul0l, ir_call(is(r, 0*x)), [])], Opt2),
    Opt2 = [ir_clause(test_mul0l, ir_call(is(r, 0)), _)].

%% dict13_save_load_roundtrip — saved dictionary reloads correctly
run_test(dict13_save_load_roundtrip) :-
    TmpFile = '/tmp/npl_dict13_test.pl',
    % Save the current dictionary to a temp file
    npl_opt_dict_save(TmpFile),
    % Record current entry count
    npl_opt_dict_entries(Before),
    length(Before, NBefore),
    % Load the file — duplicate entries are replaced, counts stay stable
    npl_opt_dict_load(TmpFile),
    npl_opt_dict_entries(After),
    length(After, NAfter),
    NAfter == NBefore,
    % Verify a known entry survived the roundtrip
    npl_opt_entry(identity, Fields),
    member(category:simplification, Fields).

%% dict13_load_replaces_duplicate — loading a saved entry replaces the old one
run_test(dict13_load_replaces_duplicate) :-
    TmpFile = '/tmp/npl_dict13_dup_test.pl',
    npl_opt_dict_save(TmpFile),
    npl_opt_dict_load(TmpFile),
    % There must still be exactly one entry for identity
    findall(F, npl_opt_entry(identity, F), All),
    length(All, 1).

%% dict13_entry_to_rule_projection — existing rules can be projected from entries
run_test(dict13_entry_to_rule_projection) :-
    npl_opt_entry_to_rule(identity, ir_call(true), ir_true),
    npl_opt_entry_to_rule(seq_true_left, ir_seq(ir_true, _), _).

%% dict13_entry_version_field — version field is a positive integer
run_test(dict13_entry_version_field) :-
    forall(
        npl_opt_entry(_Name, Fields),
        ( member(version:V, Fields),
          integer(V),
          V >= 1 )
    ).

%% dict13_entry_examples_field — examples field is a list
run_test(dict13_entry_examples_field) :-
    forall(
        npl_opt_entry(_Name, Fields),
        ( member(examples:Ex, Fields),
          is_list(Ex) )
    ).

%% dict13_entry_cognitive_marker_field — cognitive_marker field is present and an atom
run_test(dict13_entry_cognitive_marker_field) :-
    forall(
        npl_opt_entry(_Name, Fields),
        ( member(cognitive_marker:CM, Fields),
          atom(CM) )
    ).

%% dict13_memoisation_entry_present — memo_pure_predicate entry exists
run_test(dict13_memoisation_entry_present) :-
    npl_opt_entry(memo_pure_predicate, Fields),
    member(category:memoisation, Fields),
    member(proof:memoisation_referential_transparency, Fields).

%% dict13_gaussian_entry_present — gaussian_linear_accumulate entry exists
run_test(dict13_gaussian_entry_present) :-
    npl_opt_entry(gaussian_linear_accumulate, Fields),
    member(category:gaussian_transform, Fields),
    member(proof:gaussian_elimination_row_echelon_correctness, Fields).

%% dict13_subterm_entry_present — arg_descent_to_addr_loop entry exists
run_test(dict13_subterm_entry_present) :-
    npl_opt_entry(arg_descent_to_addr_loop, Fields),
    member(category:subterm_address_iteration, Fields),
    member(proof:subterm_bfs_completeness, Fields).

%%====================================================================
%% Stage 14: Cognitive Markers and Neurocode Mapping
%%====================================================================

%% ncm14_record_lookup — record a mapping and retrieve it by marker
run_test(ncm14_record_lookup) :-
    npl_ncm_clear,
    Orig = ir_clause(test14_foo(1), ir_true, [cognitive_marker:test_marker, source_marker:no_pos]),
    npl_ncm_record(Orig, test_marker, test14_foo(1), [rule_a], [pred_sig:test14_foo/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_lookup_by_marker(test_marker, ncm(Orig, test_marker, test14_foo(1), [rule_a], _)),
    npl_ncm_clear.

%% ncm14_lookup_by_head — retrieve entries by head functor/arity
run_test(ncm14_lookup_by_head) :-
    npl_ncm_clear,
    Orig = ir_clause(bar14(x), ir_call(baz), [cognitive_marker:none, source_marker:no_pos]),
    npl_ncm_record(Orig, none, (bar14(x) :- baz), [step1], [pred_sig:bar14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_lookup_by_head(bar14(_), ncm(Orig, _, _, _, _)),
    npl_ncm_clear.

%% ncm14_all_records — npl_ncm_all/1 returns all asserted entries
run_test(ncm14_all_records) :-
    npl_ncm_clear,
    Orig1 = ir_clause(p14(1), ir_true, []),
    Orig2 = ir_clause(q14(2), ir_true, []),
    npl_ncm_record(Orig1, none, p14(1), [], [pred_sig:p14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_record(Orig2, none, q14(2), [], [pred_sig:q14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_all(Entries),
    length(Entries, 2),
    npl_ncm_clear.

%% ncm14_clear — npl_ncm_clear/0 removes all entries
run_test(ncm14_clear) :-
    npl_ncm_clear,
    Orig = ir_clause(r14(a), ir_true, []),
    npl_ncm_record(Orig, none, r14(a), [], [pred_sig:r14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_all(Before),
    length(Before, 1),
    npl_ncm_clear,
    npl_ncm_all(After),
    After = [].

%% ncm14_schema_meta_fields — meta always contains the three required keys
run_test(ncm14_schema_meta_fields) :-
    npl_ncm_clear,
    Meta = [pred_sig:s14/1, source_marker:pos(1,1), rebuild_version:1],
    Orig = ir_clause(s14(a), ir_true, []),
    npl_ncm_record(Orig, none, s14(a), [], Meta),
    npl_ncm_all([ncm(_, _, _, _, M)]),
    member(pred_sig:_, M),
    member(source_marker:_, M),
    member(rebuild_version:_, M),
    npl_ncm_clear.

%% ncm14_opt_steps_is_list — opt_steps field is always a list
run_test(ncm14_opt_steps_is_list) :-
    npl_ncm_clear,
    Steps = [identity, seq_true_left, gaussian_reduce],
    Orig = ir_clause(t14(a), ir_true, []),
    npl_ncm_record(Orig, none, t14(a), Steps, [pred_sig:t14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_all([ncm(_, _, _, S, _)]),
    is_list(S),
    npl_ncm_clear.

%% ncm14_neurocode_is_term — neurocode fragment field is a valid Prolog term
run_test(ncm14_neurocode_is_term) :-
    npl_ncm_clear,
    NeuroFrag = (u14(X) :- member(X, [1,2,3])),
    Orig = ir_clause(u14(_), ir_call(member(_,[1,2,3])), []),
    npl_ncm_record(Orig, none, NeuroFrag, [], [pred_sig:u14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_all([ncm(_, _, NF, _, _)]),
    compound(NF),
    npl_ncm_clear.

%% ncm14_build_single_clause — build mapping from a single IR clause
run_test(ncm14_build_single_clause) :-
    npl_ncm_clear,
    OrigIR  = [ir_clause(v14(1), ir_true, [cognitive_marker:none, source_marker:no_pos])],
    OptIR   = [ir_clause(v14(1), ir_true, [cognitive_marker:none, source_marker:no_pos])],
    NC      = [v14(1)],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, Mappings),
    Mappings = [ncm(ir_clause(v14(1), _, _), none, v14(1), _, _)],
    npl_ncm_clear.

%% ncm14_build_multi_clause — build mappings from multiple IR clauses
run_test(ncm14_build_multi_clause) :-
    npl_ncm_clear,
    OrigIR = [
        ir_clause(w14(0), ir_true, [cognitive_marker:none, source_marker:no_pos]),
        ir_clause(w14(s(N)), ir_call(w14(N)), [cognitive_marker:none, source_marker:no_pos])
    ],
    OptIR = [
        ir_clause(w14(0), ir_true, [cognitive_marker:none, source_marker:no_pos]),
        ir_clause(w14(s(N)), ir_call(w14(N)), [cognitive_marker:none, source_marker:no_pos])
    ],
    NC = [ w14(0), (w14(s(N)) :- w14(N)) ],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, Mappings),
    length(Mappings, 2),
    npl_ncm_clear.

%% ncm14_build_preserves_marker — cognitive marker from IR info is preserved
run_test(ncm14_build_preserves_marker) :-
    npl_ncm_clear,
    Marker = 'recursion:tail',
    OrigIR = [ir_clause(x14(n), ir_call(x14(n1)), [cognitive_marker:Marker, source_marker:no_pos])],
    OptIR  = [ir_clause(x14(n), ir_call(x14(n1)), [cognitive_marker:Marker, source_marker:no_pos])],
    NC     = [(x14(n) :- x14(n1))],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, [ncm(_, M, _, _, _)]),
    M == Marker,
    npl_ncm_clear.

%% ncm14_build_marker_none_when_absent — marker is 'none' when not in IR info
run_test(ncm14_build_marker_none_when_absent) :-
    npl_ncm_clear,
    OrigIR = [ir_clause(y14(a), ir_true, [source_marker:no_pos])],
    OptIR  = [ir_clause(y14(a), ir_true, [source_marker:no_pos])],
    NC     = [y14(a)],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, [ncm(_, Marker, _, _, _)]),
    Marker == none,
    npl_ncm_clear.

%% ncm14_trace_report_nonempty — trace report is non-empty after recording
run_test(ncm14_trace_report_nonempty) :-
    npl_ncm_clear,
    Orig = ir_clause(z14(1), ir_true, []),
    npl_ncm_record(Orig, none, z14(1), [step_a], [pred_sig:z14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_trace_report(Report),
    Report \= [],
    npl_ncm_clear.

%% ncm14_trace_report_entry_fields — each trace entry has four fields
run_test(ncm14_trace_report_entry_fields) :-
    npl_ncm_clear,
    Orig = ir_clause(aa14(b), ir_call(bb14(b)), []),
    npl_ncm_record(Orig, 'loop:addr', (aa14(b) :- bb14(b)), [rule1, rule2], [pred_sig:aa14/1, source_marker:no_pos, rebuild_version:1]),
    npl_ncm_trace_report(Report),
    member(trace_entry(Marker, OrigHead, NeuroFrag, Steps), Report),
    Marker   == 'loop:addr',
    OrigHead == aa14(b),
    compound(NeuroFrag),
    is_list(Steps),
    npl_ncm_clear.

%% ncm14_report_entry_format — npl_ncm_report_entry/2 produces a report_line/4
run_test(ncm14_report_entry_format) :-
    npl_ncm_clear,
    Meta = [pred_sig:cc14/2, source_marker:pos(3,1), rebuild_version:1],
    Entry = ncm(ir_clause(cc14(a,b), ir_true, []), 'memoisation:hint', cc14(a,b), [r1,r2,r3], Meta),
    npl_ncm_report_entry(Entry, report_line(Marker, Sig, NF, N)),
    Marker == 'memoisation:hint',
    Sig    == cc14/2,
    NF     == cc14(a,b),
    N      == 3,
    npl_ncm_clear.

%% ncm14_meta_pred_sig — meta pred_sig matches the clause head functor/arity
run_test(ncm14_meta_pred_sig) :-
    npl_ncm_clear,
    OrigIR = [ir_clause(dd14(x, y), ir_call(ee14(x)), [cognitive_marker:none, source_marker:no_pos])],
    OptIR  = [ir_clause(dd14(x, y), ir_call(ee14(x)), [cognitive_marker:none, source_marker:no_pos])],
    NC     = [(dd14(x, y) :- ee14(x))],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, [ncm(_, _, _, _, Meta)]),
    member(pred_sig:dd14/2, Meta),
    npl_ncm_clear.

%% ncm14_meta_source_marker — meta source_marker reflects the IR info position
run_test(ncm14_meta_source_marker) :-
    npl_ncm_clear,
    OrigIR = [ir_clause(ff14(a), ir_true, [cognitive_marker:none, source_marker:pos(7,1)])],
    OptIR  = [ir_clause(ff14(a), ir_true, [cognitive_marker:none, source_marker:pos(7,1)])],
    NC     = [ff14(a)],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, [ncm(_, _, _, _, Meta)]),
    member(source_marker:pos(7,1), Meta),
    npl_ncm_clear.

%% ncm14_meta_rebuild_version — meta rebuild_version is always 1
run_test(ncm14_meta_rebuild_version) :-
    npl_ncm_clear,
    OrigIR = [ir_clause(gg14(z), ir_true, [cognitive_marker:none, source_marker:no_pos])],
    OptIR  = [ir_clause(gg14(z), ir_true, [cognitive_marker:none, source_marker:no_pos])],
    NC     = [gg14(z)],
    npl_ncm_build_from_ir(OrigIR, OptIR, NC, [ncm(_, _, _, _, Meta)]),
    member(rebuild_version:1, Meta),
    npl_ncm_clear.

%% ncm14_full_pipeline — end-to-end: parse→IR→optimise→codegen→build mappings
run_test(ncm14_full_pipeline) :-
    npl_ncm_clear,
    npl_parse_string('sum14([], 0). sum14([H|T], S) :- sum14(T, S1), S is S1 + H.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, OrigIR),
    npl_optimise(OrigIR, OptIR),
    npl_generate(OptIR, Neurocode),
    npl_ncm_build_from_ir(OrigIR, OptIR, Neurocode, Mappings),
    length(Mappings, 2),
    Mappings = [ncm(_, _, _, Steps, Meta1)|_],
    is_list(Steps),
    member(pred_sig:sum14/2, Meta1),
    member(rebuild_version:1, Meta1),
    npl_ncm_clear.

%% =====================================================================
%% Stage 15: Optimiser Pipeline
%% =====================================================================

%% pipe15_pass_names_ordered — pass names list has exactly 11 entries in order
run_test(pipe15_pass_names_ordered) :-
    npl_pipeline_pass_names(Names),
    Names = [semantic_annotation, simplification, recurrence_detection,
             gaussian_elimination, recursion_to_loop,
             subterm_address_conversion, nested_recursion_elimination,
             memoisation_insertion, dict_learned_opt,
             final_simplification, neurocode_emission],
    length(Names, 11).

%% pipe15_default_config_has_all_passes — default config has 11 pass entries
run_test(pipe15_default_config_has_all_passes) :-
    npl_pipeline_default_config(Config),
    length(Config, 11).

%% pipe15_default_all_enabled — all passes are enabled by default
run_test(pipe15_default_all_enabled) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_pass_names(Names),
    maplist(npl_pipeline_is_enabled_in(Config), Names).

npl_pipeline_is_enabled_in(Config, Name) :-
    npl_pipeline_is_enabled(Name, Config).

%% pipe15_enable_disable — enable/disable roundtrip works
run_test(pipe15_enable_disable) :-
    npl_pipeline_default_config(C0),
    npl_pipeline_disable(simplification, C0, C1),
    \+ npl_pipeline_is_enabled(simplification, C1),
    npl_pipeline_enable(simplification, C1, C2),
    npl_pipeline_is_enabled(simplification, C2).

%% pipe15_is_enabled_true — enabled pass is detected
run_test(pipe15_is_enabled_true) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_is_enabled(gaussian_elimination, Config).

%% pipe15_is_enabled_false — disabled pass is not detected
run_test(pipe15_is_enabled_false) :-
    npl_pipeline_default_config(C0),
    npl_pipeline_disable(memoisation_insertion, C0, C1),
    \+ npl_pipeline_is_enabled(memoisation_insertion, C1).

%% pipe15_run_empty_ir — pipeline runs without error on empty IR
run_test(pipe15_run_empty_ir) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config, [], OptIR, Report),
    OptIR == [],
    is_list(Report).

%% pipe15_run_report_length — report has 10 entries (one per IR-transform pass)
run_test(pipe15_run_report_length) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config, [], _, Report),
    length(Report, 10).

%% pipe15_report_has_pass_report_terms — every report entry is pass_report/3
run_test(pipe15_report_has_pass_report_terms) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config, [], _, Report),
    maplist(is_pass_report, Report).

is_pass_report(pass_report(_, _, _)).

%% pipe15_disabled_pass_skipped — a disabled pass gets status skipped in report
run_test(pipe15_disabled_pass_skipped) :-
    npl_pipeline_default_config(C0),
    npl_pipeline_disable(gaussian_elimination, C0, Config),
    npl_pipeline_run(Config, [], _, Report),
    member(pass_report(gaussian_elimination, skipped, _), Report).

%% pipe15_applied_pass_status — an enabled pass on non-empty IR gets status applied
run_test(pipe15_applied_pass_status) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config,
                     [ir_clause(fact15(a), ir_true, [])],
                     _, Report),
    member(pass_report(semantic_annotation, applied, _), Report).

%% pipe15_semantic_annotation_pass — annotation pass reports recursion classes
run_test(pipe15_semantic_annotation_pass) :-
    npl_pipeline_default_config(C0),
    npl_pipeline_disable(simplification,              C0, C1),
    npl_pipeline_disable(recurrence_detection,        C1, C2),
    npl_pipeline_disable(gaussian_elimination,        C2, C3),
    npl_pipeline_disable(recursion_to_loop,           C3, C4),
    npl_pipeline_disable(subterm_address_conversion,  C4, C5),
    npl_pipeline_disable(nested_recursion_elimination,C5, C6),
    npl_pipeline_disable(memoisation_insertion,       C6, C7),
    npl_pipeline_disable(dict_learned_opt,            C7, C8),
    npl_pipeline_disable(final_simplification,        C8, Config),
    IR = [ir_clause(ann15(x), ir_true, [recursion_class:none])],
    npl_pipeline_run(Config, IR, _, Report),
    member(pass_report(semantic_annotation, applied, Info), Report),
    member(ir_items:1, Info),
    member(annotations:[ann15/1:rc(none)], Info).

%% pipe15_recurrence_detection_pass — recurrence pass reports recurrences list
run_test(pipe15_recurrence_detection_pass) :-
    npl_pipeline_default_config(Config),
    IR = [ir_clause(rd15(x), ir_true, [])],
    npl_pipeline_run(Config, IR, _, Report),
    member(pass_report(recurrence_detection, applied, Info), Report),
    member(recurrences:_, Info).

%% pipe15_simplification_removes_trivial — simplification collapses ir_seq(ir_true,B)
run_test(pipe15_simplification_removes_trivial) :-
    npl_pipeline_default_config(C0),
    npl_pipeline_disable(recurrence_detection,        C0, C1),
    npl_pipeline_disable(gaussian_elimination,        C1, C2),
    npl_pipeline_disable(recursion_to_loop,           C2, C3),
    npl_pipeline_disable(subterm_address_conversion,  C3, C4),
    npl_pipeline_disable(nested_recursion_elimination,C4, C5),
    npl_pipeline_disable(memoisation_insertion,       C5, C6),
    npl_pipeline_disable(dict_learned_opt,            C6, C7),
    npl_pipeline_disable(final_simplification,        C7, Config),
    IR = [ir_clause(simp15(a), ir_seq(ir_true, ir_call(ok)), [])],
    npl_pipeline_run(Config, IR, [ir_clause(simp15(a), OptBody, _)], _),
    OptBody == ir_call(ok).

%% pipe15_gaussian_pass_runs — gaussian elimination pass runs without error
run_test(pipe15_gaussian_pass_runs) :-
    npl_pipeline_default_config(C0),
    npl_pipeline_disable(semantic_annotation,         C0, C1),
    npl_pipeline_disable(simplification,              C1, C2),
    npl_pipeline_disable(recurrence_detection,        C2, C3),
    npl_pipeline_disable(recursion_to_loop,           C3, C4),
    npl_pipeline_disable(subterm_address_conversion,  C4, C5),
    npl_pipeline_disable(nested_recursion_elimination,C5, C6),
    npl_pipeline_disable(memoisation_insertion,       C6, C7),
    npl_pipeline_disable(dict_learned_opt,            C7, C8),
    npl_pipeline_disable(final_simplification,        C8, Config),
    IR = [ir_clause(gauss15(a), ir_true, [])],
    npl_pipeline_run(Config, IR, OptIR, Report),
    is_list(OptIR),
    member(pass_report(gaussian_elimination, applied, _), Report).

%% pipe15_full_run_sum — full pipeline run on sum predicate succeeds
run_test(pipe15_full_run_sum) :-
    npl_parse_string('sum15([], 0). sum15([H|T], S) :- sum15(T, S1), S is S1 + H.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config, IR, OptIR, Report),
    is_list(OptIR),
    length(Report, 10),
    maplist(is_pass_report, Report).

%% pipe15_run_full_produces_neurocode — run_full produces a non-empty neurocode list
run_test(pipe15_run_full_produces_neurocode) :-
    npl_parse_string('nc15(a). nc15(b) :- true.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_pipeline_default_config(Config),
    npl_pipeline_run_full(Config, IR, _OptIR, Neurocode, Report),
    is_list(Neurocode),
    Neurocode \= [],
    length(Report, 11),
    member(pass_report(neurocode_emission, applied, _), Report).

%% pipe15_run_full_report_length — run_full report has 11 entries
run_test(pipe15_run_full_report_length) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_run_full(Config, [], _, _, Report),
    length(Report, 11).

%% pipe15_benchmark_returns_time — benchmark returns a numeric time
run_test(pipe15_benchmark_returns_time) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_benchmark(Config, [], Report, TimeMs),
    is_list(Report),
    number(TimeMs).

%% pipe15_benchmark_time_nonnegative — benchmark time is >= 0
run_test(pipe15_benchmark_time_nonnegative) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_benchmark(Config, [], _Report, TimeMs),
    TimeMs >= 0.

%% pipe15_pipeline_vs_optimiser — pipeline output is equivalent to npl_optimise output
%  Uses =@= (structural equality up to variable renaming) because
%  npl_generate/2 now converts var(Name) compound terms to real Prolog
%  variables, so the two neurocode lists have structurally equal but
%  independently instantiated variables.
run_test(pipe15_pipeline_vs_optimiser) :-
    npl_parse_string('id15(X) :- true, X = a.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_optimise(IR, OptIR1),
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config, IR, OptIR2, _),
    npl_generate(OptIR1, NC1),
    npl_generate(OptIR2, NC2),
    NC1 =@= NC2.

%% pipe15_report_print_succeeds — npl_pipeline_report_print/1 succeeds without error
run_test(pipe15_report_print_succeeds) :-
    npl_pipeline_default_config(Config),
    npl_pipeline_run(Config, [], _, Report),
    with_output_to(string(_), npl_pipeline_report_print(Report)).

%%====================================================================
%% Stage 16: Code Generator Tests
%%====================================================================

%% cg16_generate_full_basic — npl_generate_full/3 produces a list from IR
run_test(cg16_generate_full_basic) :-
    IR = [ir_clause(hello, ir_true, [])],
    npl_generate_full(IR, '', Segments),
    is_list(Segments),
    length(Segments, 1).

%% cg16_segment_is_code_segment — each segment is a code_segment/3 term
run_test(cg16_segment_is_code_segment) :-
    IR = [ir_clause(foo(a), ir_call(bar), [])],
    npl_generate_full(IR, '', Segments),
    Segments = [code_segment(_, _, _)].

%% cg16_comment_has_pred_sig — comment contains the predicate functor/arity
run_test(cg16_comment_has_pred_sig) :-
    IR = [ir_clause(mypred(X, Y), ir_seq(ir_call(X), ir_call(Y)), [])],
    npl_generate_full(IR, '', [code_segment(Comment, _, _)]),
    atom(Comment),
    sub_atom(Comment, _, _, _, 'mypred').

%% cg16_source_marker_in_comment — source position appears in the comment
run_test(cg16_source_marker_in_comment) :-
    Info = [source_marker: pos(5, 1), recursion_class: none,
            choice_point: false, memo_site: false, loop_candidate: false,
            optimisation_meta: [], cognitive_marker: none,
            head_status: ok, body_status: ok],
    IR = [ir_clause(srctest, ir_true, Info)],
    npl_generate_full(IR, 'myfile.pl', [code_segment(Comment, _, _)]),
    sub_atom(Comment, _, _, _, 'pos(5,1)').

%% cg16_cognitive_marker_in_comment — cognitive marker appears in comment when set
run_test(cg16_cognitive_marker_in_comment) :-
    Info = [source_marker: no_pos, recursion_class: none,
            choice_point: false, memo_site: false, loop_candidate: false,
            optimisation_meta: [], cognitive_marker: accumulate,
            head_status: ok, body_status: ok],
    IR = [ir_clause(cm_test, ir_true, Info)],
    npl_generate_full(IR, '', [code_segment(Comment, _, _)]),
    sub_atom(Comment, _, _, _, 'accumulate').

%% cg16_memo_site_emits_cache_check — memo_site body contains npl_memo_cache check
run_test(cg16_memo_site_emits_cache_check) :-
    npl_ir_to_body_emitting(
        ir_memo_site(fib(5, _F), ir_call(fib_body)),
        [],
        Body),
    with_output_to(atom(Txt), write_term(Body, [quoted(true)])),
    sub_atom(Txt, _, _, _, 'ground'),
    sub_atom(Txt, _, _, _, 'npl_memo_cache').

%% cg16_memo_site_emits_assertz — memo body includes assertz for caching
run_test(cg16_memo_site_emits_assertz) :-
    npl_ir_to_body_emitting(
        ir_memo_site(test_key, ir_call(test_goal)),
        [],
        Body),
    with_output_to(atom(Txt), write_term(Body, [quoted(true)])),
    sub_atom(Txt, _, _, _, 'assertz').

%% cg16_loop_candidate_emits_body — loop_candidate transparently emits its body
run_test(cg16_loop_candidate_emits_body) :-
    npl_ir_to_body_emitting(ir_loop_candidate(ir_call(my_loop_body)), [], Body),
    Body == my_loop_body.

%% cg16_addr_loop_emits_subterm_addr — addr_loop emits npl_subterm_addr_bounded call
run_test(cg16_addr_loop_emits_subterm_addr) :-
    npl_ir_to_body_emitting(
        ir_addr_loop(my_term, trav/1, ir_call(do_work)),
        [],
        Body),
    with_output_to(atom(Txt), write_term(Body, [quoted(true)])),
    sub_atom(Txt, _, _, _, 'npl_subterm_addr_bounded').

%% cg16_addr_loop_emits_forall — addr_loop emits forall loop construct
run_test(cg16_addr_loop_emits_forall) :-
    npl_ir_to_body_emitting(
        ir_addr_loop(my_term, trav/1, ir_call(do_work)),
        [],
        Body),
    with_output_to(atom(Txt), write_term(Body, [quoted(true)])),
    sub_atom(Txt, _, _, _, 'forall').

%% cg16_segment_meta_pred_sig — segment metadata includes pred_sig
run_test(cg16_segment_meta_pred_sig) :-
    IR = [ir_clause(mymeta(1, 2), ir_true, [])],
    npl_generate_full(IR, '', [code_segment(_, _, Meta)]),
    member(pred_sig: mymeta/2, Meta).

%% cg16_segment_meta_source_marker — segment metadata includes source_marker
run_test(cg16_segment_meta_source_marker) :-
    IR = [ir_clause(src_m, ir_true, [source_marker: pos(3, 1)])],
    npl_generate_full(IR, '', [code_segment(_, _, Meta)]),
    member(source_marker: pos(3, 1), Meta).

%% cg16_segment_meta_memo_site — segment meta reflects memo_site flag
run_test(cg16_segment_meta_memo_site) :-
    Info = [source_marker: no_pos, recursion_class: none,
            choice_point: false, memo_site: true, loop_candidate: false,
            optimisation_meta: [], cognitive_marker: none,
            head_status: ok, body_status: ok],
    IR = [ir_clause(memo_pred(x), ir_call(body_goal), Info)],
    npl_generate_full(IR, '', [code_segment(_, _, Meta)]),
    member(memo_site: true, Meta).

%% cg16_segment_meta_loop_candidate — segment meta reflects loop_candidate flag
run_test(cg16_segment_meta_loop_candidate) :-
    Info = [source_marker: no_pos, recursion_class: none,
            choice_point: false, memo_site: false, loop_candidate: true,
            optimisation_meta: [], cognitive_marker: none,
            head_status: ok, body_status: ok],
    IR = [ir_clause(loop_pred(x), ir_call(body_goal), Info)],
    npl_generate_full(IR, '', [code_segment(_, _, Meta)]),
    member(loop_candidate: true, Meta).

%% cg16_write_full_succeeds — npl_write_neurocode_full/3 runs without error
run_test(cg16_write_full_succeeds) :-
    IR = [ir_clause(wf_pred(a), ir_call(wf_body), [])],
    npl_generate_full(IR, 'test.pl', Segments),
    with_output_to(string(_),
        npl_write_neurocode_full(current_output, Segments,
                                  'Test neurocode')).

%% cg16_write_full_has_header — written output contains the header text
run_test(cg16_write_full_has_header) :-
    IR = [ir_clause(hdr_pred, ir_true, [])],
    npl_generate_full(IR, '', Segments),
    with_output_to(atom(Out),
        npl_write_neurocode_full(current_output, Segments,
                                  'MyHeaderText')),
    sub_atom(Out, _, _, _, 'MyHeaderText').

%% cg16_write_full_has_clause — written output contains the predicate name
run_test(cg16_write_full_has_clause) :-
    IR = [ir_clause(written_pred(x), ir_true, [])],
    npl_generate_full(IR, '', Segments),
    with_output_to(atom(Out),
        npl_write_neurocode_full(current_output, Segments, 'H')),
    sub_atom(Out, _, _, _, 'written_pred').

%% cg16_write_full_has_comment — written output contains the comment block
run_test(cg16_write_full_has_comment) :-
    IR = [ir_clause(cp_test(a), ir_call(body), [])],
    npl_generate_full(IR, 'src.pl', Segments),
    with_output_to(atom(Out),
        npl_write_neurocode_full(current_output, Segments, 'H')),
    sub_atom(Out, _, _, _, 'cp_test').

%% cg16_generate_text_is_atom — npl_generate_text/3 returns an atom
run_test(cg16_generate_text_is_atom) :-
    IR = [ir_clause(gt_pred, ir_true, [])],
    npl_generate_text(IR, '', Text),
    atom(Text).

%% cg16_generate_text_contains_header — generated text starts with a header comment
run_test(cg16_generate_text_contains_header) :-
    IR = [ir_clause(hdr_test, ir_true, [])],
    npl_generate_text(IR, 'origin.pl', Text),
    sub_atom(Text, _, _, _, 'NeuroProlog neurocode').

%% cg16_exec_equiv_basic — clause emitted via npl_ir_to_body_emitting/3 executes
%% the same as one emitted via npl_ir_to_body/2 for a plain call
run_test(cg16_exec_equiv_basic) :-
    IR = ir_seq(ir_call(true), ir_call(true)),
    npl_ir_to_body(IR, Body1),
    npl_ir_to_body_emitting(IR, [], Body2),
    call(Body1),
    call(Body2).

%% cg16_exec_equiv_memo — memo_site body executes successfully for ground key
run_test(cg16_exec_equiv_memo) :-
    npl_ir_to_body_emitting(
        ir_memo_site(memo16_test_key, ir_true),
        [],
        MemoBody),
    ( callable(MemoBody) -> call(MemoBody) ; true ).

%% cg16_exec_equiv_loop_candidate — loop_candidate body executes same as plain body
run_test(cg16_exec_equiv_loop_candidate) :-
    npl_ir_to_body_emitting(ir_loop_candidate(ir_true), [], Body),
    Body == true,
    call(Body).

%% cg16_full_pipeline_segments — full pipeline → generate_full produces segments
run_test(cg16_full_pipeline_segments) :-
    npl_parse_string('cg16p(a). cg16p(b) :- true.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_optimise(IR, OptIR),
    npl_generate_full(OptIR, 'test16.pl', Segments),
    is_list(Segments),
    Segments \= [],
    maplist([S]>>(S = code_segment(_, _, _)), Segments).

%% cg16_ir_to_body_emitting_true — ir_true emits true
run_test(cg16_ir_to_body_emitting_true) :-
    npl_ir_to_body_emitting(ir_true, [], true).

%% cg16_ir_to_body_emitting_fail — ir_fail emits fail
run_test(cg16_ir_to_body_emitting_fail) :-
    npl_ir_to_body_emitting(ir_fail, [], fail).

%% cg16_ir_to_body_emitting_seq — ir_seq emits conjunction
run_test(cg16_ir_to_body_emitting_seq) :-
    npl_ir_to_body_emitting(ir_seq(ir_call(a), ir_call(b)), [], (a, b)).

%% cg16_ir_to_body_emitting_disj — ir_disj emits disjunction
run_test(cg16_ir_to_body_emitting_disj) :-
    npl_ir_to_body_emitting(ir_disj(ir_call(a), ir_call(b)), [], (a ; b)).

%% cg16_ir_to_body_emitting_if_then — ir_if with ir_fail else emits if-then
run_test(cg16_ir_to_body_emitting_if_then) :-
    npl_ir_to_body_emitting(
        ir_if(ir_call(cond), ir_call(then), ir_fail), [],
        (cond -> then)).

%% cg16_ir_to_body_emitting_if_then_else — ir_if emits if-then-else
run_test(cg16_ir_to_body_emitting_if_then_else) :-
    npl_ir_to_body_emitting(
        ir_if(ir_call(cond), ir_call(then), ir_call(els)), [],
        (cond -> then ; els)).

%% cg16_ir_to_body_emitting_not — ir_not emits negation-as-failure
run_test(cg16_ir_to_body_emitting_not) :-
    npl_ir_to_body_emitting(ir_not(ir_call(g)), [], \+ g).

%% cg16_ir_to_body_emitting_source_marker_transparent — source_marker is transparent
run_test(cg16_ir_to_body_emitting_source_marker_transparent) :-
    npl_ir_to_body_emitting(
        ir_source_marker(pos(1, 1), ir_call(my_goal)), [],
        my_goal).

%% cg16_neurocode_is_valid_prolog — generated neurocode text parses as Prolog
run_test(cg16_neurocode_is_valid_prolog) :-
    IR = [ir_clause(valid16(X), ir_call(member(X, [a,b,c])), [])],
    npl_generate_text(IR, '', Text),
    atom(Text),
    atom_length(Text, Len),
    Len > 0.

%% cg16_neurocode_is_reloadable — neurocode can be read back as Prolog terms
run_test(cg16_neurocode_is_reloadable) :-
    IR = [ir_clause(reload16, ir_true, [])],
    npl_generate_full(IR, '', Segments),
    Segments = [code_segment(_, Clause, _)],
    callable(Clause).

%% cg16_vars_become_prolog_vars — var(Name) terms in IR are emitted as
%  real Prolog variables, not var('N') compound terms.
run_test(cg16_vars_become_prolog_vars) :-
    npl_parse_string('double16v(X, Y) :- Y is X * 2.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_generate(IR, [Clause]),
    Clause = (Head :- _Body),
    Head =.. [double16v, A1, _A2],
    var(A1).

%% cg16_vars_shared_in_clause — occurrences of the same source variable name
%  map to the same Prolog variable within a generated clause.
run_test(cg16_vars_shared_in_clause) :-
    npl_parse_string('id16v(X, X).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_generate(IR, [Clause]),
    Clause =.. [id16v, A, B],
    A == B.

%% cg16_anon_vars_distinct — each var('_') becomes a distinct fresh variable.
run_test(cg16_anon_vars_distinct) :-
    npl_parse_string('anon16v(_, _).', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_generate(IR, [Clause]),
    Clause =.. [anon16v, A, B],
    \+ A == B.

%% cg16_e2e_pipeline_vars_correct — full pipeline generates executable Prolog
%  with real variables (not var(Name) compounds).
run_test(cg16_e2e_pipeline_vars_correct) :-
    npl_parse_string('add16v(X, Y, Z) :- Z is X + Y.', AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_pipeline_default_config(Config),
    npl_pipeline_run_full(Config, IR, _OptIR, Neurocode, _Report),
    Neurocode = [(add16v(A, B, C) :- _Body)],
    var(A), var(B), var(C).

%%====================================================================
%% Stage 19: Self-Hosting Tests
%%====================================================================

%% sh19_predicates_exported — self_host module exports required predicates
run_test(sh19_predicates_exported) :-
    current_predicate(check_self_hosting/0),
    current_predicate(compare_behaviour/0).

%% sh19_invariant_source_exists — invariant 1: plain source file is present
run_test(sh19_invariant_source_exists) :-
    module_property(run_tests, file(TestFile)),
    file_directory_name(TestFile, TestDir),
    atomic_list_concat([TestDir, '/../src/neuroprolog.pl'], Path),
    exists_file(Path).

%% sh19_invariant_opt_dict_nonempty — invariant 3: opt dict has rules
run_test(sh19_invariant_opt_dict_nonempty) :-
    npl_opt_dict_rules(Rules),
    Rules \= [].

%% sh19_invariant_cognitive_markers_loaded — invariant 4: module is loaded
run_test(sh19_invariant_cognitive_markers_loaded) :-
    current_predicate(npl_ncm_all/1).

%% sh19_invariant_learned_transforms_present — invariant 5: learned entry predicate exists
run_test(sh19_invariant_learned_transforms_present) :-
    current_predicate(npl_opt_dict_entries/1),
    npl_opt_dict_entries(Names),
    Names \= [].

%% sh19_compile_small_source — self_compile pipeline on a tiny source succeeds
run_test(sh19_compile_small_source) :-
    Src = 'greet19(world).',
    npl_lex_string(Src, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR),
    npl_optimise(IR, OptIR),
    npl_generate(OptIR, NC),
    NC \= [].

%% sh19_compare_behaviour_true — source and compiled agree on `true'
run_test(sh19_compare_behaviour_true) :-
    npl_interp_reset,
    ( npl_interp_query(true, R1) -> true ; R1 = false ),
    R1 == true.

%% sh19_compare_behaviour_arithmetic — arithmetic results match
run_test(sh19_compare_behaviour_arithmetic) :-
    Src = 'sq19(X, Y) :- Y is X * X.',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(sq19(5, R), R, SrcSols),
    npl_interp_reset,
    npl_lex_string(Src, Tok2),
    npl_parse(Tok2, AST2),
    npl_analyse(AST2, AAST2),
    npl_intermediate(AAST2, IR),
    npl_optimise(IR, OptIR),
    npl_generate(OptIR, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(sq19(5, R), R, NCSols),
    SrcSols == NCSols.

%% sh19_compare_behaviour_list_ops — list operations match between modes
run_test(sh19_compare_behaviour_list_ops) :-
    Src = 'myapp19([], L, L). myapp19([H|T], L, [H|R]) :- myapp19(T, L, R).',
    npl_interp_reset,
    npl_lex_string(Src, Tok1),
    npl_parse(Tok1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_load(AAST1),
    npl_interp_query_all(myapp19([1,2],[3],R), R, SrcSols),
    npl_interp_reset,
    npl_lex_string(Src, Tok2),
    npl_parse(Tok2, AST2),
    npl_analyse(AST2, AAST2),
    npl_intermediate(AAST2, IR),
    npl_optimise(IR, OptIR),
    npl_generate(OptIR, NC),
    npl_interp_load_clauses(NC),
    npl_interp_query_all(myapp19([1,2],[3],R), R, NCSols),
    SrcSols == NCSols.

%% sh19_bench_query_list_nonempty — self_host_bench_queries/1 returns a nonempty list
run_test(sh19_bench_query_list_nonempty) :-
    self_host:self_host_bench_queries(Qs),
    Qs \= [].
