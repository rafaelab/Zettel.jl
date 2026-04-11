export
	findByKey,
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
