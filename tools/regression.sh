#!/usr/bin/env sh
# regression.sh — NeuroProlog Regression Suite
#
# Runs all test categories required by Stage 19 and reports a
# consolidated pass/fail summary.
#
# Test categories covered:
#   - Full unit test suite      (tests/run_tests.pl)
#   - Equivalence test suite    (tests/equivalence_tests.pl)
#   - Self-hosting invariants   (src/self_host.pl)
#   - Optimisation dict reload  (via equivalence_tests.pl)
#   - Rebuild safe-config       (via equivalence_tests.pl)
#
# Usage:
#   ./tools/regression.sh [--bench] [--bench-iters N]
#
# Options:
#   --bench          Also run the benchmark suite after the tests
#   --bench-iters N  Iterations per benchmark case (default: 50)
#
# Run from the repository root directory.
# Exits with status 0 if all test categories pass, 1 otherwise.

set -e

SWIPL="${SWIPL:-swipl}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

RUN_BENCH=0
BENCH_ITERS=50

while [ $# -gt 0 ]; do
    case "$1" in
        --bench)
            RUN_BENCH=1
            shift
            ;;
        --bench-iters)
            BENCH_ITERS="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,23p' "$0" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage." >&2
            exit 1
            ;;
    esac
done

PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Helper: run a check, update pass/fail counters
# ---------------------------------------------------------------------------
run_check() {
    LABEL="$1"
    shift
    echo ""
    echo "====== ${LABEL} ======"
    if "$@"; then
        echo "[PASS] ${LABEL}"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] ${LABEL}"
        FAIL=$((FAIL + 1))
    fi
}

# ---------------------------------------------------------------------------
# 1. Full unit test suite
#    Covers: lexer, parser, semantic, WAM/execution, control, recursion,
#    Gaussian, memoisation, nested recursion elimination, neurocode
#    generation, and self-hosting tests.
# ---------------------------------------------------------------------------
run_check "Unit test suite (tests/run_tests.pl)" \
    "$SWIPL" \
        -g "consult('tests/run_tests')" \
        -g "run_all_tests" \
        -t halt

# ---------------------------------------------------------------------------
# 2. Equivalence test suite
#    Covers: rebuild equivalence, optimisation dictionary reload,
#    cognitive marker preservation, end-to-end compilation equivalence.
# ---------------------------------------------------------------------------
run_check "Equivalence tests (tests/equivalence_tests.pl)" \
    "$SWIPL" \
        -g "consult('tests/equivalence_tests')" \
        -g "run_equivalence_tests" \
        -t halt

# ---------------------------------------------------------------------------
# 3. Self-hosting invariant checks
#    Covers: source file present, neurocode loads, opt dict preserved,
#    cognitive markers preserved, learned transforms preserved.
# ---------------------------------------------------------------------------
run_check "Self-hosting invariants (src/self_host.pl)" \
    "$SWIPL" \
        -g "consult('src/self_host')" \
        -g "check_self_hosting" \
        -t halt

# ---------------------------------------------------------------------------
# 4. Benchmark suite (optional — only if --bench is given)
# ---------------------------------------------------------------------------
if [ "$RUN_BENCH" -eq 1 ]; then
    echo ""
    echo "====== Benchmark suite ======"
    # Benchmarks are informational; non-zero exit does not count as a
    # test failure, but we still surface the output.
    if "${SCRIPT_DIR}/benchmarks.sh" --iters "${BENCH_ITERS}"; then
        echo "[INFO] Benchmarks completed."
    else
        echo "[WARN] Benchmarks encountered an error (see output above)."
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
TOTAL=$((PASS + FAIL))
echo "Regression suite: ${PASS}/${TOTAL} category checks passed."
if [ "$FAIL" -gt 0 ]; then
    echo "FAIL: ${FAIL} category check(s) failed."
    exit 1
else
    echo "All regression checks passed."
fi
