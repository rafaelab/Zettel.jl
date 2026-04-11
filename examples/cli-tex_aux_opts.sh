#!/usr/bin/env bash

set -eu

#-------------------------------------------------------------------------------
# Example: generate .bbl from .aux using zettel with multiple libraries
#
# This script demonstrates invoking the CLI wrapper `bin/zettel` in AUX-mode. 
# It produce a `.bbl` file from a small `.aux` fragment. 
# Multiple library files and a bibliography style are specified.
#
# Usage: run this script from the `examples/` directory. 
# It writes temporary files under `examples/tmp/` and prints the resulting .bbl path on success.
#
# Prerequisites:
# - A Julia executable is available (via `JULIA_BIN` or `julia` on PATH).
# - The `examples/data` directory contains `references.bib`, which is converted
#   on the fly into YAML and JSON libraries for this example.
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JULIA_BIN="${JULIA_BIN:-julia}"
DATA_DIR="$SCRIPT_DIR/data"
TMP_DIR="$SCRIPT_DIR/tmp"
AUX_FILE="$TMP_DIR/workflow.aux"
BBL_FILE="$TMP_DIR/workflow.bbl"
LIB_YAML="$TMP_DIR/references.yaml"
LIB_JSON="$TMP_DIR/references.json"
ZETTEL_CMD=("$JULIA_BIN" --project="$SCRIPT_DIR/.." -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

mkdir -p "$TMP_DIR"
"${ZETTEL_CMD[@]}" convert "$DATA_DIR/references.bib" "$LIB_YAML" --to yaml
"${ZETTEL_CMD[@]}" convert "$DATA_DIR/references.bib" "$LIB_JSON" --to json
cat > "$AUX_FILE" <<'AUX'
\relax
\citation{einstein1905a,friedmann1922a}
\bibdata{sample}
\bibstyle{plain}
AUX

"${ZETTEL_CMD[@]}" "$AUX_FILE" -o "$BBL_FILE" -l "$LIB_YAML" -l "$LIB_JSON" -s plain

printf 'Wrote %s\n' "$BBL_FILE"
