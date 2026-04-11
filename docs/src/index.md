# Zettel.jl

`Zettel.jl` is a lightweight bibliography manager for Julia. It reads and writes BibTeX, JSON, and YAML libraries, fetches DOI metadata, and can generate `.bbl` files directly from LaTeX `.aux` files.

## Features

- Read and write `.bib`, `.json`, `.yaml`, and `.yml` libraries.
- Convert between formats with either the Julia API or the CLI.
- Fetch one bibliographic entry from DOI metadata sources such as Crossref and DataCite.
- Update an existing library from a pasted BibTeX entry with automatic key generation and backup creation.
- Generate `.bbl` files from `.aux` files without calling BibTeX.

## Dependency note

BibTeX parsing and writing rely on [Pybtex.jl](https://github.com/rafaelab/pybtex.jl), which in turn uses the Python package `pybtex` through `PythonCall.jl`.

If you use a system Python, a typical setup is:

```bash
export JULIA_CONDAPKG_BACKEND=Null
export JULIA_PYTHONCALL_EXE=python
python -m pip install pybtex
```

## Quick Start

### Julia API

```julia
using OrderedCollections
using Zettel

entry = ZettelEntry(
	"einstein1905a",
	"article",
	OrderedDict(
		"author" => "Einstein, A.",
		"title" => "Zur Elektrodynamik bewegter Körper",
		"journal" => "Annalen der Physik",
		"year" => "1905",
		"doi" => "10.1002/andp.19053221004",
	),
)

lib = ZettelLibrary([entry])

writeJsonLibrary(lib, "references.json")
writeYamlLibrary(lib, "references.yml")
writeBibtexLibrary(lib, "references.bib")

sameLib = loadLibrary("references.json")
```

### Format conversion

```julia
using Zettel

bibtexToJson("references.bib", "references.json")
jsonToYaml("references.json", "references.yml")
yamlToBibtex("references.yml", "references_roundtrip.bib")
```

### Fetch one DOI entry

```julia
using Zettel

entry = fetchFromDoiSource(
	"10.1002/andp.19053221004";
	source = "crossref",
	mailto = "you@example.org",
)

println(entry)
```

### Generate a `.bbl` from a LaTeX `.aux`

```julia
using Zettel

writeBblFromAux(
	"paper.aux";
	libraryFiles = ["references.json"],
	outputPath = "paper.bbl",
	style = "plain",
)
```

## CLI Quick Start

During development inside this repository, the most reliable entry point is the Julia command below, because it always uses the current source tree:

```bash
julia --project=. -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' -- --help
```

If you have built the executable, you can also use:

```bash
bin/zettel --help
```

Common CLI tasks:

```bash
# simple two-file conversion
bin/zettel references.bib references.json

# explicit conversion mode
bin/zettel convert references.json references.yml --to yaml

# fetch one DOI entry
bin/zettel doi 10.1038/nphys1170 --source crossref --mailto you@example.org --to yaml

# paste one BibTeX entry from stdin
pbpaste | bin/zettel paste --to json

# update an existing library from one pasted BibTeX entry
pbpaste | bin/zettel libupdate --library references.yml

# generate a .bbl from an .aux file
bin/zettel paper.aux --library references.json --output paper.bbl --style plain
```

## JSON and YAML Library Shape

`writeJsonLibrary` and `writeYamlLibrary` serialise a library as a list of entry objects with three top-level keys: `key`, `type`, and `fields`.

### JSON

```json
[
	{
		"key": "einstein1905a",
		"type": "article",
		"fields": {
			"author": ["Einstein, A."],
			"title": "Zur Elektrodynamik bewegter Körper",
			"journal": "Annalen der Physik",
			"year": "1905"
		}
	}
]
```

### YAML

```yaml
- key: "einstein1905a"
  type: "article"
  fields:
    author:
      - "Einstein, A."
    title: "Zur Elektrodynamik bewegter Körper"
    journal: "Annalen der Physik"
    year: "1905"
```

Internally, a [`ZettelEntry`](@ref) still stores person-like fields such as `author` and `collaboration` as BibTeX-style strings joined by ` and `. The JSON and YAML writers expand those fields back to arrays for readability.

## Main Entry Points

- [`ZettelEntry`](@ref), [`ZettelLibrary`](@ref)
- [`loadLibrary`](@ref), [`saveLibrary`](@ref)
- [`readBibtexString`](@ref), [`readJsonString`](@ref), [`readYamlString`](@ref)
- [`writeBibtexLibrary`](@ref), [`writeJsonLibrary`](@ref), [`writeYamlLibrary`](@ref)
- [`fetchFromDoiSource`](@ref)
- [`writeBblFromAux`](@ref)
- [`zettelCLI`](@ref)

## Further Reading

- [CLI Guide](cli.md)
- [Examples](examples.md)
- [CLI Build](juliac.md)
- [API Reference](api.md)
