# Zettel.jl

**Zettel.jl** is a lightweight reference manager for Julia that stores bibliographic
data as JSON/YAML while maintaining full BibTeX compatibility.

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

# Cceate an entry
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

### Aux → bbl

```bash
pdflatex test.tex
bin/zettel test.aux
pdflatex test.tex
```

`bin/zettel` reads `\bibstyle{...}` from the `.aux` file by default and supports:
`plain`, `unsrt`, `alpha`, `ieeestr`, `revtex`, `jhep`, `full`, `abntex2-num`,
`abntex2-alpha`.

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
