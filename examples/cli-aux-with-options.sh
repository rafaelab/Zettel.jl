#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
AUX_FILE="$TMP_DIR/workflow.aux"
BBL_FILE="$TMP_DIR/workflow.bbl"

mkdir -p "$TMP_DIR"
cat > "$AUX_FILE" <<'AUX'
\relax
\citation{Einstein1905,Misner1973}
\bibdata{sample}
\bibstyle{plain}
AUX

"$BIN_ZETTEL" "$AUX_FILE" -o "$BBL_FILE" -l "$SCRIPT_DIR/sample.yaml" -l "$SCRIPT_DIR/sample.json" -s plain

printf 'Wrote %s\n' "$BBL_FILE"
