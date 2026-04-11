% cognitive_markers.pl — NeuroProlog Cognitive Markers and Neurocode Mapping (Stage 14)
%
% Preserves correspondence between original source clauses and their
% optimised neurocode equivalents for provenance, maintainability,
% and self-rebuild continuity.
%
% == Marker Schema ==
%
%   npl_ncm_entry(OriginalClause, CogMarker, NeurocodeFragment, OptSteps, Meta)
%     OriginalClause    — original ir_clause/3 term (before optimisation)
%     CogMarker         — cognitive/code marker atom from IR info, or 'none'
%     NeurocodeFragment — generated Prolog clause term (after optimisation)
%     OptSteps          — list of optimisation step name atoms applied
%     Meta              — list of key:value metadata pairs; always includes:
%                           pred_sig:       F/A  functor/arity
%                           source_marker:  Pos | no_pos
%                           rebuild_version: 1
%
% == Mapping Tools ==
%
%   npl_ncm_record/5            — assert a single mapping entry
%   npl_ncm_lookup_by_marker/2  — retrieve entries by cognitive marker
%   npl_ncm_lookup_by_head/2    — retrieve entries by head functor/arity
%   npl_ncm_all/1               — retrieve all recorded mappings as a list
%   npl_ncm_clear/0             — retract all mapping entries
%   npl_ncm_build_from_ir/4     — build mappings from (OrigIR, OptIR, Neurocode)
%   npl_ncm_trace_report/1      — produce a structured trace report list
%   npl_ncm_report_entry/2      — format a single ncm/5 entry as a report line
%
% == Trace Report ==
%
%   npl_ncm_trace_report/1 produces a list of:
%     trace_entry(CogMarker, OrigHead, NeurocodeFragment, OptSteps)
%
% == Constraints ==
%
%   All data is kept in Prolog term form.
%   No chatbot-style reasoning is introduced.
%   Purely for provenance, maintainability, and self-rebuild continuity.

:- module(cognitive_markers, [
    npl_ncm_record/5,
    npl_ncm_lookup_by_marker/2,
    npl_ncm_lookup_by_head/2,
    npl_ncm_all/1,
    npl_ncm_clear/0,
    npl_ncm_build_from_ir/4,
    npl_ncm_trace_report/1,
    npl_ncm_report_entry/2
]).

:- use_module(library(lists)).

:- use_module('src/intermediate_codegen').
:- use_module('src/optimisation_dictionary').

:- dynamic npl_ncm_entry/5.
%  npl_ncm_entry(+OriginalClause, +CogMarker, +NeurocodeFragment, +OptSteps, +Meta)

%%====================================================================
%% Schema access and storage
%%====================================================================

%% npl_ncm_record/5
%  npl_ncm_record(+OriginalClause, +CogMarker, +NeurocodeFragment, +OptSteps, +Meta)
%  Assert a new cognitive-marker mapping entry into the dynamic database.
npl_ncm_record(OrigClause, CogMarker, NeuroFrag, OptSteps, Meta) :-
    assertz(npl_ncm_entry(OrigClause, CogMarker, NeuroFrag, OptSteps, Meta)).

%% npl_ncm_lookup_by_marker/2
%  npl_ncm_lookup_by_marker(+Marker, -Entry)
%  Retrieve all mapping entries with the given cognitive marker.
%  Entry = ncm(OrigClause, Marker, NeurocodeFragment, OptSteps, Meta)
npl_ncm_lookup_by_marker(Marker, ncm(Orig, Marker, Neuro, Steps, Meta)) :-
    npl_ncm_entry(Orig, Marker, Neuro, Steps, Meta).

%% npl_ncm_lookup_by_head/2
%  npl_ncm_lookup_by_head(+Head, -Entry)
%  Retrieve entries whose original clause has the same functor/arity as Head.
%  Entry = ncm(OrigClause, Marker, NeurocodeFragment, OptSteps, Meta)
npl_ncm_lookup_by_head(Head, ncm(Orig, Marker, Neuro, Steps, Meta)) :-
    callable(Head),
    functor(Head, F, A),
    npl_ncm_entry(Orig, Marker, Neuro, Steps, Meta),
    Orig = ir_clause(OrigHead, _, _),
    callable(OrigHead),
    functor(OrigHead, F, A).

%% npl_ncm_all/1
%  npl_ncm_all(-Entries)
%  Retrieve all mapping entries as a list of ncm/5 terms.
npl_ncm_all(Entries) :-
    findall(ncm(O, M, N, S, Meta),
            npl_ncm_entry(O, M, N, S, Meta),
            Entries).

%% npl_ncm_clear/0
%  Retract all cognitive-marker mapping entries from the database.
npl_ncm_clear :-
    retractall(npl_ncm_entry(_, _, _, _, _)).

%%====================================================================
%% Mapping construction from IR pipeline
%%====================================================================

%% npl_ncm_build_from_ir/4
%  npl_ncm_build_from_ir(+OrigIR, +OptIR, +Neurocode, -Mappings)
%  Build a list of ncm/5 mapping terms from the three pipeline artefacts.
%
%    OrigIR    — flat list of ir_clause/3 before optimisation
%    OptIR     — flat list of ir_clause/3 after all optimisations
%    Neurocode — list of Prolog clause terms generated from OptIR (1-to-1)
%    Mappings  — list of ncm/5 terms
%
%  Pairing strategy: OptIR and Neurocode are zipped 1-to-1 (codegen
%  produces exactly one clause per ir_clause).  Each OrigIR clause is
%  then matched to the first Neurocode clause sharing the same head F/A.
npl_ncm_build_from_ir(OrigIR, OptIR, Neurocode, Mappings) :-
    npl_ncm_zip_opt_nc(OptIR, Neurocode, OptNCPairs),
    npl_ncm_collect_opt_steps(OptSteps),
    maplist(npl_ncm_make_mapping(OptNCPairs, OptSteps), OrigIR, Mappings).

%% npl_ncm_zip_opt_nc/3
%  Zip OptIR and Neurocode into a list of Clause-NeurocodeFragment pairs.
npl_ncm_zip_opt_nc([], _, []).
npl_ncm_zip_opt_nc(_, [], []).
npl_ncm_zip_opt_nc([OI|OIs], [NC|NCs], [OI-NC|Pairs]) :-
    npl_ncm_zip_opt_nc(OIs, NCs, Pairs).

%% npl_ncm_collect_opt_steps/1
%  Collect all currently registered optimisation rule names plus the
%  fixed algorithmic pass names as the complete set of applicable steps.
npl_ncm_collect_opt_steps(Steps) :-
    findall(R, npl_opt_rule(R, _, _), RuleNames),
    sort(RuleNames, UniqueRules),
    AlgoPasses = [ gaussian_reduce,
                   nested_elimination,
                   memoisation_pass,
                   subterm_address_iteration ],
    append(UniqueRules, AlgoPasses, Steps).

%% npl_ncm_make_mapping/4
%  npl_ncm_make_mapping(+OptNCPairs, +OptSteps, +OrigClause, -Mapping)
%  Build a single ncm/5 term for one original IR clause.
npl_ncm_make_mapping(OptNCPairs, OptSteps, OrigClause, Mapping) :-
    OrigClause = ir_clause(Head, _, Info),
    npl_ncm_extract_marker(Info, CogMarker),
    npl_ncm_find_neurocode(Head, OptNCPairs, NeuroFrag),
    npl_ncm_extract_meta(Head, Info, Meta),
    Mapping = ncm(OrigClause, CogMarker, NeuroFrag, OptSteps, Meta).

%% npl_ncm_extract_marker/2
%  Extract the cognitive marker from an IR info list.
%  Returns 'none' when absent or explicitly set to none.
npl_ncm_extract_marker(Info, Marker) :-
    ( npl_ir_info_get(Info, cognitive_marker, M), M \== none ->
        Marker = M
    ;
        Marker = none
    ).

%% npl_ncm_find_neurocode/3
%  Find the neurocode fragment whose OptIR clause head shares F/A with Head.
%  Returns 'no_neurocode' when no match is found.
npl_ncm_find_neurocode(Head, Pairs, NeuroFrag) :-
    callable(Head), !,
    functor(Head, F, A),
    ( npl_ncm_find_by_sig(F, A, Pairs, NeuroFrag) -> true
    ; NeuroFrag = no_neurocode
    ).
npl_ncm_find_neurocode(_, _, no_neurocode).

npl_ncm_find_by_sig(F, A, [ir_clause(H, _, _)-NC|_], NC) :-
    callable(H), functor(H, F, A), !.
npl_ncm_find_by_sig(F, A, [_|Rest], NC) :-
    npl_ncm_find_by_sig(F, A, Rest, NC).

%% npl_ncm_extract_meta/3
%  Build the rebuild-safe metadata list from a clause head and IR info.
npl_ncm_extract_meta(Head, Info, Meta) :-
    ( callable(Head) ->
        Head =.. [F|Args],
        length(Args, A),
        PredSig = F/A
    ;
        PredSig = unknown/0
    ),
    ( npl_ir_info_get(Info, source_marker, Pos) -> true ; Pos = no_pos ),
    Meta = [ pred_sig:       PredSig,
             source_marker:  Pos,
             rebuild_version: 1 ].

%%====================================================================
%% Trace report
%%====================================================================

%% npl_ncm_trace_report/1
%  npl_ncm_trace_report(-Report)
%  Produce a trace report from all currently recorded mapping entries.
%  Report is a list of trace_entry/4 terms:
%    trace_entry(CogMarker, OrigHead, NeurocodeFragment, OptSteps)
npl_ncm_trace_report(Report) :-
    findall(
        trace_entry(Marker, OrigHead, NeuroFrag, OptSteps),
        ( npl_ncm_entry(OrigClause, Marker, NeuroFrag, OptSteps, _),
          ( OrigClause = ir_clause(OrigHead, _, _) -> true
          ; OrigHead = OrigClause
          )
        ),
        Report
    ).

%% npl_ncm_report_entry/2
%  npl_ncm_report_entry(+Entry, -ReportLine)
%  Format a single ncm/5 entry into a report_line/4 term.
%    report_line(CogMarker, PredSig, NeurocodeFragment, OptStepCount)
npl_ncm_report_entry(ncm(OrigClause, Marker, NeuroFrag, OptSteps, Meta),
                     report_line(Marker, Sig, NeuroFrag, N)) :-
    ( member(pred_sig:Sig, Meta) -> true
    ; OrigClause = ir_clause(Head, _, _), callable(Head),
      functor(Head, F, A), Sig = F/A
    ; Sig = unknown/0
    ),
    length(OptSteps, N).
