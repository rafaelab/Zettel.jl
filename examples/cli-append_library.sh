#!/usr/bin/env bash

set -eu

#-------------------------------------------------------------------------------
# Example: paste a BibTeX entry and add it to a library
#
# This script pipes a small BibTeX entry into `bin/zettel paste`. 
# It requests JSON output while also updating a temporary library file under `examples/tmp/`.
#
# Usage: run from the `examples/` directory. Requires `bin/zettel` to be executable.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_JSON="$TMP_DIR/pasted.json"
LIBRARY_JSON="$TMP_DIR/library.json"

mkdir -p "$TMP_DIR"
rm -f "$LIBRARY_JSON"
cat <<'BIB' | "$BIN_ZETTEL" paste --to json --library "$LIBRARY_JSON" > "$OUTPUT_JSON"
@article{Doe2024,
  author = {Doe, Jane},
  title = {Sample Entry},
  journal = {Journal of Examples},
  year = {2024}
}
BIB

printf 'Wrote %s\n' "$OUTPUT_JSON"
printf 'Library updated at %s\n' "$LIBRARY_JSON"
