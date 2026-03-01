# Zettel.jl

[![CI](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml)

Simple reference manager based on JSON with BibTeX capabilities.

## Features

- Fetch JSON metadata from Crossref by DOI.
- Convert BibTeX to JSON and JSON back to BibTeX.
- BibTeX parsing/writing is handled through [Pybtex.jl](https://github.com/rafaelab/pybtex.jl).
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaelab.github.io/Zettel.jl/dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![codecov](https://codecov.io/gh/rafaelab/Zettel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaelab/Zettel.jl)

Simple reference manager for Julia that stores bibliographic data as **JSON** while maintaining full **BibTeX** compatibility.

---

## Features

| Feature | Description |
|---|---|
| 📄 **JSON library** | Store and load references in a readable, VCS-friendly JSON format |
| 🔍 **CrossRef fetch** | Automatically retrieve metadata from [CrossRef](https://www.crossref.org/) using a DOI |
| 🔁 **BibTeX I/O** | Read and write `.bib` files via [Pybtex.jl](https://github.com/rafaelab/pybtex.jl) |
| 🧩 **BibTeX fields** | Preserves all standard BibTeX fields (`author`, `title`, `journal`, `doi`, …) |
| 💡 **Simple API** | camelCase helper functions, `@doc` docstrings, tab-indented JSON output |

---

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
julia> using Pkg
julia> Pkg.add(url="https://github.com/rafaelab/Zettel.jl")
```

> **Dependency**: Zettel.jl uses [Pybtex.jl](https://github.com/rafaelab/pybtex.jl) for
> BibTeX parsing.  The Python package `pybtex` must be available in the environment used
> by [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl) (e.g. install it with
> `pip install pybtex` or via [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl)).

---

## Quick start

```julia
using Zettel
using OrderedCollections

# ── Create an entry manually ─────────────────────────────────────────────
entry = ZettelEntry(
    "Einstein1905",
    "article",
    OrderedDict(
        "author"  => "Einstein, A.",
        "title"   => "Zur Elektrodynamik bewegter Körper",
        "journal" => "Annalen der Physik",
        "year"    => "1905",
        "volume"  => "322",
        "number"  => "10",
        "pages"   => "891-921",
        "doi"     => "10.1002/andp.19053221004",
    ),
)

lib = ZettelLibrary([entry])
println(lib)
# ZettelLibrary containing 1 entries.

# ── Fetch from CrossRef ───────────────────────────────────────────────────
entry2 = fetchFromCrossref("10.1103/PhysRev.47.777")
push!(lib, entry2)

# ── Save to JSON ──────────────────────────────────────────────────────────
writeJsonLibrary(lib, "library.json")

# ── Load from JSON ────────────────────────────────────────────────────────
lib2 = readJsonLibrary("library.json")

# ── Save to BibTeX ────────────────────────────────────────────────────────
writeBibTeX(lib, "library.bib")

# ── Load from BibTeX ─────────────────────────────────────────────────────
lib3 = readBibTeX("library.bib")
```

### JSON format

Each entry is stored as a JSON object with three top-level keys:

```json
[
    {
        "key": "Einstein1905",
        "type": "article",
        "fields": {
            "author": "Einstein, A.",
            "title": "Zur Elektrodynamik bewegter Körper",
            "journal": "Annalen der Physik",
            "year": "1905",
            "volume": "322",
            "number": "10",
            "pages": "891-921",
            "doi": "10.1002/andp.19053221004"
        }
    }
]
```

The file uses **tab characters** for indentation (one tab per nesting level).

---

## API overview

### Types

| Type | Description |
|---|---|
| `ZettelEntry` | A single bibliographic entry |
| `ZettelLibrary` | An ordered collection of entries |

### JSON I/O

| Function | Description |
|---|---|
| `readJsonLibrary(filename)` | Load a library from a JSON file |
| `writeJsonLibrary(lib, filename)` | Save a library to a JSON file |

### BibTeX I/O

| Function | Description |
|---|---|
| `readBibTeX(filename)` | Parse a `.bib` file into a `ZettelLibrary` |
| `writeBibTeX(lib, filename)` | Write a `ZettelLibrary` to a `.bib` file |
| `toBibTeX(lib)` | Convert to a `Pybtex.BibLibrary` object |
| `fromBibTeX(bibLib)` | Convert from a `Pybtex.BibLibrary` object |

### CrossRef

| Function | Description |
|---|---|
| `fetchFromCrossref(doi)` | Fetch metadata from CrossRef and return a `ZettelEntry` |

### Entry accessors

`getKey`, `getType`, `getTitle`, `getAuthors`, `getYear`, `getJournal`, `getDOI`,
`getURL`, `getVolume`, `getNumber`, `getPages`, `getAbstract`, `getPublisher`,
`getISBN`, `hasField`, `getField`, `getAllFields`

---

## Examples

See the [`examples/`](examples/) folder for runnable scripts.

---

## License

MIT © rafaelab
