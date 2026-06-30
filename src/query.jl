export
	findByKey,
	findEntryByKey,
	searchEntries,
	filterByField


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	findByKey(lib, key)

Return the [`ZettelEntry`](@ref) with the given citation key, or `nothing` if not found.
"""
@inline findByKey(lib::ZettelLibrary, key::AbstractString) = haskey(lib, key) ? lib[key] : nothing


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	findEntryByKey(filename, key)

Look up a single entry by exact citation key in the library file `filename`, returning the matching [`ZettelEntry`](@ref) or `nothing`.

For JSON and BibTeX libraries this scans the file and materialises only the matching record.
This avoids the cost of building every entry in the file (the dominant cost of a full `loadLibrary` on a large library; for BibTeX that cost is the per-entry pybtex interop).
For BibTeX the scan locates the single `@type{key, … }` block by balanced-delimiter matching and parses only that block; if the key is absent it returns `nothing` without materialising the full library.
Unexpected JSON or matching-entry BibTeX parse failures degrade to the validated full-load path, so correctness is never worse than the generic path when the file shape is surprising.
For YAML libraries, where the underlying parser offers no cheap single-record access, it falls back to loading the whole library and calling [`findByKey`](@ref).
The result is identical to `findByKey(loadLibrary(filename), key)` for well-formed libraries.

# Input
- `filename` [`AbstractString`]: path to a library file in JSON, BibTeX or YAML format.
- `key` [`AbstractString`]: the citation key to look up.
- `type` [`BibliographyFormat`]: the format of the bibliography file.
"""
function findEntryByKey(filename::AbstractString, key::AbstractString)
	if ! isfile(filename)
		throw(ArgumentError("File not found: $(filename)"))
	end
	return findEntryByKey(identifyBibliographyFormat(filename), filename, key)
end

function findEntryByKey(::BibliographyFormat, filename::AbstractString, key::AbstractString) 
	return findByKey(loadLibrary(filename), key)
end

function findEntryByKey(::JsonFormat, filename::AbstractString, key::AbstractString)
	# JSON fast path: scan records and build only the matching entry. 
	# Any unexpected shape or parse problem degrades gracefully to the validated full-load path, so correctness is never worse than the generic path.

	result = try
		_fastJsonLookup(read(filename, String), key)
	catch
		:fallback
	end

	if result === :fallback
		return findByKey(loadLibrary(filename), key)
	end

	return result
end

function findEntryByKey(::BibtexFormat, filename::AbstractString, key::AbstractString)
	# BibTeX fast path: locate the single `@type{key, … }` block by balanced-delimiter matching and run the parser on just that block, avoiding pybtex interop over every entry in the file.
	# An absent key returns `nothing` directly because exact-key query mode should not materialise a whole library just to report a miss.

	result = try
		_fastBibtexLookup(read(filename, String), key)
	catch
		:fallback
	end

	if result === :notfound
		return nothing
	elseif result === :fallback
		return findByKey(loadLibrary(filename), key)
	end

	return result
end


function _fastJsonLookup(text::AbstractString, key::AbstractString)
	parsed = JSON3.read(text)

	if parsed isa JSON3.Object
		return _matchJsonRecord(parsed, key)
	elseif parsed isa JSON3.Array
		for raw ∈ parsed
			(raw isa JSON3.Object) || throw(ArgumentError("Not an entry object."))
			hit = _matchJsonRecord(raw, key)
			isnothing(hit) || return hit
		end
		return nothing
	end

	throw(ArgumentError("Unexpected JSON shape."))
end

function _matchJsonRecord(raw, key::AbstractString)
	haskey(raw, :key) || throw(ArgumentError("Entry object without a key."))
	String(raw[:key]) == key || return nothing
	return ZettelEntry(normaliseJson(raw))
end

function _fastBibtexLookup(text::AbstractString, key::AbstractString)
	block = _bibtexEntryBlock(text, key)
	isnothing(block) && return :notfound
	return findByKey(readBibtexLibrary(readBibtexString(block)), key)
end

function _bibtexEntryBlock(text::AbstractString, key::AbstractString)
	pattern = Regex("@[ \t]*[A-Za-z]+[ \t]*[{(][ \t\r\n]*\\Q" * key * "\\E[ \t\r\n]*,")
	m = match(pattern, text)
	isnothing(m) && return nothing

	blockStart = m.offset
	openIdx = findnext(c -> c == '{' || c == '(', text, blockStart)
	openCh = text[openIdx]
	closeCh = openCh == '{' ? '}' : ')'

	depth = 0
	idx = openIdx
	while idx ≤ lastindex(text)
		c = text[idx]
		if c == openCh
			depth += 1
		elseif c == closeCh
			depth -= 1
			if depth == 0
				return text[blockStart : idx]
			end
		end
		idx = nextind(text, idx)
	end

	throw(ArgumentError("Unbalanced BibTeX entry for key '$(key)'."))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	searchEntries(lib; field, text, caseSensitive)

Search entries in `lib` for `text`.
If `field` is provided, only that field is searched; otherwise the key and all fields are searched.
Returns a vector of matching entries.

# Input
- `lib` [`ZettelLibrary`]: the library to search.
- `field` [`AbstractString` or `Nothing`]: the field to search, or `nothing` to search all fields.
- `text` [`AbstractString`]: the text to search for.
- `caseSensitive` [`Bool`]: whether the search is case-sensitive (default: `false`).
"""
function searchEntries(lib::ZettelLibrary; field::Maybe{AbstractString} = nothing, text::AbstractString = "", caseSensitive::Bool = false)
	query = String(text)
	if isempty(query)
		return collect(values(lib))
	end

	queryCmp = caseSensitive ? query : lowercase(query)
	matches = ZettelEntry[]

	for entry ∈ values(lib)
		if entryMatches(entry, field, queryCmp, caseSensitive)
			push!(matches, entry)
		end
	end

	return matches
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	filterByField(lib, field, value; exact, caseSensitive)

Filter entries where `field` matches `value`.
When `exact` is `false`, substring matching is used.
Returns a vector of matching entries.

# Input
- `lib` [`ZettelLibrary`]: the library to search.
- `field` [`AbstractString`]: the field to search.
- `value` [`AbstractString`]: the value to match.
- `exact` [`Bool`]: whether to match exactly (default: `false`).
- `caseSensitive` [`Bool`]: whether the search is case-sensitive (default: `false`).
"""
function filterByField(lib::ZettelLibrary, field::AbstractString, value::AbstractString; exact::Bool = false, caseSensitive::Bool = false)
	target = caseSensitive ? String(value) : lowercase(String(value))
	matches = ZettelEntry[]

	for entry ∈ values(lib)
		val = getField(entry, field)
		valCmp = caseSensitive ? val : lowercase(val)
		ok = exact ? (valCmp == target) : occursin(target, valCmp)
		if ok 
			push!(matches, entry)
		end
	end

	return matches
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	entryMatches(entry, field, queryCmp, caseSensitive)

Helper function to check if an entry matches a query.
If `field` is `nothing`, the key and all fields are checked; otherwise only the specified field is checked.

# Input
- `entry` [`ZettelEntry`]: the entry to check.
- `field` [`AbstractString` or `Nothing`]: the field to check, or `nothing` to check all fields.
- `queryCmp` [`AbstractString`]: the query string, already lowercased if case-insensitive.
- `caseSensitive` [`Bool`]: whether the search is case-sensitive.

# Output
- `Bool`: `true` if the entry matches the query, `false` otherwise.
"""
function entryMatches(entry::ZettelEntry, ::Nothing, queryCmp::AbstractString, caseSensitive::Bool)
	keyCmp = caseSensitive ? entry.key : lowercase(entry.key)
	if occursin(queryCmp, keyCmp)
		return true
	end

	for val ∈ values(entry.fields)
		valCmp = caseSensitive ? val : lowercase(val)
		if occursin(queryCmp, valCmp)
			return true
		end
	end

	return false
end

function entryMatches(entry::ZettelEntry, field::AbstractString, queryCmp::AbstractString, caseSensitive::Bool)
	val = getField(entry, field)
	valCmp = caseSensitive ? val : lowercase(val)
	return occursin(queryCmp, valCmp)
end


# ----------------------------------------------------------------------------------------------- #
