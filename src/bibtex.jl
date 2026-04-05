# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_pybtexPersonsToString(personsIterable)

Convert a Pybtex persons iterable (of `Person` objects) to a BibTeX-style author/editor string `"Last1, First1 and Last2, First2 and ..."`.
"""
function _pybtexPersonsToString(personsIterable)
	parts = String[]
	for p ∈ personsIterable
		name = Pybtex.pybtexToPersonName(p)
		last = decodeTex(name.lastName)
		first = decodeTex(name.firstName)
		middle = decodeTex(name.middleName)
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
@doc """
	fromBibTeX(bibLib)

Convert a `Pybtex.BibLibrary` to a [`ZettelLibrary`](@ref).

All BibTeX fields are preserved as string values and TeX accent escapes are decoded
to UTF-8; author and editor person lists are collapsed into the standard
`"Last, First and ..."` notation.
"""
function fromBibTeX(bibLib::Pybtex.BibLibrary)
	entries = ZettelEntry[]
	for key ∈ Pybtex.keys(bibLib)
		pyEntry = Pybtex.getEntry(bibLib, key)
		entryType = Pybtex.getType(pyEntry)

		fields = OrderedDict{String, String}()

		# authors
		try
			authors = pyEntry.info.persons["author"]
			if ! isempty(authors)
				fields["author"] = _pybtexPersonsToString(authors)
			end
		catch
		end

		# editors
		try
			editors = pyEntry.info.persons["editor"]
			if ! isempty(editors)
				fields["editor"] = _pybtexPersonsToString(editors)
			end
		catch
		end

		# all other fields
		allFields = Pybtex.getAllFields(pyEntry)
		for field ∈ allFields
			val = _pybtexFieldValue(pyEntry, field)
			if ! isempty(val)
				fields[field] = val
			end
		end

		push!(entries, ZettelEntry(key, entryType, fields))
	end

	return ZettelLibrary(entries)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_pybtexFieldValue(entry, field)

Extract the string value of `field` from a Pybtex `BibEntry`.
"""
function _pybtexFieldValue(entry::Pybtex.BibEntry, field::AbstractString)
	if ! Pybtex.hasField(entry, field)
		return ""
	end
	raw = entry.info.fields[field]
	s = Pybtex.stringPy2Jl(raw)

	# strip surrounding braces added by pybtex
	s = replace(s, r"^\{" => "")
	s = replace(s, r"\}$" => "")
	return decodeTex(s)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	toBibTeX(lib)

Convert a [`ZettelLibrary`](@ref) to a `Pybtex.BibLibrary`.

This builds a Pybtex in-memory database so that it can subsequently be written to a `.bib` file with [`writeBibTeXLibrary`](@ref).
UTF-8 accent characters are encoded to TeX escapes before emitting BibTeX.

# Input
- `lib::ZettelLibrary`: the library to convert.

# Output
- A `Pybtex.BibLibrary` object containing the same entries as `lib`.
"""
function toBibTeX(lib::ZettelLibrary)
	pydb = pyimport("pybtex.database")
	bibData = pydb.BibliographyData()

	for entry ∈ values(lib)
		encodedFields = Dict{String, Any}()
		for (field, value) ∈ entry.fields
			encodedFields[field] = encodeTex(value)
		end
		pyFields = pydict(encodedFields)

		# remove author/editor from fields dict; pybtex stores them separately
		pyFields.pop("author", nothing)
		pyFields.pop("editor", nothing)

		pyPersons = pydict(Dict{String, Any}())

		authorStr = encodeTex(get(entry.fields, "author", ""))
		if ! isempty(authorStr)
			pyPersons["author"] = pylist(_authorStringToPersonList(authorStr))
		end

		editorStr = encodeTex(get(entry.fields, "editor", ""))
		if ! isempty(editorStr)
			pyPersons["editor"] = pylist(_authorStringToPersonList(editorStr))
		end

		pyEntry = pydb.Entry(entry.entryType, fields = pyFields, persons = pyPersons)
		bibData.entries[entry.key] = pyEntry
	end

	return Pybtex.BibLibrary(bibData)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_authorStringToPersonList(authorStr)

Convert a BibTeX-style author string `"Last1, First1 and Last2, First2"` to a list of Pybtex `Person` objects.

# Input
- `authorStr::AbstractString`: a BibTeX-style author/editor string.

# Output
- A list of Pybtex `Person` objects corresponding to the authors/editors in `authorStr`.
"""
function _authorStringToPersonList(authorStr::AbstractString)
	pyPerson = pyimport("pybtex.database").Person
	persons = []
	for part ∈ split(authorStr, " and ")
		part = strip(part)
		push!(persons, pyPerson(part))
	end
	return persons
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeBibTeXLibrary(lib, filename)

Write the [`ZettelLibrary`](@ref) `lib` to a BibTeX `.bib` file at `filename` using Pybtex as the backend.

# Input
- `lib::ZettelLibrary`: the library to write.
- `filename::AbstractString`: the destination file path.

# Output
- `nothing`
"""
function writeBibTeXLibrary(lib::ZettelLibrary, filename::AbstractString)
	bibLib = toBibTeX(lib)
	Pybtex.writeBibtexDataBase(bibLib, filename)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibTeXLibrary(filename)

Read a BibTeX `.bib` file and return a [`ZettelLibrary`](@ref).
Uses Pybtex as the parsing backend.

# Input
- `filename::AbstractString`: path to the `.bib` file to read.

# Output
- A [`ZettelLibrary`](@ref) containing the entries parsed from `filename`.
"""
function readBibTeXLibrary(filename::AbstractString)
	bibLib = Pybtex.readBibtexDataBase(filename)
	return fromBibTeX(bibLib)
end


# ----------------------------------------------------------------------------------------------- #
#
