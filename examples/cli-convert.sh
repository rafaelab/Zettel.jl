#!/usr/bin/env bash
set -eu

#-------------------------------------------------------------------------------
# Example: convert YAML to BibTeX using the CLI
#
# This script converts `examples/data/references.yml` into BibTeX.
# Output is saved to `examples/tmp/references.bib`.
# Conversion is done with explicit `-f`/`-t` format flags.
#
# Usage: run from the `examples/` directory.
# Requires a Julia executable (`JULIA_BIN` or `julia` on PATH).
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JULIA_BIN="${JULIA_BIN:-julia}"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_BIB="$TMP_DIR/references.bib"
ZETTEL_CMD=("$JULIA_BIN" --project="$SCRIPT_DIR/.." -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

mkdir -p "$TMP_DIR"
"${ZETTEL_CMD[@]}" convert "$DATA_DIR/references.yml" "$OUTPUT_BIB" -f yaml -t bib

printf 'Wrote %s\n' "$OUTPUT_BIB"
