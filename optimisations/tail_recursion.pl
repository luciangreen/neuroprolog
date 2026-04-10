% tail_recursion.pl — Tail-recursion optimisation rules
%
% These rules assist the Gaussian recursion reducer.
%
% To register these rules with the optimisation dictionary, load this file
% and call npl_opt_dict_register_file/0, or consult this file after
% src/optimisation_dictionary.pl has been loaded. The npl_opt_rule/3 facts
% defined here are picked up automatically by npl_opt_dict_rules/1 via
% findall, since they share the same predicate name as the built-in rules.
%
% Example:
%   :- consult('src/optimisation_dictionary').
%   :- consult('optimisations/tail_recursion.pl').

:- use_module('src/optimisation_dictionary').

% A tail-recursive call followed by true can be simplified.
% (The Gaussian reducer handles the structural transform;
%  these rules handle IR-level cleanup.)

npl_opt_rule(tail_call_true,
    ir_seq(ir_call(G), ir_true),
    ir_call(G)).

npl_opt_rule(tail_seq_cut,
    ir_seq(ir_cut, ir_true),
    ir_cut).
