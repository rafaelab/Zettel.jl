# Changelog


## 2.6.1 — 2026-06-29

### Performance

- `--query`: exact-key lookup on JSON libraries now scans for the requested key and builds
  only the matching entry instead of materialising the whole library. It now uses Julia's
  regex for the citation key. On a 5,000-entry synthetic bibtex file, querying one key 
  dropped from ~1,120 ms → ~0.9 ms (≈1,260× faster), returning a byte-identical entry.
  library the lookup drops from ~0.3 s to ~0.01 s (~26× faster). YAML and BibTeX libraries
  keep the full-load path.


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


## 2.5.1 — 2026-06-17

### Changed

- Add tool to convert a .bbl file to .bib.
- Improve documentation.



