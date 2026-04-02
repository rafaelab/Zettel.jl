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

	@testset "set-like operations" begin
		left = ZettelEntry(
			"leftKey",
			"article",
			OrderedDict{String, String}(
				"author" => "Einstein, A.",
				"title" => "Left Title",
				"year" => "1905",
				"doi" => "10.1000/left",
			),
		)
		right = ZettelEntry(
			"rightKey",
			"book",
			OrderedDict{String, String}(
				"title" => "Right Title",
				"year" => "1910",
				"url" => "https://example.org",
				"isbn" => "978-0-00-000000-0",
			),
		)

		common = intersect(left, right)
		@test common.key == "leftKey"
		@test common.entryType == "article"
		@test collect(keys(common.fields)) == ["title", "year"]
		@test common.fields["title"] == "Left Title"
		@test common.fields["year"] == "1905"

		combined = union(left, right)
		@test combined.key == "leftKey"
		@test combined.entryType == "article"
		@test combined.fields["author"] == "Einstein, A."
		@test combined.fields["title"] == "Right Title"
		@test combined.fields["year"] == "1910"
		@test combined.fields["doi"] == "10.1000/left"
		@test combined.fields["url"] == "https://example.org"
		@test combined.fields["isbn"] == "978-0-00-000000-0"
	end

end
