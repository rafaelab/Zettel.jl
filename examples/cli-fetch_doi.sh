#!/usr/bin/env bash
set -eu

#-------------------------------------------------------------------------------
# Example: fetch a DOI via Crossref and write one entry as YAML
#
# This script demonstrates using `bin/zettel doi` to fetch metadata for a DOI.
# It writes a single Zettel entry in YAML format to `examples/tmp/`.
#
# Usage: run from the `examples/` directory. 
# Optionally pass a DOI as the first argument; by default it fetches `10.1038/nphys1170`.
#
# Prerequisites:
# - `bin/zettel` is executable and points to the project entrypoint.
# - For polite Crossref access provide `CROSSREF_MAILTO` or rely on the `MAILTO` variable set in this script.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUT="$TMP_DIR/crossref_entry.yml"
DOI="${1:-10.1038/nphys1170}"
MAILTO="${CROSSREF_MAILTO:-dummy@example.org}"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" doi "$DOI" --source crossref --mailto "$MAILTO" --to yaml --output "$OUT"

printf 'Wrote %s\n' "$OUT"
