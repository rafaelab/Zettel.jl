# ----------------------------------------------------------------------------------------------- #
#
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

	@testset "field ordering" begin
		entry = ZettelEntry(
			"ordered",
			"article",
			OrderedDict{String, String}(
				"doi" => "10.1000/pref",
				"custom" => "extra",
				"title" => "Preferred Title",
				"year" => "2022",
				"author" => "Author, A.",
			),
		)
		@test collect(keys(entry.fields)) == ["author", "title", "year", "doi", "custom"]

		entry2 = ZettelEntry(
			"ordered2",
			"article",
			OrderedDict(
				"Year" => "2023",
				"AUTHOR" => "Author, B.",
				"title" => "Another Title",
			),
		)
		orderFields!(entry2; preferredOrder = ["year", "author"])
		@test collect(keys(entry2.fields)) == ["Year", "AUTHOR", "title"]
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "entryToString" begin
	e = _sampleArticle()

	@testset "BibTeX format" begin
		s = entryToString(e, bibTeXFormat())
		@test startswith(s, "@article{Einstein1905,")
		@test occursin("author = {Einstein, A.}", s)
		@test occursin("K\\\"orper", s)
		@test occursin("year = {1905}", s)
		@test occursin("doi = {10.1002/andp.19053221004}", s)
	end

	@testset "JSON format" begin
		s = entryToString(e, jsonFormat())
		@test occursin("\"key\"", s)
		@test occursin("\"Einstein1905\"", s)
		@test occursin("\"type\"", s)
		@test occursin("\"article\"", s)
		@test occursin("\"fields\"", s)
	end

	@testset "YAML format" begin
		s = entryToString(e, yamlFormat())
		@test occursin("key:", s)
		@test occursin("Einstein1905", s)
		@test occursin("type:", s)
		@test occursin("article", s)
	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "entryFromString round-trip" begin
	e = _sampleArticle()

	@testset "JSON round-trip" begin
		s = entryToString(e, jsonFormat())
		e2 = entryFromString(s, jsonFormat())
		@test e2.key == e.key
		@test e2.entryType == e.entryType
		@test getTitle(e2) == getTitle(e)
		@test getYear(e2) == getYear(e)
		@test getDOI(e2) == getDOI(e)
	end

	@testset "YAML round-trip" begin
		s = entryToString(e, yamlFormat())
		e2 = entryFromString(s, yamlFormat())
		@test e2.key == e.key
		@test e2.entryType == e.entryType
		@test getTitle(e2) == getTitle(e)
		@test getYear(e2) == getYear(e)
	end

end

# ----------------------------------------------------------------------------------------------- #
