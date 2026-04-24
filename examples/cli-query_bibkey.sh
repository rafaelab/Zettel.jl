#!/usr/bin/env bash
set -eu

#-------------------------------------------------------------------------------
# Example: query one bibkey from a bibliography library
#
# This script demonstrates `bin/zettel --query <bibkey> --library <file>`.
# It queries a key from `examples/data/references.bib` and prints a compact summary.
#
# Usage: run from the `examples/` directory.
# Optionally pass the bibkey as the first argument.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
DATA_DIR="$SCRIPT_DIR/data"
KEY="${1:-einstein1905a}"

"$BIN_ZETTEL" --query "$KEY" --library "$DATA_DIR/references.bib"
