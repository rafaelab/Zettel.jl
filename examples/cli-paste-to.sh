#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
OUTPUT_YAML="$TMP_DIR/pasted.yaml"

mkdir -p "$TMP_DIR"
cat <<'BIB' | "$BIN_ZETTEL" paste --to yaml > "$OUTPUT_YAML"
@article{Doe2024,
  author = {Doe, Jane},
  title = {Sample Entry},
  journal = {Journal of Examples},
  year = {2024}
}
BIB

printf 'Wrote %s\n' "$OUTPUT_YAML"
