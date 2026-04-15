/*Neuroprolog Optimisation Notes

Gaussian Elimination Optimisation

Finds 0.5*N^2+0.5*N^1+0*N^0 = n(n+1)/2 for 1+2+...+n or any polynomial for some recursive maths operation
Instead of using A = [0.5,1,-0.5,-1,0,-2,2] as an arbitrary way to solve the following, use Gaussian elimination to solve the matrix.
*/
nn_induction_optimisation(B,C):-A=[0.5,1,-0.5,-1,0,-2,2],member(B,A),member(C,A),F = [[1,1],[2,3],[3,6],[4,10]],maplist(f([B,C]),F,_G).
f([B,C],F,E3):-[E1,E2]=F,E3 is B*(E1^2)+C*(E1^1)+0*(E1^0),E2 =:= E3.
/*Choosing B*(E1^2) and C*(E1^1) because they work, but normally, with Gaussian elimination, solve from E1^[0 to 3].

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

/*
Output Character Number and Formulas

1. Work out the number of output characters produced by each command from the number of output characters in the output, or a cutoff with memory
2. Work out the formulas for each command, starting with the first command
3. This is the optimiser, so just give the final formula (or as close to it as possible, i.e. as few of the formulas as needed)
*/