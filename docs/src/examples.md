# Examples: Workflows and Patterns

This guide shows common Zettel.jl workflows with both CLI and Julia API examples,
complete with actual data transformations.

## Overview

The [`examples/`](../../../examples/) folder contains:

- **CLI Scripts** (`cli-*.sh`): Command-line usage patterns
- **Julia Scripts** (`example-*.jl`): Julia REPL and script patterns
- **Sample Data** (`data/*.{bib,json,yaml}`): Example bibliography files

Each workflow below includes:
1. Problem description
2. CLI solution with explanation
3. Julia API equivalent
4. Before/after data example
5. Link to example script

---

## Workflow 1: BibTeX → JSON Conversion

**Problem**: Convert a BibTeX file to Zettel's JSON format for better compatibility.

### CLI Command

```bash
bin/zettel references.bib references.json
```

### Julia API

```julia
using Zettel

bibTeXToJson("references.bib", "references.json")
```

Or using the library functions:

```julia
using Zettel

lib = readBibTeX("references.bib")
writeJsonLibrary(lib, "references.json")
```

### Data Example

**Input** (`sample.bib`):
```bibtex
@ARTICLE{Einstein1905,
    author = {{Einstein}, A.},
    title = {Zur Elektrodynamik bewegter K{\"o}rper},
    journal = {Annalen der Physik},
    year = 1905,
    volume = {322},
    number = {10},
    pages = {891-921},
    doi = {10.1002/andp.19053221004}
}

@BOOK{Misner1973,
    author = {Misner, Charles W. and Thorne, Kip S. and Wheeler, John A.},
    title = {Gravitation},
    publisher = {W. H. Freeman},
    year = {1973},
    isbn = {978-0-7167-0344-0}
}
```

**Output** (`sample.json`):
```json
{
    "Einstein1905": {
        "entryType": "article",
        "title": "Zur Elektrodynamik bewegter K{\\\"o}rper",
        "author": [
            {
                "first": "A.",
                "last": "Einstein"
            }
        ],
        "year": "1905",
        "journal": "Annalen der Physik",
        "volume": "322",
        "number": "10",
        "pages": "891-921",
        "doi": "10.1002/andp.19053221004"
    },
    "Misner1973": {
        "entryType": "book",
        "title": "Gravitation",
        "author": [
            {
                "first": "Charles",
                "middle": "W.",
                "last": "Misner"
            },
            {
                "first": "Kip",
                "middle": "S.",
                "last": "Thorne"
            },
            {
                "first": "John",
                "middle": "A.",
                "last": "Wheeler"
            }
        ],
        "year": "1973",
        "publisher": "W. H. Freeman",
        "isbn": "978-0-7167-0344-0"
    }
}
```

**Key transformation**: Authors are parsed into structured `{ "first", "middle", "last" }` objects.

**Example script**: [`examples/cli-bib-to-json.sh`](../../../examples/cli-bib-to-json.sh)

---

## Workflow 2: Format Conversion (JSON ↔ YAML ↔ BibTeX)

**Problem**: Convert between multiple bibliography formats.

### CLI Commands

Convert JSON to YAML:
```bash
bin/zettel convert references.json references.yaml --to yaml
```

Convert YAML to BibTeX:
```bash
bin/zettel convert references.yaml references.bib --to bib
```

Convert with explicit input type (when extension is ambiguous):
```bash
bin/zettel convert data.txt output.json --from yaml --to json
```

### Julia API

```julia
using Zettel

# JSON → YAML
jsonToYaml("references.json", "references.yaml")

# YAML → BibTeX
yamlToBibTeX("references.yaml", "references.bib")

# JSON → BibTeX
jsonToBibTeX("references.json", "references.bib")

# Via library objects
lib = readJsonLibrary("references.json")
writeYamlLibrary(lib, "references.yaml")
writeBibTeX(lib, "references.bib")
```

### Data Example

**Input** (`sample.json`):
```json
{
    "Einstein1905": {
        "entryType": "article",
        "author": [{"first": "A.", "last": "Einstein"}],
        "title": "Zur Elektrodynamik bewegter Körper",
        "year": "1905",
        "journal": "Annalen der Physik"
    }
}
```

**Output** (`sample.yaml`):
```yaml
Einstein1905:
    entryType: article
    author:
        - first: A.
          last: Einstein
    title: Zur Elektrodynamik bewegter Körper
    year: "1905"
    journal: Annalen der Physik
```

**Example scripts**:
- [`examples/cli-convert-to.sh`](../../../examples/cli-convert-to.sh) — Using `--to` flag
- [`examples/cli-convert-from-to.sh`](../../../examples/cli-convert-from-to.sh) — Using `-f`/`--from` and `-t`/`--to`
- [`examples/example-yaml.jl`](../../../examples/example-yaml.jl) — Julia YAML workflows

---

## Workflow 3: Fetch DOI Metadata

**Problem**: Retrieve bibliographic data from a DOI.

### CLI Commands

Fetch from Crossref (default):
```bash
bin/zettel doi 10.1002/andp.19053221004 --mailto you@example.org --to json
```

Fetch from DataCite explicitly:
```bash
bin/zettel doi <doi> --source datacite --to yaml
```

With Crossref Metadata Plus token for higher limits:
```bash
export CROSSREF_PLUS_API_TOKEN=your-token
bin/zettel doi 10.1002/andp.19053221004 --mailto you@example.org --to json --output entry.json
```

### Julia API

```julia
using Zettel

# Fetch from Crossref
entry = fetchFromCrossref("10.1002/andp.19053221004"; mailto = "you@example.org")
println(entry)

# Fetch from DataCite
entry2 = fetchFromDataCite("<doi>")

# Fetch and save to JSON
record = fetchCrossrefJson("10.1002/andp.19053221004")
crossrefJsonToZettelJson(record, "entry.json")

# Use in a library
lib = ZettelLibrary([entry])
writeJsonLibrary(lib, "bibliography.json")
```

### Expected Output

After fetching `10.1002/andp.19053221004` (Einstein's 1905 paper):

```julia
ZettelEntry(
    key = "Einstein1905",
    entryType = "article",
    fields = OrderedDict(
        "author" => "Einstein, A.",
        "title" => "Zur Elektrodynamik bewegter Körper",
        "journal" => "Annalen der Physik",
        "year" => "1905",
        "volume" => "322",
        "number" => "10",
        "pages" => "891-921",
        "doi" => "10.1002/andp.19053221004"
    )
)
```

**Limitations**: Requires internet connectivity. Crossref recommends polite access via `--mailto` parameter.

**Example scripts**:
- [`examples/cli-crossref-doi.sh`](../../../examples/cli-crossref-doi.sh) — Basic Crossref fetch
- [`examples/cli-doi-source.sh`](../../../examples/cli-doi-source.sh) — Alternative sources

---

## Workflow 4: Paste BibTeX from Clipboard

**Problem**: Add a single BibTeX entry from clipboard without maintaining a library file.

### CLI Commands

Convert and display as JSON:
```bash
pbpaste | bin/zettel paste --to json
```

Convert and display as YAML:
```bash
pbpaste | bin/zettel paste --to yaml
```

Convert and add to existing library:
```bash
pbpaste | bin/zettel paste --to json --library references.json
```

### Julia API

```julia
using Zettel

# Paste BibTeX entry (from stdin or programmatically)
bib_entry = """
@ARTICLE{NewEntry2024,
    author = {Author, A. and Others, B.},
    title = {Example Title},
    journal = {Example Journal},
    year = {2024},
    volume = {1},
    pages = {1-10}
}
"""

# Convert to library and inspect
lib = readBibTeX(IOBuffer(bib_entry))
entry = first(values(lib))
println(entry)

# Write as JSON
writeJsonLibrary(lib, "new_entry.json")
```

### Data Example

**Clipboard input**:
```bibtex
@ARTICLE{Einstein1905,
    author = {{Einstein}, A.},
    title = {Zur Elektrodynamik bewegter Körper},
    journal = {Annalen der Physik},
    year = {1905}
}
```

**Output** (with `--to json`):
```json
{
    "Einstein1905": {
        "entryType": "article",
        "author": [{"first": "A.", "last": "Einstein"}],
        "title": "Zur Elektrodynamik bewegter Körper",
        "year": "1905",
        "journal": "Annalen der Physik"
    }
}
```

**Example scripts**:
- [`examples/cli-paste-to.sh`](../../../examples/cli-paste-to.sh) — Paste to stdout
- [`examples/cli-paste-to-library.sh`](../../../examples/cli-paste-to-library.sh) — Paste to library

---

## Workflow 5: LaTeX `.aux` → `.bbl` (BibTeX-Like Workflow)

**Problem**: Generate a bibliography from a LaTeX document using a Zettel library instead of traditional bibtex.

### CLI Commands

Basic workflow:
```bash
pdflatex paper.tex              # Generates paper.aux
bin/zettel paper.aux            # Generates paper.bbl from paper.json (auto-resolved)
pdflatex paper.tex              # Includes bibliography in PDF
```

With explicit library and output:
```bash
bin/zettel paper.aux -l references.json -o paper.bbl
```

With custom bibliography style:
```bash
bin/zettel paper.aux --style=alpha -o paper.bbl
```

### Julia API

```julia
using Zettel

# Parse the .aux file to understand what's needed
aux = parseAuxFile("paper.aux")
println("Citations: ", aux.citations)
println("Bibliography sources: ", aux.bibdata)
println("Style: ", aux.bibstyle)

# Generate .bbl file
result = writeBblFromAux(
    "paper.aux";
    libraryFiles = ["references.json"],
    outputPath = "paper.bbl",
    style = "alpha"
)
println("Used keys: ", result.usedKeys)
println("Missing keys: ", result.absent)
```

### Data Example

**Input** (`paper.aux` excerpt):
```
\citation{Einstein1905}
\citation{Misner1973}
\bibdata{references}
\bibstyle{plain}
```

**Resolved library**: `references.json` (next to `.aux`)

**Generated output** (`paper.bbl` excerpt):
```
\begin{thebibliography}{1}

\bibitem{Einstein1905}
A.~Einstein.
\newblock Zur {E}lektrodynamik bewegter {K}orper.
\newblock {\em Annalen der Physik}, 322(10):891--921, 1905.

\bibitem{Misner1973}
C.~W. Misner, K.~S. Thorne, and J.~A. Wheeler.
\newblock {\em Gravitation}.
\newblock W. H. Freeman, 1973.

\end{thebibliography}
```

**Available bibliography styles**:
`plain`, `unsrt`, `alpha`, `ieeestr`, `revtex`, `jhep`, `full`, `abntex2-num`, `abntex2-alpha`

**Example script**: [`examples/cli-tex_aux.sh`](../../../examples/cli-tex_aux.sh)

---

## Workflow 6: Reading and Querying Libraries

**Problem**: Load a library and search for specific entries.

### Julia API

```julia
using Zettel

# Load a JSON library
lib = readJsonLibrary("references.json")

# Access an entry by key
entry = lib["Einstein1905"]
println("Title: ", getTitle(entry))
println("Authors: ", getAuthors(entry))
println("Year: ", getYear(entry))

# Get all entries
for (key, entry) in pairs(lib)
    println("$(key): $(getTitle(entry))")
end

# Filter entries
physics_entries = filterByField(lib, "journal", r"Annalen|Physics")
for entry in physics_entries
    println(entry.key)
end

# Search entries
results = searchEntries(lib, r"Einstein|Misner")
for entry in results
    println("Found: $(entry.key)")
end
```

### Data Example

**Library structure** (as loaded):
```julia
lib = ZettelLibrary([
    ZettelEntry("Einstein1905", "article", ...),
    ZettelEntry("Misner1973", "book", ...)
])
```

**Query examples**:
- `findByKey(lib, "Einstein1905")` → Entry for Einstein1905
- `filterByField(lib, "year", "1905")` → All entries from 1905
- `searchEntries(lib, r"gravitation")` → Entries matching pattern (title, author, journal)

**Example script**: [`examples/example-simple.jl`](../../../examples/example-simple.jl)

---

## Quick Reference: CLI vs Julia

| Task | CLI | Julia |
|------|-----|-------|
| BibTeX → JSON | `bin/zettel in.bib out.json` | `bibTeXToJson(in, out)` |
| JSON → YAML | `bin/zettel convert in.json out.yaml --to yaml` | `jsonToYaml(in, out)` |
| Fetch DOI | `bin/zettel doi <doi> --to json` | `fetchFromCrossref(doi)` |
| Parse `.aux` | (auto in `.aux` workflow) | `parseAuxFile(path)` |
| Generate `.bbl` | `bin/zettel paper.aux` | `writeBblFromAux(auxPath)` |
| Read library | (auto) | `readJsonLibrary(path)` |
| Write library | (auto) | `writeJsonLibrary(lib, path)` |

---

## See Also

- [API Reference](api.md) — Complete function documentation
- [CLI Guide](cli.md) — Detailed CLI documentation and troubleshooting
- [`examples/` folder](../../../examples/) — Runnable scripts and sample data
