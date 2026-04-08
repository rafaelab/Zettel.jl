# ----------------------------------------------------------------------------------------------- #
#
const crossRefAPI = "https://api.crossref.org/works/"
const crossRefDefaultUserAgent = "Zettel.jl (https://github.com/rafaelab/Zettel.jl)"


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


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_crossrefRequestConfig(doi; mailto, plusToken, userAgent)

Build URL and headers for Crossref requests, honoring explicit values first and then environment variables:
- `CROSSREF_MAILTO`
- `CROSSREF_PLUS_API_TOKEN`
- `CROSSREF_USER_AGENT`
"""
function _crossrefRequestConfig(doi::AbstractString; mailto::Maybe{AbstractString} = nothing, plusToken::Maybe{AbstractString} = nothing, userAgent::Maybe{AbstractString} = nothing)
	effectiveMailto = nonEmptyString(mailto)
	if isnothing(effectiveMailto) 
		effectiveMailto = nonEmptyString(get(ENV, "CROSSREF_MAILTO", ""))
	end

	effectiveToken = nonEmptyString(plusToken)
	if isnothing(effectiveToken)
		effectiveToken = nonEmptyString(get(ENV, "CROSSREF_PLUS_API_TOKEN", ""))
	end
	baseUserAgent = something(nonEmptyString(userAgent), nonEmptyString(get(ENV, "CROSSREF_USER_AGENT", "")), crossRefDefaultUserAgent)

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

		# crossref docs currently mention crossref-Plus-API-Token; keep legacy key for compatibility
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
	fetchFromCrossref(doi; fetcher, mailto, plusToken, userAgent)

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
	fetcher::Function = defaultFetcher,
	mailto::Maybe{AbstractString} = nothing,
	plusToken::Maybe{AbstractString} = nothing,
	userAgent::Maybe{AbstractString} = nothing,
)
	record = fetchCrossrefJson(
		doi;
		fetcher = fetcher,
		mailto = mailto,
		plusToken = plusToken,
		userAgent = userAgent,
	)
	entryKey, entryDict = _crossrefMessageToZettelEntry(record)
	return _crossrefStructuredToEntry(entryKey, entryDict)
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
	if response.status ≠ 200 
		error("CrossRef request failed with status $(response.status) at URL: $(url)")
	end
	return String(response.body)
end


function defaultFetcher(url::AbstractString, headers::AbstractVector{<: Pair{String, String}})
	response = HTTP.get(url; headers = collect(headers))
	if response.status ≠ 200 
		error("CrossRef request failed with status $(response.status) at URL: $(url)")
	end
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
function fetchCrossrefJson(doi::AbstractString; fetcher::Function = defaultFetcher, mailto::Maybe{AbstractString} = nothing, plusToken::Maybe{AbstractString} = nothing, userAgent::Maybe{AbstractString} = nothing)
	cfg = _crossrefRequestConfig(doi; mailto = mailto, plusToken = plusToken, userAgent = userAgent)
	payload = applicable(fetcher, cfg.url, cfg.headers) ? fetcher(cfg.url, cfg.headers) : fetcher(cfg.url)
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
function saveCrossrefJson(doi::AbstractString, outputPath::AbstractString; fetcher::Function = defaultFetcher, mailto::Maybe{AbstractString} = nothing, plusToken::Maybe{AbstractString} = nothing, userAgent::Maybe{AbstractString} = nothing)
	record = fetchCrossrefJson(doi; fetcher = fetcher, mailto = mailto, plusToken = plusToken, userAgent = userAgent)
	write(outputPath, JSON3.write(record))
	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_crossrefMessageToZettelEntry(msg; key)

Convert a Crossref work message to a Zettel-style JSON entry dictionary.

# Input
- `msg::Dict{String, Any}`: Crossref work message
- `key::Maybe{AbstractString}`: optional citation key override

# Output
- A tuple `(entryKey, entryDict)` where `entryKey` is the citation key for the entry, and `entryDict` is an ordered dictionary containing the entry's fields in Zettel JSON format.
"""
function _crossrefMessageToZettelEntry(msg::Dict{String, Any}; key::Maybe{AbstractString} = nothing)
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
		entryDict["title"] = stripOuterBraces(String(titleList[1]))
	end

	containerTitles = get(msg, "container-title", [])
	if length(containerTitles) > 0
		ct = stripOuterBraces(String(containerTitles[1]))
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
		entryDict["volume"] = stripOuterBraces(String(vol))
	end

	issue = get(msg, "issue", nothing)
	if ! isnothing(issue)
		entryDict["number"] = stripOuterBraces(String(issue))
	end

	pageStr = get(msg, "page", nothing)
	if ! isnothing(pageStr)
		entryDict["pages"] = stripOuterBraces(String(pageStr))
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
		entryDict["publisher"] = stripOuterBraces(String(pub))
	end

	isbns = get(msg, "ISBN", [])
	if length(isbns) > 0
		entryDict["isbn"] = stripOuterBraces(String(isbns[1]))
	end

	return entryKey, entryDict
end


# ----------------------------------------------------------------------------------------------- #
#
function _crossrefStructuredToEntry(entryKey, entryDict::AbstractDict)
	if ! haskey(entryDict, "entryType")
		throw(ArgumentError("Invalid Crossref payload: entry $(entryKey) is missing \"entryType\"."))
	end

	fields = OrderedDict{String, String}()
	for (rawField, rawValue) ∈ pairs(entryDict)
		field = String(rawField)
		field == "entryType" && continue
		if field ∈ personRoles && rawValue isa AbstractVector
			fields[field] = namesToBibtex(rawValue)
		elseif field == "collaboration" && rawValue isa AbstractVector
			fields[field] = namesToBibtex(rawValue; collaboration = true)
		elseif rawValue isa AbstractVector
			fields[field] = join([string(v) for v ∈ rawValue], ", ")
		else
			fields[field] = string(rawValue)
		end
	end

	return ZettelEntry(String(entryKey), lowercase(string(entryDict["entryType"])), fields)
end

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	_crossrefPeople(authorList)

Convert a list of Crossref author/editor/translator dictionaries to a list of Zettel-style person dictionaries.
Each person dictionary may have "first", "middle", and "last" keys, or a "name" key for the full name. The function processes the input list and constructs a new list of dictionaries in the format expected by Zettel JSON entries.

# Input
- `authorList::Vector{Dict{String, Any}}`: a list of dictionaries representing authors, editors, or translators from a Crossref message. Each dictionary may contain keys such as "name", "family", and "given".

# Output
- A list of dictionaries, where each dictionary represents a person with keys like "first", "middle", and "last" for name components, or a "name" key for the full name. This list is formatted according to the expectations of Zettel JSON entries.
"""
function _crossrefPeople(authorList)
	people = []
	for author ∈ authorList
		name = get(author, "name", "")
		family = get(author, "family", "")
		given = get(author, "given", "")

		personDict = Dict{String, String}()
		if ! isempty(name)
			personDict["last"] = stripOuterBraces(String(name))
		else
			first, middle = splitGivenName(String(given))
			last = stripOuterBraces(String(family))
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
@doc """
Convert a Crossref work message (as returned by `fetchCrossrefJson`) to a Zettel-style JSON file.

# Input
- `record::Dict{String, Any}`: Crossref work message.
- `outputPath::AbstractString`: destination `.json` file.
- `key`: optional citation key override.

# Output
- The `outputPath` string after writing the converted file.
"""
function crossrefJsonToZettelJson(record::Dict{String, Any}, outputPath::AbstractString; key::Maybe{AbstractString} = nothing)
	entryKey, entryDict = _crossrefMessageToZettelEntry(record; key = key)
	entry = _crossrefStructuredToEntry(entryKey, entryDict)
	text = entryToString(entry, JsonFormat())
	endswith(text, "\n") || (text *= "\n")
	write(outputPath, text)
	return outputPath
end

# ----------------------------------------------------------------------------------------------- #
