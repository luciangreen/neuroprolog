% lexer.pl — NeuroProlog Lexer
%
% Tokenises a Prolog source file into a list of tokens.
% Token types: atom, var, integer, float, string, punct

:- module(lexer, [npl_lex/2, npl_lex_string/2]).

:- use_module(library(lists)).

%% npl_lex/2
%  npl_lex(+SourceFile, -Tokens)
%  Read a file and return its token list.
npl_lex(File, Tokens) :-
    read_file_to_codes(File, Codes, []),
    npl_lex_codes(Codes, Tokens).

%% npl_lex_string/2
%  npl_lex_string(+String, -Tokens)
npl_lex_string(String, Tokens) :-
    atom_codes(String, Codes),
    npl_lex_codes(Codes, Tokens).

%% npl_lex_codes/2
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
    ; npl_lex_codes(Cs, Tokens)
    ).

%% npl_whitespace/1
npl_whitespace(0' ).
npl_whitespace(0'\t).
npl_whitespace(0'\n).
npl_whitespace(0'\r).

%% npl_lex_token/3
%  npl_lex_token(+Codes, -Token, -Rest)

npl_lex_token([0'%|Cs], comment, Rest) :- !,
    npl_skip_line(Cs, Rest).

npl_lex_token([0'/,0'*|Cs], comment, Rest) :- !,
    npl_skip_block_comment(Cs, Rest).

npl_lex_token([0'\'|Cs], atom(A), Rest) :- !,
    npl_lex_quoted(0'\', Cs, Codes, Rest),
    atom_codes(A, Codes).

npl_lex_token([0'"|Cs], string(S), Rest) :- !,
    npl_lex_quoted(0'", Cs, Codes, Rest),
    atom_codes(S, Codes).

npl_lex_token([C|Cs], Token, Rest) :-
    char_type(C, alpha), !,
    ( char_type(C, upper) ->
        npl_lex_id([C|Cs], Codes, Rest),
        atom_codes(A, Codes),
        Token = var(A)
    ; npl_lex_id([C|Cs], Codes, Rest),
      atom_codes(A, Codes),
      Token = atom(A)
    ).

npl_lex_token([0'_|Cs], var('_'), Rest) :- !,
    npl_lex_id_rest(Cs, _, Rest).

npl_lex_token([C|Cs], Token, Rest) :-
    char_type(C, digit), !,
    npl_lex_number([C|Cs], Token, Rest).

npl_lex_token([C|Cs], punct(P), Rest) :-
    npl_punct([C|Cs], P, Rest), !.

npl_lex_token([C|Cs], atom(A), Rest) :-
    npl_lex_symbol([C|Cs], Codes, Rest),
    Codes \= [],
    atom_codes(A, Codes).

%% npl_skip_line/2
npl_skip_line([], []).
npl_skip_line([0'\n|Cs], Cs) :- !.
npl_skip_line([_|Cs], Rest) :- npl_skip_line(Cs, Rest).

%% npl_skip_block_comment/2
npl_skip_block_comment([], []).
npl_skip_block_comment([0'*,0'/|Cs], Cs) :- !.
npl_skip_block_comment([_|Cs], Rest) :- npl_skip_block_comment(Cs, Rest).

%% npl_lex_quoted/4
npl_lex_quoted(_, [], [], []).
npl_lex_quoted(Q, [Q|Cs], [], Cs) :- !.
npl_lex_quoted(Q, [0'\\, C|Cs], [EC|Codes], Rest) :- !,
    npl_escape(C, EC),
    npl_lex_quoted(Q, Cs, Codes, Rest).
npl_lex_quoted(Q, [C|Cs], [C|Codes], Rest) :-
    npl_lex_quoted(Q, Cs, Codes, Rest).

npl_escape(0'n, 0'\n).
npl_escape(0't, 0'\t).
npl_escape(0'r, 0'\r).
npl_escape(0'\\, 0'\\).
npl_escape(0'\', 0'\').
npl_escape(0'", 0'").
npl_escape(C, C).

%% npl_lex_id/3
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

%% npl_lex_number/3
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

%% npl_lex_symbol/3
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

%% npl_punct/3
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
npl_punct([0':|Cs], ':', Cs).
