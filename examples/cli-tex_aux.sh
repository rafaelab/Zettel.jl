#!/usr/bin/env bash

set -eu

#-------------------------------------------------------------------------------
# Example: full TeX AUX -> BBL workflow
#
# This script compiles small TeX fixtures to generate `.aux` files. 
# Then runs `zettel` via Julia to produce `.bbl` files for multiple bibliography styles.
# It exercises the AUX-mode workflow end-to-end and writes artifacts to `examples/tmp/`.
#
# Usage: run from the `examples/` directory. 
# Requires `pdflatex` and a Julia executable (`JULIA_BIN` or `julia` on PATH).
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JULIA_BIN="${JULIA_BIN:-julia}"
TMP_DIR="$SCRIPT_DIR/tmp"
STYLES=(unsrt alpha ieeestr)
ZETTEL_CMD=("$JULIA_BIN" --startup-file=no --compile=min -O0 --project="$SCRIPT_DIR/.." -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' --)

run_aux_workflow() {
  local tex_file="$1"
  local library_file="$2"
  local stem="$3"
  local aux_file="$TMP_DIR/${stem}.aux"
  local bbl_file="$TMP_DIR/${stem}.bbl"

  printf '[%s] pdflatex pass 1\n' "$stem"
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$TMP_DIR" "$tex_file" >/dev/null

  printf '[%s] zettel style plain\n' "$stem"
  "${ZETTEL_CMD[@]}" "$aux_file" --library "$library_file" --style plain --output "$bbl_file"

  for style in "${STYLES[@]}"; do
    printf '[%s] zettel style %s\n' "$stem" "$style"
    "${ZETTEL_CMD[@]}" "$aux_file" --library "$library_file" --style "$style" --output "$TMP_DIR/${stem}_${style}.bbl"
  done

  printf '[%s] pdflatex pass 2\n' "$stem"
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$TMP_DIR" "$tex_file" >/dev/null
  printf '[%s] pdflatex pass 3\n' "$stem"
  pdflatex -interaction=nonstopmode -halt-on-error -output-directory "$TMP_DIR" "$tex_file" >/dev/null
}

mkdir -p "$TMP_DIR"

run_aux_workflow "$SCRIPT_DIR/tex-aux_yaml.tex" "$SCRIPT_DIR/data/references.yml" "tex-aux_yaml"
run_aux_workflow "$SCRIPT_DIR/tex-aux_json.tex" "$SCRIPT_DIR/data/references.json" "tex-aux_json"

printf 'Wrote TeX AUX/BBL/PDF artifacts in %s\n' "$TMP_DIR"
printf 'Style variants tested: plain %s\n' "${STYLES[*]}"
