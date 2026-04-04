#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUT="$TMP_DIR/help.txt"

mkdir -p "$TMP_DIR"
"$BIN_ZETTEL" -h > "$OUT"
printf 'Wrote %s\n' "$OUT"
