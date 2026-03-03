# ----------------------------------------------------------------------------------------------- #
#
@doc """
	findByKey(lib, key)

Return the [`ZettelEntry`](@ref) with the given citation key, or `nothing` if not found.
"""
function findByKey(lib::ZettelLibrary, key::AbstractString)
	return haskey(lib, key) ? lib[key] : nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	searchEntries(lib; field, text, caseSensitive)

Search entries in `lib` for `text`. If `field` is provided, only that field is searched; otherwise the key and all fields are searched. 
Returns a vector of matching entries.
"""
function searchEntries(lib::ZettelLibrary; field::Union{Nothing, AbstractString} = nothing, text::AbstractString = "", caseSensitive::Bool = false)
	query = String(text)
	if isempty(query)
		return collect(values(lib))
	end

	queryCmp = caseSensitive ? query : lowercase(query)
	matches = ZettelEntry[]

	for entry ∈ values(lib)
		if _entryMatches(entry, field, queryCmp, caseSensitive)
			push!(matches, entry)
		end
	end

	return matches
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	filterByField(lib, field, value; exact, caseSensitive)

Filter entries where `field` matches `value`. When `exact` is `false`, substring matching is used. 
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
function _entryMatches(entry::ZettelEntry, field::Union{Nothing, AbstractString}, queryCmp::AbstractString, caseSensitive::Bool)
	if ! isnothing(field)
		val = getField(entry, field)
		valCmp = caseSensitive ? val : lowercase(val)
		return occursin(queryCmp, valCmp)
	end

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


# ----------------------------------------------------------------------------------------------- #
