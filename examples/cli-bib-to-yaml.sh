#!/usr/bin/env bash

set -eu

#-------------------------------------------------------------------------------
# Example: convert a BibTeX library to YAML (alternate)
#
# Converts `examples/data/sample.bib` to `examples/tmp/sample.yaml`.
# Uses the simple two-argument CLI invocation: 
#   `zettel <input> <output>`.
#
# Usage: run from the `examples/` directory. Requires `bin/zettel` present.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_YAML="$TMP_DIR/references.yml"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" "$DATA_DIR/references.bib" "$OUTPUT_YAML"

printf 'Wrote %s\n' "$OUTPUT_YAML"
