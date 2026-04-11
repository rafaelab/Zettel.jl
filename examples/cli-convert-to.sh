#!/usr/bin/env bash

set -eu

#-------------------------------------------------------------------------------
# Example: convert a BibTeX library to YAML using the CLI
#
# This script runs `zettel convert` via Julia.
# It converts `examples/data/references.bib` to YAML at `examples/tmp/references.yml`.
#
# Usage: run from the `examples/` directory.
# Requires a Julia executable (`JULIA_BIN` or `julia` on PATH).
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JULIA_BIN="${JULIA_BIN:-julia}"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_YAML="$TMP_DIR/references.yml"
ZETTEL_CMD=("$JULIA_BIN" --project="$SCRIPT_DIR/.." -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

mkdir -p "$TMP_DIR"
"${ZETTEL_CMD[@]}" convert "$DATA_DIR/references.bib" "$OUTPUT_YAML" --to yaml

printf 'Wrote %s\n' "$OUTPUT_YAML"
