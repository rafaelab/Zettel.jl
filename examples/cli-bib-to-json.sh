#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_JSON="$TMP_DIR/references.json"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" "$DATA_DIR/sample.bib" "$OUTPUT_JSON"

printf 'Wrote %s\n' "$OUTPUT_JSON"
