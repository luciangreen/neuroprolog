% wam_model.pl — NeuroProlog WAM Model (Stage 6)
%
% Logical Warren Abstract Machine (WAM) model for NeuroProlog.
%
% This module defines a WAM-inspired execution model in pure Prolog.
% It is a *logical* model — it uses Prolog data structures to represent
% WAM concepts rather than a low-level byte emulator.  This makes it
% suitable for both the interpreter and the compiler pipeline.
%
% == WAM Concepts vs. This Logical Model ==
%
% | Standard WAM Concept     | Logical Model Representation                     |
% |--------------------------|--------------------------------------------------|
% | Heap (global stack)      | wam_heap: list of addr-cell(Tag,Value) pairs     |
% | Environment stack (E)    | env_stack field: list of env/3 frames            |
% | Choice point stack (B)   | choice_stack field: list of choice/7 terms       |
% | Trail                    | trail field: list of heap addresses to unbind    |
% | Argument registers (A1…) | regs field: list of terms indexed from 1         |
% | Program pointer (P)      | cont field: remaining instruction list           |
% | Continuation (CP)        | saved inside env/3 and choice/7 frames           |
% | Unification (unify)      | wam_unify/4 with explicit binding store          |
% | Backtracking             | wam_backtrack/3 restores trail + heap + regs     |
%
% == Execution State ==
%
% The full execution state is represented as:
%
%   wam_state(Regs, Heap, HTop, EnvStack, ChoiceStack, Trail, Cont, Bindings)
%
%   Regs        — argument registers: list of terms [A1, A2, ...]
%   Heap        — heap cells: list of heap_addr-heap_cell pairs
%   HTop        — heap top pointer (integer, next free address)
%   EnvStack    — environment (activation) stack: list of env/3 frames
%   ChoiceStack — choice point stack: list of choice/7 terms
%   Trail       — trail: list of heap addresses bound since last choice point
%   Cont        — continuation: remaining WAM instructions to execute
%   Bindings    — variable binding store: assoc addr→value
%
% == Environments (call frames) ==
%
%   env(CE, CP, Vars)
%     CE   — saved parent environment (previous EnvStack)
%     CP   — saved continuation (instruction list to resume on proceed)
%     Vars — local variable bindings for this activation record
%
% == Choice Points ==
%
%   choice(B, E, CP, TrailTop, HeapTop, Alts, SavedRegs)
%     B         — saved previous choice point stack
%     E         — saved environment stack at time of creation
%     CP        — saved continuation at time of creation
%     TrailTop  — trail length at time of creation (for unwinding)
%     HeapTop   — heap top at time of creation (for heap trimming)
%     Alts      — remaining clause alternatives (list of instruction lists)
%     SavedRegs — saved argument registers
%
% == Heap Cells ==
%
%   heap_cell(var, unbound)      — unbound logic variable
%   heap_cell(ref, Addr)         — bound reference to another cell
%   heap_cell(atom, Atom)        — atomic constant
%   heap_cell(int, N)            — integer
%   heap_cell(float, F)          — float
%   heap_cell(str, f(Name,Args)) — compound term f(arg1,…,argn)
%
% == Trail ==
%
% When a variable (heap_cell(var,unbound)) is bound during unification,
% its address is pushed onto the trail IF the binding is conditional
% (i.e. it was created before the current choice point).  On backtracking
% wam_unwind_trail/3 resets those cells back to heap_cell(var,unbound).
%
% == Usage Example ==
%
%   wam_init_state(S0),
%   wam_alloc_var(S0, A1, S1),          % allocate a fresh variable
%   wam_alloc_atom(S1, hello, A2, S2),  % allocate atom 'hello'
%   wam_bind(A1, A2, S2, S3),           % bind var at A1 to atom at A2
%   wam_deref(A1, S3, Cell).            % dereference: Cell = heap_cell(atom,hello)

:- module(wam_model, [
    % State management
    wam_init_state/1,
    wam_get_regs/2,
    wam_set_regs/3,
    wam_get_reg/3,
    wam_set_reg/4,
    wam_get_cont/2,
    % Heap operations
    wam_alloc_var/3,
    wam_alloc_atom/4,
    wam_alloc_int/4,
    wam_alloc_str/4,
    wam_deref/3,
    wam_heap_get/3,
    wam_heap_set/4,
    % Trail and binding
    wam_bind/4,
    wam_do_bind/4,
    wam_trail_bind/4,
    wam_unwind_trail/3,
    % Environments (call frames)
    wam_push_env/3,
    wam_pop_env/3,
    % Choice points
    wam_push_choice/4,
    wam_backtrack/3,
    % Unification
    wam_unify/4,
    % Instruction execution
    wam_execute/3,
    wam_instruction/4,
    % Compilation
    wam_compile_clause/2,
    % Legacy compatibility
    wam_execute/2,
    wam_instruction/3
]).

:- use_module(library(lists)).
:- use_module(library(assoc)).

% ============================================================
% 1. STATE INITIALISATION
% ============================================================

%% wam_init_state(-State)
%  Create an empty initial WAM execution state.
wam_init_state(wam_state([], Heap, 0, [], [], [], [], Bindings)) :-
    empty_assoc(Heap),
    empty_assoc(Bindings).

% ============================================================
% 2. ARGUMENT REGISTERS
% ============================================================

%% wam_get_regs(+State, -Regs)
%  Retrieve the argument register list from State.
wam_get_regs(wam_state(Regs,_,_,_,_,_,_,_), Regs).

%% wam_set_regs(+State, +Regs, -State1)
%  Replace the argument register list in State.
wam_set_regs(wam_state(_,H,HT,E,C,TR,Cont,B),
             Regs,
             wam_state(Regs,H,HT,E,C,TR,Cont,B)).

%% wam_get_reg(+State, +N, -Value)
%  Read argument register N (1-based) from State.
wam_get_reg(State, N, Value) :-
    wam_get_regs(State, Regs),
    nth1(N, Regs, Value).

%% wam_set_reg(+State, +N, +Value, -State1)
%  Write Value into argument register N (1-based).
wam_set_reg(State, N, Value, State1) :-
    wam_get_regs(State, Regs),
    wam_set_reg_list(Regs, N, Value, Regs1),
    wam_set_regs(State, Regs1, State1).

wam_set_reg_list([], N, V, Padded) :-
    length(Padded, N),
    nth1(N, Padded, V).
wam_set_reg_list([_|T], 1, V, [V|T]) :- !.
wam_set_reg_list([H|T], N, V, [H|T1]) :-
    N > 1,
    N1 is N - 1,
    wam_set_reg_list(T, N1, V, T1).

% ============================================================
% 3. HEAP OPERATIONS
% ============================================================

%% wam_heap_get(+State, +Addr, -Cell)
%  Read the heap cell at address Addr.
wam_heap_get(wam_state(_,Heap,_,_,_,_,_,_), Addr, Cell) :-
    get_assoc(Addr, Heap, Cell).

%% wam_heap_set(+State, +Addr, +Cell, -State1)
%  Write Cell to heap address Addr.
wam_heap_set(wam_state(R,Heap,HT,E,C,TR,Cont,B), Addr, Cell,
             wam_state(R,Heap1,HT,E,C,TR,Cont,B)) :-
    put_assoc(Addr, Heap, Cell, Heap1).

%% wam_alloc_var(+State, -Addr, -State1)
%  Allocate a fresh unbound variable cell on the heap.
%  Returns its address Addr.
wam_alloc_var(wam_state(R,Heap,HTop,E,C,TR,Cont,B),
              HTop,
              wam_state(R,Heap1,HTop1,E,C,TR,Cont,B)) :-
    put_assoc(HTop, Heap, heap_cell(var, unbound), Heap1),
    HTop1 is HTop + 1.

%% wam_alloc_atom(+State, +Atom, -Addr, -State1)
%  Allocate an atom constant cell on the heap.
wam_alloc_atom(wam_state(R,Heap,HTop,E,C,TR,Cont,B),
               Atom, HTop,
               wam_state(R,Heap1,HTop1,E,C,TR,Cont,B)) :-
    put_assoc(HTop, Heap, heap_cell(atom, Atom), Heap1),
    HTop1 is HTop + 1.

%% wam_alloc_int(+State, +N, -Addr, -State1)
%  Allocate an integer cell on the heap.
wam_alloc_int(wam_state(R,Heap,HTop,E,C,TR,Cont,B),
              N, HTop,
              wam_state(R,Heap1,HTop1,E,C,TR,Cont,B)) :-
    put_assoc(HTop, Heap, heap_cell(int, N), Heap1),
    HTop1 is HTop + 1.

%% wam_alloc_str(+State, +Term, -Addr, -State1)
%  Allocate a compound term cell on the heap.
%  Term should be f(Name, ArgList) or an atom for arity-0 structures.
wam_alloc_str(wam_state(R,Heap,HTop,E,C,TR,Cont,B),
              Term, HTop,
              wam_state(R,Heap1,HTop1,E,C,TR,Cont,B)) :-
    put_assoc(HTop, Heap, heap_cell(str, Term), Heap1),
    HTop1 is HTop + 1.

%% wam_deref(+Addr, +State, -Cell)
%  Dereference a heap address, following reference chains.
%  Returns the final heap_cell/2 term (either var or a value).
wam_deref(Addr, State, Cell) :-
    wam_heap_get(State, Addr, RawCell),
    ( RawCell = heap_cell(ref, Target)
    -> wam_deref(Target, State, Cell)
    ;  Cell = RawCell
    ).

% ============================================================
% 4. TRAIL AND VARIABLE BINDING
% ============================================================

%% wam_trail_state(+State, -TrailLen, -ChoiceStack)
%  Helper: extract trail length and choice stack from State.
wam_trail_state(wam_state(_,_,_,_,ChoiceStack,Trail,_,_), TrailLen, ChoiceStack) :-
    length(Trail, TrailLen).

%% wam_bind(+Addr, +TargetAddr, +State, -State1)
%  Bind the variable at Addr to point to TargetAddr (unconditional).
%  This records on the trail only if the variable is older than the
%  current choice point (conditional binding).
wam_bind(Addr, Target, State, State1) :-
    ( wam_is_conditional_bind(Addr, State)
    -> wam_trail_bind(Addr, Target, State, State1)
    ;  wam_do_bind(Addr, Target, State, State1)
    ).

%% wam_is_conditional_bind(+Addr, +State)
%  True if binding Addr requires trail recording (variable is older
%  than the current choice point's heap top).
%  Fails if there are no choice points (nothing to backtrack to).
wam_is_conditional_bind(Addr, wam_state(_,_,_,_,[choice(_,_,_,_,BHTop,_,_)|_],_,_,_)) :-
    Addr < BHTop.

%% wam_do_bind(+Addr, +Target, +State, -State1)
%  Perform the actual binding without trail recording.
wam_do_bind(Addr, Target, State, State1) :-
    wam_heap_set(State, Addr, heap_cell(ref, Target), State1).

%% wam_trail_bind(+Addr, +Target, +State, -State1)
%  Bind Addr → Target and push Addr onto the trail.
wam_trail_bind(Addr, Target,
               wam_state(R,H,HT,E,CP,Trail,Cont,B),
               wam_state(R,H1,HT,E,CP,[Addr|Trail],Cont,B)) :-
    put_assoc(Addr, H, heap_cell(ref, Target), H1).

%% wam_unwind_trail(+SavedTrailLen, +State, -State1)
%  Unwind the trail back to SavedTrailLen, resetting all bindings
%  made since that point (backtrack variable bindings).
wam_unwind_trail(SavedLen,
                 wam_state(R,H,HT,E,CP,Trail,Cont,B),
                 wam_state(R,H1,HT,E,CP,Trail1,Cont,B)) :-
    length(Trail, Len),
    ToUndo is Len - SavedLen,
    wam_unwind_n(ToUndo, Trail, H, H1, Trail1).

wam_unwind_n(0, Trail, H, H, Trail) :- !.
wam_unwind_n(N, [Addr|Trail], H0, H, Remaining) :-
    N > 0,
    put_assoc(Addr, H0, heap_cell(var, unbound), H1),
    N1 is N - 1,
    wam_unwind_n(N1, Trail, H1, H, Remaining).

% ============================================================
% 5. ENVIRONMENTS (CALL FRAMES)
% ============================================================
%
% An environment frame records the activation record for a clause body.
% It is pushed on call and popped on proceed (deterministic return).
%
%   env(SavedEnvStack, SavedCont, LocalVars)
%     SavedEnvStack — the caller's environment stack (for return)
%     SavedCont     — the continuation instruction list to resume after proceed
%     LocalVars     — assoc of named local variable bindings (Name→HeapAddr)

%% wam_push_env(+State, +SavedCont, -State1)
%  Push a new environment frame onto the environment stack.
wam_push_env(wam_state(R,H,HT,EnvStack,CP,TR,Cont,B),
             SavedCont,
             wam_state(R,H,HT,EnvStack1,CP,TR,Cont,B)) :-
    empty_assoc(LocalVars),
    EnvStack1 = [env(EnvStack, SavedCont, LocalVars)|EnvStack].

%% wam_pop_env(+State, -RestoredCont, -State1)
%  Pop the topmost environment frame and restore its continuation.
wam_pop_env(wam_state(R,H,HT,[env(SavedEnvStack,SavedCont,_)|_],CP,TR,_,B),
            SavedCont,
            wam_state(R,H,HT,SavedEnvStack,CP,TR,SavedCont,B)).

% ============================================================
% 6. CHOICE POINTS
% ============================================================
%
% A choice point is created when a predicate has multiple clauses.
% It saves enough state to allow restoration on backtracking.
%
%   choice(SavedChoiceStack, SavedEnvStack, SavedCont,
%          SavedTrailLen, SavedHeapTop, Alternatives, SavedRegs)

%% wam_push_choice(+State, +Alternatives, +SavedCont, -State1)
%  Push a new choice point onto the choice point stack.
wam_push_choice(wam_state(R,H,HT,EnvStack,ChoiceStack,TR,Cont,B),
                Alternatives, SavedCont,
                wam_state(R,H,HT,EnvStack,ChoiceStack1,TR,Cont,B)) :-
    length(TR, TrailLen),
    ChoiceStack1 = [choice(ChoiceStack, EnvStack, SavedCont,
                           TrailLen, HT, Alternatives, R)
                   | ChoiceStack].

%% wam_backtrack(+State, -NextAlts, -State1)
%  Restore state from the most recent choice point.
%  On success: State1 is the restored state with the next alternative
%  loaded into Cont, and NextAlts is the remaining alternatives list.
%  Fails if there are no choice points (no more solutions).
wam_backtrack(wam_state(_,H,_,_,
                        [choice(PrevCP, SavedEnv, SavedCont,
                                TrailLen, SavedHTop, [NextAlt|RestAlts], SavedRegs)
                        |_],
                        TR,_,_),
              RestAlts,
              RestoredState) :-
    % Unwind trail to saved trail length
    length(TR, CurTrailLen),
    ToUndo is CurTrailLen - TrailLen,
    wam_unwind_n(ToUndo, TR, H, H1, TR1),
    % Trim heap back to saved heap top
    wam_trim_heap(H1, SavedHTop, H2),
    % Restore the choice point stack (minus the exhausted/replaced entry)
    ( RestAlts = []
    -> NewCP = PrevCP           % last alternative: pop choice point
    ;  NewCP = [choice(PrevCP, SavedEnv, SavedCont,
                       TrailLen, SavedHTop, RestAlts, SavedRegs)
               | PrevCP]
    ),
    empty_assoc(EmptyB),
    RestoredState = wam_state(SavedRegs, H2, SavedHTop,
                               SavedEnv, NewCP, TR1, NextAlt, EmptyB).

%% wam_trim_heap(+Heap, +HTop, -TrimmedHeap)
%  Remove all heap cells at addresses >= HTop.
wam_trim_heap(Heap, HTop, Trimmed) :-
    assoc_to_keys(Heap, Keys),
    include([K]>>(K < HTop), Keys, KeepKeys),
    list_to_assoc_subset(KeepKeys, Heap, Trimmed).

%% list_to_assoc_subset(+Keys, +Src, -Assoc)
%  Build a new association from the key-value pairs of Src whose keys
%  appear in Keys.  Used by wam_trim_heap/3 to reconstruct the heap
%  after backtracking discards cells added after a choice point.
list_to_assoc_subset(Keys, Src, Assoc) :-
    maplist([K, K-V]>>(get_assoc(K, Src, V)), Keys, Pairs),
    list_to_assoc(Pairs, Assoc).

% ============================================================
% 7. UNIFICATION
% ============================================================
%
% wam_unify/4 implements Robinson unification over heap addresses.
% Variables are represented as heap_cell(var,unbound) cells.
% Binding uses the trail when the variable may need to be unbound
% on backtracking (conditional binding).

%% wam_unify(+Addr1, +Addr2, +State, -State1)
%  Unify the terms rooted at Addr1 and Addr2 in the heap.
%  Fails if the terms are not unifiable.
wam_unify(A, B, S, S1) :-
    wam_deref(A, S, CellA),
    wam_deref(B, S, CellB),
    wam_unify_cells(CellA, A, CellB, B, S, S1).

% Both unbound variables: bind A → B
wam_unify_cells(heap_cell(var, unbound), AddrA,
                heap_cell(var, unbound), AddrB,
                S, S1) :- !,
    ( AddrA =:= AddrB
    -> S1 = S          % same variable, already unified
    ;  wam_bind(AddrA, AddrB, S, S1)
    ).

% A is unbound: bind A → B
wam_unify_cells(heap_cell(var, unbound), AddrA,
                _, AddrB,
                S, S1) :- !,
    wam_bind(AddrA, AddrB, S, S1).

% B is unbound: bind B → A
wam_unify_cells(_, AddrA,
                heap_cell(var, unbound), AddrB,
                S, S1) :- !,
    wam_bind(AddrB, AddrA, S, S1).

% Both atoms: must be identical
wam_unify_cells(heap_cell(atom, X), _,
                heap_cell(atom, X), _,
                S, S) :- !.

% Both integers: must be identical
wam_unify_cells(heap_cell(int, N), _,
                heap_cell(int, N), _,
                S, S) :- !.

% Both floats: must be identical
wam_unify_cells(heap_cell(float, F), _,
                heap_cell(float, F), _,
                S, S) :- !.

% Both structures: functor/arity must match, then unify args pairwise
wam_unify_cells(heap_cell(str, f(Name, ArgsA)), _,
                heap_cell(str, f(Name, ArgsB)), _,
                S, S1) :- !,
    length(ArgsA, Arity),
    length(ArgsB, Arity),
    wam_unify_args(ArgsA, ArgsB, S, S1).

% All other combinations fail (incompatible types or mismatched atoms/funcs)
wam_unify_cells(_, _, _, _, _, _) :- fail.

%% wam_unify_args(+AddrListA, +AddrListB, +State, -State1)
%  Unify corresponding argument address pairs.
wam_unify_args([], [], S, S).
wam_unify_args([A|As], [B|Bs], S0, S) :-
    wam_unify(A, B, S0, S1),
    wam_unify_args(As, Bs, S1, S).

% ============================================================
% 8. INSTRUCTION SET
% ============================================================
%
% WAM instructions are represented as Prolog terms.  The full state
% is threaded through instruction execution.
%
% Instruction categories (following standard WAM):
%
%   Get instructions  — match argument registers against head arguments
%   Put instructions  — load argument registers for a call
%   Unify instructions— used inside structure building/matching
%   Control           — allocate/deallocate/call/proceed/execute/cut
%   Indexing          — switch_on_term/switch_on_atom/switch_on_structure
%
% Instruction summary:
%
%   get_variable(Reg, VarAddr)   — unify register Reg with heap var at VarAddr
%   get_constant(Reg, Atom)      — unify register Reg with atom Atom
%   get_structure(Reg, F/A)      — begin structure matching in register Reg
%   get_list(Reg)                — begin list matching in register Reg
%   get_nil(Reg)                 — match register Reg against []
%   put_variable(Reg, VarAddr)   — allocate var, store addr in Reg and VarAddr
%   put_constant(Reg, Atom)      — store atom in register Reg
%   put_structure(Reg, F/A)      — begin structure building for register Reg
%   put_list(Reg)                — begin list building for register Reg
%   put_nil(Reg)                 — store [] in register Reg
%   unify_variable(VarAddr)      — unify next subarg with var at VarAddr
%   unify_constant(Atom)         — unify next subarg with atom
%   call(F/A, N)                 — call predicate F/A, N = env size
%   execute(F/A)                 — tail-call predicate F/A
%   proceed                      — deterministic return (pop environment)
%   allocate(N)                  — push environment with N slots
%   deallocate                   — pop environment
%   enter(F/A)                   — clause entry point label (no-op)
%   try_me_else(Alt)             — push choice point with alternative Alt
%   retry_me_else(Alt)           — update top choice point with alternative Alt
%   trust_me                     — pop/commit the top choice point
%   neck_cut                     — cut above current choice point
%   cut                          — cut above current choice point (with env)

%% wam_instruction/4 — execute one WAM instruction, threading state.
%  wam_instruction(+Instr, +State, -State1, -Cont)
%  Cont is the remaining instruction list after this instruction.
%  (Cont is taken from State.cont and may be modified by call/proceed.)

% --- Entry label (no-op) ---
wam_instruction(enter(_FA), S, S, Cont) :-
    wam_get_cont(S, Cont).

% --- Environment management ---
% NOTE: In this logical model `allocate` saves the continuation
% (remaining instructions after allocate itself) into the new
% environment frame.  When `proceed` fires it restores that
% continuation, which is the sequence the clause body must complete
% before returning.  This differs from the byte-level WAM where
% `allocate` saves the caller's CP register; here the caller's
% continuation is threaded via the instruction list itself.
wam_instruction(allocate(_N), S, S1, Cont) :-
    wam_get_cont(S, Cont),
    wam_push_env(S, Cont, S1).

wam_instruction(deallocate, S, S1, Cont) :-
    wam_pop_env(S, Cont, S1).

% --- Proceed: return to caller ---
wam_instruction(proceed, S, S, []) :-
    wam_get_cont(S, []),
    S = wam_state(_, _, _, [], _, _, _, _), !.
wam_instruction(proceed, S, S1, Cont) :-
    wam_pop_env(S, Cont, S1).

% --- Call and execute ---
wam_instruction(call(Goal, _N), S, S1, []) :-
    wam_get_cont(S, RestCont),
    wam_push_env(S, RestCont, SE),
    wam_set_cont(SE, [call_builtin(Goal)], S1).

wam_instruction(execute(Goal), S, S1, []) :-
    wam_set_cont(S, [call_builtin(Goal)], S1).

% Dispatch a built-in/Prolog goal
wam_instruction(call_builtin(Goal), S, S, []) :-
    call(Goal).

% --- Choice point management ---
wam_instruction(try_me_else(Alt), S, S1, Cont) :-
    wam_get_cont(S, Cont),
    wam_push_choice(S, [Alt], Cont, S1).

wam_instruction(retry_me_else(Alt), S, S1, Cont) :-
    wam_get_cont(S, Cont),
    wam_update_choice_alt(S, Alt, S1).

wam_instruction(trust_me, S, S1, Cont) :-
    wam_get_cont(S, Cont),
    wam_pop_choice(S, S1).

% --- Cut ---
wam_instruction(cut, S, S1, Cont) :-
    wam_get_cont(S, Cont),
    wam_cut(S, S1).

wam_instruction(neck_cut, S, S1, Cont) :-
    wam_get_cont(S, Cont),
    wam_cut(S, S1).

% --- Get instructions (head argument matching) ---
wam_instruction(get_variable(Reg, NewVarAddr), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_get_reg(S, Reg, RegVal),
    wam_alloc_var(S, NewVarAddr, Stmp),
    wam_unify(NewVarAddr, RegVal, Stmp, S1).

wam_instruction(get_constant(Reg, Atom), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_get_reg(S, Reg, RegVal),
    wam_alloc_atom(S, Atom, AtomAddr, Stmp),
    wam_unify(RegVal, AtomAddr, Stmp, S1).

wam_instruction(get_structure(Reg, F/A), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_get_reg(S, Reg, RegVal),
    length(ArgAddrs, A),
    wam_alloc_vars(S, ArgAddrs, Stmp),
    wam_alloc_str(Stmp, f(F, ArgAddrs), StrAddr, Stmp2),
    wam_unify(RegVal, StrAddr, Stmp2, S1).

wam_instruction(get_nil(Reg), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_get_reg(S, Reg, RegVal),
    wam_alloc_atom(S, '[]', NilAddr, Stmp),
    wam_unify(RegVal, NilAddr, Stmp, S1).

% --- Put instructions (argument register loading for calls) ---
wam_instruction(put_variable(Reg, NewVarAddr), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_alloc_var(S, NewVarAddr, S1_tmp),
    wam_set_reg(S1_tmp, Reg, NewVarAddr, S1).

wam_instruction(put_constant(Reg, Atom), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_alloc_atom(S, Atom, Addr, Stmp),
    wam_set_reg(Stmp, Reg, Addr, S1).

wam_instruction(put_structure(Reg, F/A), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    length(ArgAddrs, A),
    wam_alloc_vars(S, ArgAddrs, Stmp),
    wam_alloc_str(Stmp, f(F, ArgAddrs), StrAddr, Stmp2),
    wam_set_reg(Stmp2, Reg, StrAddr, S1).

wam_instruction(put_nil(Reg), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_alloc_atom(S, '[]', Addr, Stmp),
    wam_set_reg(Stmp, Reg, Addr, S1).

% --- Unify instructions (subterm read/write mode) ---
wam_instruction(unify_variable(VarAddr), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_alloc_var(S, VarAddr, S1).

wam_instruction(unify_constant(Atom), S, S1, Cont) :-
    wam_get_cont(S, [_|Cont]),
    wam_alloc_atom(S, Atom, _, S1).

% Legacy arity-3 form (keep existing interface working)
wam_instruction(enter(_FA), S, S) :- !.
wam_instruction(proceed, S, S) :- !.
wam_instruction(get_constant(C), S, S) :- ground(C).
wam_instruction(get_variable(_), S, S).
wam_instruction(get_structure(_FA), S, S).
wam_instruction(call(Goal), S, S) :- call(Goal).
wam_instruction(put_constant(_C, _Reg), S, S).
wam_instruction(put_variable(_V, _Reg), S, S).
wam_instruction(unify_variable(_V), S, S).
wam_instruction(unify_constant(C), S, S) :- ground(C).

% ============================================================
% 9. STATE ACCESSOR HELPERS
% ============================================================

wam_get_cont(wam_state(_,_,_,_,_,_,Cont,_), Cont).

wam_set_cont(wam_state(R,H,HT,E,CP,TR,_,B), Cont,
             wam_state(R,H,HT,E,CP,TR,Cont,B)).

wam_pop_choice(wam_state(R,H,HT,E,[_|CP],TR,Cont,B),
               wam_state(R,H,HT,E,CP,TR,Cont,B)).

wam_update_choice_alt(wam_state(R,H,HT,E,
                                [choice(PrevCP,SE,SC,TL,SH,_,SR)|CP],
                                TR,Cont,B),
                      NewAlt,
                      wam_state(R,H,HT,E,
                                [choice(PrevCP,SE,SC,TL,SH,[NewAlt],SR)|CP],
                                TR,Cont,B)).

wam_cut(wam_state(R,H,HT,E,[_|CP],TR,Cont,B),
        wam_state(R,H,HT,E,CP,TR,Cont,B)).
wam_cut(S, S).   % no choice points: cut is a no-op

% Helper: allocate N fresh variables on the heap, return list of addresses.
wam_alloc_vars(S, [], S).
wam_alloc_vars(S0, [Addr|Addrs], S) :-
    wam_alloc_var(S0, Addr, S1),
    wam_alloc_vars(S1, Addrs, S).

% ============================================================
% 10. EXECUTION ENGINE
% ============================================================

%% wam_execute/3 — execute a WAM instruction list against a state.
%  wam_execute(+Instructions, +State, -FinalState)
wam_execute([], S, S).
wam_execute([I|Is], S0, S) :-
    wam_set_cont(S0, Is, S1),
    wam_instruction(I, S1, S2, Cont),
    wam_execute(Cont, S2, S).

%% wam_execute/2 — legacy: execute instructions, ignoring state details.
%  wam_execute(+Instructions, +State)
wam_execute([], _).
wam_execute([I|Is], State) :-
    wam_instruction(I, State, State1),
    wam_execute(Is, State1).

% ============================================================
% 11. CLAUSE COMPILATION
% ============================================================

%% wam_compile_clause/2
%  Compile a Prolog clause to WAM instructions.
%  wam_compile_clause(+Clause, -Instructions)
%
%  Fact with no body: single get_constant for the functor.
wam_compile_clause(Head, [get_constant(F/A)]) :-
    \+ compound(Head), !,
    functor(Head, F, A).
wam_compile_clause(Head, [get_constant(F/A)]) :-
    compound(Head),
    Head \= (_:-_), !,
    functor(Head, F, A).
%  Rule: allocate + get args + body + proceed
wam_compile_clause((Head :- Body), Instructions) :-
    functor(Head, F, A),
    Head =.. [_|Args],
    maplist(wam_get_arg, Args, GetArgs),
    wam_compile_body(Body, BodyInstr),
    append([enter(F/A)|GetArgs], [proceed|BodyInstr], Instructions).

wam_get_arg(Arg, get_variable(Arg)) :- var(Arg), !.
wam_get_arg(Arg, get_constant(Arg)) :- atomic(Arg), !.
wam_get_arg(Arg, get_structure(F/A)) :- compound(Arg), functor(Arg, F, A).

wam_compile_body(true, []) :- !.
wam_compile_body(','(A, B), Instr) :- !,
    wam_compile_body(A, IA),
    wam_compile_body(B, IB),
    append(IA, IB, Instr).
wam_compile_body(Goal, [call(Goal)]) :- callable(Goal).
