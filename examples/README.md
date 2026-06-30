# Examples

This directory contains small example scripts demonstrating common `zettel` CLI workflows.
Run scripts from the repository root (or from this directory) with `bash examples/<script>.sh`.

## Prerequisites
- `bin/zettel` (or a Julia invocation) is executable and points to the project entrypoint.
- `pdflatex` is required for the TeX/AUX workflow examples.
- Network access is required for DOI examples that fetch metadata (Crossref).

## Available scripts
The README lists the example shell scripts present in this directory. Use them as small demonstrations or templates for integrating `zettel` into your workflows.
- `cli-bib2json.sh`: Convert `examples/data/references.bib` to JSON and write to `examples/tmp/references.json`.
- `cli-bib2yaml.sh`: Convert `examples/data/references.bib` to YAML and write to `examples/tmp/references.yml`.
- `cli-convert.sh`: Convert `examples/data/references.yml` to BibTeX with explicit `-f`/`-t` flags.
- `cli-convert_simple.sh`: Simple convert helper (legacy/simple convert invocations).
- `cli-fetch_doi.sh`: Fetch a DOI (default `10.1038/nphys1170`) from Crossref and write YAML.
- `cli-fetch_doi_sources.sh`: Fetch a DOI from a configurable metadata source (default: crossref).
- `cli-help.sh`: Capture the CLI `-h`/`--help` output to `examples/tmp/help.txt`.
- `cli-query_bibkey.sh`: Query one bibkey in a library and print a compact summary.
- `cli-append_library.sh`: Append an entry to a library file (example helper script).
- `cli-paste_conversion.sh`: Pipe a BibTeX entry into `zettel paste` and print converted output.
- `cli-tex_aux.sh`: Full TeX AUX -> BBL workflow; compiles small TeX fixtures and generates `.bbl` files for several bibliography styles (requires `pdflatex`).
- `cli-tex_aux_opts.sh`: Variant of the TeX AUX workflow exercising additional options.
- `zettelLibUpdate.sh`: Example library-update workflow (BibTeX-backed library updates).
- `zettelLibUpdateYaml.sh`: Variant demonstrating YAML-backed library updates.
- `example-addBibtexToJsonLibrary.jl`: Fast JSON-library update helper for one pasted BibTeX entry with entry fixes.

## Notes
- Example scripts write artifacts under `examples/tmp/` and read from `examples/data/`.
- The example scripts are intended as demonstrations; adapt them as templates for your own automation or CI tasks.
