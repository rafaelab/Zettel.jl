# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_indentJson(json, indent)

Post-process a JSON string to replace groups of leading spaces on each line with the given `indent` string (typically `"\\t"`).

JSON3 always emits spaces, so this function converts the indentation to tabs after the fact.  
String contents that happen to start with spaces are not affected because the replacement only targets leading whitespace.
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

The file uses tab characters for indentation (one tab per nesting level).  
Each entry is stored as an object with `"key"`, `"type"`, and `"fields"` properties that mirror the corresponding BibTeX fields.
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

Read a JSON file previously written by [`writeJsonLibrary`](@ref) and return a [`ZettelLibrary`](@ref).
"""
function readJsonLibrary(filename::AbstractString)
	data = JSON3.read(read(filename, String))
	entries = ZettelEntry[_entryFromDict(d) for d ∈ data]
	return ZettelLibrary(entries)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a BibTeX file into JSON while preserving entry type and fields, and structuring author/editor/translator persons as name parts.
"""
function bibTeXToJson(inputPath::AbstractString, outputPath::AbstractString)
	isfile(inputPath) || throw(ArgumentError("Input BibTeX file not found: $(inputPath)"))
	library = readBibtexDataBase(String(inputPath))
	data = OrderedDict{String, Any}()

	sortedKeys = sort([String(k) for k ∈ keys(library)])
	for key ∈ sortedKeys
		entry = Pybtex.getEntry(library, key)
		entryType = Pybtex.getType(entry)
		entryDict = OrderedDict{String, Any}()
		entryDict["entryType"] = lowercase(entryType)

		collabRaw = ""
		for field ∈ Pybtex.getAllFields(entry)
			fieldName = String(field)
			fieldValue = _stripOuterBraces(pyconvert(String, entry.info.fields[field]))
			if fieldName == "collaboration"
				collabRaw = fieldValue
			else
				entryDict[fieldName] = fieldValue
			end
		end

		authorPersons = _pybtexPersonsToNameParts(entry, "author")
		editorPersons = _pybtexPersonsToNameParts(entry, "editor")
		translatorPersons = _pybtexPersonsToNameParts(entry, "translator")
		collaborationPersons = _collaborationToPersons(collabRaw)

		if ! isempty(authorPersons)
			entryDict["author"] = authorPersons
		end
		if ! isempty(editorPersons)
			entryDict["editor"] = editorPersons
		end
		if ! isempty(translatorPersons)
			entryDict["translator"] = translatorPersons
		end
		if ! isempty(collaborationPersons)
			entryDict["collaboration"] = collaborationPersons
		end

		data[key] = _orderEntryFields(entryDict)
	end

	buf = IOBuffer()
	JSON3.pretty(buf, data, JSON3.AlignmentContext(indent = 4))
	jsonStr = String(take!(buf))
	if ! isempty(jsonStr) && jsonStr[end] ≠ '\n'
		jsonStr *= "\n"
	end
	write(outputPath, jsonStr)
	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a JSON bibliography generated by `bibTeXToJson` back into BibTeX via Pybtex.jl.
"""
function jsonToBibTeX(inputPath::AbstractString, outputPath::AbstractString)
	isfile(inputPath) || throw(ArgumentError("Input JSON file not found: $(inputPath)"))
	parsed = try
		JSON3.read(read(inputPath, String))
	catch
		throw(ArgumentError("Input JSON file is not valid JSON: $(inputPath)"))
	end
	entries = parsed

	io = IOBuffer()
	for (rawKey, rawEntry) ∈ pairs(entries)
		key = String(rawKey)
		entryType = String(rawEntry[:entryType])
		println(io, "@$(entryType){$(key),")

		_emitPersons(io, rawEntry)

		for (rawField, rawValue) ∈ pairs(rawEntry)
			field = String(rawField)
			if field == "entryType" || field == "author" || field == "editor" || field == "translator" || field == "collaboration"
				continue
			end
			value = String(rawValue)
			println(io, "\t$(field) = {$(value)},")
		end

		println(io, "}\n")
	end

	(tempPath, handle) = mktemp()
	try
		write(handle, String(take!(io)))
		close(handle)
		library = readBibtexDataBase(tempPath)
		writeBibtexDataBase(library, String(outputPath))
	finally
		isopen(handle) && close(handle)
		rm(tempPath; force = true)
	end

	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
#
function _pybtexPersonsToNameParts(entry, role::AbstractString)
	persons = []
	try
		rolePersons = entry.info.persons[role]
		for person ∈ rolePersons
			first = _stripOuterBraces(_joinNameParts(person, "first_names"))
			middle = _stripOuterBraces(_joinNameParts(person, "middle_names"))
			last = _stripOuterBraces(_joinNameParts(person, "last_names"))
			prelast = _stripOuterBraces(_joinNameParts(person, "prelast_names"))
			lineage = _stripOuterBraces(_joinNameParts(person, "lineage_names"))

			lastParts = String[]
			if ! isempty(prelast)
				push!(lastParts, prelast)
			end
			if ! isempty(last)
				push!(lastParts, last)
			end
			if ! isempty(lineage)
				push!(lastParts, lineage)
			end

			first, middle, last = _normalizeNameParts(first, middle, join(lastParts, " "))
			personDict = Dict{String, String}()
			if ! isempty(first)
				personDict["first"] = first
			end
			if ! isempty(middle)
				personDict["middle"] = middle
			end
			if ! isempty(last)
				personDict["last"] = last
			end
			push!(persons, personDict)
		end
	catch
	end
	return persons
end


# ----------------------------------------------------------------------------------------------- #
#
function _joinNameParts(person, attr::AbstractString)
	try
		parts = pyconvert(Vector{String}, getproperty(person, Symbol(attr)))
		return join(parts, " ")
	catch
		return ""
	end
end


# ----------------------------------------------------------------------------------------------- #
#
function _emitPersons(io, rawEntry)
	hasAuthor = haskey(rawEntry, :author)
	hasEditor = haskey(rawEntry, :editor)
	hasTranslator = haskey(rawEntry, :translator)

	if hasAuthor
		_emitRole(io, "author", rawEntry[:author])
	end
	if hasEditor
		_emitRole(io, "editor", rawEntry[:editor])
	end
	if hasTranslator
		_emitRole(io, "translator", rawEntry[:translator])
	end
	if haskey(rawEntry, :collaboration)
		_emitCollaboration(io, rawEntry[:collaboration])
	end

	if ! hasAuthor && ! hasEditor && ! hasTranslator && haskey(rawEntry, :persons)
		for (rawRole, rawNames) in pairs(rawEntry[:persons])
			role = String(rawRole)
			names = [String(name) for name ∈ rawNames]
			if ! isempty(names)
				personLine = join(names, " and ")
				println(io, "\t$(role) = {$(personLine)},")
			end
		end
	end
end


# ----------------------------------------------------------------------------------------------- #
#
function _emitRole(io, role::AbstractString, rawPeople)
	personLine = _peopleToPersonLine(rawPeople)
	if ! isempty(personLine)
		println(io, "\t$(role) = {$(personLine)},")
	end
end


# ----------------------------------------------------------------------------------------------- #
#
function _emitCollaboration(io, rawPeople)
	personLine = _peopleToPersonLine(rawPeople)
	if ! isempty(personLine)
		println(io, "\tcollaboration = {$(personLine)},")
	end
end


# ----------------------------------------------------------------------------------------------- #
#
function _peopleToPersonLine(rawPeople)
	people = String[]
	for p ∈ rawPeople
		first = haskey(p, :first) ? String(p[:first]) : ""
		middle = haskey(p, :middle) ? String(p[:middle]) : ""
		last = haskey(p, :last) ? String(p[:last]) : ""

		name = ""
		if ! isempty(last)
			if isempty(first) && isempty(middle)
				name = last
			else
				fullFirst = strip(join(filter(! isempty, [first, middle]), " "))
				name = "$(last), $(fullFirst)"
			end
		else
			name = strip(join(filter(! isempty, [first, middle]), " "))
		end

		if ! isempty(name)
			push!(people, name)
		end
	end
	return join(people, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
function _stripOuterBraces(s::AbstractString)
	t = strip(String(s))
	while startswith(t, "{") && endswith(t, "}")
		i = nextind(t, firstindex(t))
		j = prevind(t, lastindex(t))
		if i > j
			return ""
		end
		t = strip(t[i : j])
	end
	return t
end


# ----------------------------------------------------------------------------------------------- #
#
function _normalizeNameParts(first::AbstractString, middle::AbstractString, last::AbstractString)
	f = strip(_stripOuterBraces(first))
	m = strip(_stripOuterBraces(middle))
	l = strip(_stripOuterBraces(last))
	if isempty(f) && occursin(",", l)
		parts = split(l, ","; limit = 2)
		l = strip(_stripOuterBraces(parts[1]))
		f = strip(_stripOuterBraces(parts[2]))
	end
	return f, m, l
end


# ----------------------------------------------------------------------------------------------- #
#
function _collaborationToPersons(collabRaw::AbstractString)
	raw = strip(collabRaw)
	if isempty(raw)
		return []
	end
	parts = split(raw, " and ")
	people = []
	for part ∈ parts
		name = strip(_stripOuterBraces(part))
		if ! isempty(name)
			push!(people, Dict("last" => name))
		end
	end
	return people
end

# ----------------------------------------------------------------------------------------------- #
#
function _orderEntryFields(entryDict::OrderedDict{String, Any})
	ordered = OrderedDict{String, Any}()
	preferred = ["entryType", "title", "author", "editor", "translator", "collaboration",
		"year", "journal", "volume", "pages"]
	for key ∈ preferred
		if haskey(entryDict, key)
			ordered[key] = entryDict[key]
		end
	end
	remaining = sort([k for k ∈ keys(entryDict) if ! (k ∈ preferred)])
	for key ∈ remaining
		ordered[key] = entryDict[key]
	end
	return ordered
end


# ----------------------------------------------------------------------------------------------- #