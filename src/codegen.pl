% codegen.pl — NeuroProlog Code Generator (Stage 16)
%
% Translates optimised IR into neurocode (valid Prolog).
% Neurocode is inspectable, editable, and diffable in Git.
%
% == Stage 16 additions ==
%
%   npl_generate_full/3
%     Generates annotated code_segment/3 terms carrying a human-readable
%     comment, the Prolog clause term, and a metadata list.  Produces
%     readable predicate definitions with source links, optimisation
%     markers, cognitive-marker annotations, and memoisation metadata.
%
%   npl_ir_to_body_emitting/3
%     Like npl_ir_to_body/2 but emits explicit, self-contained Prolog
%     for IR nodes that have richer neurocode equivalents:
%       ir_memo_site  — inline ground-key cache-check + assertz
%       ir_addr_loop  — npl_subterm_addr_bounded/3 bounded loop form
%       ir_loop_candidate — body unchanged (loop shape noted in comment)
%       ir_source_marker  — transparent (position in comment)
%
%   npl_write_neurocode_full/3
%     Writes annotated code_segment/3 terms to a stream as readable,
%     indented Prolog with preceding comment blocks.  Uses portray_clause/2
%     so that operator and quote conventions are human-friendly.
%
%   npl_generate_text/3
%     Convenience wrapper that combines npl_generate_full/3 and
%     npl_write_neurocode_full/3, writing the result to an atom.
%
% == Constraints ==
%
%   All emitted code is valid Prolog — no binary or opaque representations.
%   Generated files are reloadable via consult/1 and parseable by the
%   NeuroProlog lexer/parser pipeline (self-hosting support).

:- module(codegen, [npl_generate/2,
                    npl_ir_to_source/2,
                    npl_ir_to_source_text/2,
                    npl_ir_to_source_file/2,
                    npl_code_generate/2,
                    npl_ir_to_clause_public/2,
                    npl_ir_to_body_public/2,
                    npl_source_to_ir/2,
                    npl_source_to_optimised_ir/2,
                    npl_roundtrip_source/2,
                    npl_roundtrip_source_text/2,
                    npl_roundtrip_source_file/2,
                    npl_ir_to_body/2,
                    npl_generate_full/3,
                    npl_ir_to_body_emitting/3,
                    npl_write_neurocode_full/3,
                    npl_generate_text/3,
                    npl_cg_loop_max_depth/1]).

:- discontiguous npl_ir_to_body_emitting/3.

:- use_module('./lexer', [npl_lex/2]).
:- use_module('./parser', [npl_parse/2]).
:- use_module('./semantic_analyser', [npl_analyse/2]).
:- use_module('./intermediate_codegen', [npl_intermediate/2]).
:- use_module('./optimiser', [npl_optimise/2]).

%% npl_generate/2
%  npl_generate(+OptIR, -Neurocode)
%  Convert optimised IR to a list of Prolog clause terms (neurocode).
%  var(Name) compound terms produced by the NeuroProlog parser are
%  converted to actual Prolog variables so that emitted clauses are
%  valid, executable Prolog.
npl_generate(IR, Neurocode) :-
    maplist(npl_ir_to_clause, IR, Neurocode).

%% Stage 1 public IR-to-source wrappers

%% npl_ir_to_source/2
%  Public wrapper for IR->clause generation.
npl_ir_to_source(IR, Clauses) :-
    npl_generate(IR, Clauses).

%% npl_code_generate/2
%  Compatibility alias for users expecting code-generation naming.
npl_code_generate(IR, Clauses) :-
    npl_ir_to_source(IR, Clauses).

%% npl_ir_to_source_text/2
%  Public wrapper for IR->readable Prolog text generation.
npl_ir_to_source_text(IR, Text) :-
    npl_ir_to_source(IR, Clauses),
    with_output_to(atom(Text),
        npl_codegen_write_clauses_(current_output, Clauses)).

%% npl_ir_to_source_file/2
%  Public wrapper for IR->consultable Prolog file generation.
npl_ir_to_source_file(IR, File) :-
    npl_ir_to_source_text(IR, Text),
    setup_call_cleanup(
        open(File, write, Stream),
        write(Stream, Text),
        close(Stream)).

npl_codegen_write_clauses_(Stream, Clauses) :-
    npl_codegen_write_clauses_(Stream, Clauses, none).

npl_codegen_write_clauses_(_, [], _).
npl_codegen_write_clauses_(Stream, [Clause|Rest], PrevSig) :-
    npl_codegen_clause_sig_(Clause, Sig),
    ( PrevSig \= none, Sig \= PrevSig ->
        nl(Stream)
    ;
        true
    ),
    npl_codegen_write_clause_(Stream, Clause),
    npl_codegen_write_clauses_(Stream, Rest, Sig).

npl_codegen_clause_sig_((Head :- _), Sig) :- !,
    npl_codegen_head_sig_(Head, Sig).
npl_codegen_clause_sig_(Head, Sig) :-
    npl_codegen_head_sig_(Head, Sig).

npl_codegen_head_sig_(Head, Sig) :-
    ( callable(Head) ->
        functor(Head, F, A),
        Sig = F/A
    ;
        Sig = unknown/0
    ).

npl_codegen_write_clause_(Stream, (Head :- Body)) :- !,
    write_term(Stream, Head, [quoted(true), numbervars(true)]),
    write(Stream, ' :-'), nl(Stream),
    npl_codegen_write_body_(Stream, Body, 4),
    write(Stream, '.'), nl(Stream).
npl_codegen_write_clause_(Stream, Fact) :-
    write_term(Stream, Fact, [quoted(true), numbervars(true)]),
    write(Stream, '.'), nl(Stream).

npl_codegen_write_body_(Stream, Body, Indent) :-
    npl_codegen_conjuncts_(Body, Goals),
    npl_codegen_write_goals_(Stream, Goals, Indent).

npl_codegen_conjuncts_((A, B), Goals) :- !,
    npl_codegen_conjuncts_(A, GA),
    npl_codegen_conjuncts_(B, GB),
    append(GA, GB, Goals).
npl_codegen_conjuncts_(Goal, [Goal]).

npl_codegen_write_goals_(Stream, [Goal], Indent) :- !,
    npl_codegen_write_goal_(Stream, Goal, Indent).
npl_codegen_write_goals_(Stream, [Goal|Goals], Indent) :-
    npl_codegen_write_goal_(Stream, Goal, Indent),
    write(Stream, ','), nl(Stream),
    npl_codegen_write_goals_(Stream, Goals, Indent).

npl_codegen_goal_priority_(999).

npl_codegen_write_goal_(Stream, Goal, Indent) :-
    % 999 is the context priority used inside conjunctions (A, B),
    % ensuring disjunction/if-then-else goals are parenthesised when needed.
    npl_codegen_goal_priority_(Priority),
    tab(Stream, Indent),
    write_term(Stream, Goal, [quoted(true), numbervars(true), priority(Priority)]).

%% Stage 3 source round-trip helpers

%% npl_source_to_ir/2
%  Public helper for source file -> IR conversion.
npl_source_to_ir(SourceFile, IR) :-
    npl_lex(SourceFile, Tokens),
    npl_parse(Tokens, AST),
    npl_analyse(AST, AAST),
    npl_intermediate(AAST, IR).

%% npl_source_to_optimised_ir/2
%  Public helper for source file -> optimised IR conversion.
npl_source_to_optimised_ir(SourceFile, OptIR) :-
    npl_source_to_ir(SourceFile, IR),
    npl_optimise(IR, OptIR).

%% npl_roundtrip_source/2
%  Public helper for source file -> optimised regenerated clauses.
npl_roundtrip_source(SourceFile, Clauses) :-
    npl_source_to_optimised_ir(SourceFile, OptIR),
    npl_ir_to_source(OptIR, Clauses).

%% npl_roundtrip_source_text/2
%  Public helper for source file -> optimised regenerated source text.
npl_roundtrip_source_text(SourceFile, Text) :-
    npl_source_to_optimised_ir(SourceFile, OptIR),
    npl_ir_to_source_text(OptIR, Text).

%% npl_roundtrip_source_file/2
%  Public helper for source file -> optimised regenerated source file.
npl_roundtrip_source_file(SourceFile, OutFile) :-
    npl_source_to_optimised_ir(SourceFile, OptIR),
    npl_ir_to_source_file(OptIR, OutFile).

%% Stage 2 public clause/body conversion wrappers
%%
%% Supported IR body nodes in basic mode:
%%   ir_true
%%   ir_fail
%%   ir_cut
%%   ir_repeat
%%   ir_not/1
%%   ir_call/1
%%   ir_seq/2
%%   ir_disj/2
%%   ir_if/3
%%   ir_source_marker/2
%%   ir_memo_site/2
%%   ir_loop_candidate/1
%%   ir_addr_loop/3
%%   ir_choice_point/1 (non-empty list)

%% npl_ir_to_clause_public/2
%% Public, validated wrapper for ir_clause/3 -> Prolog clause conversion.
npl_ir_to_clause_public(IRClause, Clause) :-
    npl_cg_validate_ir_clause_(IRClause, npl_ir_to_clause_public/2),
    npl_ir_to_clause(IRClause, Clause).

%% npl_ir_to_body_public/2
%% Public, validated wrapper for IR body -> Prolog body conversion.
npl_ir_to_body_public(IRBody, Body) :-
    npl_cg_validate_ir_body_(IRBody, npl_ir_to_body_public/2),
    npl_ir_to_body(IRBody, Body).

%% npl_ir_to_clause/2
%  Translate one ir_clause/3 to a Prolog clause term.
%  var(Name) terms in head and body are replaced by real Prolog variables
%  so that the generated clause unifies and executes correctly.
npl_ir_to_clause(ir_clause(Head, ir_true, _), Clause) :- !,
    npl_cg_instantiate_clause(Head, Clause).
npl_ir_to_clause(ir_clause(Head, IRBody, _), Clause) :-
    npl_ir_to_body(IRBody, Body),
    npl_cg_instantiate_clause((Head :- Body), Clause).

%% npl_ir_to_body/2
npl_ir_to_body(ir_true, true) :- !.
npl_ir_to_body(ir_fail, fail) :- !.
npl_ir_to_body(ir_cut, !) :- !.
npl_ir_to_body(ir_repeat, repeat) :- !.
npl_ir_to_body(ir_not(G), \+ Body) :- !,
    npl_ir_to_body(G, Body).
npl_ir_to_body(ir_call(Goal), Goal) :- !.
npl_ir_to_body(ir_seq(A, B), (BodyA, BodyB)) :- !,
    npl_ir_to_body(A, BodyA),
    npl_ir_to_body(B, BodyB).
npl_ir_to_body(ir_disj(A, B), (BodyA ; BodyB)) :- !,
    npl_ir_to_body(A, BodyA),
    npl_ir_to_body(B, BodyB).
npl_ir_to_body(ir_if(Cond, Then, ir_fail), (CondB -> ThenB)) :- !,
    npl_ir_to_body(Cond, CondB),
    npl_ir_to_body(Then, ThenB).
npl_ir_to_body(ir_if(Cond, Then, Else), (CondB -> ThenB ; ElseB)) :- !,
    npl_ir_to_body(Cond, CondB),
    npl_ir_to_body(Then, ThenB),
    npl_ir_to_body(Else, ElseB).
%% Stage 8 new body nodes — transparent wrappers for source and semantics:
npl_ir_to_body(ir_source_marker(_, IRBody), Body) :- !,
    npl_ir_to_body(IRBody, Body).
npl_ir_to_body(ir_memo_site(_, IRBody), Body) :- !,
    npl_ir_to_body(IRBody, Body).
npl_ir_to_body(ir_loop_candidate(IRBody), Body) :- !,
    npl_ir_to_body(IRBody, Body).
%% Stage 10 address-loop node — emit underlying body (correctness-preserving fallback):
npl_ir_to_body(ir_addr_loop(_, _, IRBody), Body) :- !,
    npl_ir_to_body(IRBody, Body).
npl_ir_to_body(ir_choice_point([Alt]), Body) :- !,
    npl_ir_to_body(Alt, Body).
npl_ir_to_body(ir_choice_point([Alt|Alts]), (BodyA ; BodyB)) :- !,
    npl_ir_to_body(Alt, BodyA),
    npl_ir_to_body(ir_choice_point(Alts), BodyB).

%% npl_cg_validate_ir_clause_/2
npl_cg_validate_ir_clause_(IRClause, Context) :-
    ( var(IRClause) ->
        throw(error(instantiation_error,
                    context(Context, 'IR clause must be instantiated')))
    ; IRClause = ir_clause(_, IRBody, _) ->
        npl_cg_validate_ir_body_(IRBody, Context)
    ;
        throw(error(domain_error(npl_ir_clause, IRClause),
                    context(Context, 'Expected ir_clause(Head, Body, Info)')))
    ).

%% npl_cg_validate_ir_body_/2
npl_cg_validate_ir_body_(IRBody, Context) :-
    ( var(IRBody) ->
        throw(error(instantiation_error,
                    context(Context, 'IR body must be instantiated')))
    ; npl_cg_supported_ir_body_(IRBody) ->
        true
    ;
        throw(error(domain_error(npl_ir_body, IRBody),
                    context(Context, 'Unsupported or malformed basic-mode IR body')))
    ).

%% npl_cg_supported_ir_body_/1
npl_cg_supported_ir_body_(ir_true).
npl_cg_supported_ir_body_(ir_fail).
npl_cg_supported_ir_body_(ir_cut).
npl_cg_supported_ir_body_(ir_repeat).
npl_cg_supported_ir_body_(ir_not(G)) :-
    npl_cg_supported_ir_body_(G).
npl_cg_supported_ir_body_(ir_call(Goal)) :-
    nonvar(Goal).
npl_cg_supported_ir_body_(ir_seq(A, B)) :-
    npl_cg_supported_ir_body_(A),
    npl_cg_supported_ir_body_(B).
npl_cg_supported_ir_body_(ir_disj(A, B)) :-
    npl_cg_supported_ir_body_(A),
    npl_cg_supported_ir_body_(B).
npl_cg_supported_ir_body_(ir_if(Cond, Then, Else)) :-
    npl_cg_supported_ir_body_(Cond),
    npl_cg_supported_ir_body_(Then),
    npl_cg_supported_ir_body_(Else).
npl_cg_supported_ir_body_(ir_source_marker(_, IRBody)) :-
    npl_cg_supported_ir_body_(IRBody).
npl_cg_supported_ir_body_(ir_memo_site(_, IRBody)) :-
    npl_cg_supported_ir_body_(IRBody).
npl_cg_supported_ir_body_(ir_loop_candidate(IRBody)) :-
    npl_cg_supported_ir_body_(IRBody).
npl_cg_supported_ir_body_(ir_addr_loop(_, _, IRBody)) :-
    npl_cg_supported_ir_body_(IRBody).
npl_cg_supported_ir_body_(ir_choice_point(Alts)) :-
    is_list(Alts),
    Alts = [_|_],
    maplist(npl_cg_supported_ir_body_, Alts).

%%====================================================================
%% Stage 16: Annotated code generation
%%====================================================================

%% npl_generate_full/3
%  npl_generate_full(+OptIR, +SrcFile, -Segments)
%  Generate a list of code_segment/3 terms from optimised IR.
%  Each segment = code_segment(Comment, Clause, Meta)
%    Comment — atom: human-readable comment block (source links, markers, opts)
%    Clause  — Prolog clause term using explicit memo/loop constructs
%    Meta    — list of key:value metadata pairs
%  SrcFile is the original source file path atom, or '' when unknown.
npl_generate_full(IR, SrcFile, Segments) :-
    maplist(npl_ir_to_segment(SrcFile), IR, Segments).

%% npl_ir_to_segment/3
npl_ir_to_segment(SrcFile, ir_clause(Head, IRBody, IRInfo),
                  code_segment(Comment, Clause, Meta)) :- !,
    npl_segment_comment(Head, IRInfo, SrcFile, Comment),
    npl_ir_to_clause_emitting(Head, IRBody, IRInfo, Clause),
    npl_segment_meta(Head, IRInfo, Meta).
npl_ir_to_segment(_, Other, code_segment('', Other, [])).

%%--------------------------------------------------------------------
%% Comment generation
%%--------------------------------------------------------------------

%% npl_segment_comment/4
%  Build a multi-line comment atom from IR info fields.
%  The comment is suitable for writing directly before the clause.
npl_segment_comment(Head, IRInfo, SrcFile, Comment) :-
    npl_comment_pred_line(Head, PredLine),
    npl_comment_source_line(IRInfo, SrcFile, SrcLine),
    npl_comment_marker_line(IRInfo, MarkerLine),
    npl_comment_recursion_line(IRInfo, RecLine),
    npl_comment_opts_line(IRInfo, OptsLine),
    npl_comment_memo_line(IRInfo, MemoLine),
    npl_comment_loop_line(IRInfo, LoopLine),
    atomic_list_concat(
        [PredLine, SrcLine, MarkerLine, RecLine, OptsLine, MemoLine, LoopLine],
        Comment).

npl_comment_pred_line(Head, Line) :-
    ( callable(Head) ->
        Head =.. [F|Args], length(Args, A),
        format(atom(Line), '%% ~w/~w~n', [F, A])
    ;
        format(atom(Line), '%% (unknown)~n', [])
    ).

npl_comment_source_line(IRInfo, SrcFile, Line) :-
    ( npl_cg_ir_info_get(IRInfo, source_marker, Pos), Pos \= no_pos ->
        ( SrcFile \= '' ->
            format(atom(Line), '%  source: ~w  file: ~w~n', [Pos, SrcFile])
        ;
            format(atom(Line), '%  source: ~w~n', [Pos])
        )
    ;
        ( SrcFile \= '' ->
            format(atom(Line), '%  file: ~w~n', [SrcFile])
        ;
            Line = ''
        )
    ).

npl_comment_marker_line(IRInfo, Line) :-
    ( npl_cg_ir_info_get(IRInfo, cognitive_marker, Marker), Marker \= none ->
        format(atom(Line), '%  marker: ~w~n', [Marker])
    ;
        Line = ''
    ).

npl_comment_recursion_line(IRInfo, Line) :-
    ( npl_cg_ir_info_get(IRInfo, recursion_class, RC), RC \= none ->
        format(atom(Line), '%  recursion: ~w~n', [RC])
    ;
        Line = ''
    ).

npl_comment_opts_line(IRInfo, Line) :-
    ( npl_cg_ir_info_get(IRInfo, optimisation_meta, Opts), Opts \= [] ->
        format(atom(Line), '%  opts: ~w~n', [Opts])
    ;
        Line = ''
    ).

npl_comment_memo_line(IRInfo, Line) :-
    ( npl_cg_ir_info_get(IRInfo, memo_site, true) ->
        format(atom(Line), '%  [memo_site] memoisation enabled for this clause~n', [])
    ;
        Line = ''
    ).

npl_comment_loop_line(IRInfo, Line) :-
    ( npl_cg_ir_info_get(IRInfo, loop_candidate, true) ->
        format(atom(Line), '%  [loop_candidate] accumulator/iterative form applicable~n', [])
    ;
        Line = ''
    ).

%% npl_cg_ir_info_get/3
%  Internal helper — retrieve a value from an IRInfo list or info/N functor.
npl_cg_ir_info_get(Info, Key, Value) :-
    is_list(Info), !,
    member(Key:Value, Info).
npl_cg_ir_info_get(Info, Key, Value) :-
    Info =.. [info|Pairs],
    member(Key:Value, Pairs).

%%--------------------------------------------------------------------
%% Metadata extraction
%%--------------------------------------------------------------------

%% npl_segment_meta/3
%  Build a key:value metadata list from a clause head and IRInfo.
npl_segment_meta(Head, IRInfo, Meta) :-
    ( callable(Head) ->
        Head =.. [F|Args], length(Args, A),
        PredSig = F/A
    ;
        PredSig = unknown/0
    ),
    ( npl_cg_ir_info_get(IRInfo, source_marker, Pos) -> true ; Pos = no_pos ),
    ( npl_cg_ir_info_get(IRInfo, recursion_class, RC) -> true ; RC = none ),
    ( npl_cg_ir_info_get(IRInfo, memo_site,      MS) -> true ; MS = false ),
    ( npl_cg_ir_info_get(IRInfo, loop_candidate, LC) -> true ; LC = false ),
    ( npl_cg_ir_info_get(IRInfo, cognitive_marker, CM) -> true ; CM = none ),
    Meta = [ pred_sig:        PredSig,
             source_marker:   Pos,
             recursion_class: RC,
             memo_site:       MS,
             loop_candidate:  LC,
             cognitive_marker: CM ].

%%--------------------------------------------------------------------
%% Clause emission with explicit memo/loop constructs
%%--------------------------------------------------------------------

%% npl_ir_to_clause_emitting/4
%  Produce a Prolog clause term using the emitting body translator.
%  var(Name) compound terms are converted to real Prolog variables.
npl_ir_to_clause_emitting(Head, ir_true, _, Clause) :- !,
    npl_cg_instantiate_clause(Head, Clause).
npl_ir_to_clause_emitting(Head, IRBody, IRInfo, Clause) :-
    npl_ir_to_body_emitting(IRBody, IRInfo, Body),
    npl_cg_instantiate_clause((Head :- Body), Clause).

%% npl_ir_to_body_emitting/3
%  Like npl_ir_to_body/2 but emits explicit Prolog for memo and loop nodes.
%
%  ir_memo_site(Key, Body):
%    Emits an inline ground-key cache lookup + assertz pattern.
%    The emitted code is self-contained valid Prolog requiring only the
%    dynamic predicate npl_memo_cache/3 to be declared.
%
%  ir_addr_loop(TV, Sig, Body):
%    Emits a bounded subterm address loop using npl_subterm_addr_bounded/3.
%    This expresses the loop in Prolog: collect all bounded addresses for TV,
%    then execute Body for each address (forall/2).
%
%  ir_loop_candidate(Body):
%    The loop shape has not been finalised at this IR level; emit the body
%    unchanged.  The loop nature is documented in the clause comment.
%
%  All other nodes delegate to the existing npl_ir_to_body/2.
npl_ir_to_body_emitting(ir_true, _, true) :- !.
npl_ir_to_body_emitting(ir_fail, _, fail) :- !.
npl_ir_to_body_emitting(ir_cut,  _, !)    :- !.
npl_ir_to_body_emitting(ir_repeat, _, repeat) :- !.
npl_ir_to_body_emitting(ir_not(G), Info, \+ Body) :- !,
    npl_ir_to_body_emitting(G, Info, Body).
npl_ir_to_body_emitting(ir_call(Goal), _, Goal) :- !.
npl_ir_to_body_emitting(ir_seq(A, B), Info, (BodyA, BodyB)) :- !,
    npl_ir_to_body_emitting(A, Info, BodyA),
    npl_ir_to_body_emitting(B, Info, BodyB).
npl_ir_to_body_emitting(ir_disj(A, B), Info, (BodyA ; BodyB)) :- !,
    npl_ir_to_body_emitting(A, Info, BodyA),
    npl_ir_to_body_emitting(B, Info, BodyB).
npl_ir_to_body_emitting(ir_if(Cond, Then, ir_fail), Info,
                         (CondB -> ThenB)) :- !,
    npl_ir_to_body_emitting(Cond, Info, CondB),
    npl_ir_to_body_emitting(Then, Info, ThenB).
npl_ir_to_body_emitting(ir_if(Cond, Then, Else), Info,
                         (CondB -> ThenB ; ElseB)) :- !,
    npl_ir_to_body_emitting(Cond, Info, CondB),
    npl_ir_to_body_emitting(Then, Info, ThenB),
    npl_ir_to_body_emitting(Else, Info, ElseB).

%% Source marker — transparent; position already captured in comment.
npl_ir_to_body_emitting(ir_source_marker(_, IRBody), Info, Body) :- !,
    npl_ir_to_body_emitting(IRBody, Info, Body).

%% Memo site — emit explicit inline memoisation Prolog.
%  The emitted form:
%    ( ground(Key) ->
%        ( npl_memo_cache(Key, det, true) -> true
%        ; Body, assertz(npl_memo_cache(Key, det, true)) )
%    ; Body )
%  This is self-contained: it stores and retrieves the ground result in
%  npl_memo_cache/3 without requiring any external memo infrastructure.
npl_ir_to_body_emitting(ir_memo_site(Key, IRBody), Info, MemoBody) :- !,
    npl_ir_to_body_emitting(IRBody, Info, Body),
    MemoBody = ( ground(Key) ->
                     ( npl_memo_cache(Key, det, true) -> true
                     ; Body,
                       assertz(npl_memo_cache(Key, det, true)) )
               ; Body ).

%% Loop candidate — body unchanged; loop shape is noted in the comment.
npl_ir_to_body_emitting(ir_loop_candidate(IRBody), Info, Body) :- !,
    npl_ir_to_body_emitting(IRBody, Info, Body).

%% npl_cg_loop_max_depth/1
%  npl_cg_loop_max_depth(?MaxDepth)
%  Default maximum depth for bounded subterm address iteration in generated code.
%  A depth of 10 is conservative but handles typical clause structure.
%  To customise, redefine this predicate in the module that loads codegen,
%  or pass the depth explicitly via npl_ir_to_body_emitting/3 by specialising
%  the ir_addr_loop case in a wrapper.
npl_cg_loop_max_depth(10).

%% Address loop — emit bounded subterm iteration using npl_subterm_addr_bounded/3.
%  The emitted form:
%    ( npl_subterm_addr_bounded(TV, MaxDepth, NplLoopAddrs_),
%      forall(member(_, NplLoopAddrs_), Body) )
%  This expresses the loop in valid Prolog: collect all subterm addresses of
%  TV within MaxDepth, then execute Body for each address position.
%  MaxDepth is taken from npl_cg_loop_max_depth/1 (default 10).
npl_ir_to_body_emitting(ir_addr_loop(TV, _Sig, IRBody), Info, LoopBody) :- !,
    npl_ir_to_body_emitting(IRBody, Info, Body),
    npl_cg_loop_max_depth(MaxDepth),
    LoopBody = ( npl_subterm_addr_bounded(TV, MaxDepth, NplLoopAddrs_),
                 forall(member(_, NplLoopAddrs_), Body) ).

npl_ir_to_body_emitting(ir_choice_point([Alt]), Info, Body) :- !,
    npl_ir_to_body_emitting(Alt, Info, Body).
npl_ir_to_body_emitting(ir_choice_point([Alt|Alts]), Info, (BodyA ; BodyB)) :- !,
    npl_ir_to_body_emitting(Alt, Info, BodyA),
    npl_ir_to_body_emitting(ir_choice_point(Alts), Info, BodyB).

%% Fallback — delegate to the core npl_ir_to_body/2.
npl_ir_to_body_emitting(IRBody, _, Body) :-
    npl_ir_to_body(IRBody, Body).

%%====================================================================
%% Stage 16: Neurocode writing
%%====================================================================

%% npl_write_neurocode_full/3
%  npl_write_neurocode_full(+Stream, +Segments, +Header)
%  Write annotated neurocode to Stream with a file-level header comment.
%  Each segment is written as:
%    - the comment block (if non-empty), then
%    - the Prolog clause via portray_clause/2 (readable, with operators),
%    - a blank line separator.
%  Header is an atom used in the first comment line.
npl_write_neurocode_full(Stream, Segments, Header) :-
    format(Stream, '% ~w~n', [Header]),
    format(Stream, '%~n', []),
    format(Stream, '% Generated by NeuroProlog Stage 16 Code Generator.~n', []),
    format(Stream, '% This file is valid Prolog — load with consult/1.~n', []),
    format(Stream, '% Do not add binary or opaque representations.~n', []),
    format(Stream, '%~n~n', []),
    maplist(npl_write_segment(Stream), Segments).

%% npl_write_segment/2
npl_write_segment(Stream, code_segment(Comment, Clause, _Meta)) :- !,
    ( Comment \= '' ->
        write(Stream, Comment),
        nl(Stream)
    ;
        true
    ),
    portray_clause(Stream, Clause),
    nl(Stream).
npl_write_segment(Stream, Other) :-
    write_term(Stream, Other, [quoted(true)]),
    write(Stream, '.'), nl(Stream), nl(Stream).

%%====================================================================
%% Stage 16: Text generation convenience predicate
%%====================================================================

%% npl_generate_text/3
%  npl_generate_text(+OptIR, +SrcFile, -Text)
%  Generate a complete neurocode text atom from optimised IR.
%  Text is a valid Prolog file as an atom, suitable for atom_to_term/3 or
%  writing directly to a file.
npl_generate_text(OptIR, SrcFile, Text) :-
    npl_generate_full(OptIR, SrcFile, Segments),
    ( SrcFile \= '' ->
        format(atom(Header), 'NeuroProlog neurocode — source: ~w', [SrcFile])
    ;
        Header = 'NeuroProlog neurocode'
    ),
    with_output_to(atom(Text),
        npl_write_neurocode_full(current_output, Segments, Header)).

%%====================================================================
%% Variable instantiation helpers
%%====================================================================
%
% The NeuroProlog parser represents source variables as var(Name) compound
% terms (e.g. var('X'), var('N')) rather than real Prolog variables.
% These helpers convert var(Name) to actual Prolog variables so that the
% generated clause terms are valid, executable Prolog.
%
% Variables with the same Name within a clause share the same Prolog
% variable (correct scoping).  var('_') (anonymous) always produces a
% fresh independent variable.

%% npl_cg_instantiate_clause/2
%  npl_cg_instantiate_clause(+RawClause, -Clause)
%  Replace var(Name) compound terms in a clause (head or head+body)
%  with real Prolog variables.
npl_cg_instantiate_clause((Head :- Body), (Head1 :- Body1)) :- !,
    npl_cg_term_vars(Head, [], Head1, Dict),
    npl_cg_term_vars(Body, Dict, Body1, _).
npl_cg_instantiate_clause(Head, Head1) :-
    npl_cg_term_vars(Head, [], Head1, _).

%% npl_cg_term_vars/4
%  npl_cg_term_vars(+Term, +Dict0, -Term1, -Dict)
%  Recursively traverse Term, replacing var(Name) compound terms with
%  Prolog variables.  Dict0/Dict maps Name atoms to their Prolog variables.
%  The var/1 guard prevents an unbound Prolog variable from matching
%  the var(Name) pattern.
npl_cg_term_vars(Term, Dict0, Term1, Dict) :-
    ( var(Term) ->
        Term1 = Term,
        Dict = Dict0
    ; functor(Term, var, 1), arg(1, Term, Name), atom(Name) ->
        ( Name = '_' ->
            % Anonymous variable: leave Term1 unbound so that each
            % occurrence in the clause head gets a distinct fresh Prolog
            % variable.  Term1 is the fresh variable from the clause head
            % — not binding it IS the correct way to create a fresh var.
            Dict = Dict0
        ;
            ( member(Name-Var, Dict0)
            -> Term1 = Var, Dict = Dict0
            ;  Term1 = Var, Dict = [Name-Var|Dict0]
            )
        )
    ; compound(Term) ->
        Term =.. [F|Args],
        npl_cg_term_vars_list(Args, Dict0, Args1, Dict),
        Term1 =.. [F|Args1]
    ;
        Term1 = Term,
        Dict = Dict0
    ).

npl_cg_term_vars_list([], Dict, [], Dict).
npl_cg_term_vars_list([H|T], Dict0, [H1|T1], Dict) :-
    npl_cg_term_vars(H, Dict0, H1, Dict1),
    npl_cg_term_vars_list(T, Dict1, T1, Dict).
