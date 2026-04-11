#!/usr/bin/env sh
# benchmarks.sh — NeuroProlog Benchmark Suite
#
# Measures performance across five categories:
#
#   1. Interpreted vs neurocode execution
#   2. Recursive vs transformed recursive forms
#   3. Repeated query performance with memoisation
#   4. Subterm-address loop performance
#   5. Self-build performance
#
# Usage:
#   ./tools/benchmarks.sh [--iters N]
#
# Options:
#   --iters N   Number of benchmark iterations per case (default: 100)
#
# Run from the repository root directory.
# Results are printed to stdout.  Exit status 0 = all benchmarks ran.

set -e

SWIPL="${SWIPL:-swipl}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

ITERS=100

while [ $# -gt 0 ]; do
    case "$1" in
        --iters)
            ITERS="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,19p' "$0" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage." >&2
            exit 1
            ;;
    esac
done

echo "=== NeuroProlog Benchmark Suite (iterations: ${ITERS}) ==="
echo ""

# ---------------------------------------------------------------------------
# Helper: run an inline Prolog benchmark and print the result
# ---------------------------------------------------------------------------
run_bench() {
    LABEL="$1"
    GOAL="$2"
    echo "--- ${LABEL} ---"
    "$SWIPL" \
        -g "consult('src/prelude')" \
        -g "consult('src/lexer')" \
        -g "consult('src/parser')" \
        -g "consult('src/semantic_analyser')" \
        -g "consult('src/intermediate_codegen')" \
        -g "consult('src/optimisation_dictionary')" \
        -g "consult('src/memoisation')" \
        -g "consult('src/unfolding')" \
        -g "consult('src/pattern_correlation')" \
        -g "consult('src/gaussian_recursion')" \
        -g "consult('src/subterm_addressing')" \
        -g "consult('src/optimiser')" \
        -g "consult('src/nested_recursion')" \
        -g "consult('src/codegen')" \
        -g "consult('src/control')" \
        -g "consult('src/optimiser_pipeline')" \
        -g "consult('src/wam_model')" \
        -g "consult('src/interpreter')" \
        -g "consult('src/cognitive_markers')" \
        -g "${GOAL}" \
        -t halt
    echo ""
}

# ---------------------------------------------------------------------------
# 1. Interpreted vs neurocode execution
#    Compare wall-clock time running a simple recursive predicate (length/2)
#    N times through the source interpreter and through generated neurocode.
# ---------------------------------------------------------------------------
BENCH1_GOAL="
    Iters = ${ITERS},
    Src = 'mylen_b1([], 0). mylen_b1([_|T], N) :- mylen_b1(T, N1), N is N1 + 1.',
    npl_lex_string(Src, Toks1),
    npl_parse(Toks1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_reset,
    npl_interp_load(AAST1),
    List = [a,b,c,d,e,f,g,h,i,j],
    get_time(T0_interp),
    forall(between(1, Iters, _), npl_interp_query(mylen_b1(List, _), _)),
    get_time(T1_interp),
    Interp_ms is (T1_interp - T0_interp) * 1000,
    npl_lex_string(Src, Toks2),
    npl_parse(Toks2, AST2),
    npl_analyse(AST2, AAST2),
    npl_intermediate(AAST2, IR),
    npl_optimise(IR, OptIR),
    npl_generate(OptIR, NC),
    npl_interp_reset,
    npl_interp_load_clauses(NC),
    get_time(T0_nc),
    forall(between(1, Iters, _), npl_interp_query(mylen_b1(List, _), _)),
    get_time(T1_nc),
    NC_ms is (T1_nc - T0_nc) * 1000,
    format('  Interpreted : ~4f ms total (~4f ms/iter)~n',
           [Interp_ms, Interp_ms / Iters]),
    format('  Neurocode   : ~4f ms total (~4f ms/iter)~n',
           [NC_ms, NC_ms / Iters])
"

run_bench "1. Interpreted vs Neurocode Execution (mylen/2, list of 10)" \
    "${BENCH1_GOAL}"

# ---------------------------------------------------------------------------
# 2. Recursive vs transformed recursive forms
#    Run a plain recursive sum and its Gaussian-transformed counterpart.
# ---------------------------------------------------------------------------
BENCH2_GOAL="
    Iters = ${ITERS},
    SrcPlain = 'mysum_b2([], 0). mysum_b2([H|T], S) :- mysum_b2(T, S1), S is S1 + H.',
    npl_lex_string(SrcPlain, Toks1),
    npl_parse(Toks1, AST1),
    npl_analyse(AST1, AAST1),
    npl_intermediate(AAST1, IR1),
    npl_interp_reset,
    npl_interp_load(AAST1),
    List = [1,2,3,4,5,6,7,8,9,10],
    get_time(T0_plain),
    forall(between(1, Iters, _), npl_interp_query(mysum_b2(List, _), _)),
    get_time(T1_plain),
    Plain_ms is (T1_plain - T0_plain) * 1000,
    npl_pipeline_default_config(Cfg),
    npl_pipeline_run(Cfg, IR1, OptIR1, _Report),
    npl_generate(OptIR1, NC1),
    npl_interp_reset,
    npl_interp_load_clauses(NC1),
    get_time(T0_opt),
    forall(between(1, Iters, _), npl_interp_query(mysum_b2(List, _), _)),
    get_time(T1_opt),
    Opt_ms is (T1_opt - T0_opt) * 1000,
    format('  Plain recursive : ~4f ms total (~4f ms/iter)~n',
           [Plain_ms, Plain_ms / Iters]),
    format('  Transformed     : ~4f ms total (~4f ms/iter)~n',
           [Opt_ms, Opt_ms / Iters])
"

run_bench "2. Recursive vs Transformed Recursive Forms (mysum/2, list of 10)" \
    "${BENCH2_GOAL}"

# ---------------------------------------------------------------------------
# 3. Repeated query performance with memoisation
#    Run the same query repeatedly; subsequent calls should hit the cache.
# ---------------------------------------------------------------------------
BENCH3_GOAL="
    Iters = ${ITERS},
    Src = 'fib_b3(0, 0) :- !. fib_b3(1, 1) :- !. fib_b3(N, F) :- N > 1, N1 is N-1, N2 is N-2, fib_b3(N1,F1), fib_b3(N2,F2), F is F1+F2.',
    npl_lex_string(Src, Toks1),
    npl_parse(Toks1, AST1),
    npl_analyse(AST1, AAST1),
    npl_interp_reset,
    npl_interp_load(AAST1),
    npl_memo_clear_all,
    get_time(T0_cold),
    forall(between(1, Iters, _), npl_interp_query(fib_b3(10, _), _)),
    get_time(T1_cold),
    Cold_ms is (T1_cold - T0_cold) * 1000,
    npl_memo_check(fib_b3(10, _), _F),
    get_time(T0_warm),
    forall(between(1, Iters, _), npl_memo_check(fib_b3(10, _), _)),
    get_time(T1_warm),
    Warm_ms is (T1_warm - T0_warm) * 1000,
    format('  Cold (~w calls) : ~4f ms total (~4f ms/iter)~n',
           [Iters, Cold_ms, Cold_ms / Iters]),
    format('  Warm (cache hits)        : ~4f ms total (~4f ms/iter)~n',
           [Warm_ms, Warm_ms / Iters])
"

run_bench "3. Repeated Query Performance with Memoisation (fib/2, N=10)" \
    "${BENCH3_GOAL}"

# ---------------------------------------------------------------------------
# 4. Subterm-address loop performance
#    Time how long npl_subterm_iter_bounded takes over a moderately-sized term.
# ---------------------------------------------------------------------------
BENCH4_GOAL="
    Iters = ${ITERS},
    Term = f(g(h(a,b),i(c,d)),j(k(e,f(1,2)),l(3,4))),
    get_time(T0),
    forall(between(1, Iters, _),
           (findall(A-ST, npl_subterm_iter_bounded(Term, 10, A, ST), _))),
    get_time(T1),
    Ms is (T1 - T0) * 1000,
    format('  Subterm iteration over nested term : ~4f ms total (~4f ms/iter)~n',
           [Ms, Ms / Iters])
"

run_bench "4. Subterm-Address Loop Performance (depth-10, nested term)" \
    "${BENCH4_GOAL}"

# ---------------------------------------------------------------------------
# 5. Self-build performance
#    Time a full pipeline run over the neuroprolog source file.
# ---------------------------------------------------------------------------
BENCH5_GOAL="
    ( exists_file('src/neuroprolog.pl') ->
        get_time(T0),
        npl_lex('src/neuroprolog.pl', Toks),
        npl_parse(Toks, AST),
        npl_analyse(AST, AAST),
        npl_intermediate(AAST, IR),
        npl_pipeline_default_config(Cfg),
        npl_pipeline_benchmark(Cfg, IR, _Report, TimeMs),
        get_time(T1),
        WallMs is (T1 - T0) * 1000,
        format('  Pipeline benchmark time (reported) : ~4f ms~n', [TimeMs]),
        format('  Total wall-clock (lex+parse+IR+pipeline) : ~4f ms~n', [WallMs])
    ;
        write('  NOTE: src/neuroprolog.pl not found — skipping self-build benchmark'), nl
    )
"

run_bench "5. Self-Build Performance (full pipeline on src/neuroprolog.pl)" \
    "${BENCH5_GOAL}"

echo "=== Benchmark suite complete. ==="
