# ----------------------------------------------------------------------------------------------- #
@testset "Query helpers" begin
	lib = ZettelLibrary([_sampleArticle(), _sampleBook()])

	@test findByKey(lib, "Einstein1905").key == "Einstein1905"
	@test findByKey(lib, "absent") === nothing

	titleMatches = filterByField(lib, "title", "Gravitation")
	@test length(titleMatches) == 1
	@test titleMatches[1].key == "Misner1973"

	allMatches = searchEntries(lib; text = "Annalen")
	@test length(allMatches) == 1
	@test allMatches[1].key == "Einstein1905"
end
