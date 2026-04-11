% pattern_correlation.pl — NeuroProlog Pattern Correlation Matcher (Stage 12)
%
% Identifies repeated logical forms by recording and correlating normalised
% structural patterns across goals and predicates.
%
% == Design ==
%
%   Patterns are stored in npl_pcorr_db/2 as:
%     npl_pcorr_db(+NormPattern, +Count)
%   where NormPattern is the output of npl_unfold_term/2 and Count is the
%   number of times that pattern has been recorded.
%
%   npl_pcorr_repeated/2 returns only those patterns seen more than once,
%   i.e. the repeated logical forms required by Stage 12.
%
% == IR correlation ==
%
%   npl_pcorr_record_ir/1 extracts all ir_call goals from an IR body and
%   records their patterns, enabling correlation across an entire IR list.

:- module(pattern_correlation, [
    npl_pcorr_record/1,
    npl_pcorr_lookup/2,
    npl_pcorr_correlate/3,
    npl_pcorr_repeated/2,
    npl_pcorr_all/1,
    npl_pcorr_clear/0,
    npl_pcorr_record_ir/1,
    npl_pcorr_ir_report/2
]).

:- use_module(unfolding).
:- use_module(library(lists)).

:- dynamic npl_pcorr_db/2.
%  npl_pcorr_db(+Pattern, +Count)
%  Stored count for each normalised structural pattern.

%%====================================================================
%% Recording
%%====================================================================

%% npl_pcorr_record/1
%  npl_pcorr_record(+Term)
%  Record the structural pattern of Term.  Increments the count for that
%  pattern, or inserts a new entry with count 1.
npl_pcorr_record(Term) :-
    npl_unfold_term(Term, Pattern),
    ( retract(npl_pcorr_db(Pattern, N)) ->
        N1 is N + 1
    ; N1 = 1
    ),
    assertz(npl_pcorr_db(Pattern, N1)).

%%====================================================================
%% Lookup and correlation
%%====================================================================

%% npl_pcorr_lookup/2
%  npl_pcorr_lookup(+Term, -Count)
%  Return the recorded occurrence Count for the pattern of Term.
%  Fails if the pattern has not been recorded.
npl_pcorr_lookup(Term, Count) :-
    npl_unfold_term(Term, Pattern),
    npl_pcorr_db(Pattern, Count).

%% npl_pcorr_correlate/3
%  npl_pcorr_correlate(+Term, -Pattern, -Count)
%  Return the normalised Pattern and its Count for Term.
%  Backtracks over all matching patterns (there is at most one per shape).
npl_pcorr_correlate(Term, Pattern, Count) :-
    npl_unfold_term(Term, Pattern),
    npl_pcorr_db(Pattern, Count).

%% npl_pcorr_repeated/2
%  npl_pcorr_repeated(+Term, -Count)
%  Succeed (and return Count) when the pattern of Term has been seen
%  more than once.  These are the repeated logical forms.
npl_pcorr_repeated(Term, Count) :-
    npl_unfold_term(Term, Pattern),
    npl_pcorr_db(Pattern, Count),
    Count >= 2.

%% npl_pcorr_all/1
%  npl_pcorr_all(-Entries)
%  Return all recorded pattern entries as a list of pcorr(Pattern, Count).
npl_pcorr_all(Entries) :-
    findall(pcorr(P, N), npl_pcorr_db(P, N), Entries).

%%====================================================================
%% Cache management
%%====================================================================

%% npl_pcorr_clear/0
%  Clear all recorded patterns.
npl_pcorr_clear :-
    retractall(npl_pcorr_db(_, _)).

%%====================================================================
%% IR-level correlation
%%====================================================================

%% npl_pcorr_record_ir/1
%  npl_pcorr_record_ir(+IRBody)
%  Extract all ir_call goals from IRBody and record their patterns.
npl_pcorr_record_ir(ir_call(Goal)) :- !,
    npl_pcorr_record(Goal).
npl_pcorr_record_ir(ir_true)   :- !.
npl_pcorr_record_ir(ir_fail)   :- !.
npl_pcorr_record_ir(ir_cut)    :- !.
npl_pcorr_record_ir(ir_repeat) :- !.
npl_pcorr_record_ir(ir_seq(A, B)) :- !,
    npl_pcorr_record_ir(A),
    npl_pcorr_record_ir(B).
npl_pcorr_record_ir(ir_disj(A, B)) :- !,
    npl_pcorr_record_ir(A),
    npl_pcorr_record_ir(B).
npl_pcorr_record_ir(ir_if(C, T, E)) :- !,
    npl_pcorr_record_ir(C),
    npl_pcorr_record_ir(T),
    npl_pcorr_record_ir(E).
npl_pcorr_record_ir(ir_not(G)) :- !,
    npl_pcorr_record_ir(G).
npl_pcorr_record_ir(ir_source_marker(_, B)) :- !,
    npl_pcorr_record_ir(B).
npl_pcorr_record_ir(ir_memo_site(_, B)) :- !,
    npl_pcorr_record_ir(B).
npl_pcorr_record_ir(ir_loop_candidate(B)) :- !,
    npl_pcorr_record_ir(B).
npl_pcorr_record_ir(ir_addr_loop(_, _, B)) :- !,
    npl_pcorr_record_ir(B).
npl_pcorr_record_ir(ir_choice_point(Alts)) :- !,
    maplist(npl_pcorr_record_ir, Alts).
npl_pcorr_record_ir(_).

%% npl_pcorr_ir_report/2
%  npl_pcorr_ir_report(+IR, -Report)
%  Given a flat IR list, record all call patterns and return a report of
%  patterns that appear more than once across the entire IR.
%  Report is a list of repeated(Pattern, Count) terms.
npl_pcorr_ir_report(IR, Report) :-
    npl_pcorr_clear,
    maplist(npl_pcorr_record_clause_body, IR),
    findall(repeated(P, N),
            ( npl_pcorr_db(P, N), N >= 2 ),
            Report).

npl_pcorr_record_clause_body(ir_clause(_, Body, _)) :- !,
    npl_pcorr_record_ir(Body).
npl_pcorr_record_clause_body(_).
