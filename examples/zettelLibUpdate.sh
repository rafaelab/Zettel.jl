#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
TMP_DIR="$SCRIPT_DIR/tmp"

SOURCE_LIBRARY="${1:-$SCRIPT_DIR/data/references.bib}"
WORK_LIBRARY="$TMP_DIR/references.bib"
ROUNDTRIP_FILE="$TMP_DIR/references_roundtrip.bib"
ROUNDTRIP_YAML="$TMP_DIR/references_roundtrip.yml"
JULIA_BIN="${JULIA_BIN:-julia}"
ZETTEL_CMD=("$JULIA_BIN" --project="$PROJECT_ROOT" -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

if [ ! -f "$SOURCE_LIBRARY" ]; then
	echo "Error: source library not found: $SOURCE_LIBRARY" >&2
	exit 1
fi

mkdir -p "$TMP_DIR"
cp "$SOURCE_LIBRARY" "$WORK_LIBRARY"

echo "################################################################"
echo "# zettelLibUpdate                                              #"
echo "# Source:  $SOURCE_LIBRARY"
echo "# Working: $WORK_LIBRARY"
echo "# Paste one BibTeX entry below.                                #"
echo "# End input with a line containing only ';;'.                  #"
echo "################################################################"

awk '/^;;$/ {exit} {print}' | "${ZETTEL_CMD[@]}" libupdate --library "$WORK_LIBRARY"

"${ZETTEL_CMD[@]}" convert "$WORK_LIBRARY" "$ROUNDTRIP_YAML" --to yaml
"${ZETTEL_CMD[@]}" convert "$ROUNDTRIP_YAML" "$ROUNDTRIP_FILE" --from yaml --to bib

printf 'Backup and updated library written in %s\n' "$TMP_DIR"
printf 'Roundtrip file: %s\n' "$ROUNDTRIP_FILE"
