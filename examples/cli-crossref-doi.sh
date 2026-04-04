#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUT="$TMP_DIR/crossref_entry.yaml"
DOI="${1:-10.1038/nphys1170}"
MAILTO="${CROSSREF_MAILTO:-dummy@example.org}"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" doi "$DOI" --source crossref --mailto "$MAILTO" --to yaml --output "$OUT"

printf 'Wrote %s\n' "$OUT"
