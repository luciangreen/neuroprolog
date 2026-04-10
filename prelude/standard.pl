% standard.pl — NeuroProlog Standard Prelude Library
%
% This file is the canonical prelude, loaded by default.
% It re-exports the prelude module predicates for direct use.

:- consult('../src/prelude').

% Additional standard definitions

%% between/3 — already in control, re-exported here
:- consult('../src/control').

%% true/0, fail/0, nl/0, write/1 — provided by the host Prolog system.
