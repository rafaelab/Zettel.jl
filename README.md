# Zettel.jl

[![CI](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/rafaelab/Zettel.jl/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaelab.github.io/Zettel.jl/dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![codecov](https://codecov.io/gh/rafaelab/Zettel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaelab/Zettel.jl)

`Zettel.jl` is a bibliography manager for Julia centred on BibTeX, JSON, and YAML workflows.
It provides a Julia API and a command-line interface for converting libraries, fetching DOI metadata, maintaining bibliography files, and generating `.bbl` output for LaTeX.

## Features

- Read and write bibliography libraries in BibTeX, JSON, YAML.
- Convert between supported formats from the Julia API or the CLI.
- Fetch metadata from DOI providers, with Crossref and DataCite support.
- Query one entry from a library by citation key.
- Read one BibTeX entry from standard input and print or store it in another format.
- Maintain working libraries with backup creation and citation-key handling.
- Extract cited entries from an existing `.bbl` into a smaller output library.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/rafaelab/Zettel.jl")
```

BibTeX parsing and writing rely on [Pybtex.jl](https://github.com/rafaelab/pybtex.jl), which uses Python's `pybtex` package through `PythonCall.jl`.
A typical setup is:

```bash
python3 -m pip install --user pybtex
```

## Documentation

The full documentation is available at <https://rafaelab.github.io/Zettel.jl/>.

- The CLI guide explains each command and its options.
- The examples page shows which command to use for which task.
- The API reference documents the exported Julia interface.

## Repository examples

Runnable scripts are available in `examples/` for common workflows such as conversion, DOI lookup, library updates, and LaTeX integration.

## License

MIT © rafaelab
