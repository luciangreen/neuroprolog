% parser.pl — NeuroProlog Parser
%
% Parses a token list into an Abstract Syntax Tree (AST).
% The AST represents Prolog clauses as terms.

:- module(parser, [npl_parse/2, npl_run/1]).

%% npl_parse/2
%  npl_parse(+Tokens, -AST)
%  Convert a token list to a list of clause AST nodes.
npl_parse(Tokens, AST) :-
    npl_parse_clauses(Tokens, AST).

%% npl_parse_clauses/2
npl_parse_clauses([], []).
npl_parse_clauses(Tokens, [Clause|Clauses]) :-
    npl_parse_clause(Tokens, Clause, Rest), !,
    npl_parse_clauses(Rest, Clauses).
npl_parse_clauses([_|Tokens], Clauses) :-
    npl_parse_clauses(Tokens, Clauses).

%% npl_parse_clause/3
%  Parse a single clause (fact or rule).
npl_parse_clause(Tokens, clause(Head, Body), Rest) :-
    npl_parse_term(Tokens, Head, Rest0),
    ( Rest0 = [punct('.')|Rest] ->
        Body = true
    ; Rest0 = [atom(':-')|BodyTokens] ->
        npl_parse_body(BodyTokens, Body, [punct('.')|Rest])
    ; Body = true, Rest = Rest0
    ).

%% npl_parse_body/3
npl_parse_body(Tokens, Body, Rest) :-
    npl_parse_conjunction(Tokens, Body, Rest).

%% npl_parse_conjunction/3
npl_parse_conjunction(Tokens, Conj, Rest) :-
    npl_parse_term(Tokens, T1, Rest1),
    ( Rest1 = [punct(',')|Rest2] ->
        npl_parse_conjunction(Rest2, T2, Rest),
        Conj = ','(T1, T2)
    ; Conj = T1, Rest = Rest1
    ).

%% npl_parse_term/3
%  Parse a single term.
npl_parse_term([atom(F)|Tokens], Term, Rest) :-
    Tokens = [punct('(')|ArgTokens], !,
    npl_parse_args(ArgTokens, Args, [punct(')')|Rest]),
    Term =.. [F|Args].
npl_parse_term([atom(A)|Rest], A, Rest) :- !.
npl_parse_term([var(V)|Rest], var(V), Rest) :- !.
npl_parse_term([integer(N)|Rest], N, Rest) :- !.
npl_parse_term([float(F)|Rest], F, Rest) :- !.
npl_parse_term([string(S)|Rest], S, Rest) :- !.
npl_parse_term([punct('[')|Tokens], List, Rest) :- !,
    npl_parse_list(Tokens, List, Rest).
npl_parse_term([punct('!')|Rest], !, Rest) :- !.

%% npl_parse_args/3
npl_parse_args(Tokens, [], Tokens) :-
    Tokens = [punct(')')|_], !.
npl_parse_args(Tokens, [Arg|Args], Rest) :-
    npl_parse_term(Tokens, Arg, Rest1),
    ( Rest1 = [punct(',')|Rest2] ->
        npl_parse_args(Rest2, Args, Rest)
    ; Args = [], Rest = Rest1
    ).

%% npl_parse_list/3
npl_parse_list([punct(']')|Rest], [], Rest) :- !.
npl_parse_list(Tokens, [H|T], Rest) :-
    npl_parse_term(Tokens, H, Rest1),
    ( Rest1 = [punct('|')|Rest2] ->
        npl_parse_term(Rest2, T, [punct(']')|Rest])
    ; Rest1 = [punct(',')|Rest2] ->
        npl_parse_list(Rest2, T, Rest)
    ; T = [], Rest1 = [punct(']')|Rest]
    ).

%% npl_run/1  — run AST clauses (assert them)
npl_run([]).
npl_run([clause(Head, true)|Cs]) :- !,
    assertz(Head),
    npl_run(Cs).
npl_run([clause(Head, Body)|Cs]) :-
    assertz((Head :- Body)),
    npl_run(Cs).
