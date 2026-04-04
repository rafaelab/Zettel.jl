# ----------------------------------------------------------------------------------------------- #
#
@doc """
	findByKey(lib, key)

Return the [`ZettelEntry`](@ref) with the given citation key, or `nothing` if not found.

# Input
- `lib::ZettelLibrary`: bibliography library to search.
- `key::AbstractString`: citation key to look for.

# Output
- The matching `ZettelEntry` or `nothing` if not found.
"""
function findByKey(lib::ZettelLibrary, key::AbstractString)
	return haskey(lib, key) ? lib[key] : nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	searchEntries(lib; field, text, caseSensitive)

Search entries in `lib` for `text`. 
If `field` is provided, only that field is searched; otherwise the key and all fields are searched. 
Returns a vector of matching entries.

# Input
- `lib::ZettelLibrary`: bibliography library to search.
- `field::Maybe{AbstractString}`: optional field name to restrict the search to.
- `text::AbstractString`: text to search for.
- `caseSensitive::Bool`: whether the search should be case-sensitive (default: `false`).

# Output
- A vector of `ZettelEntry` objects matching the search criteria.
"""
function searchEntries(lib::ZettelLibrary; field::Maybe{AbstractString} = nothing, text::AbstractString = "", caseSensitive::Bool = false)
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

# Input
- `lib::ZettelLibrary`: bibliography library to search.
- `field::AbstractString`: field name to filter by.
- `value::AbstractString`: value to match in the specified field.
- `exact::Bool`: whether to require an exact match (default: `false`).
- `caseSensitive::Bool`: whether the match should be case-sensitive (default: `false`).

# Output
- A vector of `ZettelEntry` objects where the specified field matches the given value according to the criteria.
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
	_entryMatches(entry, field, queryCmp, caseSensitive)

Helper function to check if a `ZettelEntry` matches a search query.
If `field` is provided, only that field is checked for a match.
Otherwise, the key and all fields are checked.

# Input
- `entry::ZettelEntry`: the entry to check for a match.
- `field::Maybe{AbstractString}`: optional field name to restrict the search to.
- `queryCmp::AbstractString`: the search query, already processed for case sensitivity.
- `caseSensitive::Bool`: whether the search is case-sensitive.

# Output
- `true` if the entry matches the search query according to the criteria, `false` otherwise.
"""
function _entryMatches(entry::ZettelEntry, field::Maybe{AbstractString}, queryCmp::AbstractString, caseSensitive::Bool)
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
