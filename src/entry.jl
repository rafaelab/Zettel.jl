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
	entryFromString,
	similarityScores,
	totalSimilarityScore,
	verySimilarEntry,
	findVerySimilarEntry,
	similarityReport


# ----------------------------------------------------------------------------------------------- #
#
const preferredFieldOrder = (
	"collaboration",
	"author",
	"onbehalf",
	"editor",
	"title",
	"booktitle",
	"journal",
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
const _similarityWeights = (
	author = 0.22,
	key = 0.18,
	title = 0.25,
	venue = 0.20,
	volumePages = 0.15,
)
const _defaultSimilarityFields = ("title", "journal", "booktitle")

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	ZettelEntry

A single bibliographic entry stored as:
* a key;
* an entry type (e.g. `"article"`);
* an ordered dictionary of BibTeX-compatible field names to their string values.

# Fields
- `key` [`AbstractString`]: unique citation key (e.g. `"Einstein1905"`)
- `entryType` [`AbstractString`]: BibTeX entry type in lower case (e.g. `"article"`, `"book"`)
- `fields` [`OrderedDict{String,String}`]: ordered mapping of field names to values
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

ZettelEntry(key::String, entryType::String) = begin
	return ZettelEntry(key, entryType, OrderedDict{String, String}())
end

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



# ----------------------------------------------------------------------------------------------- #
#
@doc """
	intersect(entry1, entry2)

Return a `ZettelEntry` containing only the fields that appear in both entries.

# Input
- `entry1` [`ZettelEntry`]: left-hand entry
- `entry2` [`ZettelEntry`]: right-hand entry

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
- `entry1` [`ZettelEntry`]: left-hand entry
- `entry2` [`ZettelEntry`]: right-hand entry

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
- `entry` [`ZettelEntry`]: the entry whose journal field is to be fixed.

# Output
- The input `entry` with its journal field normalized (journal names converted to abbreviations).
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
- `entry` [`ZettelEntry`]: the entry whose month field is to be fixed.

# Output
- The input `entry` with its month field normalised (month names converted to numbers).
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
- `entry` [`ZettelEntry`]: the entry to reorder.
- `preferredOrder` [`AbstractVector{<: AbstractString}`]: the preferred field order (e.g. `["author", "title", "year"]`).

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
@inline getKey(entry::ZettelEntry) = entry.key


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getType(entry)

Return the BibTeX entry type string (e.g. `"article"`) of a [`ZettelEntry`](@ref).
"""
@inline getType(entry::ZettelEntry) = entry.entryType


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getTitle(entry)

Return the title of a [`ZettelEntry`](@ref), or `""` if the `title` field is absent.
"""
@inline getTitle(entry::ZettelEntry) = getField(entry, "title")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getAuthors(entry)

Return the author string of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getAuthors(entry::ZettelEntry) = getField(entry, "author")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getYear(entry)

Return the year string of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getYear(entry::ZettelEntry) = getField(entry, "year")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getJournal(entry)

Return the journal name of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getJournal(entry::ZettelEntry) = getField(entry, "journal")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getDOI(entry)

Return the DOI of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getDOI(entry::ZettelEntry) = getField(entry, "doi")
@inline getDoi(entry::ZettelEntry) = getDOI(entry)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getURL(entry)

Return the URL of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getURL(entry::ZettelEntry) = getField(entry, "url")
@inline getUrl(entry::ZettelEntry) = getURL(entry)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getVolume(entry)

Return the volume of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getVolume(entry::ZettelEntry) = getField(entry, "volume")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getNumber(entry)

Return the issue/number of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getNumber(entry::ZettelEntry) = getField(entry, "number")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getPages(entry)

Return the pages of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getPages(entry::ZettelEntry) = getField(entry, "pages")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getAbstract(entry)

Return the abstract of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getAbstract(entry::ZettelEntry) = getField(entry, "abstract")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getPublisher(entry)

Return the publisher of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getPublisher(entry::ZettelEntry) = getField(entry, "publisher")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getISBN(entry)

Return the ISBN of a [`ZettelEntry`](@ref), or `""` if absent.
"""
@inline getISBN(entry::ZettelEntry) = getField(entry, "isbn")
@inline getIsbn(entry::ZettelEntry) = getISBN(entry)

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	hasField(entry, field)

Return `true` if `field` (case-insensitive) is present in the entry's fields.
"""
@inline hasField(entry::ZettelEntry, field::AbstractString) = haskey(entry.fields, lowercase(field))


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getAllFields(entry)

Return the collection of field names present in the entry.
"""
@inline getAllFields(entry::ZettelEntry) = keys(entry.fields)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	getField(entry, field)

Return the value of `field` in the entry, or `""` if the field is absent.
"""
@inline getField(entry::ZettelEntry, field::AbstractString) = get(entry.fields, lowercase(field), "")


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
#
@doc """
	verySimilarEntry(candidate, existing; authorThreshold = 0.95, keyThreshold = 0.95, titleThreshold = 0.95, venueThreshold = 0.95, volumePagesThreshold = 0.9, totalThreshold = 0.95, contingent = false)

Return `true` when two entries look like duplicates according to a weighted total similarity score.
"""
function verySimilarEntry( entry1::ZettelEntry, entry2::ZettelEntry; args...)
	return ! isnothing(similarityReport(entry1, entry2; args...))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	similarityScores(candidate, existing; fields = ("title", "journal", "booktitle"), fieldScorers = Dict{String, Function}())

Compute detailed similarity components and a weighted total score in `[0, 1]`.
The returned named tuple includes:
- arbitrary per-field scores from `fields`;
- `author`, `key`, `title`, and venue (`journal` or `booktitle`) scores;
- `volume`, `pages`, and combined `volumePages` scores;
- exact `year` agreement score;
- weighted `totalScore`.
"""
function similarityScores(candidate::ZettelEntry, existing::ZettelEntry; fields = _defaultSimilarityFields, fieldScorers = Dict{String, Function}(),scoreWeights = _similarityWeights)
	fieldScores = OrderedDict{String, Float64}()

	for field ∈ fields
		candidateValue = get(candidate.fields, field, "")
		existingValue = get(existing.fields, field, "")
		if isempty(strip(candidateValue)) || isempty(strip(existingValue))
			continue
		end

		fieldScores[field] = scoreByField(field, candidateValue, existingValue, fieldScorers)
	end

	candidateAuthor = authorSurnameToken(candidate.fields)
	existingAuthor = authorSurnameToken(existing.fields)
	authorScore = (isempty(candidateAuthor) || isempty(existingAuthor)) ? 0. : stringSimilarityScore(candidateAuthor, existingAuthor)

	candidateKeyToken = keyTokenFromEntryKey(candidate.key)
	existingKeyToken = keyTokenFromEntryKey(existing.key)
	keyScore = (isempty(candidateKeyToken) || isempty(existingKeyToken)) ? 0. : stringSimilarityScore(candidateKeyToken, existingKeyToken)

	titleScore = get(fieldScores, "title", 0.0)
	journalScore = get(fieldScores, "journal", 0.0)
	booktitleScore = get(fieldScores, "booktitle", 0.0)
	venueScore = max(journalScore, booktitleScore)

	candidateYear = strip(get(candidate.fields, "year", ""))
	existingYear = strip(get(existing.fields, "year", ""))
	yearScore = (! isempty(candidateYear) && ! isempty(existingYear) && candidateYear == existingYear) ? 1.0 : 0.0

	candidateVolume = strip(get(candidate.fields, "volume", ""))
	existingVolume = strip(get(existing.fields, "volume", ""))
	candidatePages = get(candidate.fields, "pages", "")
	existingPages = get(existing.fields, "pages", "")
	volumeScore = volumeSimilarityScore(candidateVolume, existingVolume)
	pagesScore = pagesSimilarityScore(candidatePages, existingPages)
	volumePagesScore = volumePagesSimilarityScore(candidateVolume, existingVolume, candidatePages, existingPages)
	fieldScores["volume"] = volumeScore
	fieldScores["pages"] = pagesScore

	weights = _normalisedSimilarityWeights(scoreWeights)
	totalScore = (
		weights.author * authorScore +
		weights.key * keyScore +
		weights.title * titleScore +
		weights.venue * venueScore +
		weights.volumePages * volumePagesScore
	)

	return (
		fieldScores = fieldScores,
		authorScore = authorScore,
		keyScore = keyScore,
		titleScore = titleScore,
		journalScore = journalScore,
		booktitleScore = booktitleScore,
		venueScore = venueScore,
		yearScore = yearScore,
		volumeScore = volumeScore,
		pagesScore = pagesScore,
		volumePagesScore = volumePagesScore,
		totalScore = totalScore,
		candidateAuthor = candidateAuthor,
		existingAuthor = existingAuthor,
		year = isempty(candidateYear) ? existingYear : candidateYear,
		volume = isempty(candidateVolume) ? existingVolume : candidateVolume,
	)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	totalSimilarityScore(candidate, existing; kwargs...)

Return only the weighted total similarity score used by duplicate detection.
"""
function totalSimilarityScore(candidate::ZettelEntry, existing::ZettelEntry; kwargs...)
	return similarityScores(candidate, existing; kwargs...).totalScore
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	similarityReport(candidate, existing; authorThreshold = 0.95, keyThreshold = 0.95, titleThreshold = 0.95, venueThreshold = 0.95, volumePagesThreshold = 0.9, totalThreshold = 0.95, contingent = false)

Return a named tuple describing why two entries are considered too similar.
If they do not meet the total-score criterion, return `nothing`.

When `contingent = true`, the decision is made in a strict ordered chain: `author → title → year → booktitle → journal → volume → pages → others`.
At each step, if the compared score is below its threshold, `nothing` is returned immediately.
"""
function similarityReport(candidate::ZettelEntry, existing::ZettelEntry; authorThreshold::Real = 0.95, keyThreshold::Real = 0.95, titleThreshold::Real = 0.95, venueThreshold::Real = 0.95, volumePagesThreshold::Real = 0.95, totalThreshold::Real = 0.95, contingent::Bool = false, otherThreshold::Real = titleThreshold, fields = _defaultSimilarityFields, fieldScorers = Dict{String, Function}(), scoreWeights = _similarityWeights)
	scores = similarityScores(candidate, existing; fields = fields, fieldScorers = fieldScorers, scoreWeights = scoreWeights)

	matchedFieldNames = String[]
	if scores.titleScore ≥ titleThreshold
		push!(matchedFieldNames, "title")
	end
	if scores.journalScore ≥ venueThreshold
		push!(matchedFieldNames, "journal")
	end
	if scores.booktitleScore ≥ venueThreshold
		push!(matchedFieldNames, "booktitle")
	end

	hasComparableBooktitle = haskey(scores.fieldScores, "booktitle")
	hasComparableJournal = haskey(scores.fieldScores, "journal")
	hasComparableVolume = ! isempty(strip(get(candidate.fields, "volume", ""))) && ! isempty(strip(get(existing.fields, "volume", "")))
	hasComparablePages = ! isempty(strip(get(candidate.fields, "pages", ""))) && ! isempty(strip(get(existing.fields, "pages", "")))

	if contingent
		if scores.authorScore < authorThreshold
			return nothing
		end
		if scores.titleScore < titleThreshold
			return nothing
		end
		if scores.yearScore < 1.0
			return nothing
		end
		if hasComparableBooktitle && scores.booktitleScore < venueThreshold
			return nothing
		end
		if hasComparableJournal && scores.journalScore < venueThreshold
			return nothing
		end
		if hasComparableVolume && scores.volumeScore < volumePagesThreshold
			return nothing
		end
		if hasComparablePages && scores.pagesScore < volumePagesThreshold
			return nothing
		end

		for (field, score) ∈ pairs(scores.fieldScores)
			name = lowercase(field)
			if name ∈ ("title", "booktitle", "journal", "volume", "pages")
				continue
			end
			if score < otherThreshold
				return nothing
			end
		end
	else
		if scores.yearScore < 1.0
			return nothing
		end
		if scores.authorScore < authorThreshold
			return nothing
		end
		if scores.keyScore < keyThreshold
			return nothing
		end
		if scores.titleScore < titleThreshold
			return nothing
		end
		if scores.venueScore < venueThreshold
			return nothing
		end
		if scores.volumePagesScore < volumePagesThreshold
			return nothing
		end
	end

	if scores.totalScore < totalThreshold
		return nothing
	end

	return (
		similar = true,
		existingKey = existing.key,
		matchedFieldNames = matchedFieldNames,
		comparedFields = length(scores.fieldScores),
		textRatio = length(scores.fieldScores) == 0 ? 0. : length(matchedFieldNames) / length(scores.fieldScores),
		textScore = (scores.titleScore + scores.venueScore) / 2,
		fieldScores = scores.fieldScores,
		authorScore = scores.authorScore,
		keyScore = scores.keyScore,
		titleScore = scores.titleScore,
		venueScore = scores.venueScore,
		yearScore = scores.yearScore,
		pagesScore = scores.pagesScore,
		volumeScore = scores.volumeScore,
		volumePagesScore = scores.volumePagesScore,
		totalScore = scores.totalScore,
		totalThreshold = totalThreshold,
		candidateAuthor = scores.candidateAuthor,
		existingAuthor = scores.existingAuthor,
		year = scores.year,
		volume = scores.volume,
	)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	findVerySimilarEntry(lib, candidate; authorThreshold = 0.95, keyThreshold = 0.95, titleThreshold = 0.95, venueThreshold = 0.95, volumePagesThreshold = 0.9, totalThreshold = 0.95, contingent = false)

Return the first existing entry in `lib` that looks like a duplicate of `candidate`.
Returns `nothing` if no entry matches.

A positive decision from [`similarityReport`](@ref) always requires an exact, non-empty year match (`yearScore == 1.0`) in both the contingent and the
non-contingent branch. 
The library is therefore pre-filtered on the candidate year before the expensive per-field similarity work (notably the title Levenshtein distance) is performed. 
This is behaviour-preserving: entries that fail the year check could never have been reported as similar, so skipping them cannot change which entry (if any) is returned.
"""
function findVerySimilarEntry(lib, candidate::ZettelEntry; args...)
	candidateYear = strip(get(candidate.fields, "year", ""))
	if isempty(candidateYear)
		return nothing
	end

	for existing ∈ values(lib)
		if strip(get(existing.fields, "year", "")) ≠ candidateYear
			continue
		end
		report = similarityReport(candidate, existing; args...)
		if ! isnothing(report)
			return report
		end
	end
	
	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	scoreByField(field, left, right, fieldScorers)

Score one field using:
- an explicit scorer from `fieldScorers`, when provided;
- built-in scorers for specific fields (`volume`, `pages`);
- `stringSimilarityScore` as fallback.
"""
function scoreByField(field::AbstractString, left::AbstractString, right::AbstractString, fieldScorers::AbstractDict{String, Function})
	name = lowercase(strip(field))
	if haskey(fieldScorers, name)
		return fieldScorers[name](left, right)
	end
	if name == "volume"
		return volumeSimilarityScore(left, right)
	end
	if name == "pages"
		return pagesSimilarityScore(left, right)
	end
	return stringSimilarityScore(left, right)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_normalisedSimilarityWeights(scoreWeights)

Internal helper to validate and normalise component weights for similarity scoring.
"""
function _normalisedSimilarityWeights(scoreWeights)
	requiredKeys = (:author, :key, :title, :venue, :volumePages)
	weights = Dict{Symbol, Float64}()
	for key ∈ requiredKeys
		if ! haskey(scoreWeights, key)
			throw(ArgumentError("Missing similarity weight: $(key)."))
		end
		value = Float64(scoreWeights[key])
		if value < 0
			throw(DomainError("Similarity weights must be non-negative."))
		end
		weights[key] = value
	end

	normalisation = sum(values(weights))
	if normalisation ≤ 0
		throw(ArgumentError("At least one similarity weight must be positive."))
	end

	return (
		author = weights[:author] / normalisation,
		key = weights[:key] / normalisation,
		title = weights[:title] / normalisation,
		venue = weights[:venue] / normalisation,
		volumePages = weights[:volumePages] / normalisation,
	)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	keyTokenFromEntryKey(key)

Extract a normalised token from a citation key, removing a trailing year+suffix when present.
"""
function keyTokenFromEntryKey(key::AbstractString)
	raw = strip(String(key))
	token = replace(raw, r"\d{4}[a-zA-Z]$" => "")
	token = isempty(token) ? raw : token
	token = _normalisedSimilarityText(token)
	token = replace(token, r"\s+" => "")
	return token
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	volumeSimilarityScore(left, right)

Compare volume identifiers, preferring numeric closeness when both are numeric.
"""
function volumeSimilarityScore(v1::AbstractString, v2::AbstractString)
	a = strip(v1)
	b = strip(v2)
	if isempty(a) || isempty(b)
		return 0.
	end
	if lowercase(a) == lowercase(b)
		return 1.
	end

	ai = tryparse(Int, replace(a, r"[^0-9]" => ""))
	bi = tryparse(Int, replace(b, r"[^0-9]" => ""))
	if ! isnothing(ai) && ! isnothing(bi) && max(ai, bi) > 0
		diff = abs(ai - bi)
		return max(0., 1. - (diff / max(ai, bi)))
	end

	return stringSimilarityScore(a, b)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	pagesSimilarityScore(left, right)

Compare page spans using exact match, range endpoints when parseable, and text fallback.
"""
function pagesSimilarityScore(p1::AbstractString, p2::AbstractString)
	a = normalisePagesText(p1)
	b = normalisePagesText(p2)
	if isempty(a) || isempty(b)
		return 0.
	end
	if a == b
		return 1.
	end

	rangeA = parsePageRange(a)
	rangeB = parsePageRange(b)
	if ! isnothing(rangeA) && ! isnothing(rangeB)
		aStart, aEnd = rangeA
		bStart, bEnd = rangeB
		startScore = 1. - min(1., abs(aStart - bStart) / max(1, max(aStart, bStart)))
		endScore = 1. - min(1., abs(aEnd - bEnd) / max(1, max(aEnd, bEnd)))
		spanA = max(1, aEnd - aStart + 1)
		spanB = max(1, bEnd - bStart + 1)
		spanScore = 1. - min(1., abs(spanA - spanB) / max(spanA, spanB))
		return (startScore + endScore + spanScore) / 3
	end

	return stringSimilarityScore(a, b)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	volumePagesSimilarityScore(volumeLeft, volumeRight, pagesLeft, pagesRight)

Combine volume and pages similarity, requiring at least one comparable component.
"""
function volumePagesSimilarityScore(volume1::AbstractString, volume2::AbstractString, pages1::AbstractString, pages2::AbstractString)
	vCompared = ! isempty(strip(volume1)) && ! isempty(strip(volume2))
	pCompared = ! isempty(strip(pages1)) && ! isempty(strip(pages2))
	if ! vCompared && ! pCompared
		return 0.0
	end
	if vCompared && pCompared
		return (volumeSimilarityScore(volume1, volume2) + pagesSimilarityScore(pages1, pages2)) / 2
	end
	return vCompared ? volumeSimilarityScore(volume1, volume2) : pagesSimilarityScore(pages1, pages2)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	normalisePagesText(pages)

Normalise page text for similarity comparison.
"""
function normalisePagesText(pages::AbstractString)
	text = strip(lowercase(String(pages)))
	text = replace(text, "–" => "-", "—" => "-", "--" => "-")
	text = replace(text, r"[^0-9a-z\-]+" => "")
	return text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	parsePageRange(text)

Parse a page range into `(start, end)` when possible.
"""
function parsePageRange(text::AbstractString)
	m = match(r"([0-9]+)\-([0-9]+)", text)
	if ! isnothing(m)
		a = tryparse(Int, m.captures[1])
		b = tryparse(Int, m.captures[2])
		if ! isnothing(a) && ! isnothing(b)
			return (min(a, b), max(a, b))
		end
	end

	n = match(r"([0-9]+)", text)
	if ! isnothing(n)
		v = tryparse(Int, n.captures[1])
		if ! isnothing(v)
			return (v, v)
		end
	end

	return nothing
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	stringSimilarityScore(left, right)

Compute a normalised similarity score in `[0, 1]` from two strings using Levenshtein distance after light normalisation.
"""
function stringSimilarityScore(v1::AbstractString, v2::AbstractString)
	a = _normalisedSimilarityText(v1)
	b = _normalisedSimilarityText(v2)
	if isempty(a) && isempty(b)
		return 1.
	end
	if isempty(a) || isempty(b)
		return 0.
	end

	dist = levenshteinDistance(collect(a), collect(b))
	scale = max(length(a), length(b))

	return scale == 0 ? 1. : 1 - (dist / scale)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_normalisedSimilarityText(text)

Normalise free text for similarity comparison.
"""
function _normalisedSimilarityText(text::AbstractString)
	s = strip(decodeTex(stripOuterBraces(text)))
	s = replace(Base.Unicode.normalize(s, :NFD), r"\p{M}" => "")
	s = lowercase(s)
	s = replace(s, r"[^a-z0-9]+" => " ")
	s = replace(s, r"\s+" => " ")
	return strip(s)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	authorSurnameToken(fields)

Extract the first author surname in normalised token form for similarity comparison.
"""
function authorSurnameToken(fields::AbstractDict{String, String})
	author = get(fields, "author", "")
	if isempty(strip(author))
		return ""
	end

	parts = splitBibtexNames(author)
	firstPerson = isempty(parts) ? author : parts[1]
	parsed = parseBibtexPerson(firstPerson)
	last = strip(parsed.lastName)
	if isempty(last)
		last = strip(decodeTex(stripOuterBraces(firstPerson)))
	end

	return cleanKeyToken(last)
end



# ----------------------------------------------------------------------------------------------- #
