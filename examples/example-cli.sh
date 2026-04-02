#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

INPUT_BIB="$SCRIPT_DIR/sample.bib"
JSON_FROM_BIB="$SCRIPT_DIR/sample_from_bib.json"
YAML_FROM_BIB="$SCRIPT_DIR/sample_from_bib.yaml"
BIB_FROM_YAML="$SCRIPT_DIR/sample_from_yaml.bib"
JSON_FROM_YAML="$SCRIPT_DIR/sample_from_yaml.json"

julia --project="$ROOT_DIR" -e 'using Zettel; zettelCLI(args = [ARGS[1], ARGS[2]])' \
	"$INPUT_BIB" "$JSON_FROM_BIB"

julia --project="$ROOT_DIR" -e 'using Zettel; zettelCLI(args = ["convert", ARGS[1], ARGS[2], "--to", "yaml"])' \
	"$JSON_FROM_BIB" "$YAML_FROM_BIB"

julia --project="$ROOT_DIR" -e 'using Zettel; zettelCLI(args = ["convert", ARGS[1], ARGS[2], "--to", "bib"])' \
	"$YAML_FROM_BIB" "$BIB_FROM_YAML"

julia --project="$ROOT_DIR" -e 'using Zettel; zettelCLI(args = ["convert", ARGS[1], ARGS[2], "--to", "json"])' \
	"$YAML_FROM_BIB" "$JSON_FROM_YAML"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/workflow.aux" <<'EOF'
\relax
\citation{Einstein1905,Misner1973}
\bibdata{sample}
\bibstyle{plain}
EOF

julia --project="$ROOT_DIR" -e 'using Zettel; zettelCLI(args = [ARGS[1], "-o", ARGS[2], "-l", ARGS[3]])' \
	"$TMPDIR/workflow.aux" "$TMPDIR/workflow.bbl" "$SCRIPT_DIR/sample.yaml"

printf 'Wrote:\n'
printf '  %s\n' "$JSON_FROM_BIB" "$YAML_FROM_BIB" "$BIB_FROM_YAML" "$JSON_FROM_YAML" "$TMPDIR/workflow.bbl"
