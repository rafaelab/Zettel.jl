# Zettel.jl

[![CI](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaelab.github.io/Zettel.jl/dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![codecov](https://codecov.io/gh/rafaelab/Zettel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaelab/Zettel.jl)

Simple reference manager for Julia that stores bibliographic data as **JSON/YAML** while maintaining full **BibTeX** compatibility.
It creates a new type, `ZettelEntry`, which is essentially equivalent to BibTeX, but in JSON/YAML, for performance.

---

## Features

| Feature | Description |
|---|---|
| 📄 **JSON/YAML library** | Store and load references in readable, VCS-friendly JSON or YAML |
| 🔍 **CrossRef fetch** | Automatically retrieve metadata from [CrossRef](https://www.crossref.org/) using a DOI |
| 🔁 **BibTeX I/O** | Read and write `.bib` files via [Pybtex.jl](https://github.com/rafaelab/pybtex.jl) |
| 🧭 **Query helpers** | Search and filter entries in a `ZettelLibrary` |
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
bibTeXToYaml("references.bib", "references.yaml")
yamlToBibTeX("references.yaml", "references_roundtrip.bib")

record = fetchCrossrefJson("10.1038/nphys1170")
println(record["DOI"])

crossrefJsonToZettelJson(record, "crossref.json")
```

See `examples/basic.jl` for a minimal end-to-end example.
See `examples/yaml_basic.jl` and `examples/yaml_aux_workflow.tex` for YAML-specific workflows.

> **Dependency**: Zettel.jl uses [Pybtex.jl](https://github.com/rafaelab/pybtex.jl) for
> BibTeX parsing.  The Python package `pybtex` must be available in the Python
> interpreter used by [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl).
> When using a system Python, set `JULIA_CONDAPKG_BACKEND=Null` and
> `JULIA_PYTHONCALL_EXE=python`, then install `pybtex` with `python -m pip install pybtex`.

---

## CLI workflows

### BibTeX → Zettel JSON

Convert a `.bib` file to Zettel JSON (per-key map with structured people):

```bash
bin/zettel references.bib references.json
```

### BibTeX-like workflow (aux → bbl)

Zettel can replace `bibtex` for a simple BibTeX-style workflow that reads citation keys
from `.aux` files and writes a `.bbl` file using a `ZettelLibrary`:

```bash
pdflatex test.tex
bin/zettel test.aux
pdflatex test.tex
```

By default, `zettel` reads `\\bibdata{...}` from `test.aux` and resolves each name to
`name.json` (preferred), `name.yaml`, `name.yml`, or `name.bib` next to the `.aux` file. You can also pass explicit
library files:

```bash
bin/zettel test.aux --library references.json
```

Styles:

`zettel` uses the style from `\\bibstyle{...}` in the `.aux` file by default.
You can override it with `--style <name>`.

Available styles: `plain`, `unsrt`, `alpha`, `ieeestr`, `revtex`, `jhep`,
`full`, `abntex2-num`, `abntex2-alpha`.

For faster startup, build the optional sysimage with:

```bash
julia sysimage/build_sysimage.jl
```

`bin/zettel` will use `sysimage/Zettel.*` automatically when present. You can also
override it with `ZETTEL_SYSIMAGE=/path/to/sysimage`.

Options:

```text
-l, --library <file>   Path to a .json, .yaml/.yml, or .bib library (repeatable)
-o, --output <file>    Output .bbl path (default: <auxfile>.bbl)
-s, --style <name>     Bibliography style (default: auto -> \\bibstyle{...} or plain)
-f, --from <type>      Input type for convert mode (optional: infer from extension)
-t, --to <type>        Output type for convert mode (mandatory in convert mode)
```

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

### Library JSON format

`writeJsonLibrary` and `readJsonLibrary` store a library as a list of entries:

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

### Zettel JSON format

`bibTeXToJson` and `crossrefJsonToZettelJson` use a per-key map with structured people:

```json
{
    "Einstein1905": {
        "entryType": "article",
        "title": "Zur Elektrodynamik bewegter Körper",
        "author": [
            { "first": "A.", "last": "Einstein" }
        ],
        "year": "1905",
        "journal": "Annalen der Physik",
        "volume": "322",
        "pages": "891-921"
    }
}
```

The file uses **4-space indentation**. Collaboration fields are emitted as a list of
objects with a single `"name"` key.

`readJsonLibrary` accepts both formats.

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
| `crossrefJsonToZettelJson(record, filename)` | Write a Crossref work message to Zettel JSON |
| `bibTeXToJson(input, output)` | Convert BibTeX to Zettel JSON |
| `jsonToBibTeX(input, output)` | Convert Zettel JSON to BibTeX |
| `readYamlLibrary(filename)` | Load a library from a YAML file |
| `writeYamlLibrary(lib, filename)` | Save a library to a YAML file |
| `bibTeXToYaml(input, output)` | Convert BibTeX to Zettel YAML |
| `yamlToBibTeX(input, output)` | Convert Zettel YAML to BibTeX |
| `yamlToJson(input, output)` | Convert YAML bibliography to JSON |
| `jsonToYaml(input, output)` | Convert JSON bibliography to YAML |

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
| `fetchCrossrefJson(doi)` | Fetch a Crossref work message |

### Entry accessors

`getKey`, `getType`, `getTitle`, `getAuthors`, `getYear`, `getJournal`, `getDOI`,
`getURL`, `getVolume`, `getNumber`, `getPages`, `getAbstract`, `getPublisher`,
`getISBN`, `hasField`, `getField`, `getAllFields`

### Query helpers

`findByKey`, `searchEntries`, `filterByField`

---

## Examples

See the [`examples/`](examples/) folder for runnable scripts.

---

## License

MIT © rafaelab
### Format conversion mode

Use `convert` mode to convert between JSON, YAML, and BibTeX:

```bash
bin/zettel convert references.yaml references.json --to json
bin/zettel convert references.json references.bib --to bib
bin/zettel convert references.bib references.yaml --to yaml
```

`--from` is optional and inferred from the input extension by default:

```bash
bin/zettel convert in.dat out.yaml --from json --to yaml
```
