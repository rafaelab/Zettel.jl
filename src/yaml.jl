export
	readYamlFile,
	readYamlString,
	readYamlEntry,
	readYamlLibrary,
	writeYamlLibrary


# ----------------------------------------------------------------------------------------------- #
#
const _extensionsYaml = ("yaml", "yml")

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	normaliseYaml(value)

Convert YAML-parsed data to plain Julia collections with string keys.
"""
function normaliseYaml(value)
	return value
end

function normaliseYaml(value::AbstractDict)
	out = OrderedDict{String, Any}()
	for (k, v) ∈ pairs(value)
		out[String(k)] = normaliseYaml(v)
	end
	return out
end

function normaliseYaml(value::AbstractVector)
	return [normaliseYaml(v) for v ∈ value]
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readYamlFile(filename)

Read and parse a YAML bibliography file into a dictionary keyed by citation key.
"""
function readYamlFile(filename::AbstractString)
	if ! isfile(filename)
		throw(ArgumentError("Input YAML file not found: $(filename)."))
	end

	return readYamlString(read(filename, String))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readYamlString(inputString)

Read and parse a YAML bibliography string into a dictionary keyed by citation key.
Accepted YAML shapes:
- one entry object (`{"key","type","fields"}`)
- list of entry objects (`[{"key","type","fields"}, ...]`)
"""
function readYamlString(inputString::AbstractString)
	parsed = try
		YAML.load(String(inputString))
	catch
		throw(ArgumentError("Input YAML string is not valid YAML."))
	end

	data = normaliseYaml(parsed)
	records = OrderedDict{String, Any}()

	if data isa AbstractDict
		if ! dictionaryResemblesEntry(data)
			throw(ArgumentError("Invalid YAML string: expected entry object or list of entry objects."))
		end
		key = strip(String(data["key"]))
		isempty(key) && throw(ArgumentError("Invalid YAML string: entry key must be non-empty."))
		records[key] = data
		return records
	end

	if data isa AbstractVector
		for (i, rawEntry) ∈ enumerate(data)
			if ! (rawEntry isa AbstractDict) || ! dictionaryResemblesEntry(rawEntry)
				throw(ArgumentError("Invalid YAML string: element $(i) is not an entry object with keys \"key\", \"type\", \"fields\"."))
			end

			key = strip(String(rawEntry["key"]))
			isempty(key) && throw(ArgumentError("Invalid YAML string: element $(i) has an empty entry key."))
			if haskey(records, key)
				throw(ArgumentError("Invalid YAML string: duplicate entry key \"$(key)\"."))
			end
			records[key] = rawEntry
		end
		return records
	end

	throw(ArgumentError("Invalid YAML string: expected entry object or list of entry objects."))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeYamlFile(data, filename)

Write plain Julia collections to a YAML file.
"""
function writeYamlFile(data, filename::AbstractString)
	text = try
		YAML.write(normaliseYaml(data))
	catch
		throw(ArgumentError("Failed to serialise bibliography to YAML."))
	end
	
	if ! isempty(text) && text[end] ≠ '\n'
		text *= "\n"
	end
	write(filename, text)
	
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readYamlEntry(filename)

Read one entry from a YAML bibliography file and return a [`ZettelEntry`](@ref).

Accepted YAML shapes:
- one entry object (`{"key","type","fields"}`)
- one-element list (`[{"key","type","fields"}]`)
"""
function readYamlEntry(filename::AbstractString)
	records = readYamlFile(filename)
	if length(records) ≠ 1
		throw(ArgumentError("YAML file $(filename) contains $(length(records)) entries; expected exactly one."))
	end
	return ZettelEntry(first(values(records)))
end

function readYamlEntry(records::AbstractDict)
	if dictionaryResemblesEntry(records)
		return ZettelEntry(records)
	end
	if length(records) ≠ 1
		throw(ArgumentError("YAML dictionary contains $(length(records)) entries; expected exactly one."))
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
	readYamlLibrary(filename)

Read a YAML bibliography file and return a [`ZettelLibrary`](@ref).

Accepted YAML shapes:
- one entry object (`{"key","type","fields"}`)
- list of entry objects (`[{"key","type","fields"}, ...]`)
"""
function readYamlLibrary(filename::AbstractString)
	return readYamlLibrary(readYamlFile(filename))
end

function readYamlLibrary(records::AbstractDict)
	if dictionaryResemblesEntry(records)
		return ZettelLibrary([ZettelEntry(records)])
	end

	entries = ZettelEntry[]
	for rawEntry ∈ values(records)
		if ! (rawEntry isa AbstractDict) || ! dictionaryResemblesEntry(rawEntry)
			throw(ArgumentError(_errorMsgNotEntryLike))
		end
		push!(entries, ZettelEntry(rawEntry))
	end

	return ZettelLibrary(entries)
end



# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeYamlLibrary(lib, filename)

Write a bibliography library to YAML as a list of entry objects.
"""
function writeYamlLibrary(lib::ZettelLibrary, filename::AbstractString)
	records = [entryToStructuredDict(entry) for entry ∈ values(lib)]
	writeYamlFile(records, filename)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
