# ----------------------------------------------------------------------------------------------- #
#
const dataCiteAPI = "https://api.datacite.org/dois/"


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


# ----------------------------------------------------------------------------------------------- #
#
@doc """
	fetchFromDataCite(doi; fetcher, userAgent)

Fetch bibliographic metadata from the DataCite REST API for the given `doi` and return a [`ZettelEntry`](@ref).
"""
function fetchFromDataCite(doi::AbstractString; fetcher::Function = defaultFetcher,	userAgent::Maybe{AbstractString} = nothing)
	ua = something(nonEmptyString(userAgent), nonEmptyString(get(ENV, "DATACITE_USER_AGENT", "")), crossRefDefaultUserAgent)
	url = dataCiteAPI * strip(String(doi))
	headers = Pair{String, String}["User-Agent" => ua]

	payload = applicable(fetcher, url, headers) ? fetcher(url, headers) : fetcher(url)
	parsed = try
		JSON3.read(payload)
	catch
		throw(ArgumentError("DataCite response was not valid JSON."))
	end

	data = haskey(parsed, :data) ? toPlainDict(parsed[:data]) : nothing
	if isnothing(data)
		throw(ArgumentError("DataCite response did not contain a data field."))
	end

	attrs = get(data, "attributes", nothing)
	if isnothing(attrs)
		throw(ArgumentError("DataCite response did not contain data.attributes."))
	end

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

	key = entryKeyFromNameAndYear(firstFamily, year)
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
	if ! isempty(volume)
		fields["volume"] = volume
	end
	
	issue = strip(String(get(container, "issue", "")))
	if ! isempty(issue)
		fields["number"] = issue
	end
	
	firstPage = strip(String(get(container, "firstPage", "")))
	lastPage = strip(String(get(container, "lastPage", "")))
	
	if ! isempty(firstPage) && ! isempty(lastPage)
		fields["pages"] = string(firstPage, "-", lastPage)
	elseif ! isempty(firstPage)
		fields["pages"] = firstPage
	end

	if ! isempty(year)
		fields["year"] = year
	end

	doiVal = strip(String(get(attrs, "doi", "")))
	if ! isempty(doiVal)
		fields["doi"] = doiVal
	end

	urlVal = strip(String(get(attrs, "url", "")))
	if ! isempty(urlVal)
		fields["url"] = urlVal
	end

	publisherVal = strip(String(get(attrs, "publisher", "")))
	if ! isempty(publisherVal)
		fields["publisher"] = publisherVal
	end

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
