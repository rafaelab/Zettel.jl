# ----------------------------------------------------------------------------------------------- #
@testset "ZettelEntry" begin

	@testset "construction" begin
		e = _sampleArticle()
		@test e.key == "Einstein1905"
		@test e.entryType == "article"
		@test hasField(e, "author")
		@test ! hasField(e, "abstract")
	end

	@testset "accessor helpers" begin
		e = _sampleArticle()
		@test getKey(e) == "Einstein1905"
		@test getType(e) == "article"
		@test getTitle(e) == "Zur Elektrodynamik bewegter Körper"
		@test getAuthors(e) == "Einstein, A."
		@test getYear(e) == "1905"
		@test getJournal(e) == "Annalen der Physik"
		@test getVolume(e) == "322"
		@test getNumber(e) == "10"
		@test getPages(e) == "891-921"
		@test getDOI(e) == "10.1002/andp.19053221004"
		@test getURL(e) == ""
		@test getAbstract(e) == ""
	end

	@testset "getField" begin
		e = _sampleArticle()
		@test getField(e, "year") == "1905"
		@test getField(e, "YEAR") == "1905"  # case insensitive
		@test getField(e, "nonexistent") == ""
	end

	@testset "getAllFields" begin
		e = _sampleArticle()
		fs = getAllFields(e)
		@test "author" ∈ fs
		@test "title" ∈ fs
		@test "journal" ∈ fs
	end

end
