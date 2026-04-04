# Zettel.jl

**Zettel.jl** is a lightweight reference manager for Julia that stores bibliographic
data as JSON/YAML while maintaining full BibTeX compatibility.

BibTeX parsing is handled by [Pybtex.jl](https://github.com/rafaelab/pybtex.jl), which
expects the Python package `pybtex` in the Python interpreter used by
[PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl). When using a system Python,
set `JULIA_CONDAPKG_BACKEND=Null` and `JULIA_PYTHONCALL_EXE=python`, then install
`pybtex` with `python -m pip install pybtex`.

## Features

- Store references in JSON/YAML formats that mirror BibTeX fields.
- Fetch metadata automatically from [CrossRef](https://www.crossref.org/) using a DOI.
- Read and write BibTeX `.bib` files via
  [Pybtex.jl](https://github.com/rafaelab/pybtex.jl).
- Simple, consistent API following Julia conventions.
- BibTeX-like `.aux` → `.bbl` workflow with style selection.

## Quick start

```julia
using Zettel, OrderedCollections

# Create an entry
entry = ZettelEntry(
    "Einstein1905",
    "article",
    OrderedDict(
        "author"  => "Einstein, A.",
        "title"   => "Zur Elektrodynamik bewegter Körper",
        "journal" => "Annalen der Physik",
        "year"    => "1905",
        "doi"     => "10.1002/andp.19053221004",
    ),
)

lib = ZettelLibrary([entry])

# save to JSON
writeJsonLibrary(lib, "library.json")

# save to YAML
writeYamlLibrary(lib, "library.yaml")

# save Crossref JSON in Zettel format
record = fetchCrossrefJson("10.1002/andp.19384240107")
crossrefJsonToZettelJson(record, "crossref.json")

# save to BibTeX
writeBibTeX(lib, "library.bib")

# fetch from CrossRef
entry2 = fetchFromCrossref("10.1002/andp.19053221004")
```

## CLI workflows

### BibTeX → Zettel JSON

```bash
bin/zettel references.bib references.json
```

### Convert between JSON/YAML/BibTeX

```bash
bin/zettel convert references.yaml references.json --to json
bin/zettel convert references.json references.bib --to bib
```

### Paste BibTeX from stdin

```bash
pbpaste | bin/zettel paste --to yaml
pbpaste | bin/zettel paste --to json --library references.json
```

### Aux → bbl

```bash
pdflatex test.tex
bin/zettel test.aux
pdflatex test.tex
```

`bin/zettel` reads `\bibstyle{...}` from the `.aux` file by default and supports:
`plain`, `unsrt`, `alpha`, `ieeestr`, `revtex`, `jhep`, `full`, `abntex2-num`,
`abntex2-alpha`.

For faster startup, build the optional compiled CLI with Julia >= 1.12:

```bash
julia cli/buildExecutable.jl
```

`bin/zettel` will use `lib/zettel` automatically when present. You can also
override it with `ZETTEL_EXECUTABLE=/path/to/compiled/zettel`.

## Zettel JSON format

`bibTeXToJson` and `crossrefJsonToZettelJson` emit a per-key JSON map with structured
people lists, for example:

```json
{
    "Einstein1905": {
        "entryType": "article",
        "title": "Zur Elektrodynamik bewegter Körper",
        "author": [
            { "first": "A.", "last": "Einstein" }
        ],
        "year": "1905"
    }
}
```

`readJsonLibrary` and `readYamlLibrary` accept both the per-key Zettel format and the
list-based library format produced by `writeJsonLibrary`/`writeYamlLibrary`.
