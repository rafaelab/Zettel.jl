#!/usr/bin/env bash
set -eu

#-------------------------------------------------------------------------------
# Example: extract only the references used in a .bbl from a master library.
#
# This script demonstrates `bin/zettel bbl <bblfile> <input.bib> <output.bib>`.
# It reads the cited bibkeys from `examples/data/sample.bbl`.
# Then it pulls the matching entries from `examples/data/references.bib`.
# Finally, it writes a .bib that contains only the used keys (in citation order) to `examples/tmp/usedRefs.bib`.
#
# Usage: run this script from the `examples/` directory.
# It writes the output under `examples/tmp/` and prints the resulting path on success.
#
# Prerequisites:
# - The `bin/zettel` wrapper is executable and points to the project entrypoint.
# - The `examples/data/sample.bbl` and `examples/data/references.bib` files exist.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" bbl "$DATA_DIR/sample.bbl" "$DATA_DIR/references.bib" "$TMP_DIR/sample_bbl.bib"
