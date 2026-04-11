#!/usr/bin/env sh
# self_check.sh — NeuroProlog Self-Check Script
#
# Verify that NeuroProlog satisfies its self-hosting invariants and
# that source and compiled forms are behaviourally equivalent.
#
# Checks performed:
#   1. self-hosting invariants (src/self_host.pl)
#   2. equivalence test suite   (tests/equivalence_tests.pl)
#   3. full test suite          (tests/run_tests.pl)  [optional, --full]
#
# Usage:
#   ./tools/self_check.sh [--full]
#
# Options:
#   --full    Also run the complete test suite in tests/run_tests.pl
#
# Run from the repository root directory.
# Exits with status 0 if all checks pass, 1 otherwise.

set -e

SWIPL="${SWIPL:-swipl}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

RUN_FULL=0
while [ $# -gt 0 ]; do
    case "$1" in
        --full)
            RUN_FULL=1
            shift
            ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

PASS=0
FAIL=0

run_check() {
    LABEL="$1"
    shift
    echo ""
    echo "--- $LABEL ---"
    if "$@"; then
        echo "[OK] $LABEL"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $LABEL"
        FAIL=$((FAIL + 1))
    fi
}

# 1. Self-hosting invariants
run_check "Self-hosting invariants" \
    "$SWIPL" -g "consult('src/self_host')" \
             -g "check_self_hosting" \
             -t halt

# 2. Equivalence test suite
run_check "Equivalence tests" \
    "$SWIPL" -g "consult('tests/equivalence_tests')" \
             -g "run_equivalence_tests" \
             -t halt

# 3. Full test suite (optional)
if [ "$RUN_FULL" -eq 1 ]; then
    run_check "Full test suite" \
        "$SWIPL" -g "consult('tests/run_tests')" \
                 -g "run_all_tests" \
                 -t halt
fi

echo ""
echo "=== Self-check summary: $PASS check(s) passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
