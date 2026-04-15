#!/usr/bin/env sh
# self_build.sh — NeuroProlog Self-Build Script
#
# Rebuild NeuroProlog from its own source using one of four modes:
#
#   --clean              Clean rebuild from plain Prolog source (default)
#   --with-dict FILE     Rebuild loading a prior optimisation dictionary
#   --merge FILE         Rebuild merging in newly learned optimisations
#   --safe               Safe fallback rebuild without experimental transforms
#   --approve-opt-loss   Approve any lost optimisation rules (logs to rebuild_log.txt)
#
# Usage:
#   ./tools/self_build.sh [--clean]
#   ./tools/self_build.sh --with-dict optimisations/my_dict.pl
#   ./tools/self_build.sh --merge /tmp/new_opts.pl
#   ./tools/self_build.sh --safe
#   ./tools/self_build.sh --clean --approve-opt-loss
#
# All modes write output to neurocode/neuroprolog_nc.pl.
# Run from the repository root directory.

set -e

SWIPL="${SWIPL:-swipl}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

MODE="clean"
FILE=""
APPROVE_OPT_LOSS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --clean)
            MODE="clean"
            shift
            ;;
        --with-dict)
            MODE="with_dict"
            FILE="$2"
            shift 2
            ;;
        --merge)
            MODE="merged"
            FILE="$2"
            shift 2
            ;;
        --safe)
            MODE="safe"
            shift
            ;;
        --approve-opt-loss)
            APPROVE_OPT_LOSS="-g npl_rebuild_approve_opt_loss"
            shift
            ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage." >&2
            exit 1
            ;;
    esac
done

echo "=== NeuroProlog Self-Build (mode: $MODE) ==="

case "$MODE" in
    clean)
        "$SWIPL" -g "consult('src/rebuild')" \
                 $APPROVE_OPT_LOSS \
                 -g "rebuild_clean" \
                 -t halt
        ;;
    with_dict)
        if [ -z "$FILE" ]; then
            echo "Error: --with-dict requires a file argument." >&2
            exit 1
        fi
        if [ ! -f "$FILE" ]; then
            echo "Error: dictionary file not found: $FILE" >&2
            exit 1
        fi
        "$SWIPL" -g "consult('src/rebuild')" \
                 $APPROVE_OPT_LOSS \
                 -g "rebuild_with_dict('$FILE')" \
                 -t halt
        ;;
    merged)
        if [ -z "$FILE" ]; then
            echo "Error: --merge requires a file argument." >&2
            exit 1
        fi
        if [ ! -f "$FILE" ]; then
            echo "Error: new-optimisations file not found: $FILE" >&2
            exit 1
        fi
        "$SWIPL" -g "consult('src/rebuild')" \
                 $APPROVE_OPT_LOSS \
                 -g "rebuild_with_merged('$FILE')" \
                 -t halt
        ;;
    safe)
        "$SWIPL" -g "consult('src/rebuild')" \
                 $APPROVE_OPT_LOSS \
                 -g "rebuild_safe_fallback" \
                 -t halt
        ;;
esac

echo "=== Build complete. Output: neurocode/neuroprolog_nc.pl ==="
