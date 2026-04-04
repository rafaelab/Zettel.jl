# ----------------------------------------------------------------------------------------------- #
#
@testset "Crossref fetch" begin
	payload = """{"status":"ok","message":{"DOI":"10.1000/test","title":["Example"]}}"""
	record = fetchCrossrefJson("10.1000/test"; fetcher = _ -> payload)
	@test record["DOI"] == "10.1000/test"
	@test record["title"][1] == "Example"
	@test_throws ArgumentError fetchCrossrefJson("10.1000/test"; fetcher = _ -> "{")
	@test_throws ArgumentError fetchCrossrefJson("10.1000/test"; fetcher = _ -> "{\"status\":\"ok\"}")
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Crossref polite/auth request config" begin
	seenUrl = Ref("")
	seenHeaders = Ref(Pair{String, String}[])
	payload = """{"status":"ok","message":{"DOI":"10.1000/test"}}"""

	function captureFetcher(url, headers)
		seenUrl[] = url
		seenHeaders[] = collect(headers)
		return payload
	end

	record = fetchCrossrefJson(
		"10.1000/test";
		fetcher = captureFetcher,
		mailto = "user@example.org",
		plusToken = "abc123",
		userAgent = "ZettelTest/0.1",
	)

	@test record["DOI"] == "10.1000/test"
	@test occursin("mailto=user%40example.org", seenUrl[])
	@test any(h -> first(h) == "User-Agent" && occursin("mailto:user@example.org", last(h)), seenHeaders[])
	@test any(h -> first(h) == "Crossref-Plus-API-Token" && last(h) == "Bearer abc123", seenHeaders[])
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "DOI sources and DataCite fetch" begin
	@test "crossref" ∈ doiSources()
	@test "datacite" ∈ doiSources()

	payload = """
	{
		"data": {
			"attributes": {
				"types": { "resourceTypeGeneral": "JournalArticle" },
				"creators": [{ "familyName": "Doe", "givenName": "Jane" }],
				"publicationYear": "2024",
				"titles": [{ "title": "Sample DataCite Entry" }],
				"container": {
					"title": "Journal of Testing",
					"volume": "12",
					"issue": "3",
					"firstPage": "10",
					"lastPage": "19"
				},
				"doi": "10.1234/example.doi",
				"url": "https://doi.org/10.1234/example.doi",
				"publisher": "Example Publisher",
				"identifiers": [{ "identifierType": "ISBN", "identifier": "978-1-23456-789-0" }]
			}
		}
	}
	"""

	entry = fetchFromDataCite("10.1234/example.doi"; fetcher = _ -> payload)
	@test getKey(entry) == "Doe2024"
	@test getType(entry) == "article"
	@test getField(entry, "title") == "Sample DataCite Entry"
	@test getField(entry, "journal") == "Journal of Testing"
	@test getField(entry, "year") == "2024"
	@test getField(entry, "doi") == "10.1234/example.doi"

	seenUrl = Ref("")
	fetchFromDataCite("10.1234/example.doi"; fetcher = (url, _headers) -> (seenUrl[] = url; payload))
	@test occursin("/10.1234/example.doi", seenUrl[])
end

# ----------------------------------------------------------------------------------------------- #
