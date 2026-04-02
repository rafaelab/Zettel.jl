# Sysimage Generation Guide

By default, `bin/zettel` uses on-demand compilation, which causes a startup delay (~1-2 seconds on first run). For faster repeated invocations, especially in CI/CD pipelines or batch workflows, you can **precompile Zettel into a sysimage**.

A [sysimage](https://docs.julialang.org/en/v1/manual/embedding/#Creating-a-system-image) is a precompiled Julia system that includes your package's compiled code, reducing startup latency to ~200–300 ms.

## Building the Sysimage

### Prerequisites

- Julia 1.9 or later
- [`PackageCompiler.jl`](https://github.com/JuliaLang/PackageCompiler.jl) (automatically installed in `bin/`)
- The main Zettel package installed and working

### Build Script

The repository includes `bin/buildExecutable.jl` for automating sysimage creation:

```bash
cd /path/to/Zettel.jl
julia bin/buildExecutable.jl
```

This script:
1. Activates the `bin/` environment
2. Installs dependencies (including `PackageCompiler.jl`)
3. Develops the main `Zettel` package locally
4. Pre-executes common Zettel workflows (precompilation)
5. Compiles everything into a platform-specific sysimage:
   - `Zettel.so` on Linux
   - `Zettel.dylib` on macOS
   - `Zettel.dll` on Windows

**Expected output:**

```
Wrote sysimage to /path/to/Zettel.jl/bin/Zettel.dylib
```

### Verification

After building, verify the sysimage is in place:

```bash
ls -lh bin/Zettel.*
```

Then test with:

```bash
time bin/zettel --help
```

Startup should now be much faster (~300 ms vs. 1-2 seconds).

## How It Works

### Precompilation File

`bin/precompile.jl` exercises common Zettel workflows to ensure methods are compiled into the sysimage:

- BibTeX → JSON conversion (`bibTeXToJson`)
- JSON ↔ YAML round-tripping
- YAML → BibTeX conversion
- `.aux` → `.bbl` bibliography generation
- CLI invocation (`zettelCLI`)

When you run `julia bin/buildExecutable.jl`, these operations are executed, and their compiled methods are frozen into the sysimage.

**Add more scenarios** if your typical workflow involves functions not covered:

```julia
# Edit bin/precompile.jl
using Zettel
# ... existing precompilation code ...
# Add your custom operations here:
someFunction(arg1, arg2, ...)
```

Then rebuild.

### Environment Setup

`bin/Project.toml` specifies dependencies for the sysimage build:

```toml
[deps]
OrderedCollections = "..."
PackageCompiler = "..."
Zettel = "..."
```

`PackageCompiler` is only needed during sysimage generation; it is not part of the runtime.

### Automatic Discovery

`bin/zettel` (the launcher script) automatically detects and uses the sysimage:

```bash
# Looks for Zettel.so / Zettel.dylib / Zettel.dll in bin/
if [ -f "$SCRIPT_DIR/Zettel.dylib" ]; then
    exec julia -J "$sysimage_path" ...
fi
```

Override with the `ZETTEL_SYSIMAGE` environment variable:

```bash
export ZETTEL_SYSIMAGE=/custom/path/to/Zettel.so
bin/zettel references.bib references.json
```

## Rebuilding After Updates

If you update the Zettel package source, rebuild the sysimage to include new features:

```bash
julia bin/buildExecutable.jl
```

The old sysimage will be overwritten.

### Clean Rebuild

To force a complete rebuild (without any caching):

```bash
rm bin/Zettel.*
julia bin/buildExecutable.jl
```

## Troubleshooting

### "PackageCompiler not found" Error

Ensure `bin/Project.toml` lists `PackageCompiler` and the UUID matches the Julia registry:

```toml
[deps]
PackageCompiler = "9b87118b-4619-50d2-8e1e-99f35a4d4d9d"
```

Then instantiate the environment:

```bash
julia --project=bin -e 'using Pkg; Pkg.instantiate()'
```

### Sysimage Building Fails

Check for:
1. **Memory:** sysimage building is memory-intensive; ensure ~2–4 GB free RAM.
2. **Precompile errors:** If `bin/precompile.jl` fails, debug by running it directly:
   ```bash
   julia --project=bin bin/precompile.jl
   ```
3. **Dependency issues:** Update and resolve `bin/Manifest.toml`:
   ```bash
   julia --project=bin -e 'using Pkg; Pkg.resolve()'
   ```

### Sysimage is Not Used

Verify the sysimage file exists and `bin/zettel` can find it:

```bash
ls -lh bin/Zettel.*
file bin/Zettel.dylib  # Should be a dylib or shared library
```

Check the launcher script `bin/zettel` is sourcing the correct paths.

## Performance Impact

**Before sysimage:**
```bash
$ time bin/zettel --help
Zettel CLI tool ...

real    0m1.847s
user    0m1.234s
sys     0m0.456s
```

**After sysimage:**
```bash
$ time bin/zettel --help
Zettel CLI tool ...

real    0m0.289s
user    0m0.178s
sys     0m0.089s
```

**Speedup:** ~6–7× faster startup.

## Development Workflow

During development, you may want to use Julia source directly without rebuilding the sysimage each time:

```bash
bin/zettel --no-sysimage references.bib references.json
```

Once satisfied, rebuild the sysimage:

```bash
julia bin/buildExecutable.jl
```

Then use the optimized version in production.

## CI/CD Integration

If distributing Zettel in CI/CD, include the prebuilt sysimage:

```yaml
# Example GitHub Actions
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
        with:
          version: '1.9'
      - run: julia bin/buildExecutable.jl
      - uses: actions/upload-artifact@v2
        with:
          name: zettel-sysimage
          path: bin/Zettel.so
```

Users can then extract and use `bin/zettel` with the prebuilt sysimage immediately.

## Further Reading

- [PackageCompiler.jl Documentation](https://julialang.github.io/PackageCompiler.jl/stable/)
- [Julia System Images](https://docs.julialang.org/en/v1/manual/embedding/#Creating-a-system-image)
- [Zettel CLI Guide](cli.md)
