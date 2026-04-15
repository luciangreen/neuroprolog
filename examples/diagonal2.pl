% diagonal2.pl — NeuroProlog example: Subterm-address index loop optimisation
%
% Demonstrates the "subterm address index loop" optimisation described in
% "Neuroprolog Optimisation Notes.pl".
%
% The key insight is that computing the diagonal of a Cartesian-product
% matrix does not require building the full matrix.  When each dimension is
% an arithmetic sequence, the i-th diagonal element can be computed directly
% as a formula in i, skipping the intermediate O(n^2) structure.
%
% Two operation variants are provided:
%   diagonal2      — diagonal of a multiplication table  (product diagonal)
%   sum_diagonal2  — diagonal of an addition table       (sum diagonal)
%
% Both follow the same optimisation pattern:
%   1. Build full matrix (unoptimised *1 variant), then select diagonal.
%   2. Skip matrix, compute diagonal element per step (optimised *2 variant).
%
% Usage:
%   ?- demo_diagonal.

:- module(diagonal2_example, [
    diagonal1/1,
    diagonal2/1,
    sum_diagonal1/1,
    sum_diagonal2/1,
    demo_diagonal/0
]).

%%====================================================================
%% Product diagonal  (B1=[4,5,6], B2=[5,6,7], result = B1_i * B2_i)
%%====================================================================

%% diagonal1/1 — unoptimised: builds full 3x3 product matrix, then selects diagonal
%
%  ?- diagonal1(D).
%  D = [20, 30, 42].
%
%  Product matrix:
%    [ 4*5, 5*5, 6*5 ]  = [20, 25, 30]
%    [ 4*6, 5*6, 6*6 ]  = [24, 30, 36]
%    [ 4*7, 5*7, 6*7 ]  = [28, 35, 42]
%  Diagonal: [20, 30, 42]
diagonal1(D1) :-
    findall(A, between(4,6,A), B1),
    %B1_1=4, B1_2=5, B1_3=6
    findall(A, between(5,7,A), B2),
    %B2_1=5, B2_2=6, B2_3=7
    findall(B, (member(B21,B2), findall(B3,(member(B11,B1), B3 is B11*B21), B)), B4),
    findall(A, between(1,3,A), C),
    findall(D, (member(C1,C), nth1(C1,B4,B31), nth1(C1,B31,D)), D1).

%% diagonal2/1 — optimised: computes diagonal elements directly
%
%  ?- diagonal2(D).
%  D = [20, 30, 42].
%
%  Derivation: the i-th element of B1 is 4+C1-1 = 3+C1,
%              the i-th element of B2 is 5+C1-1 = 4+C1.
%  The code keeps the unsimplified form (`D1 is 4+C1-1, D2 is 5+C1-1`)
%  to show the derivation; D = D1*D2 = (3+C1)*(4+C1).
%  D_1 = 4*5 = 20,  D_2 = 5*6 = 30,  D_3 = 6*7 = 42
%
%  Note: Prolog requires separate is/2 steps; D is (4+C1-1)*(5+C1-1)
%  triggers an interpreter error on some systems.
diagonal2(D3) :-
    findall(A, between(1,3,A), A1),
    findall(D, (member(C1,A1), D1 is 4+C1-1, D2 is 5+C1-1, D is D1*D2), D3).

%%====================================================================
%% Sum diagonal  (B1=[1,2,3], B2=[4,5,6], result = B1_i + B2_i)
%%====================================================================

%% sum_diagonal1/1 — unoptimised: builds full 3x3 sum matrix, then selects diagonal
%
%  ?- sum_diagonal1(D).
%  D = [5, 7, 9].
%
%  Sum matrix:
%    [ 1+4, 2+4, 3+4 ]  = [5, 6, 7]
%    [ 1+5, 2+5, 3+5 ]  = [6, 7, 8]
%    [ 1+6, 2+6, 3+6 ]  = [7, 8, 9]
%  Diagonal: [5, 7, 9]
sum_diagonal1(D1) :-
    findall(A, between(1,3,A), B1),
    %B1_1=1, B1_2=2, B1_3=3
    findall(A, between(4,6,A), B2),
    %B2_1=4, B2_2=5, B2_3=6
    findall(B, (member(B21,B2), findall(B3,(member(B11,B1), B3 is B11+B21), B)), B4),
    findall(A, between(1,3,A), C),
    findall(D, (member(C1,C), nth1(C1,B4,B31), nth1(C1,B31,D)), D1).

%% sum_diagonal2/1 — optimised: computes diagonal elements directly
%
%  ?- sum_diagonal2(D).
%  D = [5, 7, 9].
%
%  Derivation: the i-th element of B1 is 1+C1-1 = C1 (stored as D1),
%              the i-th element of B2 is 4+C1-1 = 3+C1 (stored as D2).
%  The code evaluates `D1 is C1, D2 is 3+C1, D is D1+D2`,
%  so D = C1 + (3+C1) = 2*C1 + 3.
%  D_1 = 1+4 = 5,  D_2 = 2+5 = 7,  D_3 = 3+6 = 9
sum_diagonal2(D3) :-
    findall(A, between(1,3,A), A1),
    findall(D, (member(C1,A1), D1 is C1, D2 is 3+C1, D is D1+D2), D3).

%%====================================================================
%% Demo
%%====================================================================

%% demo_diagonal/0 — run all four variants and print results
demo_diagonal :-
    diagonal1(D1),
    write('diagonal1 (unoptimised, product):  '), write(D1), nl,
    diagonal2(D2),
    write('diagonal2 (optimised,   product):  '), write(D2), nl,
    sum_diagonal1(S1),
    write('sum_diagonal1 (unoptimised, sum):  '), write(S1), nl,
    sum_diagonal2(S2),
    write('sum_diagonal2 (optimised,   sum):  '), write(S2), nl.
