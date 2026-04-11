#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

LIBRARY_PATH="${1:-$SCRIPT_DIR/tmp/references.yaml}"
SOURCE_LIBRARY="$SCRIPT_DIR/data/references.bib"
BIN_ZETTEL="$PROJECT_ROOT/bin/zettel"

if [ ! -x "$BIN_ZETTEL" ]; then
	if command -v zettel >/dev/null 2>&1; then
		BIN_ZETTEL="zettel"
	else
		echo "Error: could not find executable zettel CLI (tried $PROJECT_ROOT/bin/zettel and PATH)." >&2
		exit 1
	fi
fi

if [ ! -f "$LIBRARY_PATH" ]; then
	mkdir -p "$(dirname "$LIBRARY_PATH")"
	"$BIN_ZETTEL" "$SOURCE_LIBRARY" "$LIBRARY_PATH"
fi

echo "################################################################"
echo "# zettelLibUpdateYaml                                          #"
echo "# Library: $LIBRARY_PATH                                       #"
echo "# Paste one BibTeX entry below.                                #"
echo "# End input with a line containing only ';;'.                  #"
echo "################################################################"

awk '/^;;$/ {exit} {print}' | "$BIN_ZETTEL" libupdate --library "$LIBRARY_PATH"
