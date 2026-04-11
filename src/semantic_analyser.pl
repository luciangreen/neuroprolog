% semantic_analyser.pl — NeuroProlog Semantic Analyser (Stage 5)
%
% Validates and annotates the AST produced by the parser.
%
% Checks performed:
%   - predicate arity consistency
%   - variable usage (singleton variable detection)
%   - control structure placement (cut, if-then-else)
%   - recursion form identification (tail, linear, mutual, nested)
%   - memoisation candidate detection
%   - subterm-address looping candidate detection
%
% Annotation fields on each analysed/3 node:
%   head           : ok | error(non_callable_head)
%   body           : ok | warning(...) | error(...)
%   variables      : ok | warning(singletons, [Var,...])
%   control        : ok | warning(misplaced_cut) | warning(bare_if_then)
%   recursion_class: none | tail | linear | mutual | nested
%   eliminable_nested_recursion : true | false
%   memoisation_suitable        : true | false
%   gaussian_elimination_suitable: true | false
%   simplification_opportunities: list of atoms
%   cognitive_code_marker       : none | Marker
%
% Accepts both the new rich AST (fact/4, rule/5, directive/4, query/4,
% parse_error/2) and the legacy clause/2 format for backward compatibility.
% Directives, queries, and parse errors are passed through unchanged.

:- module(semantic_analyser, [npl_analyse/2,
                              npl_classify_recursion/5,
                              npl_eliminable_nested/2]).

:- use_module(library(lists)).

%%====================================================================
%% Public API
%%====================================================================

%% npl_analyse/2
%  npl_analyse(+AST, -AnnotatedAST)
npl_analyse(AST, AAST) :-
    npl_collect_signatures(AST, Sigs),
    maplist(npl_analyse_node(Sigs, AST), AST, AAST).

%%====================================================================
%% Signature collection
%%====================================================================

%% npl_collect_signatures/2
%% Gather functor/arity signatures for all facts and rules in the AST.
npl_collect_signatures([], []).
npl_collect_signatures([fact(Head, _, _, _)|Cs], [Sig|Sigs]) :- !,
    npl_head_sig(Head, Sig),
    npl_collect_signatures(Cs, Sigs).
npl_collect_signatures([rule(Head, _, _, _, _)|Cs], [Sig|Sigs]) :- !,
    npl_head_sig(Head, Sig),
    npl_collect_signatures(Cs, Sigs).
npl_collect_signatures([clause(Head, _)|Cs], [Sig|Sigs]) :- !,
    npl_head_sig(Head, Sig),
    npl_collect_signatures(Cs, Sigs).
%% Directives, queries, parse errors contribute no signatures.
npl_collect_signatures([_|Cs], Sigs) :-
    npl_collect_signatures(Cs, Sigs).

%% npl_head_sig(+Head, -Sig)
npl_head_sig(Head, F/Arity) :-
    callable(Head), Head =.. [F|Args],
    length(Args, Arity), !.
npl_head_sig(_, unknown/0).

%%====================================================================
%% Per-node analysis
%%====================================================================

%% npl_analyse_node(+Sigs, +FullAST, +Node, -AnnotatedNode)

%% New AST: fact — body is implicitly true
npl_analyse_node(Sigs, AST, fact(Head, Pos, Annots, _M),
                 analysed(Head, true, Props)) :- !,
    npl_check_head(Head, Sigs, HeadInfo),
    npl_check_vars(Head, true, VarInfo),
    npl_check_control(Head, true, CtrlInfo),
    npl_head_sig(Head, Sig),
    npl_classify_recursion(Sig, Head, true, AST, RecClass),
    npl_eliminable_nested(RecClass, Eliminable),
    npl_memo_suitable(Head, true, MemoOk),
    npl_gaussian_suitable(RecClass, GaussOk),
    npl_simplification_ops(Head, true, RecClass, Simps),
    npl_cognitive_marker(Annots, Marker),
    Props = [ head:HeadInfo,
              body:ok,
              variables:VarInfo,
              control:CtrlInfo,
              recursion_class:RecClass,
              eliminable_nested_recursion:Eliminable,
              memoisation_suitable:MemoOk,
              gaussian_elimination_suitable:GaussOk,
              simplification_opportunities:Simps,
              cognitive_code_marker:Marker,
              source_pos:Pos ].

%% New AST: rule
npl_analyse_node(Sigs, AST, rule(Head, Body, Pos, Annots, _M),
                 analysed(Head, Body, Props)) :- !,
    npl_check_head(Head, Sigs, HeadInfo),
    npl_check_body(Body, Sigs, BodyInfo),
    npl_check_vars(Head, Body, VarInfo),
    npl_check_control(Head, Body, CtrlInfo),
    npl_head_sig(Head, Sig),
    npl_classify_recursion(Sig, Head, Body, AST, RecClass),
    npl_eliminable_nested(RecClass, Eliminable),
    npl_memo_suitable(Head, Body, MemoOk),
    npl_gaussian_suitable(RecClass, GaussOk),
    npl_simplification_ops(Head, Body, RecClass, Simps),
    npl_cognitive_marker(Annots, Marker),
    Props = [ head:HeadInfo,
              body:BodyInfo,
              variables:VarInfo,
              control:CtrlInfo,
              recursion_class:RecClass,
              eliminable_nested_recursion:Eliminable,
              memoisation_suitable:MemoOk,
              gaussian_elimination_suitable:GaussOk,
              simplification_opportunities:Simps,
              cognitive_code_marker:Marker,
              source_pos:Pos ].

%% New AST: directive — pass through unchanged
npl_analyse_node(_Sigs, _AST, directive(Goal, Pos, A, M),
                 directive(Goal, Pos, A, M)) :- !.

%% New AST: query — pass through unchanged
npl_analyse_node(_Sigs, _AST, query(Goal, Pos, A, M),
                 query(Goal, Pos, A, M)) :- !.

%% New AST: parse error — pass through unchanged
npl_analyse_node(_Sigs, _AST, parse_error(Msg, Pos),
                 parse_error(Msg, Pos)) :- !.

%% Legacy: clause/2
npl_analyse_node(Sigs, AST, clause(Head, Body),
                 analysed(Head, Body, Props)) :- !,
    npl_check_head(Head, Sigs, HeadInfo),
    npl_check_body(Body, Sigs, BodyInfo),
    npl_check_vars(Head, Body, VarInfo),
    npl_check_control(Head, Body, CtrlInfo),
    npl_head_sig(Head, Sig),
    npl_classify_recursion(Sig, Head, Body, AST, RecClass),
    npl_eliminable_nested(RecClass, Eliminable),
    npl_memo_suitable(Head, Body, MemoOk),
    npl_gaussian_suitable(RecClass, GaussOk),
    npl_simplification_ops(Head, Body, RecClass, Simps),
    Props = [ head:HeadInfo,
              body:BodyInfo,
              variables:VarInfo,
              control:CtrlInfo,
              recursion_class:RecClass,
              eliminable_nested_recursion:Eliminable,
              memoisation_suitable:MemoOk,
              gaussian_elimination_suitable:GaussOk,
              simplification_opportunities:Simps,
              cognitive_code_marker:none ].

%%====================================================================
%% Head checking
%%====================================================================

%% npl_check_head/3
npl_check_head(Head, _Sigs, ok) :-
    callable(Head), !.
npl_check_head(_, _, error(non_callable_head)).

%%====================================================================
%% Body checking
%%====================================================================

%% npl_check_body/3
npl_check_body(true, _, ok) :- !.
npl_check_body(','(A, B), Sigs, info(A:IA, B:IB)) :- !,
    npl_check_body(A, Sigs, IA),
    npl_check_body(B, Sigs, IB).
npl_check_body(Goal, Sigs, Info) :-
    ( callable(Goal) ->
        ( Goal =.. [F|Args], length(Args, Arity),
          ( member(F/Arity, Sigs)
          -> Info = ok
          ;  npl_builtin(F/Arity)
          -> Info = ok
          ;  Info = warning(possibly_undefined, Goal)
          )
        )
    ; Info = error(non_callable_goal, Goal)
    ).

%% npl_builtin/1
%% Known built-in predicates that need not appear in the source signatures.
npl_builtin(true/0).
npl_builtin(fail/0).
npl_builtin(false/0).
npl_builtin(!/0).
npl_builtin(repeat/0).
npl_builtin(nl/0).
npl_builtin(halt/0).
npl_builtin(halt/1).
npl_builtin(call/1).
npl_builtin(call/2).
npl_builtin(call/3).
npl_builtin(call/4).
npl_builtin(assert/1).
npl_builtin(assertz/1).
npl_builtin(asserta/1).
npl_builtin(retract/1).
npl_builtin(retractall/1).
npl_builtin(functor/3).
npl_builtin(arg/3).
npl_builtin('=..'/2).
npl_builtin(copy_term/2).
npl_builtin(var/1).
npl_builtin(nonvar/1).
npl_builtin(atom/1).
npl_builtin(number/1).
npl_builtin(integer/1).
npl_builtin(float/1).
npl_builtin(compound/1).
npl_builtin(atomic/1).
npl_builtin(callable/1).
npl_builtin(ground/1).
npl_builtin(is_list/1).
npl_builtin('='/2).
npl_builtin('\\='/2).
npl_builtin('=='/2).
npl_builtin('\\=='/2).
npl_builtin(is/2).
npl_builtin('<'/2).
npl_builtin('>'/2).
npl_builtin('=<'/2).
npl_builtin('>='/2).
npl_builtin('=:='/2).
npl_builtin('=\\='/2).
npl_builtin(write/1).
npl_builtin(writeln/1).
npl_builtin(read/1).
npl_builtin(format/2).
npl_builtin(format/1).
npl_builtin(succ/2).
npl_builtin(plus/3).
npl_builtin(length/2).
npl_builtin(append/3).
npl_builtin(member/2).
npl_builtin(memberchk/2).
npl_builtin(nth0/3).
npl_builtin(nth1/3).
npl_builtin(last/2).
npl_builtin(msort/2).
npl_builtin(sort/2).
npl_builtin(findall/3).
npl_builtin(bagof/3).
npl_builtin(setof/3).
npl_builtin(aggregate_all/3).
npl_builtin(forall/2).
npl_builtin(between/3).
npl_builtin(succ_or_zero/2).
npl_builtin('\\+'/1).
npl_builtin(not/1).
npl_builtin('->'/2).
npl_builtin(';'/2).
npl_builtin(','/2).
npl_builtin(catch/3).
npl_builtin(throw/1).
npl_builtin(ignore/1).
npl_builtin(once/1).
npl_builtin(number_codes/2).
npl_builtin(number_chars/2).
npl_builtin(atom_codes/2).
npl_builtin(atom_chars/2).
npl_builtin(atom_length/2).
npl_builtin(atom_concat/3).
npl_builtin(char_code/2).
npl_builtin(sub_atom/5).
npl_builtin(atom_string/2).
npl_builtin(string_concat/3).
npl_builtin(string_codes/2).
npl_builtin(upcase_atom/2).
npl_builtin(downcase_atom/2).
npl_builtin(open/3).
npl_builtin(open/4).
npl_builtin(close/1).
npl_builtin(read_term/2).
npl_builtin(write_term/2).
npl_builtin(write_term/3).
npl_builtin(writef/2).
npl_builtin(print/1).
npl_builtin(tab/1).
npl_builtin(flush_output/0).
npl_builtin(flush_output/1).
npl_builtin('dynamic'/1).
npl_builtin(module/2).
npl_builtin('use_module'/1).
npl_builtin(consult/1).
npl_builtin(numlist/3).
npl_builtin(maplist/2).
npl_builtin(maplist/3).
npl_builtin(maplist/4).
npl_builtin(include/3).
npl_builtin(exclude/3).
npl_builtin(foldl/4).
npl_builtin(foldl/5).
npl_builtin(partition/4).
npl_builtin(partition/5).
npl_builtin(pairs_keys_values/3).
npl_builtin(pairs_keys/2).
npl_builtin(pairs_values/2).
npl_builtin(max_list/2).
npl_builtin(min_list/2).
npl_builtin(sum_list/2).
npl_builtin(select/3).
npl_builtin(permutation/2).
npl_builtin(subtract/3).
npl_builtin(intersection/3).
npl_builtin(union/3).
npl_builtin(list_to_set/2).
npl_builtin(delete/3).
npl_builtin(reverse/2).
npl_builtin(flatten/2).
npl_builtin(max_member/2).
npl_builtin(min_member/2).
npl_builtin(compare/3).
npl_builtin('@<'/2).
npl_builtin('@>'/2).
npl_builtin('@=<'/2).
npl_builtin('@>='/2).
npl_builtin(nb_getval/2).
npl_builtin(nb_setval/2).
npl_builtin(char_type/2).
npl_builtin(string_to_atom/2).
npl_builtin(term_to_atom/2).
npl_builtin(predsort/3).

%%====================================================================
%% Variable usage checking (singleton detection)
%%====================================================================

%% npl_check_vars(+Head, +Body, -Info)
%% Warn about variable names that appear exactly once in Head+Body.
%% Anonymous variables (var('_')) are excluded from singleton warnings.
%% Works with both native Prolog variables and the parsed var(Name) representation.
npl_check_vars(Head, Body, Info) :-
    npl_collect_var_names(Head, HNames),
    npl_collect_var_names(Body, BNames),
    append(HNames, BNames, AllNames),
    include(npl_non_anonymous, AllNames, Named),
    npl_singleton_names(Named, Singletons),
    ( Singletons = []
    -> Info = ok
    ;  Info = warning(singletons, Singletons)
    ).

%% npl_non_anonymous(+Name) — succeeds unless Name is '_'.
npl_non_anonymous('_') :- !, fail.
npl_non_anonymous(_).

%% npl_collect_var_names(+Term, -Names)
%% Collect all var(Name) atom names in Term (parsed AST representation).
npl_collect_var_names(var(Name), [Name]) :- !.
npl_collect_var_names(Term, Names) :-
    ( compound(Term) ->
        Term =.. [_|Args],
        maplist(npl_collect_var_names, Args, NameLists),
        append(NameLists, Names)
    ; is_list(Term) ->
        maplist(npl_collect_var_names, Term, NameLists),
        append(NameLists, Names)
    ; Names = []
    ).

%% npl_singleton_names(+Names, -Singletons)
%% Return atom names that appear exactly once in Names.
npl_singleton_names(Names, Singletons) :-
    msort(Names, Sorted),
    npl_find_singletons(Sorted, Singletons).

npl_find_singletons([], []).
npl_find_singletons([N], [N]) :- !.
npl_find_singletons([N, N|Rest], Singletons) :- !,
    npl_skip_duplicates(N, Rest, After),
    npl_find_singletons(After, Singletons).
npl_find_singletons([N|Rest], [N|Singletons]) :-
    npl_find_singletons(Rest, Singletons).

npl_skip_duplicates(_, [], []) :- !.
npl_skip_duplicates(N, [N|Rest], After) :- !,
    npl_skip_duplicates(N, Rest, After).
npl_skip_duplicates(_, Rest, Rest).

%%====================================================================
%% Control structure placement checking
%%====================================================================

%% npl_check_control(+Head, +Body, -Info)
%% Warns about: cut (!) in a fact body, bare if-then without else.
npl_check_control(_Head, true, ok) :- !.
npl_check_control(Head, Body, Info) :-
    ( Head == (!) ->
        Info = warning(misplaced_cut, head_is_cut)
    ; npl_body_has_bare_ifthen(Body) ->
        Info = warning(bare_if_then, Body)
    ;   Info = ok
    ).

%% npl_body_has_bare_ifthen(+Body)
%% Detect a naked '->'(Cond,Then) not wrapped in ';'(_, _).
npl_body_has_bare_ifthen('->'(_, _)) :- !.
npl_body_has_bare_ifthen(','(A, _)) :- npl_body_has_bare_ifthen(A), !.
npl_body_has_bare_ifthen(','(_, B)) :- npl_body_has_bare_ifthen(B).

%%====================================================================
%% Recursion classification
%%====================================================================

%% npl_classify_recursion(+Sig, +Head, +Body, +FullAST, -Class)
%% Class: none | tail | linear | mutual | nested
npl_classify_recursion(Sig, Head, Body, AST, Class) :-
    ( \+ callable(Head) ->
        Class = none
    ;
        npl_collect_recursive_calls(Sig, Body, RecCalls),
        npl_count_recursive_calls(Sig, Body, DirectCount),
        npl_body_last_call(Body, LastCall),
        ( DirectCount =:= 0 ->
            ( npl_has_mutual_recursion(Sig, Body, AST) ->
                Class = mutual
            ;   Class = none
            )
        ; DirectCount =:= 1 ->
            ( callable(LastCall),
              functor(LastCall, F, A),
              Sig = F/A ->
                Class = tail
            ;   Class = linear
            )
        ;   % Multiple recursive calls — check for nesting
            ( npl_has_nested_recursion(Sig, RecCalls) ->
                Class = nested
            ;   Class = linear
            )
        )
    ).

%% npl_collect_recursive_calls(+Sig, +Body, -Calls)
%% Collect all direct recursive calls to Sig in Body.
npl_collect_recursive_calls(Sig, Body, Calls) :-
    npl_body_goals(Body, Goals),
    include(npl_matches_sig(Sig), Goals, Calls).

npl_matches_sig(F/A, Goal) :-
    callable(Goal),
    functor(Goal, F, A).

%% npl_count_recursive_calls(+Sig, +Body, -N)
npl_count_recursive_calls(Sig, Body, N) :-
    npl_collect_recursive_calls(Sig, Body, Calls),
    length(Calls, N).

%% npl_body_goals(+Body, -Goals)
%% Flatten a conjunction/disjunction body into a list of atomic goals.
npl_body_goals(true, []) :- !.
npl_body_goals(','(A, B), Goals) :- !,
    npl_body_goals(A, GA),
    npl_body_goals(B, GB),
    append(GA, GB, Goals).
npl_body_goals(';'(A, B), Goals) :- !,
    npl_body_goals(A, GA),
    npl_body_goals(B, GB),
    append(GA, GB, Goals).
npl_body_goals('->'(A, B), Goals) :- !,
    npl_body_goals(A, GA),
    npl_body_goals(B, GB),
    append(GA, GB, Goals).
npl_body_goals('\\+'(G), Goals) :- !,
    npl_body_goals(G, Goals).
npl_body_goals(Goal, [Goal]).

%% npl_body_last_call(+Body, -Last)
%% Return the last atomic goal in a conjunctive body.
npl_body_last_call(','(_, B), Last) :- !,
    npl_body_last_call(B, Last).
npl_body_last_call(Goal, Goal).

%% npl_has_nested_recursion(+Sig, +RecCalls)
%% Succeeds when any recursive call has an argument that itself
%% contains another recursive call (nested recursion pattern).
npl_has_nested_recursion(F/A, RecCalls) :-
    member(Call, RecCalls),
    Call =.. [F|Args],
    length(Args, A),
    member(Arg, Args),
    term_variables(Arg, _),
    npl_subterm_contains_sig(F/A, Arg).

npl_subterm_contains_sig(Sig, Term) :-
    compound(Term),
    Term =.. [_|Args],
    member(Arg, Args),
    ( npl_matches_sig(Sig, Arg)
    ; npl_subterm_contains_sig(Sig, Arg)
    ).

%% npl_has_mutual_recursion(+Sig, +Body, +AST)
%% Succeed when Body contains a call P where P's definition calls back Sig.
npl_has_mutual_recursion(Sig, Body, AST) :-
    npl_body_goals(Body, Goals),
    member(Goal, Goals),
    callable(Goal),
    \+ npl_matches_sig(Sig, Goal),
    functor(Goal, GF, GA),
    npl_ast_body_for(GF/GA, AST, CalledBody),
    npl_body_goals(CalledBody, CalledGoals),
    member(BackCall, CalledGoals),
    callable(BackCall),
    npl_matches_sig(Sig, BackCall).

%% npl_ast_body_for(+Sig, +AST, -Body)
%% Find the body of a rule for Sig in the AST.
npl_ast_body_for(F/A, [rule(Head, Body, _, _, _)|_], Body) :-
    callable(Head), functor(Head, F, A), !.
npl_ast_body_for(Sig, [_|Rest], Body) :-
    npl_ast_body_for(Sig, Rest, Body).

%%====================================================================
%% Derived annotation predicates
%%====================================================================

%% npl_eliminable_nested(+RecClass, -Boolean)
npl_eliminable_nested(nested, true) :- !.
npl_eliminable_nested(_, false).

%% npl_memo_suitable(+Head, +Body, -Boolean)
%% A predicate is a memoisation candidate when:
%%   - its head is callable,
%%   - its body is free of side-effect operators (assert/retract/IO),
%%   - it has at least one argument (parameterised).
npl_memo_suitable(Head, Body, Result) :-
    ( callable(Head),
      Head =.. [_|Args],
      Args \= [],
      \+ npl_body_has_side_effects(Body)
    -> Result = true
    ;  Result = false
    ).

%% npl_body_has_side_effects(+Body)
npl_body_has_side_effects(Body) :-
    npl_body_goals(Body, Goals),
    member(Goal, Goals),
    npl_is_side_effect(Goal).

npl_is_side_effect(assert(_)).
npl_is_side_effect(assertz(_)).
npl_is_side_effect(asserta(_)).
npl_is_side_effect(retract(_)).
npl_is_side_effect(retractall(_)).
npl_is_side_effect(write(_)).
npl_is_side_effect(writeln(_)).
npl_is_side_effect(nl).
npl_is_side_effect(format(_, _)).
npl_is_side_effect(format(_)).
npl_is_side_effect(read(_)).
npl_is_side_effect(read_term(_, _)).
npl_is_side_effect(open(_, _, _)).
npl_is_side_effect(open(_, _, _, _)).
npl_is_side_effect(close(_)).
npl_is_side_effect(nb_setval(_, _)).

%% npl_gaussian_suitable(+RecClass, -Boolean)
%% Linear-tail-recursive predicates may be candidates for Gaussian elimination.
npl_gaussian_suitable(tail, true) :- !.
npl_gaussian_suitable(linear, true) :- !.
npl_gaussian_suitable(_, false).

%% npl_simplification_ops(+Head, +Body, +RecClass, -Ops)
%% Identify simplification opportunities applicable to this clause.
npl_simplification_ops(Head, Body, RecClass, Ops) :-
    npl_body_goals(Body, Goals),
    ( RecClass = tail       -> Ops0 = [tail_call_optimisation] ; Ops0 = [] ),
    ( RecClass = linear     -> Ops1 = [accumulator_introduction|Ops0] ; Ops1 = Ops0 ),
    ( RecClass = nested     -> Ops2 = [eliminate_nested_recursion|Ops1] ; Ops2 = Ops1 ),
    ( RecClass = mutual     -> Ops3 = [inline_mutual_call|Ops2] ; Ops3 = Ops2 ),
    ( npl_body_has_true(Goals) -> Ops4 = [remove_trivial_true|Ops3] ; Ops4 = Ops3 ),
    ( callable(Head), Head =.. [_|Args], length(Args, A), A > 0,
      npl_body_has_is(Goals)
      -> Ops5 = [arithmetic_simplification|Ops4]
      ;  Ops5 = Ops4
    ),
    Ops = Ops5.

npl_body_has_true(Goals) :- member(true, Goals).

npl_body_has_is(Goals) :-
    member(Goal, Goals),
    Goal =.. [is|_].

%% npl_cognitive_marker(+Annots, -Marker)
%% Extract the first cognitive-code annotation, if present.
npl_cognitive_marker([A|_], A) :- !.
npl_cognitive_marker([], none).
