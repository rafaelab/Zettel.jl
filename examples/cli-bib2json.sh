#!/usr/bin/env bash
set -eu

#-------------------------------------------------------------------------------
# Example: convert a BibTeX library to JSON using the CLI wrapper
#
# This script demonstrates invoking the `bin/zettel` CLI in the simple two-arg mode: 
#   `zettel <input> <output>`
# It converts `examples/data/sample.bib` to a pretty JSON bibliography at `examples/tmp/references.json`.
#
# Usage: run this script from the `examples/` directory. 
# It writes the output under `examples/tmp/` and prints the resulting JSON path on success.
#
# Prerequisites:
# - The `bin/zettel` wrapper is executable and points to the project entrypoint.
# - The `examples/data/sample.bib` library file exists.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_JSON="$TMP_DIR/references.json"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" "$DATA_DIR/references.bib" "$OUTPUT_JSON"

printf 'Wrote %s\n' "$OUTPUT_JSON"
