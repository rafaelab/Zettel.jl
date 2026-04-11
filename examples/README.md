# Examples

This directory contains small example scripts demonstrating common `zettel` CLI workflows. 
Run scripts from the repository root (or from this directory) with `bash examples/<script>.sh`.

### Prerequisites
- `bin/zettel` is executable and points to the project entrypoint.
- `pdflatex` is required for the TeX/AUX workflow example.
- Network access is required for DOI examples that fetch metadata (Crossref).

### Scripts
- `cli-aux-with-options.sh`: Generate a `.bbl` from a small `.aux` fragment while specifying multiple library files and a bibliography style.
- `cli-bib-to-json.sh`: Convert `examples/data/sample.bib` to JSON (simple two-arg mode).
- `cli-bib-to-yaml.sh`: Convert `examples/data/sample.bib` to YAML (alternate output).
- `cli-convert-from-to.sh`: Convert between formats using explicit `-f`/`-t` flags.
- `cli-convert-to.sh`: Convert `sample.bib` to YAML using `convert` subcommand.
- `cli-crossref-doi.sh`: Fetch a single DOI from Crossref and write one entry as YAML.
- `cli-doi-source.sh`: Fetch a DOI from a configurable metadata source (default: crossref).
- `cli-help.sh`: Capture the CLI `-h`/`--help` output to `examples/tmp/help.txt`.
- `cli-paste-to.sh`: Pipe a small BibTeX entry into `zettel paste` and print YAML.
- `cli-paste-to-library.sh`: Paste a BibTeX entry and update a temporary library file.
- `cli-tex_aux.sh`: Full TeX AUX -> BBL workflow; compiles small TeX fixtures and generates `.bbl` files for several bibliography styles (requires `pdflatex`).
- `zettelLibUpdate.sh`: Helper/example script for library update workflows.
- `zettelLibUpdateYaml.sh`: Variant demonstrating YAML-backed library updates.

### Notes
- Example scripts write artifacts under `examples/tmp/` and read fixtures from `examples/data/`.
- The example scripts are intended as demonstrations; use them as templates for integrating `zettel` into your own workflows.
