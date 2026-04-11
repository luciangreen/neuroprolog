% interpreter.pl — NeuroProlog Interpreter Core (Stage 7)
%
% Implements a working Prolog meta-interpreter in Prolog.
%
% == Design ==
%
% The interpreter maintains its own clause database using the dynamic
% predicate npl_user_clause/2.  This keeps user-defined predicates
% separate from SWI-Prolog's own predicate space.
%
% Execution proceeds via npl_solve_goal/2:
%   - Control structures (,) (;) (->)  (\+) are handled structurally.
%   - Cut (!) throws an exception caught at the predicate-call boundary.
%     The catch Recovery uses native Prolog `!` to remove the choice
%     point created by npl_user_clause/2 backtracking, which correctly
%     prevents re-entry on subsequent backtracking (e.g. from findall).
%     A non-unique barrier `cut_for(F/A)` is safe: SWI-Prolog's catch/3
%     always catches the nearest matching exception on the stack, so
%     recursive calls with the same functor/arity have independent frames.
%   - Built-in and library predicates not in npl_user_clause/2 are
%     dispatched to SWI-Prolog via call/1.  The use_module directives
%     below import the Prelude and Control predicates so they are
%     reachable from within this module.
%   - Generated neurocode (valid Prolog clause terms) can be loaded
%     via npl_interp_load_clauses/1 and executed immediately.
%
% == Public API ==
%
%   npl_interp_reset/0             — clear the interpreter's clause DB
%   npl_interp_assert/1            — assert one clause (fact or rule)
%   npl_interp_asserta/1           — assert at front
%   npl_interp_retract/1           — retract one matching clause
%   npl_interp_load/1              — load an AST (from parser/analyser)
%   npl_interp_load_clauses/1      — load plain clause terms
%   npl_interp_query/2             — run a query -> true | false
%   npl_interp_query_all/3         — collect all solutions
%   npl_query_runner/2             — run a list of queries
%   npl_solve/1                    — solve a goal (top-level entry)
%
% == Compatibility ==
%
% Interpreter behaviour is compatible with the compiler pipeline:
% the same clauses can be loaded into the interpreter and compiled
% to neurocode, enabling direct comparison of interpreted vs compiled
% execution results.

:- module(interpreter, [
    npl_interp_reset/0,
    npl_interp_assert/1,
    npl_interp_asserta/1,
    npl_interp_retract/1,
    npl_interp_load/1,
    npl_interp_load_clauses/1,
    npl_interp_query/2,
    npl_interp_query_all/3,
    npl_query_runner/2,
    npl_solve/1
]).

:- use_module(library(lists)).
:- use_module(prelude).   % makes npl_append/3, npl_member/2, etc. visible
:- use_module(control).   % makes npl_if/3, npl_not/1, etc. visible

% ============================================================
% 1. CLAUSE DATABASE
% ============================================================

%% npl_user_clause/2 — the interpreter's runtime clause database
%  npl_user_clause(?Head, ?Body)
%  Body is `true` for facts; a goal term for rules.
:- dynamic npl_user_clause/2.

% ============================================================
% 2. DATABASE MANAGEMENT
% ============================================================

%% npl_interp_reset/0 — clear all user-defined clauses
npl_interp_reset :-
    retractall(npl_user_clause(_, _)).

%% npl_interp_assert/1 — assert a clause at the end of the database
%  Accepts facts (plain terms) and rules ((Head :- Body)).
npl_interp_assert((Head :- Body)) :- !,
    assertz(npl_user_clause(Head, Body)).
npl_interp_assert(Head) :-
    assertz(npl_user_clause(Head, true)).

%% npl_interp_asserta/1 — assert a clause at the front of the database
npl_interp_asserta((Head :- Body)) :- !,
    asserta(npl_user_clause(Head, Body)).
npl_interp_asserta(Head) :-
    asserta(npl_user_clause(Head, true)).

%% npl_interp_retract/1 — retract the first matching clause
npl_interp_retract((Head :- Body)) :- !,
    retract(npl_user_clause(Head, Body)).
npl_interp_retract(Head) :-
    retract(npl_user_clause(Head, true)).

% ============================================================
% 3. LOADING
% ============================================================

%% npl_interp_load/1 — load an AST into the interpreter
%  Accepts the output of the parser (fact/4, rule/5, directive/4,
%  query/4, parse_error/2), the semantic analyser (analysed/3),
%  and the legacy clause/2 format.
%
%  NOTE: The parser represents variables as compound terms var(Name).
%  Rules loaded via this predicate use these compound terms as-is;
%  for programs with variables use npl_interp_assert/1 directly with
%  proper Prolog variable terms, or npl_interp_load_clauses/1.
npl_interp_load([]).

npl_interp_load([fact(Head, _, _, _)|Cs]) :- !,
    assertz(npl_user_clause(Head, true)),
    npl_interp_load(Cs).

npl_interp_load([rule(Head, Body, _, _, _)|Cs]) :- !,
    assertz(npl_user_clause(Head, Body)),
    npl_interp_load(Cs).

npl_interp_load([directive(Goal, _, _, _)|Cs]) :- !,
    catch(npl_solve(Goal), _, true),
    npl_interp_load(Cs).

npl_interp_load([query(Goal, _, _, _)|Cs]) :- !,
    catch(npl_solve(Goal), _, true),
    npl_interp_load(Cs).

npl_interp_load([parse_error(_, _)|Cs]) :- !,
    npl_interp_load(Cs).

npl_interp_load([analysed(Head, true, _)|Cs]) :- !,
    assertz(npl_user_clause(Head, true)),
    npl_interp_load(Cs).

npl_interp_load([analysed(Head, Body, _)|Cs]) :- !,
    assertz(npl_user_clause(Head, Body)),
    npl_interp_load(Cs).

npl_interp_load([clause(Head, true)|Cs]) :- !,
    assertz(npl_user_clause(Head, true)),
    npl_interp_load(Cs).

npl_interp_load([clause(Head, Body)|Cs]) :- !,
    assertz(npl_user_clause(Head, Body)),
    npl_interp_load(Cs).

npl_interp_load([_|Cs]) :-    % skip unrecognised nodes
    npl_interp_load(Cs).

%% npl_interp_load_clauses/1 — load a list of plain Prolog clause terms
%  Suitable for loading neurocode (generated by npl_generate/2) since
%  neurocode terms are valid Prolog clauses.
npl_interp_load_clauses([]).
npl_interp_load_clauses([Clause|Cs]) :-
    npl_interp_assert(Clause),
    npl_interp_load_clauses(Cs).

% ============================================================
% 4. QUERY INTERFACE
% ============================================================

%% npl_interp_query/2 — run a query, return `true` or `false`
%  Produces exactly one answer (the first solution).
npl_interp_query(Goal, true) :- npl_solve(Goal), !.
npl_interp_query(_, false).

%% npl_interp_query_all/3 — collect all solutions
%  npl_interp_query_all(+Goal, +Template, -Solutions)
%  Solutions is a list of all bindings of Template for which Goal
%  succeeds under the interpreter.
npl_interp_query_all(Goal, Template, Solutions) :-
    findall(Template, npl_solve(Goal), Solutions).

%% npl_query_runner/2 — run a list of queries, collect results
%  npl_query_runner(+Goals, -Results)
%  Each element of Results is `true` or `false` for the corresponding
%  Goal in Goals.
npl_query_runner([], []).
npl_query_runner([Goal|Goals], [Result|Results]) :-
    npl_interp_query(Goal, Result),
    npl_query_runner(Goals, Results).

% ============================================================
% 5. SOLVER
% ============================================================

%% npl_solve/1 — top-level entry point
%  Solves Goal using the interpreter's clause database plus SWI-Prolog
%  built-ins.  Supports backtracking on failure.
npl_solve(Goal) :-
    npl_solve_goal(Goal, npl_top_cut).

%% npl_solve_goal/2 — meta-interpreter with cut barrier
%  npl_solve_goal(+Goal, +CutBarrier)
%
%  CutBarrier is the term thrown by `!` to signal a cut.  For user-
%  defined predicates the barrier is cut_for(F/A).  This is non-unique
%  across calls, but correct: SWI-Prolog's catch/3 catches the NEAREST
%  matching exception on the call stack, so nested recursive calls to
%  the same predicate each catch only their own exception.
%
%  The catch Recovery uses native Prolog `!` (not `true`) to remove
%  the choice point from npl_user_clause/2 backtracking.  This is the
%  key invariant that makes cut + findall work correctly: after catching
%  the cut exception, `!` makes the predicate-call deterministic so
%  findall cannot re-enter it on backtracking.

% --- true / fail / false ---
npl_solve_goal(true, _) :- !.
npl_solve_goal(fail, _) :- !, fail.
npl_solve_goal(false, _) :- !, fail.

% --- Cut: throw the current cut barrier ---
npl_solve_goal(!, CB) :- !, throw(npl_cut(CB)).

% --- Conjunction ---
npl_solve_goal((A, B), CB) :- !,
    npl_solve_goal(A, CB),
    npl_solve_goal(B, CB).

% --- If-then-else and if-then ---
npl_solve_goal((Cond -> Then ; Else), CB) :- !,
    ( npl_solve_goal(Cond, CB)
    -> npl_solve_goal(Then, CB)
    ;  npl_solve_goal(Else, CB)
    ).

npl_solve_goal((Cond -> Then), CB) :- !,
    npl_solve_goal(Cond, CB),
    npl_solve_goal(Then, CB).

% --- Disjunction ---
npl_solve_goal((A ; B), CB) :- !,
    ( npl_solve_goal(A, CB)
    ; npl_solve_goal(B, CB)
    ).

% --- Negation as failure ---
npl_solve_goal(\+(G), CB) :- !,
    \+ npl_solve_goal(G, CB).

npl_solve_goal(not(G), CB) :- !,
    \+ npl_solve_goal(G, CB).

% --- once/1 ---
npl_solve_goal(once(G), CB) :- !,
    once(npl_solve_goal(G, CB)).

% --- ignore/1 ---
npl_solve_goal(ignore(G), CB) :- !,
    ( npl_solve_goal(G, CB) -> true ; true ).

% --- call/N: call with extra arguments appended ---
npl_solve_goal(call(G), CB) :- !,
    npl_solve_goal(G, CB).

npl_solve_goal(call(G, A), CB) :- !,
    G =.. GList,
    append(GList, [A], GList1),
    Goal =.. GList1,
    npl_solve_goal(Goal, CB).

npl_solve_goal(call(G, A, B), CB) :- !,
    G =.. GList,
    append(GList, [A, B], GList1),
    Goal =.. GList1,
    npl_solve_goal(Goal, CB).

npl_solve_goal(call(G, A, B, C), CB) :- !,
    G =.. GList,
    append(GList, [A, B, C], GList1),
    Goal =.. GList1,
    npl_solve_goal(Goal, CB).

npl_solve_goal(call(G, A, B, C, D), CB) :- !,
    G =.. GList,
    append(GList, [A, B, C, D], GList1),
    Goal =.. GList1,
    npl_solve_goal(Goal, CB).

% --- assert / retract (modify interpreter DB) ---
npl_solve_goal(assert(C), _) :- !, npl_interp_assert(C).
npl_solve_goal(assertz(C), _) :- !, npl_interp_assert(C).
npl_solve_goal(asserta(C), _) :- !, npl_interp_asserta(C).
npl_solve_goal(retract(C), _) :- !, npl_interp_retract(C).
npl_solve_goal(abolish(F/A), _) :- !,
    functor(Template, F, A),
    retractall(npl_user_clause(Template, _)).

% --- clause/2: query the interpreter's clause database ---
npl_solve_goal(clause(Head, Body), _) :- !,
    npl_user_clause(Head, Body).

% --- findall/3 ---
%  Goals are executed via npl_solve/1 so they use the interpreter.
%  User-predicate cuts are handled by each predicate's own catch frame
%  and do not escape the predicate boundary.
npl_solve_goal(findall(T, G, L), _) :- !,
    findall(T, npl_solve(G), L).

% --- catch/3 ---
%  Re-throws internal cut exceptions so they are not absorbed by
%  user-level catch goals.
npl_solve_goal(catch(Goal, Catcher, Recovery), CB) :- !,
    catch(
        npl_solve_goal(Goal, CB),
        Err,
        ( Err = npl_cut(_) -> throw(Err)
        ; Catcher = Err, npl_solve_goal(Recovery, CB)
        )
    ).

% --- throw/1 ---
npl_solve_goal(throw(E), _) :- !, throw(E).

% --- User-defined predicates ---
%  Committed when any clause for functor/arity exists in the DB.
%
%  Cut implementation — two-part mechanism:
%   1. Each invocation gets a unique ID (gensym) stored as a global
%      variable via nb_setval.  nb_setval/nb_getval are NOT rolled back
%      by exception handling or backtracking.
%   2. npl_user_clause/2 is called BEFORE the catch so head-variable
%      bindings survive exception propagation (SWI-Prolog undoes only
%      bindings made inside the Goal argument of catch/3).
%   3. When the cut exception is caught, nb_setval marks the invocation
%      as cut.  The post-catch ( nb_getval(...) -> ! ; true ) fires
%      native Prolog ! inside ->, which cuts the npl_user_clause choice
%      point and prevents findall from backtracking into more clauses.
%
%  The CutBarrier cut_for(F/A) is non-unique across invocations, but
%  safe: SWI-Prolog's catch/3 catches the NEAREST matching exception,
%  so recursive calls each catch only their own.
npl_solve_goal(Goal, _ParentCB) :-
    functor(Goal, F, A),
    npl_has_user_clauses(F/A), !,
    CutBarrier = cut_for(F/A),
    gensym(npl_inv_, InvID),
    nb_setval(InvID, not_cut),
    npl_user_clause(Goal, Body),   % head unification happens here, BEFORE catch
    catch(
        npl_solve_goal(Body, CutBarrier),
        npl_cut(CutBarrier),
        nb_setval(InvID, cut)      % side-effect: survives exception binding undo
    ),
    % If cut fired: ! cuts npl_user_clause choice point (! inside -> cuts parent)
    ( nb_getval(InvID, cut) -> ! ; true ).

% --- Fallthrough: delegate to SWI-Prolog ---
%  Handles arithmetic, comparison, type tests, I/O, library predicates,
%  and all npl_* prelude and control predicates (imported via use_module).
npl_solve_goal(Goal, _) :-
    call(Goal).

% ============================================================
% 6. INTERNAL HELPERS
% ============================================================

%% npl_has_user_clauses/1 — true when the interpreter DB has at least
%  one clause for the given functor/arity.
npl_has_user_clauses(F/A) :-
    functor(Template, F, A),
    npl_user_clause(Template, _), !.
