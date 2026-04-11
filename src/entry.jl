export
	ZettelEntry,
	entryToDict,
	orderFields!,
	fixJournalAbbreviations!,
	fixMonth!,
	hasField,
	getKey,
	getType,
	getAllFields,
	getField,
	getAuthors,
	getTitle,
	getYear,
	getJournal,
	getDOI,
	getDoi,
	getURL,
	getUrl,
	getVolume,
	getNumber,
	getPages,
	getAbstract,
	getPublisher,
	getISBN,
	getIsbn,
	entryToString,
	entryFromString


# ----------------------------------------------------------------------------------------------- #
#
const preferredFieldOrder = (
	"collaboration",
	"onbehalf",
	"author",
	"title",
	"booktitle",
	"journal",
	"editor",
	"publisher",
	"year",
	"month",
	"volume",
	"edition",
	"number",
	"pages",
	"eid",
	"doi",
	"adsurl",
	"url",
	"isbn",
	"archivePrefix",
	"primaryClass",
	"eprint",
	"keywords",
	"type",
	"file",
	"groups",
	"note",
	"abstract",
)

const _personFieldNames = ("author", "editor", "translator", "collaboration")

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelEntry

A single bibliographic entry stored as:
* a key;
* an entry type (e.g. `"article"`);
* an ordered dictionary of BibTeX-compatible field names to their string values.

# Fields
- `key::String`: unique citation key (e.g. `"Einstein1905"`)
- `entryType::String`: BibTeX entry type in lower case (e.g. `"article"`, `"book"`)
- `fields::OrderedDict{String,String}`: ordered mapping of field names to values
"""
struct ZettelEntry
	key::String
	entryType::String
	fields::OrderedDict{String, String}

	function ZettelEntry(key::String, entryType::String, fields::OrderedDict{String, String})
		entry = new(key, entryType, OrderedDict{String, String}(fields))
		fixJournalAbbreviations!(entry)
		fixMonth!(entry)
		orderFields!(entry)
		return entry
	end
end

ZettelEntry(key::String, entryType::String) = ZettelEntry(key, entryType, OrderedDict{String, String}())

ZettelEntry(d::AbstractDict) = begin
	hasKey = haskey(d, "key") || haskey(d, :key)
	hasType = haskey(d, "type") || haskey(d, :type)
	hasFields = haskey(d, "fields") || haskey(d, :fields)
	if ! (hasKey && hasType && hasFields)
		throw(ArgumentError("Invalid entry object: expected keys \"key\", \"type\", \"fields\"."))
	end

	keyRaw = haskey(d, "key") ? d["key"] : d[:key]
	typeRaw = haskey(d, "type") ? d["type"] : d[:type]
	fieldsRaw = haskey(d, "fields") ? d["fields"] : d[:fields]
	if ! (fieldsRaw isa AbstractDict)
		throw(ArgumentError("Invalid entry object: \"fields\" must be a dictionary."))
	end

	key = String(keyRaw)
	entryType = String(typeRaw)
	fields = OrderedDict{String, String}()

	for (k, v) ∈ fieldsRaw
		field = String(k)
		if (field ∈ _personFieldNames) && (v isa AbstractVector)
			parts = String[]
			for rawName ∈ v
				name = strip(String(rawName))
				if ! isempty(name)
					push!(parts, name)
				end
			end
			fields[field] = join(parts, " and ")
		else
			fields[field] = String(v)
		end
	end

	return ZettelEntry(key, entryType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	entryToDict(entry)

Convert a [`ZettelEntry`](@ref) to an `OrderedDict` in library-record format:
`{"key": ..., "type": ..., "fields": {...}}`.
"""
function entryToDict(entry::ZettelEntry)
	d = OrderedDict{String, Any}()
	d["key"] = entry.key
	d["type"] = entry.entryType
	d["fields"] = OrderedDict{String, String}(entry.fields)
	return d
end

function entryToStructuredDict(entry::ZettelEntry)
	d = OrderedDict{String, Any}()
	d["key"] = entry.key
	d["type"] = entry.entryType

	fields = OrderedDict{String, Any}()
	for (field, value) ∈ entry.fields
		if field ∈ _personFieldNames
			names = String[]
			for rawName ∈ splitBibtexNames(value)
				name = strip(stripOuterBraces(rawName))
				if ! isempty(name)
					push!(names, name)
				end
			end
			fields[field] = names
		else
			fields[field] = value
		end
	end
	d["fields"] = fields
	return d
end

# constructors from BibTeX, JSON, YAML, etc. are defined in their respective modules


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	intersect(entry1, entry2)

Return a `ZettelEntry` containing only the fields that appear in both entries.

# Input
- `entry1::ZettelEntry`: left-hand entry.
- `entry2::ZettelEntry`: right-hand entry.

# Output
- A `ZettelEntry` whose `key` and `entryType` come from `entry1`, and whose fields are the common field names present in both entries. 
When a field is shared, the value from `entry1` is preserved.
"""
function Base.intersect(entry1::ZettelEntry, entry2::ZettelEntry)
	fields = OrderedDict{String, String}()
	for (field, value) ∈ entry1.fields
		if haskey(entry2.fields, field)
			fields[field] = value
		end
	end
	return ZettelEntry(entry1.key, entry1.entryType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	union(entry1, entry2)

Return a `ZettelEntry` containing the fields from both entries.

# Input
- `entry1::ZettelEntry`: left-hand entry.
- `entry2::ZettelEntry`: right-hand entry.

# Output
- A `ZettelEntry` whose `key` and `entryType` come from `entry1`, and whose fields contain the combination of fields from both entries. 
When a field exists in both entries, the value from `entry2` overwrites the value from `entry1`.
"""
function Base.union(entry1::ZettelEntry, entry2::ZettelEntry)
	fields = OrderedDict{String, String}(entry1.fields)
	for (field, value) ∈ entry2.fields
		fields[field] = value
	end
	return ZettelEntry(entry1.key, entry1.entryType, fields)
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
	fixJournalAbbreviations!(fields)

Replace common journal names in `fields["journal"]` with their standard abbreviations.

# Input
- `fields::OrderedDict{String, String}`: mapping of field names to values.

# Output
- The input `fields` with common values normalised (journal names converted to abbreviations).
"""
function fixJournalAbbreviations!(entry::ZettelEntry)
	if haskey(entry.fields, "journal")
		journal = strip(entry.fields["journal"])
		entry.fields["journal"] = get(journalAbbreviationsDict, journal, entry.fields["journal"])
	end
	return entry
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fixMonth!(fields)

Replace month information `fields["month"]` by its numerical representation.

# Input
- `fields::OrderedDict{String, String}`: mapping of field names to values.

# Output
- The input `fields` with common values normalised (month names converted to numbers).
"""
function fixMonth!(entry::ZettelEntry)
	if haskey(entry.fields, "month")
		month = lowercase(strip(entry.fields["month"]))
		entry.fields["month"] = get(monthsDict, month, entry.fields["month"])
	end
	return entry
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	orderFields!(entry; preferredOrder = preferredFieldOrder)

Reorder `entry.fields` in-place so that the field names listed in `preferredOrder` appear first and in the requested sequence. 
Matching is case-insensitive and any remaining fields are appended in their original relative order.
Returns the mutated entry for convenience.

# Input
- `entry::ZettelEntry`: the entry to reorder.
- `preferredOrder::AbstractVector{<:AbstractString}`: the preferred field order (e.g. `["author", "title", "year"]`).

# Output
- The input `entry` with its `fields` reordered according to the specified preferences.
"""
function orderFields!(entry::ZettelEntry; preferredOrder = preferredFieldOrder)
	existing = OrderedDict(entry.fields)
	empty!(entry.fields)

	existingKeys = collect(keys(existing))
	existingLower = lowercase.(existingKeys)

	preferredLower = lowercase.(string.(collect(preferredOrder)))
	inserted = Set{String}()

	for pref ∈ preferredLower
		for (key, keyLower) ∈ zip(existingKeys, existingLower)
			if key ∈ inserted
				continue
			end
			if keyLower == pref
				entry.fields[key] = existing[key]
				push!(inserted, key)
				break
			end
		end
	end

	for key ∈ existingKeys
		if key ∉ inserted
			entry.fields[key] = existing[key]
		end
	end

	return entry
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
getDoi(entry::ZettelEntry) = getDOI(entry)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getURL(entry)

Return the URL of a [`ZettelEntry`](@ref), or `""` if absent.
"""
getURL(entry::ZettelEntry) = getField(entry, "url")
getUrl(entry::ZettelEntry) = getURL(entry)


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
getField(entry::ZettelEntry, field::AbstractString) = get(entry.fields, lowercase(field), "")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	dictionaryResemblesEntry(d)

Return `true` if `d` looks like a dictionary representation of a [`ZettelEntry`](@ref).
"""
@inline dictionaryResemblesEntry(d::AbstractDict) = haskey(d, "key") && haskey(d, "type") && haskey(d, "fields")


# ----------------------------------------------------------------------------------------------- #
#
const _errorMsgNotEntryLike = "Invalid entry record: expected object with keys \"key\", \"type\", and \"fields\". "

# ----------------------------------------------------------------------------------------------- #

#
@doc """
	entryToString(entry, format)

Serialise one [`ZettelEntry`](@ref) to `format`.
"""
function entryToString(entry::ZettelEntry, ::JsonFormat)
	buf = IOBuffer()
	JSON3.pretty(buf, entryToStructuredDict(entry), JSON3.AlignmentContext(indent = 4))
	return String(take!(buf))
end

function entryToString(entry::ZettelEntry, ::YamlFormat)
	return YAML.write(normaliseYaml(entryToStructuredDict(entry)))
end

function entryToString(entry::ZettelEntry, ::BibtexFormat)
	io = IOBuffer()
	println(io, "@$(entry.entryType){$(entry.key),")

	nonEmpty = [(field, strip(value)) for (field, value) ∈ entry.fields if ! isempty(strip(value))]
	for (i, (field, value)) ∈ enumerate(nonEmpty)
		comma = i < length(nonEmpty) ? "," : ""
		println(io, "\t$(field) = {$(encodeTex(value))}$(comma)")
	end

	print(io, "}")
	return String(take!(io))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	entryFromString(text, format)

Parse one bibliography entry from a `text` string in `format`.
"""
entryFromString(text::AbstractString, ::JsonFormat) = readJsonEntry(readJsonString(text))
entryFromString(text::AbstractString, ::YamlFormat) = readYamlEntry(readYamlString(text))
entryFromString(text::AbstractString, ::BibtexFormat) = readBibtexEntry(readBibtexString(text))


# ----------------------------------------------------------------------------------------------- #
