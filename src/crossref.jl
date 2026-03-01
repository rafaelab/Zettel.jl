# ----------------------------------------------------------------------------------------------- #
#
const CROSSREF_API = "https://api.crossref.org/works/"


# ----------------------------------------------------------------------------------------------- #
#
# map CrossRef `type` values to BibTeX entry types
const crossrefTypeMap = Dict{String, String}(
	"journal-article"          => "article",
	"book"                     => "book",
	"book-chapter"             => "inbook",
	"edited-book"              => "book",
	"monograph"                => "book",
	"proceedings-article"      => "inproceedings",
	"proceedings"              => "proceedings",
	"report"                   => "techreport",
	"dissertation"             => "phdthesis",
	"dataset"                  => "misc",
	"posted-content"           => "misc",
	"reference-entry"          => "misc",
	"other"                    => "misc",
)

# ----------------------------------------------------------------------------------------------- #
#
@doc """
	crossrefAuthors(authorList)

Convert the CrossRef author array (each element has `"family"` and optionally `"given"` sub-fields) into a BibTeX-style author string `"Last1, First1 and Last2, First2 and ..."`.
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

Extract the publication year from a CrossRef work message.  Returns an empty string when
no date information is available.
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

Fetch bibliographic metadata from the CrossRef REST API for the given `doi` and return a
[`ZettelEntry`](@ref).
`userAgent` can be set to a custom string (recommended by CrossRef polite-pool guidelines).

# Example
```julia
entry = fetchFromCrossref("10.1002/andp.19053221004")
```
"""
function fetchFromCrossref(doi::AbstractString; userAgent::AbstractString = "Zettel.jl/0.1 (https://github.com/rafaelab/Zettel.jl)")
	url = CROSSREF_API * HTTP.escapeuri(doi)
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
