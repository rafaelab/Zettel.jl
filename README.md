# Zettel.jl

[![CI](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml)

Simple reference manager based on JSON with BibTeX capabilities.

## Features

- Fetch JSON metadata from Crossref by DOI.
- Convert BibTeX to JSON and JSON back to BibTeX.
- BibTeX parsing/writing is handled through [Pybtex.jl](https://github.com/rafaelab/pybtex.jl).

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/rafaelab/Zettel.jl")
```

Pybtex.jl uses Python's `pybtex` package. Install it once with:

```bash
python3 -m pip install --user pybtex
```

## Usage

```julia
using Zettel

bibTeXToJson("references.bib", "references.json")
jsonToBibTeX("references.json", "references_roundtrip.bib")

record = fetchCrossrefJson("10.1038/nphys1170")
println(record["DOI"])
```

See `examples/basic.jl` for a minimal end-to-end example.
