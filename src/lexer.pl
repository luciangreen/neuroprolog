% lexer.pl — NeuroProlog Lexer
%
% Tokenises a Prolog source file into a list of tokens.
%
% Plain token types (npl_lex/2, npl_lex_string/2):
%   atom(A)       — lowercase identifier or quoted atom
%   var(V)        — variable (uppercase-initial or underscore-prefixed)
%   integer(N)    — integer literal
%   float(N)      — floating-point literal
%   string(S)     — double-quoted string literal
%   punct(P)      — punctuation character
%   annot(Text)   — cognitive-code annotation  (%@ text)
%   error(Msg)    — malformed token (e.g. unterminated_string)
%
% Positioned token format (npl_lex_pos/2, npl_lex_string_pos/2):
%   tok(Token, pos(Line, Col))

:- module(lexer, [npl_lex/2, npl_lex_string/2,
                  npl_lex_pos/2, npl_lex_string_pos/2]).

:- use_module(library(lists)).

%% npl_lex/2
%  npl_lex(+SourceFile, -Tokens)
%  Read a file and return its plain token list.
npl_lex(File, Tokens) :-
    read_file_to_codes(File, Codes, []),
    npl_lex_codes(Codes, Tokens).

%% npl_lex_string/2
%  npl_lex_string(+AtomOrString, -Tokens)
npl_lex_string(String, Tokens) :-
    atom_codes(String, Codes),
    npl_lex_codes(Codes, Tokens).

%% npl_lex_pos/2
%  npl_lex_pos(+SourceFile, -PositionedTokens)
%  Each element is tok(Token, pos(Line, Col)).
npl_lex_pos(File, Tokens) :-
    read_file_to_codes(File, Codes, []),
    npl_lex_codes_pos(Codes, 1, 1, Tokens).

%% npl_lex_string_pos/2
%  npl_lex_string_pos(+AtomOrString, -PositionedTokens)
npl_lex_string_pos(String, Tokens) :-
    atom_codes(String, Codes),
    npl_lex_codes_pos(Codes, 1, 1, Tokens).

%% =====================================================================
%% Plain lexer (no position tracking)
%% =====================================================================

npl_lex_codes([], []).
npl_lex_codes([C|Cs], Tokens) :-
    ( npl_whitespace(C)
    -> npl_lex_codes(Cs, Tokens)
    ; npl_lex_token([C|Cs], Token, Rest)
    -> ( Token = comment
       -> npl_lex_codes(Rest, Tokens)
       ;  Tokens = [Token|More],
          npl_lex_codes(Rest, More)
       )
    ; char_code(Ch, C),
      Tokens = [error(unknown_char(Ch))|More],
      npl_lex_codes(Cs, More)
    ).

%% =====================================================================
%% Positioned lexer
%% =====================================================================

npl_lex_codes_pos([], _, _, []).
npl_lex_codes_pos([C|Cs], L, Col, Tokens) :-
    ( C =:= 0'\n
    -> L1 is L + 1,
       npl_lex_codes_pos(Cs, L1, 1, Tokens)
    ; npl_whitespace(C)
    -> Col1 is Col + 1,
       npl_lex_codes_pos(Cs, L, Col1, Tokens)
    ; npl_lex_token([C|Cs], Token, Rest)
    -> append(Consumed, Rest, [C|Cs]),
       npl_advance_pos(Consumed, L, Col, L1, Col1),
       % comment tokens are discarded (not wrapped); all other tokens are wrapped
       ( Token = comment
       -> npl_lex_codes_pos(Rest, L1, Col1, Tokens)
       ;  Tokens = [tok(Token, pos(L, Col))|More],
          npl_lex_codes_pos(Rest, L1, Col1, More)
       )
    ; char_code(Ch, C),
      Col1 is Col + 1,
      Tokens = [tok(error(unknown_char(Ch)), pos(L, Col))|More],
      npl_lex_codes_pos(Cs, L, Col1, More)
    ).

%% npl_advance_pos/5
%  Advance Line/Col over a list of consumed character codes.
npl_advance_pos([], L, Col, L, Col).
npl_advance_pos([0'\n|Cs], L, _, L1, Col1) :- !,
    L2 is L + 1,
    npl_advance_pos(Cs, L2, 1, L1, Col1).
npl_advance_pos([_|Cs], L, Col, L1, Col1) :-
    Col2 is Col + 1,
    npl_advance_pos(Cs, L, Col2, L1, Col1).

%% =====================================================================
%% Whitespace
%% =====================================================================

npl_whitespace(0' ).
npl_whitespace(0'\t).
npl_whitespace(0'\n).
npl_whitespace(0'\r).

%% =====================================================================
%% Token dispatch
%% =====================================================================

%% Cognitive-code annotation: %@ text
%  Must be tested before plain line comment.
npl_lex_token([0'%, 0'@|Cs], annot(Text), Rest) :- !,
    npl_lex_annot(Cs, TextCodes, Rest),
    atom_codes(Text, TextCodes).

%% Line comment: skip to end of line
npl_lex_token([0'%|Cs], comment, Rest) :- !,
    npl_skip_line(Cs, Rest).

%% Block comment: skip to */; error if unterminated
npl_lex_token([0'/, 0'*|Cs], Token, Rest) :- !,
    ( npl_skip_block_comment(Cs, Rest)
    -> Token = comment
    ;  Token = error(unterminated_block_comment), Rest = []
    ).

%% Quoted atom: error if unterminated
npl_lex_token([0''|Cs], Token, Rest) :- !,
    ( npl_lex_quoted(0'', Cs, Codes, Rest)
    -> atom_codes(A, Codes), Token = atom(A)
    ;  Token = error(unterminated_atom), Rest = []
    ).

%% Double-quoted string: error if unterminated
npl_lex_token([0'"|Cs], Token, Rest) :- !,
    ( npl_lex_quoted(0'", Cs, Codes, Rest)
    -> atom_codes(S, Codes), Token = string(S)
    ;  Token = error(unterminated_string), Rest = []
    ).

%% Identifier: atom (lowercase) or variable (uppercase)
npl_lex_token([C|Cs], Token, Rest) :-
    char_type(C, alpha), !,
    ( char_type(C, upper)
    -> npl_lex_id([C|Cs], Codes, Rest),
       atom_codes(A, Codes),
       Token = var(A)
    ;  npl_lex_id([C|Cs], Codes, Rest),
       atom_codes(A, Codes),
       Token = atom(A)
    ).

%% Underscore: anonymous var (_) or named var (_Foo)
npl_lex_token([0'_|Cs], var(V), Rest) :- !,
    npl_lex_id_rest(Cs, RestCodes, Rest),
    ( RestCodes = []
    -> V = '_'
    ;  atom_codes(V, [0'_|RestCodes])
    ).

%% Number
npl_lex_token([C|Cs], Token, Rest) :-
    char_type(C, digit), !,
    npl_lex_number([C|Cs], Token, Rest).

%% Punctuation
npl_lex_token([C|Cs], punct(P), Rest) :-
    npl_punct([C|Cs], P, Rest), !.

%% Operator symbol sequence
npl_lex_token([C|Cs], atom(A), Rest) :-
    npl_lex_symbol([C|Cs], Codes, Rest),
    Codes \= [],
    atom_codes(A, Codes).

%% =====================================================================
%% Comment helpers
%% =====================================================================

npl_skip_line([], []).
npl_skip_line([0'\n|Cs], Cs) :- !.
npl_skip_line([_|Cs], Rest) :- npl_skip_line(Cs, Rest).

%% npl_skip_block_comment/2 — fails if input runs out before */
%  The absence of a npl_skip_block_comment([], _) base case is intentional:
%  reaching EOF without finding */ signals an unterminated block comment.
npl_skip_block_comment([0'*, 0'/|Cs], Cs) :- !.
npl_skip_block_comment([_|Cs], Rest) :- npl_skip_block_comment(Cs, Rest).

%% npl_lex_annot/3
%  Read annotation text, trimming a single leading space, up to EOL/EOF.
npl_lex_annot([0' |Cs], Codes, Rest) :- !,
    npl_lex_annot_rest(Cs, Codes, Rest).
npl_lex_annot(Cs, Codes, Rest) :-
    npl_lex_annot_rest(Cs, Codes, Rest).

npl_lex_annot_rest([], [], []).
npl_lex_annot_rest([0'\n|Cs], [], Cs) :- !.
npl_lex_annot_rest([C|Cs], [C|Codes], Rest) :-
    npl_lex_annot_rest(Cs, Codes, Rest).

%% =====================================================================
%% Quoted token (atom or string)
%% =====================================================================

%% npl_lex_quoted/4 — fails on unterminated input (no EOF-as-close clause)
npl_lex_quoted(Q, [Q|Cs], [], Cs) :- !.
npl_lex_quoted(Q, [0'\\, C|Cs], [EC|Codes], Rest) :- !,
    npl_escape(C, EC),
    npl_lex_quoted(Q, Cs, Codes, Rest).
npl_lex_quoted(Q, [C|Cs], [C|Codes], Rest) :-
    C \= Q,
    npl_lex_quoted(Q, Cs, Codes, Rest).

npl_escape(0'n,  0'\n).
npl_escape(0't,  0'\t).
npl_escape(0'r,  0'\r).
npl_escape(0'\\, 0'\\).
npl_escape(0'',  0'').
npl_escape(0'",  0'").
npl_escape(C, C).

%% =====================================================================
%% Identifiers
%% =====================================================================

npl_lex_id([C|Cs], [C|Codes], Rest) :-
    npl_id_start(C), !,
    npl_lex_id_rest(Cs, Codes, Rest).

npl_lex_id_rest([], [], []).
npl_lex_id_rest([C|Cs], [C|Codes], Rest) :-
    npl_id_cont(C), !,
    npl_lex_id_rest(Cs, Codes, Rest).
npl_lex_id_rest(Cs, [], Cs).

npl_id_start(C) :- char_type(C, alpha).
npl_id_start(0'_).
npl_id_cont(C) :- char_type(C, alnum).
npl_id_cont(0'_).

%% =====================================================================
%% Numbers
%% =====================================================================

npl_lex_number(Codes, Token, Rest) :-
    npl_lex_digits(Codes, Digits, Rest1),
    ( Rest1 = [0'.|More], npl_lex_digits(More, Frac, Rest2), Frac \= []
    -> append(Digits, [0'.|Frac], NumCodes),
       number_codes(N, NumCodes),
       Token = float(N), Rest = Rest2
    ; number_codes(N, Digits),
      Token = integer(N), Rest = Rest1
    ).

npl_lex_digits([C|Cs], [C|Ds], Rest) :-
    char_type(C, digit), !,
    npl_lex_digits(Cs, Ds, Rest).
npl_lex_digits(Cs, [], Cs).

%% =====================================================================
%% Symbol characters (operators)
%% =====================================================================

npl_lex_symbol([C|Cs], [C|Codes], Rest) :-
    npl_symbol_char(C), !,
    npl_lex_symbol(Cs, Codes, Rest).
npl_lex_symbol(Cs, [], Cs).

npl_symbol_char(0'+).
npl_symbol_char(0'-).
npl_symbol_char(0'*).
npl_symbol_char(0'/).
npl_symbol_char(0'\\).
npl_symbol_char(0'^).
npl_symbol_char(0'<).
npl_symbol_char(0'>).
npl_symbol_char(0'=).
npl_symbol_char(0'?).
npl_symbol_char(0'@).
npl_symbol_char(0'#).
npl_symbol_char(0'&).
npl_symbol_char(0':).

%% =====================================================================
%% Punctuation
%% =====================================================================

npl_punct([0'(|Cs], '(', Cs).
npl_punct([0')|Cs], ')', Cs).
npl_punct([0'[|Cs], '[', Cs).
npl_punct([0']|Cs], ']', Cs).
npl_punct([0'{|Cs], '{', Cs).
npl_punct([0'}|Cs], '}', Cs).
npl_punct([0',|Cs], ',', Cs).
npl_punct([0';|Cs], ';', Cs).
npl_punct([0'||Cs], '|', Cs).
npl_punct([0'!|Cs], '!', Cs).
npl_punct([0'.|Cs], '.', Cs).
