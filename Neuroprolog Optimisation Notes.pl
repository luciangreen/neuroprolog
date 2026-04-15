/*Neuroprolog Optimisation Notes

Gaussian Elimination Optimisation

Finds 0.5*N^2+0.5*N^1+0*N^0 = n(n+1)/2 for 1+2+...+n or any polynomial for some recursive maths operation
Instead of using A = [0.5,1,-0.5,-1,0,-2,2] as an arbitrary way to solve the following, use Gaussian elimination to solve the matrix.
*/
nn_induction_optimisation(B,C):-A=[0.5,1,-0.5,-1,0,-2,2],member(B,A),member(C,A),F = [[1,1],[2,3],[3,6],[4,10]],maplist(f([B,C]),F,_G).
f([B,C],F,E3):-[E1,E2]=F,E3 is B*(E1^2)+C*(E1^1)+0*(E1^0),E2 =:= E3.
/*Choosing B*(E1^2) and C*(E1^1) because they work, but normally, with Gaussian elimination, solve from E1^[0 to 3].

Gaussian Elimination Worked Example: Triangular Numbers

Goal: find the polynomial S(n) = a*n^2 + b*n + c such that S(n) = 1+2+...+n.

Sample the function at n=1,2,3:
  S(1)=1, S(2)=3, S(3)=6

This gives the 3x4 augmented matrix  [n^2, n^1, n^0 | S(n)]:

  [ 1  1  1 | 1 ]   (n=1: a + b + c = 1)
  [ 4  2  1 | 3 ]   (n=2: 4a + 2b + c = 3)
  [ 9  3  1 | 6 ]   (n=3: 9a + 3b + c = 6)

Row reduction:
  R2 := R2 - 4*R1  =>  [ 0  -2  -3 | -1 ]
  R3 := R3 - 9*R1  =>  [ 0  -6  -8 | -3 ]
  R3 := R3 - 3*R2  =>  [ 0   0   1 |  0 ]

Row echelon form:
  [ 1  1  1 |  1 ]
  [ 0 -2 -3 | -1 ]
  [ 0  0  1 |  0 ]

Back-substitution:
  c = 0
  -2b - 3*0 = -1  =>  b = 1/2
  a + 1/2 + 0 = 1  =>  a = 1/2

Result: S(n) = 0.5*n^2 + 0.5*n = n*(n+1)/2   (correct!)

The npl_gauss_eliminate/2 engine in src/gaussian_recursion.pl performs this
reduction automatically using exact frac(Numerator,Denominator) arithmetic.
To run the example load src/gaussian_recursion.pl and call:

  ?- gauss_triangular_example(Echelon).

The predicate is defined below.
*/

% :- use_module('src/gaussian_recursion').

%% gauss_triangular_example/1
%  Demonstrates Gaussian elimination on the triangular-numbers system.
%  Echelon is the row echelon form of the augmented coefficient matrix.
%  Load src/gaussian_recursion.pl before calling this predicate.
%
%  Example:
%    ?- gauss_triangular_example(E), maplist(write, E).
%
gauss_triangular_example(Echelon) :-
    % Augmented matrix: rows are [n^2, n^1, n^0 | S(n)] for n=1,2,3
    Matrix = [
        [frac(1,1), frac(1,1), frac(1,1), frac(1,1)],
        [frac(4,1), frac(2,1), frac(1,1), frac(3,1)],
        [frac(9,1), frac(3,1), frac(1,1), frac(6,1)]
    ],
    npl_gauss_eliminate(Matrix, Echelon).

/* The rewritten accumulator form produced by npl_gaussian_reduce/2 for:

   sum([], 0).
   sum([H|T], S) :- sum(T, S1), S is S1 + H.

is:

   sum(List, Result)        :- sum_gauss_acc(List, 0, Result).
   sum_gauss_acc([], Acc, Acc).
   sum_gauss_acc([H|T], Acc0, Result) :- Acc1 is Acc0 + H, sum_gauss_acc(T, Acc1, Result).

The transform is safe: it preserves observable behaviour for all ground inputs
and reduces stack use from O(n) to O(1).

Choosing B*(E1^2) and C*(E1^1) because they work, but normally, with Gaussian elimination, solve from E1^[0 to 3].

Subterm address index loop

1. Change variables to have indices
This works for any computation, not just the example
2. Trace indices through predicates that process atoms, strings, numbers and terms
3. Subterm address index loop
*/
%?- diagonal1(A).
%A = [20, 30, 42].

diagonal1(D1):-findall(A,between(4,6,A),B1),
%B1_1=4, B1_2=5, B1_3=6
findall(A,between(5,7,A),B2),
%B2_1=5, B2_2=6, B2_3=7
findall(B,(member(B21,B2),findall(B3,(member(B11,B1),B3 is B11*B21),B)),B4),
/* set of formulas (1): B4 is B1_(N is 1..3)*B2_(M is 1),
B4 is B1_(N is 1..3)*B2_(M is 2),
B4 is B1_(N is 1..3)*B2_(M is 3)
*/
findall(A,between(1,3,A),C),
findall(D,(member(C1,C),nth1(C1,B4,B31),nth1(C1,B31,D)),D1).

%diagonal2(D1).
/* A = [20=4*5=B1_1*B2_1, 
30=5*6=B1_2*B2_2,
42=6*7=B1_3*B2_3].
from  B4 is B1_(N is 1)*B2_(M is 1),
B4 is B1_(N is 2)*B2_(M is 2),
B4 is B1_(N is 3)*B2_(M is 3)
- must keep set of formulas (1), changes N is 1..3 to N1 is 1 in the first instance, N1 is 2 in the second and so on
*/

diagonal2(D3):-findall(A,between(1,3,A),A1),findall(D,(member(C1,A1),D1 is 4+C1-1, D2 is 5+C1-1, D is D1*D2),D3).
% note 4+C1-1=3+C1, 5+C1-1=4+C1
% Prolog quirk - interpreter error on D is (4+C1-1)*(5+C1-1)
% See also examples/diagonal2.pl for standalone runnable versions.

/*
Similar Example to diagonal2: Sum Diagonal

The same subterm-address index loop optimisation applies when the
element-wise operation is addition rather than multiplication.

sum_diagonal1 computes the same shape as diagonal1 — a full Cartesian
sum matrix — then extracts the main diagonal.  The result is identical
to sum_diagonal2, which skips the intermediate matrix entirely.

B1=[1,2,3], B2=[4,5,6]:
  Full sum matrix:
    [ 1+4, 2+4, 3+4 ]   = [5, 6, 7]
    [ 1+5, 2+5, 3+5 ]   = [6, 7, 8]
    [ 1+6, 2+6, 3+6 ]   = [7, 8, 9]
  Diagonal: [5, 7, 9]

?- sum_diagonal1(D).   D = [5, 7, 9].
?- sum_diagonal2(D).   D = [5, 7, 9].
*/

%% sum_diagonal1/1 — unoptimised: builds full sum matrix then selects diagonal
sum_diagonal1(D1):-
    findall(A,between(1,3,A),B1),
    %B1_1=1, B1_2=2, B1_3=3
    findall(A,between(4,6,A),B2),
    %B2_1=4, B2_2=5, B2_3=6
    findall(B,(member(B21,B2),findall(B3,(member(B11,B1),B3 is B11+B21),B)),B4),
    /* set of formulas (1): B4 is B1_(N is 1..3)+B2_(M is 1),
    B4 is B1_(N is 1..3)+B2_(M is 2),
    B4 is B1_(N is 1..3)+B2_(M is 3)
    */
    findall(A,between(1,3,A),C),
    findall(D,(member(C1,C),nth1(C1,B4,B31),nth1(C1,B31,D)),D1).

%% sum_diagonal2/1 — optimised: computes diagonal elements directly
%
% A = [5=1+4=B1_1+B2_1,
%      7=2+5=B1_2+B2_2,
%      9=3+6=B1_3+B2_3].
% Applies the same index-loop transform as diagonal2:
%   D1 is 1+C1-1 = C1     (element of B1)
%   D2 is 4+C1-1 = 3+C1   (element of B2)
sum_diagonal2(D3):-findall(A,between(1,3,A),A1),findall(D,(member(C1,A1),D1 is C1, D2 is 3+C1, D is D1+D2),D3).

/*
Output Character Number and Formulas

1. Work out the number of output characters produced by each command from the number of output characters in the output, or a cutoff with memory
2. Work out the formulas for each command, starting with the first command
3. This is the optimiser, so just give the final formula (or as close to it as possible, i.e. as few of the formulas as needed)
*/