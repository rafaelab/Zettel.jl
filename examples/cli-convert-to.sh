#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_YAML="$TMP_DIR/references.yaml"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" convert "$DATA_DIR/sample.bib" "$OUTPUT_YAML" --to yaml

printf 'Wrote %s\n' "$OUTPUT_YAML"
