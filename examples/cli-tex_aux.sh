#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_ZETTEL="$SCRIPT_DIR/../bin/zettel"
TMP_DIR="$SCRIPT_DIR/tmp"
STYLES=(plain unsrt alpha ieeestr)

run_aux_workflow() {
  local tex_file="$1"
  local library_file="$2"
  local stem="$3"
  local aux_file="$TMP_DIR/${stem}.aux"
  local bbl_file="$TMP_DIR/${stem}.bbl"

  pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$TMP_DIR" "$tex_file" >/dev/null

  "$BIN_ZETTEL" "$aux_file" --library "$library_file" --style plain --output "$bbl_file"

  for style in "${STYLES[@]}"; do
    "$BIN_ZETTEL" "$aux_file" --library "$library_file" --style "$style" --output "$TMP_DIR/${stem}_${style}.bbl"
  done

  pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$TMP_DIR" "$tex_file" >/dev/null
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$TMP_DIR" "$tex_file" >/dev/null
}

mkdir -p "$TMP_DIR"

run_aux_workflow "$SCRIPT_DIR/tex-aux_yaml.tex" "$SCRIPT_DIR/data/sample.yaml" "tex-aux_yaml"
run_aux_workflow "$SCRIPT_DIR/tex-aux_json.tex" "$SCRIPT_DIR/data/sample.json" "tex-aux_json"

printf 'Wrote TeX AUX/BBL/PDF artifacts in %s\n' "$TMP_DIR"
printf 'Style variants tested: %s\n' "${STYLES[*]}"
