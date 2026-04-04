#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_BIB="$TMP_DIR/references.bib"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" convert "$SCRIPT_DIR/sample.yaml" "$OUTPUT_BIB" -f yaml -t bib

printf 'Wrote %s\n' "$OUTPUT_BIB"
