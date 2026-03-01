# Zettel.jl

**Zettel.jl** is a lightweight reference manager for Julia that stores bibliographic
data as JSON while maintaining full BibTeX compatibility.

## Features

- Store references in a JSON format that mirrors BibTeX fields.
- Fetch metadata automatically from [CrossRef](https://www.crossref.org/) using a DOI.
- Read and write BibTeX `.bib` files via
  [Pybtex.jl](https://github.com/rafaelab/pybtex.jl).
- Simple, consistent API following Julia conventions.

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

# Save to JSON
writeJsonLibrary(lib, "library.json")

# Save to BibTeX
writeBibTeX(lib, "library.bib")

# Fetch from CrossRef
entry2 = fetchFromCrossref("10.1002/andp.19053221004")
```
