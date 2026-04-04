# ----------------------------------------------------------------------------------------------- #
#
const crossRefAPI = "https://api.crossref.org/works/"


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
	fetchFromCrossref(doi; userAgent)

Fetch bibliographic metadata from the CrossRef REST API for the given `doi` and return a [`ZettelEntry`](@ref).
`userAgent` can be set to a custom string (recommended by CrossRef polite-pool guidelines).

# Example
```julia
	entry = fetchFromCrossref("10.1002/andp.19053221004")
```
"""
function fetchFromCrossref(doi::AbstractString; userAgent::AbstractString = "Zettel.jl/2.1 (https://github.com/rafaelab/Zettel.jl)")
	url = crossRefAPI * HTTP.escapeuri(doi)
	response = HTTP.get(url; headers = ["User-Agent" => userAgent])

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
	defaultFetcher(url)

Default fetcher function for CrossRef metadata. Downloads the content at `url` to a temporary file, reads it as a string, and then deletes the temporary file.

# Input
- `url::AbstractString`: URL to fetch.

# Output
- The content at `url` as a string.
"""
function defaultFetcher(url::AbstractString)
	tmpFile = Downloads.download(url)
	try
		return read(tmpFile, String)
	finally
		rm(tmpFile; force = true)
	end
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
	fetchCrossrefJson(doi; fetcher)

Fetch metadata for a DOI from CrossRef and return it as a JSON dictionary.

# Input
- `doi::AbstractString`: DOI to fetch metadata for.
- `fetcher::Function`: function to fetch the CrossRef API response as a string (defaults to `defaultFetcher`).

# Output
- A `Dict` containing the CrossRef metadata for the DOI.
"""
function fetchCrossrefJson(doi::AbstractString; fetcher::Function = defaultFetcher)
	escapedDoi = encodeUriComponent(String(doi))
	payload = fetcher("$(crossRefAPI)$(escapedDoi)")
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
	saveCrossrefJson(doi, outputPath; fetcher)

Fetch metadata for a DOI from CrossRef and save it to `outputPath`.

# Input
- `doi::AbstractString`: DOI to fetch metadata for.
- `outputPath::AbstractString`: file path to save the metadata to.
- `fetcher::Function`: function to fetch the CrossRef API response as a string (defaults to `defaultFetcher`).

# Output
- The `outputPath` string after writing the metadata to it.
"""
function saveCrossrefJson(doi::AbstractString, outputPath::AbstractString; fetcher::Function = defaultFetcher)
	record = fetchCrossrefJson(doi; fetcher = fetcher)
	write(outputPath, JSON3.write(record))
	return outputPath
end


# ----------------------------------------------------------------------------------------------- #
