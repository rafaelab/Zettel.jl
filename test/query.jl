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