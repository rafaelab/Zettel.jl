export
	readJsonFile,
	readJsonString,
	readJsonEntry,
	readJsonLibrary,
	writeJsonLibrary


# ----------------------------------------------------------------------------------------------- #
#
const tabSizeJson = 4

const _extensionsJson = ("json",)

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	indentJson(text; tabSize = 4)

Re-indent pretty JSON output with tabs (JSON3 always uses spaces).
"""
function indentJson(text::AbstractString; tabSize::Int = tabSizeJson)
	lines = split(text, '\n')
	tabIndented = String[]
	for line ∈ lines
		m = match(r"^( +)", line)
		if isnothing(m)
			push!(tabIndented, line)
		else
			nSpaces = length(m.captures[1])
			nTabs = nSpaces ÷ tabSize
			push!(tabIndented, "\t" ^ nTabs * line[nSpaces + 1 : end])
		end
	end
	return join(tabIndented, '\n')
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	normaliseJson(value)

Convert JSON3 objects / arrays into plain Julia Dict / Vector containers.
"""
normaliseJson(value::Any) = value

function normaliseJson(value::AbstractDict)
	out = OrderedDict{String, Any}()
	for (k, v) ∈ pairs(value)
		out[String(k)] = normaliseJson(v)
	end
	return out
end

function normaliseJson(value::AbstractVector) 
	return [normaliseJson(v) for v ∈ value]
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readJsonFile(filename)

Read and parse a JSON bibliography file into a dictionary keyed by citation key.
"""
function readJsonFile(filename::AbstractString)
	if ! isfile(filename)
		throw(ArgumentError("Input JSON file not found: $(filename)."))
	end

	return readJsonString(read(filename, String))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readJsonString(inputString)

Read and parse a JSON bibliography string into a dictionary keyed by citation key.
Accepted JSON shapes:
- one entry object (`{"key","type","fields"}`)
- list of entry objects (`[{"key","type","fields"}, ...]`)
"""
function readJsonString(inputString::AbstractString)
	parsed = try
		JSON3.read(String(inputString))
	catch
		throw(ArgumentError("Input JSON string is not valid JSON."))
	end

	data = normaliseJson(parsed)
	
	return _readJsonString(data)
end

function _readJsonString(data::AbstractDict)
	records = OrderedDict{String, Any}()
	if ! dictionaryResemblesEntry(data)
		throw(ArgumentError("Invalid JSON string: expected entry object or list of entry objects."))
	end

	key = strip(String(data["key"]))
	if isempty(key)
		throw(ArgumentError("Invalid JSON string: entry key must be non-empty."))
	end
	records[key] = data

	return records
end

function _readJsonString(data::AbstractVector)
	records = OrderedDict{String, Any}()

	for (i, rawEntry) ∈ enumerate(data)
		if ! (rawEntry isa AbstractDict) || ! dictionaryResemblesEntry(rawEntry)
			throw(ArgumentError("Invalid JSON string: element $(i) is not an entry object with keys \"key\", \"type\", \"fields\"."))
		end

		key = strip(String(rawEntry["key"]))
		isempty(key) && throw(ArgumentError("Invalid JSON string: element $(i) has an empty entry key."))
		if haskey(records, key)
			throw(ArgumentError("Invalid JSON string: duplicate entry key \"$(key)\"."))
		end
		records[key] = rawEntry
	end

	return records
end

function _readJsonString(data)
	throw(ArgumentError("Invalid JSON string: expected entry object or list of entry objects."))
end

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeJsonFile(data, filename)

Write plain Julia collections to a JSON file.
"""
function writeJsonFile(data, filename::AbstractString; tabSize::Int = tabSizeJson)
	buffer = IOBuffer()
	JSON3.pretty(buffer, data, JSON3.AlignmentContext(; indent = tabSize))
	text = indentJson(String(take!(buffer)); tabSize = tabSize)
	if ! isempty(text) && text[end] ≠ '\n'
		text *= "\n"
	end
	write(filename, text)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readJsonEntry(filename)

Read one entry from a JSON bibliography file or a list of one entry, and return a [`ZettelEntry`](@ref).
Accepted JSON shapes:
- one entry object (`{"key", "type", "fields"}`)
- one-element list (`[{"key", "type", "fields"}]`)
"""
function readJsonEntry(filename::AbstractString)
	records = readJsonFile(filename)
	if length(records) ≠ 1
		throw(ArgumentError("JSON file $(filename) contains $(length(records)) entries; expected exactly one."))
	end
	return ZettelEntry(first(values(records)))
end

function readJsonEntry(records::AbstractDict)
	if dictionaryResemblesEntry(records)
		return ZettelEntry(records)
	end
	if length(records) ≠ 1
		throw(ArgumentError("JSON dictionary contains $(length(records)) entries; expected exactly one."))
	end
	rawEntry = first(values(records))
	if ! (rawEntry isa AbstractDict) || ! dictionaryResemblesEntry(rawEntry)
		throw(ArgumentError(_errorMsgNotEntryLike))
	end
	return ZettelEntry(rawEntry)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readJsonLibrary(filename)

Read a JSON bibliography file and return a [`ZettelLibrary`](@ref).

Accepted JSON shapes:
- one entry object (`{"key","type","fields"}`)
- list of entry objects (`[{"key","type","fields"}, ...]`)
"""
function readJsonLibrary(filename::AbstractString)
	return readJsonLibrary(readJsonFile(filename))
end

function readJsonLibrary(records::AbstractDict)
	if dictionaryResemblesEntry(records)
		return ZettelLibrary([ZettelEntry(records)])
	end

	totalCount = length(records)
	reportTotal("Building bibliography from JSON records", totalCount)
	entries = ZettelEntry[]
	sizehint!(entries, totalCount)
	index = 0
	for rawEntry ∈ values(records)
		index += 1
		if ! (rawEntry isa AbstractDict) || ! dictionaryResemblesEntry(rawEntry)
			throw(ArgumentError(_errorMsgNotEntryLike))
		end
		push!(entries, ZettelEntry(rawEntry))
		reportProgress("Converted JSON records", index, totalCount)
	end
	return ZettelLibrary(entries)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeJsonLibrary(lib, filename)

Write a bibliography library to JSON as a list of entry objects.
"""
function writeJsonLibrary(lib::ZettelLibrary, filename::AbstractString)
	totalCount = length(lib)
	reportTotal("Preparing JSON entries", totalCount)
	records = Vector{OrderedDict{String, Any}}()
	sizehint!(records, totalCount)
	index = 0
	for entry ∈ values(lib)
		index += 1
		push!(records, entryToStructuredDict(entry))
		reportProgress("Prepared JSON entries", index, totalCount)
	end
	writeJsonFile(records, filename)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
