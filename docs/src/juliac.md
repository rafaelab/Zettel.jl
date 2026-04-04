# CLI Compilation Guide (juliac)

By default, `bin/zettel` runs the CLI via the Julia interpreter, which can add startup latency on first run. With Julia **1.12+**, you can compile a native CLI executable using JuliaC (the engine behind `juliac`) for faster startup.

## Prerequisites

- Julia **1.12 or later** (ships with `juliac`)
- The Zettel package installed and working

## Build Script

The repository includes `cli/buildExecutable.jl` for compiling the CLI:

```bash
cd /path/to/Zettel.jl
julia cli/buildExecutable.jl
```

This script:
1. Activates the `cli/` environment
2. Develops the main `Zettel` package locally
3. Invokes JuliaC to build a native executable

**Output:**
- macOS/Linux: `lib/zettel`
- Windows: `lib/zettel.exe`

## How It Works

`bin/zettel` is a small launcher script. When a compiled executable is present, it runs it directly. Otherwise, it falls back to the Julia interpreter.

### Environment Variables

- `ZETTEL_EXECUTABLE`: Path to a custom compiled executable. If set, `bin/zettel` uses it.
- `ZETTEL_SYSIMAGE`: Deprecated alias for `ZETTEL_EXECUTABLE`.
- `JULIA_BIN`: Path to the Julia executable (default: `julia`).
- `JULIAC_FLAGS`: Extra flags passed to JuliaC during compilation.

### Running Without the Compiled Executable

```bash
bin/zettel --no-compile references.bib references.json
```

`--no-sysimage` is still accepted as a backward-compatible alias for `--no-compile`.

## Rebuilding After Updates

If you update the package source, rebuild the CLI executable:

```bash
julia cli/buildExecutable.jl
```

To force a clean rebuild:

```bash
rm -f lib/zettel lib/zettel.exe
julia cli/buildExecutable.jl
```

## Troubleshooting

**Compilation fails immediately**
- Ensure Julia 1.12+ is installed.
- Re-instantiate the CLI environment: `julia --project=cli -e 'using Pkg; Pkg.instantiate()'`.

**Slow startup:**
- Confirm `lib/zettel` exists and is executable.
- Run `bin/zettel --no-compile --help` to compare interpreter startup vs compiled startup.

## Optional Precompile Warmup

You can exercise common code paths before building:

```bash
julia --project=cli cli/precompile.jl
```

This is optional and can help compile frequently used methods ahead of time.
