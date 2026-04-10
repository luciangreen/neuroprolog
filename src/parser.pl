% parser.pl — NeuroProlog Parser (Stage 4)
%
% Parses a token stream into an Abstract Syntax Tree (AST).
%
% ===  AST Node Types ===
%
%   fact(Head, Pos, Annots, Meta)
%     A unit clause with no body.
%     Head   — the head term (variables represented as var(Name))
%     Pos    — pos(Line, Col) | no_pos
%     Annots — list of annotation strings from preceding %@ markers
%     Meta   — [] (reserved for optimisation metadata)
%
%   rule(Head, Body, Pos, Annots, Meta)
%     A clause with a body.
%     Body   — the body term (compound Prolog term)
%
%   directive(Goal, Pos, Annots, Meta)
%     A :- directive.
%
%   query(Goal, Pos, Annots, Meta)
%     A ?- query.
%
%   parse_error(Msg, Pos)
%     Syntax error node; the rest of the malformed clause is skipped.
%
% === Public API ===
%
%   npl_parse/2             (+PlainTokens, -AST)
%   npl_parse_pos/2         (+PositionedTokens, -AST)
%   npl_parse_string/2      (+StringOrAtom, -AST)
%   npl_parse_string_pos/2  (+StringOrAtom, -AST)  [with source positions]
%   npl_run/1               (+AST)

:- module(parser, [npl_parse/2, npl_parse_pos/2,
                   npl_parse_string/2, npl_parse_string_pos/2,
                   npl_run/1]).

:- use_module(library(lists)).
:- use_module(lexer, [npl_lex_string/2, npl_lex_string_pos/2]).

%%====================================================================
%% Public API
%%====================================================================

%% npl_parse(+PlainTokens, -AST)
%% Parse a plain (non-positioned) token list.
npl_parse(Tokens, AST) :-
    npl_wrap_plain(Tokens, PToks),
    npl_parse_program(PToks, [], AST).

%% npl_parse_pos(+PositionedTokens, -AST)
%% Parse a positioned token list (tok(Token, Pos) elements).
npl_parse_pos(Tokens, AST) :-
    npl_parse_program(Tokens, [], AST).

%% npl_parse_string(+Src, -AST)
%% Lex (without positions) and parse a string or atom.
npl_parse_string(Src, AST) :-
    npl_lex_string(Src, Tokens),
    npl_parse(Tokens, AST).

%% npl_parse_string_pos(+Src, -AST)
%% Lex (with positions) and parse a string or atom.
npl_parse_string_pos(Src, AST) :-
    npl_lex_string_pos(Src, Tokens),
    npl_parse_pos(Tokens, AST).

%%====================================================================
%% Token normalisation
%%====================================================================

%% npl_wrap_plain(+PlainTokens, -WrappedTokens)
%% Wrap each plain token as tok(Token, no_pos) for uniform internal handling.
npl_wrap_plain([], []).
npl_wrap_plain([T|Ts], [tok(T, no_pos)|Rest]) :-
    npl_wrap_plain(Ts, Rest).

%%====================================================================
%% Program-level parser
%%====================================================================

%% npl_parse_program(+Tokens, +PendingAnnots, -AST)
%% Parse a sequence of clauses from a positioned token list.
%% PendingAnnots accumulates annotation strings until a clause is parsed.
npl_parse_program([], _, []).
npl_parse_program(Tokens, PendingAnnots, AST) :-
    npl_collect_annots(Tokens, NewAnnots, Toks1),
    append(PendingAnnots, NewAnnots, AllAnnots),
    ( Toks1 = []
    ->  AST = []
    ;   ( catch(
              npl_parse_one_clause(Toks1, AllAnnots, Node, Rest),
              _,
              fail
          )
        ->  AST = [Node|More],
            npl_parse_program(Rest, [], More)
        ;   npl_first_pos(Toks1, EPos),
            npl_skip_to_dot(Toks1, Rest),
            AST = [parse_error(syntax_error, EPos)|More],
            npl_parse_program(Rest, [], More)
        )
    ).

%% npl_collect_annots(+Tokens, -Annots, -Rest)
%% Strip leading annotation tokens; return annotation strings and the rest.
npl_collect_annots([tok(annot(A), _)|Ts], [A|As], Rest) :- !,
    npl_collect_annots(Ts, As, Rest).
npl_collect_annots(Tokens, [], Tokens).

%% npl_skip_to_dot(+Tokens, -Rest)
%% Skip tokens up to and including the next '.' punctuation.
npl_skip_to_dot([tok(punct('.'), _)|Rest], Rest) :- !.
npl_skip_to_dot([_|Ts], Rest) :- !,
    npl_skip_to_dot(Ts, Rest).
npl_skip_to_dot([], []).

%% npl_first_pos(+Tokens, -Pos)
%% Return the source position of the first token, or no_pos if empty.
npl_first_pos([tok(_, Pos)|_], Pos) :- !.
npl_first_pos([], no_pos).

%%====================================================================
%% Clause-level parser
%%====================================================================

%% npl_parse_one_clause(+Tokens, +Annots, -Node, -Rest)
%% Parse one complete clause (up to and including '.') and classify it.
npl_parse_one_clause(Tokens, Annots, Node, Rest) :-
    npl_first_pos(Tokens, Pos),
    npl_parse_expr(1200, Tokens, Term, R0),
    R0 = [tok(punct('.'), _)|Rest],
    npl_classify_clause(Term, Pos, Annots, Node).

%% npl_classify_clause(+Term, +Pos, +Annots, -Node)
%% Map a top-level parsed term to the appropriate AST node type.
npl_classify_clause(':-'(Head, Body), Pos, Annots,
                    rule(Head, Body, Pos, Annots, [])) :- !.
npl_classify_clause(':-'(Goal), Pos, Annots,
                    directive(Goal, Pos, Annots, [])) :- !.
npl_classify_clause('?-'(Goal), Pos, Annots,
                    query(Goal, Pos, Annots, [])) :- !.
npl_classify_clause(Head, Pos, Annots,
                    fact(Head, Pos, Annots, [])).

%%====================================================================
%% Operator-Precedence (Pratt) Expression Parser
%%====================================================================

%% npl_parse_expr(+MaxPrec, +Tokens, -Term, -Rest)
%% Parse an expression whose operator precedence does not exceed MaxPrec.
npl_parse_expr(MaxPrec, Tokens, Term, Rest) :-
    npl_parse_unary(MaxPrec, Tokens, T0, T0Prec, R0),
    npl_parse_infix_loop(MaxPrec, T0, T0Prec, R0, Term, Rest).

%% npl_parse_unary(+MaxPrec, +Tokens, -Term, -TermPrec, -Rest)
%% Parse a primary term or a prefix-operator application.
%% TermPrec records the effective operator precedence of the assembled term.
npl_parse_unary(MaxPrec, [tok(Tok, _)|Ts], Term, OpPrec, Rest) :-
    npl_tok_as_op(Tok, Op),
    npl_op_entry(OpPrec, Type, Op),
    npl_is_prefix(Type),
    OpPrec =< MaxPrec,
    \+ npl_is_functor_call(Ts),         % let primary handle: f( Args )
    !,
    npl_prefix_arg_max_prec(Type, OpPrec, ArgMaxPrec),
    npl_parse_expr(ArgMaxPrec, Ts, Arg, Rest),
    Term =.. [Op, Arg].
npl_parse_unary(_, Tokens, Term, 0, Rest) :-
    npl_parse_primary(Tokens, Term, Rest).

%% npl_is_functor_call(+Tokens)
%% Succeeds when Tokens begins with '(', indicating a functor-call argument list
%% rather than a standalone prefix-operator application.
npl_is_functor_call([tok(punct('('), _)|_]).

%% npl_parse_infix_loop(+MaxPrec, +Left, +LeftPrec, +Tokens, -Term, -Rest)
%% Extend Left by consuming infix operators whose precedence does not exceed MaxPrec.
npl_parse_infix_loop(MaxPrec, Left, LeftPrec,
                     [tok(Tok, _)|Ts], Term, Rest) :-
    npl_tok_as_op(Tok, Op),
    npl_op_entry(OpPrec, Type, Op),
    npl_is_infix(Type),
    OpPrec =< MaxPrec,
    npl_infix_left_ok(Type, LeftPrec, OpPrec),
    !,
    npl_infix_right_max_prec(Type, OpPrec, RightMaxPrec),
    npl_parse_expr(RightMaxPrec, Ts, Right, R1),
    NewTerm =.. [Op, Left, Right],
    npl_parse_infix_loop(MaxPrec, NewTerm, OpPrec, R1, Term, Rest).
npl_parse_infix_loop(_, Term, _, Rest, Term, Rest).

%%====================================================================
%% Operator type helpers
%%====================================================================

npl_is_prefix(fx).
npl_is_prefix(fy).

npl_is_infix(xfx).
npl_is_infix(xfy).
npl_is_infix(yfx).

%% npl_prefix_arg_max_prec(+Type, +OpPrec, -ArgMaxPrec)
npl_prefix_arg_max_prec(fx, P, Q) :- Q is P - 1.
npl_prefix_arg_max_prec(fy, P, P).

%% npl_infix_right_max_prec(+Type, +OpPrec, -RightMaxPrec)
npl_infix_right_max_prec(xfx, P, Q) :- Q is P - 1.
npl_infix_right_max_prec(xfy, P, P).
npl_infix_right_max_prec(yfx, P, Q) :- Q is P - 1.

%% npl_infix_left_ok(+Type, +LeftPrec, +OpPrec)
%% Succeeds when the effective precedence of the left operand is compatible
%% with the associativity of the infix operator.
npl_infix_left_ok(xfx, LeftPrec, OpPrec) :- LeftPrec < OpPrec.
npl_infix_left_ok(xfy, LeftPrec, OpPrec) :- LeftPrec < OpPrec.
npl_infix_left_ok(yfx, LeftPrec, OpPrec) :- LeftPrec =< OpPrec.

%% npl_tok_as_op(+Token, -Op)
%% Extract the operator atom from an atom or punctuation token.
npl_tok_as_op(atom(Op), Op).
npl_tok_as_op(punct(Op), Op).

%%====================================================================
%% Primary term parser
%%====================================================================

%% Parenthesised expression:  ( Expr )
npl_parse_primary([tok(punct('('), _)|Ts], Term, Rest) :- !,
    npl_parse_expr(1200, Ts, Term, R0),
    R0 = [tok(punct(')'), _)|Rest].

%% Curly-brace expression:  {} or { Expr }
npl_parse_primary([tok(punct('{'), _), tok(punct('}'), _)|Ts], '{}', Ts) :- !.
npl_parse_primary([tok(punct('{'), _)|Ts], '{}'(Expr), Rest) :- !,
    npl_parse_expr(1200, Ts, Expr, R0),
    R0 = [tok(punct('}'), _)|Rest].

%% List:  [ ... ]
npl_parse_primary([tok(punct('['), _)|Ts], List, Rest) :- !,
    npl_parse_list_expr(Ts, List, Rest).

%% Functor call:  f( Args )
npl_parse_primary([tok(atom(F), _), tok(punct('('), _)|Ts], Term, Rest) :- !,
    npl_parse_arglist(Ts, Args, R0),
    R0 = [tok(punct(')'), _)|Rest],
    Term =.. [F|Args].

%% Plain atom
npl_parse_primary([tok(atom(A), _)|Ts], A, Ts) :- !.

%% Variable  (represented as var(Name) in the AST)
npl_parse_primary([tok(var(V), _)|Ts], var(V), Ts) :- !.

%% Integer literal
npl_parse_primary([tok(integer(N), _)|Ts], N, Ts) :- !.

%% Floating-point literal
npl_parse_primary([tok(float(F), _)|Ts], F, Ts) :- !.

%% String literal (double-quoted)
npl_parse_primary([tok(string(S), _)|Ts], S, Ts) :- !.

%% Cut
npl_parse_primary([tok(punct('!'), _)|Ts], !, Ts) :- !.

%%====================================================================
%% List expression parser
%%====================================================================

%% npl_parse_list_expr(+Tokens, -List, -Rest)
%% Parse list body after the opening '[' has been consumed.
npl_parse_list_expr([tok(punct(']'), _)|Rest], [], Rest) :- !.
npl_parse_list_expr(Tokens, List, Rest) :-
    npl_parse_expr(999, Tokens, Head, R1),
    ( R1 = [tok(punct('|'), _)|R2]
    ->  npl_parse_expr(999, R2, Tail, R3),
        R3 = [tok(punct(']'), _)|Rest],
        List = [Head|Tail]
    ; R1 = [tok(punct(','), _)|R2]
    ->  npl_parse_list_expr(R2, Tail, Rest),
        List = [Head|Tail]
    ;   R1 = [tok(punct(']'), _)|Rest],
        List = [Head]
    ).

%%====================================================================
%% Argument list parser
%%====================================================================

%% npl_parse_arglist(+Tokens, -Args, -Rest)
%% Parse comma-separated functor arguments at prec 999 so that ',' (prec 1000)
%% is not consumed as conjunction inside argument positions.
npl_parse_arglist([tok(punct(')'), _)|_] = Tokens, [], Tokens) :- !.
npl_parse_arglist(Tokens, [Arg|Args], Rest) :-
    npl_parse_expr(999, Tokens, Arg, R1),
    ( R1 = [tok(punct(','), _)|R2]
    ->  npl_parse_arglist(R2, Args, Rest)
    ;   Args = [],
        Rest = R1
    ).

%%====================================================================
%% Operator Table  (standard ISO Prolog operators)
%%====================================================================

%% npl_op_entry(+Prec, +Type, +Op)
%% Named npl_op_entry to avoid clashing with SWI-Prolog's built-in op/3.
npl_op_entry(1200, xfx, ':-').
npl_op_entry(1200, xfx, '-->').
npl_op_entry(1200, fx,  ':-').
npl_op_entry(1200, fx,  '?-').
npl_op_entry(1100, xfy, ';').
npl_op_entry(1050, xfy, '->').
npl_op_entry(1000, xfy, ',').
npl_op_entry(900,  fy,  '\\+').
npl_op_entry(900,  fy,  'not').
npl_op_entry(700,  xfx, '=').
npl_op_entry(700,  xfx, '\\=').
npl_op_entry(700,  xfx, '==').
npl_op_entry(700,  xfx, '\\==').
npl_op_entry(700,  xfx, 'is').
npl_op_entry(700,  xfx, '=..').
npl_op_entry(700,  xfx, '<').
npl_op_entry(700,  xfx, '>').
npl_op_entry(700,  xfx, '=<').
npl_op_entry(700,  xfx, '>=').
npl_op_entry(700,  xfx, '@<').
npl_op_entry(700,  xfx, '@>').
npl_op_entry(700,  xfx, '@=<').
npl_op_entry(700,  xfx, '@>=').
npl_op_entry(600,  xfy, ':').
npl_op_entry(500,  yfx, '+').
npl_op_entry(500,  yfx, '-').
npl_op_entry(500,  yfx, '/\\').
npl_op_entry(500,  yfx, '\\/').
npl_op_entry(500,  yfx, 'xor').
npl_op_entry(400,  yfx, '*').
npl_op_entry(400,  yfx, '/').
npl_op_entry(400,  yfx, '//').
npl_op_entry(400,  yfx, 'mod').
npl_op_entry(400,  yfx, 'rem').
npl_op_entry(400,  yfx, '<<').
npl_op_entry(400,  yfx, '>>').
npl_op_entry(200,  xfx, '**').
npl_op_entry(200,  xfy, '^').
npl_op_entry(200,  fy,  '+').
npl_op_entry(200,  fy,  '-').
npl_op_entry(200,  fy,  '\\').

%%====================================================================
%% npl_run/1  —  Execute a parsed (or analysed) AST
%%====================================================================

%% Handles the new rich AST format, the semantic-analyser's analysed/3 format,
%% and the legacy clause/2 format for backward compatibility.

npl_run([]).

%% New AST: fact
npl_run([fact(Head, _, _, _)|Cs]) :- !,
    assertz(Head),
    npl_run(Cs).

%% New AST: rule
npl_run([rule(Head, Body, _, _, _)|Cs]) :- !,
    assertz((Head :- Body)),
    npl_run(Cs).

%% New AST: directive
npl_run([directive(Goal, _, _, _)|Cs]) :- !,
    call(Goal),
    npl_run(Cs).

%% New AST: query
npl_run([query(Goal, _, _, _)|Cs]) :- !,
    call(Goal),
    npl_run(Cs).

%% New AST: parse error  (skip silently)
npl_run([parse_error(_, _)|Cs]) :- !,
    npl_run(Cs).

%% Semantic-analyser output: analysed/3
npl_run([analysed(Head, true, _)|Cs]) :- !,
    assertz(Head),
    npl_run(Cs).
npl_run([analysed(Head, Body, _)|Cs]) :- !,
    assertz((Head :- Body)),
    npl_run(Cs).

%% Legacy format: clause/2
npl_run([clause(Head, true)|Cs]) :- !,
    assertz(Head),
    npl_run(Cs).
npl_run([clause(Head, Body)|Cs]) :-
    assertz((Head :- Body)),
    npl_run(Cs).
