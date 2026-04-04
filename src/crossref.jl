# ----------------------------------------------------------------------------------------------- #
#
const crossRefAPI = "https://api.crossref.org/works/"
const dataCiteAPI = "https://api.datacite.org/dois/"
const crossRefDefaultUserAgent = "Zettel.jl/2.1 (https://github.com/rafaelab/Zettel.jl)"


# map CrossRef `type` values to BibTeX entry types
const crossrefTypeMap = Dict{String, String}(
	"journal-article" => "article",
	"book" => "book",
	"book-chapter" => "inbook",
	"edited-book" => "book",
	"monograph" => "book",
	"proceedings-article" => "inproceedings",
	"proceedings" => "proceedings",
	"report" => "techreport",
	"dissertation" => "phdthesis",
	"dataset" => "misc",
	"posted-content" => "misc",
	"reference-entry" => "misc",
	"other" => "misc",
	"code" => "misc",
)


# map DataCite `types.resourceTypeGeneral` values to BibTeX entry types
const dataCiteTypeMap = Dict{String, String}(
	"journalarticle" => "article",
	"book" => "book",
	"bookchapter" => "inbook",
	"conferencepaper" => "inproceedings",
	"conferenceproceeding" => "proceedings",
	"dissertation" => "phdthesis",
	"report" => "techreport",
	"dataset" => "misc",
	"software" => "misc",
	"text" => "misc",
	"other" => "misc",
)

const doiSourcesList = ("crossref", "datacite")


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_nonEmptyString(value)

Normalize optional string-like values to `nothing` when empty after trimming.
"""
function _nonEmptyString(value)
	if isnothing(value)
		return nothing
	end
	text = strip(String(value))
	return isempty(text) ? nothing : text
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	doiSources()

Return the list of supported DOI metadata sources for [`fetchFromDoiSource`](@ref).
"""
doiSources() = collect(doiSourcesList)


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_normaliseDoiSource(source)

Normalise source names used by DOI fetching.
"""
function _normaliseDoiSource(source::AbstractString)
	return lowercase(strip(String(source)))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_entryKeyFromNameAndYear(name, year)

Build a stable citation key seed from first author/contributor name and publication year.
"""
function _entryKeyFromNameAndYear(name::AbstractString, year::AbstractString)
	base = replace(strip(String(name)), r"\s+" => "")
	isempty(base) && (base = "Unknown")
	return base * (isempty(year) ? "" : year)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_crossrefRequestConfig(doi; mailto, plusToken, userAgent)

Build URL and headers for Crossref requests, honoring explicit values first and then environment variables:
- `CROSSREF_MAILTO`
- `CROSSREF_PLUS_API_TOKEN`
- `CROSSREF_USER_AGENT`
"""
function _crossrefRequestConfig(
	doi::AbstractString;
	mailto::Union{Nothing, AbstractString} = nothing,
	plusToken::Union{Nothing, AbstractString} = nothing,
	userAgent::Union{Nothing, AbstractString} = nothing,
)
	effectiveMailto = _nonEmptyString(mailto)
	isnothing(effectiveMailto) && (effectiveMailto = _nonEmptyString(get(ENV, "CROSSREF_MAILTO", "")))

	effectiveToken = _nonEmptyString(plusToken)
	isnothing(effectiveToken) && (effectiveToken = _nonEmptyString(get(ENV, "CROSSREF_PLUS_API_TOKEN", "")))
	baseUserAgent = something(_nonEmptyString(userAgent), _nonEmptyString(get(ENV, "CROSSREF_USER_AGENT", "")), crossRefDefaultUserAgent)

	ua = if isnothing(effectiveMailto)
		baseUserAgent
	elseif occursin(lowercase(effectiveMailto), lowercase(baseUserAgent))
		baseUserAgent
	else
		string(baseUserAgent, " (mailto:", effectiveMailto, ")")
	end

	url = crossRefAPI * HTTP.escapeuri(String(doi))
	if ! isnothing(effectiveMailto)
		url *= "?mailto=$(HTTP.escapeuri(effectiveMailto))"
	end

	headers = Pair{String, String}["User-Agent" => ua]
	if ! isnothing(effectiveToken)
		tokenValue = "Bearer $(effectiveToken)"
		# Crossref docs currently mention Crossref-Plus-API-Token; keep legacy key for compatibility.
		push!(headers, "Crossref-Plus-API-Token" => tokenValue)
		push!(headers, "crossref-api-key" => tokenValue)
	end

	return (; url, headers, mailto = effectiveMailto, plusToken = effectiveToken, userAgent = ua)
end

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	crossrefAuthors(authorList)

Convert the CrossRef author array (each element has `"family"` and optionally `"given"` sub-fields) into a BibTeX-style author string `"Last1, First1 and Last2, First2 and ..."`.

# Input
- `authorList::Vector{Dict}`: list of author objects from CrossRef metadata.

# Output
- A string of authors formatted for BibTeX.
"""
function crossrefAuthors(authorList)
	parts = String[]
	for author ∈ authorList
		family = get(author, "family", "")
		given  = get(author, "given", "")
		if isempty(given)
			push!(parts, family)
		else
			push!(parts, string(family, ", ", given))
		end
	end
	return join(parts, " and ")
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	crossrefYear(msg)

Extract the publication year from a CrossRef work message. 
Returns an empty string when no date information is available.

# Input
- `msg::Dict`: CrossRef work message dictionary.

# Output
- The publication year as a string, or an empty string if not found.
"""
function crossrefYear(msg)
	for key ∈ ("published", "published-print", "published-online", "issued")
		if haskey(msg, key)
			dateParts = get(msg[key], "date-parts", nothing)
			if ! isnothing(dateParts) && length(dateParts) > 0
				parts = dateParts[1]
				if length(parts) > 0
					return string(parts[1])
				end
			end
		end
	end

	return ""
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fetchFromCrossref(doi; mailto, plusToken, userAgent)

Fetch bibliographic metadata from the CrossRef REST API for the given `doi` and return a [`ZettelEntry`](@ref).
For polite access, set `mailto` (or environment variable `CROSSREF_MAILTO`).
For Metadata Plus, set `plusToken` (or `CROSSREF_PLUS_API_TOKEN`).
You may also override the user agent with `userAgent`.

# Example

```julia
using Zettel

# Fetch an entry by DOI with polite access
entry = fetchFromCrossref("10.1002/andp.19053221004"; mailto = "you@example.org")

# Check what we got
println("Key: ", getKey(entry))
println("Title: ", getTitle(entry))
println("Authors: ", getAuthors(entry))
println("Year: ", getYear(entry))

# Add to a library and save
lib = ZettelLibrary([entry])
writeJsonLibrary(lib, "entry.json")
```

# Note
This function requires internet connectivity to access the CrossRef API.
"""
function fetchFromCrossref(
	doi::AbstractString;
	mailto::Union{Nothing, AbstractString} = nothing,
	plusToken::Union{Nothing, AbstractString} = nothing,
	userAgent::Union{Nothing, AbstractString} = nothing,
)
	cfg = _crossrefRequestConfig(doi; mailto = mailto, plusToken = plusToken, userAgent = userAgent)
	response = HTTP.get(cfg.url; headers = cfg.headers)

	if response.status ≠ 200
		error("CrossRef request failed with status $(response.status) for DOI: $doi")
	end

	body = JSON3.read(String(response.body))
	msg = body["message"]

	# determine BibTeX type
	crType = String(get(msg, "type", "other"))
	bibType = get(crossrefTypeMap, crType, "misc")

	# build citation key: LastnameYear
	authorList = get(msg, "author", [])
	firstFamily = length(authorList) > 0 ? get(authorList[1], "family", "Unknown") : "Unknown"
	year = crossrefYear(msg)
	key = replace(firstFamily, " " => "") * (isempty(year) ? "" : year)

	# populate fields preserving BibTeX conventions
	fields = OrderedDict{String, String}()

	# authors
	if length(authorList) > 0
		fields["author"] = crossrefAuthors(authorList)
	end

	# title
	titles = get(msg, "title", [])
	if length(titles) > 0
		fields["title"] = String(titles[1])
	end

	# journal / container
	containerTitles = get(msg, "container-title", [])
	if length(containerTitles) > 0
		ct = String(containerTitles[1])
		if bibType == "article"
			fields["journal"] = ct
		elseif bibType ∈ ("inproceedings", "proceedings")
			fields["booktitle"] = ct
		else
			fields["journal"] = ct
		end
	end

	# year
	if ! isempty(year)
		fields["year"] = year
	end

	# volume / issue / pages
	vol = get(msg, "volume", nothing)
	if ! isnothing(vol)
		fields["volume"] = String(vol)
	end

	issue = get(msg, "issue", nothing)
	if ! isnothing(issue)
		fields["number"] = String(issue)
	end

	pageStr = get(msg, "page", nothing)
	if ! isnothing(pageStr)
		fields["pages"] = String(pageStr)
	end

	# DOI
	doiVal = get(msg, "DOI", nothing)
	if ! isnothing(doiVal)
		fields["doi"] = String(doiVal)
	end

	# url
	urlVal = get(msg, "URL", nothing)
	if ! isnothing(urlVal)
		fields["url"] = String(urlVal)
	end

	# publisher
	pub = get(msg, "publisher", nothing)
	if ! isnothing(pub)
		fields["publisher"] = String(pub)
	end

	# isbn
	isbns = get(msg, "ISBN", [])
	if length(isbns) > 0
		fields["isbn"] = String(isbns[1])
	end

	return ZettelEntry(key, bibType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fetchFromDataCite(doi; fetcher, userAgent)

Fetch bibliographic metadata from the DataCite REST API for the given `doi` and return a [`ZettelEntry`](@ref).
"""
function fetchFromDataCite(
	doi::AbstractString;
	fetcher::Function = defaultFetcher,
	userAgent::Union{Nothing, AbstractString} = nothing,
)
	ua = something(_nonEmptyString(userAgent), _nonEmptyString(get(ENV, "DATACITE_USER_AGENT", "")), crossRefDefaultUserAgent)
	url = dataCiteAPI * strip(String(doi))
	headers = Pair{String, String}["User-Agent" => ua]

	payload = if applicable(fetcher, url, headers)
		fetcher(url, headers)
	else
		fetcher(url)
	end

	parsed = try
		JSON3.read(payload)
	catch
		throw(ArgumentError("DataCite response was not valid JSON."))
	end

	data = haskey(parsed, :data) ? toPlainDict(parsed[:data]) : nothing
	isnothing(data) && throw(ArgumentError("DataCite response did not contain a data field."))
	attrs = get(data, "attributes", nothing)
	isnothing(attrs) && throw(ArgumentError("DataCite response did not contain data.attributes."))

	types = get(attrs, "types", Dict{String, Any}())
	rtg = lowercase(replace(String(get(types, "resourceTypeGeneral", "other")), r"\s+" => ""))
	bibType = get(dataCiteTypeMap, rtg, "misc")

	creators = get(attrs, "creators", Any[])
	authorParts = String[]
	firstFamily = "Unknown"
	for creator ∈ creators
		family = strip(String(get(creator, "familyName", "")))
		given = strip(String(get(creator, "givenName", "")))
		name = strip(String(get(creator, "name", "")))

		if firstFamily == "Unknown"
			if ! isempty(family)
				firstFamily = family
			elseif ! isempty(name)
				firstFamily = first(split(name))
			end
		end

		if ! isempty(family) && ! isempty(given)
			push!(authorParts, string(family, ", ", given))
		elseif ! isempty(name)
			push!(authorParts, name)
		elseif ! isempty(family)
			push!(authorParts, family)
		end
	end

	year = strip(String(get(attrs, "publicationYear", "")))
	if isempty(year)
		dates = get(attrs, "dates", Any[])
		for d ∈ dates
			dateVal = String(get(d, "date", ""))
			m = match(r"(\d{4})", dateVal)
			if ! isnothing(m)
				year = m.captures[1]
				break
			end
		end
	end

	key = _entryKeyFromNameAndYear(firstFamily, year)
	fields = OrderedDict{String, String}()

	if ! isempty(authorParts)
		fields["author"] = join(authorParts, " and ")
	end

	titles = get(attrs, "titles", Any[])
	if ! isempty(titles)
		title1 = get(first(titles), "title", nothing)
		! isnothing(title1) && (fields["title"] = String(title1))
	end

	container = get(attrs, "container", Dict{String, Any}())
	containerTitle = strip(String(get(container, "title", "")))
	if ! isempty(containerTitle)
		if bibType == "article"
			fields["journal"] = containerTitle
		else
			fields["booktitle"] = containerTitle
		end
	end

	volume = strip(String(get(container, "volume", "")))
	! isempty(volume) && (fields["volume"] = volume)
	issue = strip(String(get(container, "issue", "")))
	! isempty(issue) && (fields["number"] = issue)
	firstPage = strip(String(get(container, "firstPage", "")))
	lastPage = strip(String(get(container, "lastPage", "")))
	if ! isempty(firstPage) && ! isempty(lastPage)
		fields["pages"] = string(firstPage, "-", lastPage)
	elseif ! isempty(firstPage)
		fields["pages"] = firstPage
	end

	! isempty(year) && (fields["year"] = year)

	doiVal = strip(String(get(attrs, "doi", "")))
	! isempty(doiVal) && (fields["doi"] = doiVal)
	urlVal = strip(String(get(attrs, "url", "")))
	! isempty(urlVal) && (fields["url"] = urlVal)
	publisherVal = strip(String(get(attrs, "publisher", "")))
	! isempty(publisherVal) && (fields["publisher"] = publisherVal)

	identifiers = get(attrs, "identifiers", Any[])
	for ident ∈ identifiers
		idType = lowercase(strip(String(get(ident, "identifierType", ""))))
		idValue = strip(String(get(ident, "identifier", "")))
		if idType == "isbn" && ! isempty(idValue)
			fields["isbn"] = idValue
			break
		end
	end

	return ZettelEntry(key, bibType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fetchFromDoiSource(doi; source, mailto, plusToken, userAgent)

Fetch a [`ZettelEntry`](@ref) for a DOI from the requested source.
Supported sources are listed by [`doiSources`](@ref).
`source` defaults to `"crossref"`.
"""
function fetchFromDoiSource(
	doi::AbstractString;
	source::AbstractString = "crossref",
	mailto::Union{Nothing, AbstractString} = nothing,
	plusToken::Union{Nothing, AbstractString} = nothing,
	userAgent::Union{Nothing, AbstractString} = nothing,
)
	s = _normaliseDoiSource(source)
	if s == "crossref"
		return fetchFromCrossref(doi; mailto = mailto, plusToken = plusToken, userAgent = userAgent)
	elseif s == "datacite"
		return fetchFromDataCite(doi; userAgent = userAgent)
	end

	throw(ArgumentError("Unsupported DOI source: $(source). Supported: $(join(doiSources(), ", "))"))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	defaultFetcher(url, headers)

Default fetcher function for CrossRef metadata using `HTTP.get`.

# Input
- `url::AbstractString`: URL to fetch.
- `headers::Vector{Pair{String, String}}`: HTTP headers for the request.

# Output
- The content at `url` as a string.
"""
function defaultFetcher(url::AbstractString)
	response = HTTP.get(url)
	response.status == 200 || error("CrossRef request failed with status $(response.status) at URL: $(url)")
	return String(response.body)
end


function defaultFetcher(url::AbstractString, headers::AbstractVector{<:Pair{String, String}})
	response = HTTP.get(url; headers = collect(headers))
	response.status == 200 || error("CrossRef request failed with status $(response.status) at URL: $(url)")
	return String(response.body)
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	toPlainDict(node)

Convert Crossref JSON-like nodes into plain Julia dictionaries and vectors.

# Input
- `node`: Crossref payload node.

# Output
- A plain Julia value with `Dict` and `Vector` containers.
"""
toPlainDict(node) = node


@doc """
	toPlainDict(node)

Convert Crossref JSON-like nodes into plain Julia dictionaries and vectors.

# Input
- `node::JSON3.Object`: Crossref object node.

# Output
- A `Dict{String, Any}`.
"""
toPlainDict(node::JSON3.Object) = Dict(String(k) => toPlainDict(v) for (k, v) ∈ pairs(node))


@doc """
	toPlainDict(node)

Convert Crossref JSON-like nodes into plain Julia dictionaries and vectors.

# Input
- `node::JSON3.Array`: Crossref array node.

# Output
- A vector of plain Julia values.
"""
toPlainDict(node::JSON3.Array) = [toPlainDict(v) for v ∈ node]


@doc """
	toPlainDict(node)

Convert Crossref JSON-like nodes into plain Julia dictionaries and vectors.

# Input
- `node::Dict`: Crossref dictionary node.

# Output
- A `Dict{String, Any}`.
"""
toPlainDict(node::Dict) = Dict(String(k) => toPlainDict(v) for (k, v) ∈ node)


@doc """
	toPlainDict(node)

Convert Crossref JSON-like nodes into plain Julia dictionaries and vectors.

# Input
- `node::AbstractVector`: Crossref array-like node.

# Output
- A vector of plain Julia values.
"""
toPlainDict(node::AbstractVector) = [toPlainDict(v) for v ∈ node]

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	encodeUriComponent(value)

Percent-encode a string for use in a URI path component.

# Input
- `value::AbstractString`: string to encode.

# Output
- The encoded URI component.
"""
function encodeUriComponent(value::AbstractString)
	io = IOBuffer()

	for b ∈ codeunits(value)
		if isAsciiUnreserved(b)
			write(io, b)
		else
			print(io, '%')
			print(io, uppercase(string(b; base = 16, pad = 2)))
		end
	end

	return String(take!(io))
end

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	isAsciiUnreserved(b)

Return whether a byte is an unreserved ASCII URI character.

# Input
- `b::UInt8`: byte to test.

# Output
- `true` if `b` is unreserved, otherwise `false`.
"""
function isAsciiUnreserved(b::UInt8)
	return (UInt8('A') ≤ b ≤ UInt8('Z')) ||
		(UInt8('a') ≤ b ≤ UInt8('z')) ||
		(UInt8('0') ≤ b ≤ UInt8('9')) ||
		b == UInt8('-') ||
		b == UInt8('.') ||
		b == UInt8('_') ||
		b == UInt8('~')
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fetchCrossrefJson(doi; fetcher, mailto, plusToken, userAgent)

Fetch metadata for a DOI from CrossRef and return it as a JSON dictionary.

# Input
- `doi::AbstractString`: DOI to fetch metadata for.
- `fetcher::Function`: function to fetch the CrossRef API response as a string (defaults to `defaultFetcher`).
- `mailto`: contact email for polite access (`CROSSREF_MAILTO` also supported).
- `plusToken`: Crossref Metadata Plus token (`CROSSREF_PLUS_API_TOKEN` also supported).
- `userAgent`: optional user-agent override (`CROSSREF_USER_AGENT` also supported).

# Output
- A `Dict` containing the CrossRef metadata for the DOI.

# Example

```julia
using Zettel

# Fetch raw CrossRef JSON data
record = fetchCrossrefJson("10.1002/andp.19053221004"; mailto = "you@example.org")

# Inspect the structure
println("Type: ", record["type"])
println("Title: ", record["title"])

# Convert to Zettel JSON format
crossrefJsonToZettelJson(record, "entry.json")
```

# Note
This function requires internet connectivity and returns the raw CrossRef API response.
For direct entry creation, use [`fetchFromCrossref`](@ref) instead.
"""
function fetchCrossrefJson(
	doi::AbstractString;
	fetcher::Function = defaultFetcher,
	mailto::Union{Nothing, AbstractString} = nothing,
	plusToken::Union{Nothing, AbstractString} = nothing,
	userAgent::Union{Nothing, AbstractString} = nothing,
)
	cfg = _crossrefRequestConfig(doi; mailto = mailto, plusToken = plusToken, userAgent = userAgent)
	payload = if applicable(fetcher, cfg.url, cfg.headers)
		fetcher(cfg.url, cfg.headers)
	else
		fetcher(cfg.url)
	end
	parsed = try
		JSON3.read(payload)
	catch
		throw(ArgumentError("CrossRef response was not valid JSON."))
	end

	if haskey(parsed, :message)
		return toPlainDict(parsed[:message])
	end

	throw(ArgumentError("CrossRef response did not contain a message field."))
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	saveCrossrefJson(doi, outputPath; fetcher, mailto, plusToken, userAgent)

Fetch metadata for a DOI from CrossRef and save it to `outputPath`.

# Input
- `doi::AbstractString`: DOI to fetch metadata for.
- `outputPath::AbstractString`: file path to save the metadata to.
- `fetcher::Function`: function to fetch the CrossRef API response as a string (defaults to `defaultFetcher`).
- `mailto`: contact email for polite access (`CROSSREF_MAILTO` also supported).
- `plusToken`: Crossref Metadata Plus token (`CROSSREF_PLUS_API_TOKEN` also supported).
- `userAgent`: optional user-agent override (`CROSSREF_USER_AGENT` also supported).

# Output
- The `outputPath` string after writing the metadata to it.
"""
function saveCrossrefJson(
	doi::AbstractString,
	outputPath::AbstractString;
	fetcher::Function = defaultFetcher,
	mailto::Union{Nothing, AbstractString} = nothing,
	plusToken::Union{Nothing, AbstractString} = nothing,
	userAgent::Union{Nothing, AbstractString} = nothing,
)
	record = fetchCrossrefJson(doi; fetcher = fetcher, mailto = mailto, plusToken = plusToken, userAgent = userAgent)
	write(outputPath, JSON3.write(record))
	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
