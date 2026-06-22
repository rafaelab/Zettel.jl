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

Look up a single entry by exact citation key in the library file `filename`, returning the
matching [`ZettelEntry`](@ref) or `nothing`.

For JSON libraries this scans the entries and materialises only the matching record. 
This avoids the cost of building every entry in the file (the dominant cost of a full `loadLibrary` on a large library). 
For YAML and BibTeX libraries, where the underlying parsers offer no cheap single-record access, it falls back to loading the whole library and calling [`findByKey`](@ref).
The JSON fast path is also used as the lookup for any other format via the generic fallback, so the observable result is identical to `findByKey(loadLibrary(filename), key)` for well-formed libraries.
"""
function findEntryByKey(filename::AbstractString, key::AbstractString)
	if ! isfile(filename)
		throw(ArgumentError("File not found: $(filename)"))
	end
	return findEntryByKey(identifyBibliographyFormat(filename), filename, key)
end

findEntryByKey(::BibliographyFormat, filename::AbstractString, key::AbstractString) = findByKey(loadLibrary(filename), key)

# JSON fast path: scan records and build only the matching entry. 
# Any unexpected shape or parse problem degrades gracefully to the validated full-load path, so correctness is never worse than the generic path.
function findEntryByKey(::JsonFormat, filename::AbstractString, key::AbstractString)
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

# Compare against the raw `key` field exactly as `findByKey` does (library keys are the
# unstripped `String` of the record key). Returns the built entry on match, `nothing` otherwise.
function _matchJsonRecord(raw, key::AbstractString)
	haskey(raw, :key) || throw(ArgumentError("Entry object without a key."))
	String(raw[:key]) == key || return nothing
	return ZettelEntry(normaliseJson(raw))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	searchEntries(lib; field, text, caseSensitive)

Search entries in `lib` for `text`.
If `field` is provided, only that field is searched; otherwise the key and all fields are searched.
Returns a vector of matching entries.
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
