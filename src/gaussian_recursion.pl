% gaussian_recursion.pl — NeuroProlog Gaussian Recursion Reduction (Stage 9)
%
% Applies Gaussian-elimination-style transforms to convert recursive
% predicate definitions into polynomial-time (accumulator) form, where
% correctness is guaranteed.
%
% === Supported recursion classes ===
%
%   linear_tail_recursion
%     The recursive call is the last goal in the body.  The predicate is
%     already in optimal loop form; no structural rewrite is performed
%     (tail-call optimisation, if required, is handled by the code
%     generator).  The group is emitted unchanged.
%
%   linear_accumulate(Op, Id)
%     A single recursive call whose result is combined with extra terms via
%     an arithmetic operator before being returned.  The recurrence has the
%     shape  f(n) = Op(f(n-1), extra(n))  with identity Id for Op.
%     Supported operators: +  (Id = 0),  *  (Id = 1).
%     The group is rewritten to an accumulator-passing form:
%       f(Args, R)        :- f_gauss_acc(Args, Id, R).
%       f_gauss_acc(Base, Acc, Acc).
%       f_gauss_acc(Step, Acc0, R) :- Acc1 is Op(Acc0,Extra), f_gauss_acc(Rec,Acc1,R).
%
% === Gaussian elimination engine ===
%
%   npl_gauss_eliminate/2 performs exact row reduction (Gaussian
%   elimination) on a matrix of rational numbers represented as
%   frac(Numerator, Denominator) terms.  The result is the reduced row
%   echelon form (RREF) of the input matrix.  This is used to analyse systems of mutually
%   recursive linear recurrences and determine whether they can be reduced
%   to a simpler representation.
%
% === Safety guarantee ===
%
%   No transform is applied unless a syntactic proof of correctness exists
%   for the recognised pattern.  Unrecognised groups are emitted unchanged.

:- module(gaussian_recursion, [
    npl_gaussian_reduce/2,
    npl_is_reducible/2,
    npl_reduce_clause_group/2,
    npl_extract_recurrence/2,
    npl_gauss_eliminate/2,
    npl_build_coefficient_matrix/2,
    npl_detect_polynomial_degree/2,
    npl_build_polynomial_system/4,
    npl_gaussian_elimination/3,
    npl_reconstruct_polynomial/3,
    npl_validate_polynomial_formula/4
]).

:- use_module(library(lists)).

%%====================================================================
%% Top-level driver
%%====================================================================

%% npl_gaussian_reduce/2
%  npl_gaussian_reduce(+IR, -ReducedIR)
npl_gaussian_reduce(IR, ReducedIR) :-
    npl_group_by_functor(IR, Groups),
    maplist(npl_reduce_group, Groups, ReducedGroups),
    npl_flatten_groups(ReducedGroups, ReducedIR).

%% npl_group_by_functor/2
%  Group IR clauses by head functor/arity.
npl_group_by_functor([], []).
npl_group_by_functor([C|Cs], [[C|Group]|Groups]) :-
    C = ir_clause(Head, _, _),
    functor(Head, F, A),
    partition(npl_same_functor(F/A), Cs, Group, Rest),
    npl_group_by_functor(Rest, Groups).

npl_same_functor(F/A, ir_clause(Head, _, _)) :-
    functor(Head, F, A).

%% npl_reduce_group/2
%  Attempt to reduce a group of clauses for the same predicate.
npl_reduce_group(Group, Reduced) :-
    ( npl_is_reducible(Group, linear_tail_recursion) ->
        npl_reduce_clause_group(Group, Reduced)
    ; npl_is_reducible(Group, linear_accumulate(_Op, _Id)) ->
        npl_reduce_clause_group(Group, Reduced)
    ; Reduced = Group
    ).

%% npl_flatten_groups/2
npl_flatten_groups([], []).
npl_flatten_groups([G|Gs], Flat) :-
    append(G, Rest, Flat),
    npl_flatten_groups(Gs, Rest).

%%====================================================================
%% Reducibility detection
%%====================================================================

%% npl_is_reducible/2
%  npl_is_reducible(+Group, -Pattern)
%  Succeeds when Group is amenable to the named reduction.
%
%  Pattern = linear_tail_recursion
%    Two clauses; base body is ir_true; step body ends with a recursive call.
npl_is_reducible(Group, linear_tail_recursion) :-
    length(Group, 2),
    Group = [Base, Step],
    Base  = ir_clause(BaseHead, ir_true, _),
    Step  = ir_clause(StepHead, StepBody, _),
    functor(BaseHead, F, A),
    functor(StepHead, F, A),
    npl_ir_body_ends_with_rec_call(StepBody, RecCall),
    functor(RecCall,  F, A).

%  Pattern = linear_accumulate(Op, Id)
%    Two clauses; base body is ir_true and last head arg is a concrete
%    integer (the identity); step body has exactly one recursive call
%    whose result appears in an immediately following is/2 expression of
%    the form  Result is Op(RecResult, Extra)  with Op in {+, *}.
npl_is_reducible(Group, linear_accumulate(Op, Id)) :-
    length(Group, 2),
    Group = [Base, Step],
    Base  = ir_clause(BaseHead, ir_true, _),
    Step  = ir_clause(StepHead, StepBody, _),
    functor(BaseHead, F, A), A >= 2,
    functor(StepHead, F, A),
    % Base result (last argument) must be a concrete integer
    BaseHead =.. [F|BaseArgs],
    last(BaseArgs, BaseResult),
    integer(BaseResult),
    % Step body: find recursive call then is/2 arithmetic combination
    npl_ir_body_find_rec_call(StepBody, F, A, RecCall),
    npl_ir_last_arg(RecCall, RecResultVar),
    npl_ir_body_find_is(StepBody, _ResultVar, ArithExpr),
    npl_linear_arith(RecResultVar, ArithExpr, Op, _Extra),
    npl_op_identity(Op, Id),
    Id =:= BaseResult.

%%====================================================================
%% Recurrence extractor
%%====================================================================

%% npl_extract_recurrence/2
%  npl_extract_recurrence(+ClauseGroup, -Recurrence)
%  Extract a structured recurrence descriptor from a clause group.
%
%  Recurrence has one of these forms:
%    recurrence(F/A, linear_tail,       info(base:BaseHead))
%    recurrence(F/A, linear_accumulate, info(op:Op, identity:Id, base:BaseHead))
%    recurrence(F/A, none,              info(reason:unrecognised))
npl_extract_recurrence(Group, Recurrence) :-
    Group = [ir_clause(Head, _, _)|_],
    functor(Head, F, A),
    Sig = F/A,
    ( npl_is_reducible(Group, linear_tail_recursion) ->
        Group = [Base|_],
        Base  = ir_clause(BaseHead, _, _),
        Recurrence = recurrence(Sig, linear_tail, info(base:BaseHead))
    ; npl_is_reducible(Group, linear_accumulate(Op, Id)) ->
        Group = [Base|_],
        Base  = ir_clause(BaseHead, _, _),
        Recurrence = recurrence(Sig, linear_accumulate,
                                info(op:Op, identity:Id, base:BaseHead))
    ;
        Recurrence = recurrence(Sig, none, info(reason:unrecognised))
    ).
npl_extract_recurrence([], recurrence(unknown/0, none, info(reason:empty_group))).

%%====================================================================
%% Reduce clause group (rewrite pass)
%%====================================================================

%% npl_reduce_clause_group/2
%  npl_reduce_clause_group(+Group, -Reduced)
%  Rewrite a recognised group.  Falls back to Group if the specific
%  transform cannot be safely constructed.
npl_reduce_clause_group(Group, Reduced) :-
    ( npl_is_reducible(Group, linear_accumulate(_Op, _Id)) ->
        ( npl_accumulator_rewrite(Group, AccGroup) ->
            Reduced = AccGroup
        ; Reduced = Group
        )
    ; % linear_tail_recursion and unrecognised: emit unchanged
      Reduced = Group
    ).

%% npl_accumulator_rewrite/2
%  npl_accumulator_rewrite(+[BaseClause,StepClause], -NewClauses)
%  Produce three accumulator-form IR clauses replacing the original two.
%  Fails if the structural analysis cannot be completed safely.
npl_accumulator_rewrite([Base, Step], [WrapClause, AccBase, AccStep]) :-
    Base = ir_clause(BaseHead, ir_true, _),
    Step = ir_clause(StepHead, StepBody, _),
    functor(BaseHead, F, A),
    A >= 2,
    atom_concat(F, '_gauss_acc', FAccName),

    % Extract identity from base (last arg must be concrete integer)
    BaseHead =.. [F|BArgs],
    last(BArgs, Identity),
    integer(Identity),
    append(BStructArgs, [Identity], BArgs),
    length(BStructArgs, NStruct),
    NStruct >= 1,

    % Validate and extract step components
    npl_ir_body_find_rec_call(StepBody, F, A, RecCall),
    npl_ir_last_arg(RecCall, RecResultVar),
    npl_ir_body_find_is(StepBody, _StepResultVar, ArithExpr),
    npl_linear_arith(RecResultVar, ArithExpr, Op, Extra),
    npl_op_identity(Op, Identity),

    % Structural args from step head (all except last/result)
    StepHead =.. [F|SArgs],
    append(SStructArgs, [_SResult], SArgs),

    % Structural args from recursive call (all except last/result)
    RecCall =.. [F|RArgs],
    append(RStructArgs, [_RResult], RArgs),

    % --- 1. Wrapper clause: f(WS..., WR) :- f_gauss_acc(WS..., Id, WR) ---
    functor(WrapHead, F, A),
    WrapHead =.. [F|WrapAllArgs],
    last(WrapAllArgs, WrapR),
    append(WrapSArgs, [WrapR], WrapAllArgs),
    append(WrapSArgs, [Identity, WrapR], WrapAccArgs),
    WrapBodyGoal =.. [FAccName|WrapAccArgs],
    WrapClause = ir_clause(WrapHead, ir_call(WrapBodyGoal), []),

    % --- 2. Accumulator base: f_gauss_acc(BStruct..., Acc, Acc) :- true ---
    % Use copy_term so BStructArgs get fresh variable copies
    copy_term(BStructArgs, BStructArgsCopy),
    append(BStructArgsCopy, [AccBaseVar, AccBaseVar], AccBaseArgList),
    AccBaseHead =.. [FAccName|AccBaseArgList],
    AccBase = ir_clause(AccBaseHead, ir_true, []),

    % --- 3. Accumulator step: f_gauss_acc(SStruct..., Acc0, R) :-
    %            Acc1 is Op(Acc0, Extra), f_gauss_acc(RStruct..., Acc1, R) ---
    % copy_term keeps sharing between SStructArgs, RStructArgs, Extra
    copy_term(SStructArgs-RStructArgs-Extra, SStructCopy-RStructCopy-ExtraCopy),
    npl_build_arith(Op, Acc0, ExtraCopy, NewArithExpr),
    append(SStructCopy, [Acc0, AccStepResult], AccStepHeadArgs),
    AccStepHead =.. [FAccName|AccStepHeadArgs],
    append(RStructCopy, [Acc1, AccStepResult], AccStepRecArgs),
    AccStepRecCall =.. [FAccName|AccStepRecArgs],
    AccStepBody = ir_seq(ir_call(is(Acc1, NewArithExpr)), ir_call(AccStepRecCall)),
    AccStep = ir_clause(AccStepHead, AccStepBody, []).

%%====================================================================
%% Gaussian elimination engine
%%====================================================================
%%
%% Operates on matrices whose entries are frac(Numerator, Denominator)
%% rational numbers.  Produces the row echelon form via exact row
%% reduction, which allows zero-rank detection and coefficient analysis
%% for systems of mutual linear recurrences.

%% npl_gauss_eliminate/2
%  npl_gauss_eliminate(+Matrix, -RREF)
%  Apply Gaussian (row) elimination to produce reduced row echelon form.
%  Matrix is a list of rows; each row is a list of frac/2 terms.
npl_gauss_eliminate([], []) :- !.
npl_gauss_eliminate(Matrix, RREF) :-
    length(Matrix, NRows),
    Matrix = [FirstRow|_],
    length(FirstRow, NCols),
    npl_gauss_rref(Matrix, NRows, NCols, 1, 1, RREF).

npl_gauss_rref(Rows, NRows, _NCols, PivotRow, _Col, Rows) :-
    PivotRow > NRows, !.
npl_gauss_rref(Rows, _NRows, NCols, _PivotRow, Col, Rows) :-
    Col > NCols, !.
npl_gauss_rref(Rows, NRows, NCols, PivotRow, Col, RREF) :-
    ( npl_find_pivot_row_index(Rows, PivotRow, Col, PivotIdx) ->
        npl_swap_rows(Rows, PivotRow, PivotIdx, Swapped),
        nth1(PivotRow, Swapped, RawPivotRow),
        nth1(Col, RawPivotRow, PivotVal),
        npl_row_scale(RawPivotRow, PivotVal, NormPivotRow),
        npl_set_row(Swapped, PivotRow, NormPivotRow, WithNormPivot),
        npl_eliminate_column_except(WithNormPivot, PivotRow, Col, NormPivotRow, Eliminated),
        NextPivotRow is PivotRow + 1,
        NextCol is Col + 1,
        npl_gauss_rref(Eliminated, NRows, NCols, NextPivotRow, NextCol, RREF)
    ;
        NextCol is Col + 1,
        npl_gauss_rref(Rows, NRows, NCols, PivotRow, NextCol, RREF)
    ).

npl_find_pivot_row_index(Rows, StartRow, Col, PivotIdx) :-
    nth1(PivotIdx, Rows, Row),
    PivotIdx >= StartRow,
    nth1(Col, Row, Entry),
    \+ npl_frac_zero_val(Entry), !.

npl_swap_rows(Rows, I, I, Rows) :- !.
npl_swap_rows(Rows, I, J, Swapped) :-
    nth1(I, Rows, RowI),
    nth1(J, Rows, RowJ),
    npl_set_row(Rows, I, RowJ, Tmp),
    npl_set_row(Tmp, J, RowI, Swapped).

npl_set_row([_|Rows], 1, NewRow, [NewRow|Rows]) :- !.
npl_set_row([Row|Rows], Index, NewRow, [Row|Out]) :-
    Index > 1,
    I1 is Index - 1,
    npl_set_row(Rows, I1, NewRow, Out).

npl_eliminate_column_except([], _, _, _, []).
npl_eliminate_column_except([Row|Rows], PivotIdx, Col, PivotRow, [OutRow|OutRows]) :-
    ( PivotIdx =:= 1 ->
        OutRow = Row
    ;
        nth1(Col, Row, Factor),
        ( npl_frac_zero_val(Factor) ->
            OutRow = Row
        ;
            npl_row_sub_scaled(Row, PivotRow, Factor, OutRow)
        )
    ),
    PivotIdx1 is PivotIdx - 1,
    npl_eliminate_column_except(Rows, PivotIdx1, Col, PivotRow, OutRows).

npl_row_sub_scaled(Row, PivotRow, Factor, OutRow) :-
    maplist(npl_frac_mul(Factor), PivotRow, ScaledPivot),
    maplist(npl_frac_sub_pair, Row, ScaledPivot, OutRow).

npl_frac_sub_pair(A, B, R) :- npl_frac_sub(A, B, R).

npl_frac_zero_val(frac(0, _)) :- !.

%% npl_row_scale/3
%  Divide every entry in Row by Divisor.
npl_row_scale(Row, Divisor, Scaled) :-
    maplist(npl_frac_div_by(Divisor), Row, Scaled).

npl_frac_div_by(Div, X, R) :- npl_frac_div(X, Div, R).

%% npl_eliminate_entry/3
%  Subtract a multiple of PivotRow from TargetRow to zero the first entry.
npl_eliminate_entry(PivotRow, TargetRow, Result) :-
    PivotRow  = [_|_],
    TargetRow = [TFirst|_],
    npl_frac_neg(TFirst, NegTFirst),
    maplist(npl_frac_mul(NegTFirst), PivotRow, ScaledPivot),
    maplist(npl_frac_add_pair, TargetRow, ScaledPivot, Result).

npl_frac_add_pair(A, B, R) :- npl_frac_add(A, B, R).

%% npl_row_tail/2  and  npl_row_cons/3 — for column-skipping
npl_row_tail([_|T], T).
npl_row_cons(H, T, [H|T]).

%%====================================================================
%% Coefficient matrix builder
%%====================================================================

%% npl_build_coefficient_matrix/2
%  npl_build_coefficient_matrix(+RecurrenceList, -Matrix)
%  Build a coefficient matrix from a list of recurrence descriptors of
%  the form  recurrence(Sig, linear_accumulate, info(op:Op, ...)).
%  Each row corresponds to one recurrence; each column to one recurrence
%  in the system.  Off-diagonal entries are frac(0,1); diagonal entries
%  encode the linear coefficient (1 for additive, 1 for multiplicative).
npl_build_coefficient_matrix(Recurrences, Matrix) :-
    length(Recurrences, N),
    numlist(1, N, Indices),
    maplist(npl_build_matrix_row(Recurrences, N), Indices, Matrix).

npl_build_matrix_row(Recurrences, N, RowIdx, Row) :-
    numlist(1, N, ColIndices),
    maplist(npl_matrix_entry(Recurrences, RowIdx), ColIndices, Row).

npl_matrix_entry(Recurrences, RowIdx, ColIdx, Entry) :-
    ( RowIdx =:= ColIdx ->
        nth1(RowIdx, Recurrences, Rec),
        npl_recurrence_coeff(Rec, Coeff),
        Entry = frac(Coeff, 1)
    ;
        Entry = frac(0, 1)
    ).

npl_recurrence_coeff(recurrence(_, linear_accumulate, info(op:'+', _, _)), 1) :- !.
npl_recurrence_coeff(recurrence(_, linear_accumulate, info(op:'*', _, _)), 1) :- !.
npl_recurrence_coeff(recurrence(_, linear_tail, _), 1) :- !.
npl_recurrence_coeff(_, 0).

%%====================================================================
%% Rational arithmetic  (frac(N, D) representation)
%%====================================================================

npl_frac_zero(frac(0, 1)).
npl_frac_one(frac(1, 1)).

npl_frac_from_int(N, frac(N, 1)) :- integer(N).

npl_frac_eq(frac(A, B), frac(C, D)) :-
    V1 is A * D, V2 is C * B, V1 =:= V2.

npl_frac_add(frac(A, B), frac(C, D), R) :-
    N is A * D + C * B, Den is B * D,
    npl_frac_reduce(frac(N, Den), R).

npl_frac_neg(frac(A, B), frac(N, B)) :- N is -A.

npl_frac_sub(X, Y, R) :- npl_frac_neg(Y, NY), npl_frac_add(X, NY, R).

npl_frac_mul(frac(A, B), frac(C, D), R) :-
    N is A * C, Den is B * D,
    npl_frac_reduce(frac(N, Den), R).

npl_frac_inv(frac(A, B), frac(B, A)) :- A =\= 0.

npl_frac_div(X, Y, R) :- npl_frac_inv(Y, IY), npl_frac_mul(X, IY, R).

npl_frac_reduce(frac(0, _), frac(0, 1)) :- !.
npl_frac_reduce(frac(N, D), frac(SN, SD)) :-
    G is gcd(abs(N), abs(D)),
    G > 0,
    N0 is N // G, D0 is D // G,
    ( D0 < 0 -> SN is -N0, SD is -D0 ; SN = N0, SD = D0 ).

%%====================================================================
%% IR body inspection helpers
%%====================================================================

%% npl_ir_body_find_rec_call/4
%  Find the (first) recursive call to F/A inside an IR body tree.
npl_ir_body_find_rec_call(ir_call(Goal), F, A, Goal) :-
    callable(Goal), functor(Goal, F, A), !.
npl_ir_body_find_rec_call(ir_seq(Left, _Right), F, A, Call) :-
    npl_ir_body_find_rec_call(Left, F, A, Call), !.
npl_ir_body_find_rec_call(ir_seq(_Left, Right), F, A, Call) :-
    npl_ir_body_find_rec_call(Right, F, A, Call), !.

%% npl_ir_body_find_is/3
%  Find the first  is(Var, Expr)  call inside an IR body tree.
npl_ir_body_find_is(ir_call(is(Var, Expr)), Var, Expr) :- !.
npl_ir_body_find_is(ir_seq(Left, _Right), Var, Expr) :-
    npl_ir_body_find_is(Left, Var, Expr), !.
npl_ir_body_find_is(ir_seq(_Left, Right), Var, Expr) :-
    npl_ir_body_find_is(Right, Var, Expr), !.

%% npl_ir_body_ends_with_rec_call/2
%  Succeeds when an IR body terminates in an ir_call(Goal) node.
npl_ir_body_ends_with_rec_call(ir_call(Goal), Goal) :- !.
npl_ir_body_ends_with_rec_call(ir_seq(_, Right), Goal) :-
    npl_ir_body_ends_with_rec_call(Right, Goal), !.

%% npl_ir_last_arg/2
%  Get the last argument of a compound term.
npl_ir_last_arg(Term, Last) :-
    Term =.. [_|Args],
    last(Args, Last).

%% npl_linear_arith/4
%  npl_linear_arith(+RecVar, +Expr, -Op, -Extra)
%  Succeed when Expr is a linear arithmetic expression of the form
%  Op(RecVar, Extra) or Op(Extra, RecVar).  The first argument RecVar
%  is used to identify which sub-expression is the recursive result.
npl_linear_arith(RecVar, '+'(RecVar, Extra), '+', Extra) :- !.
npl_linear_arith(RecVar, '+'(Extra, RecVar), '+', Extra) :- !.
npl_linear_arith(RecVar, '*'(RecVar, Extra), '*', Extra) :- !.
npl_linear_arith(RecVar, '*'(Extra, RecVar), '*', Extra) :- !.

%% npl_op_identity/2
%  Identity elements for supported arithmetic operators.
npl_op_identity('+', 0).
npl_op_identity('*', 1).

%% npl_build_arith/4
%  npl_build_arith(+Op, +Acc, +Extra, -Expr)
%  Build an arithmetic expression  Acc Op Extra.
npl_build_arith('+', Acc, Extra, '+'(Acc, Extra)).
npl_build_arith('*', Acc, Extra, '*'(Acc, Extra)).

%%====================================================================
%% Stage 2: Polynomial coefficient discovery via Gaussian elimination
%%====================================================================
%%
%% These predicates implement the public interface for discovering
%% polynomial formulas from sample point sets (X,Y pairs) using
%% Gaussian elimination on a Vandermonde coefficient matrix.
%%
%% Workflow:
%%   1. npl_detect_polynomial_degree/2   — estimate degree by finite differences
%%   2. npl_build_polynomial_system/4    — construct Vandermonde matrix + RHS
%%   3. npl_gaussian_elimination/3       — solve the system for coefficients
%%   4. npl_reconstruct_polynomial/3     — build arithmetic expression from coefficients
%%   5. npl_validate_polynomial_formula/4 — confirm formula matches all samples
%%
%% Arithmetic is performed throughout using exact frac(N,D) rationals.
%% The reconstructed polynomial expression uses rdiv/2 for non-integer
%% coefficients so that SWI-Prolog's is/2 can evaluate it exactly.

%% npl_detect_polynomial_degree(+Samples, -Degree)
%  Detect the polynomial degree of the sample sequence by computing
%  successive finite differences until a constant sequence is reached.
%  Samples: non-empty list of (X,Y) integer pairs in ascending X order;
%           at least two samples are required for meaningful degree detection.
%  Degree:  the minimum degree K such that K-th order differences are constant.
%  Fails if Samples is empty, has fewer than two elements, or the sequence
%  appears non-polynomial within the available sample set.
npl_detect_polynomial_degree(Samples, Degree) :-
    Samples = [_, _ | _],
    npl_samples_ys_(Samples, YValues),
    length(YValues, Len),
    MaxDegree is Len - 1,
    npl_poly_degree_by_diffs_(YValues, 0, MaxDegree, Degree).

npl_samples_ys_([], []).
npl_samples_ys_([(_X, Y) | Rest], [Y | Ys]) :-
    npl_samples_ys_(Rest, Ys).

npl_poly_degree_by_diffs_(Ys, Acc, Max, Degree) :-
    ( npl_all_same_(Ys) ->
        Degree = Acc
    ; Acc < Max ->
        npl_finite_differences_(Ys, Diffs),
        Acc1 is Acc + 1,
        npl_poly_degree_by_diffs_(Diffs, Acc1, Max, Degree)
    ;
        fail
    ).

%% npl_all_same_(+List)
%  Succeeds when all elements of List are numerically equal.
%  Requires at least one element; fails explicitly on the empty list.
npl_all_same_([]) :- !, fail.
npl_all_same_([_]) :- !.
npl_all_same_([A, B | Rest]) :-
    A =:= B,
    npl_all_same_([B | Rest]).

%% npl_finite_differences_(+Ys, -Diffs)
%  Compute the list of first-order finite differences of Ys.
npl_finite_differences_([_], []) :- !.
npl_finite_differences_([A, B | Rest], [D | Diffs]) :-
    D is B - A,
    npl_finite_differences_([B | Rest], Diffs).

%% npl_build_polynomial_system(+Samples, +Degree, -Matrix, -Vector)
%  Build the Vandermonde linear system for polynomial coefficient fitting.
%  Samples: list of (X,Y) integer pairs; at least Degree+1 are required.
%  Degree:  polynomial degree K.
%  Matrix:  list of K+1 rows; each row is [X^0, X^1, ..., X^K] as frac/2.
%  Vector:  list of K+1 Y values as frac/2.
%  The first Degree+1 samples are used to form a square system.
npl_build_polynomial_system(Samples, Degree, Matrix, Vector) :-
    NCols is Degree + 1,
    length(Samples, NSamples),
    NSamples >= NCols,
    length(SystemSamples, NCols),
    append(SystemSamples, _, Samples),
    maplist(npl_vandermonde_row_(Degree), SystemSamples, Matrix),
    maplist(npl_sample_rhs_, SystemSamples, Vector).

npl_vandermonde_row_(Degree, (X, _Y), Row) :-
    numlist(0, Degree, Powers),
    maplist(npl_int_pow_frac_(X), Powers, Row).

npl_int_pow_frac_(X, P, frac(V, 1)) :-
    V is X ^ P.

npl_sample_rhs_((_X, Y), frac(Y, 1)).

%% npl_gaussian_elimination(+Matrix, +Vector, -Coefficients)
%  Solve the linear system  Matrix * Coefficients = Vector  using
%  Gaussian elimination.  Matrix and Vector are in frac/2 representation.
%  Coefficients is the solution list [a0, a1, ..., aK] as frac/2 terms,
%  corresponding to ascending polynomial powers 0, 1, ..., K.
npl_gaussian_elimination(Matrix, Vector, Coefficients) :-
    maplist(npl_augment_row_, Matrix, Vector, Augmented),
    npl_gauss_eliminate(Augmented, RREF),
    maplist(npl_rref_solution_, RREF, Coefficients).

npl_augment_row_(Row, RHS, AugRow) :-
    append(Row, [RHS], AugRow).

npl_rref_solution_(Row, RHS) :-
    last(Row, RHS).

%% npl_reconstruct_polynomial(+Var, +Coefficients, -Expr)
%  Build a Prolog arithmetic expression for the polynomial in Var.
%  Var:          an unbound Prolog variable used as the indeterminate.
%  Coefficients: [a0, a1, ..., aK] as frac/2 terms (ascending powers).
%  Expr:         an arithmetic term evaluable by is/2 once Var is bound.
%  Zero coefficients are omitted; rational coefficients use rdiv/2;
%  coefficients of 1 are simplified away where possible.
npl_reconstruct_polynomial(Var, Coefficients, Expr) :-
    npl_poly_terms_(Var, Coefficients, 0, Terms),
    npl_sum_terms_(Terms, Expr).

npl_poly_terms_(_Var, [], _Power, []).
npl_poly_terms_(Var, [Coeff | Rest], Power, Terms) :-
    Power1 is Power + 1,
    npl_poly_terms_(Var, Rest, Power1, RestTerms),
    ( npl_frac_zero_val(Coeff) ->
        Terms = RestTerms
    ;
        npl_poly_single_term_(Var, Power, Coeff, Term),
        Terms = [Term | RestTerms]
    ).

npl_poly_single_term_(_Var, 0, Coeff, Term) :- !,
    npl_frac_to_arith_(Coeff, Term).
npl_poly_single_term_(Var, 1, frac(1, 1), Var) :- !.
npl_poly_single_term_(Var, 1, Coeff, CoeffExpr * Var) :- !,
    npl_frac_to_arith_(Coeff, CoeffExpr).
npl_poly_single_term_(Var, Power, frac(1, 1), Var ^ Power) :- !.
npl_poly_single_term_(Var, Power, Coeff, CoeffExpr * Var ^ Power) :-
    npl_frac_to_arith_(Coeff, CoeffExpr).

%% npl_frac_to_arith_(+Frac, -ArithExpr)
%  Convert a frac/2 rational to a Prolog arithmetic expression.
%  Integer-valued fracs become plain integers; others become rdiv/2.
npl_frac_to_arith_(frac(N, 1), N) :- !.
npl_frac_to_arith_(frac(N, D), rdiv(N, D)).

%% npl_sum_terms_(+Terms, -Expr)
%  Combine a list of polynomial terms into a single sum expression.
npl_sum_terms_([], 0) :- !.
npl_sum_terms_([T], T) :- !.
npl_sum_terms_([T | Rest], T + RestExpr) :-
    npl_sum_terms_(Rest, RestExpr).

%% npl_validate_polynomial_formula(+Samples, +Expr, +Var, -Result)
%  Validate that Expr evaluates correctly for every sample point.
%  Samples: list of (X,Y) integer pairs.
%  Expr:    arithmetic expression in Var (from npl_reconstruct_polynomial/3).
%  Var:     the Prolog variable appearing in Expr (will be bound per sample).
%  Result:  the atom 'true' when all samples validate; fails on mismatch.
%  Each sample is checked by binding a fresh copy of Var to X and
%  evaluating Expr with is/2, then comparing the result to Y.
npl_validate_polynomial_formula(Samples, Expr, Var, true) :-
    maplist(npl_validate_sample_(Expr, Var), Samples).

npl_validate_sample_(Expr, Var, (X, Y)) :-
    copy_term(Expr-Var, ExprCopy-VarCopy),
    VarCopy = X,
    Val is ExprCopy,
    Val =:= Y.

