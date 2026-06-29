# ----------------------------------------------------------------------------------------------- #
#
@testset "Query helpers" begin
	lib = ZettelLibrary([sampleArticle(), sampleBook()])

	@testset "findByKey" begin
		@test findByKey(lib, "Einstein1905").key == "Einstein1905"
		@test isnothing(findByKey(lib, "absent"))
	end

	@testset "filterByField" begin
		titleMatches = filterByField(lib, "title", "Gravitation")
		@test length(titleMatches) == 1
		@test titleMatches[1].key == "Misner1973"

		# exact match
		exact = filterByField(lib, "year", "1905"; exact = true)
		@test length(exact) == 1
		@test exact[1].key == "Einstein1905"

		# case insensitive (default)
		ci = filterByField(lib, "title", "GRAVITATION")
		@test length(ci) == 1

		# case sensitive — should not match
		cs = filterByField(lib, "title", "GRAVITATION"; caseSensitive = true)
		@test length(cs) == 0
	end

	@testset "searchEntries — all fields (Nothing dispatch)" begin
		allMatches = searchEntries(lib; text = "Annalen")
		@test length(allMatches) == 1
		@test allMatches[1].key == "Einstein1905"

		# empty query returns all
		@test length(searchEntries(lib)) == 2

		# key search
		keyMatches = searchEntries(lib; text = "Misner")
		@test length(keyMatches) == 1
		@test keyMatches[1].key == "Misner1973"
	end

	@testset "searchEntries — specific field (String dispatch)" begin
		fieldMatches = searchEntries(lib; field = "journal", text = "Annalen")
		@test length(fieldMatches) == 1
		@test fieldMatches[1].key == "Einstein1905"

		# field that neither entry has → no matches
		@test isempty(searchEntries(lib; field = "abstract", text = "anything"))
	end
end


# ----------------------------------------------------------------------------------------------- #
#
@testset "findEntryByKey" begin
	mktempdir() do dir
		jsonPath = joinpath(dir, "lib.json")
		yamlPath = joinpath(dir, "lib.yaml")
		lib = ZettelLibrary([sampleArticle(), sampleBook()])
		writeJsonLibrary(lib, jsonPath)
		writeYamlLibrary(lib, yamlPath)

		# JSON fast path: the returned entry is byte-identical to a full load + findByKey
		fast = findEntryByKey(jsonPath, "Misner1973")
		@test ! isnothing(fast)
		@test fast.key == "Misner1973"
		@test getTitle(fast) == "Gravitation"
		full = findByKey(loadLibrary(jsonPath), "Misner1973")
		@test entryToString(fast, JsonFormat()) == entryToString(full, JsonFormat())

		# absent key returns nothing (not an error)
		@test isnothing(findEntryByKey(jsonPath, "absent2000a"))

		# BibTeX fast path: the returned entry matches a full load + findByKey
		bibPath = joinpath(dir, "lib.bib")
		writeBibtexLibrary(lib, bibPath)
		bibFast = findEntryByKey(bibPath, "Misner1973")
		@test ! isnothing(bibFast)
		@test bibFast.key == "Misner1973"
		@test getTitle(bibFast) == "Gravitation"
		bibFull = findByKey(loadLibrary(bibPath), "Misner1973")
		@test entryToString(bibFast, BibtexFormat()) == entryToString(bibFull, BibtexFormat())

		# a key that is a prefix of a real key must not match, and absent keys return nothing
		@test isnothing(findEntryByKey(bibPath, "Misner197"))
		@test isnothing(findEntryByKey(bibPath, "absent2000a"))

		# generic (YAML) path returns the same result as findByKey
		yamlEntry = findEntryByKey(yamlPath, "Einstein1905")
		@test ! isnothing(yamlEntry)
		@test yamlEntry.key == "Einstein1905"
		@test isnothing(findEntryByKey(yamlPath, "absent2000a"))

		# missing file is rejected
		@test_throws ArgumentError findEntryByKey(joinpath(dir, "nope.json"), "x")
	end
end


# ----------------------------------------------------------------------------------------------- #
#