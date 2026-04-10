% tail_recursion.pl — Tail-recursion optimisation rules
%
% These rules assist the Gaussian recursion reducer.

:- module(tail_recursion_opts, []).

% A tail-recursive call followed by true can be simplified.
% (The Gaussian reducer handles the structural transform;
%  these rules handle IR-level cleanup.)

npl_opt_rule(tail_call_true,
    ir_seq(ir_call(G), ir_true),
    ir_call(G)).

npl_opt_rule(tail_seq_cut,
    ir_seq(ir_cut, ir_true),
    ir_cut).
