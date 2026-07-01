# Changelog



---
## 2.6.4 — 2026-07-01

### Added
- Single-reference extraction helpers in `tools/` are now wired into the CLI so exact-key operations
  no longer parse the whole library. `tools/extractEntry KEY FILE` pulls one entry out of a `.bib`
  (perl), `.json` (`jq`), or `.yaml`/`.yml` (`yq`) file by exact citation key; the Julia side wraps
  them in `extractEntryWithTool` / `extractRawEntry` (`src/extract.jl`).
- `ZETTEL_TOOLS_DIR` environment variable to point at the `tools/` directory when the package is
  relocated or run from a compiled binary. Defaults to `tools/` next to the package source.

### Changed
- `--query <bibkey>` for `.bib` and `.yaml`/`.yml` libraries now extracts and parses **only** the
  requested entry via `tools/extractEntry`, instead of building every entry in the file. For BibTeX
  this avoids pybtex interop over the whole library; the in-process balanced-delimiter scan remains
  as an authoritative fallback (it also covers paren-delimited entries the extractor skips). JSON
  queries keep their existing in-process fast path. Results are unchanged.
- `zettel bbl <bbl> <master.bib> <out>` (`writeBibFromBbl`) now reads a BibTeX master once and parses
  **only** the cited entries in a single pass, rather than parsing the entire master library. JSON and
  YAML masters keep the cheap full-load. Output, citation order, and the missing-key report are
  unchanged.
- Every tool-backed path degrades gracefully: a missing interpreter (`perl`/`jq`/`yq`), a missing
  script, or unexpected output falls back to the validated full-load path, so behaviour is never worse
  than before.

### Fixed
- `tools/extractYamlEntry.sh` never matched a key: the `$1` in `select(.key == "$1")` was single-quoted
  and passed literally to `yq`. It now passes the key through the environment and uses `strenv`.
- The `tools/extractEntry` dispatcher and its helper scripts are now marked executable.

### Changed
- Encoding direction is now explicit: BibTeX uses TeX escapes, while JSON and YAML use plain UTF-8.
  The ampersand follows this rule — `\&` in BibTeX decodes to `&` in JSON/YAML, and `&` re-encodes to
  `\&` on BibTeX output — so journals such as `A&A` and `&` inside URLs/links round-trip losslessly.
- `decodeTex` no longer breaks down when grouping braces or whitespace surround a macro:
  `{{\'a}}` and `{ \'a }` decode to `á`, and no-argument letter macros decode regardless of a trailing
  `{}` or wrapping braces (`\l`, `\l{}`, `{\l}` → `ł`; likewise `\ss`, `\ae`, …). Journal macros
  such as `\aap`/`\apj` are left intact for later expansion.
- Long-running operations (parsing/building/writing libraries, `.bbl` extraction) now show a single
  `ProgressMeter` progress bar that updates in place, instead of repeating the same log line. The
  `reportTotal`/`reportProgress` helpers wrap a `ProgressMeter.Progress` object.
- `paste` help now documents that `--library <file.json>` inserts a pasted BibTeX entry into a
  `.json`/`.yaml` library, converting it to the library's format on the way in.
  - Removed `conversions.jl` and the six thin wrapper functions it exported
  (`bibtexToJson`, `jsonToBibtex`, `bibtexToYaml`, `yamlToBibtex`, `yamlToJson`,
  `jsonToYaml`). All callers (tests, examples, docs, precompile script) now call
  `convertBibliography(input, output, FromFormat(), ToFormat())` directly.
- `encoding.jl`: removed ~110 explicit per-letter accent entries from `tex2utf8` (acute,
  grave, circumflex, diaeresis, tilde, macron, caron, breve, double-acute, ogonek, dot-above,
  cedilla). Those entries exactly duplicated what the generic combining-mark engine
  (`_decodeAccentMacro` / `_encodeAccentFallback`) already computes, so all accented letters
  now route through that engine in both directions. The table retains only the non-derivable
  entries: no-argument letter macros/ligatures (`\ss`, `\l`, `\ae`, …), `\textasciitilde`,
  and punctuation. Removed the separate dotless-i/j pass in `decodeTex` (already covered by
  the no-arg macro loop). File shrinks from 375 → 266 lines; all 351 encoding tests pass.
- Split `src/cli.jl` (1,220 lines) into focused subfiles under a new `src/cli/` directory.
  `cli.jl` is now just six `include` lines:
  - `cli/usage.jl` — `usageCLI` help text
  - `cli/dispatch.jl` — `zettelCLI` entry point and argument dispatch, `isPossibleDoiInvocation`
  - `cli/commands.jl` — all `run*CLI` subcommand handlers (doi, query, bbl, convert, paste, libupdate, aux)
  - `cli/render.jl` — entry rendering for stdout (`renderDoiEntry`, `renderQueriedEntry`, `renderPastedEntry`, and query helpers)
  - `cli/libraryMutation.jl` — `addEntriesToLibrary` and the JSON text-splice helpers
  - `cli/terminal.jl` — interactive TTY prompts (`chooseKeyFromTty`, `acceptFileKeyFromTty`)

### Additions
- `externalauthor` and `collaborationauthor` are now treated like `author`/`collaboration`: they hold a
  list/vector in JSON/YAML and the internal `… and …` form in BibTeX.
- Added `ProgressMeter` as a dependency (the 2.6.2 changelog mentioned it, but it had not actually been
  added or wired up).


---
## 2.6.2 — 2026-06-30

### Performance

- `--query`: exact-key lookup on JSON libraries now scans for the requested key and builds
  only the matching entry instead of materialising the whole library. It now uses Julia's
  regex for the citation key. On a 5,000-entry synthetic bibtex file, querying one key 
  dropped from ~1,120 ms → ~0.9 ms (≈1,260× faster), returning a byte-identical entry.
  library the lookup drops from ~0.3 s to ~0.01 s (~26× faster). YAML and BibTeX libraries
  keep the full-load path.
- `decodeTex`: precompute sorted TeX key list once (`_tex2utf8SortedKeys`) instead of re-sorting on every call.
- `encodeTex`: reference the module constant `utf8ToTex` directly, dropping the per-call `isdefined`/`getfield` fallback.
- `orderFields!`: precompute lowercased default field order (`_preferredFieldOrderLower`); skip reallocation when the default order is used.
- BibTeX name parsing: one Python round-trip per person (`str(person)`) instead of five attribute accesses.

### Changed
- `utf8ToTex` was never bound (a `return` inside its top-level `begin` block); the dropped `encodeTex` guard had been masking this. Replaced `return d` with `d`.
- BibTeX accent macros requiring braces (e.g. `\v{S}` → Š) were mangled because the name helper stripped grouping braces; now uses `str(person)`, which preserves them, via `parseBibtexPerson`.
- Display status of tasks during long operations.

### Additions
- Added `examples/runAll` to run all examples at once.


---
## 2.6.1 — 2026-06-29

### Performance

- `--query`: exact-key lookup on JSON libraries now scans for the requested key and builds
  only the matching entry instead of materialising the whole library. It now uses Julia's
  regex for the citation key. On a 5,000-entry synthetic bibtex file, querying one key 
  dropped from ~1,120 ms → ~0.9 ms (≈1,260× faster), returning a byte-identical entry.
  library the lookup drops from ~0.3 s to ~0.01 s (~26× faster). YAML and BibTeX libraries
  keep the full-load path.

---
## 2.6.0 — 2026-06-22

### Performance

- `libupdate`: duplicate detection now skips the expensive per-entry similarity scoring
  (title Levenshtein distance and Unicode normalisation) for any entry whose year cannot
  match the pasted entry. A duplicate is only ever reported on an exact, non-empty year
  match, so the result is unchanged. On a 20k-entry library the duplicate scan drops from
  ~3.6 s to ~0.1 s (~33× faster, ~35× fewer allocations).
- `--query`: exact-key lookup on JSON libraries now scans for the requested key and builds
  only the matching entry instead of materialising the whole library. On a 20k-entry JSON
  library the lookup drops from ~0.3 s to ~0.01 s (~26× faster). YAML and BibTeX libraries
  keep the full-load path.
- `paste`/`libupdate`: sort the library in place (`sort!`) before saving instead of
  allocating a sorted copy.

### Added

- `findEntryByKey(filename, key)`: exact citation-key lookup that uses the JSON fast path
  where available and falls back to a full load for YAML/BibTeX libraries.

### Changed

- CLI routing: the `bbl` subcommand only uses the BibTeX/Python interpreter fallback when a
  `.bib` file is actually involved; `.bib`-free conversions (e.g. JSON → YAML) now run on the
  fast compiled path.
- Expanded the CLI precompile workload to exercise `--query`, the `bbl` subcommand, and the
  library-mutating `paste --library` / `libupdate` paths.


---
## 2.5.1 — 2026-06-17

### Changed

- Add tool to convert a .bbl file to .bib.
- Improve documentation.



