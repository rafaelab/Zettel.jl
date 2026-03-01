# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_pybtexPersonsToString(personsIterable)

Convert a Pybtex persons iterable (of `Person` objects) to a BibTeX-style author/editor
string `"Last1, First1 and Last2, First2 and ..."`.
"""
function _pybtexPersonsToString(personsIterable)
	parts = String[]
	for p in personsIterable
		name = Pybtex.pybtexToPersonName(p)
		last = name.lastName
		first = name.firstName
		middle = name.middleName
		full_first = isempty(middle) ? first : string(first, " ", middle)
		if isempty(first) && isempty(middle)
			push!(parts, last)
		else
			push!(parts, string(last, ", ", full_first))
		end
	end
	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fromBibTeX(bibLib)

Convert a [`Pybtex.BibLibrary`](@ref) to a [`ZettelLibrary`](@ref).

All BibTeX fields are preserved as string values; author and editor person lists are
collapsed into the standard `"Last, First and ..."` notation.
"""
function fromBibTeX(bibLib::Pybtex.BibLibrary)
	entries = ZettelEntry[]
	for key in Pybtex.keys(bibLib)
		pyEntry = Pybtex.getEntry(bibLib, key)
		entryType = Pybtex.getType(pyEntry)

		fields = OrderedDict{String, String}()

		# Authors
		try
			authors = pyEntry.info.persons["author"]
			if !isempty(authors)
				fields["author"] = _pybtexPersonsToString(authors)
			end
		catch
		end

		# Editors
		try
			editors = pyEntry.info.persons["editor"]
			if !isempty(editors)
				fields["editor"] = _pybtexPersonsToString(editors)
			end
		catch
		end

		# All other fields
		allFields = Pybtex.getAllFields(pyEntry)
		for f in allFields
			val = _pybtexFieldValue(pyEntry, f)
			if !isempty(val)
				fields[f] = val
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
	if !Pybtex.hasField(entry, field)
		return ""
	end
	raw = entry.info.fields[field]
	s = Pybtex.stringPy2Jl(raw)
	# strip surrounding braces added by pybtex
	s = replace(s, r"^\{" => "")
	s = replace(s, r"\}$" => "")
	return s
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	toBibTeX(lib)

Convert a [`ZettelLibrary`](@ref) to a [`Pybtex.BibLibrary`](@ref).

This builds a Pybtex in-memory database so that it can subsequently be written to a `.bib`
file with [`writeBibTeX`](@ref).
"""
function toBibTeX(lib::ZettelLibrary)
	pydb = pyimport("pybtex.database")
	bibData = pydb.BibliographyData()
	for entry in values(lib)
		pyFields = pydict(Dict{String, Any}(entry.fields))
		# Remove author/editor from fields dict – pybtex stores them separately
		pyFields.pop("author", nothing)
		pyFields.pop("editor", nothing)

		pyPersons = pydict(Dict{String, Any}())

		authorStr = get(entry.fields, "author", "")
		if !isempty(authorStr)
			pyPersons["author"] = pylist(_authorStringToPersonList(authorStr))
		end

		editorStr = get(entry.fields, "editor", "")
		if !isempty(editorStr)
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

Convert a BibTeX-style author string `"Last1, First1 and Last2, First2"` to a list of
Pybtex `Person` objects.
"""
function _authorStringToPersonList(authorStr::AbstractString)
	pyPerson = pyimport("pybtex.database").Person
	persons = []
	for part in split(authorStr, " and ")
		part = strip(part)
		push!(persons, pyPerson(part))
	end
	return persons
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	writeBibTeX(lib, filename)

Write the [`ZettelLibrary`](@ref) `lib` to a BibTeX `.bib` file at `filename` using
Pybtex as the backend.
"""
function writeBibTeX(lib::ZettelLibrary, filename::AbstractString)
	bibLib = toBibTeX(lib)
	Pybtex.writeBibtexDataBase(bibLib, filename)
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	readBibTeX(filename)

Read a BibTeX `.bib` file and return a [`ZettelLibrary`](@ref).

Uses Pybtex as the parsing backend.
"""
function readBibTeX(filename::AbstractString)
	bibLib = Pybtex.readBibtexDataBase(filename)
	return fromBibTeX(bibLib)
end


# ----------------------------------------------------------------------------------------------- #
#
