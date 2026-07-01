# Command-Line Interface

The CLI entry point is [`zettelCLI`](@ref). You can run it either through the repository wrapper or directly through Julia.

## Recommended invocation during development

When you are editing the source tree, prefer the Julia entry point so you always run the current code:
```bash
julia --project=. -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' -- --help
```

If you have already built the executable, `zettel` provides the same interface:
```bash
zettel --help
```
Don't forget to add `bin/zettel` to your `$PATH`.

## Commands

The CLI supports seven modes:
- `zettel convert <input> <output> [--from <fmt>] --to <fmt>`
- `zettel doi <doi> [--source <name>] [--to <fmt>] [--output <file>] [--mailto <email>] [--plus-token <token>]`
- `zettel --query <bibkey> --library <file>`
- `zettel bbl <bblfile> <input-library> <output-library>`
- `zettel paste [--to <fmt>] --library <file>`
- `zettel paste --to <fmt>`
- `zettel libupdate --library <file> [--key <key>] [--fileDir <dir>]`
- `zettel <auxfile> [options]`

Supported formats are `bib`, `json`, and `yaml`.

## Single-reference extraction

Exact-key operations do not parse the whole library. They pull just the entry they need with the
helper scripts in [`tools/`](https://github.com/rafaelab/Zettel.jl/tree/main/tools):

```bash
tools/extractEntry einstein1905a references.bib     # perl, for .bib / .bibtex
tools/extractEntry einstein1905a references.json    # jq,   for .json
tools/extractEntry einstein1905a references.yml     # yq,   for .yaml / .yml
```

`extractEntry` dispatches on the file extension and prints the single matching record in the file's
own format (nothing if the key is absent). Two CLI paths use this to skip the cost of building every
entry in the file:

- **`--query`** on `.bib` and `.yaml`/`.yml` libraries extracts and parses only the requested entry.
- **`bbl`** with a BibTeX master parses only the cited entries instead of the whole master library.

Notes:

- The Julia side (`extractEntryWithTool` in `src/extract.jl`) is best-effort: if the required
  interpreter (`perl`, `jq`, or `yq`) or the script is missing, or the output is unexpected, it
  silently falls back to the normal full-load path, so results are always correct.
- `jq` ships with most systems; `yq` (the Go [`mikefarah/yq`](https://github.com/mikefarah/yq)) is
  optional — YAML queries simply fall back to a full load when it is absent.
- Set `ZETTEL_TOOLS_DIR` to point at the `tools/` directory if you run a relocated checkout or a
  compiled binary whose `tools/` is not next to the package source.

## Convert

Convert between bibliography formats.
```bash
zettel convert references.bib references.json --to json
zettel convert references.json references.yml --to yaml
zettel convert references.yml references.bib --from yaml --to bib
```

There is also a shorthand two-argument mode that infers formats from file extensions:
```bash
zettel references.bib references.json
zettel references.json references.yml
```

Relevant example scripts:

- [`examples/cli-bib2json.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-bib2json.sh)
- [`examples/cli-bib2yaml.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-bib2yaml.sh)
- [`examples/cli-convert.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-convert.sh)
- [`examples/cli-convert_simple.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-convert_simple.sh)

## DOI Lookup

Fetch one entry from a DOI metadata source.
```bash
zettel doi 10.1038/nphys1170 --source crossref --mailto you@example.org --to yaml
zettel doi 10.5281/zenodo.2553894 --source datacite --to json --output entry.json
```

Notes:
- `crossref` is the default source.
- `datacite` is also supported.
- `--mailto` is strongly recommended for Crossref polite access.
- `--plus-token` can be used with Crossref Metadata Plus.

Instead of passing `--mailto` on every call you can set the environment variable `CROSSREF_MAILTO`.
Likewise, `CROSSREF_PLUS_API_TOKEN` is read when `--plus-token` is omitted:

```bash
export CROSSREF_MAILTO=you@example.org
export CROSSREF_PLUS_API_TOKEN=my-token   # optional
zettel doi 10.1038/nphys1170 --to yaml
```

The CLI also accepts the DOI as the first positional argument without the explicit `doi` subcommand.
The shorthand is triggered automatically when the first argument starts with `10.` and contains a `/`:

```bash
zettel 10.1038/nphys1170 --source crossref --mailto you@example.org --to bib
```

Relevant example scripts:

- [`examples/cli-fetch_doi.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-fetch_doi.sh)
- [`examples/cli-fetch_doi_sources.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-fetch_doi_sources.sh)

## Bibkey Query

Query one key from a bibliography library and print a compact human-readable summary:
```bash
zettel --query einstein1905a --library references.bib
```

For `.bib` and `.yaml`/`.yml` libraries the requested entry is pulled out with the
[single-reference extraction](#Single-reference-extraction) helpers, so the rest of the library is
never parsed.

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


## BBL / Extract Cited Entries

Extract only the entries that appear in a `.bbl` file from a master library and write a smaller library containing only those entries.
```bash
zettel bbl paper.bbl references.bib used.bib
zettel bbl paper.bbl references.yml used.json
```

Arguments (all positional, all required):
1. `<bblfile>` — the `.bbl` file whose citation keys drive the selection.
2. `<input-library>` — the master library to pull entries from (`.bib`, `.json`, `.yaml`, `.yml`).
3. `<output-library>` — the destination file; format is inferred from the extension.

Notes:
- Entries are written in the order they appear in the `.bbl` file.
- Any key referenced in the `.bbl` but absent from the master library produces a warning on stdout; the remaining keys are still written.
- The input and output libraries may use different formats, so `bbl` doubles as a targeted conversion.
- With a BibTeX master, only the cited entries are parsed (see
  [single-reference extraction](#Single-reference-extraction)) — typically a large speedup when the
  master library is much bigger than the citation list.

Relevant example scripts:

- [`examples/cli-bbl2bib.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-bbl2bib.sh)

## Paste

Read one BibTeX entry from standard input. You can print it in another format, add it to a library, or do both.

Print converted output only:
```bash
pbpaste | zettel paste --to yaml
```

Add the entry to a library while also printing JSON:
```bash
pbpaste | zettel paste --to json --library references.json
```

Notes:
- The input for `paste` is always BibTeX.
- `--library` accepts `.bib`, `.json`, `.yaml`, and `.yml` files.
- Entries inserted into a library receive generated keys of the form `surnameYYYYx` or, when appropriate, a collaboration-based key.
- When `--to` and `--library` are used together, the printed entry is the prepared library entry, including the generated key and normalised fields.
- When the library does not exist yet, it is created.

Relevant example scripts:
- [`examples/cli-paste_conversion.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-paste_conversion.sh)
- [`examples/cli-append_library.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/cli-append_library.sh)

## Library Update

`libupdate` is the main library-maintenance command. 
It reads exactly one BibTeX entry from standard input, derives or validates its key, creates a timestamped backup of the target library, checks for likely duplicates and nearby files, then inserts the entry in sorted order.
```bash
pbpaste | zettel libupdate --library references.bib
pbpaste | zettel libupdate --library references.yml
pbpaste | zettel libupdate --library references.json --fileDir /path/to/files
```

Current behaviour:
- Input is always BibTeX, even when the target library is JSON or YAML.
- The target library may be `.bib`, `.json`, `.yaml`, or `.yml`.
- A backup file is created next to the target library with a timestamp suffix (e.g. `references.bib.20241201-153000.bak`).
- Keys are generated from the first author surname by default, following the pattern `surnameYYYYx` (e.g. `einstein1905a`).
- If `collaboration` is present and `onbehalf` does not force author precedence, the collaboration token may be used for key generation.
- If a `file` field already implies a key, that key is preferred.
- Existing nearby files such as `<fileDir>/<key>.pdf` or `<fileDir>/<first-letter>/<key>.pdf` are detected and reported.
- If a very similar entry is already present in the library, the insert is skipped and a warning is emitted instead of creating a duplicate.

When running interactively from a terminal (TTY), `libupdate` prompts you to confirm or override the suggested key before proceeding.
When running in a non-interactive pipeline the suggested key is applied silently.

Relevant example scripts:
- [`examples/zettelLibUpdate.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/zettelLibUpdate.sh)
- [`examples/zettelLibUpdateYaml.sh`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/zettelLibUpdateYaml.sh)

## AUX to BBL

Pass a LaTeX `.aux` file to generate a `.bbl` bibliography file.
```bash
zettel paper.aux --library references.json --output paper.bbl --style plain
zettel paper.aux --library references.yml --style alpha
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

### `bbl`

- `<bblfile>`: LaTeX `.bbl` file providing the cited keys (positional, required)
- `<input-library>`: master library to pull entries from (`.bib`, `.json`, `.yaml`, `.yml`; positional, required)
- `<output-library>`: destination file; format inferred from extension (positional, required)

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

Rebuild the executable if you rely on `zettel` as a compiled binary:
```bash
julia --project=cli cli/buildExecutable.jl
```

During active development, use the Julia entry point shown at the top of this page.

### BibTeX commands are slower than JSON or YAML commands

That is expected. BibTeX parsing and writing go through `Pybtex.jl` and Python, whereas pure JSON and YAML flows stay within Julia. Exact-key operations (`--query`, and `bbl` with a BibTeX master) sidestep most of this cost by parsing only the requested entries — see [single-reference extraction](#Single-reference-extraction).

### `yq` is not installed

`yq` is only needed to accelerate YAML `--query`. Without it, YAML queries fall back to a full load and still work. Install the Go [`mikefarah/yq`](https://github.com/mikefarah/yq) to enable the fast path.

### `.bbl` generation reports missing keys

Check that:
- the cited keys in the `.aux` file actually exist in the provided libraries;
- the library paths passed with `--library` are correct;
- the library files use a supported extension.
