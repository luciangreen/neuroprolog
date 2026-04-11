% intermediate_codegen.pl — NeuroProlog Intermediate Code Generator
%
% Translates the annotated AST into an Intermediate Representation (IR).
%
% === Stage 8: Structured IR ===
%
% Top-level IR produced by npl_intermediate/2 is a flat list of ir_clause/3:
%
%   ir_clause(Head, IRBody, IRInfo)
%     Head   — clause head term
%     IRBody — body IR node (see below)
%     IRInfo — list of key:value annotations:
%       source_marker: pos(Line,Col) | no_pos
%       recursion_class: none | tail | linear | mutual | nested
%       choice_point: true | false
%       memo_site: true | false
%       loop_candidate: true | false
%       optimisation_meta: list of atoms
%       cognitive_marker: none | atom
%       head_status: ok | error(_)
%       body_status: ok | warning(_) | error(_)
%
% npl_ir_full/2 produces a grouped IR as a list of ir_predicate_def/3:
%
%   ir_predicate_def(Sig, Clauses, Meta)
%     Sig     — F/A functor/arity
%     Clauses — list of ir_clause/3 for that predicate
%     Meta    — predicate-level annotation list:
%       choice_point: true | false
%       recursion_class: none | tail | linear | mutual | nested
%       memo_site: true | false
%       loop_candidate: true | false
%
% === IR Body Nodes ===
%
%   ir_true                          — the goal `true`
%   ir_fail                          — the goal `fail`
%   ir_cut                           — the cut operator `!`
%   ir_repeat                        — the goal `repeat`
%   ir_call(Goal)                    — a plain goal call
%   ir_not(IRGoal)                   — negation-as-failure \+
%   ir_seq(IRA, IRB)                 — conjunction (A, B)
%   ir_disj(IRA, IRB)               — disjunction (A ; B)
%   ir_if(IRCond, IRThen, IRElse)   — if-then-else / if-then
%   ir_choice_point(Alternatives)   — explicit n-way choice; Alternatives is a list of IRBody
%   ir_source_marker(Pos, IRBody)   — source position annotation wrapping IRBody
%   ir_memo_site(Head, IRBody)      — memoisation-candidate wrapper; Head is clause head
%   ir_loop_candidate(IRBody)       — loop/accumulator-candidate wrapper

:- module(intermediate_codegen, [npl_intermediate/2, npl_body_to_ir/2,
                                  npl_ir_full/2, npl_ir_info_get/3]).

:- use_module(library(lists)).

%%====================================================================
%% Public API
%%====================================================================

%% npl_intermediate/2
%  npl_intermediate(+AAST, -IR)
%  Produce a flat list of ir_clause/3 from an annotated AST.
npl_intermediate(AAST, IR) :-
    npl_filter_compilable(AAST, Compilable),
    npl_mark_choice_points(Compilable, Marked),
    maplist(npl_clause_to_ir, Marked, IR).

%% npl_ir_full/2
%  npl_ir_full(+AAST, -PredDefs)
%  Produce a list of ir_predicate_def/3 grouped by functor/arity.
npl_ir_full(AAST, PredDefs) :-
    npl_intermediate(AAST, FlatIR),
    npl_group_by_predicate(FlatIR, PredDefs).

%% npl_ir_info_get/3
%  npl_ir_info_get(+IRInfo, +Key, -Value)
%  Retrieve a value from an ir_clause Info term.
%  Works with the structured list format [key:value,...] and the legacy
%  info(key:value, ...) functor format produced by manual IR construction.
npl_ir_info_get(Info, Key, Value) :-
    is_list(Info), !,
    member(Key:Value, Info).
npl_ir_info_get(Info, Key, Value) :-
    Info =.. [info|Pairs],
    member(Key:Value, Pairs).

%%====================================================================
%% Filtering and choice-point marking
%%====================================================================

%% npl_filter_compilable(+Nodes, -Compilable)
%% Keep only nodes that map to IR clauses (analysed/3 and legacy clause/2).
npl_filter_compilable([], []).
npl_filter_compilable([H|T], [H|Rest]) :-
    npl_is_compilable_node(H), !,
    npl_filter_compilable(T, Rest).
npl_filter_compilable([_|T], Rest) :-
    npl_filter_compilable(T, Rest).

%% npl_is_compilable_node/1
npl_is_compilable_node(analysed(_, _, _)).
npl_is_compilable_node(clause(_, _)).

%% npl_mark_choice_points/2
%  Tag each analysed/3 node with choice_point:true when the same
%  functor/arity appears more than once in the compilable list.
npl_mark_choice_points(Nodes, Marked) :-
    npl_count_sigs(Nodes, Counts),
    maplist(npl_tag_choice_point(Counts), Nodes, Marked).

%% npl_count_sigs/2
%  Build a list of Sig-Count pairs from a node list.
npl_count_sigs(Nodes, Counts) :-
    npl_extract_sigs(Nodes, Sigs),
    msort(Sigs, Sorted),
    npl_tally(Sorted, Counts).

npl_extract_sigs([], []).
npl_extract_sigs([analysed(Head, _, _)|Rest], [Sig|Sigs]) :- !,
    npl_head_sig_ic(Head, Sig),
    npl_extract_sigs(Rest, Sigs).
npl_extract_sigs([clause(Head, _)|Rest], [Sig|Sigs]) :- !,
    npl_head_sig_ic(Head, Sig),
    npl_extract_sigs(Rest, Sigs).
npl_extract_sigs([_|Rest], Sigs) :-
    npl_extract_sigs(Rest, Sigs).

npl_head_sig_ic(Head, F/A) :-
    callable(Head), Head =.. [F|Args], length(Args, A), !.
npl_head_sig_ic(_, unknown/0).

npl_tally([], []).
npl_tally([Sig|Sigs], [Sig-Count|Counts]) :-
    npl_count_prefix(Sigs, Sig, Count0, Rest),
    Count is Count0 + 1,
    npl_tally(Rest, Counts).

npl_count_prefix([], _, 0, []).
npl_count_prefix([H|T], H, N, Rest) :- !,
    npl_count_prefix(T, H, N0, Rest),
    N is N0 + 1.
npl_count_prefix(L, _, 0, L).

%% npl_tag_choice_point/3
npl_tag_choice_point(Counts, analysed(Head, Body, Props),
                     analysed(Head, Body, TaggedProps)) :- !,
    npl_head_sig_ic(Head, Sig),
    ( member(Sig-Count, Counts), Count > 1 -> CP = true ; CP = false ),
    ( member(choice_point:_, Props) ->
        TaggedProps = Props
    ;
        append(Props, [choice_point:CP], TaggedProps)
    ).
npl_tag_choice_point(_, Node, Node).

%%====================================================================
%% Clause-to-IR conversion
%%====================================================================

%% npl_clause_to_ir/2
npl_clause_to_ir(analysed(Head, Body, Props),
                 ir_clause(Head, IRBody, IRInfo)) :-
    npl_body_to_ir(Body, IRBody),
    npl_props_to_ir_info(Props, IRInfo).
npl_clause_to_ir(clause(Head, Body),
                 ir_clause(Head, IRBody, info(head:ok, body:ok))) :-
    npl_body_to_ir(Body, IRBody).

%% npl_props_to_ir_info/2
%  Derive a structured IRInfo list from analysed Props.
npl_props_to_ir_info(Props, IRInfo) :-
    npl_prop_val(Props, source_pos,                   Pos,      no_pos),
    npl_prop_val(Props, recursion_class,               RecClass, none),
    npl_prop_val(Props, choice_point,                  CP,       false),
    npl_prop_val(Props, memoisation_suitable,          MemoOk,   false),
    %% gaussian_elimination_suitable = true means the predicate can be reduced
    %% to an accumulator/iterative form — i.e. it is a loop candidate.
    npl_prop_val(Props, gaussian_elimination_suitable, GaussOk,  false),
    npl_prop_val(Props, simplification_opportunities,  Simps,    []),
    npl_prop_val(Props, cognitive_code_marker,         Marker,   none),
    npl_prop_val(Props, head,                          HStatus,  ok),
    npl_prop_val(Props, body,                          BStatus,  ok),
    IRInfo = [ source_marker:     Pos,
               recursion_class:   RecClass,
               choice_point:      CP,
               memo_site:         MemoOk,
               loop_candidate:    GaussOk,
               optimisation_meta: Simps,
               cognitive_marker:  Marker,
               head_status:       HStatus,
               body_status:       BStatus ].

%% npl_prop_val(+Props, +Key, -Value, +Default)
npl_prop_val(Props, Key, Value, Default) :-
    ( member(Key:Value, Props) -> true ; Value = Default ).

%%====================================================================
%% IR grouping into predicate definitions
%%====================================================================

%% npl_group_by_predicate/2
%  Group a flat ir_clause list into ir_predicate_def/3 terms.
npl_group_by_predicate([], []).
npl_group_by_predicate([C|Cs], [ir_predicate_def(Sig, [C|Same], Meta)|Rest]) :-
    C = ir_clause(Head, _, _),
    npl_head_sig_ic(Head, Sig),
    partition(npl_clause_has_sig(Sig), Cs, Same, Others),
    npl_predicate_meta([C|Same], Meta),
    npl_group_by_predicate(Others, Rest).

npl_clause_has_sig(Sig, ir_clause(Head, _, _)) :-
    npl_head_sig_ic(Head, Sig).

%% npl_predicate_meta/2
%  Compute predicate-level metadata from a list of ir_clause/3.
npl_predicate_meta(Clauses, Meta) :-
    length(Clauses, N),
    ( N > 1 -> CP = true ; CP = false ),
    ( Clauses = [ir_clause(_, _, Info)|_] ->
        ( npl_ir_info_get(Info, recursion_class, RC) -> true ; RC = none ),
        ( npl_ir_info_get(Info, memo_site,        MS) -> true ; MS = false ),
        ( npl_ir_info_get(Info, loop_candidate,   LC) -> true ; LC = false )
    ;
        RC = none, MS = false, LC = false
    ),
    Meta = [ choice_point:    CP,
             recursion_class: RC,
             memo_site:       MS,
             loop_candidate:  LC ].

%%====================================================================
%% Body-to-IR translation
%%====================================================================

%% npl_body_to_ir/2
%% NOTE: The if-then-else clause (';'('->'(...), ...)) MUST appear before
%% the general disjunction clause (';'(A, B)) so that (Cond -> Then ; Else)
%% is correctly recognised as ir_if rather than ir_disj.
npl_body_to_ir(true, ir_true) :- !.
npl_body_to_ir(fail, ir_fail) :- !.
npl_body_to_ir(repeat, ir_repeat) :- !.
npl_body_to_ir(\+(Goal), ir_not(IRGoal)) :- !,
    npl_body_to_ir(Goal, IRGoal).
npl_body_to_ir(','(A, B), ir_seq(IRA, IRB)) :- !,
    npl_body_to_ir(A, IRA),
    npl_body_to_ir(B, IRB).
npl_body_to_ir(';'('->'(Cond, Then), Else), ir_if(IRCond, IRThen, IRElse)) :- !,
    npl_body_to_ir(Cond, IRCond),
    npl_body_to_ir(Then, IRThen),
    npl_body_to_ir(Else, IRElse).
npl_body_to_ir(';'(A, B), ir_disj(IRA, IRB)) :- !,
    npl_body_to_ir(A, IRA),
    npl_body_to_ir(B, IRB).
npl_body_to_ir('->'(Cond, Then), ir_if(IRCond, IRThen, ir_fail)) :- !,
    npl_body_to_ir(Cond, IRCond),
    npl_body_to_ir(Then, IRThen).
npl_body_to_ir(!, ir_cut) :- !.
npl_body_to_ir(Goal, ir_call(Goal)).
