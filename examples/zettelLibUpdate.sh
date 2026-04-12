#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

LIBRARY_PATH="${1:-$SCRIPT_DIR/data/references.bib}"
JULIA_BIN="${JULIA_BIN:-julia}"
ZETTEL_CMD=("$JULIA_BIN" --project="$PROJECT_ROOT" -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

if [ ! -f "$LIBRARY_PATH" ]; then
	echo "Error: library not found: $LIBRARY_PATH" >&2
	exit 1
fi

echo "################################################################"
echo "# zettelLibUpdate                                              #"
echo "# Library: $LIBRARY_PATH"
echo "# Paste one BibTeX entry below.                                #"
echo "# End input with a line containing only ';;'.                  #"
echo "################################################################"

awk '/^;;$/ {exit} {print}' | "${ZETTEL_CMD[@]}" libupdate --library "$LIBRARY_PATH"

printf 'Updated library: %s\n' "$LIBRARY_PATH"
