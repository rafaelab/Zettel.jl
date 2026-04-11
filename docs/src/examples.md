# Examples

The `examples/` directory contains small scripts that exercise the current CLI and Julia API.
All generated files are written under `examples/tmp/`, while the source fixtures live under `examples/data/`.

## Running examples

From the repository root:

```bash
bash examples/cli-help.sh
bash examples/cli-bib2json.sh
bash examples/cli-tex_aux.sh
julia --project=. examples/example-yaml.jl
```

General prerequisites:

- a working Julia installation;
- `pybtex` available through the Python environment used by `PythonCall.jl` for BibTeX operations;
- `pdflatex` for the TeX/AUX examples;
- network access for the DOI-fetching examples.

## Conversion examples

- `examples/cli-bib2json.sh`: simple two-argument conversion from `references.bib` to JSON.
- `examples/cli-bib2yaml.sh`: simple two-argument conversion from `references.bib` to YAML.
- `examples/cli-convert.sh`: explicit `convert` invocation from YAML to BibTeX.
- `examples/cli-convert_simple.sh`: explicit `convert` invocation from BibTeX to YAML.
- `examples/example-yaml.jl`: Julia-side read, write, and roundtrip examples.
- `examples/example-json.jl`: conversion helpers and DOI JSON fetch example.

## DOI examples

- `examples/cli-fetch_doi.sh`: fetch one DOI from Crossref and write YAML.
- `examples/cli-fetch_doi_sources.sh`: fetch one DOI from a selected source, currently Crossref or DataCite.

## Paste and library-update examples

- `examples/cli-paste_conversion.sh`: pipe one BibTeX entry to `paste --to yaml`.
- `examples/cli-append_library.sh`: pipe one BibTeX entry to `paste --to json --library ...`.
- `examples/zettelLibUpdate.sh`: update a BibTeX-backed working library under `examples/tmp/`, create a backup there, and write a roundtrip file there as well.
- `examples/zettelLibUpdateYaml.sh`: same workflow, but targeting a YAML library.

Both `zettelLibUpdate` examples accept a pasted BibTeX entry on standard input and stop reading when they encounter a line containing only `;;`.

## AUX and TeX examples

- `examples/cli-tex_aux.sh`: full TeX workflow using small `.tex` fixtures, `pdflatex`, and multiple bibliography styles.
- `examples/cli-tex_aux_opts.sh`: minimal `.aux` example with explicit `--library`, `--output`, and `--style` options.

## Help example

- `examples/cli-help.sh`: capture the CLI help text into `examples/tmp/help.txt`.

## Notes on invocation style

Some examples call `bin/zettel` directly, while others use:

```bash
julia --project=. -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' -- ...
```

That split is intentional.

- The Julia form is the safest choice while developing inside the repository, because it always uses the current source tree.
- The wrapper is fine once the executable has been rebuilt and you want to exercise the installed CLI path.
