# ----------------------------------------------------------------------------------------------- #
#
const CROSSREF_API = "https://api.crossref.org/works/"

# Map CrossRef `type` values to BibTeX entry types
const _crossrefTypeMap = Dict{String, String}(
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
	_crossrefAuthors(authorList)

Convert the CrossRef author array (each element has `"family"` and optionally `"given"`
sub-fields) into a BibTeX-style author string
`"Last1, First1 and Last2, First2 and ..."`.
"""
function _crossrefAuthors(authorList)
	parts = String[]
	for a in authorList
		family = get(a, "family", "")
		given  = get(a, "given", "")
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
	_crossrefYear(msg)

Extract the publication year from a CrossRef work message.  Returns an empty string when
no date information is available.
"""
function _crossrefYear(msg)
	for key in ("published", "published-print", "published-online", "issued")
		if haskey(msg, key)
			dateParts = get(msg[key], "date-parts", nothing)
			if dateParts !== nothing && length(dateParts) > 0
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

	if response.status != 200
		error("CrossRef request failed with status $(response.status) for DOI: $doi")
	end

	body = JSON3.read(String(response.body))
	msg = body["message"]

	# Determine BibTeX type
	crType = String(get(msg, "type", "other"))
	bibType = get(_crossrefTypeMap, crType, "misc")

	# Build citation key: LastnameYear
	authorList = get(msg, "author", [])
	firstFamily = length(authorList) > 0 ? get(authorList[1], "family", "Unknown") : "Unknown"
	year = _crossrefYear(msg)
	key = replace(firstFamily, " " => "") * (isempty(year) ? "" : year)

	# Populate fields preserving BibTeX conventions
	fields = OrderedDict{String, String}()

	# Authors
	if length(authorList) > 0
		fields["author"] = _crossrefAuthors(authorList)
	end

	# Title
	titles = get(msg, "title", [])
	if length(titles) > 0
		fields["title"] = String(titles[1])
	end

	# Journal / container
	containerTitles = get(msg, "container-title", [])
	if length(containerTitles) > 0
		ct = String(containerTitles[1])
		if bibType == "article"
			fields["journal"] = ct
		elseif bibType in ("inproceedings", "proceedings")
			fields["booktitle"] = ct
		else
			fields["journal"] = ct
		end
	end

	# Year
	if !isempty(year)
		fields["year"] = year
	end

	# Volume / issue / pages
	vol = get(msg, "volume", nothing)
	if vol !== nothing
		fields["volume"] = String(vol)
	end

	issue = get(msg, "issue", nothing)
	if issue !== nothing
		fields["number"] = String(issue)
	end

	pageStr = get(msg, "page", nothing)
	if pageStr !== nothing
		fields["pages"] = String(pageStr)
	end

	# DOI
	doiVal = get(msg, "DOI", nothing)
	if doiVal !== nothing
		fields["doi"] = String(doiVal)
	end

	# URL
	urlVal = get(msg, "URL", nothing)
	if urlVal !== nothing
		fields["url"] = String(urlVal)
	end

	# Publisher
	pub = get(msg, "publisher", nothing)
	if pub !== nothing
		fields["publisher"] = String(pub)
	end

	# ISBN
	isbns = get(msg, "ISBN", [])
	if length(isbns) > 0
		fields["isbn"] = String(isbns[1])
	end

	# Abstract
	abstract_ = get(msg, "abstract", nothing)
	if abstract_ !== nothing
		fields["abstract"] = String(abstract_)
	end

	return ZettelEntry(key, bibType, fields)
end


# ----------------------------------------------------------------------------------------------- #
#
