# Command-Line Interface

The CLI entry point is [`zettelCLI`](@ref). You can run it either through the repository wrapper or directly through Julia.

## Recommended invocation during development

When you are editing the source tree, prefer the Julia entry point so you always run the current code:

```bash
julia --project=. -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' -- --help
```

If you have already built the executable, `bin/zettel` provides the same interface:

```bash
bin/zettel --help
```

## Commands

The CLI supports six modes:

- `zettel convert <input> <output> [--from <fmt>] --to <fmt>`
- `zettel doi <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]`
- `zettel --query <bibkey> --library <file>`
- `zettel paste [--to <fmt>] --library <file>`
- `zettel paste --to <fmt>`
- `zettel libupdate --library <file> [--key <key>] [--fileDir <dir>]`
- `zettel <auxfile> [options]`

Supported formats are `bib`, `json`, and `yaml`.

## Convert

Convert between bibliography formats.

```bash
bin/zettel convert references.bib references.json --to json
bin/zettel convert references.json references.yml --to yaml
bin/zettel convert references.yml references.bib --from yaml --to bib
```

There is also a shorthand two-argument mode that infers formats from file extensions:

```bash
bin/zettel references.bib references.json
bin/zettel references.json references.yml
```

Relevant example scripts:

- [`examples/cli-bib2json.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-bib2json.sh)
- [`examples/cli-bib2yaml.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-bib2yaml.sh)
- [`examples/cli-convert.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-convert.sh)
- [`examples/cli-convert_simple.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-convert_simple.sh)

## DOI Lookup

Fetch one entry from a DOI metadata source.

```bash
bin/zettel doi 10.1038/nphys1170 --source crossref --mailto you@example.org --to yaml
bin/zettel doi 10.5281/zenodo.2553894 --source datacite --to json --output entry.json
```

Notes:

- `crossref` is the default source.
- `datacite` is also supported.
- `--mailto` is strongly recommended for Crossref polite access.
- `--plus-token` can be used with Crossref Metadata Plus.

The CLI also accepts the DOI as the first positional argument without the explicit `doi` subcommand:

```bash
bin/zettel 10.1038/nphys1170 --source crossref --mailto you@example.org --to bib
```

Relevant example scripts:

- [`examples/cli-fetch_doi.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-fetch_doi.sh)
- [`examples/cli-fetch_doi_sources.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-fetch_doi_sources.sh)

## Bibkey Query

Query one key from a bibliography library and print a compact human-readable summary:

```bash
bin/zettel --query einstein1905a --library references.bib
```

Output format:

```text
"The title"
F. Author, S. Author, ...
Journal, year, volume, number
arXiv:XXXXXXXX
doi: XXXXXXX
bibkey: author20XXa
```

Collaboration behaviour:

- if `collaboration` is set, the collaboration name is printed instead of the author list;
- if `onbehalf` is truthy, the author line becomes `F. Author et al. for XXX Collaboration`.

Relevant example scripts:

- [`examples/cli-query_bibkey.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-query_bibkey.sh)

## Paste

Read one BibTeX entry from standard input. You can print it in another format, add it to a library, or do both.

Print converted output only:

```bash
pbpaste | bin/zettel paste --to yaml
```

Add the entry to a library while also printing JSON:

```bash
pbpaste | bin/zettel paste --to json --library references.json
```

Notes:

- The input for `paste` is always BibTeX.
- `--library` accepts `.bib`, `.json`, `.yaml`, and `.yml` files.
- When the library does not exist yet, it is created.

Relevant example scripts:

- [`examples/cli-paste_conversion.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-paste_conversion.sh)
- [`examples/cli-append_library.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-append_library.sh)

## Library Update

`libupdate` is the more opinionated library-maintenance command. It reads exactly one BibTeX entry from standard input, derives or validates its key, creates a timestamped backup of the target library, then inserts the entry in sorted order.

```bash
pbpaste | bin/zettel libupdate --library references.bib
pbpaste | bin/zettel libupdate --library references.yml
pbpaste | bin/zettel libupdate --library references.json --fileDir /path/to/files
```

Current behaviour:

- Input is always BibTeX, even when the target library is JSON or YAML.
- The target library may be `.bib`, `.json`, `.yaml`, or `.yml`.
- A backup file is created next to the target library with a timestamp suffix.
- Keys are generated from the first author surname by default.
- If `collaboration` is present and `onbehalf` does not force author precedence, the collaboration token may be used for key generation.
- If a `file` field already implies a key, that key is preferred.
- Existing nearby files such as `<fileDir>/<key>.pdf` or `<fileDir>/<first-letter>/<key>.pdf` are detected and reported.
- If a very similar entry is already present in the library, the insert is skipped and a warning is emitted instead of creating a duplicate.

Relevant example scripts:

- [`examples/zettelLibUpdate.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/zettelLibUpdate.sh)
- [`examples/zettelLibUpdateYaml.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/zettelLibUpdateYaml.sh)

## AUX to BBL

Pass a LaTeX `.aux` file to generate a `.bbl` bibliography file.

```bash
bin/zettel paper.aux --library references.json --output paper.bbl --style plain
bin/zettel paper.aux --library references.yml --style alpha
```

Options:

- `-l`, `--library <file>`: one or more library files
- `-o`, `--output <file>`: output `.bbl` path
- `-s`, `--style <name>`: bibliography style

When `--library` is omitted, the CLI tries to resolve libraries from `\bibdata{...}` in the `.aux` file.
When `--style auto` is used, or when `--style` is omitted, the CLI tries to use `\bibstyle{...}` from the `.aux` file.

Relevant example scripts:

- [`examples/cli-tex_aux.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-tex_aux.sh)
- [`examples/cli-tex_aux_opts.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-tex_aux_opts.sh)

## Options Summary

### `convert`

- `-f`, `--from <fmt>`: input format, inferred from the input path when omitted
- `-t`, `--to <fmt>`: output format, required

### `doi`

- `--source <name>`: DOI source, currently `crossref` or `datacite`
- `-t`, `--to <fmt>`: output format, defaults to `bib`
- `-o`, `--output <file>`: write to a file instead of stdout
- `-m`, `--mailto <email>`: Crossref contact email
- `--plus-token <token>`: Crossref Metadata Plus token

### `paste`

- `-t`, `--to <fmt>`: print the converted entry to stdout
- `-l`, `--library <file>`: append the entry to a library file

### `libupdate`

- `-l`, `--library <file>`: target library file
- `--key <key>`: force a specific key
- `--fileDir <dir>`: attachment search directory, defaulting to `<libraryDir>/files`

### AUX mode

- `-l`, `--library <file>`: repeatable library argument
- `-o`, `--output <file>`: output `.bbl` path
- `-s`, `--style <name>`: bibliography style, defaults to `auto`

### `--query`

- `--query <bibkey>`: citation key to query
- `-l`, `--library <file>`: source library (`.bib`, `.json`, `.yaml`, `.yml`)

## Troubleshooting

### The wrapper does not reflect recent source changes

Rebuild the executable if you rely on `bin/zettel` as a compiled binary:

```bash
julia --project=cli cli/buildExecutable.jl
```

During active development, use the Julia entry point shown at the top of this page.

### BibTeX commands are slower than JSON or YAML commands

That is expected. BibTeX parsing and writing go through `Pybtex.jl` and Python, whereas pure JSON and YAML flows stay within Julia.

### `.bbl` generation reports missing keys

Check that:

- the cited keys in the `.aux` file actually exist in the provided libraries;
- the library paths passed with `--library` are correct;
- the library files use a supported extension.
