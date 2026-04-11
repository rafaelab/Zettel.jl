# CLI Build

This repository includes a build script for a compiled `zettel` executable.

## Why build it?

Starting Julia for every CLI call adds noticeable latency, especially for short commands such as format conversion or `--help`. Building the executable reduces that overhead.

## Build command

From the repository root:

```bash
julia --project=cli cli/buildExecutable.jl
```

The build script:

- activates the `cli/` environment;
- develops the local `Zettel` package into that environment;
- invokes `JuliaC` on `cli/entrypoint.jl`;
- writes the executable to `bin/zettel` on Unix-like systems, or `bin/zettel.exe` on Windows.

## Runtime behaviour

The compiled entrypoint is not a completely separate code path. It still delegates some workloads deliberately:

- BibTeX-related commands are routed through the Julia interpreter, because they depend on the `Pybtex.jl` and Python stack.
- JSON-, YAML-, and AUX-oriented flows can run directly through the compiled executable.

This split keeps the CLI fast where possible while preserving the BibTeX functionality.

## Rebuild after source changes

If you change the source code, rebuild the executable before trusting `bin/zettel` to reflect the new behaviour.

```bash
julia --project=cli cli/buildExecutable.jl
```

That point matters in practice: if the executable is stale, repository examples and local debugging can appear inconsistent. During active development, it is often safer to use:

```bash
julia --project=. -e 'using Zettel; exit(Zettel.zettelCLI(; args = ARGS))' -- --help
```

## Optional warm-up

The repository also includes a precompile workload:

```bash
julia --project=cli cli/precompile.jl
```

This exercises common code paths before building and can improve the quality of the produced executable.

## Environment variables

- `JULIAC_FLAGS`: extra flags passed to `JuliaC` during the build.
- `JULIA_BIN`: Julia executable used by the runtime fallback path inside `cli/entrypoint.jl`.

## Troubleshooting

### The executable builds but still feels slow

Check which code path you are exercising.

- Pure JSON or YAML conversion should benefit the most from the compiled executable.
- BibTeX-heavy flows still pay interpreter and Python startup costs.

### The executable behaves differently from the current source tree

Rebuild it. The executable embeds compiled code and does not update itself automatically when `src/` changes.
