# CLI Examples

Each script is a self-contained example for a specific CLI option or subcommand.
Input fixtures live in `examples/data/`.
All generated files are written to `examples/tmp/`.

1. `cli-help.sh` - Show help (`-h`).
2. `cli-bib-to-json.sh` - Convert BibTeX to JSON using the two-argument form.
3. `cli-convert-to.sh` - `convert` with `--to`.
4. `cli-convert-from-to.sh` - `convert` with `-f/--from` and `-t/--to`.
5. `cli-aux-with-options.sh` - `.aux` workflow with `-l/--library` (repeatable), `-o/--output`, `-s/--style`.
6. `cli-paste-to.sh` - `paste` with `--to` (stdin → file).
7. `cli-paste-to-library.sh` - `paste` with `--library` (adds to library).
8. `cli-crossref-doi.sh` - fetch one DOI from Crossref politely (`--mailto`) and output a structured YAML entry (uses `CROSSREF_MAILTO` or a dummy fallback).
9. `cli-doi-source.sh` - fetch one DOI with `--source` (default: `crossref`; pass `datacite` explicitly if needed).
10. `cli-tex_aux.sh` - compile TeX AUX workflows for YAML and JSON, write artifacts to `examples/tmp/`, and test multiple bibliography styles.
