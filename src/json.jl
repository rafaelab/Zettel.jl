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

# Example

```julia
using Zettel, OrderedCollections

# Create a library with one entry
entry = ZettelEntry(
    "Einstein1905",
    "article",
    OrderedDict(
        "author"  => "Einstein, A.",
        "title"   => "Zur Elektrodynamik bewegter Körper",
        "journal" => "Annalen der Physik",
        "year"    => "1905",
    ),
)

lib = ZettelLibrary([entry])

# Write to JSON file
writeJsonLibrary(lib, "library.json")

# The library can be loaded with readJsonLibrary
loaded = readJsonLibrary("library.json")
```
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

Read a JSON file and return a [`ZettelLibrary`](@ref).

# Input
- `filename::AbstractString`: path to a JSON bibliography file.

# Output
- A [`ZettelLibrary`](@ref).

This accepts both:
- the list-based library format produced by [`writeJsonLibrary`](@ref)
- the per-key Zettel JSON format produced by [`bibTeXToJson`](@ref)

# Example

```julia
using Zettel

# Load a library from a JSON file
lib = readJsonLibrary("library.json")

# Access entries by key
einstein = lib["Einstein1905"]
println("Title: ", getTitle(einstein))

# Iterate over all entries
for (key, entry) in pairs(lib)
    println("\$(key): \$(getTitle(entry))")
end
```
"""
function readJsonLibrary(filename::AbstractString)
	data = JSON3.read(read(filename, String))
	return _libraryFromParsedData(data, filename, "JSON")
end


# ----------------------------------------------------------------------------------------------- #
#
function _entryFromZettelJson(rawKey, rawEntry)
	key = String(rawKey)
	entryType = ""
	fields = OrderedDict{String, String}()

	for (rawField, rawValue) ∈ pairs(rawEntry)
		field = String(rawField)
		if field == "entryType"
			entryType = lowercase(String(rawValue))
			continue
		end

		if field == "author" || field == "editor" || field == "translator"
			if rawValue isa AbstractVector
				fields[field] = _personsToString(rawValue)
			else
				fields[field] = String(rawValue)
			end
		elseif field == "collaboration"
			if rawValue isa AbstractVector
				fields[field] = _collaborationPersonsToString(rawValue)
			else
				fields[field] = String(rawValue)
			end
		else
			fields[field] = String(rawValue)
		end
	end

	isempty(entryType) && throw(ArgumentError("Missing entryType for key $(key)."))
	return ZettelEntry(key, entryType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
function _personsToString(persons)
	parts = String[]
	for p ∈ persons
		name = _getString(p, "name")
		if ! isempty(name)
			push!(parts, name)
			continue
		end

		last = _getString(p, "last")
		first = _getString(p, "first")
		middle = _getString(p, "middle")
		fullFirst = isempty(middle) ? first : string(first, " ", middle)

		if isempty(first) && isempty(middle)
			push!(parts, last)
		else
			push!(parts, string(last, ", ", fullFirst))
		end
	end
	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
function _collaborationPersonsToString(persons)
	parts = String[]
	for p ∈ persons
		name = _getString(p, "name")
		isempty(name) || push!(parts, name)
	end
	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
function _getString(obj, key::AbstractString)
	sym = Symbol(key)
	if haskey(obj, sym)
		return String(obj[sym])
	elseif haskey(obj, key)
		return String(obj[key])
	else
		return ""
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	bibTeXToJson(inputPath, outputPath)

Convert a BibTeX file into JSON while preserving entry type and fields, and structuring author/editor/translator persons as name parts.

# Input
- `inputPath::AbstractString`: source `.bib` file.
- `outputPath::AbstractString`: destination `.json` file.

# Output
- The `outputPath` string after writing the converted file.

# Example

```julia
using Zettel

# Convert a BibTeX file to JSON
bibTeXToJson("references.bib", "references.json")

# The output uses the per-key Zettel JSON format with structured author fields
# You can then load and inspect it
lib = readJsonLibrary("references.json")
for (key, entry) in pairs(lib)
    authors = getAuthors(entry)
    println("\$(key): \$(authors)")
end
```
"""
function bibTeXToJson(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, bibTeXFormat(), jsonFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a Crossref work message (as returned by `fetchCrossrefJson`) to a Zettel-style JSON file.

# Input
- `record::Dict{String, Any}`: Crossref work message.
- `outputPath::AbstractString`: destination `.json` file.
- `key`: optional citation key override.

# Output
- The `outputPath` string after writing the converted file.
"""
function crossrefJsonToZettelJson(record::Dict{String, Any}, outputPath::AbstractString; key::Union{Nothing, AbstractString} = nothing)
	entryKey, entryDict = _crossrefMessageToZettelEntry(record; key = key)
	data = OrderedDict{String, Any}()
	data[entryKey] = _orderEntryFields(entryDict)

	buf = IOBuffer()
	JSON3.pretty(buf, data, JSON3.AlignmentContext(indent = 4))
	jsonStr = String(take!(buf))
	if ! isempty(jsonStr) && jsonStr[end] != '\n'
		jsonStr *= "\n"
	end
	write(outputPath, jsonStr)
	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
Convert a JSON bibliography generated by `bibTeXToJson` back into BibTeX via Pybtex.jl.

# Input
- `inputPath::AbstractString`: source `.json` file.
- `outputPath::AbstractString`: destination `.bib` file.

# Output
- The `outputPath` string after writing the converted file.
"""
function jsonToBibTeX(inputPath::AbstractString, outputPath::AbstractString)
	return convertBibliography(inputPath, outputPath, jsonFormat(), bibTeXFormat())
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	pybtexPersonsToNameParts(entry, role)

Convert a Pybtex person list into a vector of name-part dictionaries.

# Input
- `entry`: a Pybtex bibliography entry.
- `role::AbstractString`: person role to extract, such as `"author"` or `"editor"`.

# Output
- A `Vector` of dictionaries with `first`, `middle`, and `last` keys when available.
"""
function pybtexPersonsToNameParts(entry, role::AbstractString)
	persons = []
	try
		rolePersons = entry.info.persons[role]
		for person ∈ rolePersons
			first = _stripOuterBraces(joinNameParts(person, "first_names"))
			middle = _stripOuterBraces(joinNameParts(person, "middle_names"))
			last = _stripOuterBraces(joinNameParts(person, "last_names"))
			prelast = _stripOuterBraces(joinNameParts(person, "prelast_names"))
			lineage = _stripOuterBraces(joinNameParts(person, "lineage_names"))

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

			first, middle, last = _normaliseNameParts(first, middle, join(lastParts, " "))
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
@doc """
	joinNameParts(person, attr)

Join the string parts stored on a Pybtex person object.

# Input
- `person`: a Pybtex person object.
- `attr::AbstractString`: attribute name to read, for example `"first_names"`.

# Output
- A single space-separated string, or `""` when the attribute is absent.
"""
function joinNameParts(person, attr::AbstractString)
	sym = Symbol(attr)
	if ! hasproperty(person, sym)
		return ""
	end

	try
		parts = pyconvert(Vector{String}, getproperty(person, sym))
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
		if haskey(p, :name)
			name = String(p[:name])
			if ! isempty(name)
				push!(people, name)
			end
			continue
		end

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
function _crossrefMessageToZettelEntry(msg::Dict{String, Any}; key::Union{Nothing, AbstractString} = nothing)
	crType = String(get(msg, "type", "other"))
	entryType = get(crossrefTypeMap, crType, "misc")

	authorList = get(msg, "author", [])
	year = crossrefYear(msg)

	entryKey = key
	if isnothing(entryKey)
		firstFamily = length(authorList) > 0 ? get(authorList[1], "family", "Unknown") : "Unknown"
		entryKey = replace(String(firstFamily), " " => "") * (isempty(year) ? "" : year)
	end

	entryDict = OrderedDict{String, Any}()
	entryDict["entryType"] = entryType

	authors = _crossrefPeople(authorList)
	if ! isempty(authors)
		entryDict["author"] = authors
	end

	titleList = get(msg, "title", [])
	if length(titleList) > 0
		entryDict["title"] = _stripOuterBraces(String(titleList[1]))
	end

	containerTitles = get(msg, "container-title", [])
	if length(containerTitles) > 0
		ct = _stripOuterBraces(String(containerTitles[1]))
		if entryType == "article"
			entryDict["journal"] = ct
		elseif entryType ∈ ("inproceedings", "proceedings")
			entryDict["booktitle"] = ct
		else
			entryDict["journal"] = ct
		end
	end

	if ! isempty(year)
		entryDict["year"] = year
	end

	vol = get(msg, "volume", nothing)
	if ! isnothing(vol)
		entryDict["volume"] = _stripOuterBraces(String(vol))
	end

	issue = get(msg, "issue", nothing)
	if ! isnothing(issue)
		entryDict["number"] = _stripOuterBraces(String(issue))
	end

	pageStr = get(msg, "page", nothing)
	if ! isnothing(pageStr)
		entryDict["pages"] = _stripOuterBraces(String(pageStr))
	end

	doiVal = get(msg, "DOI", nothing)
	if ! isnothing(doiVal)
		entryDict["doi"] = String(doiVal)
	end

	urlVal = get(msg, "URL", nothing)
	if ! isnothing(urlVal)
		entryDict["url"] = String(urlVal)
	end

	pub = get(msg, "publisher", nothing)
	if ! isnothing(pub)
		entryDict["publisher"] = _stripOuterBraces(String(pub))
	end

	isbns = get(msg, "ISBN", [])
	if length(isbns) > 0
		entryDict["isbn"] = _stripOuterBraces(String(isbns[1]))
	end

	return entryKey, entryDict
end

# ----------------------------------------------------------------------------------------------- #
#
function _crossrefPeople(authorList)
	people = []
	for author ∈ authorList
		name = get(author, "name", "")
		family = get(author, "family", "")
		given = get(author, "given", "")

		personDict = Dict{String, String}()
		if ! isempty(name)
			personDict["last"] = _stripOuterBraces(String(name))
		else
			first, middle = _splitGivenName(String(given))
			last = _stripOuterBraces(String(family))
			if ! isempty(first)
				personDict["first"] = first
			end
			if ! isempty(middle)
				personDict["middle"] = middle
			end
			if ! isempty(last)
				personDict["last"] = last
			end
		end

		if ! isempty(personDict)
			push!(people, personDict)
		end
	end
	return people
end


# ----------------------------------------------------------------------------------------------- #
#
function _splitGivenName(given::AbstractString)
	g = strip(given)
	if isempty(g)
		return "", ""
	end
	parts = split(g, r"\\s+")
	if length(parts) == 1
		return parts[1], ""
	end
	return parts[1], join(parts[2 : end], " ")
end


# ----------------------------------------------------------------------------------------------- #
#
function _normaliseNameParts(first::AbstractString, middle::AbstractString, last::AbstractString)
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
			push!(people, Dict("name" => name))
		end
	end
	return people
end

# ----------------------------------------------------------------------------------------------- #
#
function _orderEntryFields(entryDict::OrderedDict{String, Any})
	ordered = OrderedDict{String, Any}()
	preferred = ["entryType", "title", "author", "editor", "translator", "collaboration", "year", "journal", "volume", "pages"]
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
#
@doc """
	_libraryFromParsedData(data, filename, formatName)

Convert a parsed JSON-like bibliography payload into a [`ZettelLibrary`](@ref).

# Input
- `data`: parsed bibliography payload.
- `filename::AbstractString`: source file path used for error reporting.
- `formatName::AbstractString`: format label used in error messages.

# Output
- A [`ZettelLibrary`](@ref) built from `data`.
"""
function _libraryFromParsedData(data, filename::AbstractString, formatName::AbstractString)
	if data isa AbstractVector
		entries = ZettelEntry[_entryFromDict(d) for d ∈ data]
		return ZettelLibrary(entries)
	elseif data isa AbstractDict
		entries = ZettelEntry[_entryFromZettelJson(k, v) for (k, v) ∈ pairs(data)]
		return ZettelLibrary(entries)
	else
		throw(ArgumentError("Unsupported $(formatName) bibliography format in $(filename)."))
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_normaliseParsedData(value)

Convert parsed JSON-like data into plain Julia collections with string keys.

# Input
- `value`: parsed JSON payload or nested collection.

# Output
- A recursively normalised value with `OrderedDict{String, Any}` and `Vector` containers.
"""
function _normaliseParsedData(value)
	if value isa AbstractDict
		out = OrderedDict{String, Any}()
		for (k, v) ∈ pairs(value)
			out[String(k)] = _normaliseParsedData(v)
		end
		return out
	elseif value isa AbstractVector
		return [_normaliseParsedData(v) for v ∈ value]
	else
		return value
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_readJsonData(filename)

Read and normalise a JSON bibliography payload.

# Input
- `filename::AbstractString`: path to the JSON file.

# Output
- The parsed and normalised JSON payload.
"""
function _readJsonData(filename::AbstractString)
	data = try
		JSON3.read(read(filename, String))
	catch
		throw(ArgumentError("Input JSON file is not valid JSON: $(filename)"))
	end
	return _normaliseParsedData(data)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_writeJsonData(data, filename)

Write normalised bibliography data to a JSON file.

# Input
- `data`: bibliography payload to serialise.
- `filename::AbstractString`: destination JSON file.

# Output
- `nothing`.
"""
function _writeJsonData(data, filename::AbstractString)
	buf = IOBuffer()
	JSON3.pretty(buf, data, JSON3.AlignmentContext(indent = 4))
	jsonStr = String(take!(buf))
	if ! isempty(jsonStr) && jsonStr[end] != '\n'
		jsonStr *= "\n"
	end
	write(filename, jsonStr)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_bibTeXToStructuredData(inputPath)

Convert a BibTeX database into the structured Zettel JSON/YAML representation.

# Input
- `inputPath::AbstractString`: source `.bib` file.

# Output
- An `OrderedDict{String, Any}` keyed by citation key.
"""
function _bibTeXToStructuredData(inputPath::AbstractString)
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

		authorPersons = pybtexPersonsToNameParts(entry, "author")
		editorPersons = pybtexPersonsToNameParts(entry, "editor")
		translatorPersons = pybtexPersonsToNameParts(entry, "translator")
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
	return data
end


# ----------------------------------------------------------------------------------------------- #
