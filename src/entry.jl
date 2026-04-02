# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelEntry

A single bibliographic entry stored as a key, an entry type (e.g. `"article"`), and an ordered dictionary of BibTeX-compatible field names to their string values.

# Fields
- `key::String`: unique citation key (e.g. `"Einstein1905"`)
- `entryType::String`: BibTeX entry type in lower case (e.g. `"article"`, `"book"`)
- `fields::OrderedDict{String,String}`: ordered mapping of field names to values
"""
struct ZettelEntry
	key::String
	entryType::String
	fields::OrderedDict{String, String}
end

ZettelEntry(key::String, entryType::String) = ZettelEntry(key, entryType, OrderedDict{String, String}())


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	intersect(left, right)

Return a `ZettelEntry` containing only the fields that appear in both entries.

# Input
- `left::ZettelEntry`: left-hand entry.
- `right::ZettelEntry`: right-hand entry.

# Output
- A `ZettelEntry` whose `key` and `entryType` come from `left`, and whose fields are the common field names present in both entries. 
When a field is shared, the value from `left` is preserved.
"""
function Base.intersect(left::ZettelEntry, right::ZettelEntry)
	fields = OrderedDict{String, String}()
	for (field, value) ∈ left.fields
		if haskey(right.fields, field)
			fields[field] = value
		end
	end
	return ZettelEntry(left.key, left.entryType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	union(left, right)

Return a `ZettelEntry` containing the fields from both entries.

# Input
- `left::ZettelEntry`: left-hand entry.
- `right::ZettelEntry`: right-hand entry.

# Output
- A `ZettelEntry` whose `key` and `entryType` come from `left`, and whose fields contain the
  combination of fields from both entries. When a field exists in both entries, the value from
  `right` overwrites the value from `left`.
"""
function Base.union(left::ZettelEntry, right::ZettelEntry)
	fields = OrderedDict{String, String}(left.fields)
	for (field, value) ∈ right.fields
		fields[field] = value
	end
	return ZettelEntry(left.key, left.entryType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	show(io, entry)

Print a human-readable summary of a `ZettelEntry`.
"""
function Base.show(io::IO, entry::ZettelEntry)
	s = @sprintf("ZettelEntry [%s] %s\n", entry.entryType, entry.key)
	if haskey(entry.fields, "title")
		s *= @sprintf("  title: %s\n", entry.fields["title"])
	end
	if haskey(entry.fields, "author")
		s *= @sprintf("  author: %s\n", entry.fields["author"])
	end
	if haskey(entry.fields, "year")
		s *= @sprintf("  year: %s\n", entry.fields["year"])
	end
	print(io, s)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getKey(entry)

Return the citation key of a [`ZettelEntry`](@ref).
"""
getKey(entry::ZettelEntry) = entry.key


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getType(entry)

Return the BibTeX entry type string (e.g. `"article"`) of a [`ZettelEntry`](@ref).
"""
getType(entry::ZettelEntry) = entry.entryType


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getTitle(entry)

Return the title of a [`ZettelEntry`](@ref), or `""` if the `title` field is absent.
"""
getTitle(entry::ZettelEntry) = getField(entry, "title")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getAuthors(entry)

Return the author string of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getAuthors(entry::ZettelEntry) = getField(entry, "author")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getYear(entry)

Return the year string of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getYear(entry::ZettelEntry) = getField(entry, "year")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getJournal(entry)

Return the journal name of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getJournal(entry::ZettelEntry) = getField(entry, "journal")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getDOI(entry)

Return the DOI of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getDOI(entry::ZettelEntry) = getField(entry, "doi")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getURL(entry)

Return the URL of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getURL(entry::ZettelEntry) = getField(entry, "url")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getVolume(entry)

Return the volume of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getVolume(entry::ZettelEntry) = getField(entry, "volume")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getNumber(entry)

Return the issue/number of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getNumber(entry::ZettelEntry) = getField(entry, "number")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getPages(entry)

Return the pages of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getPages(entry::ZettelEntry) = getField(entry, "pages")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getAbstract(entry)

Return the abstract of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getAbstract(entry::ZettelEntry) = getField(entry, "abstract")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getPublisher(entry)

Return the publisher of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getPublisher(entry::ZettelEntry) = getField(entry, "publisher")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getISBN(entry)

Return the ISBN of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getISBN(entry::ZettelEntry) = getField(entry, "isbn")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	hasField(entry, field)

Return `true` if `field` (case-insensitive) is present in the entry's fields.
"""
hasField(entry::ZettelEntry, field::AbstractString) = haskey(entry.fields, lowercase(field))


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getAllFields(entry)

Return the collection of field names present in the entry.
"""
getAllFields(entry::ZettelEntry) = keys(entry.fields)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getField(entry, field)

Return the value of `field` in the entry, or `""` if the field is absent.
"""
function getField(entry::ZettelEntry, field::AbstractString)
	k = lowercase(field)
	return get(entry.fields, k, "")
end


# ----------------------------------------------------------------------------------------------- #
