# Command-Line Interface (CLI) Tutorial

This guide shows how to use **Zettel.jl** from the command line to manage bibliographic data.

## Basic Usage

The `bin/zettel` executable provides a command-line interface for common tasks:

```bash
bin/zettel [options] <input_file> [output_file]
```

### Option Flags

- `--no-sysimage`: Ignore any precompiled sysimage and run with base Julia.
- `-l`, `--library <files>`: Comma-separated list of library files (`.json`, `.yaml`, `.bib`) to load for `.aux` processing.
- `-o`, `--output <path>`: Specify the output file (alternative to positional argument).
- `--help`: Show usage information.

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

## Running Without Sysimage

If the sysimage is not present or you want to bypass it:

```bash
bin/zettel --no-sysimage references.bib references.json
```

Startup will be slower, but the result is identical.

## Environment Variables

- `ZETTEL_SYSIMAGE`: Path to a custom sysimage. If set, `bin/zettel` will use it instead of looking in `bin/`.
- `JULIA_BIN`: Path to the Julia executable (default: `julia`).

Example:

```bash
export ZETTEL_SYSIMAGE=/path/to/custom/Zettel.so
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
- Build a sysimage (see [Sysimage Generation Guide](sysimage.md)).
- Or use `--no-sysimage` to confirm the code logic is correct (then optimize with sysimage).

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
