#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./tools/roundtrip_regen.sh <source.pl> <out.pl> [--diff] [--side-by-side]

Options:
  --diff          Write <out.pl>.diff.txt report
  --side-by-side  Write <out.pl>.side_by_side.txt report
EOF
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

SRC="$1"
OUT="$2"
shift 2

if [[ "$SRC" == *"'"* || "$OUT" == *"'"* ]]; then
  echo "Error: paths containing single quotes are not supported." >&2
  exit 1
fi

DO_DIFF=false
DO_SIDE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff) DO_DIFF=true ;;
    --side-by-side) DO_SIDE=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

DIFF_OUT="${OUT}.diff.txt"
SIDE_OUT="${OUT}.side_by_side.txt"

DIFF_GOAL=""
if [[ "$DO_DIFF" == true ]]; then
  DIFF_GOAL=", npl_roundtrip_source_diff_text('$SRC', DiffText), setup_call_cleanup(open('$DIFF_OUT', write, DS), write(DS, DiffText), close(DS))"
fi

SIDE_GOAL=""
if [[ "$DO_SIDE" == true ]]; then
  SIDE_GOAL=", npl_roundtrip_source_side_by_side_text('$SRC', SideText), setup_call_cleanup(open('$SIDE_OUT', write, SS), write(SS, SideText), close(SS))"
fi

swipl -q -g "consult('src/neuroprolog'), npl_roundtrip_source_file('$SRC', '$OUT')${DIFF_GOAL}${SIDE_GOAL}, halt" -t halt

echo "Wrote optimised source: $OUT"
if [[ "$DO_DIFF" == true ]]; then
  echo "Wrote diff report: $DIFF_OUT"
fi
if [[ "$DO_SIDE" == true ]]; then
  echo "Wrote side-by-side report: $SIDE_OUT"
fi
