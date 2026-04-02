#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
BIN_ZETTEL="$ROOT_DIR/bin/zettel"

INPUT_BIB="$SCRIPT_DIR/sample.bib"
JSON_FROM_BIB="$SCRIPT_DIR/sample_from_bib.json"
YAML_FROM_BIB="$SCRIPT_DIR/sample_from_bib.yaml"
BIB_FROM_YAML="$SCRIPT_DIR/sample_from_yaml.bib"
JSON_FROM_YAML="$SCRIPT_DIR/sample_from_yaml.json"

"$BIN_ZETTEL" --no-sysimage "$INPUT_BIB" "$JSON_FROM_BIB"

"$BIN_ZETTEL" --no-sysimage convert "$JSON_FROM_BIB" "$YAML_FROM_BIB" --to yaml

"$BIN_ZETTEL" --no-sysimage convert "$YAML_FROM_BIB" "$BIB_FROM_YAML" --to bib

"$BIN_ZETTEL" --no-sysimage convert "$YAML_FROM_BIB" "$JSON_FROM_YAML" --to json

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/workflow.aux" <<'EOF'
\relax
\citation{Einstein1905,Misner1973}
\bibdata{sample}
\bibstyle{plain}
EOF

"$BIN_ZETTEL" --no-sysimage "$TMPDIR/workflow.aux" -o "$TMPDIR/workflow.bbl" -l "$SCRIPT_DIR/sample.yaml"

printf 'Wrote:\n'
printf '  %s\n' "$JSON_FROM_BIB" "$YAML_FROM_BIB" "$BIB_FROM_YAML" "$JSON_FROM_YAML" "$TMPDIR/workflow.bbl"
