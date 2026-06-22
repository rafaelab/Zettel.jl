export
	readBibtexFile,
	readBibtexString,
	readBibtexEntry,
	readBibtexLibrary,
	writeBibtexLibrary


# ----------------------------------------------------------------------------------------------- #
#
const _extensionsBibtex = ("bib", "bibtex")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibtexString(inputString)

Read and parse a BibTeX bibliography string into a dictionary keyed by citation key.
"""
function readBibtexString(inputString::AbstractString)
	parser = pyimport("pybtex.database.input.bibtex").Parser()
	parsed = try
		parser.parse_string(String(inputString))
	catch
		throw(ArgumentError("Input BibTeX string is not valid BibTeX."))
	end

	records = OrderedDict{String, Any}()
	keysList = pyconvert(Vector{String}, pylist(parsed.entries.keys()))

	for key ∈ keysList
		pyEntry = parsed.entries[key]
		fields = OrderedDict{String, String}()

		for (field, value) ∈ pyconvert(Dict{String, Any}, pyEntry.fields)
			text = strip(decodeTex(stripOuterBraces(String(value))))
			if ! isempty(text)
				fields[String(field)] = text
			end
		end

		for role ∈ pyconvert(Vector{String}, pylist(pyEntry.persons.keys()))
			names = _bibtexNamesFromPersons(pyEntry.persons[role])
			if ! isempty(names)
				fields[role] = names
			end
		end

		entryDict = OrderedDict{String, Any}()
		entryDict["key"] = key
		entryDict["type"] = lowercase(strip(pyconvert(String, pyEntry.type)))
		entryDict["fields"] = fields
		records[key] = entryDict
	end

	return records
end


@doc """
	_normalisePybtexNamePart(parts)

Convert one pybtex name-part sequence to plain text.
"""
function _normalisePybtexNamePart(parts)
	textParts = String[]
	for value ∈ pyconvert(Vector{String}, pylist(parts))
		text = strip(decodeTex(stripOuterBraces(String(value))))
		if ! isempty(text)
			push!(textParts, text)
		end
	end
	return join(textParts, " ")
end


@doc """
	_bibtexNamesFromPersons(personsIterable)

Convert a pybtex persons iterable to one BibTeX-style name line.
"""
function _bibtexNamesFromPersons(personsIterable)
	parts = String[]

	for person ∈ personsIterable
		first = _normalisePybtexNamePart(person.first_names)
		middle = _normalisePybtexNamePart(person.middle_names)
		prelast = _normalisePybtexNamePart(person.prelast_names)
		last = _normalisePybtexNamePart(person.last_names)
		lineage = _normalisePybtexNamePart(person.lineage_names)

		familyParts = String[]
		! isempty(prelast) && push!(familyParts, prelast)
		! isempty(last) && push!(familyParts, last)
		! isempty(lineage) && push!(familyParts, lineage)
		family = join(familyParts, " ")

		formatted = formatBibtexPerson(PersonName(first, middle, family, ""))
		if ! isempty(formatted)
			push!(parts, formatted)
		end
	end

	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibtexFile(filename)

Read and parse a BibTeX bibliography file into a dictionary keyed by citation key.
"""
function readBibtexFile(filename::AbstractString)
	if ! isfile(filename)
		throw(ArgumentError("Input BibTeX file not found: $(filename)."))
	end

	return readBibtexString(read(filename, String))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibtexEntry(filename)

Read one BibTeX entry from `filename`.
Throws if the file contains zero or multiple entries.
"""
function readBibtexEntry(filename::AbstractString)
	records = readBibtexFile(filename)
	if length(records) ≠ 1
		throw(ArgumentError("BibTeX file $(filename) contains $(length(records)) entries; expected exactly one."))
	end
	return ZettelEntry(first(values(records)))
end

function readBibtexEntry(records::AbstractDict)
	if dictionaryResemblesEntry(records)
		return ZettelEntry(records)
	end
	if length(records) ≠ 1
		throw(ArgumentError("BibTeX dictionary contains $(length(records)) entries; expected exactly one."))
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
	readBibtexLibrary(filename)

Read a BibTeX bibliography file and return a [`ZettelLibrary`](@ref).
"""
function readBibtexLibrary(filename::AbstractString)
	return readBibtexLibrary(readBibtexFile(filename))
end

function readBibtexLibrary(records::AbstractDict)
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
	writeBibtexLibrary(lib, outputPath)

Write a [`ZettelLibrary`](@ref) as a BibTeX `.bib` file.

# Input
- `lib` [`ZettelLibrary`]: the library
- `outputPath` [`AbstractString`]: destination file path.
"""
function writeBibtexLibrary(lib::ZettelLibrary, outputPath::AbstractString)
	open(outputPath, "w") do io
		total = length(lib)
		index = 0
		for entry ∈ values(lib)
			index += 1
			write(io, entryToString(entry, BibtexFormat()))
			write(io, "\n")
			if index < total
				write(io, "\n")
			end
		end
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
