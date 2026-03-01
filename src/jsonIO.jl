# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_indentJson(json, indent)

Post-process a JSON string to replace groups of leading spaces on each line with the
given `indent` string (typically `"\\t"`).

JSON3 always emits spaces, so this function converts the indentation to tabs after the
fact.  String contents that happen to start with spaces are not affected because the
replacement only targets leading whitespace.
"""
function _indentJson(json::AbstractString; indent::AbstractString = "\t")
	lines = split(json, '\n')
	result = String[]
	for line ∈ lines
		m = match(r"^( +)", line)
		if isnothing(m)
			push!(result, line)
		else
			nSpaces = length(m.captures[1])
			nTabs = nSpaces ÷ 4
			push!(result, indent ^ nTabs * line[nSpaces + 1 : end])
		end
	end
	return join(result, '\n')
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_entryToOrderedDict(entry)

Convert a `ZettelEntry` to an `OrderedDict` suitable for JSON serialisation.
The layout is:
```
{
    "key": "...",
    "type": "...",
    "fields": { ... }
}
```
"""
function _entryToOrderedDict(entry::ZettelEntry)
	d = OrderedDict{String, Any}()
	d["key"] = entry.key
	d["type"] = entry.entryType
	d["fields"] = OrderedDict{String, String}(entry.fields)
	return d
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_entryFromDict(d)

Reconstruct a `ZettelEntry` from a plain dictionary obtained by JSON parsing.
"""
function _entryFromDict(d)
	key = String(d["key"])
	entryType = String(d["type"])
	fields = OrderedDict{String, String}()
	
	for (k, v) ∈ d["fields"]
		fields[String(k)] = String(v)
	end

	return ZettelEntry(key, entryType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeJsonLibrary(lib, filename)

Serialise a [`ZettelLibrary`](@ref) to a JSON file at `filename`.

The file uses tab characters for indentation (one tab per nesting level).  Each entry is
stored as an object with `"key"`, `"type"`, and `"fields"` properties that mirror the
corresponding BibTeX fields.
"""
function writeJsonLibrary(lib::ZettelLibrary, filename::AbstractString)
	records = [_entryToOrderedDict(e) for e ∈ values(lib)]
	buf = IOBuffer()
	JSON3.pretty(buf, records, JSON3.AlignmentContext(indent = 4))
	jsonStr = _indentJson(String(take!(buf)))
	write(filename, jsonStr)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readJsonLibrary(filename)

Read a JSON file previously written by [`writeJsonLibrary`](@ref) and return a
[`ZettelLibrary`](@ref).
"""
function readJsonLibrary(filename::AbstractString)
	data = JSON3.read(read(filename, String))
	entries = ZettelEntry[_entryFromDict(d) for d ∈ data]
	return ZettelLibrary(entries)
end


# ----------------------------------------------------------------------------------------------- #
#
