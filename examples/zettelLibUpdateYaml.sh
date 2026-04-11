#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
TMP_DIR="$SCRIPT_DIR/tmp"

LIBRARY_PATH="$TMP_DIR/references.yml"
SOURCE_LIBRARY="$SCRIPT_DIR/data/references.bib"
ROUNDTRIP_FILE="$TMP_DIR/references_roundtrip.bib"
JULIA_BIN="${JULIA_BIN:-julia}"
ZETTEL_CMD=("$JULIA_BIN" --project="$PROJECT_ROOT" -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

if [ $# -ge 1 ]; then
	SOURCE_LIBRARY="$1"
fi

if [ ! -f "$SOURCE_LIBRARY" ]; then
	echo "Error: source library not found: $SOURCE_LIBRARY" >&2
	exit 1
fi

mkdir -p "$TMP_DIR"
if [ ! -f "$LIBRARY_PATH" ]; then
	"${ZETTEL_CMD[@]}" "$SOURCE_LIBRARY" "$LIBRARY_PATH"
fi

echo "################################################################"
echo "# zettelLibUpdateYaml                                          #"
echo "# Source:  $SOURCE_LIBRARY"
echo "# Working: $LIBRARY_PATH"
echo "# Paste one BibTeX entry below.                                #"
echo "# End input with a line containing only ';;'.                  #"
echo "################################################################"

awk '/^;;$/ {exit} {print}' | "${ZETTEL_CMD[@]}" libupdate --library "$LIBRARY_PATH"
"${ZETTEL_CMD[@]}" convert "$LIBRARY_PATH" "$ROUNDTRIP_FILE" --to bib

printf 'Backup and updated library written in %s\n' "$TMP_DIR"
printf 'Roundtrip file: %s\n' "$ROUNDTRIP_FILE"
