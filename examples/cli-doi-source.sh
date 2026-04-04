#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
SOURCE="${1:-crossref}"
DOI="${2:-10.1038/nphys1170}"
OUT="$TMP_DIR/doi_${SOURCE}.yaml"

mkdir -p "$TMP_DIR"

if [ "$SOURCE" = "crossref" ]; then
  MAILTO="${CROSSREF_MAILTO:-dummy@example.org}"
  "$BIN_ZETTEL" doi "$DOI" --source "$SOURCE" --mailto "$MAILTO" --to yaml --output "$OUT"
else
  "$BIN_ZETTEL" doi "$DOI" --source "$SOURCE" --to yaml --output "$OUT"
fi

printf 'Wrote %s\n' "$OUT"
