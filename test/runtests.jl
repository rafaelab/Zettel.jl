using Test
using Zettel
using JSON3
import Pybtex
using OrderedCollections
using PythonCall: pyconvert


testRef =  """
@article{doe2024,
author = {Doe, Jane and Roe, John},
title = {A Sample Entry},
journal = {Journal of Testing},
year = {2024},
doi = {10.1000/example}
}
"""


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
@testset "BibTeX <-> JSON conversion" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")
		outputBib = joinpath(dir, "output.bib")

		write(inputBib, testRef)

		bibTeXToJson(inputBib, outputJson)
		jsonToBibTeX(outputJson, outputBib)

		original = Pybtex.readBibtexDataBase(inputBib)
		rebuilt = Pybtex.readBibtexDataBase(outputBib)
		originalEntry = Pybtex.getEntry(original, "doe2024")
		rebuiltEntry = Pybtex.getEntry(rebuilt, "doe2024")

		for field ∈ Pybtex.getAllFields(originalEntry)
			@test Pybtex.hasField(rebuiltEntry, field)
			@test pyconvert(String, originalEntry.info.fields[field]) == pyconvert(String, rebuiltEntry.info.fields[field])
		end
		@test length(collect(Pybtex.getAllFields(rebuiltEntry))) == length(collect(Pybtex.getAllFields(originalEntry)))
		@test length(rebuiltEntry.info.persons["author"]) == length(originalEntry.info.persons["author"])

	end

end


# ----------------------------------------------------------------------------------------------- #
#
@testset "Zettel JSON format" begin
	mktempdir() do dir
		inputBib = joinpath(dir, "input.bib")
		outputJson = joinpath(dir, "library.json")

		write(inputBib, """
@article{bertone1938,
author = {{Bertone}, Gianfranco and Roe, Jane},
title = {{A} Title},
collaboration = {ATLAS Collaboration},
year = {1938}
}
""")

		bibTeXToJson(inputBib, outputJson)
		data = JSON3.read(read(outputJson, String))
		entry = data[:bertone1938]

		@test entry[:title] == "{A} Title"
		@test haskey(entry, :author)
		@test entry[:author][1][:first] == "Gianfranco"
		@test entry[:author][1][:last] == "Bertone"
		@test ! haskey(entry[:author][1], :middle)

		@test haskey(entry, :collaboration)
		@test entry[:collaboration][1][:name] == "ATLAS Collaboration"
	end
end


# ----------------------------------------------------------------------------------------------- #
# Helper: build a simple article entry for reuse across tests
function _sampleArticle()
	fields = OrderedDict{String, String}(
		"author"  => "Einstein, A.",
		"title"   => "Zur Elektrodynamik bewegter Körper",
		"journal" => "Annalen der Physik",
		"year"    => "1905",
		"volume"  => "322",
		"number"  => "10",
		"pages"   => "891-921",
		"doi"     => "10.1002/andp.19053221004",
	)
	return ZettelEntry("Einstein1905", "article", fields)
end

function _sampleBook()
	fields = OrderedDict{String, String}(
		"author"    => "Misner, Charles W. and Thorne, Kip S. and Wheeler, John A.",
		"title"     => "Gravitation",
		"publisher" => "W. H. Freeman",
		"year"      => "1973",
		"isbn"      => "978-0-7167-0344-0",
	)
	return ZettelEntry("Misner1973", "book", fields)
end


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


# ----------------------------------------------------------------------------------------------- #
@testset "ZettelLibrary" begin

	@testset "construction and basic operations" begin
		lib = ZettelLibrary()
		@test length(lib) == 0

		e1 = _sampleArticle()
		e2 = _sampleBook()
		push!(lib, e1)
		push!(lib, e2)
		@test length(lib) == 2
		@test haskey(lib, "Einstein1905")
		@test haskey(lib, "Misner1973")
		@test ! haskey(lib, "notpresent")
	end

	@testset "getindex" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		e = lib["Einstein1905"]
		@test e.key == "Einstein1905"
	end

	@testset "pop!" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		pop!(lib, "Einstein1905")
		@test ! haskey(lib, "Einstein1905")
		@test length(lib) == 1
	end

	@testset "iterate" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		keysFound = [e.key for e ∈ lib]
		@test "Einstein1905" ∈ keysFound
		@test "Misner1973" ∈ keysFound
	end

	@testset "vector constructor" begin
		lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
		@test length(lib) == 2
	end

end 


# ----------------------------------------------------------------------------------------------- #
#
@testset "Query helpers" begin
	lib = ZettelLibrary([_sampleArticle(), _sampleBook()])

	@test findByKey(lib, "Einstein1905").key == "Einstein1905"
	@test findByKey(lib, "missing") === nothing

	titleMatches = filterByField(lib, "title", "Gravitation")
	@test length(titleMatches) == 1
	@test titleMatches[1].key == "Misner1973"

	allMatches = searchEntries(lib; text = "Annalen")
	@test length(allMatches) == 1
	@test allMatches[1].key == "Einstein1905"
end


# ----------------------------------------------------------------------------------------------- #
@testset "JSON round-trip" begin
	lib = ZettelLibrary([_sampleArticle(), _sampleBook()])
	tmpfile = tempname() * ".json"

	try
		writeJsonLibrary(lib, tmpfile)
		@test isfile(tmpfile)

		lib2 = readJsonLibrary(tmpfile)
		@test length(lib2) == 2
		@test haskey(lib2, "Einstein1905")
		@test haskey(lib2, "Misner1973")

		e = lib2["Einstein1905"]
		@test getTitle(e) == "Zur Elektrodynamik bewegter Körper"
		@test getYear(e) == "1905"
		@test getDOI(e) == "10.1002/andp.19053221004"
	finally
		isfile(tmpfile) && rm(tmpfile)
	end
end


# ----------------------------------------------------------------------------------------------- #
@testset "BibTeX round-trip" begin
	lib = ZettelLibrary([_sampleArticle()])
	tmpbib = tempname() * ".bib"

	try
		writeBibTeX(lib, tmpbib)
		@test isfile(tmpbib)

		lib2 = readBibTeX(tmpbib)
		@test length(lib2) ≥ 1
		@test haskey(lib2, "Einstein1905")
		e = lib2["Einstein1905"]
		@test ! isempty(getTitle(e))

	finally
		isfile(tmpbib) && rm(tmpbib)
	end


end
