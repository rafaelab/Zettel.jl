# Examples

This page answers a practical question: which `zettel` command should you run for which job?
The examples are based on the runnable scripts in `examples/`, so each workflow here has a corresponding concrete reference in the repository.

All example scripts read fixtures from `examples/data/` and write generated files to `examples/tmp/`.

## Before you start

During development inside this repository, the safest invocation is:

```bash
julia --project=. -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' -- --help
```

If you have already built the CLI executable, you can use the wrapper instead:

```bash
bin/zettel --help
```

General prerequisites:

- Julia must be available.
- `pybtex` must be available through the Python environment used by `PythonCall.jl` for BibTeX operations.
- `pdflatex` is needed for the LaTeX `.aux` workflows.
- Network access is needed for DOI lookups.

## Which command should I use?

Use this quick guide first, then see the worked examples below.

| Task | Command to use | When it is the right choice |
| --- | --- | --- |
| Convert one bibliography file to another when the extensions already say enough | `zettel <input> <output>` | The simplest file-to-file conversion |
| Convert when you want to state formats explicitly | `zettel convert <input> <output> --to <fmt>` | Clearer scripts, or inputs with ambiguous extensions |
| Convert a pasted BibTeX entry from standard input | `zettel paste --to <fmt>` | One-off conversion without editing a library |
| Add a pasted BibTeX entry to an existing library | `zettel paste --library <file>` | Quick append with minimal ceremony |
| Update a maintained library with backups and key handling | `zettel libupdate --library <file>` | Curated library maintenance rather than a simple append |
| Fetch one entry from a DOI | `zettel doi <doi> ...` | Pull metadata from Crossref or DataCite |
| Extract cited entries from a `.bbl` file into a smaller library | `zettel bbl <bblfile> <library> <output>` | Produce a subset library containing only cited entries |
| Generate a `.bbl` file from a LaTeX `.aux` file | `zettel <auxfile> [options]` | Replace a simple `bibtex` step in a LaTeX workflow |
| Inspect one key in a library | `zettel --query <bibkey> --library <file>` | Quick human-readable lookup |

## Conversion workflows

### Convert one library file to another

If your input and output filenames already make the formats obvious, use the shortest form:

```bash
bin/zettel references.bib references.json
bin/zettel references.bib references.yml
bin/zettel references.json references.bib
```

Choose this when you simply want to move between BibTeX, JSON, and YAML and the file extensions are already correct.

This is the pattern used by:

- `examples/cli-bib2json.sh`
- `examples/cli-bib2yaml.sh`

### Convert with an explicit command

If you want the command line to explain itself more clearly, use `convert`:

```bash
bin/zettel convert references.yml references.bib --to bib
bin/zettel convert references.bib references.yml --to yaml
```

This is the better choice when:

- you are writing scripts for other people to read;
- the output format should be obvious even at a glance;
- the file extension is unusual and you need `--from`.

For example:

```bash
bin/zettel convert input.data output.yml --from json --to yaml
```

This is the pattern used by:

- `examples/cli-convert.sh`
- `examples/cli-convert_simple.sh`

### Convert one pasted BibTeX entry without touching a library

If the input is not a file but a single BibTeX entry on standard input, use `paste`:

```bash
pbpaste | bin/zettel paste --to yaml
pbpaste | bin/zettel paste --to json
```

Choose this when you want a quick format conversion for one entry and do not want to update a library file.

This is the pattern used by:

- `examples/cli-paste_conversion.sh`

## Library-maintenance workflows

### Append one pasted entry to a library

If you already have a library file and want to add one entry from standard input, `paste` can do both jobs at once:

```bash
pbpaste | bin/zettel paste --to json --library references.json
pbpaste | bin/zettel paste --library references.yml
```

Choose this when you want a lightweight append operation.

This is the pattern used by:

- `examples/cli-append_library.sh`

### Update a curated library with backups and key handling

If your goal is not merely to append, but to maintain a library carefully, use `libupdate`:

```bash
pbpaste | bin/zettel libupdate --library references.bib
pbpaste | bin/zettel libupdate --library references.yml
pbpaste | bin/zettel libupdate --library references.json --fileDir ./files
```

Choose `libupdate` instead of `paste --library` when you want the CLI to help with maintenance tasks such as:

- creating a timestamped backup;
- generating or validating the citation key;
- inserting the entry in sorted order;
- checking for likely duplicates;
- looking for nearby attachment files.

This is the pattern used by:

- `examples/zettelLibUpdate.sh`
- `examples/zettelLibUpdateYaml.sh`

## DOI workflows

### Fetch one DOI entry from a metadata source

Use `doi` when the entry should be created from a DOI rather than from BibTeX input:

```bash
bin/zettel doi 10.1038/nphys1170 --source crossref --mailto you@example.org --to yaml
bin/zettel doi 10.5281/zenodo.2553894 --source datacite --to json --output entry.json
```

Choose this when:

- the publication already has a DOI;
- you want metadata from Crossref or DataCite;
- you want the result directly as BibTeX, JSON, or YAML.

For Crossref, `--mailto` is strongly recommended for polite access.

This is the pattern used by:

- `examples/cli-fetch_doi.sh`
- `examples/cli-fetch_doi_sources.sh`

## LaTeX-oriented workflows

### Extract only the cited entries from an existing `.bbl`

Use `bbl` when you already have a `.bbl` file and want a smaller library containing only the cited entries:

```bash
bin/zettel bbl paper.bbl references.bib used.bib
bin/zettel bbl paper.bbl references.yml used.json
```

Choose this when the `.bbl` file already exists and your task is to derive a subset library from it.

This is the pattern used by:

- `examples/cli-bbl2bib.sh`

### Generate a `.bbl` file from a LaTeX `.aux`

Pass the `.aux` file itself when you want `zettel` to produce the bibliography output used by LaTeX:

```bash
bin/zettel paper.aux --library references.json --output paper.bbl --style plain
bin/zettel paper.aux --library references.yml --style alpha
```

Choose this when you want `zettel` to stand in for a simple `bibtex` step.

If you omit `--library`, `zettel` tries to resolve the library names from `\bibdata{...}` in the `.aux` file.
If you omit `--style`, `zettel` tries to read `\bibstyle{...}` from the same file.

This is the pattern used by:

- `examples/cli-tex_aux.sh`
- `examples/cli-tex_aux_opts.sh`

## Query workflow

### Look up one citation key in a library

Use `--query` when you want a concise human-readable summary for one entry:

```bash
bin/zettel --query einstein1905a --library references.bib
bin/zettel --query friedmann1922a --library references.yml
```

Choose this when you want to inspect an existing library quickly without converting or rewriting it.

This is the pattern used by:

- `examples/cli-query_bibkey.sh`

## Running the repository examples

From the repository root you can run, for example:

```bash
bash examples/cli-bib2json.sh
bash examples/cli-convert.sh
bash examples/cli-fetch_doi.sh 10.1038/nphys1170
bash examples/cli-tex_aux_opts.sh
julia --project=. examples/example-json.jl
julia --project=. examples/example-yaml.jl
```

The shell scripts are useful when you want a ready-made CLI template.
The Julia scripts are better when you want to see the corresponding API usage.
