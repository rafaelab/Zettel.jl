#!/usr/bin/env bash
set -eu

#-------------------------------------------------------------------------------
# Example: show CLI help output
#
# This script runs `bin/zettel -h` and writes the help text to `examples/tmp/help.txt`.
#
# Usage: run from the `examples/` directory.
# Prerequisites: `bin/zettel` is executable and points to the project entrypoint.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUT="$TMP_DIR/help.txt"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" -h > "$OUT"
printf 'Wrote %s\n' "$OUT"
