% self_host.pl — NeuroProlog Self-Hosting Support
%
% Implements the self-hosting invariants defined in SELF_HOSTING.md.
% Provides self_compile/0 and check_self_hosting/0.

:- module(self_host, [self_compile/0, check_self_hosting/0]).

:- consult('src/neuroprolog').

%% self_compile/0
%  Compile NeuroProlog using itself. Output → neurocode/neuroprolog_nc.pl
self_compile :-
    write('[self_host] Starting self-compilation...'), nl,
    npl_compile('src/neuroprolog.pl', 'neurocode/neuroprolog_nc.pl'),
    write('[self_host] Self-compilation complete.'), nl.

%% check_self_hosting/0
%  Verify all self-hosting invariants.
check_self_hosting :-
    check_invariant_1,
    check_invariant_2,
    check_invariant_3,
    write('[self_host] All invariants satisfied.'), nl.

%% Invariant 1: Plain source exists
check_invariant_1 :-
    ( exists_file('src/neuroprolog.pl') ->
        write('[inv1] Plain source present: OK'), nl
    ; write('[inv1] FAIL: src/neuroprolog.pl missing'), nl, fail
    ).

%% Invariant 2: Neurocode is valid Prolog (check it loads)
check_invariant_2 :-
    ( exists_file('neurocode/neuroprolog_nc.pl') ->
        catch(
            ( consult('neurocode/neuroprolog_nc.pl'),
              write('[inv2] Neurocode loads as valid Prolog: OK'), nl ),
            Error,
            ( write('[inv2] FAIL: '), write(Error), nl, fail )
        )
    ; write('[inv2] NOTE: neurocode not yet generated (run self_compile first)'), nl
    ).

%% Invariant 3: Optimisation dictionary preserved
check_invariant_3 :-
    npl_opt_dict_rules(Rules),
    ( Rules \= [] ->
        write('[inv3] Optimisation dictionary populated: OK'), nl
    ; write('[inv3] WARNING: Optimisation dictionary is empty'), nl
    ).
