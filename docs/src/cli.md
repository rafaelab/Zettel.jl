# Command-Line Interface (CLI) Tutorial

This guide shows how to use **Zettel.jl** from the command line to manage bibliographic data.

## Basic Usage

The `bin/zettel` executable provides a command-line interface for common tasks:

```bash
bin/zettel [options] <input_file> [output_file]
```

### Option Flags
- `--no-compile`: Run via the Julia interpreter even if a compiled executable is available.
- `--no-sysimage`: Backward-compatible alias for `--no-compile`.
- `-l`, `--library <file>`: Path to a `.json`, `.yaml/.yml`, or `.bib` library (repeatable).
- `-o`, `--output <path>`: Specify the output file (alternative to positional argument).
- `-s`, `--style <name>`: Bibliography style name.
- `-f`, `--from <type>`: Input type for `convert` (optional; inferred from extension).
- `-t`, `--to <type>`: Output type for `convert` (required in `convert` mode).
- `--source <name>`: DOI metadata source in `doi` mode (`crossref` default; also supports `datacite`).
- `-m`, `--mailto <email>`: Contact email for Crossref polite requests (`doi` mode).
- `--plus-token <token>`: Crossref Metadata Plus token (`doi` mode; optional).
- `-h`, `--help`: Show usage information.

## Common Workflows

### 1. Convert BibTeX to JSON

Convert a `.bib` file to Zettel's JSON format:

```bash
bin/zettel references.bib references.json
```

**Input:** `references.bib` (standard BibTeX file)  
**Output:** `references.json` (Zettel JSON with structured author fields)

### 2. Convert BibTeX to YAML

```bash
bin/zettel references.bib references.yaml
```

YAML is human-friendly and preserves the same structure as JSON.

### 3. Convert Between Formats Explicitly

Use the `convert` subcommand with `--from` and `--to` flags:

```bash
bin/zettel convert references.json references.yaml --to yaml
bin/zettel convert references.yaml references.bib --to bib
bin/zettel convert references.bib references.json --to json
```

**Supported formats:** `json`, `yaml`, `bib`

If input or output format is ambiguous, specify it explicitly with `--from` and `--to`.

### 4. Generate Bibliography from LaTeX `.aux` File

When `pdflatex` processes a `.tex` file, it generates a `.aux` file that lists all citations:

```bash
pdflatex paper.tex
bin/zettel paper.aux -o paper.bbl -l references.json
pdflatex paper.tex  # Rerun to include the generated bibliography
```

**Process:**
1. Run `pdflatex` to generate `paper.aux` with citation keys.
2. Run `bin/zettel` with the `.aux` file and library files.
3. Zettel generates `paper.bbl` (the formatted bibliography).
4. Run `pdflatex` again to incorporate the `.bbl` into your PDF.

**Style selection:**  
By default, `bin/zettel` reads `\bibstyle{...}` from the `.aux` file (set by `bibtex` or `biblatex`). Supported styles:

- `plain` — sorted alphabetically by author (~IEEE default)
- `unsrt` — citation order (unsorted)
- `alpha` — ~IEEE author-year-key label style
- `ieeestr` — IEEE numeric labels
- `revtex` — Physics (akin to `revtex4` BibTeX style)
- `jhep` — High-energy physics (~JHEP style)
- `full` — Expanded format with all fields
- `abntex2-num` — Brazilian standard (numbered)
- `abntex2-alpha` — Brazilian standard (author-date)

Example with explicit style:

```bash
bin/zettel paper.aux -o paper.bbl -l refs.json --style=alpha
```

### 5. Batch Processing with Shell Loop

Convert multiple files in a directory:

```bash
for bib in *.bib; do
    json="${bib%.bib}.json"
    bin/zettel "$bib" "$json"
done
```

### 6. Fetch a DOI from a Source (`crossref` Default)

Fetch one DOI from Crossref (default source) and print one `ZettelEntry`:

```bash
bin/zettel doi 10.1038/nphys1170 --mailto you@example.org --to yaml
```

Fetch from DataCite explicitly:

```bash
bin/zettel doi <doi-from-datacite> --source datacite --to yaml
```

Write Crossref output directly to a file:

```bash
bin/zettel doi 10.1038/nphys1170 --mailto you@example.org --to json --output entry.json
```

## Example: Complete LaTeX Workflow

Suppose you have:
- `paper.tex` — your LaTeX document
- `references.bib` — your bibliography database

1. **Convert references to Zettel JSON (for portability):**

   ```bash
   bin/zettel references.bib references.json
   ```

2. **Edit and organize in JSON (optional):**

   Edit `references.json` if needed; the structure mirrors BibTeX but is more structured (author lists are parsed into first/last name pairs).

3. **Generate bibliography from the `.aux` file:**

   ```bash
   pdflatex paper.tex
   bin/zettel paper.aux -o paper.bbl -l references.json
   pdflatex paper.tex
   ```

4. **Convert back to BibTeX if needed:**

   ```bash
   bin/zettel convert references.json references_updated.bib --to bib
   ```

## Running Without the Compiled Executable

If the compiled executable is not present or you want to bypass it:

```bash
bin/zettel --no-compile references.bib references.json
```

Startup will be slower, but the result is identical.
`--no-sysimage` is still accepted as a backward-compatible alias.

## Environment Variables

- `ZETTEL_EXECUTABLE`: Path to a custom compiled executable. If set, `bin/zettel` will use it instead of looking in `lib/`.
- `ZETTEL_SYSIMAGE`: Deprecated alias for `ZETTEL_EXECUTABLE`.
- `JULIA_BIN`: Path to the Julia executable (default: `julia`).
- `CROSSREF_MAILTO`: Contact email used for Crossref polite access in `doi` mode.
- `CROSSREF_PLUS_API_TOKEN`: Crossref Metadata Plus token (optional, for higher limits).
- `CROSSREF_USER_AGENT`: Optional Crossref user-agent override.
- `DATACITE_USER_AGENT`: Optional DataCite user-agent override.

Example:

```bash
export ZETTEL_EXECUTABLE=/path/to/compiled/zettel
bin/zettel references.bib references.json
```

## Troubleshooting

**No `.bbl` file generated:**
- Ensure the `.aux` file exists and contains `\citation{...}` and `\bibdata{...}` entries.
- Check that the library file (`-l` option) contains the cited keys.
- Verify the format of the library file (must be `.json`, `.yaml`, or `.bib`).

**Bibliography style not recognized:**
- Check spelling and availability: `plain`, `unsrt`, `alpha`, etc.
- The style name is case-insensitive but must match exactly.

**Slow startup:**
- Build the compiled CLI (see [CLI Compilation Guide](juliac.md)).
- Or use `--no-compile` to confirm the code logic is correct (then optimize with the compiled executable).

## Julia API (from Julia REPL)

Though this is a CLI guide, these functions are also available in Julia:

```julia
using Zettel

# Convert BibTeX to JSON
readBibTeX("references.bib")

# Convert to YAML
readYamlLibrary("references.yaml")

# Generate BBL from AUX
writeBblFromAux("paper.aux"; libraryFiles = ["references.json"], outputPath = "paper.bbl")

# Use the CLI directly from Julia
zettelCLI(args = ["references.bib", "references.json"])
```

See the [API Reference](api.md) for full details.

## Example Scripts Reference

The [`examples/`](https://github.com/rafaelab/Zettel.jl/tree/main/examples/) folder contains runnable scripts demonstrating key patterns:

### CLI Scripts (`.sh`)

| Script | Purpose | Demonstrates |
|--------|---------|--------------|
| `cli-bib-to-json.sh` | Convert `.bib` to JSON | Basic format conversion |
| `cli-convert-to.sh` | Convert with `--to` flag | Explicit output type specification |
| `cli-convert-from-to.sh` | Convert with `-f`/`--from` and `-t`/`--to` | Ambiguous format handling |
| `cli-aux-with-options.sh` | `.aux` workflow with library/output/style options | `.aux` → `.bbl` generation with custom settings |
| `cli-paste-to.sh` | Paste BibTeX from stdin to JSON/YAML | Stdin input handling without library update |
| `cli-paste-to-library.sh` | Paste entry and add to library | Library update workflow with key sorting |
| `cli-crossref-doi.sh` | Fetch DOI from Crossref (default source) | Basic DOI metadata fetching |
| `cli-doi-source.sh` | Fetch DOI with `--source` option | Alternative DOI sources (e.g., DataCite) |
| `cli-tex_aux.sh` | Compile TeX, generate `.aux`, run zettel, recompile | Complete LaTeX bibliography workflow |
| `cli-help.sh` | Display CLI help | Available options and subcommands |

### Julia Scripts (`.jl`)

| Script | Purpose | Pattern |
|--------|---------|---------|
| `example-simple.jl` | Basic end-to-end workflow | ZettelEntry creation, library I/O, JSON/BibTeX conversion |
| `example-yaml.jl` | YAML-specific workflows | JSON ↔ YAML conversions, library manipulation |
| `example-json.jl` | JSON library operations | Reading/writing JSON libraries |

### Sample Data

| File | Format | Content |
|------|--------|---------|
| `data/sample.bib` | BibTeX | 2 entries (Einstein1905 article, Misner1973 book) |
| `data/sample.json` | Zettel JSON | Per-key map format with structured author fields |
| `data/sample.yaml` | Zettel YAML | YAML equivalent of sample.json |

### Running Example Scripts

```bash
# Make executable
chmod +x examples/cli-*.sh

# Run a conversion example
bash examples/cli-bib-to-json.sh

# Run a LaTeX workflow example (requires pdflatex)
bash examples/cli-tex_aux.sh

# Run a Julia example
julia examples/example-simple.jl
```

For complete workflow examples with before/after data, see [Examples Guide](examples.md).
