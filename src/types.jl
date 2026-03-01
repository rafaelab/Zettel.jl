# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelEntry

A single bibliographic entry stored as a key, an entry type (e.g. `"article"`), and an
ordered dictionary of BibTeX-compatible field names to their string values.

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

@doc """
	ZettelEntry(key, entryType)

Construct an empty `ZettelEntry` with no fields.
"""
ZettelEntry(key::String, entryType::String) = ZettelEntry(key, entryType, OrderedDict{String, String}())


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelLibrary

A collection of [`ZettelEntry`](@ref) objects, indexed by their citation keys.

# Fields
- `entries::OrderedDict{String,ZettelEntry}`: ordered mapping of citation keys to entries
"""
struct ZettelLibrary
	entries::OrderedDict{String, ZettelEntry}
end


ZettelLibrary() = ZettelLibrary(OrderedDict{String, ZettelEntry}())

ZettelLibrary(entries::Vector{ZettelEntry}) = begin
	d = OrderedDict{String, ZettelEntry}()
	for entry ∈ entries
		d[entry.key] = entry
	end
	return ZettelLibrary(d)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	length(lib)

Return the number of entries in a `ZettelLibrary`.
"""
Base.length(lib::ZettelLibrary) = length(lib.entries)

@doc """
	keys(lib)

Return the citation keys stored in a `ZettelLibrary`.
"""
Base.keys(lib::ZettelLibrary) = keys(lib.entries)

@doc """
	values(lib)

Return all [`ZettelEntry`](@ref) objects stored in a `ZettelLibrary`.
"""
Base.values(lib::ZettelLibrary) = values(lib.entries)

@doc """
	getindex(lib, key)

Return the [`ZettelEntry`](@ref) with the given citation key.
"""
Base.getindex(lib::ZettelLibrary, key::AbstractString) = lib.entries[key]

@doc """
	haskey(lib, key)

Return `true` if the library contains an entry with the given citation key.
"""
Base.haskey(lib::ZettelLibrary, key::AbstractString) = haskey(lib.entries, key)

@doc """
	push!(lib, entry)

Insert a [`ZettelEntry`](@ref) into the library. If an entry with the same key already
exists it is overwritten.
"""
function Base.push!(lib::ZettelLibrary, entry::ZettelEntry)
	lib.entries[entry.key] = entry
	return lib
end

@doc """
	pop!(lib, key)

Remove and return the [`ZettelEntry`](@ref) with the given citation key.
"""
Base.pop!(lib::ZettelLibrary, key::AbstractString) = pop!(lib.entries, key)

@doc """
	iterate(lib[, state])

Iterate over the entries in a `ZettelLibrary`.
"""
function Base.iterate(lib::ZettelLibrary, state = iterate(values(lib.entries)))
    state === nothing && return nothing
    entry, inner_state = state
    return (entry, iterate(values(lib.entries), inner_state))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	show(io, lib)

Print a brief summary of a `ZettelLibrary`.
"""
function Base.show(io::IO, lib::ZettelLibrary)
	n = length(lib)
	print(io, @sprintf("ZettelLibrary containing %d entries.\n", n))
end

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

@doc """
	getType(entry)

Return the BibTeX entry type string (e.g. `"article"`) of a [`ZettelEntry`](@ref).
"""
getType(entry::ZettelEntry) = entry.entryType

@doc """
	getTitle(entry)

Return the title of a [`ZettelEntry`](@ref), or `""` if the `title` field is absent.
"""
getTitle(entry::ZettelEntry) = getField(entry, "title")

@doc """
	getAuthors(entry)

Return the author string of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getAuthors(entry::ZettelEntry) = getField(entry, "author")

@doc """
	getYear(entry)

Return the year string of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getYear(entry::ZettelEntry) = getField(entry, "year")

@doc """
	getJournal(entry)

Return the journal name of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getJournal(entry::ZettelEntry) = getField(entry, "journal")

@doc """
	getDOI(entry)

Return the DOI of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getDOI(entry::ZettelEntry) = getField(entry, "doi")

@doc """
	getURL(entry)

Return the URL of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getURL(entry::ZettelEntry) = getField(entry, "url")

@doc """
	getVolume(entry)

Return the volume of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getVolume(entry::ZettelEntry) = getField(entry, "volume")

@doc """
	getNumber(entry)

Return the issue/number of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getNumber(entry::ZettelEntry) = getField(entry, "number")

@doc """
	getPages(entry)

Return the pages of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getPages(entry::ZettelEntry) = getField(entry, "pages")

@doc """
	getAbstract(entry)

Return the abstract of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getAbstract(entry::ZettelEntry) = getField(entry, "abstract")

@doc """
	getPublisher(entry)

Return the publisher of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getPublisher(entry::ZettelEntry) = getField(entry, "publisher")

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

@doc """
	getAllFields(entry)

Return the collection of field names present in the entry.
"""
getAllFields(entry::ZettelEntry) = keys(entry.fields)

@doc """
	getField(entry, field)

Return the value of `field` in the entry, or `""` if the field is absent.
"""
function getField(entry::ZettelEntry, field::AbstractString)
	k = lowercase(field)
	return get(entry.fields, k, "")
end


# ----------------------------------------------------------------------------------------------- #
#
