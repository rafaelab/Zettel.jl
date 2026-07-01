# ----------------------------------------------------------------------------------------------- #
#
# Single-reference extraction via the `tools/extractEntry` helpers.
#
# These helpers shell out to `tools/extractEntry`, which pulls one raw entry out of a bibliography
# file by exact citation key (perl for BibTeX, `jq` for JSON, `yq` for YAML) without materialising
# the whole library. They are used to accelerate exact-key lookups in the CLI. Every function here
# is best-effort: any missing interpreter, missing script, or unexpected output degrades to a
# `:unavailable` result so that callers can fall back to the validated full-load path. Correctness
# is therefore never worse than the generic path.
#


# ----------------------------------------------------------------------------------------------- #
#
# Location of the `tools/` directory captured at include time (`src/../tools`). Overridable at
# runtime with `ZETTEL_TOOLS_DIR` so a relocated/compiled deployment can point at a shipped copy.
const _defaultToolsDir = normpath(joinpath(@__DIR__, "..", "tools"))


@doc """
	zettelToolsDir()

Return the directory holding the `extractEntry` helper scripts.
Defaults to `tools/` next to the package source; override with the `ZETTEL_TOOLS_DIR`
environment variable.
"""
function zettelToolsDir()
	override = strip(get(ENV, "ZETTEL_TOOLS_DIR", ""))
	return isempty(override) ? _defaultToolsDir : String(override)
end


# ----------------------------------------------------------------------------------------------- #
#
# Command-line interpreter each format's extractor depends on.
@inline _toolInterpreter(::BibtexFormat) = "perl"
@inline _toolInterpreter(::JsonFormat)   = "jq"
@inline _toolInterpreter(::YamlFormat)   = "yq"


@doc """
	extractionAvailable(format)

Return `true` when `tools/extractEntry` can run for `format`: the dispatcher script exists and both
`bash` and the format's interpreter (`perl`/`jq`/`yq`) are on the `PATH`.
"""
function extractionAvailable(format::BibliographyFormat)
	isfile(joinpath(zettelToolsDir(), "extractEntry")) || return false
	isnothing(Sys.which("bash")) && return false
	return ! isnothing(Sys.which(_toolInterpreter(format)))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	extractRawEntry(filename, key)

Run `tools/extractEntry key filename` and return its raw stdout (the single matching record in the
file's own format), or `nothing` if the tool fails to run. An empty string means the tool ran but
matched nothing.
"""
function extractRawEntry(filename::AbstractString, key::AbstractString)
	script = joinpath(zettelToolsDir(), "extractEntry")
	return try
		out = IOBuffer()
		run(pipeline(`bash $script $key $filename`; stdout = out, stderr = devnull))
		String(take!(out))
	catch
		nothing
	end
end


# ----------------------------------------------------------------------------------------------- #
#
# Parse a single raw extracted record into a `ZettelEntry` using the format's normal string reader.
_parseExtractedEntry(::BibtexFormat, raw::AbstractString, key::AbstractString) = findByKey(readBibtexLibrary(readBibtexString(raw)), key)
_parseExtractedEntry(::JsonFormat,   raw::AbstractString, key::AbstractString) = findByKey(readJsonLibrary(readJsonString(raw)), key)
_parseExtractedEntry(::YamlFormat,   raw::AbstractString, key::AbstractString) = findByKey(readYamlLibrary(readYamlString(raw)), key)


@doc """
	extractEntryWithTool(format, filename, key)

Extract and parse a single entry from `filename` by exact `key` using `tools/extractEntry`.

Returns either the matching [`ZettelEntry`](@ref), or `:unavailable` when the tool could not run,
matched nothing, or produced output that failed to parse. `:unavailable` is deliberately used for a
non-match too: the extractors do not cover every document shape (the BibTeX helper only recognises
brace-delimited entries), so callers must confirm a miss on the authoritative full/in-process path
rather than trust an empty result. This keeps correctness identical to the generic path.
"""
function extractEntryWithTool(format::BibliographyFormat, filename::AbstractString, key::AbstractString)
	extractionAvailable(format) || return :unavailable

	raw = extractRawEntry(filename, key)
	(isnothing(raw) || isempty(strip(raw))) && return :unavailable

	entry = try
		_parseExtractedEntry(format, raw, key)
	catch
		nothing
	end

	return isnothing(entry) ? :unavailable : entry
end


# ----------------------------------------------------------------------------------------------- #
